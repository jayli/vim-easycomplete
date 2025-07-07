local util = require "easycomplete.util"
local console = util.console
local errlog = util.errlog
-- cmdline_start_cmdpos 是不带偏移量的，偏移量只给 pum 定位用
local cmdline_start_cmdpos = 0
local old_cmdline = ""
local pum_noselect = vim.g.easycomplete_pum_noselect
local this = {}

function this.pum_complete(start_col, menu_items)
  vim.g.easycomplete_pum_noselect = 1
  vim.fn["easycomplete#pum#complete"](start_col, menu_items)
end

function this.pum_close()
  vim.fn["easycomplete#pum#close"]()
  vim.g.easycomplete_pum_noselect = pum_noselect
end

function this.get_typing_word()
  return vim.fn['easycomplete#util#GetTypingWord']()
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
    width = width + max_num_width + 1 -- 加 1 是为了考虑空隙或者额外的字符
  end

  return width
end

function this.flush()
  vim.g.easycomplete_cmdline_pattern = ""
  vim.g.easycomplete_cmdline_typing = 0
  cmdline_start_cmdpos = 0
  this.pum_close()
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
    vim.defer_fn(function()
      vim.schedule(function()
        local ok, ret = pcall(this.cmdline_handler, keys, key_str)
        if not ok then
          print(ret)
        end
      end)
    end, 10)
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
  if string.byte(key_str) == 9 then
    -- console("Tab 键被按下")
  elseif string.byte(key_str) == 32 then
    -- console("空格键被按下")
    -- this.pum_close()
    this.do_complete()
  elseif string.byte(key_str) == 128 and #cmdline == #old_cmdline then
    -- 方向键
    this.pum_close()
  elseif string.byte(key_str) == 128 and #cmdline == #old_cmdline - 1 then
    -- 退格键
    this.do_complete()
  elseif string.byte(key_str) == 8 then
    -- console("退格键被按下")
    this.do_complete()
  elseif string.byte(key_str) == 13 then
    -- console("回车键被按下")
    this.pum_close()
  else
    -- console("其他键被按下: " .. keys)
    this.do_complete()
  end
  old_cmdline = cmdline
  vim.cmd("redraw")
end

-- MAIN ROUTER
this.REG_CMP_HANDLER = {
  {
    -- cmdline 是空
    pattern = "^%s*$",
    get_cmd_items = function()
      return {}
    end
  },
  {
    -- 正在输入第一个命令
    pattern = "^[a-zA-Z0-9_]+$",
    get_cmp_items = function()
      return this.get_all_commands()
    end
  },
  {
    pattern = {
      "^[a-zA-Z0-9_]+%s$", -- 命令输入完毕，并敲击空格
      "^[a-zA-Z0-9_]+%s+%w+$" -- 命令输入完毕，敲击空格后直接输入单词
    },
    get_cmp_items = function()
      local cmd_name = this.get_guide_cmd()
      local cmp_type = this.get_complition_type(cmd_name)
      if cmp_type == "" then
        return {}
      else
        local result = vim.fn.getcompletion("", cmp_type)
        return result
      end
    end
  },
  {
    -- 输入路径
    pattern = {
      "^[a-zA-Z0-9_]+%s+.*/$",
      "^[a-zA-Z0-9_]+%s+.*/[a-zA-Z0-9_]+$"
    },
    get_cmp_items = function()
      local typing_path = vim.fn['easycomplete#sources#directory#TypingAPath']()
      if typing_path.is_path == 0 then
        return {}
      else
        -- 这里原来就不提供模糊匹配？
        local ret = vim.fn['easycomplete#sources#directory#GetDirAndFiles'](typing_path, typing_path.fname)
        local result = this.path_dir_normalize(ret)
        return ret
      end
    end
  }
}

-- 在路径匹配中，正文中tab匹配一个目录会自动带上'/'，方便回车后继续匹配下级目录
-- 在cmdline中按回车是执行的意思，所以这里保持了原生menu行为习惯，即Tab出菜单和
-- 选择下一个，回车是执行，因此这里就把目录末尾的"/"去掉了，让用户去输入，以便
-- 做到连续的逐级匹配
function this.path_dir_normalize(ret)
  for index, item in ipairs(ret) do
    item.word = string.gsub(item.word, "/$", "")
  end
  return ret
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

