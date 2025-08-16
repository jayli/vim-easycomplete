local util = require "easycomplete.util"
local console = util.console
local M = {}
local input_chars_vec = {}
local auto_pair_funcs = {
  "=AutoPairsInsert("
}

local function match_autopair_func()
  local matched = false
  for _, value in ipairs(auto_pair_funcs) do
    
  end




end

function M.hack_pair_input(keys)
  return
  if #input_chars_vec > 40 then
    table.remove(input_chars_vec,1)
  end
  table.insert(input_chars_vec, keys)
  console(">>",keys)
end

return M
