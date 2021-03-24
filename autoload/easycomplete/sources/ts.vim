if get(g:, 'easycomplete_sources_ts')
  finish
endif
let g:easycomplete_sources_ts = 1

augroup easycomplete#sources#ts#InitLocalVars
  " 正在运行中的 job 指针
  " {
  "   "job": 1,
  "   "opend_files": {
  "     "1":[file1,file2,file3],
  "     "2":[file1,file2]
  "   }
  " }
  let s:tsq_job = {
        \ "job": 0,
        \ "opend_files":{}
        \ }
  let s:event_callbacks = {}
  let s:response_callbacks = {}
  let s:buf_info_map = {}
  let s:notify_callback = {}
  let s:request_seq = 1
  let b:tsserver_reloading = 0
  let s:menu_flag = "[TS]"
  " 正在返回的字符串片段，等待所有返回片段拼接成一个完整的json后，执行
  " MessageHandler
  let s:callback_data_str = ""
augroup END

augroup easycomplete#sources#ts#InitIgnoreConditions
  let s:ignore_response_events = ["configFileDiag",
        \ "telemetry","projectsUpdatedInBackground",
        \ "setTypings","syntaxDiag","semanticDiag",
        \ "suggestionDiag","typingsInstallerPid"]
augroup END

function! easycomplete#sources#ts#destory()
  call s:StopTsserver()
  call s:DelTmpFiles()
endfunction

function! easycomplete#sources#ts#getConfig(opts) abort
  return extend({
        \ 'refresh_pattern': '\%(\k\|\.\)',
        \}, a:opts)
endfunction

" regist events
function! easycomplete#sources#ts#constructor(opt, ctx)

  augroup easycomplete#sources#ts#augroup
    autocmd!
    autocmd BufUnload *.js,*.ts,*.jsx,*.tsx call easycomplete#sources#ts#destory()
    " TODO 因为e出来的buffer，在bnext和bprevious 切换时，job 就被杀掉了(原因未
    " 知)，所以需要切换后执行init，但vim无bnext和bprevious事件，这里用
    " InsertEnter,SafeState 来实现，这里的 init 会执行的比较频繁，可能会有性能问题
    autocmd InsertEnter *.js,*.ts,*.jsx,*.tsx call easycomplete#sources#ts#init()
    if g:env_is_vim
      autocmd SafeState *.js,*.ts,*.jsx,*.tsx call easycomplete#sources#ts#init()
    endif
    " goto definition 方法需要抽到配置里去
    command! EasyCompleteGotoDefinition : call easycomplete#sources#ts#GotoDefinition()
    " TODO 重新定义 c-] 做 definition 跳转，有待进一步测试兼容
    nnoremap <c-]> :EasyCompleteGotoDefinition<CR>
  augroup END

  call s:RegistEventCallback('easycomplete#sources#ts#DiagnosticsCallback', 'diagnostics')
  call s:RegistResponseCallback('easycomplete#sources#ts#CompleteCallback', 'completions')
  call s:RegistResponseCallback('easycomplete#sources#ts#DefinationCallback', 'definition')
  call s:RegistResponseCallback('easycomplete#sources#ts#TsReloadingCallback', 'reload')
  call s:RegistResponseCallback('easycomplete#sources#ts#EntryDetailsCallback', 'completionEntryDetails')
  call easycomplete#util#AsyncRun('easycomplete#sources#ts#init', [], 5)
endfunction

function! easycomplete#sources#ts#init()
  " TSServer 在多个 buffer 间可以共享，一次创建多次使用，但每个 buffer
  " 所对应的文件必须在 TSServer 中 open，每 enterbuf 时都需重新 open
  " e 出来的 buf 在切换时会导致 TSServer 进程被杀掉，这样就需要重启 Tserver以
  " 及重新给每个 buf 做 open 的动作，因此这里绑定了 InsertEnter 来做这个事情
  call s:StartTsserver()
  call s:TsserverOpen()
