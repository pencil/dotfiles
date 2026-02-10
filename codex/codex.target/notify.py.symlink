#!/usr/bin/env python3

import json
import os
import subprocess
import sys
from typing import Any, Iterable


MAX_TITLE_LENGTH = 160
MAX_MESSAGE_LENGTH = 512
ELLIPSIS = "..."


def _truncate(text: str, limit: int) -> str:
    stripped = text.strip()
    if not stripped or len(stripped) <= limit:
        return stripped
    if limit <= len(ELLIPSIS):
        return stripped[:limit]
    return f"{stripped[: limit - len(ELLIPSIS)].rstrip()}{ELLIPSIS}"


def _clean_spaces(text: str) -> str:
    return " ".join(text.split())


def _only_strings(values: Iterable[Any]) -> list[str]:
    return [
        str(value).strip()
        for value in values
        if isinstance(value, str) and value and str(value).strip()
    ]


def _build_agent_turn_notification(notification: dict[str, Any]) -> tuple[str, str]:
    assistant_message = (notification.get("last-assistant-message") or "").strip()
    input_messages = _only_strings(notification.get("input_messages", []))

    message_blocks: list[str] = []
    if assistant_message:
        message_blocks.append(assistant_message)
    if input_messages:
        message_blocks.append("\n".join(input_messages))

    message = "\n\n".join(block for block in message_blocks if block).strip()
    if not message:
        message = "Turn complete."

    raw_title = assistant_message or input_messages[0] if input_messages else ""
    if not raw_title:
        raw_title = "Turn complete."

    title = f"Codex: {raw_title}"
    title = _clean_spaces(title)
    title = _truncate(title, MAX_TITLE_LENGTH)
    message = _truncate(message, MAX_MESSAGE_LENGTH)

    return title or "Codex", message or title or "Codex"


def _notify_with_osascript(title: str, message: str) -> None:
    fallback_title = _truncate(_clean_spaces(title) or "Codex", MAX_TITLE_LENGTH)
    fallback_message = message.strip() or fallback_title
    apple_script = (
        f"display notification {json.dumps(fallback_message)} "
        f"with title {json.dumps(fallback_title)}"
    )

    try:
        subprocess.run(
            ["osascript", "-e", apple_script],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=True,
        )
        return
    except Exception as first_error:
        shorter_title = _truncate(fallback_title, 96)
        shorter_message = _truncate(_clean_spaces(fallback_message), 180)
        shorter_script = (
            f"display notification {json.dumps(shorter_message)} "
            f"with title {json.dumps(shorter_title)}"
        )
        try:
            subprocess.run(
                ["osascript", "-e", shorter_script],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=True,
            )
        except Exception as second_error:
            combined_error = f"{first_error}; {second_error}"
            #print(
            #    f"notify.py warning: osascript fallback failed: {combined_error}",
            #    file=sys.stderr,
            #)


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: notify.py <NOTIFICATION_JSON>")
        return 1

    try:
        notification = json.loads(sys.argv[1])
    except json.JSONDecodeError:
        return 1

    match notification_type := notification.get("type"):
        case "agent-turn-complete":
            title, message = _build_agent_turn_notification(notification)
        case _:
            print(f"not sending a push notification for: {notification_type}")
            return 0

    notifier_args = [
        "terminal-notifier",
        "-title",
        title,
        "-message",
        message,
        "-group",
        "codex",
        "-ignoreDnD",
        "-activate",
        "net.kovidgoyal.kitty",
        "-contentImage",
        "/Applications/ChatGPT.app/Contents/Resources/AppIcon.icns",
    ]

    try:
        subprocess.run(
            notifier_args,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=True,
        )
    except Exception:
        _notify_with_osascript(title, message)

    sound_path = os.path.expanduser("~/.codex/jobs_done.mp3")
    if os.path.exists(sound_path):
        try:
            subprocess.Popen(
                ["afplay", sound_path],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except FileNotFoundError:
            # afplay is unavailable, skip audio notification silently
            pass

    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:  # noqa: BLE001 - ensure a single-line error without a traceback
        #error_text = " ".join(str(exc).split()) or exc.__class__.__name__
        #print(f"notify.py error: {error_text}", file=sys.stderr)
        sys.exit(0)
