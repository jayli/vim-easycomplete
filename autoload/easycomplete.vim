" File:         easycomplete.vim
" Author:       @jayli <https://github.com/jayli/>
" Description:  The extreme simple complete plugin for vim
"
"               更多信息：
"                   <https://github.com/jayli/vim-easycomplete>

if get(g:, 'easycomplete_script_loaded')
  finish
endif
let g:easycomplete_script_loaded = 1

function! s:InitLocalVars()
  " 全局存储安装的插件
  let g:easycomplete_source  = {}
  " complete 匹配过的单词的存储，用来后退时回显completemenu
  let g:easycomplete_menucache = {}
  " 当前 complete 匹配完成的存储，补 info 时补充到这里, CompleteDone 后置空
  let g:easycomplete_menuitems = []
  " pum 展开时记录 v:event.completed_item
  " 用来判断是否正在滑选completemenu中的项
  let g:easycomplete_completed_item = {}

  " hack，为了避免在 complete menu 中选择回到首项时触发 completeDone 事
  " 件，需要保存 ctx，触发 completeDone 时比对 ctx 判断事件是否正确发生
  let g:easycomplete_firstcomplete_ctx = {}

  " 只在敲入字符第一次匹配时去取 complete suggest items, 匹配菜单展开时的匹配
  " 动作都交给 CompleteChanged 来完成，这时只对第一次匹配的结果做过滤，而不在
  " 重新去取 complete suggestions
  "
  " 这样做参考了YCM，主要是性能考虑，避免频繁的 reload 和 suggestion 动作
  let g:easycomplete_first_complete_hit = 0

  " 暂存正在异步执行的每个 completor 任务，有返回后置标志位 done
  " 用来处理多个 completor 返回时机保持一致的问题
  " [
  "   {
  "     "ctx": {},
  "     "name": "ts",
  "     "condition": 0
  "     "done" : 0
  "   }
  " ]
  let g:easycomplete_complete_taskqueue = []

  " 当前敲入的字符存储
  let b:typing_key = 0

  " 当前是否正在敲入 <BS> 或者 <CR>
  let g:easycomplete_backing_or_cr = 0
  set completeopt-=menu
  set completeopt+=menuone
  set completeopt+=noselect
  " TODO width 不管用？
  set completepopup=width:90,highlight:Pmenu,border:off,align:menu
  set completeopt+=popup
  set completeopt-=longest
  set cpoptions+=B

  " UltiSnips 也用了 tab 键，重写写避免冲突
  " let g:UltiSnipsExpandTrigger = "<c-l>"
  " if g:UltiSnipsExpandTrigger == "<tab>"
  " endif
endfunction

" 初始化入口
function! easycomplete#Enable()
  " 加载每个 Buffer 时执行，buffer 的文件类型不同，插件理论上需要重新装载
  if exists("b:easycomplete_loaded_done")
    return
  endif
  let b:easycomplete_loaded_done= 1

  " 初始化全局变量
  call s:InitLocalVars()
  " 一定是 typing 的绑定在前，每个插件重写的command在后
  call s:BindingTypingCommand()
  " 初始化每个语言的插件配置
  call plugin#init()
  " 每个插件根据文件类型来调用初始化函数
  call s:ConstructorCalling()
  " 初始化 complete 缓存
  call s:SetupCompleteCache()
  " 设置 Pmenu 样式
  call ui#setScheme()
endfunction

function! s:SnipSupports()
  try
    call funcref("UltiSnips#RefreshSnippets")
  catch /^Vim\%((\a\+)\)\=:E700/
    return v:false
  endtry
  return v:true
endfunction

function! easycomplete#nill() abort
  return v:none " DO NOTHING
endfunction

function! easycomplete#GetBindingKeys()
  let l:key_liststr = 'abcdefghijklmnopqrstuvwxyz'.
                    \ 'ABCDEFGHIJKLMNOPQRSTUVWXYZ/.:>_'
  return l:key_liststr
endfunction