endfunction

function! easycomplete#sources#ts#DefinationCallback(item)
  let l:definition_info = get(a:item, 'body')
  if empty(l:definition_info)
    return
  endif
  let defination = l:definition_info[0]
  let filename = defination.file
  let start = defination.contextStart

  call s:UpdateTagStack()
  call s:location(fnameescape(filename), start.line, start.offset)
endfunction

function! easycomplete#sources#ts#TsReloadingCallback(item)
  let b:tsserver_reloading = 0
endfunction

function! easycomplete#sources#ts#DiagnosticsCallback(item)
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
  if type(l:menu_details) != type([]) || empty(l:menu_details)
    return
  endif
  let idx = 0
  for item in l:menu_details
    let l:info = s:NormalizeEntryDetail(item)
    call easycomplete#SetMenuInfo(get(item, "name"), l:info, s:menu_flag)
    let idx = idx + 1
  endfor
endfunction

" job complete 回调
function! easycomplete#sources#ts#CompleteCallback(item)
  if empty(a:item)
    return
  endif

  let l:raw_list = get(a:item, 'body')
  if empty(l:raw_list)
    return
  endif

  let l:request_req = get(a:item, 'request_seq')
  let l:easycomplete_menu_list = map(filter(sort(copy(l:raw_list),
        \                       "s:sortTextComparator"), 'v:val.kind != "warning"'),
        \ function("s:CompleteMenuMap"))
  let l:ctx = easycomplete#util#GetCtxByRequestSeq(l:request_req)
  " 如果返回时携带的 ctx 和当前的 ctx 不同，应当取消这次匹配动作
  if !easycomplete#CheckContextSequence(l:ctx)
    return
  endif
  " 显示 completemenu
  call s:DoComplete(l:ctx, l:easycomplete_menu_list)
  " 取 entries details
  let l:entries= map(copy(l:easycomplete_menu_list), function("s:EntriesMap"))
  if type(l:entries) == type([]) && !empty(l:entries)
    call s:TsCompletionEntryDetails(l:ctx['filepath'], l:ctx['lnum'], l:ctx['col'], l:entries)
  endif
endfunction

function! s:DoComplete(ctx, menu_list)
  call easycomplete#complete('ts', a:ctx, a:ctx['startcol'], a:menu_list)
endfunction

function! s:NormalizeEntryDetail(item)
  let l:title = ""
  let l:desp_list = []
  let l:doc_list = []

  let l:title = join([
        \ get(a:item, 'kindModifiers'),
        \ get(a:item, 'name'),
        \ get(a:item, 'kind'),
        \ get(a:item, 'name')], " ")

  if !empty(get(a:item, "displayParts")) && len(get(a:item, "displayParts")) > 0
    let l:desp_list = []
    let l:t_line = ""
    for dis_item in get(a:item, "displayParts")
      if dis_item.text =~ "\\(\\r\\|\\n\\)"
        call add(l:desp_list, l:t_line)
        let l:t_line = ""
      else 
        let l:t_line  = l:t_line  . dis_item.text
      endif
    endfor
    if !empty(l:t_line)
      call add(l:desp_list, l:t_line)
    endif
  endif

  if !empty(get(a:item, "documentation")) && len(get(a:item, "documentation")) > 0
    let l:doc_list = ["------------"] " 任意长度即可, 显示的时候回重新计算分割线宽度
    let l:t_line = ""
    for document_item in get(a:item, "documentation")
      if document_item.text =~ "\\(\\r\\|\\n\\)"
        call add(l:doc_list, l:t_line)
        let l:t_line = ""
      else
        let l:t_line = l:t_line . document_item.text
      endif
    endfor
    if !empty(l:t_line)
      call add(l:doc_list, l:t_line)
    endif
  endif

  return [l:title] + l:desp_list + l:doc_list
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
        \ "info": "",
        \ "equal":1
        \ }
endfunction

