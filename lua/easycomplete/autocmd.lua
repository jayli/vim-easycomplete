local M = {}

function M.init_once()
  local augroup = vim.api.nvim_create_augroup('CustomNvimInsertingAction', { clear = true })

  vim.api.nvim_create_autocmd("TextChangedI", {
      group = augroup,
      callback = function()
        vim.fn["easycomplete#TextChangedI"]()
      end,
    })

  vim.api.nvim_create_autocmd("TextChangedP", {
      group = augroup,
      callback = function()
        vim.fn["easycomplete#TextChangedP"]()
      end,
    })

  vim.api.nvim_create_autocmd("InsertCharPre", {
      group = augroup,
      callback = function()
        vim.fn["easycomplete#InsertCharPre"]()
      end,
    })
end

return M
