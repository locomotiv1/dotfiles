return {
  -----------------------------------------------------------------------------
  --- 1. LSPs & MASON (Auto-installer)
  -----------------------------------------------------------------------------
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'mason-org/mason.nvim', opts = {} },
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end
          map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
          map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
        end,
      })

      -- ADD YOUR LSPs HERE
      local servers = {
        lua_ls = {
          settings = {
            Lua = {
              completion = { callSnippet = 'Replace' },
            },
          },
        },
        -- example:
        pyright = {},
        gopls = {},
      }

      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        -- ADD FORMATTERS AND LINTERS TO BE AUTO-INSTALLED BY MASON HERE
        'stylua',
        'markdownlint',
        'jsonlint',
        'golangci-lint',
      })

      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      require('mason-lspconfig').setup {
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            server.capabilities = vim.tbl_deep_extend('force', {}, vim.lsp.protocol.make_client_capabilities(), server.capabilities or {})
            require('lspconfig')[server_name].setup(server)
          end,
        },
      }
    end,
  },

  -----------------------------------------------------------------------------
  --- 2. FORMATTERS (conform.nvim)
  -----------------------------------------------------------------------------
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      { '<leader>f', function() require('conform').format { async = true, lsp_format = 'fallback' } end, mode = '', desc = '[F]ormat buffer' },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        local disable_filetypes = { c = true, cpp = true }
        if disable_filetypes[vim.bo[bufnr].filetype] then return nil end
        return { timeout_ms = 500, lsp_format = 'fallback' }
      end,
      -- ADD FORMATTERS TO FILETYPES HERE
      formatters_by_ft = {
        lua = { 'stylua' },
        python = { 'ruff' },
        go = { 'gofumpt', 'goimports' },
      },
    },
  },

  -----------------------------------------------------------------------------
  --- 3. LINTERS (nvim-lint)
  -----------------------------------------------------------------------------
  {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'

      -- ADD LINTERS TO FILETYPES HERE
      lint.linters_by_ft = {
        markdown = { 'markdownlint' },
        json = { 'jsonlint' },
        go = { 'golangcilint' },
        -- example:
        -- python = { 'flake8' }
      }

      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          if vim.bo.modifiable then lint.try_lint() end
        end,
      })
    end,
  },
}
