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
