function! s:PreparePythonEnvironment()
  if get(g:, 'easycomplete_python3_ready') == 2
    return v:true
  endif

  if get(g:, 'easycomplete_python3_ready') == 1
    return v:false
  endif

  if !has("python3")
    let g:easycomplete_python3_ready = 1
    return v:false
  else
    py3 import vim
    py3 import EasyCompleteUtil.util as EasyCompleteUtil
    let g:easycomplete_python3_ready = 2
    return v:true
  endif
endfunction

function! easycomplete#python#NormalizeSortPY(items)
  if !s:PreparePythonEnvironment() | return a:items | endif
  py3 vim.command("let ret = %s"% EasyCompleteUtil.normalize_sort(vim.eval("a:items")))
  return ret
endfunction

" 实测性能不如 VIM 的实现，一般不用
function! easycomplete#python#FuzzySearchPy(needle, haystack)
  if !s:PreparePythonEnvironment() | return 0 | endif
  let needle = tolower(a:needle)
  let haystack = tolower(a:haystack)
  py3 vim.command("let ret = %s"% EasyCompleteUtil.fuzzy_search(vim.eval("needle"), vim.eval("haystack")))
  return ret
endfunction

function! easycomplete#python#GetSnippetsCodeInfo(snip_object)
  if !s:PreparePythonEnvironment() | return "" | endif
  py3 filepath = vim.eval("a:snip_object.filepath")
  py3 line_number = int(vim.eval("a:snip_object.line_number"))
  py3 vim.command('let ret = %s'% EasyCompleteUtil.snippets_code_info(filepath, line_number))
  return ret
endfunction
