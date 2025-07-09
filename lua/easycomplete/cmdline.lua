local util = require("easycomplete.util")
local console = util.console
-- cmdline_start_cmdpos 是不带偏移量的，偏移量只给 pum 定位用
local cmdline_start_cmdpos = 0
local old_cmdline = ""
local pum_noselect = vim.g.easycomplete_pum_noselect
local this = {}

function this.pum_complete(start_col, menu_items)
  vim.g.easycomplete_pum_noselect = 1
  vim.fn["easycomplete#pum#complete"](start_col, menu_items)
end

function this.pum_redraw()
  if vim.fn.has('nvim-0.10') then
    local pum_bufid = this.pum_bufid()
    vim.api.nvim__redraw({
      buf = pum_bufid,
      flush = true
    })
  else
    vim.cmd("redraw")
  end
end

function this.pum_close()
  vim.fn["easycomplete#pum#close"]()
  vim.g.easycomplete_pum_noselect = pum_noselect
end

function this.pum_bufid()
  local pum_bufid = vim.fn['easycomplete#pum#bufid']()
  return pum_bufid
end

function this.pum_winid()
  local pum_winid = vim.fn['easycomplete#pum#winid']()
  return pum_winid
end

function this.get_typing_word()
  return vim.fn['easycomplete#util#GetTypingWord']()
end

function this.get_buf_keywords(typing_word)
  local items_list = vim.fn['easycomplete#sources#buf#GetBufKeywords'](typing_word)
  local distinct_items = util.distinct(items_list)
  return distinct_items
end

function this.calculate_sign_and_linenr_width()
  local width = 0
  -- 检查是否有 sign 列
  local signcolumn = vim.api.nvim_win_get_option(0, "signcolumn")
  if signcolumn == "yes" or signcolumn == "auto" or signcolumn == "number" then
    width = width + 2 -- sign 列通常占据 2 个字符宽度
  end
  -- 检查是否显示行号
  if vim.wo.number or vim.wo.relativenumber then
    -- 计算行号的最大宽度
    local max_num_width = #tostring(vim.fn.line("$"))
    width = width + max_num_width
  end
  return width
end

function this.flush()
  vim.g.easycomplete_cmdline_pattern = ""
  vim.g.easycomplete_cmdline_typing = 0
  cmdline_start_cmdpos = 0
  this.pum_close()
end

function this.pum_visible()
  return vim.fn["easycomplete#pum#visible"]()
end

function this.pum_selected()
  return vim.fn['easycomplete#pum#CompleteCursored']()
end

function this.pum_selected_item()
  return vim.fn['easycomplete#pum#CursoredItem']()
end

function this.select_next()
  vim.fn['easycomplete#pum#next']()
  util.zizz()
  local new_whole_word = this.get_tab_returing_opword()
  return new_whole_word
end

function this.select_prev()
  vim.fn['easycomplete#pum#prev']()
  util.zizz()
  local new_whole_word = this.get_tab_returing_opword()
  return new_whole_word
end

-- Tab 切换 pum 选项的动作
function this.get_tab_returing_opword()
  local backing_count = vim.fn.getcmdpos() - cmdline_start_cmdpos
  local oprator_str = string.rep("\b", backing_count)
  local new_whole_word = ""
  if this.pum_selected() then
    local item = this.pum_selected_item()
    local word = item.word
    new_whole_word = oprator_str .. word
  else
    new_whole_word = oprator_str
  end
  return new_whole_word
end

function this.bind_cmdline_event()
  local augroup = vim.api.nvim_create_augroup('CustomCmdlineComplete', { clear = true })

  vim.api.nvim_create_autocmd("CmdlineEnter", {
      group = augroup,
      pattern = ":",
      callback = function()
        vim.g.easycomplete_cmdline_pattern = ":"
      end,
    })
  vim.api.nvim_create_autocmd("CmdlineEnter", {
      group = augroup,
      pattern = "/",
      callback = function()
        vim.g.easycomplete_cmdline_pattern = "/"
      end,
    })

  vim.api.nvim_create_autocmd("CmdlineLeave", {
      group = augroup,
      callback = function()
        this.flush()
        vim.g.easycomplete_pum_noselect = pum_noselect
      end
    })

  vim.keymap.set("c", "<Tab>", function()
    return this.select_next()
  end, { expr = true, noremap = true })

  vim.keymap.set("c", "<S-Tab>", function()
    return this.select_prev()
  end, { expr = true, noremap = true })

  vim.on_key(function(keys, _)
    if vim.api.nvim_get_mode().mode ~= "c" then
      return
    end
    local key_str = vim.api.nvim_replace_termcodes(keys, true, false, true)
    vim.g.easycomplete_cmdline_typing = 1
    -- TODO 匹配模式闪烁问题没解决，先关闭
    if vim.g.easycomplete_cmdline_pattern == '/' then
      return
    end
    vim.defer_fn(function()
      vim.schedule(function()
        local ok, ret = pcall(this.cmdline_handler, keys, key_str)
        if not ok then
          print(ret)
        end
      end)
    end, 10)
    if key_str == '\r' then
      if this.cr_handler() then
        return -- 执行回车
      else
        return "" -- 阻止回车
      end
    end
  end)
