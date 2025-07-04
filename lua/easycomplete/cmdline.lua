local util = require "easycomplete.util"
local console = util.console
local normal_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRST0123456789#$_"
-- cmdline_start_cmdpos 是不带偏移量的，偏移量只给 pum 定位用
local cmdline_start_cmdpos = 0
local completeopt = vim.o.completeopt
local this = {}

function this.pum_complete(start_col, menu_items)
  vim.opt.completeopt:append("noselect")
  vim.fn["easycomplete#pum#complete"](start_col, menu_items)
end

function this.pum_close()
  vim.fn["easycomplete#pum#close"]()
  vim.opt.completeopt = completeopt
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
        vim.o.completeopt = completeopt
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
    table.insert(ret, {
        word = arr[index],
        abbr = arr[index],
        kind = vim.g.easycomplete_kindflag_cmdline,
        menu = vim.g.easycomplete_menuflag_cmdline,
      })
  end
  return vim.fn['easycomplete#util#CompleteMenuFilter'](ret, word, 500)
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
    this.pum_close()
  elseif string.byte(key_str) == 8 or string.byte(key_str) == 128 then
    -- console("退格键被按下")
    this.do_complete()
  elseif string.byte(key_str) == 13 then
    -- console("回车键被按下")
    this.pum_close()
  else
    -- console("其他键被按下: " .. keys)
    this.do_complete()
  end
  vim.cmd("redraw")
end

this.REG_CMP_HANDLER = {
  {
    -- 空
    pattern = "^%s*$",
    get_cmd_items = function()
      return {}
    end
  },
  {
    -- 正在输入命令
    pattern = "^[a-zA-Z0-9_]+$",
    get_cmp_items = function()
      return this.get_all_commands()
    end
  },
  {
    -- 命令输入完毕，并敲击空格
    pattern = "^[a-zA-Z0-9_]+%s",
    get_cmp_items = function()
    end
  }
}

function this.do_complete()
  local word = this.get_typing_word()
  for index, item in ipairs(this.REG_CMP_HANDLER) do
    if this.cmd_match(item.pattern) then
      local start_col = vim.fn.getcmdpos() - this.calculate_sign_and_linenr_width() - #word
      cmdline_start_cmdpos = vim.fn.getcmdpos() - #word
      local ok, menu_items = pcall(item.get_cmp_items)
      if not ok then
        this.pum_close()
      elseif menu_items == nil or #menu_items == 0 then
        this.pum_close()
      else
        this.pum_complete(start_col, this.normalize_list(menu_items, word))
      end
      break
    end
  end
  do return end
  -------------------------------------------
  -- local word = this.get_typing_word()
  -- if word == "" then
  --   this.pum_close()
  -- else
  --   local start_col = vim.fn.getcmdpos() - this.calculate_sign_and_linenr_width() - #word
  --   cmdline_start_cmdpos = vim.fn.getcmdpos() - #word
  --   local menu_items = this.get_cmp_items()
  --   if menu_items == nil or #menu_items == 0 then
  --     this.pum_close()
  --   else
  --     this.pum_complete(start_col, this.normalize_list(menu_items, word))
  --   end
  -- end
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

-- 路由 TODO: 命令跟一个空格也应该直接弹出菜单
function this.get_cmp_items()
  if this.typing:cmd() then
    return this.get_all_commands()
  elseif this.typing:file() then
    return vim.fn.getcompletion("", "file")
  elseif this.typing:buffer() then
    return {}
  elseif this.typing:fun() then
    return {}
  else
    return {}
  end
end

function this.cmdline_before_cursor()
  local cmdline_all = vim.fn.getcmdline()
  local cmdline_typed = util.trim_before(string.sub(cmdline_all, 1, vim.fn.getcmdpos()))
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

this.typing = {
  -- 正在输入命令
  cmd = function()
    return this.cmd_match("^[a-zA-Z0-9_]+$")
  end,
  -- 正在输入路径
  file = function()
    local cmd_name = this.get_guide_cmd()
    if this.cmd_match("^[a-zA-Z0-9_]+%s") and
       util.has_item(this.cmd_type.file, cmd_name) then
      return true
    else
      return false
    end
  end,
  -- 正在输入buf
  buffer = function()
  end,
  -- 正在输入函数
  fun = function ()
  end
}

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
    'find',
    'sfind',
    'tabfind'
  }
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
  -- console(1)
  -- TODO here -----------------------------
  vim.g.easycomplete_cmdline_pattern = ""
  vim.g.easycomplete_cmdline_typing = 0
  this.bind_cmdline_event()
end

return this
