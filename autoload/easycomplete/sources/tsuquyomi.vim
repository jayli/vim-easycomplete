if get(g:, 'loaded_autoload_easycomplete_sources_tsuquyomi')
  finish
endif
let g:loaded_autoload_easycomplete_sources_tsuquyomi = 1
let s:save_cpo = &cpo
set cpo&vim

let s:request_seq = 1

let s:ignore_response_conditions = []
" ignore events configFileDiag triggered by reload event. See also #99
call add(s:ignore_response_conditions, '"type":"event","event":"configFileDiag"')
call add(s:ignore_response_conditions, '"type":"event","event":"telemetry"')
call add(s:ignore_response_conditions, '"type":"event","event":"projectsUpdatedInBackground"')
call add(s:ignore_response_conditions, '"type":"event","event":"setTypings"')
call add(s:ignore_response_conditions, '"type":"event","event":"syntaxDiag"')
call add(s:ignore_response_conditions, '"type":"event","event":"semanticDiag"')
call add(s:ignore_response_conditions, '"type":"event","event":"suggestionDiag"')
call add(s:ignore_response_conditions, '"type":"event","event":"typingsInstallerPid"')
call add(s:ignore_response_conditions, 'npm notice created a lockfile')

" ### Async variables
let s:callbacks = {}
let s:ctx_list = {}
let s:notify_callback = {}
let s:quickfix_list = []
" ### }}}

augroup easycomplete#sources#tsuquyomi#augroup
  autocmd!
  autocmd BufRead * call easycomplete#sources#tsuquyomi#init()
augroup END

function! easycomplete#sources#tsuquyomi#init()
  call easycomplete#util#AsyncRun('easycomplete#sources#tsuquyomi#tsOpen', [], 1)
endfunction

function! easycomplete#sources#tsuquyomi#tsOpen()
  call s:StartTss()
  call s:TsOpen(easycomplete#context()['filepath'])
endfunction


" Copied from https://github.com/yami-beta/easycomplete-omni.vim
" ORIGINAL LICENCE: MIT
" ORIGINAL AUTHOR: Takahiro Abe
function! easycomplete#sources#tsuquyomi#get_source_options(opts) abort
  return extend({
        \ 'refresh_pattern': '\%(\k\|\.\)',
        \}, a:opts)
endfunction

function! easycomplete#sources#tsuquyomi#constructor(opt, ctx)
  call s:registerCallback('easycomplete#sources#tsuquyomi#diagnosticsCallback', 'diagnostics')
endfunction

function! easycomplete#sources#tsuquyomi#diagnosticsCallback(item)
  " do nothing
endfunction

" Forked from https://github.com/yami-beta/easycomplete-omni.vim
" ORIGINAL LICENCE: MIT
" ORIGINAL AUTHOR: Takahiro Abe
" MODIFIED BY: ishitaku5522
function! easycomplete#sources#tsuquyomi#completor(opt, ctx) abort

  " jayli
  call s:restoreCtx(a:ctx)
  call s:TsCompletions(a:ctx['filepath'], a:ctx['lnum'], a:ctx['col'], a:ctx['typing'])
  " call tsuquyomi#complete(0, a:ctx['typing'])
  " let alist = tsuquyomi#tsClient#tsCompletions(a:ctx['filepath'], a:ctx['lnum'], a:ctx['col'], a:ctx['typing'])
  " call easycomplete#log(alist)
endfunction

function! s:nSort(a, b)
    return a:a == a:b ? 0 : a:a > a:b ? 1 : -1
endfunction

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

function! s:SendAsyncRequest(line)
  call s:StartTss()
  " call easycomplete#log(a:line)
  call ch_sendraw(s:tsq['channel'], a:line . "\n")
endfunction

function! s:SendCommandAsyncResponse(cmd, args)
  let l:input = json_encode({'command': a:cmd, 'arguments': a:args, 'type': 'request', 'seq': s:request_seq})
  call s:SendAsyncRequest(l:input)
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
function! s:TsCompletions(file, line, offset, prefix)
  let l:args = {'file': a:file, 'line': a:line, 'offset': a:offset, 'prefix': a:prefix}
  call s:SendCommandAsyncResponse('completions', l:args)
endfunction

function! easycomplete#sources#tsuquyomi#StartTss()
  call s:StartTss()
endfunction

function! s:StartTss()
  if !exists('s:tsq')
    let s:tsq = {'job':0}
  endif
  if type(s:tsq['job']) == 8 && job_info(s:tsq['job']).status == 'run'
    return 'existing'
  endif
  let l:cmd = "tsserver --locale en" " substitute(tsuquyomi#config#tsscmd(), '\\', '\\\\', 'g').' '.tsuquyomi#config#tssargs()
  try
    let s:tsq['job'] = job_start(l:cmd, {
      \ 'out_cb': {ch, msg -> easycomplete#sources#tsuquyomi#handleMessage(ch, msg)},
      \ })
    let s:tsq['channel'] = job_getchannel(s:tsq['job'])
    let out = ch_readraw(s:tsq['channel'])
    " let st = tsuquyomi#tsClient#statusTss()
  catch
    return 0
  endtry
  return 1
endfunction

function! s:TsOpen(file)
  let l:args = {'file': a:file}
  call s:SendCommandOneWay('open', l:args)
endfunction

function! easycomplete#sources#tsuquyomi#handleMessage(ch, msg)
  if type(a:msg) != 1 || a:msg == ''
    " Not a string or blank message.
    return
  endif
  let l:res_item = substitute(a:msg, 'Content-Length: \d\+', '', 'g')
  if l:res_item == ''
    " Ignore content-length.
    return
  endif
  " Ignore messages.
  let l:to_be_ignored = 0
  for ignore_reg in s:ignore_response_conditions
    let l:to_be_ignored = l:to_be_ignored || (l:res_item =~ ignore_reg)
    if l:to_be_ignored
      return
    endif
  endfor
  let l:item = json_decode(l:res_item)
  let l:eventName = s:getEventType(l:item)

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
    call easycomplete#complete('tsuquyomi', l:ctx, l:ctx['startcol'], l:menu_list)
  endif
endfunction

function! s:registerCallback(callback, eventName)
  let s:callbacks[a:eventName] = a:callback
endfunction

function! s:getEventType(item)
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

let &cpo = s:save_cpo
unlet s:save_cpo