end

function this.normalize_list(arr, word)
  if #arr == 0 then return arr end
  local ret = {}
  for index, value in ipairs(arr) do
    if type(value) == "table" then
      table.insert(ret, {
          word = value["word"],
          abbr = value["abbr"],
          kind = value["kind"],
          menu = value["menu"],
        })
    else
      table.insert(ret, {
          word = arr[index],
          abbr = arr[index],
          kind = vim.g.easycomplete_kindflag_cmdline,
          menu = vim.g.easycomplete_menuflag_cmdline,
        })
    end
  end
  local filtered_items = vim.fn['easycomplete#util#CompleteMenuFilter'](ret, word, 500)
  return filtered_items
end

function this.cmdline_handler(keys, key_str)
  if vim.g.easycomplete_cmdline_pattern == "" then
    return
  end
  if util.zizzing() then return end
  local cmdline = vim.fn.getcmdline()
  cmdline_start_cmdpos = 0
  -- console(string.byte(key_str), vim.g.easycomplete_cmdline_pattern)
  if string.byte(key_str) == 9 then
    -- console("Tab 键")
  elseif string.byte(key_str) == 32 then
    -- console("空格键")
    -- this.pum_close()
    this.do_complete()
  elseif string.byte(key_str) == 128 and #cmdline == #old_cmdline then
    -- 方向键
    this.pum_close()
  elseif string.byte(key_str) == 128 and #cmdline == #old_cmdline - 1 then
    -- 退格键
    this.do_complete()
  elseif string.byte(key_str) == 8 then
    -- console("退格")
    this.do_complete()
  elseif string.byte(key_str) == 13 then
    -- console("回车")
  elseif string.byte(key_str) == 58 then
    -- console("冒号:")
    this.do_complete()
  elseif string.byte(key_str) == 95 then
    -- console("下划线_")
    this.do_complete()
  else
    -- console("其他键: " .. keys)
    this.do_complete()
  end
  old_cmdline = cmdline
  this.pum_redraw()
end

function this.cr_handler()
  if this.pum_visible() and this.pum_selected() then
    this.pum_close()
    vim.defer_fn(function()
      if this.char_before_cursor() == "/" then
        this.do_path_complete()
      end
    end, 30)
    return false -- 阻止回车
  else
    return true -- 执行回车
  end
end

