// scarlett-mic: a clean virtual microphone from a Focusrite Scarlett Solo 4th Gen,
// with a menu bar item to watch it and to pause it.
//
// The Scarlett exposes four input channels to macOS: Input 1, Input 2 and a
// stereo Loopback pair that mirrors whatever the Mac plays through the
// interface. Apps that mix every input channel feed the far end of a call back
// to itself. Neither Focusrite Control 2 nor Audio MIDI Setup can hide the
// Loopback pair, so this tool copies Input 1 alone into a virtual cable device
// (VB-Cable), which apps then select as the microphone.
//
// Why an aggregate device: both devices join a private aggregate with the
// Scarlett as clock master and drift compensation on the cable. One IO callback
// then sees the input and output buffers in lock step, so there is no ring
// buffer, no latency creep, and the HAL absorbs clock drift between the two.
//
// Why the modern IOProcID API: Chrome restarts both devices when a call's audio
// pipeline starts (its echo-cancellation unit binds microphone and default
// output together). IOProcIDs survive that restart. The legacy function-pointer
// API used by sox and LadioCast does not, which is why those die mid-call.
//
// Why the duck check: macOS voice processing (VoiceProcessingIO, which Firefox,
// Safari and many call apps use for echo cancellation) ducks the call's output
// device, here the Scarlett, by about 30 dB, and that includes everyone reading
// its input. Firefox releases the duck right away and other apps when they
// stop, but a reader that was already running can miss the release and stay
// 30 dB down until it is rebuilt, so the call hears the voice that quiet.
// Readers started later are unaffected, so the forwarder briefly opens a fresh
// one every few seconds and rebuilds its IO when its own input is far quieter.
//
// The menu bar icon is outline while quiet, filled while Input 1 carries voice,
// slashed while paused, and badged when a device is missing. Pause writes
// silence to the cable and is never remembered across a relaunch. There is no
// Quit: launchd keeps the process alive, and ./dotfiles reloads it.
//
// Check: with this running, speech must register on the cable's input:
//   ffmpeg -f avfoundation -i ":VB-Cable" -t 5 -af astats -f null -
import AppKit
import CoreAudio
import Synchronization

// MARK: CoreAudio helpers

func log(_ message: String) {
  let f = DateFormatter()
  f.dateFormat = "yyyy-MM-dd HH:mm:ss"
  print("\(f.string(from: Date())) \(message)")
  fflush(stdout)
}

func address(_ selector: AudioObjectPropertySelector, _ scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal) -> AudioObjectPropertyAddress {
  AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
}

func string(_ object: AudioObjectID, _ selector: AudioObjectPropertySelector) -> String {
  var a = address(selector)
  var value: Unmanaged<CFString>?
  var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
  guard AudioObjectGetPropertyData(object, &a, 0, nil, &size, &value) == noErr, let value else { return "" }
  return value.takeRetainedValue() as String
}

func objectIDs(_ object: AudioObjectID, _ selector: AudioObjectPropertySelector, _ scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal) -> [AudioObjectID] {
  var a = address(selector, scope)
  var size: UInt32 = 0
  guard AudioObjectGetPropertyDataSize(object, &a, 0, nil, &size) == noErr else { return [] }
  var value = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
  guard AudioObjectGetPropertyData(object, &a, 0, nil, &size, &value) == noErr else { return [] }
  return value
}

func device(named prefix: String) -> AudioObjectID? {
  objectIDs(AudioObjectID(kAudioObjectSystemObject), kAudioHardwarePropertyDevices)
    .first { string($0, kAudioObjectPropertyName).hasPrefix(prefix) }
}

// MARK: Forwarder

/// Routes channel 1 of the input device into every channel of the output
/// device through a private aggregate device. All methods run on the main
/// thread; the IO callback shares state with it only through atomics.
final class Forwarder {
  let inputPrefix: String
  let outputPrefix: String
  private(set) var running = false
  private(set) var inputName = ""
  private(set) var outputName = ""
  let paused = Atomic<Bool>(false)
  private let callbacks = Atomic<Int>(0)
  /// Bit pattern of the largest |sample| on channel 1 since the last readPeak().
  /// Non-negative floats order like their bit patterns, so an integer max works.
  private let peakBits = Atomic<UInt32>(0)
  /// Channel 1 peaks of the forwarder and of the fresh reference reader over
  /// one duck check window, in the same bit-pattern form.
  private let windowPeakBits = Atomic<UInt32>(0)
  private let referencePeakBits = Atomic<UInt32>(0)
  private var reference: AudioDeviceIOProcID?
  private var referenceDevice: AudioObjectID = 0
  private var duckChecks = 0
  private var aggregate: AudioObjectID = 0
  private var ioProc: AudioDeviceIOProcID?
  private var lastCount = 0
  private var announcedWait = false

  init(inputPrefix: String, outputPrefix: String) {
    self.inputPrefix = inputPrefix
    self.outputPrefix = outputPrefix
  }

  var devicesPresent: Bool { device(named: inputPrefix) != nil && device(named: outputPrefix) != nil }

  func readPeak() -> Float { Float(bitPattern: peakBits.exchange(0, ordering: .relaxed)) }

  /// Starts when waiting and both devices exist, restarts after a stall, and
  /// stops when a device vanished. `checkStall` is only true from the periodic
  /// timer, because a tick right after start() would see no callbacks yet.
  func tick(checkStall: Bool) {
    if running {
      if !devicesPresent {
        log("a device disappeared")
        stop()
        return
      }
      let count = callbacks.load(ordering: .relaxed)
      if checkStall, count == lastCount {
        log("IO stalled, restarting")
        stop()
        _ = start()
      }
      lastCount = count
    } else if devicesPresent {
      _ = start()
    } else if !announcedWait {
      log("waiting for \(inputPrefix) and \(outputPrefix)")
      announcedWait = true
    }
  }

  private func start() -> Bool {
    guard let inputDevice = device(named: inputPrefix), let outputDevice = device(named: outputPrefix) else { return false }
    inputName = string(inputDevice, kAudioObjectPropertyName)
    outputName = string(outputDevice, kAudioObjectPropertyName)
    let inputUID = string(inputDevice, kAudioDevicePropertyDeviceUID)
    let outputUID = string(outputDevice, kAudioDevicePropertyDeviceUID)
    let composition: [String: Any] = [
      kAudioAggregateDeviceUIDKey as String: "com.local.scarlett-mic",
      kAudioAggregateDeviceNameKey as String: "scarlett-mic",
      kAudioAggregateDeviceIsPrivateKey as String: 1,
      kAudioAggregateDeviceMainSubDeviceKey as String: inputUID,
      kAudioAggregateDeviceSubDeviceListKey as String: [
        [kAudioSubDeviceUIDKey as String: inputUID],
        [kAudioSubDeviceUIDKey as String: outputUID, kAudioSubDeviceDriftCompensationKey as String: 1],
      ],
    ]
    var agg: AudioObjectID = 0
    var status = AudioHardwareCreateAggregateDevice(composition as CFDictionary, &agg)
    guard status == noErr else {
      log("aggregate device creation failed: \(status)")
      return false
    }
    // The callback receives one buffer per aggregate stream, in the aggregate's
    // own stream order. That order does not always follow the sub-device list
    // and can change when a device re-enumerates, so the sub-device list cannot
    // be used to place the buffers. Identify the Scarlett's input buffer by its
    // channel count, which is unique among the members, and place the cable's
    // output buffer by the matching sub-device position. Reading the wrong input
    // buffer binds the callback to the cable's own input, a silent loop.
    func streamChannels(_ stream: AudioObjectID) -> Int {
      var a = address(kAudioStreamPropertyVirtualFormat)
      var format = AudioStreamBasicDescription()
      var size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
      guard AudioObjectGetPropertyData(stream, &a, 0, nil, &size, &format) == noErr else { return -1 }
      return Int(format.mChannelsPerFrame)
    }
    let inStreams = objectIDs(agg, kAudioDevicePropertyStreams, kAudioObjectPropertyScopeInput)
    let outStreams = objectIDs(agg, kAudioDevicePropertyStreams, kAudioObjectPropertyScopeOutput)
    let inChannels = inStreams.map(streamChannels)
    let outChannels = outStreams.map(streamChannels)
    let scarlettChannels = objectIDs(inputDevice, kAudioDevicePropertyStreams, kAudioObjectPropertyScopeInput)
      .map(streamChannels).reduce(0, +)
    log("aggregate input buffers \(inChannels), output buffers \(outChannels); \(inputName) has \(scarlettChannels) input channels")
    // Each member contributes one stream per scope, in the same member order for
    // both scopes, so the Scarlett's output buffer sits at its input position and
    // the cable's output buffer is the other one.
    guard inStreams.count == 2, outStreams.count == 2,
          let inputIndex = inChannels.firstIndex(of: scarlettChannels),
          inChannels.filter({ $0 == scarlettChannels }).count == 1 else {
      log("could not identify the \(inputName) input buffer; retrying")
      AudioHardwareDestroyAggregateDevice(agg)
      return false
    }
    let outputIndex = 1 - inputIndex

    var proc: AudioDeviceIOProcID?
    status = AudioDeviceCreateIOProcIDWithBlock(&proc, agg, nil) { _, inputData, _, outputData, _ in
      self.callbacks.add(1, ordering: .relaxed)
      let inputs = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: inputData))
      let outputs = UnsafeMutableAudioBufferListPointer(outputData)
      // Silence every output stream, including the Scarlett's own, which the HAL
      // mixes with other apps; then write Input 1 into the cable alone.
      for buffer in outputs {
        if let data = buffer.mData { memset(data, 0, Int(buffer.mDataByteSize)) }
      }
      // Identify the buffers on every cycle rather than trusting the indexes
      // found at start, so a changed stream order can never leave us reading
      // the cable's own input. The Scarlett is the input buffer whose channel
      // count is unique among the members; the cable's output is the member
      // counterpart of the other input.
      guard inputs.count == 2, outputs.count == 2 else { return }
      let scarIn = Int(inputs[0].mNumberChannels) == scarlettChannels ? 0 : 1
      let cableOut = 1 - scarIn
      guard Int(inputs[scarIn].mNumberChannels) == scarlettChannels,
            let source = inputs[scarIn].mData, let destination = outputs[cableOut].mData else { return }
      let inChannels = Int(inputs[scarIn].mNumberChannels)
      let outChannels = Int(outputs[cableOut].mNumberChannels)
      let frames = min(Int(inputs[scarIn].mDataByteSize) / 4 / inChannels,
                       Int(outputs[cableOut].mDataByteSize) / 4 / outChannels)
      let src = source.assumingMemoryBound(to: Float.self)
      let dst = destination.assumingMemoryBound(to: Float.self)
      let mute = self.paused.load(ordering: .relaxed)
      var peak: Float = 0
      for frame in 0..<frames {
        let sample = src[frame * inChannels]
        peak = max(peak, abs(sample))
        if !mute {
          for channel in 0..<outChannels { dst[frame * outChannels + channel] = sample }
        }
      }
      self.peakBits.max(peak.bitPattern, ordering: .relaxed)
      self.windowPeakBits.max(peak.bitPattern, ordering: .relaxed)
    }
    guard status == noErr, let proc else {
      log("IOProc creation failed: \(status)")
      AudioHardwareDestroyAggregateDevice(agg)
      return false
    }
    status = AudioDeviceStart(agg, proc)
    guard status == noErr else {
      log("IO start failed: \(status)")
      AudioDeviceDestroyIOProcID(agg, proc)
      AudioHardwareDestroyAggregateDevice(agg)
      return false
    }
    aggregate = agg
    ioProc = proc
    running = true
    announcedWait = false
    lastCount = callbacks.load(ordering: .relaxed)
    log("routing \(inputName) channel 1 (input buffer \(inputIndex)) -> \(outputName) (output buffer \(outputIndex))")
    return true
  }

  private func stop() {
    guard running else { return }
    stopReference()
    if let proc = ioProc {
      AudioDeviceStop(aggregate, proc)
      AudioDeviceDestroyIOProcID(aggregate, proc)
    }
    AudioHardwareDestroyAggregateDevice(aggregate)
    ioProc = nil
    aggregate = 0
    running = false
  }

  /// Runs once a second. Every fifth tick it opens a fresh reader on the input
  /// device, and on the next tick compares the two channel 1 peaks over that
  /// second. A stuck duck reads about 30 dB down, normal jitter within 15 dB,
  /// so it restarts below a tenth (-20 dB). Room noise alone peaks well above
  /// the -60 dBFS floor, so this also works between words.
  func checkDuck() {
    guard running else { return }
    duckChecks += 1
    if reference != nil {
      stopReference()
      let fresh = Float(bitPattern: referencePeakBits.load(ordering: .relaxed))
      let ours = Float(bitPattern: windowPeakBits.load(ordering: .relaxed))
      guard fresh > 1e-3, ours < fresh / 10 else { return }
      log(String(format: "input ducked (%.0f dBFS, a fresh reader gets %.0f dBFS), restarting", 20 * log10(ours), 20 * log10(fresh)))
      restart()
    } else if duckChecks % 5 == 0, let device = device(named: inputPrefix) {
      windowPeakBits.store(0, ordering: .relaxed)
      referencePeakBits.store(0, ordering: .relaxed)
      var proc: AudioDeviceIOProcID?
      let status = AudioDeviceCreateIOProcIDWithBlock(&proc, device, nil) { _, inputData, _, _, _ in
        let inputs = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: inputData))
        guard let first = inputs.first, let data = first.mData, first.mNumberChannels > 0 else { return }
        let samples = data.assumingMemoryBound(to: Float.self)
        var peak: Float = 0
        for i in stride(from: 0, to: Int(first.mDataByteSize) / 4, by: Int(first.mNumberChannels)) { peak = max(peak, abs(samples[i])) }
        self.referencePeakBits.max(peak.bitPattern, ordering: .relaxed)
      }
      guard status == noErr, let proc else { return }
      guard AudioDeviceStart(device, proc) == noErr else {
        AudioDeviceDestroyIOProcID(device, proc)
        return
      }
      reference = proc
      referenceDevice = device
    }
  }

  private func stopReference() {
    guard let proc = reference else { return }
    AudioDeviceStop(referenceDevice, proc)
    AudioDeviceDestroyIOProcID(referenceDevice, proc)
    reference = nil
  }

  /// Tears the aggregate down and builds it fresh, rediscovering the buffer
  /// layout. The menu's Restart item uses this to recover at once instead of
  /// waiting for the stall timer.
  func restart() {
    stop()
    _ = start()
  }
}