function this.log(str)
  this.pum_complete(1, this.normalize_list({str}, ""))
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

-- 正在输入buffer
-- 正在输入路径
-- 正在输入函数
-- 正在输入文本
-- 正在输入color
-- 正在输入...

function this.get_completion_type()
  local cmdline = vim.fn.getcmdline()
  local cmd_name = string.match(cmdline, "([^%s]+)")
  if cmd_name == nil then
    return nil
  end
  local cmd_type = ""
  for key, value in pairs(this.commands_type) do
    if cmd_name == key then
      cmd_type = value
      break
    end
  end
  return cmd_type
end

this.cmd_type = {
  file = {
    'edit',
    'read',
    'write',
    'saveas',
    'source',
    'split',
    'vsplit',
    'tabedit',
    'diffsplit',
    'diffpatch',
    'explore',
    'lexplore',
    'sexplore',
    'vexplore',
  },
  file_in_path = {
    'find',
    'sfind',
    'tabfind'
  },
}

this.commands_type = {
  -- File completion
  edit = 'file',
  read = 'file',
  write = 'file',
  saveas = 'file',
  source = 'file',
  split = 'file',
  vsplit = 'file',
  tabedit = 'file',
  diffsplit = 'file',
  diffpatch = 'file',
  explore = 'file',
  lexplore = 'file',
  sexplore = 'file',
  vexplore = 'file',
  find = 'file_in_path',
  sfind = 'file_in_path',
  tabfind = 'file_in_path',
  -- Directory completion
  cd = 'dir',
  lcd = 'dir',
  tcd = 'dir',
  chdir = 'dir',
  -- Buffer completion
  buffer = 'buffer',
  bdelete = 'buffer',
  bwipeout = 'buffer',
  bnext = 'buffer',
  bprevious = 'buffer',
  bfirst = 'buffer',
  blast = 'buffer',
  sbuffer = 'buffer',
  sball = 'buffer',
  diffthis = 'diff_buffer',
  diffoff = 'diff_buffer',
  diffupdate = 'diff_buffer',
  -- Command completion
  command = 'command',
  delcommand = 'command',
  -- Option completion
  set = 'option',
  setlocal = 'option',
  setglobal = 'option',
  -- Help completion
  help = 'help',
  -- Expression completion
  substitute = 'expression',
  global = 'expression',
  vglobal = 'expression',
  let = 'expression',
  echo = 'expression',
  -- Tag completion
  tag = 'tag',
  stag = 'tag',
  tselect = 'tag',
  tjump = 'tag',
  tlast = 'tag',
  tnext = 'tag',
  tprev = 'tag',
  tunmenu = 'tag',
  -- Argument completion
  args = 'arglist',
  argadd = 'file',
  argdelete = 'file',
  argdo = 'file',
  -- User completion (for user-defined functions/commands)
  ['function'] = 'function',
  delfunction = 'function',
  -- Mapping completion
  map = 'mapping',
  noremap = 'mapping',
  unmap = 'mapping',
  nmap = 'mapping',
  vmap = 'mapping',
  imap = 'mapping',
  cmap = 'mapping',
  nunmap = 'mapping',
  vunmap = 'mapping',
  iunmap = 'mapping',
  cunmap = 'mapping',
  -- Autocmd completion
  autocmd = 'event',
  augroup = 'augroup',
  doautocmd = 'event',
  doautoall = 'event',
  -- Shell command completion
  terminal = 'shellcmd',
  ['!'] = 'shellcmd',
  -- Misc
  ['='] = 'lua',
  colorscheme = 'color',
  compiler = 'compiler',
  filetype = 'filetype',
  highlight = 'highlight',
  history = 'history',
  lua = 'lua',
  messages = 'messages',
  packadd = 'packadd',
  register = 'register',
  runtime = 'runtime',
  sign = 'sign',
  syntax = 'syntax',
  user = 'user',
}

function this.init_once()
  -- TODO here -----------------------------
  do return end
  -- errlog(1)
  -- TODO here -----------------------------
  vim.g.easycomplete_cmdline_pattern = ""
  vim.g.easycomplete_cmdline_typing = 0
  this.bind_cmdline_event()
end

return this
