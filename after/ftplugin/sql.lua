local bufnr = vim.api.nvim_get_current_buf()

vim.schedule(function()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  if vim.bo[bufnr].filetype ~= 'sql' then
    return
  end

  require('custom.sql_indent').attach(bufnr)
end)
