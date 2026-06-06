---@module 'lazy'
---@type LazySpec
return {
  'lewis6991/gitsigns.nvim',
  ---@module 'gitsigns'
  ---@type Gitsigns.Config
  ---@diagnostic disable-next-line: missing-fields
  opts = {
    signs = {
      add = { text = '┃' },
      change = { text = '┃' },
      delete = { text = '_' },
      topdelete = { text = '‾' },
      changedelete = { text = '~' },
      untracked = { text = '┆' },
    },
    signs_staged = {
      add = { text = '┃' },
      change = { text = '┃' },
      delete = { text = '_' },
      topdelete = { text = '‾' },
      changedelete = { text = '~' },
      untracked = { text = '┆' },
    },
    on_attach = function(bufnr)
      local gitsigns = require 'gitsigns'

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      map('n', ']c', function()
        if vim.wo.diff then
          vim.cmd.normal { ']c', bang = true }
        else
          gitsigns.nav_hunk 'next'
        end
      end, { desc = 'Jump to next git [c]hange' })

      map('n', '[c', function()
        if vim.wo.diff then
          vim.cmd.normal { '[c', bang = true }
        else
          gitsigns.nav_hunk 'prev'
        end
      end, { desc = 'Jump to previous git [c]hange' })

      map('v', '<leader>gs', function() gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = '[G]it add -p ([s]tage hunk)' })
      map('v', '<leader>gr', function() gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = '[G]it restore -p ([r]eset hunk)' })

      map('n', '<leader>gs', gitsigns.stage_hunk, { desc = '[G]it add -p ([s]tage hunk)' })
      map('n', '<leader>gr', gitsigns.reset_hunk, { desc = '[G]it restore -p ([r]eset hunk)' })
      map('n', '<leader>gS', gitsigns.stage_buffer, { desc = '[G]it add % ([S]tage buffer)' })
      map('n', '<leader>gR', gitsigns.reset_buffer, { desc = '[G]it restore % ([R]eset buffer)' })
      map('n', '<leader>gu', gitsigns.undo_stage_hunk, { desc = '[G]it restore --staged ([u]ndo stage)' })
      map('n', '<leader>gp', gitsigns.preview_hunk, { desc = '[G]it diff ([p]review hunk)' })
      map('n', '<leader>gi', gitsigns.preview_hunk_inline, { desc = '[G]it diff ([i]nline preview)' })
      map('n', '<leader>gb', function() gitsigns.blame_line { full = true } end, { desc = '[G]it [b]lame line' })
      map('n', '<leader>gd', gitsigns.diffthis, { desc = '[G]it [d]iff (against index)' })
      map('n', '<leader>gD', function() gitsigns.diffthis '@' end, { desc = '[G]it [D]iff HEAD (last commit)' })

      map('n', '<leader>gQ', function() gitsigns.setqflist 'all' end, { desc = '[G]it status ([Q]uickfix all files)' })
      map('n', '<leader>gq', gitsigns.setqflist, { desc = '[G]it status ([q]uickfix current file)' })
      map({ 'o', 'x' }, 'ih', gitsigns.select_hunk)
    end,
  },
}
