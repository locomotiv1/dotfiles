return {
  {
    'akinsho/bufferline.nvim',
    dependencies = 'nvim-tree/nvim-web-devicons',
    lazy = false,
    -- Define your keymaps here
    keys = {
      -- Use Shift-h and Shift-l to cycle through buffers
      { '<S-h>', '<cmd>BufferLineCyclePrev<cr>', desc = 'Prev Buffer' },
      { '<S-l>', '<cmd>BufferLineCycleNext<cr>', desc = 'Next Buffer' },

      -- Close the current buffer
      { '<leader>c', '<cmd>bdelete<cr>', desc = '[C]lose Buffer' },
    },
    config = function()
      -- Set termguicolors before loading bufferline
      vim.opt.termguicolors = true

      require('bufferline').setup {
        options = {
          -- This removes the 'X' button from each individual buffer tab
          show_buffer_close_icons = false,

          -- This removes the single 'X' button at the far top-right of the screen
          show_close_icon = false,
        },
      }
    end,
  },
}