// MARK: Menu bar

final class StatusController: NSObject {
  private let forwarder: Forwarder
  private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
  private let statusLine = NSMenuItem(title: "", action: nil, keyEquivalent: "")
  private let levelLine = NSMenuItem(title: "", action: nil, keyEquivalent: "")
  private let pauseItem = NSMenuItem(title: "Pause", action: #selector(togglePause), keyEquivalent: "")
  private let restartItem = NSMenuItem(title: "Restart", action: #selector(restartForwarding), keyEquivalent: "")
  private var loudUntil = Date.distantPast

  init(forwarder: Forwarder) {
    self.forwarder = forwarder
    super.init()
    let menu = NSMenu()
    menu.autoenablesItems = false
    statusLine.isEnabled = false
    levelLine.isEnabled = false
    pauseItem.target = self
    restartItem.target = self
    menu.addItem(statusLine)
    menu.addItem(levelLine)
    menu.addItem(.separator())
    menu.addItem(pauseItem)
    menu.addItem(restartItem)
    item.menu = menu
    refresh()
  }

  @objc private func togglePause() {
    let now = forwarder.paused.load(ordering: .relaxed)
    forwarder.paused.store(!now, ordering: .relaxed)
    log(now ? "resumed" : "paused")
    refresh()
  }

  @objc private func restartForwarding() {
    log("restart requested")
    forwarder.restart()
    refresh()
  }

  /// Runs every 100 ms, also while the menu is open.
  func refresh() {
    let peak = forwarder.readPeak()
    let dBFS = peak > 0 ? 20 * log10(peak) : -Float.infinity
    // Room noise peaks around -35 dBFS; speech sits well above -25.
    if dBFS > -25 { loudUntil = Date().addingTimeInterval(0.3) }
    let paused = forwarder.paused.load(ordering: .relaxed)
    let symbol: String
    let text: String
    if !forwarder.running {
      symbol = "mic.badge.xmark"
      text = "Waiting for \(forwarder.inputPrefix)"
    } else if paused {
      symbol = "mic.slash.fill"
      text = "Paused"
    } else {
      symbol = Date() < loudUntil ? "mic.fill" : "mic"
      text = "\(forwarder.inputName) channel 1 → \(forwarder.outputName)"
    }
    if item.button?.image?.name() != symbol {
      let image = NSImage(systemSymbolName: symbol, accessibilityDescription: text)
      image?.setName(symbol)
      item.button?.image = image
    }
    statusLine.title = text
    levelLine.isHidden = !forwarder.running || paused
    levelLine.title = peak > 0 ? String(format: "Input level: %.0f dBFS", dBFS) : "Input level: silent"
    pauseItem.title = paused ? "Resume" : "Pause"
    pauseItem.isEnabled = forwarder.running
  }
}

// MARK: Main

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let forwarder = Forwarder(
  inputPrefix: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Scarlett Solo",
  outputPrefix: CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "VB-Cable")
forwarder.tick(checkStall: false)
let controller = StatusController(forwarder: forwarder)

// A reconnected or removed device is handled within a second; the timer covers stalls.
var deviceList = address(kAudioHardwarePropertyDevices)
AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &deviceList, DispatchQueue.main) { _, _ in
  forwarder.tick(checkStall: false)
  controller.refresh()
}
let supervisor = Timer(timeInterval: 5, repeats: true) { _ in forwarder.tick(checkStall: true) }
let meter = Timer(timeInterval: 0.1, repeats: true) { _ in controller.refresh() }
let duckCheck = Timer(timeInterval: 1, repeats: true) { _ in forwarder.checkDuck() }
RunLoop.main.add(supervisor, forMode: .common)
RunLoop.main.add(duckCheck, forMode: .common)
RunLoop.main.add(meter, forMode: .common)
signal(SIGINT) { _ in exit(0) }
signal(SIGTERM) { _ in exit(0) }
// A private aggregate device is destroyed with its owning process.
app.run()
