function! easycomplete#python#NormalizeSortPY(items)
pyx << EOF
import vim
import json
items = vim.eval("a:items")

def getKey(el):
  if len(el["abbr"]) != 0:
    k1 = el["abbr"]
  else:
    k1 = el["word"]
  return k1

def getKeyByAlphabet(el):
  return getKey(el).lower().rjust(5,"a")

def getKeyByLength(el):
  return len(getKey(el))

# 先按照长度排序
items.sort(key=getKeyByLength)
# 再按照字母表排序
items.sort(key=getKeyByAlphabet)
vim.command("let ret = %s"%json.dumps(items))
EOF
  return ret
endfunction

" 实测性能不如 VIM 的实现
function! easycomplete#python#FuzzySearchPy(needle, haystack)
  let needle = tolower(a:needle)
  let haystack = tolower(a:haystack)
pyx << EOF
import vim
needle = vim.eval("needle")
haystack = vim.eval("haystack")

def FuzzySearch(needle, haystack):
  flag = 1
  tlen = len(haystack)
  qlen = len(needle)
  if qlen > tlen:
    return 0
  elif qlen == tlen:
    if needle == haystack:
      return 1
    else:
      return 0
  else:
    needle_ls = list(needle)
    haystack_ls = list(haystack)
    j = 0
    fallback = 0
    for nch in needle_ls:
      fallback = 0
      while j < tlen:
        if haystack_ls[j] == nch:
          j += 1
          fallback = 1
          break
        else:
          j += 1
      if fallback == 1:
        continue
      return 0
    return 1

flag = FuzzySearch(needle, haystack)
vim.command("let ret = %s"%flag)
EOF
  return ret
endfunction
