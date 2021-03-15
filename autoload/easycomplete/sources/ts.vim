if get(g:, 'easycomplete_sources_ts')
  finish
endif
let g:easycomplete_sources_ts = 1

augroup easycomplete#sources#ts#augroup
  autocmd!
  autocmd BufUnload *.js,*.ts,*.jsx,*.tsx call easycomplete#sources#ts#destory()
  autocmd TextChangedI *.js,*.ts,*.jsx,*.tsx call easycomplete#sources#ts#tsReload()
augroup END

augroup easycomplete#sources#ts#initLocalVars
  let s:event_callbacks = {}
  let s:response_callbacks = {}
  let s:ctx_list = {}
  let s:buf_info_map = {}
  let s:notify_callback = {}
  let s:quickfix_list = []
  let s:request_seq = 1
  let b:tsserver_reloading = 0
  let s:menu_flag = "[TS]"
augroup END

augroup easycomplete#sources#ts#initIgnoreConditions
  let s:ignore_response_events = ["configFileDiag",
        \ "telemetry","projectsUpdatedInBackground",
        \ "setTypings","syntaxDiag","semanticDiag",
        \ "suggestionDiag","typingsInstallerPid"]
  " ignore events configFileDiag triggered by reload event. See also #99
  " call add(s:ignore_response_conditions, 'npm notice created a lockfile')
augroup END

function! easycomplete#sources#ts#destory()
  call s:stopTsserver()
  call s:delTmpFiles()
endfunction

function! easycomplete#sources#ts#tsOpen()
  call s:startTsserver()
  call s:tsserverOpen() " open 完了再异步执行 config，需要绑定回调事件 TODO
  call s:configTsserver()
endfunction

function! easycomplete#sources#ts#tsReload()
  " 需要劫持 typing 动作的标准做法: 重写 TextChangedI 方法，在触发typing动作之
  " 前加上 TsServerReload 的动作
  if !easycomplete#FireCondition()
    return
  endif
  call easycomplete#util#StopAsyncRun()
  call easycomplete#util#AsyncRun(function('s:TsserverReloadAndDoTyping'), [], 30)
endfunction

function! s:TsserverReloadAndDoTyping()
  call s:TsserverReload()
  " TODO 这里用了 sleep 等待 Tsserverreload 成功，需要改成callback模式
  " 目前性能问题不明显，凑合用
  call easycomplete#typing()
endfunction

function! easycomplete#sources#ts#getConfig(opts) abort
  return extend({
        \ 'refresh_pattern': '\%(\k\|\.\)',
        \}, a:opts)
endfunction

" TODO 优化代码结构
function! easycomplete#sources#ts#constructor(opt, ctx)
  call s:registEventCallback('easycomplete#sources#ts#diagnosticsCallback', 'diagnostics')
  call s:registResponseCallback('easycomplete#sources#ts#completeCallback', 'completions')
  call s:registResponseCallback('easycomplete#sources#ts#tsReloadingCallback', 'reload')
  call s:registResponseCallback('easycomplete#sources#ts#EntryDetailsCallback', 'completionEntryDetails')
  call easycomplete#util#AsyncRun('easycomplete#sources#ts#tsOpen', [], 5)
endfunction

function! easycomplete#sources#ts#tsReloadingCallback(item)
  let b:tsserver_reloading = 0
endfunction

function! easycomplete#sources#ts#diagnosticsCallback(item)
  " TODO
endfunction

"     [{
"       'name': 'DOMError',
"       'kind': 'var',
"       'kindModifier': 'declare',
"       'displayParts': [
"         {'kind': 'keyword', 'text': 'interface'},
"         {'kind': 'space', 'text': ' '},
"         ...
"         {'kind': 'lineBreak', 'text': '\n'},
"         ...
"       ]
"     }, ...]
function! easycomplete#sources#ts#EntryDetailsCallback(item)
  if !pumvisible()
    return
  endif

  let l:menu_details = get(a:item, 'body')
  let idx = 0
  for item in l:menu_details
    let l:info = s:NormalizeEntryDetail(item)
    call easycomplete#SetMenuInfo(get(item, "name"), l:info, s:menu_flag)
    let idx = idx + 1
  endfor
