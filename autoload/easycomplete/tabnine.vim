" ./sources/tn.vim 负责pum匹配，这里只负责做代码联想提示
" tabnine suggestion 和 tabnine complete 共享一个 job

let s:tabnine_toolkit = v:lua.require("easycomplete.tabnine")
" 临时存放 suggest 或者 complete
let b:tabnine_typing_type = ""
let s:tabnine_hint_snippet = ""

function easycomplete#tabnine#ready()
  if !easycomplete#ok('g:easycomplete_tabnine_enable')
    return v:false
  endif
  if !easycomplete#ok('g:easycomplete_tabnine_suggestion')
    return v:false
  endif
  if !easycomplete#installer#LspServerInstalled("tn")
    return v:false
  endif
  if g:env_is_vim
    return v:false
  endif
  return v:true
endfunction

" function! easycomplete#tabnine#init()
"   if !easycomplete#tabnine#ready()
"     return
"   endif
" endfunction

function! easycomplete#tabnine#fire()
  if pumvisible()
    return
  endif
  if !easycomplete#tabnine#ready()
    return
  endif
  " 不是空格除外的最后一个字符
  if !s:is_last_char()
    return
  endif

  call s:flush()
  call easycomplete#tabnine#SuggestFlagSet()
  call easycomplete#sources#tn#SimpleTabNineRequest()
endfunction

function! easycomplete#tabnine#SuggestFlagSet()
  let b:tabnine_typing_type = "suggest"
  call timer_start(800, { -> easycomplete#tabnine#SuggestFlagClear()})
endfunction

function! easycomplete#tabnine#SuggestFlagClear()
  let b:tabnine_typing_type = ""
endfunction

function! easycomplete#tabnine#SuggestFlagCheck()
  if b:tabnine_typing_type == "suggest"
    call easycomplete#tabnine#SuggestFlagClear()
    return v:true
  endif
  return v:false
endfunction

function! s:flush()
  if exists("s:tabnine_hint_snippet") && s:tabnine_hint_snippet == ""
    return
  endif
  call s:tabnine_toolkit.delete_hint()
  call easycomplete#tabnine#SuggestFlagClear()
  let s:tabnine_hint_snippet = ""
endfunction

function! easycomplete#tabnine#flush()
  call s:flush()
endfunction

function! easycomplete#tabnine#Callback(res_array)
  if easycomplete#util#NotInsertMode()
    call s:flush()
    return
  endif
  " call s:console(a:res_array)
  let snippet = s:get_snippet(a:res_array)
  call s:tabnine_toolkit.show_hint(snippet)
  let s:tabnine_hint_snippet = snippet
endfunction

function! easycomplete#tabnine#SnippetReady()
  return s:tabnine_hint_snippet != ""
endfunction

function! easycomplete#tabnine#insert()
  try
    let curr_line = getline(line("."))
    let curr_line = curr_line . s:tabnine_hint_snippet
    call feedkeys(s:tabnine_hint_snippet, 'i')
  catch
    echom v:exception
  endtry
  redraw
  call s:flush()
endfunction

function! s:get_snippet(res_array)
  let res = get(a:res_array, "results", [])
  if empty(res) | return [] | endif
  let new_prefix = ""
  let percent = 0
  for item in res
    let item_new_prefix = get(item, "new_prefix", "")
    if has_key(item, 'completion_metadata')
      let item_percent_str = easycomplete#util#get(item, 'completion_metadata', 'detail')
    else
      let item_percent_str = get(item, 'detail', "   ")
    endif
    let item_percent = str2nr(matchstr(item_percent_str, "\\d\\+"))
    if item_percent == percent
      if len(new_prefix) <= len(item_new_prefix)
        let new_prefix = item_new_prefix
      endif
    elseif item_percent > percent
      let new_prefix = item_new_prefix
      let percent = item_percent
    endif
  endfor
  " remove old prefix
  let old_prefix = get(a:res_array, "old_prefix", "")
  return new_prefix[len(old_prefix):]
endfunction

function! s:is_last_char()
  let current_col = col('.')
  let current_line = getline('.')
  if current_col - 1 == len(current_line)
    return v:true
  endif
  let rest_of_line = current_line[current_col - 1:]
  if rest_of_line =~ "^\\s\\+$"
    return v:true
  else
    return v:false
  endif
endfunction

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction
