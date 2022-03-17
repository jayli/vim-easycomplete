-- local debug = true
local EasyComplete = {}

-- all in all 入口
function main()
  vim.cmd([[
    autocmd TextChangedI * lua require("easycomplete").typing()
  ]])
  console(1,1,2,9, "sdf")
  console('------------------------')
  console('xcv')
  console(table)
  console__(1,2,3)
  foo()
  console("=================================")
  vim.cmd([[
    autocmd CompleteChanged * lua require("easycomplete").complete_changed()
  ]])
end

function EasyComplete.complete_changed()
  console('--',get(vim.v.event, "completed_item", "user_data"))
end

function get(a, ...)
  local args = {...}
  if type(a) ~= "table" then
    return a
  end
  local tmp_obj = a
  for i = 1, #args do
    tmp_obj = tmp_obj[args[i]]
    if type(tmp_obj) == nil then
      break
    end
  end
  return tmp_obj
end

function EasyComplete.typing(...)

  local ctx = vim.fn['easycomplete#context']()

  print({
    console(vim.v.event)
  })

  print({
    pcall(function()
      console { aaa = 123 , bb = 456 }
      local aaa = vim.api.nvim_command("echo g:easycomplete_default_plugin_init")
    end)
  })

end

function foo()
  vim.api.nvim_command("echom 123")
  vim.fn["easycomplete#lua#api"]()
  vim.fn["easycomplete#lua#test"]()
  console(1,2,3,4,5,6)
  for i=1,80 do
    console(math.random())
  end
  console('>>---------------')
end

function console__(...)
  local args = {...}
  for i,v in ipairs{...} do
    print(i,v)
  end
  print('sss',args)
end

function EasyComplete.init()
  console = vim.fn['easycomplete#log#log']
  log = vim.fn["easycomplete#util#info"]
  if vim.api.nvim_get_var('easycomplete_kindflag_buf') == "羅" and debug == true then
    main()
  else
    return
  end
end

return EasyComplete

