let s:tn_job = v:null
let s:ctx = v:null
let s:opt = v:null
let s:name = ''
let s:tn_ready = v:false
" TabNine 第一次匹配需要大量算法运算，比较耗时，完成第一次之后速度比较快
let b:module_building = v:false
let s:tn_render_timer = 0
let s:version = ''
" 只用作空格、等号、逗号这些情况强制触发 Tabnine complete 的标志位
" 0: 触发条件一律遵循 easycomplete#condition() 条件，和 FirstComplete 混合在一
" 起返回结果
" 1：单独触发
let s:force_complete = 0

function! easycomplete#sources#tn#constructor(opt, ctx)
  " call s:console('.')
  let s:opt = a:opt
  let name = get(a:opt, "name", "")
  let s:name = name
  if !easycomplete#installer#LspServerInstalled(name)
    return v:true
  endif
  if !easycomplete#ok('g:easycomplete_tabnine_enable')
    return v:true
  endif
  call s:StartTabNine()
  return v:true
endfunction

function! easycomplete#sources#tn#available()
  if easycomplete#ok('g:easycomplete_tabnine_enable')
    return s:tn_ready
  else
    return v:false
  endif
endfunction

function! s:flush()
  let global_opt = get(g:easycomplete_source, s:name, {})
  let global_opt.complete_result = []
  let s:force_complete = 0
endfunction

function! s:ResetForceCompleteFlag()
  let s:force_complete = 0
endfunction

" 只更新 g:easycomplete_sources['tn'].complete_result
" refresh(v:true), 强制给出匹配菜单
function! easycomplete#sources#tn#refresh(...)
  if exists("a:1") && a:1 == v:true
    let s:force_complete = 1
    call timer_start(100, { -> s:ResetForceCompleteFlag()})
  else
    let s:force_complete = 0
  endif
  if !easycomplete#ok('g:easycomplete_tabnine_enable')
    return
  endif
  call easycomplete#sources#tn#completor(s:opt, easycomplete#context())
endfunction

function! easycomplete#sources#tn#FireCondition()
  let l:ctx = easycomplete#context()
  let l:char = l:ctx["char"]
  let l:typed = l:ctx["typed"]
  if strlen(l:typed) >= 2
    if l:typed[-2:] == "' " || l:typed[-2:] == '" '
      return v:false
    endif
    if l:typed[strlen(l:typed) - 2] != " " && l:typed[strlen(l:typed) - 1] == " "
      return v:true
    endif
    let charset = [":","=",",",";",">", "'", '"']
    if index(charset, l:char) >= 0 &&
          \ index(charset, l:typed[strlen(l:typed) - 2]) < 0
      return v:true
    endif
    return v:false
  else
    return v:false
  endif
endfunction

function! easycomplete#sources#tn#GetGlboalSoucresItems()
  return g:easycomplete_source[s:name].complete_result
endfunction

function! easycomplete#sources#tn#completor(opt, ctx) abort
  if !s:tn_ready
    call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], [])
    return v:true
  endif
  if !exists('b:module_building') | let b:module_building = v:false | endif
  if b:module_building == v:false && len(easycomplete#GetStuntMenuItems()) == 0
    " 防止 tabnine 初始模型构建时的 UI 阻塞
    call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], [])
  endif
  call easycomplete#sources#tn#SimpleTabNineRequest(a:ctx)
  return v:true
endfunction

function! s:GetTabNineParams()
  let l:line_limit = get(g:easycomplete_tabnine_config, 'line_limit', 1000)
  let l:max_num_result = get(g:easycomplete_tabnine_config, 'max_num_result', 3)
  let l:pos = getpos('.')
  let l:last_line = line('$')
  let l:before_line = max([1, l:pos[1] - l:line_limit])
  let l:before_lines = getline(l:before_line, l:pos[1])
  if !empty(l:before_lines)
    let l:before_lines[-1] = l:before_lines[-1][:l:pos[2]-1]
  endif
  let l:after_line = min([l:last_line, l:pos[1] + l:line_limit])
  let l:after_lines = getline(l:pos[1], l:after_line)
  if !empty(l:after_lines)
    let l:after_lines[0] = l:after_lines[0][l:pos[2]:]
  endif

  let l:region_includes_beginning = v:false
  if l:before_line == 1
    let l:region_includes_beginning = v:true
  endif

  let l:region_includes_end = v:false
  if l:after_line == l:last_line
    let l:region_includes_end = v:true
  endif

  " TODO jayli here 加了"\n"，突然什么也出不来了？，现在好像出来了!
  " 又突然不好使了？
  " 如果结尾是一个"\n"，返回的结果里面会是一个代码片段"completion_kind":"Snippet"
  " 如果是complete的话，代码片段类型应该为"completion_kind":"Classic"
  let l:params = {
     \   'filename': expand('%:p'),
     \   'before': join(l:before_lines, "\n"),
     \   'after': join(l:after_lines, "\n"),
     \   'region_includes_beginning': l:region_includes_beginning,
     \   'region_includes_end': l:region_includes_end,
     \   'max_num_result': l:max_num_result,
     \   'net_length':1000
     \ }
  return l:params
endfunction

function! easycomplete#sources#tn#GetTabNineVersion()
  if empty(s:version)
    let l:tabnine_cmd = easycomplete#installer#GetCommand(s:name)
    let l:tabnine_dir = fnameescape(fnamemodify(l:tabnine_cmd, ':p:h'))
    let l:version_file = l:tabnine_dir . '/version'

    for line in readfile(l:version_file, '', 10)
      if trim(line) =~ "^\\d\\{-}.\\d\\{-}.\\d\\{-}$"
        let s:version = trim(line)
        break
      endif
    endfor
  endif
  return s:version
endfunction

" 返回 complete_kind: snippet 或者 classic
" 返回 nothing 说明匹配内容是空的
" 根据这里的返回来决定处理方式，是 suggest 还是 complete
function! s:TabNineCompleteKind(res_array)
  if empty(a:res_array)
    return "nothing"
  endif
  let results = get(a:res_array, "results", [])
  if empty(results)
    return 'nothing'
  endif
  let first_item = results[0]
  if has_key(first_item, 'completion_metadata')
    let metadata = get(first_item, 'completion_metadata', {})
    if empty(metadata)
      return 'nothing'
    endif
    let completion_kind = get(metadata, 'completion_kind', '')
    return tolower(completion_kind)
  else
    return "classic"
  endif
endfunction

function! s:TabNineRequest(name, param, ctx) abort
  if s:tn_job == v:null || !s:tn_ready
    return
  endif
  let l:req = {
        \ 'version': easycomplete#sources#tn#GetTabNineVersion(),
        \ 'request': {
        \     a:name : a:param
        \   },
        \ }
  try
    let l:buffer = json_encode(l:req) . "\n"
  catch /474/
    return
  endtry
  let s:ctx = a:ctx
  call easycomplete#job#send(s:tn_job, l:buffer)
endfunction

" 可以传参 ctx, 也可以留空
function! easycomplete#sources#tn#SimpleTabNineRequest(...)
  let l:ctx = exists('a:1') ? a:1 : easycomplete#context()
  let l:params = s:GetTabNineParams()
  " ['{"error":"Worker error: unknown variant `AutocompleteArgs`, expected one of `Autocomplete`, `AutocompleteV4471`, `AutocompleteV4451`, `AutocompleteV4448`, `AutocompleteV4121`, `AutocompleteV4057`, `AutocompleteV3534`, `AutocompleteV3271`, `AutocompleteV3253`, `AutocompleteV21`, `AutocompleteV20`, `AutocompleteV10`, `AutocompleteV6`, `AutocompleteV4`, `AutocompleteV3`, `AutocompleteV2`, `Inform`, `ListIndexedFiles`, `Metadata`, `State`, `SetState`, `SetStateV20`, `Features`, `Prefetch`, `GetIdentifierRegex`, `Configuration`, `Deactivate`, `Uninstalling`, `Restart`, `Notifications`, `NotificationAction`, `StatusBar`, `StatusBarAction`, `Hover`, `HoverAction`, `StartupActions`, `Event`, `HubStructure`, `Login`, `LoginWithCustomToken`, `LoginWithCustomTokenUrl`, `Logout`, `NotifyWorkspaceChanged`, `OpenUrl`, `SaveSnippet`, `SuggestionShown`, `SuggestionDropped`, `About`, `FileMetadata`, `RefreshRemoteProperties`, `StartLoginServer`, `ChatCommunicatorAddress`, `Workspace`"}', '']
  call s:TabNineRequest("Autocomplete", l:params, l:ctx)
endfunction

