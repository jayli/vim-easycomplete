" params 信息的缓存
" key 是buf 绝对路径 /User/bachi/ttt...
let g:easycomplete_diagnostics_cache = {}

let g:easycomplete_diagnostics_config = {
      \ 'error':       {'type': 1, 'prompt_text': '>>', 'fg_color': g:env_is_cterm ? 'red' : '#FF0000'},
      \ 'warning':     {'type': 2, 'prompt_text': '>>', 'fg_color': g:env_is_cterm ? 'yellow' : '#FFFF00'},
      \ 'information': {'type': 3, 'prompt_text': '>>', 'fg_color': g:env_is_cterm ? 'blue' : '#00FFFF'},
      \ 'hint':        {'type': 4, 'prompt_text': '>>', 'fg_color': g:env_is_cterm ? 'green' : '#00FF00' }
      \ }

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
  if empty(server_info['server_names'])
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
  let cursor_index = easycomplete#sign#CursorIndex()[0]
  if len(diagnostics) == 1
    call easycomplete#sign#jump(0)
    return
  endif
  if cursor_index == len(diagnostics)
    call easycomplete#sign#jump(0)
    return
  endif
  call easycomplete#sign#jump(cursor_index)
endfunction

function! easycomplete#sign#previous()
  let origin_diagnostics = easycomplete#sign#GetCurrentDiagnostics()
  if easycomplete#sign#DiagnosticsIsEmpty(origin_diagnostics)
    return
  endif
  let diagnostics = easycomplete#sign#ValidDiagnostics(origin_diagnostics)
  let cursor_index = easycomplete#sign#CursorIndex()[0]
  let equal_flag = easycomplete#sign#CursorIndex()[1]
  if len(diagnostics) == 1
    call easycomplete#sign#jump(0)
    return
  endif
  if cursor_index >= len(diagnostics)
    call easycomplete#sign#jump(cursor_index - 1 - equal_flag)
    return
  endif
  if cursor_index == 0
    call easycomplete#sign#jump(len(diagnostics) - 1)
    return
  endif
  call easycomplete#sign#jump(cursor_index - 1 - equal_flag)
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
    let l:col = get(item, 'range')['start']['character']
    if current_line < l:line
      let cursor_index = l:count
      break
    endif
    if current_line == l:line && current_col < l:col
      let cursor_index = l:count
      break
    endif
    if current_line == l:line && current_col - 1 == l:col
      let equal_flag = 1
    endif
    let l:count += 1
  endwhile
  " cursor_index 是光标位置在 diagnostics 里的位置
  return [cursor_index, equal_flag]
endfunction

function! easycomplete#sign#jump(diagnostics_index)
  let diagnostics = easycomplete#sign#GetCurrentDiagnostics()
  let item = diagnostics[a:diagnostics_index]
  let l:line = get(item, 'range')['start']['line'] + 1
  let l:col = get(item, 'range')['start']['character']
  call cursor(l:line, l:col + 1)
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

function! easycomplete#sign#cache(response)
  let l:key = easycomplete#util#TrimFileName(a:response['params']['uri'])
  let g:easycomplete_diagnostics_cache[l:key] = a:response
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
    if line > buflinenr
      " lsp 有时返回 buf 行数 + 1 行报错，比如提示缺少 endfunction，这里选择直
      " 接丢弃，目前没发现有严重超行显示的报错干扰编程的情况
      let l:count += 1
      continue
      let line = 1
    endif
    " sign place 1 line=10 name=error_holder file=/Users/bachi/ttt/ttt.vim
    let fn = easycomplete#util#TrimFileName(uri)
    let cmd = "sign place " . l:count . " line=" . line . " name=error_holder file=" . fn
    call execute(cmd)
    let l:count += 1
    if l:count > 500 | break | endif
  endwhile

  call easycomplete#sign#LintCurrentLine()
endfunction

function! easycomplete#sign#LintCurrentLine()
  let ctx = easycomplete#context()
  let diagnostics_info = easycomplete#sign#GetDiagnosticsInfo(ctx["lnum"])
  if empty(diagnostics_info)
    echo ""
    return
  endif

  let msg = get(diagnostics_info, 'message', '')
  let msg = split(msg, "\\n")[0]
  echo printf('[%s]%s,%s %s',
        \ get(diagnostics_info, 'source', 'lsp'),
        \ get(diagnostics_info, 'range')['start']['line'] + 1,
        \ get(diagnostics_info, 'range')['start']['character'],
        \ msg
        \ )
endfunction

function! easycomplete#sign#GetDiagnosticsInfo(line)
  let lint_list = easycomplete#sign#GetCurrentDiagnostics()
  let l:count = 0
  let ret = {}
  while l:count < len(lint_list)
    let item = lint_list[l:count]
    let info_line = item.range.start.line
    if (info_line + 1) == a:line
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
  return deepcopy(cache.params.diagnostics)
endfunction

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction
