

local module = {}

function module.api()

  vim.api.nvim_command("echom 123")
  vim.fn["easycomplete#ui#api"]()

end


return module
