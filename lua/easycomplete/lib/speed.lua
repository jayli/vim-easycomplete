local speed = {}

function speed.replacement(abbr, positions, wrap_char)
  -- 转换为字符数组（字符串 -> 字符表）
  local letters = {}
  for i = 1, #abbr do
    -- lua 的 string.sub 是根据字节长度取下表对应的字符，而不是字符长度
    -- 因此对于 unicode 字符就取不正确，需要用 vim.fn.strcharpart 代替
    -- letters[i] = abbr:sub(i, i)
    letters[i] = vim.fn.strcharpart(abbr, i - 1, 1)
  end
  -- 对每个位置进行包裹处理
  for _, idx in ipairs(positions) do
    if idx >= 0 and idx < #letters then
      letters[idx+1] = wrap_char .. letters[idx+1] .. wrap_char
    end
  end
  -- 合并成新字符串
  local res_o = table.concat(letters)
  local res_r = string.gsub(res_o, "%" .. wrap_char .. "%" .. wrap_char, "")
  return res_r
end

function speed.parse_abbr(abbr)
  local max_length = vim.g.easycomplete_pum_maxlength
  if #abbr <= max_length then
    if vim.g.easycomplete_pum_fix_width == 1 then
      local spaces = string.rep(" ", max_length - #abbr)
      return abbr .. spaces
    else
      return abbr
    end
  else
    local short_abbr = string.sub(abbr, 1, max_length - 1) .. "…"
    return short_abbr
  end
end

return speed
