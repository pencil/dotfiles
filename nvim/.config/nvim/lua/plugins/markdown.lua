-- Relax markdownlint: silence the noisy stylistic rules listed in
-- markdownlint.yaml (line length, blank-line spacing, etc.).
--
-- markdownlint-cli2 is the markdown linter (nvim-lint, over stdin) and the
-- on-save fixer (conform, `--fix`). Both get pointed at the same explicit
-- config so diagnostics and auto-fix agree on the ruleset. We pass an absolute
-- --config because cli2's stdin mode only reads a config from the process cwd.
local config = vim.fn.stdpath("config") .. "/markdownlint.yaml"

return {
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters = {
        ["markdownlint-cli2"] = {
          args = { "--config", config, "-" },
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters = {
        ["markdownlint-cli2"] = {
          prepend_args = { "--config", config },
        },
      },
    },
  },
}
