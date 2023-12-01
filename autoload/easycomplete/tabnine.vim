" ./sources/tn.vim 负责pum匹配，这里只负责做代码联想提示
" tabnine suggestion 和 tabnine complete 共享一个 job

let s:tabnine_toolkit = v:lua.require("easycomplete.tabnine")

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
  " 非空行
  if !len(trim(getline("."))) == 0
    return
  endif

  call s:flush()
  call s:console('cursor hold fire >>>')
  call easycomplete#sources#tn#SimpleTabNineRequest()
endfunction

function! s:flush()
  call s:tabnine_toolkit.delete_hint()
endfunction

function! easycomplete#tabnine#Callback(res_array)
  call s:console(a:res_array)
  if easycomplete#util#NotInsertMode() || pumvisible()
    call s:flush()
    return
  endif
endfunction

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction
