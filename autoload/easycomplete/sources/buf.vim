
let s:lua_toolkit = easycomplete#util#HasLua() ? v:lua.require("easycomplete") : v:null

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

  " 这里异步和非异步都可以，性能考虑，如果返回空用同步，如果数据量大用异步
  " call asyncomplete#complete(a:opt['name'], a:ctx, l:startcol, l:matches)
  " call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], keywords_result)
  " call timer_start(0, { -> easycomplete#sources#buf#asyncHandler(l:typing,
  "                                         \ a:opt['name'], a:ctx, a:ctx['startcol'])})
  call easycomplete#util#AsyncRun(function('s:CompleteHandler'),
        \ [l:typing, a:opt['name'], a:ctx, a:ctx['startcol']], 1)
  return v:true
endfunction

" 读取缓冲区词表和字典词表，两者合并输出大词表
function! s:GetKeywords(typing)
  " 性能测试，3万个单词两级
  " lua: 0.0644
  " vim: 0.2573
  let bufkeyword_list = s:GetBufKeywordsList(a:typing)
  let dickeyword_list = s:GetDicKeywordsList(a:typing)
  let combined_all_temp  = bufkeyword_list + dickeyword_list
  let combined_all = s:ArrayDistinct(combined_all_temp)
  let combined_list = combined_all
  let ret_list = []
  for word in combined_list
    if index(bufkeyword_list, word) >= 0
      call add(ret_list, {
            \ "word": word,
            \ "dup" : 1,
            \ "icase" : 1,
            \ "equal" : 1,
            \ "info" : "",
            \ "abbr" : word,
            \ "kind" : g:easycomplete_kindflag_buf,
            \ "menu" : g:easycomplete_menuflag_buf,
            \ })
    else
      call add(ret_list, {
            \ "word": word,
            \ "dup" : 1,
            \ "icase" : 1,
            \ "equal" : 1,
            \ "info" : "",
            \ "abbr" : word,
            \ "kind" : g:easycomplete_kindflag_dict,
            \ "menu" : g:easycomplete_menuflag_dict,
            \ })
    endif
  endfor
  return ret_list
endfunction

function! s:CompleteHandler(typing, name, ctx, startcol)
  try
    let keywords_result = s:GetKeywords(a:typing)
  catch
    echom v:exception
  endtry
  call easycomplete#complete(a:name, a:ctx, a:startcol, keywords_result)
endfunction

" 获取当前所有 buff 内的关键词列表
function! s:GetBufKeywordsList(typing)
  if !exists("g:easycomplete_bufkw_storage")
    let g:easycomplete_bufkw_storage = {}
  endif
  let tmpkeywords = []
  " preform: 0.022s
  for buf in getbufinfo()
    if !empty(getbufvar(buf['bufnr'], '&buftype'))
      continue
    endif
    if !(bufloaded(buf['bufnr']))
      continue
    endif
    let nr_key = 'k' . string(buf['bufnr']) " bufnr key
    let tk_key = 'c' . string(buf['bufnr']) " changedtick key
    let stored_kws = get(g:easycomplete_bufkw_storage, nr_key, [])
    let stored_cgtk = get(g:easycomplete_bufkw_storage, tk_key, 0)
    if buf["changedtick"] == stored_cgtk && !empty(stored_kws)
      let tmpkeywords += copy(stored_kws)
    else
      let lines = getbufline(buf.bufnr, 1 ,"$")
      let local_kwlist = []
      " 性能测试：分检出 84238 个单词
      " lua: 0.021
      " vim: 0.147
      if easycomplete#util#HasLua()
        let local_kwlist = s:lua_toolkit.get_buf_keywords(lines)
      else
        for line in lines
          let local_kwlist += split(line,'[^A-Za-z0-9_#]')
        endfor
      endif
      let g:easycomplete_bufkw_storage[nr_key] = local_kwlist
      let g:easycomplete_bufkw_storage[tk_key] = buf["changedtick"]
      let tmpkeywords += local_kwlist
    endif
  endfor
  if exists("*matchfuzzy")
    " lua 和 vim 的 matchfuzzy 速度对比，vim 更快
    "    单词数→匹配出的结果个数
    " lua 53377→9748   0.028384
    " vim 53377→9748   0.010808
    " let keyword_list = s:lua_toolkit.matchfuzzy(tmpkeywords, a:typing)
    let keyword_list = matchfuzzy(tmpkeywords, a:typing, {"limit": 1000})
  else
    call filter(tmpkeywords, 'v:val =~ "^' . a:typing . '" && v:val !=# "' . a:typing . '"')
    let keyword_list = tmpkeywords
  endif

  return keyword_list
endfunction

function! s:GetDicKeywordsList(typing)
  let global_dict_keyword = s:GetGlobalDictKeyword()
  let localdicts = deepcopy(global_dict_keyword)
  call filter(localdicts, 'v:val =~ "^' . a:typing . '"')
  return localdicts
endfunction

function! s:GetGlobalDictKeyword()
  if exists("b:easycomplete_global_dict")
    return b:easycomplete_global_dict
  endif
  let b:easycomplete_global_dict = []
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
      call extend(localdicts, split(line, s:KeywordsRegx()))
    endfor

    let localdicts_uniq = s:ArrayDistinct(localdicts)
    let dictkeywords += localdicts_uniq
  endfor
  let b:easycomplete_global_dict = dictkeywords
  return dictkeywords
endfunction

function! s:KeywordsRegx()
  if exists("s:easycomplete_temp_keywords")
    return s:easycomplete_temp_keywords
  endif
  let key_word_list = split(&iskeyword, ",")
  let tmp_letters = ["@","_","-"]
  let res_letters = ["#"]
  for char in tmp_letters
    if index(key_word_list, char) >= 0
      call add(res_letters, char)
    endif
  endfor
  let reg_str = "[^A-Za-z0-9" . join(res_letters, "") . "]"
  let s:easycomplete_temp_keywords = reg_str
  return reg_str
endfunction

" List 去重，类似 uniq，纯数字要去掉
function! s:ArrayDistinct(list)
  if easycomplete#util#HasLua()
    let ret = s:lua_toolkit.distinct(a:list)
  else
    call uniq(sort(a:list))
    call filter(a:list, '!empty(v:val) && !str2nr(v:val) && len(v:val) != 1')
    let ret = a:list
  endif
  return ret
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction
