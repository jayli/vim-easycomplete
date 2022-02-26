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
  let s:opt = {}
  let s:menu_flag = "[TS]"
  let s:file_extensions = ["js","jsx","ts","tsx","mjs","ejs"]
  " 三种提示默认支持，和coc默认配置保持一致:
  " syntaxDiag/semanticDiag/suggestionDiag
  " requestCompleted表示一轮events完成
  let b:diagnostics_cache = {
        \   "uri":"file://...",
        \   "cache":{
        \     "syntaxDiag":     [],
        \     "semanticDiag":   [],
        \     "suggestionDiag": []
        \   }
        \ }
  " "error", "warning", or "suggestion"
  let s:diagostics_category = {
        \ "error" : 1,
        \ "warning": 2,
        \ "suggestion":3
        \ }
  let b:tsserver_reloading = 0

  " https://github.com/microsoft/TypeScript/issues/36265
  " completionEntryDetails 请求很耗时，在完成之前没办法再做 completion 动作
  " 需要标记 completionEntryDetails 的请求状态
  let b:entry_details_requesting = 0
  let s:entry_detail_fetching_timer = 0

  " 用以取回 entry details 时所需的请求携带的 ctx
  let s:request_queue_ctx = {}

  " 正在返回的字符串片段，等待所有返回片段拼接成一个完整的 json 后，执行
  " MessageHandler，在 neovim 中常用
  let s:callback_data_str = ""
augroup END

augroup easycomplete#sources#ts#InitIgnoreConditions
  let s:ignore_response_events = ["configFileDiag",
        \ "telemetry","projectsUpdatedInBackground",
        \ "setTypings", "typingsInstallerPid"]
augroup END

function! easycomplete#sources#ts#destory()
  call s:StopTsserver()
  call s:DelTmpFiles()
endfunction

" 判断当前是否正在读取 entry details 中
" 避免 entry detail 太耗时导致 tsserver 响应延迟，进而导致时序错乱
function! s:EntryDetailsIsFetching()
  if !exists('b:entry_details_requesting')
    let b:entry_details_requesting = 0
  endif
  return b:entry_details_requesting
endfunction

function! s:EntryDetailsStatusReset()
  if s:entry_detail_fetching_timer > 0
    call timer_stop(s:entry_detail_fetching_timer)
    let s:entry_detail_fetching_timer = 0
  endif
  let b:entry_details_requesting = 0
endfunction

function! s:EntryDetailsStatusSetFetching()
  if s:entry_detail_fetching_timer > 0
    call timer_stop(s:entry_detail_fetching_timer)
  endif
  let s:entry_detail_fetching_timer = timer_start(5000,
        \ { -> easycomplete#util#call(function("s:EntryDetailsStatusReset"), []) })
  let b:entry_details_requesting = 1
endfunction

" regist events
function! easycomplete#sources#ts#constructor(opt, ctx)
  if easycomplete#sources#deno#IsDenoProject()
    call easycomplete#UnRegisterSource("ts")
    return
  else
    call easycomplete#UnRegisterSource("deno")
  endif
  if !s:TsserverIsReady()
    return
  endif
  augroup easycomplete#sources#ts#augroup
    autocmd!
    autocmd BufUnload *.mjs,*.ejs,*.js,*.ts,*.jsx,*.tsx call easycomplete#sources#ts#destory()
    " TODO 因为 e 出来的buffer，在bnext和bprevious 切换时，job 就被杀掉了(原因未
    " 知)，所以需要切换后执行init，但vim无bnext和bprevious事件，这里用
    " InsertEnter,SafeState 来实现，这里的 init 会执行的比较频繁，可能会有性能问题
    autocmd InsertEnter *.mjs,*.ejs,*.js,*.ts,*.jsx,*.tsx call easycomplete#sources#ts#init()
    " Diagnostics Event
    autocmd InsertLeave *.mjs,*.ejs,*.js,*.ts,*.jsx,*.tsx call easycomplete#sources#ts#lint()
    autocmd BufWritePost *.mjs,*.ejs,*.js,*.ts,*.jsx,*.tsx call easycomplete#sources#ts#lint()
    autocmd BufEnter *.mjs,*.ejs,*.js,*.ts,*.jsx,*.tsx call easycomplete#sources#ts#lint()
    " hack for #56
    autocmd CompleteChanged *.mjs,*.ejs,*.js,*.ts,*.jsx,*.tsx call easycomplete#sources#ts#CompleteChanged()
    if g:env_is_vim
      autocmd SafeState *.mjs,*.ejs,*.js,*.ts,*.jsx,*.tsx call easycomplete#sources#ts#init()
    endif
  augroup END

  call s:RegistEventCallback('easycomplete#sources#ts#DiagnosticsCallback', 'diagnostics')
  call s:RegistResponseCallback('easycomplete#sources#ts#CompleteCallback', 'completions')
  call s:RegistResponseCallback('easycomplete#sources#ts#SignatureCallback', 'signatureHelp')
  call s:RegistResponseCallback('easycomplete#sources#ts#DefinationCallback', 'definition')
  call s:RegistResponseCallback('easycomplete#sources#ts#TsReloadingCallback', 'reload')
  call s:RegistResponseCallback('easycomplete#sources#ts#EntryDetailsCallback', 'completionEntryDetails')
  call easycomplete#util#AsyncRun('easycomplete#sources#ts#init', [], 5)

  let s:opt = a:opt
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
    echo printf('%s', "No defination found")
    return
  endif
  let defination = l:definition_info[0]
  let filename = get(defination, 'file', '')
  let start = get(defination, 'contextStart', {})

  call s:UpdateTagStack()
  try
    call s:location(fnameescape(filename), start.line, start.offset)
  catch
    echo printf('%s', v:exception)
  endtry
endfunction

function! easycomplete#sources#ts#TsReloadingCallback(item)
  let b:tsserver_reloading = 0
endfunction

function! easycomplete#sources#ts#DiagnosticsCallback(item)
  call s:HandleDiagnosticResponse(a:item)
endfunction

function! s:DiagnosticsRender()
  try
    let response = s:GetWrappedDiagnosticsCache()
  catch
    return
  endtry
  call easycomplete#sign#hold()
  call easycomplete#sign#flush()
  call easycomplete#sign#cache(response)
  call easycomplete#sign#render()
endfunction

" TSServer 格式:
" {
"   'seq': 0, 'type': 'event', 'event': 'syntaxDiag',
"   'body': {
"     'file': '/Users/bachi/ttt/b.js',
"     'diagnostics': [
"       {
"         'category': 'error',
"         'end': {'offset': 8, 'line': 1},
"         'code': 1005,
"         'text': ''';'' expected.',
"         'start': {'offset': 7, 'line': 1}
"       },
"       {...},
"       ...
"     ]
"   }
" }
"
" LSP 标准格式
" {
"   "method":"textDocument/publishDiagnostics",
"   "jsonrpc":"2.0",
"   "params":{
"     "uri":"file:///Users/bachi/ttt/python.vim",
"     "diagnostics":[
"       {
"         "source":"vimlsp",
"         "message":"E492: Not an editor command: oooo",
"         "severity":1,
"         "range": {
"           "end":{"character":1,"line":8},
"           "start":{"character":0,"line":8}
"         }
"       },
"       {...},
"       ...
"     ]
"   }
" }
function! s:HandleDiagnosticResponse(item)
  if get(a:item, "event", "") == "requestCompleted"
        \ && s:request_seq - 1 == get(a:item, "body")["request_seq"]
    call s:StopAsyncRun()
    call s:AsyncRun(function("s:DiagnosticsRender"), [], 100)
    return
  endif
  try
    let ts_diagnostics = get(a:item, "body", {"diagnostics":[]})["diagnostics"]
    let b:diagnostics_cache["uri"] = "file://" . a:item["body"]["file"]
  catch
    return
  endtry
  let lsp_diagnostics = []
  for item in ts_diagnostics
    call add(lsp_diagnostics, {
          \   "source":"tsc " . item["code"],
          \   "message": item["text"],
          \   "severity": s:GetSeverity(item["category"]),
          \   "range": {
          \     "start":{
          \       "character":item["start"]["offset"] - 1,
          \       "line":item["start"]["line"] - 1
          \     },
          \     "end":{
          \       "character":item["end"]["offset"] - 1,
          \       "line":item["end"]["line"] - 1
          \     }
          \   }
          \ })
  endfor
  let b:diagnostics_cache["cache"][a:item['event']] = lsp_diagnostics
  call s:StopAsyncRun()
  call s:AsyncRun(function("s:DiagnosticsRender"), [], 100)
endfunction

function! s:GetSeverity(category)
  return get(s:diagostics_category, a:category, 4)
endfunction

function! s:GetWrappedDiagnosticsCache()
  let syntaxdiag = b:diagnostics_cache["cache"]["syntaxDiag"]
  let semanticdiag = b:diagnostics_cache["cache"]["semanticDiag"]
  let suggestiondiag = b:diagnostics_cache["cache"]["suggestionDiag"]
  let diag_list = syntaxdiag + semanticdiag + suggestiondiag
  let res = {
      \   "method":"textDocument/publishDiagnostics",
      \   "jsonrpc": "2.0",
      \   "params": {
      \     "uri": b:diagnostics_cache["uri"],
      \     "diagnostics": deepcopy(diag_list)
      \   }
      \ }
  return res
endfunction

" EntryDetail Callback 数据结构
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
  call s:EntryDetailsStatusReset()
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

  if easycomplete#CompleteCursored()
    let l:item = easycomplete#GetCompletedItem()
    if !empty(l:item)
      call easycomplete#ShowCompleteInfoByItem(l:item)
    endif
  endif
endfunction

" 最初 Entry Details 的实现方式是跟随 CompleteCallback 来获取，跟随
" Completion 动作紧接着读取 EntryDetails 逻辑上是 ok 的，问题是大文
" 件中 DoFetchEntryDetails 动作很慢，在 2~4s 左右，有时会到 6s，等
" 待返回值的过程中 tsserver 处于挂起状态，影响交互体验，所以把这个
" 动作转移到了 CompleteChanged 中，跟随光标移动实时读取当前 item 所
" 需的 menuinfo，解决 #56 的问题
function! easycomplete#sources#ts#CompleteChanged()
  if !easycomplete#ok('g:easycomplete_enable')
    return
  endif
  let l:item = v:event.completed_item
  if !easycomplete#CompleteCursored() | return | endif
  if empty(s:request_queue_ctx)       | return | endif
  if s:EntryDetailsIsFetching()       | return | endif
  if !empty(
        \   easycomplete#util#GetInfoByCompleteItem(
        \      l:item,
        \      g:easycomplete_source[s:opt['name']].complete_result
        \   )
        \ )
    return
  endif
  " 异步执行，避免快速移动光标的闪烁
  call easycomplete#util#StopAsyncRun()
  call easycomplete#util#AsyncRun(function('s:DoFetchEntryDetails'),
        \ [s:request_queue_ctx, [l:item]],
        \ 50)
  " TODO: 这里的实现仅为保存 event 全局对象，和 popup 有耦合，需要重构
  let g:easycomplete_completechanged_event = deepcopy(v:event)