function! s:StartTabNine()
  if empty(s:name)
    return
  endif
  let name = s:name
  let l:tabnine_path = easycomplete#installer#GetCommand(name)
  let l:log_file = fnameescape(fnamemodify(l:tabnine_path, ':p:h')) . '/tabnine.log'
  let l:cmd = [
        \   l:tabnine_path,
        \   '--client',
        \   'vscode',
        \   '--log-file-path',
        \   l:log_file,
        \ ]
  let s:tn_job = easycomplete#job#start(l:cmd,
        \ {'on_stdout': function('s:TabnineJobCallback')})
  if s:tn_job <= 0
    call s:log("[TabNine Error]:", "TabNine job start failed")
  else
    let s:tn_ready = v:true
  endif
  call timer_start(700, { -> easycomplete#sources#tn#GetTabNineVersion()})
endfunction

function! s:TabnineJobCallback(job_id, data, event)
  let l:ctx = easycomplete#context()
  if a:event != 'stdout'
    call easycomplete#complete(s:name, s:ctx, s:ctx['startcol'], [])
    return
  endif
  if !exists('b:module_building') | let b:module_building = v:false | endif
  let b:module_building = v:true
  if !easycomplete#CheckContextSequence(s:ctx)
    call easycomplete#sources#tn#refresh()
    return
  endif
  " call s:console( "---")
  " a:data is a list
  let res_array = s:ArrayParse(a:data)
  " call s:console(res_array)
  let t9_cmp_kind = s:TabNineCompleteKind(res_array)
  " call s:console(res_array)
  " TODO 这里没有测试 t9_cmp_kind == 'snippet' 的情况，tabnine basic
  " 版本不支持 snippet
  if t9_cmp_kind == "nothing"
    call s:CompleteHandler([])
    return
  endif
  " 如果有标志位，等同认为是 suggest
  if !pumvisible() && easycomplete#tabnine#SuggestFlagCheck()
    call s:SuggestHandler(res_array)
  else " 配合pum显示tabnine提示词s
    let result_items = s:NormalizeCompleteResult(a:data)
    call s:CompleteHandler(result_items)
  endif

  " if t9_cmp_kind == 'snippet'
  "   call s:SuggestHandler(res_array)
  " elseif t9_cmp_kind == "nothing"
  "   call s:CompleteHandler([])
  " else
  "   let result_items = s:NormalizeCompleteResult(a:data)
  "   call s:CompleteHandler(result_items)
  " endif
endfunction

function! s:SuggestHandler(res_array)
  if pumvisible() | return | endif
  call easycomplete#tabnine#Callback(a:res_array)
endfunction

function! s:CompleteHandler(res)
  let result = a:res
  if empty(result)
    call s:flush()
  endif
  try
    if s:force_complete
      call easycomplete#util#call(function("s:UpdateRendering"), [result])
    else
      if len(easycomplete#GetStuntMenuItems()) == 0 && g:easycomplete_first_complete_hit == 0
        " First Complete
        call easycomplete#complete(s:name, s:ctx, s:ctx['startcol'], result)
      else
        " Second Complete
        if !easycomplete#CompleteCursored()
          call easycomplete#util#call(function("s:UpdateRendering"), [result])
        endif
        " if s:tn_render_timer > 0
        "   call timer_stop(s:tn_render_timer)
        "   let s:tn_render_timer = 0
        " endif
        " let s:tn_render_timer = timer_start(60,
        "       \ { -> easycomplete#util#call(function("s:UpdateRendering"), [result])
        "       \ })
      endif
    endif
  catch
    call s:log("[TabNine Error]:", "CompleteHandler", v:exception)
    let l:ctx = easycomplete#context()
    call easycomplete#complete(s:name, l:ctx, l:ctx['startcol'], [])
  endtry
endfunction

function! s:UpdateRendering(result)
  if easycomplete#sources#directory#pum()
    return
  endif
  call easycomplete#StoreCompleteSourceItems(s:name, a:result)
  call easycomplete#TabNineCompleteRendering()
endfunction

function! s:ArrayParse(data)
  if type(a:data) == type([]) && len(a:data) >= 1
    let l:data = a:data[0]
    if l:data == ""
      return []
    endif
    let l:response = json_decode(l:data)
  elseif type(a:data) == type({})
    let l:response = a:data
  else
    let l:response = json_decode(a:data)
  endif
  return l:response
endfunction

function! s:NormalizeCompleteResult(data)
  let l:col = s:ctx['col']
  let l:typed = s:ctx['typed']

  let l:kw = matchstr(l:typed, '\w\+$')
  let l:lwlen = len(l:kw)

  let l:startcol = l:col - l:lwlen
  let l:response = s:ArrayParse(a:data)
  let old_prefix = get(l:response, 'old_prefix', "")
  if old_prefix !=# s:ctx["typing"]
    let tn_prefix = substitute(s:ctx['typing'], old_prefix . "$","","g")
  else
    let tn_prefix = ""
  endif
  let l:words = []
  for l:result in l:response['results']
    let l:word = {}

    let l:new_prefix = get(l:result, 'new_prefix')
    if l:new_prefix == ''
      continue
    endif
    let l:word['word'] = l:new_prefix

    if get(l:result, 'old_suffix', '') != '' || get(l:result, 'new_suffix', '') != ''
      let l:user_data = {
            \   'old_suffix': get(l:result, 'old_suffix', ''),
            \   'new_suffix': get(l:result, 'new_suffix', ''),
            \ }
      let l:word['user_data'] = json_encode(l:user_data)
    endif

    if !empty(g:easycomplete_kindflag_tabnine)
      let l:word["kind"] = g:easycomplete_kindflag_tabnine
    endif
    if !empty(g:easycomplete_menuflag_tabnine)
      let l:word["menu"] = g:easycomplete_menuflag_tabnine
    else
      let l:word['menu'] = '[TN]'
    endif
    if get(l:result, 'detail')
      let l:word['menu'] .= ' ' . l:result['detail']
    endif
    let l:word['abbr'] = l:word['word']
    let l:word['word'] = tn_prefix . l:word['word']
    call add(l:words, l:word)
  endfor
  return l:words
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
