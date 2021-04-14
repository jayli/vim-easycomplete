""" 常用的工具函数
function! easycomplete#util#filetype()
  " SourcePost 事件中 &filetype 为空，应当从 bufname 中根据后缀获取
  " TODO 这个函数需要重写
  let ext_part = easycomplete#util#extention()
  let filetype_dict = {
        \ 'js':'javascript',
        \ 'ts':'typescript',
        \ 'jsx':'javascript.jsx',
        \ 'tsx':'javascript.jsx',
        \ 'py':'python',
        \ 'rb':'ruby',
        \ 'sh':'shell'
        \ }
  if index(['js','ts','jsx','tsx','py','rb','sh'], ext_part) >= 0
    return filetype_dict[ext_part]
  else
    return ext_part
  endif
endfunction

function! easycomplete#util#extention()
  let filename = fnameescape(fnamemodify(bufname('%'),':p'))
  let ext_part = substitute(filename,"^.\\+[\\.]","","g")
  return ext_part
endfunction

" 运行一个全局的 Timer，只在 complete 的时候用
" 参数：method, args, timer
" method 必须是一个全局方法,
" timer 为空则默认为0
function! easycomplete#util#AsyncRun(...)
  let Method = a:1
  let args = exists('a:2') ? a:2 : []
  let delay = exists('a:3') ? a:3 : 0
  let g:easycomplete_popup_timer = timer_start(delay, { -> easycomplete#util#call(Method, args)})
  return g:easycomplete_popup_timer
endfunction

function! easycomplete#util#StopAsyncRun()
  if exists('g:easycomplete_popup_timer') && g:easycomplete_popup_timer > 0
    call timer_stop(g:easycomplete_popup_timer)
  endif
endfunction

function! easycomplete#util#call(method, args) abort
  try
    if type(a:method) == 2 " 是函数
      let TmpCallback = function(a:method, a:args)
      call TmpCallback()
    endif
    if type(a:method) == type("string") " 是字符串
      call call(a:method, a:args)
    endif
    let g:easycomplete_popup_timer = -1
    redraw
  catch /.*/
    return 0
  endtry
endfunction

function! easycomplete#util#location(path, line, col, ...) abort
  normal! m'
  let l:mods = a:0 ? a:1 : ''
  let l:buffer = bufnr(a:path)
  if l:mods ==# '' && &modified && !&hidden && l:buffer != bufnr('%')
    let l:mods = &splitbelow ? 'rightbelow' : 'leftabove'
  endif
  if l:mods ==# ''
    if l:buffer == bufnr('%')
      let l:cmd = ''
    else
      let l:cmd = (l:buffer !=# -1 ? 'b ' . l:buffer : 'edit ' . fnameescape(a:path)) . ' | '
    endif
  else
    let l:cmd = l:mods . ' ' . (l:buffer !=# -1 ? 'sb ' . l:buffer : 'split ' . fnameescape(a:path)) . ' | '
  endif
  let full_cmd = l:cmd . 'call cursor('.a:line.','.a:col.')'
  execute full_cmd
endfunction

function! easycomplete#util#normalize(buf_name)
  return substitute(a:buf_name, '\\', '/', 'g')
endfunction

function! easycomplete#util#UpdateTagStack() abort
  let l:bufnr = bufnr('%')
  let l:item = {'bufnr': l:bufnr, 'from': [l:bufnr, line('.'), col('.'), 0], 'tagname': expand('<cword>')}
  let l:winid = win_getid()

  let l:stack = gettagstack(l:winid)
  if l:stack['length'] == l:stack['curidx']
    " Replace the last items with item.
    let l:action = 'r'
    let l:stack['items'][l:stack['curidx']-1] = l:item
  elseif l:stack['length'] > l:stack['curidx']
    " Replace items after used items with item.
    let l:action = 'r'
    if l:stack['curidx'] > 1
      let l:stack['items'] = add(l:stack['items'][:l:stack['curidx']-2], l:item)
    else
      let l:stack['items'] = [l:item]
    endif
  else
    " Append item.
    let l:action = 'a'
    let l:stack['items'] = [l:item]
  endif
  let l:stack['curidx'] += 1

  call settagstack(l:winid, l:stack, l:action)
endfunction

function! easycomplete#util#trim(str)
  if !empty(a:str)
    let a1 = substitute(a:str, "^\\s\\+\\(.\\{\-}\\)$","\\1","g")
    let a1 = substitute(a:str, "^\\(.\\{\-}\\)\\s\\+$","\\1","g")
    return a1
  endif
  return ""
endfunction

function! easycomplete#util#GetInfoByCompleteItem(item, all_menu)
  let t_name = empty(get(a:item, "abbr")) ? get(a:item, "word") : get(a:item, "abbr")
  let info = ""
  for item in a:all_menu
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

function! easycomplete#util#TagBarExists()
  try
    call funcref("tagbar#StopAutoUpdate")
  catch /^Vim\%((\a\+)\)\=:E700/
    return v:false
  endtry
  return v:true
endfunction

" 存储ctx，异步返回时取出
function! easycomplete#util#RestoreCtx(ctx, request_seq)
  " 删除多余的 ctx
  let arr = []
  if !exists("s:ctx_list")
    let s:ctx_list = {}
  endif
  for item in keys(s:ctx_list)
    call add(arr, str2nr(item))
  endfor
  let sorted_arr = reverse(sort(arr, "s:nSort"))
  let new_dict = {}
  let index = 0
  while index < 10 && index < len(sorted_arr)
    let t_index = string(sorted_arr[index])
    let new_dict[t_index] = get(s:ctx_list, t_index)
    let index = index + 1
  endwhile
  let s:ctx_list = new_dict
  let s:ctx_list[string(a:request_seq)] = a:ctx
endfunction

function! easycomplete#util#GetCtxByRequestSeq(seq)
  if !exists("s:ctx_list")
    let s:ctx_list = {}
  endif
  return get(s:ctx_list, string(a:seq))
endfunction

function! s:nSort(a, b)
    return a:a == a:b ? 0 : a:a > a:b ? 1 : -1
endfunction

function! easycomplete#util#FuzzySearch(needle, haystack)
  " 实测 vim script 速度更快，这里始终使用 VIM 的实现
  " Python 实现的执行速度 ---
  " FUNCTION  easycomplete#util#FuzzySearch()
  "     Defined: ~/.vim/bundle/vim-easycomplete/autoload/easycomplete/util.vim:184
  " Called 201 times
  " Total time:   0.056193
  "  Self time:   0.005171
  " VIM 实现的执行速度 --- 
  " FUNCTION  easycomplete#util#FuzzySearch()
  "     Defined: ~/.vim/bundle/vim-easycomplete/autoload/easycomplete/util.vim:184
  " Called 201 times
  " Total time:   0.031811
  "  Self time:   0.004698
  if v:false && has("pythonx")
    return s:FuzzySearchPy(a:needle, a:haystack)
  else
    return s:FuzzySearchVim(a:needle, a:haystack)
  endif
endfunction

function! s:FuzzySearchVim(needle, haystack)
  let tlen = strlen(a:haystack)
  let qlen = strlen(a:needle)
  if qlen > tlen
    return v:false
  endif
  if qlen == tlen
    return a:needle ==? a:haystack ? v:true : v:false
  endif

  let needle_ls = str2list(tolower(a:needle))
  let haystack_ls = str2list(tolower(a:haystack))

  let i = 0
  let j = 0
  let fallback = 0
  while i < qlen
    let nch = needle_ls[i]
    let i += 1
    let fallback = 0
    while j < tlen
      if haystack_ls[j] == nch
        let j += 1
        let fallback = 1
        break
      else
        let j += 1
      endif
    endwhile
    if fallback == 1
      continue
    endif
    return v:false
  endwhile
  return v:true
endfunction

function! s:FuzzySearchPy(...)
  return call("easycomplete#python#FuzzySearchPy", a:000)
endfunction

function! easycomplete#util#ModifyInfoByMaxwidth(info, maxwidth)
  let border = " "
  let maxwidth = a:maxwidth - 2

  if type(a:info) == type("")
    if strlen(a:info) == 0
      return ""
    endif
    if trim(a:info) =~ "^-\\+$"
      return a:info
    endif
    " 字符串长度小于 maxwidth
    if strlen(a:info) <= maxwidth
      return border . a:info . border
    endif
    let span = maxwidth
    let cursor = 0
    let t_info = []
    let t_line = ""

    " 字符串长度大于 maxwidth
    while cursor <= (strlen(a:info) - 1)
      let t_line = t_line . a:info[cursor]
      if (cursor + 1) % (span) == 0 && cursor != 0
        call add(t_info, border . t_line . border)
        let t_line = ""
      endif
      let cursor += 1
    endwhile
    if !empty(t_line)
      call add(t_info, border . t_line . border)
    endif
    " t_info is Array
    return t_info
  endif

  let t_maxwidth = 0 " 实际最大宽度
  if type(a:info) == type([])
    let t_info = []
    for item in a:info
      let modified_info_item = easycomplete#util#ModifyInfoByMaxwidth(item, maxwidth)
      if type(modified_info_item) == type("")
        let t_maxwidth = strlen(modified_info_item)
        call add(t_info, modified_info_item)
      endif
      if type(modified_info_item) == type([])
        let t_maxwidth = maxwidth
        let t_info = t_info + modified_info_item
      endif
    endfor

    " 构造分割线
    let l:count = 0
    for item in t_info
      " 构造分割线
      if trim(item) =~ "^-\\+$"
        let t_info[l:count] = repeat("-", maxwidth)
        break
      endif
      let l:count += 1
    endfor

    " hack for vim popup menu scrollbar
    if len(t_info) >= 2
      if t_info[-1] ==# ""
        unlet t_info[len(t_info)-1]
      endif
    endif
    return t_info
  endif
endfunction

function! easycomplete#util#InsertMode()
  return !easycomplete#util#NotInsertMode()
endfunction

function! easycomplete#util#NotInsertMode()
  if g:env_is_vim
    return mode()[0] != 'i' ? v:true : v:false
  endif
  if g:env_is_nvim
    return mode() == 'i' ? v:false : v:true
  endif
endfunction

function! easycomplete#util#Sendkeys(keys)
  call feedkeys( a:keys, 'in' )
endfunction

function! easycomplete#util#GetTypingWord()
  let start = col('.') - 1
  let line = getline('.')
  let width = 0
  " 正常情况这里取普通单词逻辑不应当变化
  " 如果不同语言对单词组成字符界定不一，在主流程中处理
  " 比如 vim 把 'g:abc' 对待为一个完整单词
  let regx = '[a-zA-Z0-9_#]'
  while start > 0 && line[start - 1] =~ regx
    let start = start - 1
    let width = width + 1
  endwhile
  let word = strpart(line, start, width)
  return word
endfunction

function! easycomplete#util#LspType(c_type)
  let l:kinds = {
      \ 'Text' : 1,
      \ 'Method' : 2,
      \ 'Function' : 3,
	    \ 'Constructor' : 4,
      \ 'Field' : 5,
      \ 'Variable' : 6,
      \ 'Class' : 7,
      \ 'Interface' : 8,
      \ 'Module' : 9,
      \ 'Property' : 10,
      \ 'Unit' : 11,
      \ 'Value' : 12,
      \ 'Enum' : 13,
      \ 'Keyword' : 14,
      \ 'Snippet' : 15,
      \ 'Color' : 16,
      \ 'File' : 17,
      \ 'Reference' : 18,
      \ 'Folder' : 19,
      \ 'EnumMember' : 20,
      \ 'Constant' : 21,
      \ 'Struct' : 22,
      \ 'Event' : 23,
      \ 'Operator' : 24,
      \ 'TypeParameter' : 25
      \ }
  let l:type = ""
  for item in keys(l:kinds)
    if a:c_type == l:kinds[item]
      let l:type = tolower(item[0])
      break
    endif
  endfor
  return l:type
endfunction

function! s:log(msg)
  call easycomplete#util#log(a:msg)
endfunction

function! easycomplete#util#log(...)
  let l:args = a:000
  let l:res = ""
  if empty(a:000)
    let l:res = ""
  elseif len(a:000) == 1
    if index([2,7], type(a:000))
      let l:res = string(a:1)
    else
      let l:res = a:1
    endif
  else
    for item in l:args
      let l:res = l:res . " " . json_encode(item)
    endfor
  endif
  echohl MoreMsg
  echom '>>> '. l:res
  echohl NONE
endfunction

function! easycomplete#util#GotoWindow(winid) abort
  if a:winid == bufwinid(bufnr(""))
    return
  endif
  for window in range(1, winnr('$'))
    call s:GotoWinnr(window)
    if a:winid == bufwinid(bufnr(""))
      break
    endif
  endfor
endfunction " }}}

function! s:GotoWinnr(winnr) abort
  let cmd = type(a:winnr) == type(0) ? a:winnr . 'wincmd w'
        \ : 'wincmd ' . a:winnr
  noautocmd execute cmd
  call execute('redraw','silent!')
endfunction " }}}

" for tsserver only
function! easycomplete#util#NormalizeEntryDetail(item)
  let l:title = ""
  let l:desp_list = []
  let l:doc_list = []

  let l:title = join([
        \ get(a:item, 'kindModifiers'),
        \ get(a:item, 'name'),
        \ get(a:item, 'kind'),
        \ get(a:item, 'name')], " ")

  if !empty(get(a:item, "displayParts")) && len(get(a:item, "displayParts")) > 0
    let l:desp_list = []
    let l:t_line = ""
    for dis_item in get(a:item, "displayParts")
      if dis_item.text =~ "\\(\\r\\|\\n\\)"
        call add(l:desp_list, l:t_line)
        let l:t_line = ""
      else 
        let l:t_line  = l:t_line  . dis_item.text
      endif
    endfor
    if !empty(l:t_line)
      call add(l:desp_list, l:t_line)
    endif
  endif

  if !empty(get(a:item, "documentation")) && len(get(a:item, "documentation")) > 0
    let l:doc_list = ["------------"] " 任意长度即可, 显示的时候回重新计算分割线宽度
    let l:t_line = ""
    for document_item in get(a:item, "documentation")
      if document_item.text =~ "\\(\\r\\|\\n\\)"
        call add(l:doc_list, l:t_line)
        let l:t_line = ""
      else
        let l:t_line = l:t_line . document_item.text
      endif
    endfor
    if !empty(l:t_line)
      call add(l:doc_list, l:t_line)
    endif
  endif

  return [l:title] + l:desp_list + l:doc_list
endfunction

" b 字符在 a 中出现的次数
function! easycomplete#util#contains(a, b)
  let l:count = 0
  for item in str2list(a:a)
    if item == char2nr(a:b)
      let l:count += 1
    endif
  endfor
  return l:count
endfunction
