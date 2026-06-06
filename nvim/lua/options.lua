vim.o.relativenumber = true

vim.o.mouse = ""

vim.o.showmode = false

vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true

vim.o.breakindent = true

vim.o.autoindent = true
vim.o.smartindent = true

vim.o.undofile = true

vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.signcolumn = 'yes'

vim.o.updatetime = 250

vim.o.timeoutlen = 300

vim.o.splitright = true
vim.o.splitbelow = true

vim.o.list = true
vim.opt.listchars = { 
  tab = '» ', 
  trail = '·', 
  nbsp = '␣',
  leadmultispace = '│ ',
}

vim.o.inccommand = 'split'

vim.o.cursorline = true

vim.o.scrolloff = 10

vim.o.confirm = true
