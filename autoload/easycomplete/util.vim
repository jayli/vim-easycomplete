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

function! easycomplete#util#GetAttachedPlugins()
  let all_plugins = easycomplete#GetAllPlugins()
  let ft = &filetype
  let attached_plugins = []
  for name in keys(all_plugins)
    let plugin = get(all_plugins, name)
    if empty(plugin) | continue | endif
    let whitelist = get(plugin, 'whitelist')
    if index(whitelist, ft) >= 0
      call add(attached_plugins, plugin)
    endif
  endfor
  return attached_plugins
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
    " redraw " bugfix: redraw 会造成光标的闪烁
  catch /.*/
    return 0
  endtry
endfunction

" 性能很差，谨慎使用
function! easycomplete#util#uniq(menu_list)
  let tmp_list = deepcopy(a:menu_list)
  let result_list = []
  for item in tmp_list
    if !s:HasItem(result_list, item)
      call add(result_list, item)
    endif
  endfor
  return result_list
endfunction

function! s:HasItem(list,item)
  let flag = v:false
  for item in a:list
    if s:SameItem(item,a:item)
      let flag = v:true
      break
    endif
  endfor
  return flag
endfunction

function! s:SameItem(item1,item2)
  let item1 = a:item1
  let item2 = a:item2
  if get(item1, "word") ==# get(item2, "word")
        \ && get(item1, "menu") ==# get(item2, "menu")
        \ && get(item1, "kind") ==# get(item2, "kind")
        \ && get(item1, "abbr") ==# get(item2, "abbr")
        \ && get(item1, "info") ==# get(item2, "info")
    return v:true
  else
    return v:false
  endif
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
  let t_name = s:TrimWavyLine(t_name)
  let info = ""
  for item in a:all_menu
    if type(item) != type({})
      continue
    endif
    let i_name = empty(get(item, "abbr")) ? get(item, "word") : get(item, "abbr")
    let i_name = s:TrimWavyLine(i_name)
    if t_name ==# i_name && get(a:item, "menu") ==# get(item, "menu")
      if has_key(item, "info")
        let info = get(item, "info")
      endif
      break
    endif
  endfor
  return info
endfunction

function! s:TrimWavyLine(str)
  if strlen(a:str) >= 2 && a:str[-1:] == "~"
    return a:str[0:-2]
  endif
  return a:str
endfunction

function! easycomplete#util#TrimWavyLine(...)
  return call("s:TrimWavyLine", a:000)
endfunction

function! easycomplete#util#str2list(expr)
  if exists("*str2list")
    return str2list(a:expr)
  endif
  if type(a:expr) ==# v:t_list
    return a:expr
  endif
  let l:index = 0
  let l:arr = []
  while l:index < strlen(a:expr)
    call add(l:arr, char2nr(a:expr[l:index]))
    let l:index += 1
  endwhile
  return l:arr
endfunction

function! easycomplete#util#IsJson(str)
  let flag = v:true
  if a:str == "\r" || a:str == "\n"
    let flag = v:false
  else
    try
      call json_decode(a:str)
    catch /^Vim\%((\a\+)\)\=:E474/
      let flag = v:false
    endtry
  endif
  return flag
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
  " 性能测试：356 次调用实测情况
  "  - s:FuzzySearchRegx 速度最快
  "  - s:FuzzySearchCustom 速度次之
  "  - s:FuzzySearchSpeedUp 速度次之
  "  - s:FuzzySearchPy 速度最差
  return s:FuzzySearchRegx(a:needle, a:haystack) " 0.027728
  return s:FuzzySearchCustom(a:needle, a:haystack) " 0.041983
  return s:FuzzySearchSpeedUp(a:needle, a:haystack) " 0.054845
  return s:FuzzySearchPy(a:needle, a:haystack) " 0.088703
endfunction

function! s:FuzzySearchRegx(needle, haystack)
  let tlen = strlen(a:haystack)
  let qlen = strlen(a:needle)
  if qlen > tlen
    return v:false
  endif
  if qlen == tlen
    return a:needle ==? a:haystack ? v:true : v:false
  endif

  let needle_ls = map(easycomplete#util#str2list(a:needle), { _, val -> nr2char(val)})
  let needle_ls_regx = join(needle_ls, "[a-zA-Z0-9_#:\.]*")

  return (match(a:haystack, needle_ls_regx) >= 0) ? v:true : v:false
endfunction

function! s:FuzzySearchSpeedUp(needle, haystack)
  let tlen = strlen(a:haystack)
  let qlen = strlen(a:needle)
  if qlen > tlen
    return v:false
  endif
  if qlen == tlen
    return a:needle ==? a:haystack ? v:true : v:false
  endif

  let needle_ls = easycomplete#util#str2list(tolower(a:needle))
  let haystack_ls = easycomplete#util#str2list(tolower(a:haystack))

  let cursor_n = 0
  let cursor_h = 0
  let matched = v:false

  while cursor_h < len(haystack_ls)
    if haystack_ls[cursor_h] == needle_ls[cursor_n]
      if cursor_n == len(needle_ls) - 1
        let matched = v:true
        break
      endif
      let cursor_n += 1
    endif
    let cursor_h += 1
  endwhile
  return matched
endfunction

function! s:FuzzySearchCustom(needle, haystack)
  let tlen = strlen(a:haystack)
  let qlen = strlen(a:needle)
  if qlen > tlen
    return v:false
  endif
  if qlen == tlen
    return a:needle ==? a:haystack ? v:true : v:false
  endif

  let needle_ls = easycomplete#util#str2list(tolower(a:needle))
  let haystack_ls = easycomplete#util#str2list(tolower(a:haystack))

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
        if strlen(modified_info_item) > t_maxwidth
          let t_maxwidth = strlen(modified_info_item)
        endif
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
        if t_maxwidth < maxwidth
          let t_maxwidth += 1
        elseif t_maxwidth == maxwidth
          let t_maxwidth += 2
        endif
        let t_info[l:count] = repeat("-", t_maxwidth)
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

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction

function! easycomplete#util#once(...)
  if get(g:, 'easycomplete_log_once')
    return
  endif
  let g:easycomplete_log_once = 1
  return call('easycomplete#util#log', a:000)
endfunction

function! easycomplete#util#log(...)
  let l:res = call('s:NormalizeLogMsg', a:000)
  call s:MsgLog(l:res, 'WarningMsg')
endfunction

function! easycomplete#util#info(...)
  let l:res = call('s:NormalizeLogMsg', a:000)
  call s:MsgLog(l:res, 'MoreMsg')
endfunction

function! easycomplete#util#NormalizeLogMsg(...)
  return call("s:NormalizeLogMsg", a:000)
endfunction

function! s:NormalizeLogMsg(...)
  let l:args = a:000
  let l:res = ""
  if empty(a:000)
    let l:res = ""
  elseif len(a:000) == 1
    if type(a:1) == type("")
      let l:res = a:1
    elseif index([2,7], type(a:000))
      let l:res = string(a:1)
    else
      let l:res = a:1
    endif
  else
    for item in l:args
      if type(item) == type("")
        let l:res = l:res . " " . item
      else
        let l:res = l:res . " " . json_encode(item)
      endif
    endfor
  endif
  return l:res
endfunction

function! s:MsgLog(res, style)
  redraw
  exec 'echohl ' . a:style
  echom printf('>>> %s', a:res)
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
  for item in easycomplete#util#str2list(a:a)
    if item == char2nr(a:b)
      let l:count += 1
    endif
  endfor
  return l:count
endfunction

function! easycomplete#util#ProfileStart()
  exec "profile start profile.log"
  exec "profile func *"
  exec "profile file *"
endfunction

function! easycomplete#util#ProfileStop()
  exec "profile pause"
endfunction

"popup 菜单内关键词去重，只做buff、dict和lsp里的keyword去重
"snippet 不去重
function! easycomplete#util#distinct(menu_list)
  if empty(a:menu_list) || len(a:menu_list) == 0
    return []
  endif

  let result_items = deepcopy(a:menu_list)

  let buf_list = []
  for item in a:menu_list
    if item.menu == "[B]" || item.menu == "[D]"
      call add(buf_list, item.word)
    endif
  endfor

  for item in a:menu_list
    if item.menu == "[S]" || (item.menu == "[B]" || item.menu == '[D]')
      continue
    endif

    let word = has_key(item, "abbr") && !empty(item.abbr) ?
          \ item.abbr : get(item, "word", "")

    if index(buf_list, word) >= 0
      call filter(result_items,
            \ '!((v:val.menu == "[B]" || v:val.menu == "[D]") && v:val.word ==# "' . word . '")')
    endif
  endfor
  return result_items
endfunction

" 判断 items 列表中是否包含 keyname 的项
function! easycomplete#util#HasKey(obj,keyname)
  for item in a:obj
    if (empty(item.abbr) ? item.word : item.abbr) ==# a:keyname
      return v:true
    endif
  endfor
  return v:false
endfunction

function! easycomplete#util#AutoLoadDict()
  if !exists("g:easycomplete_dict")
    let g:easycomplete_dict = []
  endif
  if index(g:easycomplete_dict, &filetype) >= 0
    return
  endif
  call add(g:easycomplete_dict, &filetype)
  for es_path in split(&rtp, ",")
    if stridx(es_path, "vim-easycomplete") >= 0
      let path =  globpath(es_path, 'dict/' . &filetype . '.txt')
      if len(path) != 0 && strridx(&dictionary, path) < 0
        silent noa execute 'setlocal dictionary+='.fnameescape(path)
      endif
      break
    endif
  endfor
endfunction

" 这是 Typing 过程中耗时最多的函数，决定整体性能瓶颈
" maxlength: 针对 all_menu 的一定数量的前排元素做过滤，超过的元素就丢弃，牺牲
" 匹配精度保障性能，防止 all_menu 过大时过滤耗时太久，一般设在 500
function! easycomplete#util#CompleteMenuFilter(all_menu, word, maxlength)
  return s:CompleteMenuFilterVim(a:all_menu, a:word, a:maxlength)
  " TODO
  return easycomplete#python#CompleteMenuFilterPy(a:all_menu, a:word, a:maxlength)
endfunction

function! s:CompleteMenuFilterVim(all_menu, word, maxlength)
  let word = a:word
  if index(easycomplete#util#str2list(word), char2nr('.')) >= 0
    let word = substitute(word, "\\.", "\\\\\\\\.", "g")
  endif

  " 完整匹配
  let original_matching_menu = []
  " 非完整匹配
  let otherwise_matching_menu = []
  " 模糊匹配结果
  let otherwise_fuzzymatching = []

  " dam: 性能均衡参数，用来控制完整匹配和模糊匹配的次数均衡
  " 通常情况下 dam 越大，完整匹配次数越多，模糊匹配次数就越少，速度越快
  " 精度越好，但下面这两种情况往往会大面积存在
  "
  " - 大量同样前缀的单词拥挤在一起的情况，dam 越大越好
  " - 相同前缀词较少的情况，完整匹配成功概率较小，尽早结束完整匹配性能
  "   最好，这时 dam 越小越好
  "
  " 折中设置 dam 为 100
  let dam = 100
  let regx_com_times = 0
  let count_index = 0

  " 这里用单循环来遍历主要是处于性能最优考虑，非精度最优
  for item in deepcopy(a:all_menu)
    let item_word = s:GetItemWord(item)
    if a:word[0] != "_" && item_word[0] == "_"
      let item_word = substitute(item_word, "_\\+", "", "")
    endif
    if strlen(item_word) < strlen(a:word) | continue | endif
    if count_index > a:maxlength | break | endif
    let regx_com_times += 1
    if stridx(item_word, word) == 0 && count_index < dam
      call add(original_matching_menu, item)
      let count_index += 1
    elseif easycomplete#util#FuzzySearch(word, item_word)
      call add(otherwise_fuzzymatching, item)
      let count_index += 1
    else
      call add(otherwise_matching_menu, item)
    endif
  endfor

  call sort(original_matching_menu, "easycomplete#util#SortTextComparatorByLength")
  let result = original_matching_menu + otherwise_fuzzymatching
  let filtered_menu = map(result, function("easycomplete#util#PrepareInfoPlaceHolder"))
  return filtered_menu
endfunction

function! s:GetItemWord(item)
  let t_str = empty(get(a:item, 'abbr', '')) ? get(a:item, 'word'): get(a:item, 'abbr', '')
  let t_str = easycomplete#util#TrimWavyLine(t_str)
  return t_str
endfunction

" TODO 性能优化，4 次调用 0.08 s
function! easycomplete#util#SortTextComparatorByLength(entry1, entry2)
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

function! easycomplete#util#PrepareInfoPlaceHolder(key, val)
  if !(has_key(a:val, "info") && type(a:val.info) == type("") && !empty(a:val.info))
    let a:val.info = ""
  endif
  let a:val.equal = 1
  return a:val
endfunction

" TODO 性能优化，4 次调用 0.09 s
function! easycomplete#util#SortTextComparatorByAlphabet(entry1, entry2)
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

function! easycomplete#util#GetItemWord(...)
  return call("s:GetItemWord", a:000)
endfunction

" Same as easycomplete#python#GetSnippetsCodeInfo
" 实测 vim 性能比 python 快五倍
" 27 次调用，py 用时 0.012392
" 27 次调用，vim 用时0.002804
function! easycomplete#util#GetSnippetsCodeInfo(snip_object)
  let filepath = a:snip_object.filepath
  let line_number = a:snip_object.line_number

  if !exists('g:easycomplete_snip_files')
    let g:easycomplete_snip_files = {}
  endif
  if has_key(g:easycomplete_snip_files, filepath)
    let snip_ctx = get(g:easycomplete_snip_files, filepath)
  else
    let snip_ctx = readfile(filepath)
    let g:easycomplete_snip_files[filepath] = snip_ctx
  endif

  let cursor_line = line_number

  while cursor_line + 1 < len(snip_ctx)
    if match(snip_ctx[cursor_line + 1], '\(snippet\|endsnippet\)') == 0
      break
    else
      let cursor_line += 1
    endif
  endwhile
  let start_line_index = line_number
  let end_line_index = cursor_line

  return snip_ctx[start_line_index:end_line_index]
endfunction

function! easycomplete#util#expandable(item)
  if has_key(a:item, 'user_data') && !empty(get(a:item, 'user_data', ''))
    let user_data_str = get(a:item, 'user_data', '')
    if !easycomplete#util#IsJson(user_data_str)
      return v:false
    endif

    let l:data = json_decode(user_data_str)
    if has_key(l:data, 'expandable') && get(l:data, 'expandable', 0)
      return get(l:data, 'expandable', 0)
    endif
  else
    return v:false
  endif
endfunction

" 一个补全插件可以携带多个 LSP Server 为其工作，比如 typescript 中可以有 ts 和
" tss 两个 LSP 实现，而且可以同时生效。但实际应用中要杜绝这种情况，所以我们约
" 定一个语言当前只注册一个 LSP Server，GetLspPlugin() 即返回当前携带 LSP
" Server 的补全 Plugin 对象，而不返回一个数组
function! easycomplete#util#GetLspPlugin()
  let attached_plugins = easycomplete#util#GetAttachedPlugins()
  let ret_plugin = {}
  for plugin in attached_plugins
    if has_key(plugin, 'gotodefinition') && has_key(plugin, 'command')
      let ret_plugin = plugin
      break
    endif
  endfor
  return ret_plugin
endfunction

function! easycomplete#util#LspType(c_type)
  let l:kinds = {
      \ 'Text':          1,  'Method':      2,
      \ 'Function':      3,  'Constructor': 4,
      \ 'Field':         5,  'Variable':    6,
      \ 'Class':         7,  'Interface':   8,
      \ 'Module':        9,  'Property':    10,
      \ 'Unit':          11, 'Value':       12,
      \ 'Enum':          13, 'Keyword':     14,
      \ 'Snippet':       15, 'Color':       16,
      \ 'File':          17, 'Reference':   18,
      \ 'Folder':        19, 'EnumMember':  20,
      \ 'Constant':      21, 'Struct':      22,
      \ 'Event':         23, 'Operator':    24,
      \ 'TypeParameter': 25
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

function! easycomplete#util#GetVimCompletionItems(response, plugin_name)
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

    if has_key(l:completion_item, 'textEdit') && type(l:completion_item['textEdit']) == type({})
      if has_key(l:completion_item['textEdit'], 'nextText')
        let l:vim_complete_item['word'] = l:completion_item['textEdit']['nextText']
      endif
      if has_key(l:completion_item['textEdit'], 'newText')
        let l:vim_complete_item['word'] = l:completion_item['textEdit']['newText']
      endif
    elseif has_key(l:completion_item, 'insertText') && !empty(l:completion_item['insertText'])
      let l:vim_complete_item['word'] = l:completion_item['insertText']
    else
      let l:vim_complete_item['word'] = l:completion_item['label']
    endif

    if l:expandable
      let l:origin_word = l:vim_complete_item['word']
      let l:placeholder_regex = '\$[0-9]\+\|\${\%(\\.\|[^}]\)\+}'
      let l:vim_complete_item['word'] = easycomplete#lsp#utils#make_valid_word(
            \ substitute(l:vim_complete_item['word'],
            \ l:placeholder_regex, '', 'g'))
      let l:placeholder_position = match(l:origin_word, l:placeholder_regex)
      let l:cursor_backing_steps = strlen(l:vim_complete_item['word'][l:placeholder_position:])
      let l:vim_complete_item['abbr'] = l:completion_item['label'] . '~'
      if strlen(l:origin_word) > strlen(l:vim_complete_item['word'])
        let l:vim_complete_item['user_data'] = json_encode({'expandable':1,
              \ 'placeholder_position': l:placeholder_position,
              \ 'cursor_backing_steps': l:cursor_backing_steps})
      endif
    elseif l:completion_item['label'] =~ ".(.*)$"
      let l:vim_complete_item['abbr'] = l:completion_item['label']
      let l:vim_complete_item['word'] = substitute(l:completion_item['label'],"(.*)$","",'g') . "()"
      let l:vim_complete_item["user_data"] = json_encode({
        \ 'expandable': 1,
        \ 'placeholder_position': strlen(l:vim_complete_item['word']) - 1,
        \ 'cursor_backing_steps': 1
        \ })
    else
      let l:vim_complete_item['abbr'] = l:completion_item['label']
    endif

    let l:t_info = s:NormalizeLspInfo(get(l:completion_item, "documentation", ""))
    if !empty(get(l:completion_item, "detail", ""))
      let l:vim_complete_item['info'] = [get(l:completion_item, "detail", "")] + l:t_info
    else
      let l:vim_complete_item['info'] = l:t_info
    endif

    let l:vim_complete_items += [l:vim_complete_item]
  endfor

  if index(['nim','kotlin'], &filetype) >= 0
    let l:vim_complete_items = easycomplete#util#uniq(l:vim_complete_items)
  endif

  return { 'items': l:vim_complete_items, 'incomplete': l:incomplete }
endfunction

function! s:NormalizeLspInfo(info)
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

" s:find_complete_servers() 获取 LSP Complete Server 信息
function! easycomplete#util#FindLspServers() abort
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
