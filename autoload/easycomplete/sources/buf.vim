
function! easycomplete#sources#buf#completor(opt, ctx)
  let l:typing = a:ctx['typing']

  if a:ctx['char'] ==# '.'
    call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], [])
    return v:true
  endif

  if strlen(l:typing) == 0
    call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], [])
    return v:true
  endif

  " 这里异步和非异步都可以
  " call asyncomplete#complete(a:opt['name'], a:ctx, l:startcol, l:matches)
  " call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], keywords_result)
  " call timer_start(0, { -> easycomplete#sources#buf#asyncHandler(l:typing, a:opt['name'], a:ctx, a:ctx['startcol'])})
  call easycomplete#util#AsyncRun(function('s:CompleteHandler'), [l:typing, a:opt['name'], a:ctx, a:ctx['startcol']], 0)
  return v:true
endfunction

" 读取缓冲区词表和字典词表，两者合并输出大词表
function! s:GetKeywords(base)
  let bufKeywordList        = s:GetBufKeywordsList(a:base)
  let wrappedBufKeywordList = map(bufKeywordList,
        \ '{"word":v:val,"dup":1,"icase":1,"kind":"w","equal":1,"menu": "[B]", "info": ""}')
  let result =  s:MenuArrayDistinct(extend(
        \       wrappedBufKeywordList,
        \       s:GetWrappedDictKeywordList()
        \   ),
        \   a:base)
  return result
endfunction

function! s:CompleteHandler(typing, name, ctx, startcol)
  let keywords_result = s:GetKeywords(a:typing)
  call easycomplete#complete(a:name, a:ctx, a:startcol, keywords_result)
endfunction

" 获取当前所有 buff 内的关键词列表
function! s:GetBufKeywordsList(base)
  let tmpkeywords = []
  for buf in getbufinfo()
    if !(bufloaded(buf['bufnr']) && empty(getbufvar(buf['bufnr'], '&buftype')))
      continue
    endif
    let lines = getbufline(buf.bufnr, 1 ,"$")
    for line in lines
      call extend(tmpkeywords, split(line,'[^A-Za-z0-9_#]'))
    endfor
  endfor

  if !empty(a:base)
    let keywordList = filter(tmpkeywords, 'v:val =~ "^'. a:base .'"')
  endif
  let keywordList = s:ArrayDistinct(keywordList)
  if count(keywordList, a:base) == 1
    call remove(keywordList, index(keywordList, a:base))
  endif

  return keywordList
endfunction

" 将字典简单词表转换为补全浮窗所需的列表格式
" 比如字典原始列表为 ['abc','def'] ，输出为
" => [{"word":'abc',"kind":"[ID]","menu":"common.dict"}...]
function! s:GetWrappedDictKeywordList()
  if exists("b:globalDictKeywords")
    return b:globalDictKeywords
  endif
  let b:globalDictKeywords = []

  if empty(&dictionary)
    return []
  endif

  " 如果当前 Buff 所读取的字典目录存在
  let dictsFiles   = split(&dictionary,",")
  let dictkeywords = []
  let dictFile = ""
  for onedict in dictsFiles
    try
      let lines = readfile(onedict)
    catch /.*/
      "echoe "关键词字典不存在!请删除该字典配置 ".
      "           \ "dictionary-=".onedict
      continue
    endtry

    if dictFile == ""
      let dictFile = substitute(onedict,"^.\\+[\\/]","","g")
      let dictFile = substitute(dictFile,".txt","","g")
    endif
    let filename         = dictFile
    let localdicts       = []
    let localWrappedList = []

    if empty(lines)
      continue
    endif

    for line in lines
      if &filetype == "css"
        call extend(localdicts, split(line,'[^A-Za-z0-9_#-]'))
      else
        call extend(localdicts, split(line,'[^A-Za-z0-9_#]'))
      endif
    endfor

    let localdicts = s:ArrayDistinct(localdicts)
    for item in localdicts
      call add(dictkeywords, {
            \   "word" : item ,
            \   "kind" : "w",
            \   "equal":1,
            \   "menu" : "[Dic]"
            \ })
    endfor
  endfor
  let b:globalDictKeywords = dictkeywords

  return dictkeywords
endfunction

" List 去重，类似 uniq，纯数字要去掉
function! s:ArrayDistinct(list)
  if empty(a:list)
    return []
  else
    let tmparray = []
    let uniqlist = uniq(a:list)
    for item in uniqlist
      if !empty(item) &&
            \ !str2nr(item) &&
            \ len(item) != 1
        call add(tmparray,item)
      endif
    endfor
    return tmparray
  endif
endfunction

"popup 菜单内关键词去重，只做buff和dict里的keyword去重
"传入的 list 不应包含 snippet 缩写
"base 是要匹配的原始字符串
function! s:MenuArrayDistinct(menuList, base)
  if empty(a:menuList) || len(a:menuList) == 0
    return []
  endif

  let menulist_tmp = []
  for item in a:menuList
    call add(menulist_tmp, item.word)
  endfor

  let menulist_filter = uniq(filter(menulist_tmp,
        \ 'matchstrpos(v:val, "'.a:base.'")[1] == 0'))

  "[word1,word2,word3...]
  let menulist_assetlist = []
  "[{word:word1,kind..},{word:word2,kind..}..]
  let menulist_result = []

  for item in a:menuList
    let word = get(item, "word")
    if index(menulist_assetlist, word) >= 0
      continue
    elseif index(menulist_filter, word) >= 0
      call add(menulist_result,deepcopy(item))
      call add(menulist_assetlist, word)
    endif
  endfor

  return menulist_result
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction
