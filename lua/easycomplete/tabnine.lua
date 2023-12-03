local Export = {}
local tabnine_ns = vim.api.nvim_create_namespace('tabnine_ns')

-- local code_block = [[
-- for line in code_block:gmatch("[^\r\n]+") do
--   table.insert(lines, {{line, "Comment"}})
-- end
-- ]]


-- code_block 是一个字符串，有可能包含回车符
-- call v:lua.require("easycomplete.tabnine").show_hint()
function Export.show_hint(code_block)
  local lines = {}
  for line in code_block:gmatch("[^\r\n]+") do
    table.insert(lines, {{line, "NonText"}})
  end

  local virt_text = lines[1]
  local virt_lines

  -- print(#lines)
  if #lines >= 2 then
    table.remove(lines, 1)
    virt_lines = lines
  else
    virt_lines = nil
  end

  vim.api.nvim_buf_set_extmark(0, tabnine_ns, vim.fn.line('.') - 1, vim.fn.col('.') - 1, {
    id = 1,
    virt_text_pos = "overlay",
    virt_text = virt_text,
    virt_lines = virt_lines
  })

end

function Export.delete_hint()
  vim.api.nvim_buf_del_extmark(0, tabnine_ns, 1)
end

return Export
