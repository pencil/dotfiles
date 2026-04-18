-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.g.lazyvim_prettier_needs_config = true
vim.opt.clipboard = "unnamedplus"

-- Custom OSC 52 clipboard with DCS passthrough for nested tmux.
-- Copy uses neovim's built-in (tmux forwards OSC 52 writes automatically).
-- Paste needs explicit DCS wrapping so the query reaches the outer terminal.
local function tmux_wrap(s)
  return "\027Ptmux;" .. s:gsub("\027", "\027\027") .. "\027\\"
end

local function osc52_paste(reg)
  local clipboard = reg == "+" and "c" or "p"
  return function()
    local contents = nil
    local id = vim.api.nvim_create_autocmd("TermResponse", {
      callback = function(args)
        local encoded = args.data:match("\027%]52;%w?;([A-Za-z0-9+/=]*)")
        if encoded then
          contents = vim.base64.decode(encoded)
          return true
        end
      end,
    })

    local query = string.format("\027]52;%s;?\027\\", clipboard)
    if os.getenv("TMUX") then
      query = tmux_wrap(query)
      if os.getenv("SSH_TTY") then
        query = tmux_wrap(query)
      end
    end
    io.stdout:write(query)

    local ok, res = vim.wait(1000, function()
      return contents ~= nil
    end)
    if res == -1 then
      vim.api.nvim_echo({ { "Waiting for OSC 52 response from the terminal. Press Ctrl-C to interrupt..." } }, false, {})
      ok, res = vim.wait(9000, function()
        return contents ~= nil
      end)
    end
    if not ok then
      vim.api.nvim_del_autocmd(id)
      if res == -1 then
        vim.notify("Timed out waiting for clipboard response from terminal", vim.log.levels.WARN)
      elseif res == -2 then
        vim.api.nvim_echo({ { "" } }, false, {})
      end
      return 0
    end
    return vim.split(assert(contents), "\n")
  end
end

vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = {
    ["+"] = osc52_paste("+"),
    ["*"] = osc52_paste("*"),
  },
}
