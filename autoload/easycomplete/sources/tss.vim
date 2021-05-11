if get(g:, 'easycomplete_sources_tss')
  finish
endif
let g:easycomplete_sources_tss = 1

function! easycomplete#sources#tss#constructor(opt, ctx)
  if executable('typescript-language-server')
    call easycomplete#lsp#register_server({
          \ 'name': 'typescript-language-server',
          \ 'cmd': {server_info->['typescript-language-server', '--stdio']},
          \ 'root_uri':{server_info-> "file://". fnamemodify(expand('%'), ':p:h')},
          \ 'initialization_options': {'diagnostics': 'true'},
          \ 'whitelist': ['javascript','typescript','javascript.jsx','typescript.tsx'],
          \ 'workspace_config': {},
          \ 'semantic_highlight': {},
          \ })
  else
    echo printf("'vim-language-server' is not avilable, Please install: '%s'", 'npm -g install vim-language-server')
  endif
endfunction

function! easycomplete#sources#tss#completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! easycomplete#sources#tss#GotoDefinition(...)
  return easycomplete#DoLspDefinition(["js","ts","jsx","tsx"])
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction
