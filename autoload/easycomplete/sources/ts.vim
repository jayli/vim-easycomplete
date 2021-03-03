if get(g:, 'easycomplete_sources_ts')
  finish
endif
let g:easycomplete_sources_ts = 1

augroup easycomplete#sources#ts#augroup
  autocmd!
  autocmd BufReadPost * call easycomplete#sources#ts#init()
  autocmd VimLeave * call easycomplete#sources#ts#stopTsserver()
augroup END

augroup easycomplete#sources#ts#initLocalVars
  let s:callbacks = {}
  let s:ctx_list = {}
  let s:notify_callback = {}
  let s:quickfix_list = []
  let s:request_seq = 1
augroup END

augroup easycomplete#sources#ts#initIgnoreConditions
  let s:ignore_response_events = ["configFileDiag",
        \ "telemetry","projectsUpdatedInBackground",
        \ "setTypings","syntaxDiag","semanticDiag",
        \ "suggestionDiag","typingsInstallerPid"]
  " ignore events configFileDiag triggered by reload event. See also #99
  " call add(s:ignore_response_conditions, 'npm notice created a lockfile')
augroup END

function! easycomplete#sources#ts#init()
  call easycomplete#util#AsyncRun('easycomplete#sources#ts#tsOpen', [], 5)
endfunction

function! easycomplete#sources#ts#tsOpen()
  call s:startTsserver()
  call s:tsserverOpen(easycomplete#context()['filepath'])
endfunction

function! easycomplete#sources#ts#getConfig(opts) abort
  return extend({
        \ 'refresh_pattern': '\%(\k\|\.\)',
        \}, a:opts)
endfunction

function! easycomplete#sources#ts#constructor(opt, ctx)
  call s:registerCallback('easycomplete#sources#ts#diagnosticsCallback', 'diagnostics')
endfunction

function! easycomplete#sources#ts#diagnosticsCallback(item)
  " TODO
endfunction

function! easycomplete#sources#ts#completor(opt, ctx) abort
  call s:restoreCtx(a:ctx)
  call s:tsCompletions(a:ctx['filepath'], a:ctx['lnum'], a:ctx['col'], a:ctx['typing'])
endfunction

function! easycomplete#sources#ts#stopTsserver()
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
  " call ch_sendraw(s:tsq['channel'], a:line . "\n")
  call easycomplete#job#send(s:tsq['job'], a:line . "\n")
endfunction

function! s:sendCommandAsyncResponse(cmd, args)
  let l:input = json_encode({'command': a:cmd, 'arguments': a:args, 'type': 'request', 'seq': s:request_seq})
  call s:sendAsyncRequest(l:input)
  let s:request_seq = s:request_seq + 1
endfunction

function! s:sendCommandOneWay(cmd, args)
  call s:sendCommandAsyncResponse(a:cmd, a:args)
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
function! s:tsCompletions(file, line, offset, prefix)
  let l:args = {'file': a:file, 'line': a:line, 'offset': a:offset, 'prefix': a:prefix}
  " call tsuquyomi#complete(0, easycomplete#context()['typing'])
  call s:sendCommandAsyncResponse('completions', l:args)
endfunction

function! s:tsCompletionEntryDetails(file, line, offset, entryNames)
  let l:args = {'file': a:file, 'line': a:line, 'offset': a:offset, 'entryNames': a:entryNames}
  call s:sendCommandAsyncResponse('completionEntryDetails', l:args)
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
    let s:tsq['job'] = easycomplete#job#start(l:cmd, {'on_stdout': function('s:handleMessage')})
    if s:tsq['job'] <= 0
      echoerr "tsserver launch failed"
    endif
  endif
endfunction

function! s:handleMessage(job_id, data, event)
  if a:event != 'stdout'
    return
  endif
  if len(a:data) >=3
    call easycomplete#sources#ts#handleMessage(a:data[2])
  endif
endfunction

function! easycomplete#sources#ts#handleMessage(msg)
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

  " 执行 event 的回调
  if l:eventName != 0
    if(has_key(s:callbacks, l:eventName))
      let Callback = function(s:callbacks[l:eventName], [l:item])
      call Callback()
    endif
  endif

  " 执行 response complete 的回调
  if get(l:item, 'type') ==# 'response'
        \ && get(l:item, 'command') ==# 'completions'
        \ && get(l:item, 'success') ==# v:true
    let l:raw_list = get(l:item, 'body')
    let l:request_req = get(l:item, 'request_seq')
    let l:menu_list = map(l:raw_list, '{"word":v:val.name,"dup":1,"icase":1,"menu": "[ts]", "kind":v:val.kind}')
    let l:ctx = s:getCtxByRequestSeq(l:request_req)
    call easycomplete#complete('ts', l:ctx, l:ctx['startcol'], l:menu_list)
  endif
endfunction

function! s:tsserverOpen(file)
  let l:args = {'file': a:file}
  call s:sendCommandOneWay('open', l:args)
endfunction

function! s:registerCallback(callback, eventName)
  let s:callbacks[a:eventName] = a:callback
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
