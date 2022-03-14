

local module = {}

function module.api()

  vim.api.nvim_command("echom 123")
  vim.fn["easycomplete#lua#api"]()

end


return module
