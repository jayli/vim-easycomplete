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

function speed.complete_menu_filter(matching_res, word)
  local fullmatch_result = {} -- 完全匹配
  local firstchar_result = {} -- 首字母匹配
  local fuzzymatching = matching_res[1]
  local fuzzy_position = matching_res[2]
  local fuzzy_scores = matching_res[3]
  local fuzzymatch_result = {}

  for i, item in ipairs(fuzzymatching) do
    if item["abbr"] == nil or item["abbr"] == "" then
      item["abbr"] = item["word"]
    end
    local abbr = item["abbr"]
    abbr = speed.parse_abbr(abbr)
    item["abbr"] = abbr
    local p = fuzzy_position[i]
    item["abbr_marked"] = speed.replacement(abbr, p, "§")
    item["marked_position"] = p
    item["score"] = fuzzy_scores[i]
    if string.find(string.lower(item["word"]), string.lower(word)) == 1 then
      table.insert(fullmatch_result, item)
    elseif string.lower(string.sub(item["word"],1,1)) == string.lower(string.sub(word,1,1)) then
      table.insert(firstchar_result, item)
    else
      table.insert(fuzzymatch_result, item)
    end
  end

  local stunt_items = vim.fn["easycomplete#GetStuntMenuItems"]()

  if #stunt_items == 0 and vim.g.easycomplete_first_complete_hit == 1 then
    table.sort(fuzzymatch_result, function(a, b)
      return #a.word < #b.word -- 按 word 字段的长度升序排序
    end)
  end

  local filtered_menu = {}
  for _, v in ipairs(fullmatch_result) do table.insert(filtered_menu, v) end
  for _, v in ipairs(firstchar_result) do table.insert(filtered_menu, v) end
  for _, v in ipairs(fuzzymatch_result) do table.insert(filtered_menu, v) end
  return filtered_menu
end

return speed
