local autopair = require "easycomplete.autopair"
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

  if vim.g.AutoPairsMapSpace and vim.g.AutoPairsMapSpace == 1 then
    vim.on_key(function(keys, _)
      autopair.hack_pair_input(keys)
    end)
  end
end

return M