endfunction

" job complete 回调
function! easycomplete#sources#ts#completeCallback(item)
  if empty(a:item)
    return
  endif

  let l:raw_list = get(a:item, 'body')
  if empty(l:raw_list)
    return
  endif

  let l:request_req = get(a:item, 'request_seq')
  let l:easycomplete_menu_list = map(filter(sort(copy(l:raw_list), "s:sortTextComparator"), 'v:val.kind != "warning"'), 
        \ function("s:CompleteMenuMap"))
  let l:ctx = s:getCtxByRequestSeq(l:request_req)
  " 显示 completemenu
  call s:DoComplete(l:ctx, l:easycomplete_menu_list)
  " 取 entries details
  let l:entries= map(copy(l:easycomplete_menu_list), function("s:EntriesMap"))
  if !empty(l:entries) && type(l:entries) == type([])
    call s:tsCompletionEntryDetails(l:ctx['filepath'], l:ctx['lnum'], l:ctx['col'], l:entries)
  endif
endfunction

function! s:DoComplete(ctx, menu_list)
  call easycomplete#complete('ts', a:ctx, a:ctx['startcol'], a:menu_list)
endfunction

function! s:NormalizeEntryDetail(item)
  let l:title = ""
  let l:desp_str = ""
  let l:documentation = ""

  let l:title = join([
        \ get(a:item, 'kindModifiers'),
        \ get(a:item, 'name'),
        \ get(a:item, 'kind'),
        \ get(a:item, 'name')], " ")

  if !empty(get(a:item, "displayParts")) && len(get(a:item, "displayParts")) > 0
    let l:desp_list = []
    for dis_item in get(a:item, "displayParts")
      call add(l:desp_list, dis_item.text)
    endfor
    let l:desp_str = "\n" . join(l:desp_list, "")
  endif

  if !empty(get(a:item, "documentation")) && len(get(a:item, "documentation")) > 0
    let l:doc_list = []
    for document_item in get(a:item, "documentation")
      call add(l:doc_list, document_item.text)
    endfor
    let l:documentation = "\n---------\n" . join(l:doc_list, "")
  endif

  return l:title . l:desp_str . l:documentation
endfunction

function! s:EntriesMap(key, val)
  return a:val.abbr
endfunction

function! s:CompleteMenuMap(key, val)
  let is_func = (a:val.kind ==# "method")
  let val_name = a:val.name
  return {
        \ "abbr": val_name,
        \ "dup": 1,
        \ "icase": 1,
        \ "kind": exists('a:val.kind') ? a:val.kind[0] : "",
        \ "menu": s:menu_flag,
        \ "word": is_func ? val_name . "(" : val_name,
        \ "info": ""
        \ }
endfunction

function! easycomplete#sources#ts#completor(opt, ctx) abort
  call s:restoreCtx(a:ctx)
  if a:ctx['char'] == "/"
    return v:true
  endif
  call s:FireTsCompletions(a:ctx['filepath'], a:ctx['lnum'], a:ctx['col'], a:ctx['typing'])
  " call log#log('--docomplete--',a:ctx["char"], a:ctx["typing"])
  return v:true
endfunction

function! s:stopTsserver()
  if exists('s:tsq') && get(s:tsq, 'job') > 0
    call easycomplete#job#stop(get(s:tsq, 'job'))
  endif
endfunction

function! s:nSort(a, b)
    return a:a == a:b ? 0 : a:a > a:b ? 1 : -1
endfunction

" 存储ctx，异步返回时取出
function! s:restoreCtx(ctx)
  " 删除多余的 ctx
  let arr = []
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
  let s:ctx_list[string(s:request_seq)] = a:ctx
endfunction

function! s:getCtxByRequestSeq(seq)
  return get(s:ctx_list, string(a:seq))
endfunction

function! s:sendAsyncRequest(line)
  call s:startTsserver()
  " TODO 加上这句，所有的.号后面直接可以很好的匹配，否则有时匹配不出来？
  " call log#log('--easycomplete--')
  " call log#log(a:line)
  call easycomplete#job#send(s:tsq['job'], a:line . "\n")
endfunction

function! s:SendCommandAsyncResponse(cmd, args)
  let l:input = json_encode({'command': a:cmd, 'arguments': a:args, 'type': 'request', 'seq': s:request_seq})
  call s:sendAsyncRequest(l:input)
  let s:request_seq = s:request_seq + 1
endfunction

function! s:SendCommandOneWay(cmd, args)
  call s:SendCommandAsyncResponse(a:cmd, a:args)
endfunction

" Fetch keywards to complete from TSServer.
" PARAM: {string} file File name.
" PARAM: {string} line The line number of location to complete.
" PARAM: {string} offset The col number of location to complete.
" PARAM: {string} prefix Prefix to filter result set.
" RETURNS: {list} A List of completion info Dictionary.
"   e.g. :
"     [
"       {'name': 'close', 'kindModifiers': 'declare', 'kind': 'function'},
"       {'name': 'clipboardData', 'kindModifiers': 'declare', 'kind': 'var'}
"     ]
function! s:FireTsCompletions(file, line, offset, prefix)
  let l:args = {'file': a:file, 'line': a:line, 'offset': a:offset, 'prefix': a:prefix}

  " shoule wait for reload done
  " call log#log("complete fired", rand(), l:args)
  call s:WaitForReloadDone()
  call s:SendCommandAsyncResponse('completions', l:args)
endfunction

function! s:WaitForReloadDone()
  " 50 * 5 = 250ms
  let l:count_time = 50
  let l:cursor = 0
  while l:cursor <= l:count_time
    if b:tsserver_reloading == 0
      break
    endif
    sleep 5ms
    let l:cursor = l:cursor + 1
  endwhile
  " call log#log('sleep')
endfunction

function! s:tsCompletionEntryDetails(file, line, offset, entryNames)
  let l:args = {'file': a:file, 'line': a:line, 'offset': a:offset, 'entryNames': a:entryNames}
  call s:SendCommandAsyncResponse('completionEntryDetails', l:args)
endfunction

function! s:startTsserver()
  if !exists('s:tsq')
    let s:tsq = {'job':0}
  endif

  let l:cmd = "tsserver --locale en"
  if !executable("tsserver")
    echom '[easycomplete] tsserver is not installed. Try "npm -g install typescript".'
    return 0
  endif

  if get(s:tsq, 'job') == 0
    let s:tsq['job'] = easycomplete#job#start(l:cmd, {'on_stdout': function('s:stdOutCallback')})
    if s:tsq['job'] <= 0
      echoerr "tsserver launch failed"
    endif
  endif
endfunction

function! s:configTsserver()
  let l:file = expand('%:p')
  let l:hostInfo = &viminfo
  let l:formatOptions = { }
  let l:extraFileExtensions = []
  if exists('&shiftwidth')
    let l:formatOptions.baseIndentSize = &shiftwidth
    let l:formatOptions.indentSize = &shiftwidth
  endif
  if exists('&expandtab')
    let l:formatOptions.convertTabsToSpaces = &expandtab
  endif
  let l:args = {
        \ 'file': l:file,
        \ 'hostInfo': l:hostInfo,
        \ 'formatOptions': l:formatOptions,
        \ 'extraFileExtensions': l:extraFileExtensions
        \ }
  call s:SendCommandOneWay('configure', l:args)
endfunction

function! s:stdOutCallback(job_id, data, event)
  if a:event != 'stdout'
    return
  endif
  if len(a:data) >=3
    call s:messageHandler(a:data[2])
  endif
endfunction

function! s:messageHandler(msg)
  if type(a:msg) != 1 || empty(a:msg)
    " Not a string or blank message.
    return
  endif
  if easycomplete#util#NotInsertMode()
    return
  endif
  try
    let l:res_item = json_decode(a:msg)
  catch
    echom a:msg
    echom 'tsserver response error'
    return
  endtry

  " Ignore messages.
  if type(l:res_item) != type({})
    return
  endif
  if has_key(l:res_item, 'event') && index(s:ignore_response_events, get(l:res_item, 'event')) >= 0
    return
  endif

  let l:item = l:res_item
  let l:eventName = s:getTsserverEventType(l:item)
  let l:responseName = s:getTsserverResponseType(l:item)

  " 执行 event 的回调
  if l:eventName != 0
    if(has_key(s:event_callbacks, l:eventName))
      let EventCallback = function(s:event_callbacks[l:eventName], [l:item])
      call EventCallback()
    endif
    return
  endif

  " 执行 response 的回调
  " call log#log("responseName", l:responseName)
  if !empty(l:responseName)
    if(has_key(s:response_callbacks, l:responseName))
      let ResponseCallback = function(s:response_callbacks[l:responseName], [l:item])
      call ResponseCallback()
    endif
  endif
endfunction

function! s:sortTextComparator(entry1, entry2)
  if a:entry1.sortText < a:entry2.sortText
    return -1
  elseif a:entry1.sortText > a:entry2.sortText
    return 1
  else
    if a:entry1.name > a:entry2.name
      return -1
    else
      return 1
    endif
    return 0
  endif
endfunction

function! s:tsserverOpen()
  let l:file = easycomplete#context()['filepath']
  " call log#log("tsserver open", l:file)
  let l:args = {'file': l:file}
  call s:SendCommandOneWay('open', l:args)
endfunction

function! s:TsserverReload()
  let l:file = easycomplete#context()['filepath']
  call s:saveTmp(l:file)
  let l:args = {'file': l:file, 'tmpfile': s:getTmpFile(l:file)}
  call s:SendCommandOneWay('reload', l:args)
  let b:tsserver_reloading = 1
endfunction

function! s:saveTmp(file_name)
  let tmpfile = s:getTmpFile(a:file_name)
  call writefile(getbufline(a:file_name, 1, '$'), tmpfile)
  return 1
endfunction

function! s:getTmpFile(file_name)
  let name = s:normalize(a:file_name)
  if !has_key(s:buf_info_map, name)
    let s:buf_info_map[name] = {}
  endif
  if !has_key(s:buf_info_map[name], 'tmpfile')
    let tmpfile = tempname()
    let s:buf_info_map[name].tmpfile = tmpfile
    return tmpfile
  else
    return s:buf_info_map[name].tmpfile
  endif
endfunction

function! s:delTmpFiles()
  if !exists('s:buf_info_map')
    return
  endif
  for name in keys(s:buf_info_map)
    call s:delTmp(name)
  endfor
endfunction

function! s:delTmp(file_name)
  let name = s:normalize(a:file_name)
  if !has_key(s:buf_info_map, name)
    return
  endif
  if has_key(s:buf_info_map[name], 'tmpfile')
    let tmpfile = s:buf_info_map[name].tmpfile
    call delete(tmpfile)
  endif
endfunction

function! s:normalize(buf_name)
  return substitute(a:buf_name, '\\', '/', 'g')
endfunction

function! s:registEventCallback(callback, eventName)
  let s:event_callbacks[a:eventName] = a:callback
endfunction

function! s:registResponseCallback(callback, responseName)
  let s:response_callbacks[a:responseName] = a:callback
endfunction

function! s:getTsserverResponseType(item)
  if type(a:item) == v:t_dict
    \ && has_key(a:item, 'type')
    \ && get(a:item, 'type') ==# 'response'
  "       \ && get(l:item, 'success') ==# v:true
    return get(a:item, 'command')
  endif
  return 0
endfunction

function! s:getTsserverEventType(item)
  if type(a:item) == v:t_dict
    \ && has_key(a:item, 'type')
    \ && a:item.type ==# 'event'
    \ && (a:item.event ==# 'syntaxDiag'
      \ || a:item.event ==# 'semanticDiag'
      \ || a:item.event ==# 'requestCompleted')
    return 'diagnostics'
  endif
  return 0
endfunction

function! s:log(msg)
  call easycomplete#log(a:msg)
endfunction
