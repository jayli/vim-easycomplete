" File:         easycomplete.vim
" Author:       @jayli <https://github.com/jayli/>
" Description:  The extreme simple complete plugin for vim
"
"               More Info:
"               <https://github.com/jayli/vim-easycomplete>

if get(g:, 'easycomplete_script_loaded')
  finish
endif
let g:easycomplete_script_loaded = 1

function! s:InitLocalVars()
  if !exists("g:easycomplete_tab_trigger")
    let g:easycomplete_tab_trigger = "<Tab>"
  endif

  if !exists("g:easycomplete_shift_tab_trigger")
    let g:easycomplete_shift_tab_trigger = "<S-Tab>"
  endif

  " 全局 Complete 注册插件
  if !exists("g:easycomplete_source")
    let g:easycomplete_source  = {}
  endif
  " 匹配过程中的 Cache，主要处理 <BS> 和 <CR> 键
  let g:easycomplete_menucache = {}
  " 匹配过程中的全量匹配数据，CompleteDone 后置空
  let g:easycomplete_menuitems = []
  " 保存 v:event.complete_item,判断是否pum处于选中状态
  let g:easycomplete_completed_item = {}

  " HACK: 当从pum最后一项继续 tab 到第一项时，此时也应当避免发生 completedone
  " 因此需要选择匹配项过程中的过程变量ctx存储
  let g:easycomplete_firstcomplete_ctx = {}

  " 和 YCM 一样，用做 FirstComplete 标志位
  let g:easycomplete_first_complete_hit = 0

  " 每次first complete过程中的任务队列，所有队列任务都完成后才显示匹配菜单
  " TODO: 需要加一个 timeout
  " [
  "   {
  "     "ctx": {},
  "     "name": "ts",
  "     "condition": 0
  "     "done" : 0
  "   }
  " ]
  let g:easycomplete_complete_taskqueue = []

  " popupwindow 宽度
  let g:easycomplete_popup_width = 50

  " 当前敲入的字符
  let b:typing_key = 0

  " <BS> 或者 <CR>, 以及其他非 ASCII 字符时的标志位
  " zizz 标志位
  let g:easycomplete_backing_or_cr = 0

  " completeopt 基础配置
  setlocal completeopt-=menu
  setlocal completeopt+=menuone
  setlocal completeopt+=noselect
  setlocal completeopt-=popup
  setlocal completeopt-=preview
  setlocal completeopt-=longest
  setlocal cpoptions+=B
endfunction

" EasyComplete 入口函数
function! easycomplete#Enable()
  " 每个 BufferEnter 时调用
  if exists("b:easycomplete_loaded_done")
    return
  endif
  let b:easycomplete_loaded_done= 1

  " Init Global Setting
  call s:InitLocalVars()
  " 必须要确保typing command先绑定
  " 插件里的typing command后绑定
  call s:BindingTypingCommandOnce()
  " Init plugin configration
  call easycomplete#plugin#init()
  " Init plugins constructor
  call s:ConstructorCalling()
  " Init complete cache
  call s:SetupCompleteCache()
  " Setup Pmenu hl
  call easycomplete#ui#SetScheme()
  " lsp 服务初始化
  call easycomplete#lsp#enable()
endfunction

function! easycomplete#GetBindingKeys()
  let l:key_liststr = 'abcdefghijklmnopqrstuvwxyz'.
                    \ 'ABCDEFGHIJKLMNOPQRSTUVWXYZ/.:>_'
  return l:key_liststr
endfunction

function! s:BindingTypingCommandOnce()
  if get(g:, 'easycomplete_typing_binding_done')
    return
  endif
  let g:easycomplete_typing_binding_done = 1
  inoremap <silent><expr> <BS> easycomplete#backing()
  if s:SnipSupports() && g:UltiSnipsExpandTrigger ==? g:easycomplete_tab_trigger
    " If ultisnips is installed. Ultisnips' tab binding will conflict with
    " easycomplete tab binding. So iunmap first.
    " Ultisnips 的默认 tab 键映射和 EasyComplete 冲突，需要先unmap掉
    exec "iunmap " . g:easycomplete_tab_trigger
  endif
  exec "inoremap <silent><expr> " . g:easycomplete_tab_trigger . "  easycomplete#CleverTab()"
  exec "inoremap <silent><expr> " . g:easycomplete_shift_tab_trigger . "  easycomplete#CleverShiftTab()"
  inoremap <expr> <CR> easycomplete#TypeEnterWithPUM()
  inoremap <expr> <Up> easycomplete#Up()
  inoremap <expr> <Down> easycomplete#Down()

  augroup easycomplete#NormalBinding
    autocmd!
    " FirstComplete Action
    autocmd TextChangedI * call easycomplete#typing()
    " SecondComplete Action
    autocmd CompleteChanged * call easycomplete#CompleteChanged()
    autocmd CompleteDone * call easycomplete#CompleteDone()
    autocmd InsertLeave * call easycomplete#InsertLeave()
  augroup END

  " goto definition 通用方法的实现
  command! EasyCompleteGotoDefinition : call easycomplete#GotoDefinitionCalling()
  nnoremap <c-]> :EasyCompleteGotoDefinition<CR>