endfunction

function! easycomplete#sources#ts#signature()
  if !easycomplete#ok('g:easycomplete_signature_enable') | return | endif
  call s:TsserverReload()
  let ctx = easycomplete#context()
  let offset = ctx['col']
  let file = ctx['filepath']
  let l:args = {'file': file, 'line': line("."), 'offset': offset}
  call s:AsyncRun(function('s:SendCommandAsyncResponse'), ['signatureHelp',  l:args], 18)
endfunction

function! easycomplete#sources#ts#SignatureCallback(response)
  if !get(a:response, "success", 0)
    call easycomplete#popup#close("float")
    return
  endif
  let body = get(a:response, "body", {})
  let items = get(body, "items", [])
  if empty(items) | return | endif
  let item = items[0]
  let selected_item_index = get(body, 'selectedItemIndex', 0)
  let argument_count = get(body, 'argumentCount', 0)
  let argument_index = get(body, 'argumentIndex', 0)
  let param_length = len(item["parameters"])
  " 计算高亮参数所在的位置
  let hl_index = (argument_index + 1) >= param_length ? param_length - 1 : argument_index
  let prefix = easycomplete#util#NormalizeDetail(item, "prefixDisplayParts")
  let sepato = easycomplete#util#NormalizeDetail(item, "separatorDisplayParts")
  let params = []
  for elem in item["parameters"]
    call add(params, easycomplete#util#NormalizeDetail(elem, "displayParts")[0])
  endfor
  let offset_arr = prefix "  + [join(params, get(sepato, 0 ," "))]
  if hl_index > 0
    let offset_arr += [join(params[0:hl_index - 1], get(sepato, 0 ," "))]
    let offset_arr += [get(sepato, 0 ," ")]
  endif
  let offset_str = join(offset_arr, "")
  let offset_col = strlen(offset_str)

  let info = easycomplete#util#NormalizeSignatureDetail(item, hl_index)
  call easycomplete#popup#float(info, 'Pmenu', 1, "", [0, 0 - offset_col])
endfunction

" job complete 回调
function! easycomplete#sources#ts#CompleteCallback(item)
  if empty(a:item)
    return
  endif
  if easycomplete#IsBacking() | return | endif
  let l:request_req = get(a:item, 'request_seq')
  let l:ctx = easycomplete#util#GetCtxByRequestSeq(l:request_req)
  let l:raw_list = get(a:item, 'body')
  if empty(l:raw_list)
    call s:DoComplete(l:ctx, [])
    return
  endif

  let l:easycomplete_menu_list = map(filter(sort(copy(l:raw_list),
        \                       "s:SortTextComparator"), 'v:val.kind != "warning"'),
        \ function("s:CompleteMenuMap"))
  let s:request_queue_ctx = l:ctx
  if !easycomplete#SameBeginning(l:ctx, easycomplete#context())
    return
  endif
  " <del>如果返回时携带的 ctx 和当前的 ctx 不同，应当取消这次匹配动作</del>
  " if !easycomplete#CheckContextSequence(l:ctx)
  "   return
  " endif
  call s:DoComplete(easycomplete#context(), l:easycomplete_menu_list)
endfunction

function! s:DoComplete(ctx, menu_list)
  call easycomplete#complete(s:opt['name'], a:ctx, a:ctx['startcol'], a:menu_list)
endfunction

" 获取 keyword 的 More Info，menulist 是需要获取 Info 的 item 数组
function! s:DoFetchEntryDetails(ctx, menu_list)
  let l:entries= map(copy(a:menu_list), function("s:EntriesMap"))
  if type(l:entries) == type([]) && !empty(l:entries)
    call s:TsCompletionEntryDetails(a:ctx['filepath'], a:ctx['lnum'], a:ctx['col'], l:entries)
  endif
endfunction

function! s:NormalizeEntryDetail(item)
  return easycomplete#util#NormalizeEntryDetail(a:item)
endfunction

function! s:EntriesMap(key, val)
  let abbr = easycomplete#util#TrimWavyLine(a:val.abbr)
  return abbr
endfunction

function! s:CompleteMenuMap(key, val)
  let is_func = (a:val.kind ==# "method" || a:val.kind ==# "function")
  let val_name = a:val.name
  let ret = {
        \ "abbr": val_name,
        \ "dup": 1,
        \ "icase": 1,
        \ "kind": exists('a:val.kind') ? easycomplete#util#LspType(a:val.kind) : "",
        \ "menu": s:menu_flag,
        \ "word": val_name,
        \ "info": "",
        \ "equal":1
        \ }

  if is_func
    let ret['word'] = val_name . "()"
    let ret['abbr'] = val_name . "~"
    let ret['user_data'] = json_encode({
          \ 'expandable': 1,
          \ 'placeholder_position': strlen(val_name) + 1,
          \ 'cursor_backing_steps': 1
          \ })
  endif
  return ret
endfunction

function! easycomplete#sources#ts#completor(opt, ctx) abort
  if !easycomplete#installer#executable('tsserver')
    call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], [])
    return v:true
  endif
  call s:TsserverReload()
  call easycomplete#util#RestoreCtx(a:ctx, s:request_seq)
  if a:ctx['char'] == "/"
    return v:true
  endif
  call s:TsFlush()
  call s:FireTsCompletions(
        \   a:ctx['filepath'],
        \   a:ctx['lnum'],
        \   a:ctx['col'],
        \   a:ctx['typing']
        \ )
  " 返回 true 让其他插件的 completor 继续执行
  return v:true
endfunction

function! s:TsFlush()
  let s:request_queue_ctx = {}
  call s:EntryDetailsStatusReset()
  let g:easycomplete_completechanged_event = {}
endfunction

function! s:StopTsserver()
  if s:tsq_job.job > 0
    call easycomplete#job#stop(s:tsq_job.job)
  endif
endfunction

function! s:SendAsyncRequest(line)
  call s:StartTsserver()
  call easycomplete#job#send(s:tsq_job.job, a:line . "\n")
endfunction

function! s:SendCommandAsyncResponse(cmd, args)
  let l:input = json_encode({'command': a:cmd, 'arguments': a:args, 'type': 'request', 'seq': s:request_seq})
  call s:SendAsyncRequest(l:input)
  let s:request_seq = s:request_seq + 1
endfunction

function! s:SendCommandOneWay(cmd, args)
  call s:SendCommandAsyncResponse(a:cmd, a:args)
endfunction

" 从 TSServer 获取匹配完成的关键字
" PARAM: {string} file File name.
" PARAM: {string} line The line number of location to complete.
" PARAM: {string} offset The col number of location to complete.
" PARAM: {string} prefix Prefix to filter result set.
function! s:FireTsCompletions(file, line, offset, prefix)
  let l:args = {'file': a:file, 'line': a:line, 'offset': a:offset, 'prefix': a:prefix}
  call s:WaitForReloadDone() " shoule wait for reload done
  call s:SendCommandAsyncResponse('completions', l:args)
endfunction

function! easycomplete#sources#ts#lint()
  if !easycomplete#ok('g:easycomplete_enable')
    return
  endif
  if !easycomplete#ok('g:easycomplete_diagnostics_enable')
    return
  endif
  let l:files = [easycomplete#util#GetCurrentFullName()]
  call s:TsserverReload()
  call s:AsyncRun(function("s:Geterr"), [l:files, 100], 100)
endfunction

function! s:Geterr(files, delay)
  let l:args = {'files': a:files, 'delay': a:delay}
  call s:SendCommandAsyncResponse('geterr', l:args)
endfunction

function! s:CommonAsyncCommand(cmd, ctx)
  let l:args = {'file': a:ctx['filepath'], 'line': a:ctx['lnum'], 'offset': a:ctx['col'], 'prefix': a:ctx['typing']}
  call s:WaitForReloadDone()
  call s:SendCommandAsyncResponse(cmd, l:args)
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
  call s:EntryDetailsStatusSetFetching()
endfunction

" 跳转到定义位置
" PARAM: {string} file File name.
" PARAM: {int} line The line number of location to complete.
" PARAM: {int} offset The col number of location to complete.
function! s:GotoDefinition(file, line, offset)
  let l:args = {'file': a:file, 'line': a:line, 'offset': a:offset}
  call s:SendCommandAsyncResponse('definition', l:args)
endfunction

function! easycomplete#sources#ts#GotoDefinition(...)
  if !easycomplete#installer#executable('tsserver')
    return v:false
  endif
  let ext = tolower(easycomplete#util#extention())
  if index(s:file_extensions, ext) >= 0
    let l:ctx = easycomplete#context()
    call s:GotoDefinition(l:ctx["filepath"], l:ctx["lnum"], l:ctx["col"])
    " return v:true 成功跳转，告知主进程
    return v:true
  endif
  " exec "tag ". expand('<cword>')
  " 未成功跳转，则交给主进程处理
  return v:false
endfunction

function! s:TsServerIsRunning()
  if s:tsq_job.job <= 0
    return v:false
  endif
  let job_status = easycomplete#job#status(s:tsq_job.job)
  return job_status == 'run' ? v:true : v:false
endfunction

function! s:TsserverIsReady()
  if !easycomplete#installer#executable('tsserver')
    call easycomplete#util#info("Please Install tsserver by ",
          \ "':InstallLspServer' or 'npm -g install typescript'")
    return v:false
  endif
  return v:true
endfunction

function! s:StartTsserver()
  if !s:TsServerIsRunning()
    if !s:TsserverIsReady()
      return
    endif

    let l:command = easycomplete#installer#GetCommand("ts")
    if empty(l:command)
      echom '[easycomplete] tsserver is not installed. Try "npm -g install typescript".'
      return 0
    endif

    let job_status = easycomplete#job#status(s:tsq_job.job)
    let s:tsq_job.job = easycomplete#job#start(l:command . " --locale en",
          \ {'on_stdout': function('s:StdOutCallback')})
    if s:tsq_job.job <= 0
      echoerr "tsserver launch failed."
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
  elseif len(a:data) <= 2
    " 如果 job 回调不会一次性完整输出，会一个片段一个片段的输出
    " 需要先拼接每个片段组成一个完整的data，在执行 MessageHandler
    let s:callback_data_str = s:callback_data_str . a:data[0]
    if s:IsJSON(s:callback_data_str)
      call s:MessageHandler(s:callback_data_str)
      let s:callback_data_str = ""
      return
    endif
  endif
endfunction

function! s:IsJSON(str)
  return easycomplete#util#IsJson(a:str)
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
  if type(l:res_item) != type({})
    return
  endif

  " Ignore messages.
  if has_key(l:res_item, 'event') && index(s:ignore_response_events, get(l:res_item, 'event')) >= 0
    return
  endif

  let l:item = l:res_item
  let l:event_name = s:GetTsserverEventType(l:item)
  let l:response_name = s:GetTsserverResponseType(l:item)

  " normal 模式下只处理 definition 事件，其他事件均在插入模式下处理
  if easycomplete#util#NotInsertMode() && l:response_name !=# 'definition'
    return
  endif

  " 执行 event 的回调
  if !empty(l:event_name)
    if(has_key(s:event_callbacks, l:event_name))
      let EventCallback = function(s:event_callbacks[l:event_name], [l:item])
      call EventCallback()
    endif
    return
  endif

  " 执行 response 的回调
  if !empty(l:response_name)
    if(has_key(s:response_callbacks, l:response_name))
      let ResponseCallback = function(s:response_callbacks[l:response_name], [l:item])
      call ResponseCallback()
    endif
  endif
endfunction

function! s:SortTextComparator(entry1, entry2)
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
  let l:file_extention = tolower(easycomplete#util#extention())
  if index(["js","ts","jsx","tsx"], l:file_extention) >= 0
    call extend(l:args, {
          \  'scriptKindName': toupper(l:file_extention)
          \ })
  endif
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

" 判断当前 buf 所在的文件是否已经在 tsserver 中 open 过了
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
  silent! call writefile(getbufline(a:file_name, 1, '$'), tmpfile)
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

function! s:RegistEventCallback(callback, event_name)
  let s:event_callbacks[a:event_name] = a:callback
endfunction

function! s:RegistResponseCallback(callback, response_name)
  let s:response_callbacks[a:response_name] = a:callback
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
      \ || a:item.event ==# 'suggestionDiag'
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

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction

function! s:AsyncRun(...)
  return call('easycomplete#util#AsyncRun', a:000)
endfunction

function! s:StopAsyncRun(...)
  return call('easycomplete#util#StopAsyncRun', a:000)
endfunction
