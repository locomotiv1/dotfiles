---@module 'lazy'
---@type LazySpec
return {
  {
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      'rafamadriz/friendly-snippets',
    },
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        preset = 'default',
        ['<CR>'] = { 'accept', 'fallback' },
      },

      appearance = {
        nerd_font_variant = 'normal',
      },

      completion = {
        documentation = { auto_show = false, auto_show_delay_ms = 500 },
      },

      sources = {
        default = { 'lsp', 'path', 'snippets' },
      },

      snippets = { preset = 'default' },
      fuzzy = { implementation = 'lua' },

      signature = { enabled = true },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
