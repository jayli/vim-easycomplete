" params 信息的缓存
" key 是buf 绝对路径 /User/bachi/ttt...
let g:easycomplete_diagnostics_cache = {}
let s:easycomplete_diagnostics_hint = 1

let g:easycomplete_diagnostics_config = {
      \ 'error':       {'type': 1, 'prompt_text': '>>', 'fg_color': g:env_is_cterm ? 'red' :    '#FF0000'},
      \ 'warning':     {'type': 2, 'prompt_text': '>>', 'fg_color': g:env_is_cterm ? 'yellow' : '#FFFF00'},
      \ 'information': {'type': 3, 'prompt_text': '>>', 'fg_color': g:env_is_cterm ? '31' :     '#0087AF'},
      \ 'hint':        {'type': 4, 'prompt_text': '>>', 'fg_color': g:env_is_cterm ? '99' :     '#8787FF'}
      \ }

function! easycomplete#sign#test()
  let fn = easycomplete#util#TrimFileName(easycomplete#util#GetCurrentFullName())
  let res = {'method': 'textDocument/publishDiagnostics',
        \ 'jsonrpc': '2.0',
        \ 'params': {
        \    'uri': 'file://' . fn,
        \    'diagnostics': [
        \      {'source': 'vimlsp', 'message': 'E492: 1', 'severity': 1, 'sortNumber': 2001,
        \       'range': {
        \         'end': {'character': 1, 'line': 1},
        \          'start': {'character': 0, 'line': 1}
        \        },
        \      },
        \      {'source': 'vimlsp', 'message': 'E492: 1', 'severity': 2, 'sortNumber': 3001,
        \       'range': {
        \         'end': {'character': 1, 'line': 2},
        \          'start': {'character': 0, 'line': 2}
        \        },
        \      },
        \      {'source': 'vimlsp', 'message': 'E492: 1', 'severity': 3, 'sortNumber': 4001,
        \       'range': {
        \         'end': {'character': 1, 'line': 3},
        \          'start': {'character': 0, 'line': 3}
        \        },
        \      },
        \      {'source': 'vimlsp', 'message': 'E492: 1', 'severity': 4, 'sortNumber': 5001,
        \       'range': {
        \         'end': {'character': 1, 'line': 4},
        \          'start': {'character': 0, 'line': 4}
        \        },
        \      },
        \    ]
        \  }
        \ }
  call easycomplete#sign#hold()
  call easycomplete#sign#flush()
  call easycomplete#sign#cache(res)
  call easycomplete#sign#render()
endfunction

function! easycomplete#sign#GetStyle(msg_type)
  return {
        \ 'TextStyle': toupper(a:msg_type[0]) . tolower(a:msg_type[1:]) . 'TextStyle',
        \ 'LineStyle': toupper(a:msg_type[0]) . tolower(a:msg_type[1:]) . 'LineStyle',
        \ }
endfunction

" 只清空当前buf的diagnostics
function! easycomplete#sign#flush()
  if !exists("g:easycomplete_diagnostics_cache")
    let g:easycomplete_diagnostics_cache = {}
  endif
  if empty(get(g:easycomplete_diagnostics_cache, easycomplete#util#GetCurrentFullName(), {}))
    let g:easycomplete_diagnostics_cache[easycomplete#util#GetCurrentFullName()] = {}
    return
  endif
  let server_info = easycomplete#util#FindLspServers()
  if get(g:, 'easycomplete_sources_ts', 0) != 1 && empty(server_info['server_names'])
    return
  endif
  let cache = g:easycomplete_diagnostics_cache[easycomplete#util#GetCurrentFullName()]
  " let lsp_server = server_info['server_names'][0]
  " file:///...
  let diagnostics_uri = cache['params']['uri']
  let diagnostics_list = cache['params']['diagnostics']
  let fn = easycomplete#util#TrimFileName(easycomplete#util#GetFullName(diagnostics_uri))
  let l:count = 1
  while l:count <= len(diagnostics_list)
    call execute("sign unplace " . l:count . " file=" . fn)
    let l:count += 1
  endwhile
  let g:easycomplete_diagnostics_cache[easycomplete#util#GetCurrentFullName()] = {}
endfunction

function! easycomplete#sign#normalize(opt_config)
  let opt = a:opt_config
  for key in keys(opt)
    let styles = easycomplete#sign#GetStyle(key)
    call extend(opt[key], styles)
  endfor
  return opt
endfunction

function! easycomplete#sign#init()
  if !exists("g:easycomplete_diagnostics_cache")
    let g:easycomplete_diagnostics_cache = {}
    let g:easycomplete_diagnostics_cache[easycomplete#util#GetCurrentFullName()] = {}
  endif
  let opt = easycomplete#sign#normalize(g:easycomplete_diagnostics_config)
  let sign_column_bg = easycomplete#ui#GetBgColor('SignColumn')
  let normal_bg = easycomplete#ui#GetBgColor('Normal')
  for key in keys(opt)
    let sign_cmd = ['sign',
          \ 'define',
          \ key . '_holder',
          \ 'text=' . opt[key].prompt_text,
          \ 'texthl=' . opt[key].TextStyle,
          \ 'linehl=' . opt[key].LineStyle
          \ ]
    exec join(sign_cmd, " ")
    call easycomplete#ui#hi(opt[key].TextStyle, opt[key]['fg_color'], sign_column_bg, "")
    call easycomplete#ui#hi(opt[key].LineStyle, -1, normal_bg, "")
  endfor
  call execute('sign define place_holder text='. opt['error'].prompt_text . ' texthl=PlaceHolder')
  call easycomplete#ui#hi('PlaceHolder', sign_column_bg, sign_column_bg, "")
  call easycomplete#sign#command()
endfunction

function! easycomplete#sign#command()
  command! EasyCompleteNextDiagnostic : call easycomplete#sign#next()
  command! EasyCompletePreviousDiagnostic : call easycomplete#sign#previous()
endfunction

function! easycomplete#sign#next()
  let origin_diagnostics = easycomplete#sign#GetCurrentDiagnostics()
  if easycomplete#sign#DiagnosticsIsEmpty(origin_diagnostics)
    return
  endif
  let diagnostics = easycomplete#sign#ValidDiagnostics(origin_diagnostics)
  let cursor_index_arr = easycomplete#sign#CursorIndex()
  let cursor_index = cursor_index_arr[0]
  let equal_flag = cursor_index_arr[1]
  if len(diagnostics) == 1
    call easycomplete#sign#jump(0)
    return
  endif
  if cursor_index + equal_flag >= len(diagnostics)
    call easycomplete#sign#jump(0)
    return
  endif
  call easycomplete#sign#jump(cursor_index + equal_flag)
endfunction

function! easycomplete#sign#previous()
  let origin_diagnostics = easycomplete#sign#GetCurrentDiagnostics()
  if easycomplete#sign#DiagnosticsIsEmpty(origin_diagnostics)
    return
  endif
  let diagnostics = easycomplete#sign#ValidDiagnostics(origin_diagnostics)
  let cursor_index_arr = easycomplete#sign#CursorIndex()
  let cursor_index = cursor_index_arr[0]
  let equal_flag = cursor_index_arr[1]
  if len(diagnostics) == 1
    call easycomplete#sign#jump(0)
    return
  endif
  if cursor_index == len(diagnostics)
    call easycomplete#sign#jump(len(diagnostics) - 1 - equal_flag)
    return
  endif
  if cursor_index == 0
    call easycomplete#sign#jump(len(diagnostics) - 1)
    return
  endif
  call easycomplete#sign#jump(cursor_index - 1)
endfunction

function! easycomplete#sign#CursorIndex()
  let origin_diagnostics = easycomplete#sign#GetCurrentDiagnostics()
  let diagnostics = easycomplete#sign#ValidDiagnostics(origin_diagnostics)
  let ctx = easycomplete#context()
  let current_line = ctx["lnum"]
  let current_col = ctx["col"]
  let cursor_index = len(diagnostics)
  let equal_flag = 0
  let l:count = 0
  while l:count < len(diagnostics)
    let item = diagnostics[l:count]
    let l:line = get(item, 'range')['start']['line'] + 1
    let l:col = get(item, 'range')['start']['character'] + 1
    if current_line < l:line
      let cursor_index = l:count
      break
    endif
    if current_line == l:line && current_col < l:col
      let cursor_index = l:count
      break
    endif
    if current_line == l:line && current_col  == l:col
      let cursor_index = l:count
      let equal_flag = 1
      break
    endif
    let l:count += 1
  endwhile
  " cursor_index 是光标位置在 diagnostics 里的位置
  return [cursor_index, equal_flag]
endfunction

function! easycomplete#sign#GetSortNumbers()
  let origin_diagnostics = easycomplete#sign#GetCurrentDiagnostics()
  let diagnostics = easycomplete#sign#ValidDiagnostics(origin_diagnostics)
  let arr = []
  let l:count = 0
  while l:count < len(diagnostics)
    call add(arr, diagnostics[l:count]["sortNumber"])
    let l:count += 1
  endwhile
  return arr
endfunction

function! easycomplete#sign#jump(diagnostics_index)
  let diagnostics = easycomplete#sign#GetCurrentDiagnostics()
  let item = diagnostics[a:diagnostics_index]
  let l:line = get(item, 'range')['start']['line'] + 1
  let l:col = get(item, 'range')['start']['character'] + 1
  call cursor(l:line, l:col)
  call easycomplete#sign#LintCurrentLine()
endfunction

" 返回当前文件所有合法的lint
function! easycomplete#sign#ValidDiagnostics(diagnostics)
  if empty(a:diagnostics)
    return []
  endif
  let bufline = len(getbufline(bufnr(''),1,'$'))
  if bufline == 0
    return []
  endif
  let arr = []
  let l:count = 0
  while l:count < len(a:diagnostics)
    let item = a:diagnostics[l:count]
    if item['range']['start']['line'] + 1 <= bufline
      call add(arr, item)
    endif
    let l:count += 1
  endwhile
  return arr
endfunction

function! easycomplete#sign#DiagnosticsIsEmpty(diagnostics)
  if empty(a:diagnostics)
    return v:true
  endif
  let bufline = len(getbufline(bufnr(''),1,'$'))
  if bufline == 0
    return v:true
  endif
  let flag = v:true
  let l:count = 0
  while l:count < len(a:diagnostics)
    let item = a:diagnostics[l:count]
    if item['range']['start']['line'] + 1 <= bufline
      let flag = v:false
      break
    endif
    let l:count += 1
  endwhile
  return flag
endfunction

function! easycomplete#sign#hold()
  let diagnostics = easycomplete#sign#GetCurrentDiagnostics()
  if easycomplete#sign#DiagnosticsIsEmpty(diagnostics)
    call easycomplete#sign#flush()
  else
    let cache = get(g:easycomplete_diagnostics_cache, easycomplete#util#GetCurrentFullName(), {})
    let uri = cache['params']['uri']
    let fn = easycomplete#util#TrimFileName(uri)
    let file_line_plus_one = len(getbufline(bufnr(''),1,'$')) + 1
    if get(g:, "easycomplete_place_holder", 0) == 0
      let cmd = "sign place 999 line=" . file_line_plus_one . " name=place_holder file=" . fn
      call execute(cmd)
      let g:easycomplete_place_holder = 1
    endif
  endif
endfunction

function! easycomplete#sign#unhold()
  if get(g:, "easycomplete_place_holder", 0) == 1
    call execute("sign unplace 999 file=" . easycomplete#util#GetCurrentFullName())
  endif
  let g:easycomplete_place_holder = 0
endfunction

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
function! easycomplete#sign#cache(response)
  let l:key = easycomplete#util#TrimFileName(a:response['params']['uri'])
  let g:easycomplete_diagnostics_cache[l:key] = a:response
  let diagnostics = easycomplete#sign#GetCurrentDiagnostics()
  let diagnostics_result = easycomplete#sign#SetDiagnosticsIndexes(diagnostics)
  if !empty(diagnostics_result)
    call sort(diagnostics_result, 'easycomplete#sign#sort')
    let g:easycomplete_diagnostics_cache[l:key]['params']['diagnostics'] = diagnostics_result
    let tmp_diagnostics = g:easycomplete_diagnostics_cache[l:key]['params']['diagnostics']
    let g:easycomplete_diagnostics_cache[l:key]['params']['diagnostics'] =
          \ easycomplete#sign#distinct(tmp_diagnostics)
  endif
endfunction

" param.range.start.line | param.range.start.character => sortNumber
function! easycomplete#sign#SetDiagnosticsIndexes(diagnostics)
  let ret = []
  for item in a:diagnostics
    let decimal_num = str2nr(item['range']['start']['character']) + 1
    let decimal_str = easycomplete#util#fullfill(string(decimal_num))
    let sort_number = join(
                        \ [
                        \ string(item['range']['start']['line'] + 1),
                        \ decimal_str
                        \ ], 
                        \ ".")
    let item.sortNumber = float2nr(str2float(sort_number) * 1000)
    call add(ret, item)
  endfor
  return ret
endfunction

function! easycomplete#sign#distinct(diagnostics)
  if empty(a:diagnostics)
    return []
  endif
  let ret = []
  for item in a:diagnostics
    if easycomplete#sign#has(ret, item)
      continue
    else
      call add(ret, item)
    endif
  endfor
  return ret
endfunction

function! easycomplete#sign#has(diagnostics, item)
  let flag = v:false
  for elem in a:diagnostics
    if elem["sortNumber"] == a:item["sortNumber"]
      let flag = v:true
      break
    endif
  endfor
  return flag
endfunction

function! easycomplete#sign#sort(entry1, entry2)
  return get(a:entry1, "sortNumber", 0) - get(a:entry2, "sortNumber", 0)
endfunction

" pass diagnostics response object form lsp
function! easycomplete#sign#render(...)
  let buflinenr = len(getbufline(bufnr(''),1,'$'))
  if exists("a:1")
    call easycomplete#sign#cache(a:1)
  endif
  let diagnostics = easycomplete#sign#GetCurrentDiagnostics()
  if easycomplete#sign#DiagnosticsIsEmpty(diagnostics)
    call easycomplete#sign#unhold()
    call easycomplete#sign#flush()
    return
  endif
  let current_cache = g:easycomplete_diagnostics_cache[easycomplete#util#GetCurrentFullName()]
  let uri = current_cache['params']['uri']
  let l:count = 1
  while l:count <= len(diagnostics)
    let item = diagnostics[l:count-1]
    let line = item['range']['start']['line'] + 1
    let severity = get(item, "severity", 4)
    if line > buflinenr
      " lsp 有时返回 buf 行数 + 1 行报错，比如提示缺少 endfunction，这里选择直
      " 接丢弃，目前没发现有严重超行显示的报错干扰编程的情况
      let l:count += 1
      continue
      let line = 1
    endif
    " sign place 1 line=10 name=error_holder file=/Users/bachi/ttt/ttt.vim
    let fn = easycomplete#util#TrimFileName(uri)
    let cmd = printf('sign place %s line=%s name=%s file=%s',
          \ l:count,
          \ line,
          \ s:GetSignStyle(severity),
          \ fn
          \ )
    call execute(cmd)
    let l:count += 1
    if l:count > 500 | break | endif
  endwhile

  call easycomplete#sign#LintCurrentLine()
endfunction

function! s:GetSignStyle(severity)
  let style = "hint_holder"
  for k in keys(g:easycomplete_diagnostics_config)
    let item = g:easycomplete_diagnostics_config[k]
    if item["type"] == a:severity
      let style = k . "_holder"
      break
    endif
  endfor
  return style
endfunction

function! easycomplete#sign#LintCurrentLine()
  if !easycomplete#ok('g:easycomplete_diagnostics_enable')
    call easycomplete#sign#unhold()
    call easycomplete#sign#flush()
    return
  endif
  let ctx = easycomplete#context()
  let diagnostics_info = easycomplete#sign#GetDiagnosticsInfo(ctx["lnum"], ctx["col"])
  if empty(diagnostics_info) && s:easycomplete_diagnostics_hint == 1
    call easycomplete#nill()
    echo ""
    let s:easycomplete_diagnostics_hint = 0
    return
  elseif empty(diagnostics_info)
    call easycomplete#nill()
    return
  else
    " Use AsyncRun for #91 bugfix
    call s:AsyncRun(function("s:ShowDiagMsg"), [diagnostics_info], 10)
  endif
endfunction

function! s:ShowDiagMsg(diagnostics_info)
  let msg = get(a:diagnostics_info, 'message', '')
  let msg = split(msg, "\\n")[0]
  let showing = printf('[%s] (%s,%s) %s',
        \ toupper(get(a:diagnostics_info, 'source', 'lsp')),
        \ get(a:diagnostics_info, 'range')['start']['line'] + 1,
        \ get(a:diagnostics_info, 'range')['start']['character'] + 1,
        \ msg
        \ )
  " offset 的目的是确保不这行
  let offset = 13
  if strlen(showing) > winwidth(winnr()) - offset
    let showing = showing[0:winwidth(winnr()) - offset - 3] . '...'
  endif
  echo showing
  let s:easycomplete_diagnostics_hint = 1
endfunction

function! easycomplete#sign#GetDiagnosticsInfo(line, colnr)
  let lint_list = easycomplete#sign#GetCurrentDiagnostics()
  let l:count = 0
  let ret = {}
  while l:count < len(lint_list)
    let item = lint_list[l:count]
    let info_line = item.range.start.line + 1
    let info_col_start = item.range.start.character + 1
    let info_col_end= item.range.end.character + 1
    if info_line == a:line && (a:colnr >= info_col_start && a:colnr <= info_col_end)
      let ret = item
      break
    endif
    let l:count += 1
  endwhile
  return ret
endfunction

function! easycomplete#sign#GetCurrentDiagnostics()
  if !exists("g:easycomplete_diagnostics_cache")
    return []
  endif
  let cache = get(g:easycomplete_diagnostics_cache, easycomplete#util#GetCurrentFullName(), {})
  if empty(cache)
    return []
  endif
  if len(cache.params.diagnostics) == 0
    return []
  endif
  return cache.params.diagnostics
endfunction

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction

function! s:AsyncRun(...)
  return call('easycomplete#util#AsyncRun', a:000)
endfunction

function! s:StopAsyncRun(...)
  return call('easycomplete#util#StopAsyncRun', a:000)
endfunction