endfunction

function! easycomplete#GotoDefinitionCalling()
  let l:ctx = easycomplete#context()
  let syntax_going = v:false
  for item in keys(g:easycomplete_source)
    if s:CompleteSourceReady(item)
      if has_key(get(g:easycomplete_source, item), "gotodefinition")
        let syntax_going = s:GotoDefinitionByName(item, l:ctx)
        break
      endif
    endif
  endfor
  if syntax_going == v:false
    try
      exec "tag ". expand('<cword>')
    catch
      echom v:exception
    endtry
  endif
endfunction

" Second Complete
function! s:CompleteTypingMatch(...)
  if empty(v:completed_item) && s:zizzing()
    return
  endif
  let l:char = easycomplete#context()["char"]
  " exit on None ASCII typing
  if char2nr(l:char) < 33 || char2nr(l:char) > 126
    call s:CloseCompletionMenu()
    call s:flush()
    return
  endif
  if !get(g:, 'easycomplete_first_complete_hit')
    return
  endif

  let word = exists('a:1') ? a:1 : s:GetTypingWord()
  let g_easycomplete_menuitems = deepcopy([] + g:easycomplete_menuitems)
  let filtered_menu = s:CustomCompleteMenuFilter(g_easycomplete_menuitems, word)
  let filtered_menu = map(filtered_menu, function("s:PrepareInfoPlaceHolder"))
  " complete() 会导致 CompleteChanged 事件, 这里使用异步
  call s:AsyncRun(function('s:SecondComplete'), [
        \   col('.') - strlen(word),
        \   filtered_menu,
        \   g_easycomplete_menuitems
        \ ], 0)
endfunction

function! s:PrepareInfoPlaceHolder(key, val)
  if !(has_key(a:val, "info") && type(a:val.info) == type("") && !empty(a:val.info))
    let a:val.info = ""
  endif
  let a:val.equal = 1
  return a:val
endfunction

function! s:SecondComplete(start_pos, menuitems, easycomplete_menuitems)
  let tmp_menuitems = a:easycomplete_menuitems
  " 避免 completedone 事件递归调用
  call s:zizz()
  call complete(a:start_pos, a:menuitems)
  " complete() → completedone → s:flush()
  " 这里确保 g:easycomplete_menuitems 不会被修改
  let g:easycomplete_menuitems = tmp_menuitems
endfunction

function! s:CustomCompleteMenuFilter(all_menu, word)
  " 完整匹配在前
  let word = tolower(a:word)
  let original_matching_menu = sort(filter(deepcopy(a:all_menu),
        \ 'tolower(v:val.word) =~ "^'. word . '"'), "s:SortTextComparatorByLength")

  " 模糊匹配在后
  let otherwise_matching_menu = filter(deepcopy(a:all_menu),
        \ 'tolower(v:val.word) !~ "^'. word . '"')

  let otherwise_fuzzymatching = []
  for item in otherwise_matching_menu
    if s:FuzzySearch(word, item.word)
      call add(otherwise_fuzzymatching, item)
    endif
  endfor
  return original_matching_menu + otherwise_fuzzymatching
endfunction

function! s:FuzzySearch(needle, haystack)
  return call('easycomplete#util#FuzzySearch', [a:needle, a:haystack])
endfunction

function! easycomplete#CompleteDone()
  call easycomplete#popup#CompleteDone()
  if !s:SameCtx(easycomplete#context(), g:easycomplete_firstcomplete_ctx) && !s:zizzing()
    return
  endif
  if pumvisible() || empty(v:completed_item)
    call s:zizz()
    return
  endif

  call s:flush()
endfunction

function! easycomplete#InsertLeave()
  call easycomplete#popup#InsertLeave()
  call s:flush()
endfunction

function! easycomplete#flush()
  call s:flush()
endfunction

" 判断 pum 是否是选中状态
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

function! easycomplete#IsBacking()
  return s:zizzing()
endfunction

function! easycomplete#Up()
  if pumvisible()
    call s:zizz()
  endif
  return "\<Up>"
endfunction

function! easycomplete#Down()
  if pumvisible()
    call s:zizz()
  endif
  return "\<Down>"
endfunction

function! easycomplete#backing()
  call s:zizz()
  call s:SendKeys("\<BS>")
  let ctx = easycomplete#context()
  if strlen(ctx["typing"]) == 1 || empty(ctx["typing"])
    call s:CloseCompletionMenu()
    call s:flush()
    return ""
  endif
  if s:SameBeginning(g:easycomplete_firstcomplete_ctx, ctx)
        \ && !empty(g:easycomplete_menuitems)
    " 不明白为何 ctx 获取在 sendkey <bs> 之前，所以这里用异步
    call s:AsyncRun(function('s:CompleteTypingMatch'), [], 0)
  endif
  return ""
endfunction

" 参考 asynccomplete
function! easycomplete#context() abort
  let l:ret = {
        \ 'bufnr':bufnr('%'),
        \ 'curpos':getcurpos(),
        \ 'changedtick':b:changedtick
        \ }
  let l:ret['lnum'] = l:ret['curpos'][1] " line num
  let l:ret['col'] = l:ret['curpos'][2] " col num
  let l:ret['filetype'] = &filetype " filetype
  let l:ret['filepath'] = expand('%:p') " filepath
  let line = getline(l:ret['lnum']) " current line
  let l:ret['typed'] = strpart(line, 0, l:ret['col']-1) " current line content before col
  let l:ret['char'] = strpart(line, l:ret['col']-2, 1) " typing char
  let l:ret['typing'] = s:GetTypingWord() " typing word
  let l:ret['startcol'] = l:ret['col'] - strlen(l:ret['typing']) " start position for complete
  return l:ret
endfunction

" 检查 ctx 和当前 ctx 是否一致
function! easycomplete#CheckContextSequence(ctx)
  return s:SameCtx(a:ctx, easycomplete#context())
endfunction

function! easycomplete#complete(name, ctx, startcol, items, ...) abort
  if s:NotInsertMode()
    call s:flush()
    return
  endif
  let l:ctx = easycomplete#context()
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

function! s:GotoDefinitionByName(name, ctx)
  let l:opt = get(g:easycomplete_source, a:name)
  let b:gotodefinition= get(l:opt, "gotodefinition")
  if empty(b:gotodefinition)
    return v:false
  endif
  if type(b:gotodefinition) == 2 " type is function
    return b:gotodefinition(l:opt, a:ctx)
  endif
  if type(b:gotodefinition) == type("string") " type is string
    return call(b:gotodefinition, [l:opt, a:ctx])
  endif
  return v:false
endfunction

function! s:CallConstructorByName(name, ctx)
  let l:opt = get(g:easycomplete_source, a:name)
  let b:constructor = get(l:opt, "constructor")
  if empty(b:constructor)
    return v:null
  endif
  if type(b:constructor) == 2 " type is function
    call b:constructor(l:opt, a:ctx)
  endif
  if type(b:constructor) == type("string") " type is string
    call call(b:constructor, [l:opt, a:ctx])
  endif
endfunction

function! s:CallCompeltorByName(name, ctx)
  let l:opt = get(g:easycomplete_source, a:name)
  if empty(l:opt) || empty(get(l:opt, "completor"))
    return v:true
  endif
  let b:completor = get(l:opt, "completor")
  if type(b:completor) == 2 " type is function
    return b:completor(l:opt, a:ctx)
  endif
  if type(b:completor) == type("string") " type is string
    return call(b:completor, [l:opt, a:ctx])
  endif
endfunction

function! easycomplete#FireCondition()
  let l:char = easycomplete#context()["char"]
  if s:zizzing() && index([":",".","_","/",">"], l:char) < 0
    return v:false
  endif

  if index(str2list(easycomplete#GetBindingKeys()), char2nr(l:char)) < 0
    return v:false
  endif
  return v:true
endfunction

function! easycomplete#typing()
  if !easycomplete#FireCondition()
    return ""
  endif

  if s:zizzing()
    return ""
  endif

  if pumvisible()
    return ""
  endif
  call s:StopAsyncRun()
  call s:DoComplete(v:false)
  return ""
endfunction

" immediately: 是否立即出发 complete()
" 在 '/' 或者 '.' 触发目录匹配时立即执行
function! s:DoComplete(immediately)
  " Filter unexpected '.' dot matching
  let l:ctx = easycomplete#context()
  if strlen(l:ctx['typed']) >= 2 && l:ctx['char'] ==# '.'
        \ && l:ctx['typed'][l:ctx['col'] - 3] !~ '^[a-zA-Z0-9]$'
    call s:CloseCompletionMenu()
    return v:null
  endif


  if complete_check()
    call s:CloseCompletionMenu()
  endif

  " One ':' or '.', Do nothing
  if strlen(l:ctx['typed']) == 1 && (l:ctx['char'] ==# '.' || l:ctx['char'] ==# ':')
    call s:CloseCompletionMenu()
    return v:null
  endif

  " More than one '.'
  if l:ctx['char'] == '.'
    call s:CompleteInit()
    call s:ResetCompleteCache()
  endif

  " First typing has a delay time
  if index([':','.','/'], l:ctx['char']) >= 0 || a:immediately == v:true
    let word_first_type_delay = 0
  else
    let word_first_type_delay = 150
  endif

  " Check fuzzy match condition
  if !empty(g:easycomplete_menuitems)
        \ && !s:SameCtx(easycomplete#context(), g:easycomplete_firstcomplete_ctx)
        \ && s:SameBeginning(g:easycomplete_firstcomplete_ctx, easycomplete#context())
    call s:CompleteTypingMatch()
    return v:null
  endif

  " if not in insert mode
  if g:env_is_nvim && mode() != 'i'
    return v:null
  endif

  " Finally Do Complete Action
  call s:StopAsyncRun()
  call s:AsyncRun(function('s:CompleteHandler'), [], word_first_type_delay)
  return v:null
endfunction

" Sample:
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

" Call every completor from registed plugins
" Completor will call CompleteAdd to update complete menu
function! s:CompletorCalling(...)
  let l:ctx = easycomplete#context()
  call s:ResetCompleteTaskQueue()
  try
    for item in keys(g:easycomplete_source)
      if s:CompleteSourceReady(item)
        let l:cprst = s:CallCompeltorByName(item, l:ctx)
        if l:cprst == v:true " true: go on
          continue
        else
          call s:LetCompleteTaskQueueAllDone()
          break " false: break, only use for directory matching
        endif
      endif
    endfor
  catch
    echom v:exception
    call s:flush()
  endtry
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

function! easycomplete#CompleteChanged()
  let item = v:event.completed_item
  call easycomplete#SetCompletedItem(item)
  " 为了避免循环调用: CompleteChanged → complete() → CompleteChanged
  " 这里检查 zizzing 来判断 CompleteTypingMatch 是否需要执行
  if !s:SameCtx(easycomplete#context(), g:easycomplete_firstcomplete_ctx) && !s:zizzing()
        " \ && !easycomplete#CompleteCursored()
    call s:CompleteTypingMatch()
  endif
  if empty(item)
    " hack for nvim
    if g:env_is_nvim
      call easycomplete#popup#MenuPopupChanged([])
    else
      call easycomplete#popup#close()
    endif
    return
  endif
  let info = easycomplete#util#GetInfoByCompleteItem(copy(item), g:easycomplete_menuitems)
  let thin_info = s:ModifyInfoByMaxwidth(info, g:easycomplete_popup_width)
  call s:ShowCompleteInfo(thin_info)
endfunction

function! s:ShowCompleteInfo(info)
  if easycomplete#util#TagBarExists()
    call tagbar#StopAutoUpdate()
  endif
  call easycomplete#popup#MenuPopupChanged(a:info)
  return
endfunction

function s:ModifyInfoByMaxwidth(...)
  return call('easycomplete#util#ModifyInfoByMaxwidth', a:000)
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

"CleverTab tab
function! easycomplete#CleverTab()
  " setlocal completeopt-=noinsert
  if pumvisible()
    call s:zizz()
    return "\<C-N>"
  elseif s:SnipSupports() && UltiSnips#CanJumpForwards()
    " In Ultisnips, Tab to jump forwards
    " call UltiSnips#JumpForwards()
    call s:zizz()
    call eval('feedkeys("\'. g:UltiSnipsJumpForwardTrigger .'")')
    return ""
  elseif  getline('.')[0 : col('.')-1]  =~ '^\s*$' ||
        \ getline('.')[col('.')-2 : col('.')-1] =~ '^\s$' ||
        \ len(s:StringTrim(getline('.'))) == 0
    " empty line checking:
    "   whole empty line
    "   a space char before
    "   empty line
    call s:zizz()
    return "\<Tab>"
  elseif match(strpart(getline('.'), 0 ,col('.') - 1)[0:col('.')-1],
        \ "\\(\\w\\|\\/\\|\\.\\|\\:\\)$") < 0
    " Typing a none alphabet lettera, not '/' or ':'
    call s:zizz()
    return "\<Tab>"
  else
    " Otherwise exec docomplete()
    if g:env_is_nvim
      " Hack nvim，nvim 中，在 DoComplete 中 mode() 有时是 n，这会导致调用 flush() 来清
      " 空匹配任务队列，这里用异步调用看起来是ok的
      call s:AsyncRun(function('s:DoComplete'), [v:true], 1)
      call s:SendKeys( "\<ESC>a" )
    elseif g:env_is_vim
      call s:DoComplete(v:true)
    endif
    return ""
  endif
endfunction

" CleverShiftTab
function! easycomplete#CleverShiftTab()
  call s:zizz()
  return pumvisible() ? "\<C-P>" : "\<Tab>"
endfunction

" <CR> 逻辑，判断是否展开代码片段
function! easycomplete#TypeEnterWithPUM()
  let l:item = easycomplete#GetCompletedItem()
  " Get Matching word under cursor
  let l:word = matchstr(getline('.'), '\S\+\%'.col('.').'c')
  if ( pumvisible() && s:SnipSupports() && get(l:item, "menu") ==# "[S]" && get(l:item, "word") ==# l:word )
        \ || ( pumvisible() && s:SnipSupports() && empty(l:item) )
    " should do snippet expand action or not
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

function! s:SendKeys( keys )
  call feedkeys(a:keys, 'in')
endfunction

function! s:StringTrim(str)
  return easycomplete#util#trim(a:str)
endfunction

" close pum
function! s:CloseCompletionMenu()
  if pumvisible()
    call s:SendKeys("\<ESC>a")
  endif
  call s:ResetCompletedItem()
endfunction

function! s:CompleteHandler()
  call s:StopAsyncRun()
  if s:NotInsertMode() && g:env_is_vim | return | endif
  let l:ctx = easycomplete#context()
  if strwidth(l:ctx['typing']) == 0 && index([':','.','/'], l:ctx['char']) < 0
    return
  endif

  call s:CompleteInit()
  call s:CompletorCalling()
endfunction

function! s:CompleteInit(...)
  if !exists('a:1')
    let l:word = s:GetTypingWord()
  else
    let l:word = a:1
  endif
  " 这会导致pum闪烁
  let g:easycomplete_menuitems = []
  " 用一个延时来避免闪烁
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
  if !exists('g:easycomplete_menucache')
    call s:SetupCompleteCache()
  endif

  if !exists('g:easycomplete_menuitems')
    let g:easycomplete_menuitems = []
  endif

  " close pum before call completeadd
  if easycomplete#CompleteCursored()
    call feedkeys("\<C-E>")
  endif

  " FirstComplete will sort complete result just like YCM and coc.
  let typing_word = s:GetTypingWord()
  let new_menulist = sort(copy(s:NormalizeMenulist(a:menu_list)), "s:SortTextComparatorByLength")
  let menuitems = g:easycomplete_menuitems + new_menulist
  if type(menuitems) != type([]) || empty(menuitems)
    return
  endif
  let menuitems = sort(copy(menuitems), "s:SortTextComparatorByAlphabet")
  let menuitems = filter(menuitems,
        \ 'tolower(v:val.word) =~ "'. tolower(typing_word) . '"')

  let g:easycomplete_menuitems = deepcopy(menuitems)
  let start_pos = col('.') - strwidth(typing_word)
  try
    let menuitems = map(menuitems, function("s:PrepareInfoPlaceHolder"))
    call s:FirstComplete(start_pos, menuitems)
  catch /^Vim\%((\a\+)\)\=:E730/
    return v:null
  endtry
  " let g:easycomplete_menuitems = menuitems
  if g:env_is_vim | call popup_clear() | endif
  call s:AddCompleteCache(typing_word, menuitems)
endfunction

function! s:FirstComplete(start_pos, menuitems)
  " menuitems is not empty
  if s:CheckCompleteTastQueueAllDone()
    " 为了让 CompleteChanged 事件在 TextChange 之后设置的不同延迟
    call s:AsyncRun(function('complete'), [a:start_pos, a:menuitems], 1)
    call s:AsyncRun(function('s:SetFirstCompeleHit'), [], 40)
    let g:easycomplete_firstcomplete_ctx = easycomplete#context()
  endif
endfunction

function! s:SetFirstCompeleHit()
  let g:easycomplete_first_complete_hit = 1
endfunction

function! s:SortTextComparatorByLength(entry1, entry2)
  if has_key(a:entry1, "word") && has_key(a:entry2, "word")
    let k1 = has_key(a:entry1, "abbr") ? a:entry1.abbr : a:entry1.word
    let k2 = has_key(a:entry2, "abbr") ? a:entry2.abbr : a:entry2.word
    if strlen(k1) > strlen(k2)
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
    let k1 = has_key(a:entry1, "abbr") ? a:entry1.abbr : a:entry1.word
    let k2 = has_key(a:entry2, "abbr") ? a:entry2.abbr : a:entry2.word
    if match(k1, "_") == 0
      return v:true
    endif
    if k1 > k2
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
      let l:menu_item = { 
            \ 'word': item,
            \ 'menu': '',
            \ 'user_data': '',
            \ 'info': '',
            \ 'kind': '',
            \ 'equal' : 1,
            \ 'dup': 1,
            \ 'abbr': '' }
      call add(l:menu_list, l:menu_item)
    endif
    if type(item) == type({})
      call add(l:menu_list, extend({
            \   'word': '',
            \   'menu': '',
            \   'user_data': '',
            \   'equal': 1,
            \   'dup': 1,
            \   'info': '',
            \   'kind': '',
            \   'abbr': ''
            \ },
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
"  TaskQueue: 每个插件都完成后，一并显示匹配菜单
"  任务队列的设计不完善，当lsp特别慢的时候有可能会等待很长时间，需要加一个超时
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

" ----------------------------------------------------------------------
"  Util Method 常用的工具函数
" ----------------------------------------------------------------------

function! s:SnipSupports()
  try
    call funcref("UltiSnips#RefreshSnippets")
  catch /^Vim\%((\a\+)\)\=:E700/
    return v:false
  endtry
  return v:true
endfunction

function! easycomplete#nill() abort
  return v:null " DO NOTHING
endfunction

" 清空全局配置
function! s:flush()
  " reset menuitems
  let g:easycomplete_menuitems = []
  " reset first_complete_hit
  let g:easycomplete_first_complete_hit = 0
  " reset current selected complete item
  call s:ResetCompletedItem()
  " reset complete menu cache
  call s:ResetCompleteCache()
  " reset docomplete task
  call s:ResetCompleteTaskQueue()
endfunction

function! s:ResetCompletedItem()
  if pumvisible()
    return
  endif
  let g:easycomplete_completed_item = {}
endfunction

function! s:SetupCompleteCache()
  let g:easycomplete_menucache = {}
  let g:easycomplete_menucache["_#_1"] = 1  " line num of current typing word
  let g:easycomplete_menucache["_#_2"] = 1  " col num of current typing word
endfunction

function! s:ResetCompleteCache()
  if !exists('g:easycomplete_menucache')
    call s:SetupCompleteCache()
  endif

  let start_pos = col('.') - strwidth(s:GetTypingWord())
  if g:easycomplete_menucache["_#_1"] != line('.') || g:easycomplete_menucache["_#_2"] != start_pos
    let g:easycomplete_menucache = {}
  endif
  let g:easycomplete_menucache["_#_1"] = line('.')  " line num
  let g:easycomplete_menucache["_#_2"] = start_pos  " col num
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
  let g:easycomplete_menucache["_#_1"] = line('.')  " line num
  let g:easycomplete_menucache["_#_2"] = start_pos  " col num
endfunction

function! s:ResetBacking()
  let g:easycomplete_backing_or_cr = 0
endfunction

" setup a flag for do nothing for 20ms
function! s:zizz()
  let delay = g:env_is_nvim ? 20 : 50
  let g:easycomplete_backing_or_cr = 1
  call s:StopAsyncRun()
  call s:AsyncRun(function('s:ResetBacking'), [], delay)
  return "\<BS>"
endfunction

function s:zizzing()
  return g:easycomplete_backing_or_cr == 1 ? v:true : v:false
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

function! s:SameCtx(ctx1, ctx2)
  if type(a:ctx1) != type({}) || type(a:ctx2) != type({})
    return v:false
  endif
  if !has_key(a:ctx1, "lnum") || !has_key(a:ctx2, "lnum")
    return v:false
  endif
  if a:ctx1["lnum"] == a:ctx2["lnum"]
        \ && a:ctx1["col"] == a:ctx2["col"]
        \ && a:ctx1["typing"] ==# a:ctx2["typing"]
    return v:true
  else
    return v:false
  endif
endfunction

" ctx1 在前，ctx2 在后
" 判断 FirstComplete 和 SecondComplete 是否是一个 ctx 下的行为
function! s:SameBeginning(ctx1, ctx2)
  if !has_key(a:ctx1, "lnum") || !has_key(a:ctx2, "lnum")
    return v:false
  endif
  if a:ctx1["startcol"] == a:ctx2["startcol"]
        \ && a:ctx1["lnum"] == a:ctx2["lnum"]
        \ && match(a:ctx2["typing"], a:ctx1["typing"]) == 0
    return v:true
  else
    return v:false
  endif
endfunction

function! s:GetTypingWord()
  return easycomplete#util#GetTypingWord()
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

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction

function! s:loglog(...)
  return call('easycomplete#log#log', a:000)
endfunction

" ----------------------------------------------------------------------
" LSP 专用工具函数
" 这里把 vim-lsp 整合进来了，做好了兼容，不用再安装外部依赖，这里的 LSP
" 工具函数主要是给 easycomplete 的插件用的通用方法
" vim-lsp 源码非常脏乱差，而且冗余很大，这里只做了初步精简
" ----------------------------------------------------------------------

" LSP 的 completor 函数，通用函数，可以直接使用，也可以自己再封装一层
function! easycomplete#DoLspComplete(opt, ctx)
  let l:info = easycomplete#FindLspCompleteServers()
  let l:ctx = easycomplete#context()
  if empty(l:info['server_names'])
    call easycomplete#complete(a:opt['name'], l:ctx, l:ctx['startcol'], [])
    return v:true
  endif
  call easycomplete#LspCompleteRequest(l:info, a:opt['name'])
  return v:true
endfunction

" 原 s:send_completion_request(info)
" info: lsp server 信息
" plugin_name: 插件的名字，比如 py, ts
function! easycomplete#LspCompleteRequest(info, plugin_name) abort
  let l:server_name = a:info['server_names'][0]
  call easycomplete#lsp#send_request(l:server_name, {
        \ 'method': 'textDocument/completion',
        \ 'params': {
        \   'textDocument': easycomplete#lsp#get_text_document_identifier(),
        \   'position': easycomplete#lsp#get_position(),
        \   'context': { 'triggerKind': 1 }
        \ },
        \ 'on_notification': function('s:HandleLspCompletion', [l:server_name, a:plugin_name])
        \ })
endfunction

" s:find_complete_servers() 获取 LSP Complete Server 信息
function! easycomplete#FindLspCompleteServers() abort
  let l:server_names = []
  for l:server_name in easycomplete#lsp#get_allowed_servers()
    let l:init_capabilities = easycomplete#lsp#get_server_capabilities(l:server_name)
    if has_key(l:init_capabilities, 'completionProvider')
      " TODO: support triggerCharacters
      call add(l:server_names, l:server_name)
    endif
  endfor

  return { 'server_names': l:server_names }
endfunction

function! easycomplete#HandleLspComplete(...)
  return call('s:HandleLspComplete', a:000)
endfunction

function! s:HandleLspCompletion(server_name, plugin_name, data) abort
  let l:ctx = easycomplete#context()
  if easycomplete#lsp#client#is_error(a:data) || !has_key(a:data, 'response') || !has_key(a:data['response'], 'result')
    call easycomplete#complete(a:plugin_name, l:ctx, l:ctx['startcol'], [])
    echom "error jayli"
    return
  endif

  let l:result = s:GetLspCompletionResult(a:server_name, a:data, a:plugin_name)
  let l:matches = l:result['matches']

  try
    let l:matches = sort(deepcopy(l:matches), "s:SortTextComparatorByLength")
    let l:matches = sort(deepcopy(l:matches), "s:SortTextComparatorByAlphabet")
  catch
    echom v:exception
  endtry

  call easycomplete#complete(a:plugin_name, l:ctx, l:ctx['startcol'], l:matches)
endfunction

function! s:GetLspCompletionResult(server_name, data, plugin_name) abort
  let l:result = a:data['response']['result']
  let l:response = a:data['response']

  " 这里包含了 info document 和 matches
  let l:completion_result = s:GetVimCompletionItems(l:response, a:plugin_name)
  return {'matches': l:completion_result['items'], 'incomplete': l:completion_result['incomplete'] }
endfunction

function! s:GetVimCompletionItems(response, plugin_name)
  let l:result = a:response['result']
  if type(l:result) == type([])
    let l:items = l:result
    let l:incomplete = 0
  elseif type(l:result) == type({})
    let l:items = l:result['items']
    let l:incomplete = l:result['isIncomplete']
  else
    let l:items = []
    let l:incomplete = 0
  endif

  let l:vim_complete_items = []
  for l:completion_item in l:items
    let l:expandable = get(l:completion_item, 'insertTextFormat', 1) == 2
    let l:vim_complete_item = {
          \ 'kind': easycomplete#util#LspType(get(l:completion_item, 'kind', 0)),
          \ 'dup': 1,
          \ 'menu' : "[". toupper(a:plugin_name) ."]",
          \ 'empty': 1,
          \ 'icase': 1,
          \ }

    " 如果 label 中包含括号 且过长
    if l:completion_item['label'] =~ "(.\\+)" && strlen(l:completion_item['label']) > 40
      if easycomplete#util#contains(l:completion_item['label'], ",") >= 2
        let l:completion_item['label'] = substitute(l:completion_item['label'], "(.\\+)", "(...)", "g")
      endif
    endif

    if has_key(l:completion_item, 'textEdit') &&
          \ type(l:completion_item['textEdit']) == type({}) &&
          \ has_key(l:completion_item['textEdit'], 'nextText')
      let l:vim_complete_item['word'] = l:completion_item['textEdit']['nextText']
    elseif has_key(l:completion_item, 'insertText') && !empty(l:completion_item['insertText'])
      let l:vim_complete_item['word'] = l:completion_item['insertText']
    else
      let l:vim_complete_item['word'] = l:completion_item['label']
    endif

    if l:expandable
      let l:vim_complete_item['word'] = easycomplete#lsp#utils#make_valid_word(
            \ substitute(l:vim_complete_item['word'],
            \ '\$[0-9]\+\|\${\%(\\.\|[^}]\)\+}', '', 'g'))
      let l:vim_complete_item['abbr'] = l:completion_item['label'] . '~'
    else
      let l:vim_complete_item['abbr'] = l:completion_item['label']
    endif

    let l:t_info = s:NormalizeLSPInfo(get(l:completion_item, "documentation", ""))
    if !empty(get(l:completion_item, "detail", ""))
      let l:vim_complete_item['info'] = [get(l:completion_item, "detail", "")] + l:t_info
    else
      let l:vim_complete_item['info'] = l:t_info
    endif

    let l:vim_complete_items += [l:vim_complete_item]
  endfor

  return { 'items': l:vim_complete_items, 'incomplete': l:incomplete }
endfunction

function! s:NormalizeLSPInfo(info)
  let l:li = split(a:info, "\n")
  let l:str = []

  for item in l:li
    if item ==# ''
      call add(l:str, item)
    else
      if len(l:str) == 0
        call add(l:str, item)
      else
        let l:old = l:str[len(l:str) - 1]
        let l:str[len(l:str) - 1] = l:old . " " . item
      endif
    endif
  endfor
  return l:str
endfunction

" LSP definition 跳转的通用封装
function! easycomplete#DoLspDefinition(file_exts)
  let ext = tolower(easycomplete#util#extention())
  if index(a:file_exts, ext) >= 0
    return easycomplete#LspDefinition('definition')
  endif
  " exec "tag ". expand('<cword>')
  " 未成功跳转，则交给主进程处理
  return v:false
endfunction

" LSP 的 GoToDefinition
function! easycomplete#LspDefinition(method) abort
  " typeDefinition => type definition
  let l:operation = substitute(a:method, '\u', ' \l\0', 'g')
  let l:servers = easycomplete#FindLspCompleteServers()['server_names']
  if empty(l:servers)
    return v:false
  endif
  let l:server = easycomplete#FindLspCompleteServers()['server_names'][0]
  let l:ctx = { 'counter': len(l:server), 'list':[], 'jump_if_one': 1, 'mods': '', 'in_preview': 0 }

  let l:params = {
        \   'textDocument': easycomplete#lsp#get_text_document_identifier(),
        \   'position': easycomplete#lsp#get_position(),
        \ }
  call easycomplete#lsp#send_request(l:server, {
        \ 'method': 'textDocument/' . a:method,
        \ 'params': l:params,
        \ 'on_notification': function('s:HandleLspLocation', [l:ctx, l:server, l:operation]),
        \ })

  echo printf('Retrieving %s ...', l:operation)
  return v:true
endfunction

" 这里 ctx 的格式保留下来
" ctx = {counter, list, last_command_id, jump_if_one, mods, in_preview}
function! s:HandleLspLocation(ctx, server, type, data) abort
  if easycomplete#lsp#client#is_error(a:data['response']) || !has_key(a:data['response'], 'result')
    call s:log('Failed to retrieve '. a:type . ' for ' . a:server .
          \ ': ' . easycomplete#lsp#client#error_message(a:data['response']))
  else
    let a:ctx['list'] = a:ctx['list'] + easycomplete#lsp#utils#location#_lsp_to_vim_list(a:data['response']['result'])
  endif

  if empty(a:ctx['list'])
    call easycomplete#lsp#utils#error('No ' . a:type .' found')
  else
    call easycomplete#util#UpdateTagStack()

    let l:loc = a:ctx['list'][0]

    if len(a:ctx['list']) == 1 && a:ctx['jump_if_one'] && !a:ctx['in_preview']
      call easycomplete#lsp#utils#location#_open_vim_list_item(l:loc, a:ctx['mods'])
      echo 'Retrieved ' . a:type
      redraw
    elseif !a:ctx['in_preview']
      call setqflist([])
      call setqflist(a:ctx['list'])
      echo 'Retrieved ' . a:type
      botright copen
    else
      " do nothing
    endif
  endif
endfunction
