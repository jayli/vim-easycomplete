if get(g:, 'easycomplete_sources_xml')
  finish
endif
let g:easycomplete_sources_xml = 1

function! easycomplete#sources#xml#constructor(opt, ctx)
  call easycomplete#RegisterLspServer(a:opt, {
      \ 'name': 'lemminx',
      \ 'cmd': [easycomplete#installer#GetCommand(a:opt['name'])],
      \ 'root_uri':{server_info -> "file://" . fnamemodify(expand('%'), ':p:h')},
      \ 'initialization_options': {},
      \ 'allowlist': ['xml']
      \ })
endfunction

function! easycomplete#sources#xml#completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! easycomplete#sources#xml#GotoDefinition(...)
  return easycomplete#DoLspDefinition(["xml"])
endfunction