function! s:BindingTypingCommand()
  inoremap <silent><expr> <BS> easycomplete#backing()
  if s:SnipSupports() && g:UltiSnipsExpandTrigger == "<tab>"
    " 如果安装了 ultisnips ，因为 ultisnips 默认绑定 tab
    " 跟这里有冲突，因此需要先解除掉tab绑定
    iunmap <Tab>
  endif
  inoremap <silent><expr> <Tab>  easycomplete#CleverTab()
  inoremap <silent><expr> <S-Tab>  easycomplete#CleverShiftTab()
  inoremap <expr> <CR> easycomplete#TypeEnterWithPUM()

  augroup easycomplete#augroup
    autocmd!
    " typing 初始匹配
    autocmd TextChangedI * call easycomplete#typing()
    " typing Complete 过程中的匹配
    autocmd CompleteChanged * call easycomplete#CompleteChanged()
    autocmd CompleteDone * call easycomplete#CompleteDone()
    autocmd CursorHoldI * call easycomplete#CursorHoldI()
  augroup END
endfunction

" typing complete 过程中的匹配
function! s:CompleteTypingMatch()
  " 初始
  if !get(g:, 'easycomplete_first_complete_hit')
    return
  endif
  let word = s:GetTypingWord()
  " 加上这句 info 不生效，原因未知
  " let all_menu = deepcopy(g:easycomplete_menuitems)
  " 避免对 g:easycomplete_menuitems 直接操作
  " TODO 这里把 info ' ' 丢掉了 jayli 导致 info popup 出不来 jayli
  " 设置了 info ' ' 也 pop 不出来
  " 看样子是 info 不能是数组
  let g_easycomplete_menuitems = deepcopy([] + g:easycomplete_menuitems)
  let filtered_menu = s:CustomCompleteMenuFilter(g_easycomplete_menuitems, word)
  " CompleteChanged 事件过程中不允许 complete() 方法改变正在匹配中的 menulist
  " let res_menu = res_menu + [{"word":"aaaa","menu":"xx"}]
  let filtered_menu = map(filtered_menu,function("s:PrepareInfoPlaceHolder"))
  " 需要在 menulist 根据原匹配完成后再执行 complete()，因此这里必须需要异步
  call s:AsyncRun(function('s:SecondComplete'), [
        \   col('.') - strlen(word),
        \   filtered_menu,
        \   g_easycomplete_menuitems
        \ ], 0)
endfunction

function! s:PrepareInfoPlaceHolder(key, val)
  " 所有 Me.info 
  let a:val.info = "_"
  return a:val
endfunction

" FirstComplete: 第一次获取完整 suggestion 并做第一次匹配
" SecondComplete: 第二次只做列表匹配，不再重新获取 suggestion
function! s:SecondComplete(start_pos, menuitems, easycomplete_menuitems)
  let tmp_menuitems = a:easycomplete_menuitems
  " echom a:easycomplete_menuitems
  " 执行这一句会触发 completeDone 事件，会调用 s:flush 清空
  " g:easycomplete_menuitems，导致 info popup  失效
  " 因此这里在 complete 之后需要恢复原 easycomplete_menuitems
  call s:zizz()
  " call s:log('-------SecondComplete------------')
  " call s:log(a:menuitems)
  call complete(a:start_pos, a:menuitems)
  let g:easycomplete_menuitems = tmp_menuitems
endfunction

" 原始 Complete 匹配逻辑，用来做视觉占位，避免异步 complete 中的 menu 闪烁
function! s:NormalizedCompleteMenuFilter(all_menu, word)
  let result_menu_list = filter(deepcopy(a:all_menu),
        \ 'tolower(v:val.word) =~ "^'. tolower(a:word) . '"')
  return result_menu_list
endfunction

" 自定义匹配逻辑，匹配逻辑参照 YCY 和 coc
function! s:CustomCompleteMenuFilter(all_menu, word)
  let normalized_matching_menu = s:NormalizedCompleteMenuFilter(a:all_menu, a:word)
  return normalized_matching_menu + []
endfunction

function! easycomplete#CompleteDone()
  " 需要处理一下

  if pumvisible() || empty(v:completed_item)
    return
  endif

  " call log#log('easycomplete#CompleteDone')
  " call log#log(v:completed_item)
  " call log#log(complete_info())
  call s:flush()
endfunction

function! easycomplete#CursorHoldI()
  call s:flush()
endfunction

" 重置全局变量
function! s:flush()
  " 清空menuitems
  let g:easycomplete_menuitems = []
  " 重置 first_complete_hit 状态
  let g:easycomplete_first_complete_hit = 0
  " 重置当前选中的 complete item
  call s:ResetCompletedItem()
  " 重置 complete menu 全量缓存
  call s:ResetCompleteCache()
  " 重置当前每个插件的 docomplete 的状态
  call s:ResetCompleteTaskQueue()
endfunction

function! s:ResetCompletedItem()
  if pumvisible()
    return
  endif
  let g:easycomplete_completed_item = {}
endfunction

" 判断当前是否在complete menu 中光标移动在内高亮某一项
function! easycomplete#CompleteCursored()
  if !pumvisible()
    return v:false
  endif
  return empty(g:easycomplete_completed_item) ? v:false : v:true
endfunction

function! easycomplete#SetCompletedItem(item)
  let g:easycomplete_completed_item = a:item
endfunction

function! easycomplete#GetCompletedItem()
  return g:easycomplete_completed_item
endfunction

function! s:SetupCompleteCache()
  let g:easycomplete_menucache = {}
  let g:easycomplete_menucache["_#_1"] = 1  " 当前输入单词行号
  let g:easycomplete_menucache["_#_2"] = 1  " 当前输入单词列号
endfunction

function! s:ResetCompleteCache()
  if !exists('g:easycomplete_menucache')
    call s:SetupCompleteCache()
  endif

  let start_pos = col('.') - strwidth(s:GetTypingWord())
  if g:easycomplete_menucache["_#_1"] != line('.') || g:easycomplete_menucache["_#_2"] != start_pos
    let g:easycomplete_menucache = {}
  endif
  let g:easycomplete_menucache["_#_1"] = line('.')  " 行号
  let g:easycomplete_menucache["_#_2"] = start_pos  " 列号
endfunction

function! s:AddCompleteCache(word, menulist)
  if !exists('g:easycomplete_menucache')
    call s:SetupCompleteCache()
  endif

  let start_pos = col('.') - strwidth(a:word)
  if g:easycomplete_menucache["_#_1"] == line('.') && g:easycomplete_menucache["_#_2"] == start_pos
    let g:easycomplete_menucache[a:word] = a:menulist
  else
    let g:easycomplete_menucache = {}
  endif
  let g:easycomplete_menucache["_#_1"] = line('.')  " 行号
  let g:easycomplete_menucache["_#_2"] = start_pos  " 列号
endfunction

function! s:ResetBacking()
  let g:easycomplete_backing_or_cr = 0
endfunction

" 设置一个什么也不做的标志位，50ms 后恢复
function! s:zizz()
  let g:easycomplete_backing_or_cr = 1
  call s:StopAsyncRun()
  call s:AsyncRun(function('s:ResetBacking'), [], 50)
  return "\<BS>"
endfunction

function s:zizzing()
  return g:easycomplete_backing_or_cr ? v:true : v:false
endfunction

function! easycomplete#IsBacking()
  return s:zizzing()
endfunction

function! easycomplete#backing()
  return s:zizz()

  " if !exists('g:easycomplete_menucache')
  "   call s:SetupCompleteCache()
  " endif

  " call s:ResetCompleteCache()
  " call s:StopAsyncRun()
  " if has_key(g:easycomplete_menucache, s:GetTypingWord())
  "   call s:AsyncRun(function('s:zizzTimerHandler'), [], 500)
  " else
  "   " TODO 回退的逻辑优化
  "   " " call s:SendKeys("\<C-X>\<C-U>")
  "   " call s:DoComplete(v:true)
  "   " call s:StopAsyncRun()
  "   " call s:CompleteHandler()
  " endif
  " return ''
endfunction

function! s:zizzTimerHandler()
  if pumvisible()
    return ''
  endif

  if !exists('g:easycomplete_menucache')
    call s:SetupCompleteCache()
    return ''
  endif

  call s:CompleteAdd(get(g:easycomplete_menucache, s:GetTypingWord()))
  return ''
endfunction

" copy of asyncomplete
function! easycomplete#context() abort
  let l:ret = {
        \ 'bufnr':bufnr('%'),
        \ 'curpos':getcurpos(),
        \ 'changedtick':b:changedtick
        \ }
  let l:ret['lnum'] = l:ret['curpos'][1] " 行
  let l:ret['col'] = l:ret['curpos'][2] " 列
  let l:ret['filetype'] = &filetype " 文件类型
  let l:ret['filepath'] = expand('%:p') " 文件路径
  let line = getline(l:ret['lnum']) " 当前行
  let l:ret['typed'] = strpart(line, 0, l:ret['col']-1) " 光标之前的行内容
  let l:ret['char'] = strpart(line, l:ret['col']-2, 1) " 当前敲入字符
  let l:ret['typing'] = s:GetTypingWord() " 当前敲入的完整字符
  let l:ret['startcol'] = l:ret['col'] - strlen(l:ret['typing']) " 当前完整字符的起始列位置
  return l:ret
endfunction

function! s:SameCtx(ctx1, ctx2)
  if a:ctx1["lnum"] == a:ctx2["lnum"]
        \ && a:ctx1["col"] == a:ctx2["col"]
        \ && a:ctx1["typing"] ==# a:ctx2["typing"]
    return v:true
  else
    return v:false
  endif
endfunction

" 异步回来的complete menu携带的 ctx 和当前光标所在的 ctx 比较
" 如果发生变化则返回 false，如果是一致的则返回true
function! easycomplete#CheckContextSequence(ctx)
  return s:SameCtx(a:ctx, easycomplete#context())
endfunction

" 格式上方便兼容 asyncomplete 使用
function! easycomplete#complete(name, ctx, startcol, items, ...) abort
  let l:ctx = easycomplete#context()
  " 返回时的ctx不是typing时的ctx
  if !s:SameCtx(a:ctx, l:ctx)
    if s:CompleteSourceReady(a:name)
      " call s:CloseCompletionMenu()
      " call easycomplete#CursorHoldI()
      " call s:CallCompeltorByName(a:name, l:ctx)
    endif
    return
  endif
  call s:SetCompleteTaskQueue(a:name, l:ctx, 1, 1)
  call s:CompleteAdd(a:items)
endfunction

function! s:CallConstructorByName(name, ctx)
  let l:opt = get(g:easycomplete_source, a:name)
  let b:constructor = get(l:opt, "constructor")
  if b:constructor == 0
    return v:none
  endif
  if type(b:constructor) == 2 " 是函数
    call b:constructor(l:opt, a:ctx)
  endif
  if type(b:constructor) == type("string") " 是字符串
    call call(b:constructor, [l:opt, a:ctx])
  endif
endfunction

function! s:CallCompeltorByName(name, ctx)
  let l:opt = get(g:easycomplete_source, a:name)
  if empty(l:opt) || empty(get(l:opt, "completor"))
    return v:true
  endif
  let b:completor = get(l:opt, "completor")
  if type(b:completor) == 2 " 是函数
    return b:completor(l:opt, a:ctx)
  endif
  if type(b:completor) == type("string") " 是字符串
    return call(b:completor, [l:opt, a:ctx])
  endif
endfunction

function! easycomplete#FireCondition()
  if easycomplete#IsBacking()
    return v:false
  endif
  let l:char = easycomplete#context()["char"]
  if index(str2list(easycomplete#GetBindingKeys()), char2nr(l:char)) < 0
    return v:false
  endif
  return v:true
endfunction

function! easycomplete#typing()
  if !easycomplete#FireCondition()
    return ""
  endif

  if pumvisible()
    return ""
  endif
  call s:StopAsyncRun()
  call s:DoComplete(v:false)
  return ""
endfunction

" Complete 跟指调用起点, immediately: 是否立即调用还是延迟调用
" 一般在 : / . 时立即调用，在首次敲击字符时延迟调用
function! s:DoComplete(immediately)
  " 过滤非法的'.'点匹配
  let l:ctx = easycomplete#context()
  if strlen(l:ctx['typed']) >= 2 && l:ctx['char'] ==# '.'
        \ && l:ctx['typed'][l:ctx['col'] - 3] !~ '^[a-zA-Z0-9]$'
    call s:CloseCompletionMenu()
    return v:none
  endif

  if complete_check()
    call s:CloseCompletionMenu()
  endif

  " 孤立的点和冒号，什么也不做
  if strlen(l:ctx['typed']) == 1 && (l:ctx['char'] ==# '.' || l:ctx['char'] ==# ':')
    call s:CloseCompletionMenu()
    return v:none
  endif

  " 点号，终止连续匹配
  if l:ctx['char'] == '.'
    call s:CompleteInit()
    call s:ResetCompleteCache()
  endif

  " 判断是否是单词的首次按键，是则有一个延迟
  if index([':','.','/'], l:ctx['char']) >= 0 || a:immediately == v:true
    let word_first_type_delay = 0
  else
    let word_first_type_delay = 200
  endif

  call s:StopAsyncRun()
  call s:AsyncRun(function('s:CompleteHandler'), [], word_first_type_delay)
  return v:none
endfunction

" 代码样板
" call easycomplete#RegisterSource(easycomplete#sources#buffer#get_source_options({
"     \ 'name': 'buffer',
"     \ 'allowlist': ['*'],
"     \ 'blocklist': ['go'],
"     \ 'completor': function('easycomplete#sources#buffer#completor'),
"     \ 'config': {
"     \    'max_buffer_size': 5000000,
"     \  },
"     \ }))
function! easycomplete#RegisterSource(opt)
  if !has_key(a:opt, "name")
    return
  endif
  if !exists("g:easycomplete_source")
    let g:easycomplete_source = {}
  endif
  let g:easycomplete_source[a:opt["name"]] = a:opt
endfunction

" 依次执行安装完了的每个匹配器，依次调用每个匹配器的 completor 函数
" 每个 completor 函数中再调用 CompleteAdd
function! s:CompletorCalling(...)
  let l:ctx = easycomplete#context()
  call s:ResetCompleteTaskQueue()
  for item in keys(g:easycomplete_source)
    if s:CompleteSourceReady(item)
      let l:cprst = s:CallCompeltorByName(item, l:ctx)
      if l:cprst == v:true " 继续串行执行的指令
        continue
      else
        call s:LetCompleteTaskQueueAllDone()
        break " 返回 false 时中断后续执行
      endif
    endif
  endfor
endfunction

function! s:ConstructorCalling(...)
  let l:ctx = easycomplete#context()
  for item in keys(g:easycomplete_source)
    if s:CompleteSourceReady(item)
      call s:CallConstructorByName(item, l:ctx)
    endif
  endfor
endfunction

function! s:CompleteSourceReady(name)
  if has_key(g:easycomplete_source, a:name)
    let completor_source = get(g:easycomplete_source, a:name)
    if has_key(completor_source, 'whitelist')
      let whitelist = get(completor_source, 'whitelist')
      if index(whitelist, &filetype) >= 0 || index(whitelist, "*") >= 0
        return v:true
      else
        return v:false
      endif
    else
      return v:true
    endif
  else
    return v:false
  endif
endfunction

function! s:GetTypingWord()
  return easycomplete#util#GetTypingWord()
endfunction

function! easycomplete#CompleteChanged()
  " 判断光标是否在上下滑动，显示选中item的info
  let item = v:event.completed_item
  call easycomplete#SetCompletedItem(item)
  " call s:log('--easycomplete#CompleteChanged')
  " call s:log(item)
  " 由于 completechanged 会触发 complete()，complete() 又会触发 completechanged
  " 注意这里有一个无限递归的风险
  " 必须在 CompleteTypingMatch 中设置一个 zizz 标记，如果这里标记存在则终止调
  " 用，防止无限递归
  if empty(item) && !s:SameCtx(easycomplete#context(), g:easycomplete_firstcomplete_ctx) && !s:zizzing()
    call s:CompleteTypingMatch()
  endif
  if empty(item)
    call popup_clear()
    return
  endif
  let info = s:GetInfoByCompleteItem(copy(item))
  call s:ShowCompleteInfo(info)
  " Start fetching info for the item then call ShowCompleteInfo(info)
endfunction

function! s:GetInfoByCompleteItem(item)
  let t_name = empty(get(a:item, "abbr")) ? get(a:item, "word") : get(a:item, "abbr")
  let info = ""
  for item in g:easycomplete_menuitems
    if type(item) != type({})
      continue
    endif
    let i_name = empty(get(item, "abbr")) ? get(item, "word") : get(item, "abbr")
    if t_name ==# i_name && get(a:item, "menu") ==# get(item, "menu")
      if has_key(item, "info")
        let info = get(item, "info")
      endif
      break
    endif
  endfor
  return info
endfunction

function! s:ShowCompleteInfo(info)
  let id = popup_findinfo()
  let winid = id
  let bufnr = winbufnr(id)
  call setbufvar(bufnr, "&filetype", &filetype)
  " TODO 这个限制宽度的设置不管用
  " call setbufvar(bufnr, '&wrap', 1)
  " call popup_setoptions(id, {'maxwidth': 30})
  " call popup_move(id,{'maxwidth': 30})

  " Info 有三类
  " 字符串:".."
  " 数组:[...]
  " 占位符号:"_"
  if type(a:info) == type("") && (empty(a:info) || s:StringTrim(a:info) ==# "_")
    call popup_close(id)
    return
  endif
  if type(a:info) == type([]) && empty(a:info)
    call popup_close(id)
    return
  endif
  call popup_settext(id, a:info)
  call popup_show(id)
endfunction

function! easycomplete#SetMenuInfo(name, info, menu_flag)
  for item in g:easycomplete_menuitems
    let t_name = empty(get(item, "abbr")) ? get(item, "word") : get(item, "abbr")
    if t_name ==# a:name && get(item, "menu") ==# a:menu_flag
      let item.info = a:info
      break
    endif
  endfor
endfunction

"CleverTab tab 自动补全逻辑
function! easycomplete#CleverTab()
  setlocal completeopt-=noinsert
  call s:zizz()
  if pumvisible()
    return "\<C-N>"
  elseif s:SnipSupports() && UltiSnips#CanJumpForwards()
    " 代码已经完成展开时，编辑代码占位符，用tab进行占位符之间的跳转
    " call UltiSnips#JumpForwards()
    call eval('feedkeys("\'. g:UltiSnipsJumpForwardTrigger .'")')
    " call UltiSnips#ExpandSnippetOrJump()
    return ""
  elseif  getline('.')[0 : col('.')-1]  =~ '^\s*$' ||
        \ getline('.')[col('.')-2 : col('.')-1] =~ '^\s$' ||
        \ len(s:StringTrim(getline('.'))) == 0
    " 判断空行的三个条件
    "   如果整行是空行
    "   前一个字符是空格
    "   空行
    return "\<Tab>"
  elseif match(strpart(getline('.'), 0 ,col('.') - 1)[0:col('.')-1],
        \ "\\(\\w\\|\\/\\|\\.\\|\\:\\)$") < 0
    " 如果正在输入一个非字母，也不是'/'或'.'或者':'
    return "\<Tab>"
  else
    " 正常逻辑下都唤醒easycomplete菜单
    call s:DoComplete(v:true)
    return ""
  endif
endfunction

" CleverShiftTab 逻辑判断，无补全菜单情况下输出<Tab>
" Shift-Tab 在插入模式下输出为 Tab，仅为我个人习惯
function! easycomplete#CleverShiftTab()
  return pumvisible() ? "\<C-P>" : "\<Tab>"
endfunction

" 回车事件的行为，如果补全浮窗内点击回车，要判断是否
" 插入 snipmete 展开后的代码，否则还是默认回车事件
function! easycomplete#TypeEnterWithPUM()
  " 如果浮窗存在且 snipMate 已安装
  let l:item = easycomplete#GetCompletedItem()
  " 得到当前光标处已匹配的单词
  let l:word = matchstr(getline('.'), '\S\+\%'.col('.').'c')
  if ( pumvisible() && s:SnipSupports() && get(l:item, "menu") ==# "[S]" && get(l:item, "word") ==# l:word ) ||
        \ ( pumvisible() && s:SnipSupports() && empty(l:item) )
    " 优先判断是否前缀可被匹配 && 是否完全匹配到 snippet
    if index(keys(UltiSnips#SnippetsInCurrentScope()), l:word) >= 0
      call s:CloseCompletionMenu()
      " let key_str = "\\" . g:UltiSnipsExpandTrigger
      " call eval('feedkeys("'.key_str.'")')
      call feedkeys("\<C-R>=UltiSnips#ExpandSnippetOrJump()\<cr>")
      return ""
    endif
  endif
  if pumvisible()
    call s:zizz()
    return "\<C-Y>"
  endif
  return "\<CR>"
endfunction

" 插入模式下模拟按键点击
function! s:SendKeys( keys )
  call feedkeys( a:keys, 'in' )
endfunction


" 相当于 trim，去掉首尾的空字符
function! s:StringTrim(str)
  if !empty(a:str)
    let a1 = substitute(a:str, "^\\s\\+\\(.\\{\-}\\)$","\\1","g")
    let a1 = substitute(a:str, "^\\(.\\{\-}\\)\\s\\+$","\\1","g")
    return a1
  endif
  return ""
endfunction

" 关闭补全浮窗
function! s:CloseCompletionMenu()
  if pumvisible()
    call s:SendKeys( "\<ESC>a" )
  endif
  call s:ResetCompletedItem()
endfunction

function! s:CompleteHandler()
  call s:CompleteStopChecking()
  call s:StopAsyncRun()
  if s:NotInsertMode()
    return
  endif
  let l:ctx = easycomplete#context()
  if strwidth(l:ctx['typing']) == 0 && index([':','.','/'], l:ctx['char']) < 0
    return
  endif

  call s:CompleteInit()
  call s:CompletorCalling()
endfunction

function! s:CompleteStopChecking()
  if complete_check()
    call feedkeys("\<C-E>")
  endif
endfunction

function! s:CompleteInit(...)
  if !exists('a:1')
    let l:word = s:GetTypingWord()
  else
    let l:word = a:1
  endif
  " 这一步会让 complete popup 闪烁一下
  let g:easycomplete_menuitems = []

  " 由于 complete menu 是异步构造的，所以从敲入字符到 complete 呈现之间有一个
  " 时间，为了避免这个时间造成 complete 闪烁，这里设置了一个”视觉残留“时间
  if exists('g:easycomplete_visual_delay') && g:easycomplete_visual_delay > 0
    call timer_stop(g:easycomplete_visual_delay)
  endif
  let g:easycomplete_visual_delay = timer_start(100, function("s:CompleteMenuResetHandler"))
endfunction

function! s:CompleteMenuResetHandler(...)
  if !exists("g:easycomplete_menuitems") || empty(g:easycomplete_menuitems)
    call s:CloseCompletionMenu()
  endif
endfunction

function! easycomplete#CompleteAdd(menu_list)
  " 单词匹配表
  if !exists('g:easycomplete_menucache')
    call s:SetupCompleteCache()
  endif

  " 当前匹配
  if !exists('g:easycomplete_menuitems')
    let g:easycomplete_menuitems = []
  endif

  " 如果要给completemenu 补充数据，而这时又已经开始了tab下拉选中的action，先回
  " 退到原始状态，c-e
  if easycomplete#CompleteCursored()
    call feedkeys("\<C-E>")
  endif

  " TODO 除了排序之外，还要添加一个匹配typing word 的函数过滤，类似 coc
  let typing_word = s:GetTypingWord()
  let new_menulist = sort(copy(s:NormalizeMenulist(a:menu_list)), "s:SortTextComparatorByLength")
  let menuitems = g:easycomplete_menuitems + new_menulist
  if type(menuitems) != type([]) || empty(menuitems)
    return
  endif
  let menuitems = map(sort(copy(menuitems), "s:SortTextComparatorByAlphabet"),
        \ function("s:PrepareInfoPlaceHolder"))
  let menuitems = filter(menuitems,
        \ 'tolower(v:val.word) =~ "'. tolower(typing_word) . '"')

  let start_pos = col('.') - strwidth(typing_word)
  try
    call s:FirstComplete(start_pos, menuitems)
  catch /^Vim\%((\a\+)\)\=:E730/
    return v:none
  endtry
  let g:easycomplete_menuitems = menuitems
  call popup_clear()
  call s:AddCompleteCache(typing_word, g:easycomplete_menuitems)
endfunction

function! s:FirstComplete(start_pos, menuitems)
  " 这里的 menuitems 一定不为空
  if s:CheckCompleteTastQueueAllDone()
    " 参照 YCM，这里 complete 一律用异步
    "
    " TODO 这里的实现不严谨，通过延迟来区分 TextChange 和 CompleteChange 这两
    " 个事件，而且要让 CompleteChange 在 TextChange 第一次 complete 发生之后发
    " 生，用了两个延时来区分 first_complete_hit 的状态
    call s:AsyncRun(function('complete'), [a:start_pos, a:menuitems], 1)
    call s:AsyncRun(function('s:SetFirstCompeleHit'), [], 40)
    let g:easycomplete_firstcomplete_ctx = easycomplete#context()
  endif
endfunction

function! s:SetFirstCompeleHit()
  " 参照 g:easycomplete_first_complete_hit 定义注释
  let g:easycomplete_first_complete_hit = 1
endfunction

function! s:SortTextComparatorByLength(entry1, entry2)
  if has_key(a:entry1, "word") && has_key(a:entry2, "word")
    if strlen(a:entry1.word) > strlen(a:entry2.word)
      return v:true
    else
      return v:false
    endif
  endif
  return v:false
endfunction

function! s:SortTextComparatorByAlphabet(entry1, entry2)
  " return v:true
  if has_key(a:entry1, "word") && has_key(a:entry2, "word")
    if a:entry1.word > a:entry2.word
      return v:true
    else
      return v:false
    endif
  endif
  return v:false
endfunction

function! s:NormalizeMenulist(arr)
  if empty(a:arr)
    return []
  endif
  let l:menu_list = []

  for item in a:arr
    if type(item) == type("")
      let l:menu_item = { 'word': item,
            \ 'menu': '',
            \ 'user_data': '',
            \ 'info': '',
            \ 'kind': '',
            \ 'abbr': '' }
      call add(l:menu_list, l:menu_item)
    endif
    if type(item) == type({})
      call add(l:menu_list, extend({'word': '', 'menu': '', 'user_data': '',
            \                       'info': '', 'kind': '', 'abbr': ''},
            \ item ))
    endif
  endfor
  return l:menu_list
endfunction

function! s:CompleteAdd(...)
  return call("easycomplete#CompleteAdd", a:000)
endfunction

function! s:CompleteFilter(raw_menu_list)
  let arr = []
  let word = s:GetTypingWord()
  if empty(word)
    return a:raw_menu_list
  endif
  for item in a:raw_menu_list
    if strwidth(matchstr(item.word, word)) >= 1
      call add(arr, item)
    endif
  endfor
  return arr
endfunction

" ----------------------------------------------------------------------
"  TaskQueue: 每次匹配时，依次请求每个插件的 completor 方法
"  以最后一个返回匹配结果的时间点为准来执行 complete()
"  依次来避免每个 completor 方法返回时机不一带来的闪烁
"
"  这里的设计有缺陷，判断是否最后一个completor结果返回时，如果存在强制中
"  断的completor，这个判断会不准确，所以务必确保每个 completor 中的回调
"  easycomplete#complete 时必须要异步，手动让 easycomplete#complete 的函
"  数执行时机延迟到判断条件设置完毕之后，在写插件的时候有点费解，先只能这样
" ----------------------------------------------------------------------
function! s:ResetCompleteTaskQueue()
  let g:easycomplete_complete_taskqueue = []
  let l:ctx = easycomplete#context()
  for name in keys(g:easycomplete_source)
    if s:CompleteSourceReady(name)
      call s:SetCompleteTaskQueue(name, l:ctx, 1, 0)
    else
      call s:SetCompleteTaskQueue(name, l:ctx, 0, 0)
    endif
  endfor
endfunction

function! s:SetCompleteTaskQueue(name, ctx, condition, done)
  call filter(g:easycomplete_complete_taskqueue, 'v:val.name != "'.a:name.'"')
  call add(g:easycomplete_complete_taskqueue, {
        \ "name" : a:name,
        \ "ctx" : a:ctx,
        \ "condition": a:condition,
        \ "done" : a:done
        \ })
endfunction

function! s:CheckCompleteTastQueueAllDone()
  let flag = v:true
  for item in g:easycomplete_complete_taskqueue
    if item.condition == 1 && item.done == 0
      let flag = v:false
      break
    endif
  endfor
  return flag
endfunction

function! s:LetCompleteTaskQueueAllDone()
  for item in g:easycomplete_complete_taskqueue
    let item.done = 1
  endfor
endfunction


function! s:AsyncRun(...)
  return call('easycomplete#util#AsyncRun', a:000)
endfunction

function! s:StopAsyncRun(...)
  return call('easycomplete#util#StopAsyncRun', a:000)
endfunction

function! s:NotInsertMode()
  return call('easycomplete#util#NotInsertMode', a:000)
endfunction

function! s:log(msg)
  echohl MoreMsg
  echom '>>> '. string(a:msg)
  echohl NONE
endfunction

function! easycomplete#log(msg)
  call s:log(a:msg)
endfunction