function! easycomplete#sources#ts#completor(opt, ctx) abort
  call s:TsserverReload()
  call easycomplete#util#RestoreCtx(a:ctx, s:request_seq)
  if a:ctx['char'] == "/"
    return v:true
  endif
  call s:FireTsCompletions(a:ctx['filepath'], a:ctx['lnum'], a:ctx['col'], a:ctx['typing'])
  " 返回 true 让其他插件的 completor 继续执行
  return v:true
endfunction

function! s:StopTsserver()
  if s:tsq_job.job > 0
    call easycomplete#job#stop(s:tsq_job.job)
  endif
endfunction

function! s:sendAsyncRequest(line)
  call s:StartTsserver()
  call easycomplete#job#send(s:tsq_job.job, a:line . "\n")
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
endfunction

function! s:TsCompletionEntryDetails(file, line, offset, entryNames)
  let l:args = {'file': a:file, 'line': a:line, 'offset': a:offset, 'entryNames': a:entryNames}
  call s:SendCommandAsyncResponse('completionEntryDetails', l:args)
endfunction

" Fetch location where the symbol at cursor(line, offset) in file is defined.
" PARAM: {string} file File name.
" PARAM: {int} line The line number of location to complete.
" PARAM: {int} offset The col number of location to complete.
" RETURNS: {list<dict>} A list of dictionaries of definition location.
"   e.g. :
"     [{'file': 'hogehoge.ts', 'start': {'line': 3, 'offset': 2}, 'end': {'line': 3, 'offset': 10}}]
function! s:GotoDefinition(file, line, offset)
  let l:args = {'file': a:file, 'line': a:line, 'offset': a:offset}
  call s:SendCommandAsyncResponse('definition', l:args)
endfunction

