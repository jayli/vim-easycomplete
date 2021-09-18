py3 import vim
py3 import EasyCompleteUtil.util as EasyCompleteUtil

function! easycomplete#python#NormalizeSortPY(items)
  py3 vim.command("let ret = %s"% EasyCompleteUtil.normalize_sort(vim.eval("a:items")))
  return ret
endfunction

" 实测性能不如 VIM 的实现，一般不用
function! easycomplete#python#FuzzySearchPy(needle, haystack)
  let needle = tolower(a:needle)
  let haystack = tolower(a:haystack)
  py3 vim.command("let ret = %s"% EasyCompleteUtil.fuzzy_search(vim.eval("needle"), vim.eval("haystack")))
  return ret
endfunction

function! easycomplete#python#GetSnippetsCodeInfo(snip_object)
  " echom a:snip_object.filepath
  " echom a:snip_object.line_number
  py3 filepath = vim.eval("a:snip_object.filepath")
  py3 line_number = int(vim.eval("a:snip_object.line_number"))
  py3 vim.command('let ret = %s'% EasyCompleteUtil.snippets_code_info(filepath, line_number))
  return ret
endfunction
