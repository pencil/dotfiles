local colors = require("tokyonight.colors").setup()

return {
  "petertriho/nvim-scrollbar",
  config = function()
    require("scrollbar").setup({
      handle = {
        color = colors.bg_highlight,
      },
      marks = {
        Cursor = { text = " ", priority = 99 },
        Search = { color = colors.orange },
        Error = { color = colors.error },
        Warn = { color = colors.warning },
        Info = { color = colors.info },
        Hint = { color = colors.hint },
        Misc = { color = colors.purple },
      },
    })
  end,
}