function! easycomplete#sources#ts#GotoDefinition()
  let ext = tolower(easycomplete#util#extention())
  if index(["js","jsx","ts","tsx"], ext) >= 0
    let l:ctx = easycomplete#context()
    call s:GotoDefinition(l:ctx["filepath"], l:ctx["lnum"], l:ctx["col"])
    return
  endif
  exec "tag ". expand('<cword>')
endfunction

function! s:TsServerIsRunning()
  if s:tsq_job.job <= 0
    return v:false
  endif
  let job_status = easycomplete#job#status(s:tsq_job.job)
  return job_status == 'run' ? v:true : v:false
endfunction

function! s:StartTsserver()
  if !s:TsServerIsRunning()
    let l:cmd = "tsserver --locale en"
    if !executable("tsserver")
      echom '[easycomplete] tsserver is not installed. Try "npm -g install typescript".'
      return 0
    endif

    let job_status = easycomplete#job#status(s:tsq_job.job)
    let s:tsq_job.job = easycomplete#job#start(l:cmd, {'on_stdout': function('s:StdOutCallback')})
    if s:tsq_job.job <= 0
      echoerr "tsserver launch failed"
    endif
  endif
endfunction

function! s:ConfigTsserver()
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

function! s:StdOutCallback(job_id, data, event)
  if a:event != 'stdout'
    return
  endif
  if len(a:data) >=3
    if s:IsJSON(a:data[2])
      call s:MessageHandler(a:data[2])
      let s:callback_data_str = ""
      return
    else
      let s:callback_data_str = s:callback_data_str . a:data[2]
      return
    endif
  endif

  " 在 nvim 中不会一次性完整输出，会一个片段一个片段的输出
  " 需要先拼接每个片段组成一个完整的data，在执行 MessageHandler
  " vim 中未发现这个问题
  if len(a:data) <= 2
    let s:callback_data_str = s:callback_data_str . a:data[0]
    if s:IsJSON(s:callback_data_str)
      call s:MessageHandler(s:callback_data_str)
      let s:callback_data_str = ""
      return
    endif
  endif
endfunction

function! s:IsJSON(str)
  try
    call json_decode(a:str)
  catch
    return v:false
  endtry
  return v:true
endfunction

function! s:MessageHandler(msg)
  if type(a:msg) != 1 || empty(a:msg)
    " Not a string or blank message.
    return
  endif
  try
    let l:res_item = json_decode(a:msg)
  catch
    " TODO 出异常到这里，程序会报错
    echom v:exception
    call easycomplete#flush()
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
  let l:eventName = s:GetTsserverEventType(l:item)
  let l:responseName = s:GetTsserverResponseType(l:item)

  " normal 模式下只处理 definition 事件，其他事件均在插入模式下处理
  if easycomplete#util#NotInsertMode() && l:responseName !=# 'definition'
    return
  endif

  " 执行 event 的回调
  if l:eventName != 0
    if(has_key(s:event_callbacks, l:eventName))
      let EventCallback = function(s:event_callbacks[l:eventName], [l:item])
      call EventCallback()
    endif
    return
  endif

  " 执行 response 的回调
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

function! s:TsserverOpen()
  if s:TsServerOpenedFileAlready()
    return
  endif
  let l:file = easycomplete#context()['filepath']
  let l:args = {'file': l:file}
  call s:SendCommandOneWay('open', l:args)
  " TODO: open 比较耗时，需要 open 完了再异步执行 config，需要绑定回调事件
  call s:ConfigTsserver()
  call s:SetTsServerOpenStatusOK()
endfunction

" 成功 Open 之后，把当前 Open 的 filename 记录起来
function! s:SetTsServerOpenStatusOK()
  let jobid = s:tsq_job.job
  if !has_key(s:tsq_job.opend_files, string(jobid))
    let s:tsq_job.opend_files[string(jobid)] = []
  endif
  call add(s:tsq_job.opend_files[string(jobid)], expand('%:p'))
endfunction

" 判断当前buf所在的文件是否已经在 tsserver 中 open 过了
function! s:TsServerOpenedFileAlready()
  if !s:TsServerIsRunning()
    return v:false
  endif

  let jobid = s:tsq_job.job
  let filename = expand('%:p')
  if !has_key(s:tsq_job.opend_files, string(jobid))
    return v:false
  endif
  if index(s:tsq_job.opend_files[string(jobid)], filename) >= 0
    return v:true
  else
    return v:false
  endif
endfunction

function! s:TsserverReload()
  let l:file = expand('%:p')
  call s:SaveTmp(l:file)
  let l:args = {'file': l:file, 'tmpfile': s:GetTmpFile(l:file)}
  call s:SendCommandOneWay('reload', l:args)
  let b:tsserver_reloading = 1
endfunction

function! s:SaveTmp(file_name)
  let tmpfile = s:GetTmpFile(a:file_name)
  call writefile(getbufline(a:file_name, 1, '$'), tmpfile)
  return 1
endfunction

function! s:GetTmpFile(file_name)
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

function! s:DelTmpFiles()
  if !exists('s:buf_info_map')
    return
  endif
  for name in keys(s:buf_info_map)
    call s:DelTmp(name)
  endfor
endfunction

function! s:DelTmp(file_name)
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
  return easycomplete#util#normalize(a:buf_name)
endfunction

function! s:RegistEventCallback(callback, eventName)
  let s:event_callbacks[a:eventName] = a:callback
endfunction

function! s:RegistResponseCallback(callback, responseName)
  let s:response_callbacks[a:responseName] = a:callback
endfunction

function! s:GetTsserverResponseType(item)
  if type(a:item) == v:t_dict
    \ && has_key(a:item, 'type')
    \ && get(a:item, 'type') ==# 'response'
  "       \ && get(l:item, 'success') ==# v:true
    return get(a:item, 'command')
  endif
  return 0
endfunction

function! s:GetTsserverEventType(item)
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

function! s:location(...) abort
  return call('easycomplete#util#location', a:000)
endfunction

function! s:UpdateTagStack() abort
  call easycomplete#util#UpdateTagStack()
endfunction

function! s:log(msg)
  call easycomplete#log(a:msg)
endfunction
