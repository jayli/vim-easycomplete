

" params 信息的缓存
let g:easycomplete_diagnostics_cache = {}

let g:easycomplete_diagnostics_config = {
      \ 'error':       {'type': 1, 'prompt_text': '>>', 'color': 'red'    },
      \ 'warning':     {'type': 2, 'prompt_text': '>>', 'color': 'yellow' },
      \ 'information': {'type': 3, 'prompt_text': '>>', 'color': 'blue'   },
      \ 'hint':        {'type': 4, 'prompt_text': '>>', 'color': 'green'  }
      \ }

function! easycomplete#sign#GetStyle(msg_type)
  return {
        \ 'TextStyle': toupper(a:msg_type[0]) . tolower(a:msg_type[1:]) . 'TextStyle',
        \ 'LineStyle': toupper(a:msg_type[0]) . tolower(a:msg_type[1:]) . 'LineStyle',
        \ }
endfunction

function! easycomplete#sign#flush()
  if empty(g:easycomplete_diagnostics_cache) | return | endif

  let server_info = easycomplete#util#FindLspServers()
  if empty(server_info['server_names'])
    return
  endif

  " let lsp_server = server_info['server_names'][0]
  " file:///...
  let diagnostics_uri = g:easycomplete_diagnostics_cache['params']['uri']
  let diagnostics_list = g:easycomplete_diagnostics_cache['params']['diagnostics']
  let fn = easycomplete#util#TrimFileName(easycomplete#util#GetFullName(diagnostics_uri))
  let l:count = 1
  while l:count <= len(diagnostics_list)
    call execute("sign unplace " . l:count . " file=" . fn)
    let l:count += 1
  endwhile
  let g:easycomplete_diagnostics_cache = {}
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
  let opt = easycomplete#sign#normalize(g:easycomplete_diagnostics_config)
  for key in keys(opt)
    let sign_cmd = ['sign',
          \ 'define',
          \ key . '_holder',
          \ 'text=' . opt[key].prompt_text,
          \ 'texthl=' . opt[key].TextStyle,
          \ 'linehl=' . opt[key].LineStyle
          \ ]
    exec join(sign_cmd, " ")
  endfor
  call execute('sign define place_holder text='. opt.error.prompt_text . ' texthl=PlaceHolder')
endfunction

function! easycomplete#sign#cache(response)
  echom g:easycomplete_diagnostics_cache
  let g:easycomplete_diagnostics_cache = deepcopy(a:response)
endfunction

function! easycomplete#sign#render()
  if !exists("g:easycomplete_diagnostics_cache.params.diagnostics")
    return
  endif

  let uri = g:easycomplete_diagnostics_cache['params']['uri']
  let l:count = 1
  while l:count <= len(g:easycomplete_diagnostics_cache['params']['diagnostics'])
    let item = g:easycomplete_diagnostics_cache['params']['diagnostics'][count]
    let line = item['range']['start']['line'] + 1
    " sign place 1 line=10 name=error_holder file=/Users/bachi/ttt/ttt.vim
    let fn = easycomplete#util#TrimFileName(uri)
    let cmd = "sign place " . l:count . " line=".line." name=error_holder file=" . fn
    call execute(cmd)
    let l:count += 1
    if l:count > 100 | break | endif
  endwhile
endfunction

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction
