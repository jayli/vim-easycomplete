" File:         easycomplete.vim
" Author:       @jayli <https://github.com/jayli/>
" Description:  A minimalism style complete plugin for vim
"
"               More Info:
"               <https://github.com/jayli/vim-easycomplete>

if get(g:, 'easycomplete_script_loaded')
  finish
endif
let g:easycomplete_script_loaded = 1

augroup easycomplete#autocmd
  autocmd!
  autocmd User easycomplete_plugin silent
augroup END

function! s:InitLocalVars()
  " call s:loglog("start logging..")
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
  " 匹配过程中的临时数据
  let g:easycomplete_complete_ctx = {}
  " 保存 v:event.complete_item, 判断是否 pum 处于选中状态
  let g:easycomplete_completed_item = {}
  " 全局时间
  let g:easycomplete_start = reltime()
  " HACK: 当从pum最后一项继续 tab 到第一项时，此时也应当避免发生 completedone
  " 需要选择匹配项过程中的过程变量 ctx 暂存下来
  let g:easycomplete_firstcomplete_ctx = {}
  " 和 YCM 一样，用做 FirstComplete 标志位
  let g:easycomplete_first_complete_hit = 0
  " 菜单显示最大 item 数量，默认和 coc 保持一致
  " viml 的跟指性能不佳，适当降低下 maxlength 的阈值
  let g:easycomplete_maxlength = (&filetype == 'vim' && !has('nvim') ? 35 : 50)

  " First complete 过程中的任务队列，所有队列任务都完成后才显示匹配菜单
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
  " 当前敲入的字符所属的 ctx，用来判断光标前进还是后退
  let b:typing_ctx = easycomplete#context()

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
  " 初始化全局变量
  call s:InitLocalVars()
  " 必须要确保typing command先绑定
  " 插件里的typing command后绑定
  call s:BindingTypingCommandOnce()
  " 初始化 plugin 全局配置
  call easycomplete#plugin#init()
  " 执行 plugins 构造函数
  call s:ConstructorCalling()
  " 初始化 complete 缓存池
  call s:SetupCompleteCache()
  " 初始化皮肤 Pmenu
  call easycomplete#ui#SetScheme()
  " lsp 服务初始化
  call easycomplete#lsp#enable()

  " 载入本地字典
  call s:AsyncRun(function('easycomplete#AutoLoadDict'), [], 100)
  doautocmd <nomodeline> User easycomplete_plugin 
endfunction

function! easycomplete#GetBindingKeys()
  let l:key_liststr = 'abcdefghijklmnopqrstuvwxyz'.
                    \ 'ABCDEFGHIJKLMNOPQRSTUVWXYZ#/.:_'
  return l:key_liststr
endfunction

function! s:BindingTypingCommandOnce()
  if get(g:, 'easycomplete_typing_binding_done')
    return
  endif
  let g:easycomplete_typing_binding_done = 1
  if s:SnipSupports() && g:UltiSnipsExpandTrigger ==? g:easycomplete_tab_trigger
    " Ultisnips 的默认 tab 键映射和 EasyComplete 冲突，需要先unmap掉
    exec "iunmap " . g:easycomplete_tab_trigger
  endif
  exec "inoremap <silent><expr> " . g:easycomplete_tab_trigger . "  easycomplete#CleverTab()"
  exec "inoremap <silent><expr> " . g:easycomplete_shift_tab_trigger . "  easycomplete#CleverShiftTab()"
  inoremap <expr> <CR> easycomplete#TypeEnterWithPUM()
  inoremap <expr> <Up> easycomplete#Up()
  inoremap <expr> <Down> easycomplete#Down()
  inoremap <silent> <Plug>EasycompleteRefresh <C-r>=easycomplete#refresh()<CR>

  augroup easycomplete#NormalBinding
    autocmd!
    " FirstComplete Entry
    autocmd TextChangedI * call easycomplete#typing()
    " SecondComplete Entry 
    autocmd CompleteChanged * call easycomplete#CompleteChanged()
    autocmd CompleteDone * call easycomplete#CompleteDone()
    autocmd InsertLeave * call easycomplete#InsertLeave()
  augroup END

  " Goto definition
  command! EasyCompleteGotoDefinition : call easycomplete#GotoDefinitionCalling()
  " 检查插件依赖的命令工具是否已经安装
  command! EasyCompleteCheck : call easycomplete#checking()
  " 性能调试开启
  command! EasyCompleteProfileStart : call easycomplete#util#ProfileStart()
  " 性能调试结束
  command! EasyCompleteProfileStop : call easycomplete#util#ProfileStop()
  " 重定向 Tag 的跳转按键绑定
  nnoremap <c-]> :EasyCompleteGotoDefinition<CR>
endfunction

" 检查当前注册的插件中所依赖的 command 是否已经安装
function! easycomplete#checking()
  call s:flush()
  let amsg = ["Checking lsp cmd tools dependencies:"]
  call add(amsg, "")
  for item in keys(g:easycomplete_source)
    let l:name = item
    if !has_key(g:easycomplete_source[item], 'command')
      continue
    endif
    let l:command = get(g:easycomplete_source[item], 'command')
    let l:flag_txt = executable(l:command) ? "*ready*" : "|missing|"
    let l:flag_ico = executable(l:command) ? "√" : "×"
    let l:msg = "[".l:flag_ico."]" . " " . l:name . ": `" . l:command . "` " . l:flag_txt
    call add(amsg, l:msg)
  endfor
  call add(amsg, "")
  call add(amsg, "Done")
  let current_winid = bufwinid(bufnr(""))
  vertical botright new
  setlocal previewwindow filetype=help buftype=nofile nobuflisted modifiable
  let message_winid = bufwinid(bufnr(""))
  let ix = 0
  for line in amsg
    let ix = ix + 1
    call setbufline(bufnr(""), ix, line)
  endfor
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

" Second Complete Entry
function! s:CompleteTypingMatch(...)
  if (empty(v:completed_item) && s:zizzing()) && !(s:VimColonTyping() || s:VimDotTyping())
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

  if s:OrigionalPosition()
    call s:CloseCompletionMenu()
    call s:flush()
    return
  endif

  let l:always_call = s:CompletorCallingAtSecondComplete()
  if l:always_call
    " 等待 LSP callback → easycomplete#complete() → CompleteAdd
  else
    let word = exists('a:1') ? a:1 : s:GetTypingWord()
    let g_easycomplete_menuitems = deepcopy([] + g:easycomplete_menuitems)
    let filtered_menu = s:CompleteMenuFilter(g_easycomplete_menuitems, word)
    if len(filtered_menu) == 0
      call s:CloseCompletionMenu()
      return
    endif

    " 如果在 VIM 中输入了':'和'.'，一旦没有匹配项，就直接清空
    " g:easycomplete_menuitems，匹配状态复位
    " 注意：这里其实区分了 跟随匹配 和 Tab 匹配两个不同的动作
    " - 跟随匹配内容尽可能少，能匹配不出东西就保持空，尽可能少的干扰
    " - Tab 匹配内容尽可能多，能多匹配就多匹配，交给用户去选择
    if (s:VimDotTyping() || s:VimColonTyping()) && len(filtered_menu) == 0
      call s:CloseCompletionMenu()
      call s:flush()
      return
    endif

    call s:SecondComplete(col('.') - strlen(word), filtered_menu, g_easycomplete_menuitems)
  endif
endfunction

function! s:PrepareInfoPlaceHolder(key, val)
  if !(has_key(a:val, "info") && type(a:val.info) == type("") && !empty(a:val.info))
    let a:val.info = ""
  endif
  let a:val.equal = 1
  return a:val
endfunction

function! s:SecondComplete(start_pos, menuitems, easycomplete_menuitems)
  let tmp_menuitems = deepcopy(a:easycomplete_menuitems)
  let result = a:menuitems[0 : g:easycomplete_maxlength]
  if len(result) <= 10
    let result = easycomplete#util#uniq(result)
  endif
  " 避免递归 completedone() ×➜ CompleteTypingMatch() ...
  call s:zizz()
  call easycomplete#_complete(a:start_pos, result)
  " complete() 会触发 completedone 事件，会执行 s:flush()
  " 所以这里要确保 g:easycomplete_menuitems 不会被修改
  let g:easycomplete_menuitems = tmp_menuitems
endfunction

" TODO 此方法执行约 30ms，需要性能优化
function! s:CompleteMenuFilter(all_menu, word)
  let word = a:word
  if index(str2list(word), char2nr('.')) >= 0
    let word = substitute(word, "\\.", "\\\\\\\\.", "g")
  endif

  " 完整匹配
  let original_matching_menu = []
  " 非完整匹配
  let otherwise_matching_menu = []
  " 模糊匹配结果
  let otherwise_fuzzymatching = []

  let count_index = 0
  for item in a:all_menu
    let item_word = s:GetItemWord(item)
    if strlen(item_word) < strlen(a:word) | continue | endif
    if count_index > g:easycomplete_maxlength | break | endif
    if matchstr(item_word, "^" . word) == word
      call add(original_matching_menu, item)
      let count_index += 1
    else
      call add(otherwise_matching_menu, item)
    endif
  endfor

  for item in otherwise_matching_menu
    let item_word = s:GetItemWord(item)
    if strlen(item_word) < strlen(a:word) | continue | endif
    if count_index > g:easycomplete_maxlength | break | endif
    if easycomplete#util#FuzzySearch(word, item_word)
      call add(otherwise_fuzzymatching, item)
      let count_index += 1
    endif
  endfor

  let original_matching_menu = sort(deepcopy(original_matching_menu),
        \ "s:SortTextComparatorByLength")
  let result = easycomplete#util#distinct(original_matching_menu + otherwise_fuzzymatching)
  let filtered_menu = map(result, function("s:PrepareInfoPlaceHolder"))
  return filtered_menu
endfunction

function! s:GetItemWord(item)
  return empty(get(a:item, 'abbr', '')) ? get(a:item, 'word'): get(a:item, 'abbr', '')
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
  return complete_info()['selected'] == -1 ? v:false : v:true
endfunction

function! easycomplete#SetCompletedItem(item)
  let g:easycomplete_completed_item = a:item
endfunction

function! easycomplete#GetCompletedItem()
  return g:easycomplete_completed_item
endfunction

function! easycomplete#IsBacking()
  let curr_ctx = easycomplete#context()
  let old_ctx = copy(b:typing_ctx)
  let b:typing_ctx = curr_ctx
  if curr_ctx['lnum'] == old_ctx['lnum']
        \ && strlen(old_ctx['typed']) >= 2
        \ && curr_ctx['typed'] ==# old_ctx['typed'][:-2]
    " 单行后退
    return v:true
  elseif old_ctx['lnum'] == curr_ctx['lnum'] + 1 && old_ctx['col'] == 1
    " 隔行后退
    return v:true
  else
    return v:false
  endif
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

" 参考 asynccomplete 并做了扩充
function! easycomplete#context() abort
  let l:ret = {
        \ 'bufnr':bufnr('%'),
        \ 'curpos':getcurpos(),
        \ 'changedtick':b:changedtick
        \ }
  let l:ret['lnum'] = l:ret['curpos'][1] " 行号
  let l:ret['col'] = l:ret['curpos'][2] " 列号
  let l:ret['filetype'] = &filetype " filetype
  let l:ret['filepath'] = expand('%:p') " filepath
  let line = getline(l:ret['lnum']) " 当前行内容
  let l:ret['typed'] = strpart(line, 0, l:ret['col']-1) " 光标前敲入的内容
  let l:ret['char'] = strpart(line, l:ret['col']-2, 1) " 当前单个字符
  let l:ret['typing'] = s:GetTypingWord() " 当前敲入的单词 
  let l:ret['startcol'] = l:ret['col'] - strlen(l:ret['typing']) " 单词起始位置
  return l:ret
endfunction