-- MAIN ROUTER
this.REG_CMP_HANDLER = {
  {
    -- cmdline 是空
    pattern = "^%s*$",
    get_cmp_items = function()
      return {}
    end
  },
  {
    -- 正在输入第一个命令
    pattern = "^[a-zA-Z0-9_]+$",
    get_cmp_items = function()
      if vim.g.easycomplete_cmdline_pattern == "/" then
        local typing_word = this.get_typing_word()
        local ret = this.get_buf_keywords(string.sub(typing_word, 1, 2))
        return ret
      elseif vim.g.easycomplete_cmdline_pattern == ":" then
        -- command 共有 670 多个，因为太重要了，这里不做过滤了，返回全部
        return this.get_all_commands()
      end
    end
  },
  {
    pattern = {
      "^[a-zA-Z0-9_]+%s$", -- 命令输入完毕，并敲击空格
      "^[a-zA-Z0-9_]+%s+[_%w]+$", -- 命令输入完毕，敲击空格后直接输入正常单词
      "^[a-zA-Z0-9_]+%s+[glbwtvas]:%w-$", -- 命令输入完毕，输入 x:y 变量
    },
    get_cmp_items = function()
      if vim.g.easycomplete_cmdline_pattern == "/" then
        return {}
      end
      local cmd_name = this.get_guide_cmd()
      local cmp_type = this.get_complition_type(cmd_name)
      local typing_word = this.get_typing_word()
      if cmp_type == "" then
        if typing_word == "" then
          return {}
        else -- 如果不是预设的命令，直接从buf取词，也做前两个字符的过滤
          local ret = this.get_buf_keywords(string.sub(typing_word, 1, 2))
          return ret
        end
      elseif typing_word == "" and (cmp_type == "expression" or cmp_type == "function") then
        -- expression 和 function 的返回结果太多了，太卡了，这里做一个限制，不做空匹配取全部了
        -- 这俩都有1800+个匹配项
        return {}
      else -- 最多情况的匹配
        local guide_str = ""
        if (cmp_type == "expression" or cmp_type == "function") then
          -- 带搜索词的匹配，根据第一个字符做一遍过滤
          guide_str = string.sub(typing_word, 1, 1)
        end
        local result = vim.fn.getcompletion(guide_str, cmp_type)
        -- user 的返回结果里有重复的
        if cmp_type == "user" then
          result = util.distinct(result)
        end
        -- Hack for file and file_in_path
        -- getcompletion 的路径结果中，给所有的当前目录加上./前缀
        -- 便于连续回车匹配
        if cmp_type == "file" or cmp_type == "file_in_path" then
          for i, item in ipairs(result) do
            if string.find(item, "^[^/]+/$") ~= nil then
              result[i] = "./" .. item
            end
          end
        end
        return result
      end
    end
  },
  {
    -- 输入路径
    pattern = {
      "^[a-zA-Z0-9_]+%s+.*/$",
      "^[a-zA-Z0-9_]+%s+.*/[a-zA-Z0-9_]+$",
      "^[a-zA-Z0-9_]+%s+/$"
    },
    get_cmp_items = function()
      if vim.g.easycomplete_cmdline_pattern == "/" then
        return {}
      else
        return this.get_path_cmp_items()
      end
    end
  },
  {
    -- 输入引号里的文本
    pattern = {
      "^[a-zA-Z0-9_]+%s+.*%\"[^\"]-$",
      "^[a-zA-Z0-9_]+%s+.*%\'[^\']-$",
    },
    get_cmp_items = function()
      if vim.g.easycomplete_cmdline_pattern == "/" then
        return {}
      end
      local typing_word = this.get_typing_word()
      if typing_word == "" then
        return {}
      else
        local ret = this.get_buf_keywords(string.sub(typing_word, 1, 1))
        return ret
      end
    end
  }
}

function this.do_path_complete()
  this.cmp_regex_handler(function()
    return this.get_path_cmp_items()
  end, this.get_typing_word())
  this.pum_redraw()
end

function this.get_path_cmp_items()
  local typing_path = vim.fn['easycomplete#sources#directory#TypingAPath']()
  -- 取根目录
  -- insert模式下为了避免和输入注释"//"频繁干扰，去掉了根目录的路径匹配
  -- 这里不存在这个频繁干扰的问题，再加回来
  if string.find(typing_path.prefx,"%s/$") ~= nil then
    typing_path.is_path = 1
  end
  if typing_path.is_path == 0 then
    return {}
  else
    local ret = vim.fn['easycomplete#sources#directory#GetDirAndFiles'](typing_path, typing_path.fname)
    return ret
  end
end

function this.get_complition_type(cmd_name)
  local cmd_type = ""
  for key, item in pairs(this.cmd_type) do
    if util.has_item(item, cmd_name) then
      cmd_type = key
      break
    end
  end
  return cmd_type
end

function this.do_complete()
  local word = this.get_typing_word()
  local matched_pattern = false
  for index, item in ipairs(this.REG_CMP_HANDLER) do
    if type(item.pattern) == "table" then
      for jndex, jtem in ipairs(item.pattern) do
        if this.cmd_match(jtem) then
          this.cmp_regex_handler(item.get_cmp_items, word)
          matched_pattern = true
          break
        end
      end
    else
      if this.cmd_match(item.pattern) then
        this.cmp_regex_handler(item.get_cmp_items, word)
        matched_pattern = true
      end
    end
    if matched_pattern == true then
      break
    end
  end
  if matched_pattern == false then
    this.pum_close()
  end
end

