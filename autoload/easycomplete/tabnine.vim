" ./sources/tn.vim 负责pum匹配，这里只负责做代码联想提示
" tabnine suggestion 和 tabnine complete 共享一个 job

let s:tab9 = v:lua.require("easycomplete.tabnine")

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
  return v:true
endfunction
