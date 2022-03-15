local EasyComplete = {}
local debug = false

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
end

function EasyComplete.typing()
  console(print(vim.api.nvim_command("echo v:char")))
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
  if vim.api.nvim_get_var('easycomplete_kindflag_buf') == "羅" and debug == true then
    main()
  else
    return
  end
end

return EasyComplete