-- 根据某个正则表达式是否匹配，来调用既定的get_cmp_items，并执行complete()
function this.cmp_regex_handler(get_cmp_items, word)
  local start_col = vim.fn.getcmdpos() - this.calculate_sign_and_linenr_width() - #word
  cmdline_start_cmdpos = vim.fn.getcmdpos() - #word
  local ok, menu_items = pcall(get_cmp_items)
  if not ok then
    print("[jayli debug] ".. menu_items)
    this.pum_close()
  elseif menu_items == nil or #menu_items == 0 then
    this.pum_close()
  else
    -- console(">>> 匹配项个数", #menu_items)
    this.pum_complete(start_col, this.normalize_list(menu_items, word))
  end
end

-- 获得所有command list
function this.get_all_commands()
  local all_commands = {}
  local tmp_items = vim.fn.getcompletion("", "command")
  for index, value in ipairs(tmp_items) do
    if string.match(value, "^[_a-zA-Z0-9]") then
      table.insert(all_commands, value)
    end
  end
  return all_commands
end

function this.cmdline_before_cursor()
  local cmdline_all = vim.fn.getcmdline()
  local cmdline_typed = util.trim_before(string.sub(cmdline_all, 1, vim.fn.getcmdpos() - 1))
  return cmdline_typed
end

function this.char_before_cursor()
  local cmdline_all = vim.fn.getcmdline()
  local char = string.sub(cmdline_all, vim.fn.getcmdpos() - 1, vim.fn.getcmdpos() - 1)
  return char
end

-- 获得 cmdline 中的命令
-- 不管有没有输入完整，都返回
function this.get_guide_cmd()
  local cmdline_typed = this.cmdline_before_cursor()
  local cmdline_tb = vim.split(cmdline_typed, "%s+")
  if #cmdline_tb == 0 then
    return ""
  else
    return cmdline_tb[1]
  end
end

-- 判断当前输入命令字符串是否完全匹配rgx
-- 只获取光标前的字符串
function this.cmd_match(rgx)
  local cmdline_typed = this.cmdline_before_cursor()
  local ret = string.find(cmdline_typed, rgx)
  if ret == nil then -- 不匹配
    return false
  elseif ret == 1 then -- 从头匹配
    return true
  else -- 不从头匹配
    return false
  end
end

this.cmd_type = {
  -- File completion
  file = {
    'edit', 'read', 'write','saveas',
    'source','split', 'vsplit', 'tabedit',
    'diffsplit', 'diffpatch', 'explore',
    'lexplore', 'sexplore', 'vexplore',
    'argadd', 'argdelete', 'argdo'
  },
  file_in_path = { 'find', 'sfind', 'tabfind' },
  -- Directory completion
  dir = { 'cd', 'lcd', 'tcd', 'chdir' },
  -- Buffer completion
  buffer = {
    'buffer', 'bdelete', 'bwipeout',
    'bnext', 'bprevious', 'bfirst',
    'blast', 'sbuffer', 'sball',
  },
  diff_buffer = { 'diffthis', 'diffoff', 'diffupdate' },
  command = { 'command', 'delcommand' },
  option = { 'set', 'setlocal', 'setglobal' },
  help = { 'help' },
  expression = {
    'substitute', 'global', 'vglobal', 'let',
    'echo', 'echom', 'echon',
  },
  tag = {
    'tag', 'stag', 'tselect', 'tjump',
    'tlast', 'tnext', 'tprev', 'tunmenu',
  },
  arglist = { 'args' },
  ['function'] = { 'function', 'delfunction', 'call'},
  mapping = {
    'map', 'noremap', 'unmap',
    'nmap', 'vmap', 'imap', 'cmap',
    'nunmap', 'vunmap', 'iunmap', 'cunmap',
  },
  event     = { 'autocmd', 'doautocmd', 'doautoall' },
  augroup   = { 'augroup' },
  shellcmd  = { 'terminal' },
  color     = { 'colorscheme' },
  compiler  = { 'compiler' },
  filetype  = { 'filetype' },
  highlight = { 'highlight' },
  history   = { 'history' },
  lua       = { 'lua' },
  messages  = { 'messages' },
  packadd   = { 'packadd' },
  register  = { 'register' },
  runtime   = { 'runtime' },
  sign      = { 'sign' },
  syntax    = { 'syntax' },
  user      = { 'user' }
}

function this.init_once()
  if vim.g.easycomplete_cmdline ~= 1 then
    return
  end
  -- debug start -----------------------------
  -- do return end
  -- console(1)
  --------------------------------------------
  vim.g.easycomplete_cmdline_pattern = ""
  vim.g.easycomplete_cmdline_typing = 0
  this.bind_cmdline_event()
end

return this
