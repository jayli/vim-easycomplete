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

  " Global LSP plugins
  if !exists("g:easycomplete_source")
    let g:easycomplete_source  = {}
  endif
  " Complete Result Caching, For <BS> and <CR> typing
  let g:easycomplete_menucache = {}
  " The Global storage for each complete result
  " Info msg will be appended here.
  " menuitems will be set to [] after CompleteDone
  let g:easycomplete_menuitems = []
  " Record v:event.complete_item for pum, to checkout if there is an item
  " selected in pum
  let g:easycomplete_completed_item = {}

  " HACK: To avoid trigger completedone event after going back from last item
  " in pum, We need to store ctx for checking completedone event fired
  " correctly. This variable is for temp usage.
  let g:easycomplete_firstcomplete_ctx = {}

  " Like YCM, local variable for checking complete result form
  " the first completition or not. Second Completiton will not query
  " suggestions from lsp server.
  let g:easycomplete_first_complete_hit = 0

  " Store every async completor task. Set done to 1 for such completor
  " completed. This will ensure each completor calling shows pum menu at one
  " time.
  " [
  "   {
  "     "ctx": {},
  "     "name": "ts",
  "     "condition": 0
  "     "done" : 0
  "   }
  " ]
  let g:easycomplete_complete_taskqueue = []

  " Width of info popup window
  let g:easycomplete_popup_width = 50

  " Current typing key
  let b:typing_key = 0

  " Checking typing <BS> or <CR>, and other none ASCII typing
  " Used for every InputTextChange event for s:zizz()
  let g:easycomplete_backing_or_cr = 0

  " basic setting
  setlocal completeopt-=menu
  setlocal completeopt+=menuone
  setlocal completeopt+=noselect
  setlocal completeopt-=popup
  setlocal completeopt-=preview
  setlocal completeopt-=longest
  setlocal cpoptions+=B
endfunction

" Entry of EasyComplete
function! easycomplete#Enable()
  " EasyComplete will be initalized after BufEnter
  if exists("b:easycomplete_loaded_done")
    return
  endif
  let b:easycomplete_loaded_done= 1

  " Init Global Setting
  call s:InitLocalVars()
  " We must ensure typing command binded first
  " plugin command binded there after
  call s:BindingTypingCommandOnce()
  " Init plugin configration
  call easycomplete#plugin#init()
  " Init plugins constructor
  call s:ConstructorCalling()
  " Init complete cache
  call s:SetupCompleteCache()
  " Setup Pmenu hl
  call easycomplete#ui#setScheme()

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
    exec "iunmap " . g:easycomplete_tab_trigger
  endif
  exec "inoremap <silent><expr> " . g:easycomplete_tab_trigger . "  easycomplete#CleverTab()"
  exec "inoremap <silent><expr> " . g:easycomplete_shift_tab_trigger . "  easycomplete#CleverShiftTab()"
  inoremap <expr> <CR> easycomplete#TypeEnterWithPUM()

  augroup easycomplete#NormalBinding
    autocmd!
    " Global typing event for FirstComplete Action
    autocmd TextChangedI * call easycomplete#typing()
    " Global typing event for SecondComplete Action
    autocmd CompleteChanged * call easycomplete#CompleteChanged()
    autocmd CompleteDone * call easycomplete#CompleteDone()
    autocmd InsertLeave * call easycomplete#InsertLeave()
  augroup END

  " goto definition 方法需要抽到配置里去
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
  " During CompleteChanged event. Menulist must not be changed by complete()
  let filtered_menu = map(filtered_menu, function("s:PrepareInfoPlaceHolder"))
  " complete() will fire CompleteChanged event, use async call instead.
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

" FirstComplete: The first complete action for fetching result from lsp server
" SecondComplete: The second complete action for matching suggestions from
" easycomplete_menuitems.
function! s:SecondComplete(start_pos, menuitems, easycomplete_menuitems)
  let tmp_menuitems = a:easycomplete_menuitems
  " To avoid completedone event recursive calling
  call s:zizz()
  call complete(a:start_pos, a:menuitems)
  " complete() will cause completedone event, and then call s:flush() to reset
  " global configration. So g:easycomplete_menuitems must not be changed.
  let g:easycomplete_menuitems = tmp_menuitems
endfunction

function! s:CustomCompleteMenuFilter(all_menu, word)
  " Full match coming first.
  let word = tolower(a:word)
  let original_matching_menu = sort(filter(deepcopy(a:all_menu),
        \ 'tolower(v:val.word) =~ "^'. word . '"'), "s:SortTextComparatorByLength")

  " Fuzzy match coming second
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

" checkout Cursor is in pum or not
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
    " I dont know why I get ctx before sendkey <bs>. So I mast do this
    " asyncrun for s:CompleteTypingMatch
    call s:AsyncRun(function('s:CompleteTypingMatch'), [], 0)
  endif
  return ""
endfunction

" Same as asynccomplete
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

" Is Async completor's ctx same as current ctx or not
function! easycomplete#CheckContextSequence(ctx)
  return s:SameCtx(a:ctx, easycomplete#context())
endfunction

" Same as asynccomplete
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

" immediately: fire complete right now or not
" This will fired immediately as typing '/' or '.' for directory matching
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
  " To avoid recursive call: CompleteChanged → complete() → CompleteChanged
  " Here we check zizzing from CompleteTypingMatch to stop recursive call.
  if !s:SameCtx(easycomplete#context(), g:easycomplete_firstcomplete_ctx) && !s:zizzing()
        \ && !easycomplete#CompleteCursored()
    call s:CompleteTypingMatch()
  endif
  if empty(item)
    " hack
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
    " While in Ultisnips, Tab to jump forwards
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
    " Otherwise fire docomplete()
    if g:env_is_nvim
      " Hack for nvim, During DoComplete mode() may change to 'n'. Leveing
      " Insert Mode make a flush() call and empty the task queue.
      " I dont know why.
      " A Async call seems to be fine.
      call s:AsyncRun(function('s:DoComplete'), [v:true], 1)
      call s:SendKeys( "\<ESC>a" )
    elseif g:env_is_vim
      call s:DoComplete(v:true)
    endif
    return ""
  endif
endfunction

" CleverShiftTab, echo <Tab> when pum is not visible
function! easycomplete#CleverShiftTab()
  call s:zizz()
  return pumvisible() ? "\<C-P>" : "\<Tab>"
endfunction

" <CR> for complete selection and expand snip
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

" feedkeys at 'in' mod
function! s:SendKeys( keys )
  call feedkeys(a:keys, 'in')
endfunction

function! s:StringTrim(str)
  return easycomplete#util#trim(a:str)
endfunction

" close pum
function! s:CloseCompletionMenu()
  if pumvisible()
    call s:SendKeys( "\<ESC>a" )
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
  " this will course pum flashing
  let g:easycomplete_menuitems = []

  " Because complete menu is async created. Here I setup a delaytime for
  " continuing typing with a visible pum to avoid this flashing.
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
    " Same as YCM, Use Async Complete all time
    "
    " TODO: I use a delaytime via first_complete_hit to seperate TextChange
    " and CompleteChange. CompleteChange must happened after TextChange event
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
"  TaskQueue:
"  Exec complete() as the last async complete result coming back.
"
"  TODO: This contain a hidden trouble at force break of completor. So each
"  completor will be an async call, and return each continuing condition
"  manully. I dont find a better way to solve this problem.
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
"  Util Method
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

" Reset Global configration
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

" ctx1 before，ctx2 after
" checkout FirstComplete and SecondComplete are belong to
" one beginning ctx or not
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

function! s:log(msg)
  echohl MoreMsg
  echom '>>> '. string(a:msg)
  echohl NONE
endfunction

function! easycomplete#log(msg)
  call s:log(a:msg)
endfunction

function! s:loglog(...)
  return call('easycomplete#log#log', a:000)
endfunction

" Global API
" easycomplete#CheckContextSequence
" easycomplete#CleverShiftTab
" easycomplete#CleverTab
" easycomplete#CompleteAdd
" easycomplete#CompleteChanged
" easycomplete#CompleteCursored
" easycomplete#CompleteDone
" easycomplete#Enable
" easycomplete#FireCondition
" easycomplete#GetBindingKeys
" easycomplete#GetCompletedItem
" easycomplete#InsertLeave
" easycomplete#IsBacking
" easycomplete#RegisterSource
" easycomplete#SetCompletedItem
" easycomplete#SetMenuInfo
" easycomplete#TypeEnterWithPUM
" easycomplete#backing
" easycomplete#complete
" easycomplete#context
" easycomplete#flush
" easycomplete#log
" easycomplete#nill
" easycomplete#typing