" 检查 ctx 和当前 ctx 是否一致
function! easycomplete#CheckContextSequence(ctx)
  return s:SameCtx(a:ctx, easycomplete#context())
endfunction

" 是否回退到 first hit 所处的位置
function! s:OrigionalPosition()
  return easycomplete#CheckContextSequence(g:easycomplete_firstcomplete_ctx)
endfunction

" 外部插件回调 API
function! easycomplete#complete(name, ctx, startcol, items, ...) abort
  if s:NotInsertMode()
    call s:flush()
    return
  endif
  let l:ctx = easycomplete#context()
  if !s:SameCtx(a:ctx, l:ctx)
    if s:CompleteSourceReady(a:name)
      call easycomplete#nill()
    endif
    return
  endif
  call s:SetCompleteTaskQueue(a:name, l:ctx, 1, 1)
  call s:CompleteAdd(a:items, a:name)
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

  if s:PythonColonTyping()
    return v:false
  endif

  if index(str2list(easycomplete#GetBindingKeys()), char2nr(l:char)) < 0
    return v:false
  endif
  return v:true
endfunction

" python 的冒号
function! s:PythonColonTyping()
  if &filetype == "python" &&
        \ easycomplete#context()['typed'] =~ "\\(\\w\\|)\\):$"
    return v:true
  else
    return v:false
  endif
endfunction

" C++ 的双冒号
function! s:CppColonTyping()
  if &filetype == "cpp" &&
        \ easycomplete#context()['typed'] =~ "\\w::$"
    return v:true
  else
    return v:false
  endif
endfunction

" C++ 的箭头
function! s:CppArrowTyping()
  if &filetype == "cpp" &&
        \ easycomplete#context()['typed'] =~ "->$"
    return v:true
  else
    return v:false
  endif
endfunction

" vim 的冒号
function! s:VimColonTyping()
  if &filetype == "vim" &&
        \ easycomplete#context()['typed'] =~ "\\W\\(w\\|t\\|a\\|b\\|v\\|s\\|g\\):$"
    return v:true
  else
    return v:false
  endif
endfunction

" vim 的点号
function! s:VimDotTyping()
  if &filetype == "vim" &&
        \ easycomplete#context()['typed'] =~ "\\w\\."
    return v:true
  else
    return v:false
  endif
endfunction

function! s:TriggerAlways()
  let flag = v:false
  for item in keys(g:easycomplete_source)
    if s:CompleteSourceReady(item) && get(g:easycomplete_source[item], 'trigger', '') == 'always'
      let flag = v:true
      break
    endif
  endfor
  return flag
endfunction

" 输入和退格监听函数
function! easycomplete#typing()
  let g:easycomplete_start = reltime()
  if easycomplete#IsBacking()
    if s:TriggerAlways()
      return ""
    endif
    call s:zizz()
    let ctx = easycomplete#context()
    if empty(ctx["typing"]) || empty(ctx['char'])
          \ || !s:SameBeginning(g:easycomplete_firstcomplete_ctx, ctx)
      call s:CloseCompletionMenu()
      call s:flush()
      return ""
    endif
    if !empty(g:easycomplete_menuitems)
      call s:StopAsyncRun()
      call s:CompleteMatchAction()
    endif
    return ""
  endif

  if !easycomplete#FireCondition()
    return ""
  endif

  if &filetype == 'vim' && easycomplete#context()['char'] == ":"
    if !s:VimColonTyping()
      return ""
    endif
  endif

  if s:VimColonTyping()
    " continue
  elseif s:VimDotTyping()
    " continue
  elseif s:zizzing()
    return ""
  endif

  if pumvisible()
    return ""
  endif

  let b:typing_ctx = easycomplete#context()

  call s:StopAsyncRun()
  call s:DoComplete(v:false)
  return ""
endfunction

" immediately: 是否立即执行 complete()
" 在 '/' 或者 '.' 触发目录匹配时立即执行
function! s:DoComplete(immediately)
  let l:ctx = easycomplete#context()
  " 过滤不连续的 '.'
  if strlen(l:ctx['typed']) >= 2 && l:ctx['char'] ==# '.'
        \ && l:ctx['typed'][l:ctx['col'] - 3] !~ '^[a-zA-Z0-9]$'
    call s:CloseCompletionMenu()
    return v:null
  endif

  " sh #!<tab> hack, bugfix #12
  if &filetype == "sh" && easycomplete#context()['typed'] == "#!"
    call s:AsyncRun(function('s:CompleteHandler'), [], 0)
    return v:null
  endif

  if complete_check()
    call s:CloseCompletionMenu()
    call s:StopAsyncRun()
    return v:null
  endif

  " One ':' or '.', Do nothing
  if strlen(l:ctx['typed']) == 1 && (l:ctx['char'] ==# '.' || l:ctx['char'] ==# ':')
    call s:CloseCompletionMenu()
    return v:null
  endif

  " 连续两个 '.' 重新初始化 complete
  if l:ctx['char'] == '.' && (len(l:ctx['typed']) >= 2 && str2list(l:ctx['typed'])[-2] == char2nr('.'))
    call s:CompleteInit()
    call s:ResetCompleteCache()
  endif

  " 首次按键给一个延迟，体验更好
  if index([':','.','/'], l:ctx['char']) >= 0 || a:immediately == v:true
    let word_first_type_delay = 0
  else
    let word_first_type_delay = 150
  endif

  " typing 中的 SecondComplete 特殊字符处理
  " 特殊字符'->',':','.','::'等 在个语言中的匹配，一般要配合 lsp 一起使用，即
  " lsp给出的结果中就包含了 "a.b.c" 的提示，这时直接执行 SecondComplete 动作
  if !empty(g:easycomplete_menuitems)
    " hack for vim '.' dot typing
    if s:VimDotTyping()
      let l:vim_word = matchstr(l:ctx['typed'], '\(\w\+\.\)\{-1,}$')
      call s:CompleteTypingMatch(l:vim_word)
      return v:null
    endif

    " hack for vim ':' colon typing
    if s:VimColonTyping()
      let l:vim_word = matchstr(l:ctx['typed'], '\w:$')
      call s:CompleteTypingMatch(l:vim_word)
      return v:null
    endif
  endif

  " 检查模糊匹配 fuzzy match 条件
  if !empty(g:easycomplete_menuitems)
        \ && !s:SameCtx(easycomplete#context(), g:easycomplete_firstcomplete_ctx)
        \ && s:SameBeginning(g:easycomplete_firstcomplete_ctx, easycomplete#context())
    call s:CompleteTypingMatch()
    return v:null
  endif

  " 如果不是 insert 模式
  if g:env_is_nvim && mode() != 'i'
    return v:null
  endif

  " 执行 DoComplete
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

" 从注册的插件中依次调用每个 completor 函数，此函数只在 FirstComplete 时调用
" 每个 completor 中给出匹配结果后回调给 CompleteAdd
function! s:CompletorCallingAtFirstComplete(...)
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

" 从注册的插件中依次调用每个 completor 函数，此函数只在 SecondComplete 时调用
" 会检查插件的 trigger:always 字段判断是否重新更新
" 此方法只在 lsp 无法在 FirstComplete 时返回完整匹配结果时使用，用作实时更新
function! s:CompletorCallingAtSecondComplete()
  let l:ctx = easycomplete#context()
  call s:ResetAlwaysCompleteTaskQueue()
  let flag = v:false
  try
    for item in keys(g:easycomplete_source)
      if s:CompleteSourceReady(item) && get(g:easycomplete_source[item], 'trigger', '') == 'always'
        let flag = v:true
        let l:cprst = s:CallCompeltorByName(item, l:ctx)
        let g:easycomplete_firstcomplete_ctx = easycomplete#context()
        if l:cprst == v:true " true: go on
          continue
        else
          call s:LetCompleteTaskQueueAllDone()
          break " false: break 和 s:CompletorCallingAtFirstComplete 保持一致
        endif
      endif
    endfor
  catch
    echom v:exception
  endtry
  return flag
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

" 这个函数只能在 SecondComplete 过程中使用
" 用来根据 g:easycomplete_firstcomplete_ctx 和 ctx 做 diff 算出 typing word
" Gtx 即 g:easycomplete_firstcomplete_ctx
function! s:GetTypingWordByGtx()
  if empty(g:easycomplete_firstcomplete_ctx)
    return ""
  endif
  let l:ctx = easycomplete#context()
  let l:gtx = g:easycomplete_firstcomplete_ctx
  return l:ctx['typed'][strlen(l:gtx['typed'])-strlen(l:gtx['typing']):]
endfunction

" 只针对 FirstComplete 完成后的结果进行 Match 匹配动作，不在重新请求 LSP
function! s:CompleteMatchAction()
  call s:StopZizz()
  let l:vim_word = s:GetTypingWordByGtx() 
  call s:CompleteTypingMatch(l:vim_word)
  let b:typing_ctx = easycomplete#context()
endfunction

function! easycomplete#CompleteChanged()
  let item = v:event.completed_item
  if easycomplete#IsBacking() && s:TriggerAlways()
    call s:CloseCompleteInfo()
    call s:CloseCompletionMenu()
    return
  endif
  call easycomplete#SetCompletedItem(item)
  " SecondComplete 的前进态走这里，后退态走 easycomplete#typing 函数
  " 为了避免循环调用: CompleteChanged → complete() → CompleteChanged
  " 用 zizzing 来判断 CompleteTypingMatch 是否需要执行
  if !s:SameCtx(easycomplete#context(), g:easycomplete_firstcomplete_ctx) && !s:zizzing()
    let g:easycomplete_start = reltime()
    call s:CompleteMatchAction()
  endif
  if empty(item)
    call s:CloseCompleteInfo()
    return
  endif
  let info = easycomplete#util#GetInfoByCompleteItem(copy(item), g:easycomplete_menuitems)
  let thin_info = s:ModifyInfoByMaxwidth(info, g:easycomplete_popup_width)
  call s:ShowCompleteInfo(thin_info)
endfunction

function! s:CloseCompleteInfo()
  if g:env_is_nvim
    call easycomplete#popup#MenuPopupChanged([])
  else
    call easycomplete#popup#close()
  endif
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
    let t_name = s:GetItemWord(item)
    if t_name ==# a:name && get(item, "menu") ==# a:menu_flag
      let item.info = a:info
      break
    endif
  endfor
endfunction

"CleverTab tab
function! easycomplete#CleverTab()
  if pumvisible()
    call s:zizz()
    return "\<C-N>"
  elseif &filetype == "sh" && easycomplete#context()['typed'] == "#!"
    " sh #!<tab> hack, bugfix #12
    call s:ExpandSnipManually("#!")
    return ""
  elseif s:SnipSupports() && UltiSnips#CanJumpForwards()
    " 安装了 Ultisnips 后，用 Tab 来前跳
    " call UltiSnips#JumpForwards()
    call s:zizz()
    call eval('feedkeys("\'. g:UltiSnipsJumpForwardTrigger .'")')
    return ""
  elseif  getline('.')[0 : col('.')-1]  =~ '^\s*$' ||
        \ getline('.')[col('.')-2 : col('.')-1] =~ '^\s$' ||
        \ len(s:StringTrim(getline('.'))) == 0
    " 空行检查:
    "   whole empty line
    "   a space char before
    "   empty line
    call s:zizz()
    return "\<Tab>"
  elseif s:CppArrowTyping()
    call s:DoTabCompleteAction()
    return ""
  elseif match(strpart(getline('.'), 0 ,col('.') - 1)[0:col('.')-1],
        \ "\\(\\w\\|\\/\\|\\.\\|\\:\\)$") < 0
    " 输入非字母表字符，同时也不是 '/' 或者 ':'
    call s:zizz()
    return "\<Tab>"
  else
    call s:DoTabCompleteAction()
    return ""
  endif
endfunction

function! s:DoTabCompleteAction()
  if g:env_is_nvim
    " Hack nvim，nvim 中，在 DoComplete 中 mode() 有时是 n，这会导致调用 flush()
    " nvim 中改用异步调用
    call s:AsyncRun(function('s:DoComplete'), [v:true], 1)
    call s:SendKeys( "\<ESC>a" )
  elseif g:env_is_vim
    call s:DoComplete(v:true)
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
  " 得到光标处单词
  let l:word = matchstr(getline('.'), '\S\+\%'.col('.').'c')
  if ( pumvisible() && s:SnipSupports() && get(l:item, "menu") ==# "[S]" && get(l:item, "word") ==# l:word )
        \ || ( pumvisible() && s:SnipSupports() && empty(l:item) )
    call s:ExpandSnipManually(l:word)
    call s:zizz()
    return "\<C-Y>"
  endif
  if pumvisible()
    call s:zizz()
    return "\<C-Y>"
  endif
  return "\<CR>"
endfunction

function! s:ExpandSnipManually(word)
  try
    if index(keys(UltiSnips#SnippetsInCurrentScope()), a:word) >= 0
      call s:CloseCompletionMenu()
      call feedkeys("\<C-R>=UltiSnips#ExpandSnippetOrJump()\<cr>")
      return ""
    endif
  catch
    echom v:exception
  endtry
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
  if strwidth(l:ctx['typing']) == 0 && index([':','.','/','>'], l:ctx['char']) < 0
    return
  endif

  " 以上所有步骤都是特殊情况的拦截，后续逻辑应当完全交给 LSP 插件来做标准处
  " 理，原则上后续处理不应当做过多干扰，是什么结果就是什么结果了，除非严重错误，
  " 否则不应该在后续链路做 Hack 了
  call s:flush()
  call s:CompleteInit()
  call s:CompletorCallingAtFirstComplete()

  " 记录 g:easycomplete_firstcomplete_ctx 的时机，最早就是这里
  let g:easycomplete_firstcomplete_ctx = easycomplete#context()
endfunction

function! s:CompleteInit(...)
  if !exists('a:1')
    let l:word = s:GetTypingWord()
  else
    let l:word = a:1
  endif
  " 这会导致 pum 闪烁
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

function! easycomplete#CompleteAdd(menu_list, plugin_name)
  if s:zizzing() | return | endif
  if !exists('g:easycomplete_menucache')
    call s:SetupCompleteCache()
  endif

  if !exists('g:easycomplete_menuitems')
    let g:easycomplete_menuitems = []
  endif

  if type(a:menu_list) != type([]) || empty(a:menu_list)
    if s:CheckCompleteTastQueueAllDone()
      " continue
    else
      return
    endif
  endif

  if easycomplete#CompleteCursored()
    call feedkeys("\<C-E>")
  endif

  " FristComplete 的过滤方法参考 YCM 和 coc 重写了
  let typing_word = s:GetTypingWord()
  let new_menulist = a:menu_list
  let g:easycomplete_source[a:plugin_name].complete_result =
        \ deepcopy(s:NormalizeSort(s:NormalizeMenulist(a:menu_list)))
  let g:easycomplete_menuitems = s:CombineAllMenuitems()
  let g_easycomplete_menuitems = deepcopy(g:easycomplete_menuitems)
  let start_pos = col('.') - strwidth(typing_word)
  let filtered_menu = s:CompleteMenuFilter(g_easycomplete_menuitems, typing_word)

  try
    call s:FirstComplete(start_pos, filtered_menu)
  catch /^Vim\%((\a\+)\)\=:E730/
    return v:null
  endtry
  if g:env_is_vim | call popup_clear() | endif
  call s:AddCompleteCache(typing_word, filtered_menu)
endfunction

function! s:CombineAllMenuitems()
  let result = []
  for name in keys(g:easycomplete_source)
    call extend(result, get(g:easycomplete_source[name], 'complete_result', []))
  endfor
  return result
endfunction

function! s:FirstComplete(start_pos, menuitems)
  call s:AsyncRun(function('s:SetFirstCompeleHit'), [], 5)
  if s:zizzing() | return | endif
  if s:CheckCompleteTastQueueAllDone()
    if easycomplete#CheckContextSequence(g:easycomplete_firstcomplete_ctx)
      let result_items = a:menuitems[0 : g:easycomplete_maxlength]
      if len(result_items) <= 10
        let result_items = easycomplete#util#uniq(result_items)
      endif
      call easycomplete#_complete(a:start_pos, result_items)
    else
      " FirstTyping 已经发起 LSP Action，结果返回之前又前进 Typing，直接执行
      " easycomplete#typing() → s:CompleteTypingMatch()
    endif
  endif
endfunction

function! easycomplete#refresh()
  call complete(get(g:easycomplete_complete_ctx, 'start', col('.')),
        \ get(g:easycomplete_complete_ctx, 'candidates', []))
  return ''
endfunction

" Alias of complete()
function! easycomplete#_complete(start, items)
  let g:easycomplete_complete_ctx = {
        \ 'start': a:start,
        \ 'candidates': a:items,
        \}
  if mode() =~# 'i'
    call feedkeys("\<Plug>EasycompleteRefresh", 'i')
  endif
endfunction

function! s:SetFirstCompeleHit()
  let g:easycomplete_first_complete_hit = 1
endfunction

function! s:speed(...)
  let ss = exists('a:1') ? " " . a:1 : ""
  call call(function('s:loglog'), ['->complete speed'. ss, reltimestr(reltime(g:start))])
endfunction

function! s:StartRecord()
  let s:easy_start = reltime()
endfunction

function! s:StopRecord()
  let sp = reltimestr(reltime(g:easycomplete_start))
  call call(function('s:loglog'), ['functinal speed', reltimestr(reltime(s:easy_start))])
endfunction

" TODO 性能优化，4 次调用 0.08 s
function! s:SortTextComparatorByLength(entry1, entry2)
  let k1 = has_key(a:entry1, "abbr") && !empty(a:entry1.abbr) ?
        \ a:entry1.abbr : get(a:entry1, "word","")
  let k2 = has_key(a:entry2, "abbr") && !empty(a:entry2.abbr) ?
        \ a:entry2.abbr : get(a:entry2, "word","")
  if strlen(k1) > strlen(k2)
    return v:true
  else
    return v:false
  endif
  return v:false
endfunction

" TODO PY 和 VIM 实现的一致性
function! s:NormalizeSort(items)
  if has("pythonx")
    return s:NormalizeSortPY(a:items)
  else
    return s:NormalizeSortVIM(a:items)
  endif
endfunction

function! s:NormalizeSortVIM(items)
  " 先按照长度排序
  let l:items = sort(copy(a:items), "s:SortTextComparatorByLength")
  " 再按照字母表排序
  let l:items = sort(copy(l:items), "s:SortTextComparatorByAlphabet")
  return l:items
endfunction

function! s:NormalizeSortPY(...)
  return call("easycomplete#python#NormalizeSortPY", a:000)
endfunction

" TODO 性能优化，4 次调用 0.09 s
function! s:SortTextComparatorByAlphabet(entry1, entry2)
  let k1 = has_key(a:entry1, "abbr") && !empty(a:entry1.abbr) ?
        \ a:entry1.abbr : get(a:entry1, "word","")
  let k2 = has_key(a:entry2, "abbr") && !empty(a:entry2.abbr) ?
        \ a:entry2.abbr : get(a:entry2, "word","")
  if match(k1, "_") == 0
    return v:true
  endif
  if k1 > k2
    return v:true
  else
    return v:false
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

" FirstComplete 过程中调用
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

" SecondComplete 过程中调用
function! s:ResetAlwaysCompleteTaskQueue()
  let g:easycomplete_complete_taskqueue = []
  let l:ctx = easycomplete#context()
  for name in keys(g:easycomplete_source)
    if s:CompleteSourceReady(name) && get(g:easycomplete_source[name], 'trigger', '') == 'always'
      call s:SetCompleteTaskQueue(name, l:ctx, 1, 0)
    elseif s:CompleteSourceReady(name)
      call s:SetCompleteTaskQueue(name, l:ctx, 1, 1)
    else
      call s:SetCompleteTaskQueue(name, l:ctx, 0, 0)
    endif
  endfor
endfunction

function! s:SetCompleteTaskQueue(name, ctx, condition, done)
  call filter(g:easycomplete_complete_taskqueue, 'v:val.name != "'.a:name.'"')
  call add(g:easycomplete_complete_taskqueue, {
        \ "name" : a:name,
        \ "condition": a:condition,
        \ "ctx" : a:ctx,
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

function! s:complete_check()
  return !s:CheckCompleteTastQueueAllDone()
endfunction

function! s:LetCompleteTaskQueueAllDone()
  for item in g:easycomplete_complete_taskqueue
    let item.done = 1
  endfor
endfunction

" ----------------------------------------------------------------------
"  Util Method 常用的工具函数
" ----------------------------------------------------------------------

function! easycomplete#AutoLoadDict()
  call easycomplete#util#AutoLoadDict()
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
  " reset global first complete ctx
  let g:easycomplete_firstcomplete_ctx = {}
  " reset b:typing_ctx
  let b:typing_ctx = easycomplete#context()

  for sub in keys(g:easycomplete_source)
    let g:easycomplete_source[sub].complete_result = []
  endfor
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

function! s:ResetBacking(...)
  let g:easycomplete_backing_or_cr = 0
endfunction

" setup a flag for doing nothing for 20ms
function! s:zizz()
  let delay = g:env_is_nvim ? 30 : (&filetype == 'vim' ? 50 : 50)
  let g:easycomplete_backing_or_cr = 1
  if exists('s:zizz_timmer') && s:zizz_timmer > 0
    call timer_stop(s:zizz_timmer)
  endif
  let s:zizz_timmer = timer_start(delay, function('s:ResetBacking'))
  return "\<BS>"
endfunction

function! s:StopZizz()
  if exists('s:zizz_timmer') && s:zizz_timmer > 0
    call timer_stop(s:zizz_timmer)
  endif
  call s:ResetBacking()
endfunction

function s:zizzing()
  return g:easycomplete_backing_or_cr == 1 ? v:true : v:false
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

function! s:HasKey(...)
  return call('easycomplete#util#HasKey', a:000)
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
" 工具函数主要是给 easycomplete 的插件用的通用方法，已经做到了最小依赖
" vim-lsp 源码非常脏乱差，而且冗余很大，这里只对源码做了初步精简
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
    echom "lsp error response"
    return
  endif

  let l:result = s:GetLspCompletionResult(a:server_name, a:data, a:plugin_name)
  let l:matches = l:result['matches']

  " hack for vim-language-server: 
  "   s:<Tab> 和 s:abc<Tab> 匹配回来的 insertText 不应该带上 "s:"
  "   g:b:l:a: 都是正确的，只有 s: 不正确
  "   需要修改 word 为 insertText.slice(2)
  try
    if &filetype == 'vim' && l:ctx['typed'] =~ "s:\\w\\{-}$"
      let l:matches = map(copy(l:matches), function("s:VimHack_S_ColonMap"))
    endif
  catch
    echom v:exception
  endtry

  call easycomplete#complete(a:plugin_name, l:ctx, l:ctx['startcol'], l:matches)
endfunction

function! s:VimHack_S_ColonMap(key, val)
  if has_key(a:val, "abbr") && has_key(a:val, "word")
        \ && get(a:val, "abbr") ==# get(a:val, "word")
        \ && matchstr(get(a:val, "word"), "^s:") ==  "s:"
    let a:val.word = get(a:val, "word")[2:]
  endif
  return a:val
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
" file_exts 文件后缀
function! easycomplete#DoLspDefinition(file_exts)
  let ext = tolower(easycomplete#util#extention())
  if index(a:file_exts, ext) >= 0
    return easycomplete#LspDefinition()
  endif
  " exec "tag ". expand('<cword>')
  " 未成功跳转，则交给主进程处理
  return v:false
endfunction

" LSP 的 GoToDefinition
function! easycomplete#LspDefinition() abort
  " typeDefinition => type definition
  let l:method = "definition"
  let l:operation = substitute(l:method, '\u', ' \l\0', 'g')
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
        \ 'method': 'textDocument/' . l:method,
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
