

local EasyComplete = {}

function foo()
  vim.api.nvim_command("echom 123")
  vim.fn["easycomplete#lua#api"]()
  vim.fn["easycomplete#lua#test"]()
  console(1,2,3)
end

function console__(...)
  local args = {...}
  for i,v in ipairs{...} do
    print(i,v)
  end
  print('sss',args)
end

function console(...)
  local args = {...}
  local params = {}

  for i = 1, #args do
    print(args[i])
  end

  vim.fn['easycomplete#log#log']({...})
end

function EasyComplete.init()
  console(1,1,2,9, "sdf")
  console('------------------------')
  console('xcv')
  console(table)
end

return EasyComplete

