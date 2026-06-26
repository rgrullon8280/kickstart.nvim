-- Treesitter: Neovim 0.12 has built-in highlighting/injections/folds; this plugin
-- installs parsers and queries and provides experimental indent.
-- https://github.com/nvim-treesitter/nvim-treesitter

local parsers = {
  'bash',
  'c',
  'diff',
  'html',
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'query',
  'vim',
  'vimdoc',
  'go',
  'python',
  'sql',
}

local vim_regex_filetypes = { ruby = true, sql = true }
local no_ts_indent_filetypes = { ruby = true, sql = true }

return {
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  build = ':TSUpdate',
  config = function()
    require('nvim-treesitter').setup()

    -- Install missing parsers asynchronously (replaces old ensure_installed / auto_install).
    require('nvim-treesitter').install(parsers)

    vim.api.nvim_create_autocmd('FileType', {
      desc = 'Start treesitter highlighting and optional indent',
      callback = function(args)
        local bufnr = args.buf
        local ft = vim.bo[bufnr].filetype
        if ft == '' then
          return
        end

        if not pcall(vim.treesitter.start, bufnr) then
          return
        end

        if vim_regex_filetypes[ft] then
          vim.bo[bufnr].syntax = 'ON'
        end

        if not no_ts_indent_filetypes[ft] then
          vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
