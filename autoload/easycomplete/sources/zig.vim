function! easycomplete#sources#zig#constructor(opt, ctx)
  call easycomplete#RegisterLspServer(a:opt, {
      \ 'name': 'zls',
      \ 'cmd': [easycomplete#installer#GetCommand(a:opt['name']), '--config-path',
      \         easycomplete#installer#LspServerDir() . '/zig/zls.json'],
      \ 'allowlist': a:opt['whitelist'],
      \ 'root_uri':{server_info->easycomplete#util#GetDefaultRootUri()},
      \ })
endfunction

function! easycomplete#sources#zig#completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! easycomplete#sources#zig#GotoDefinition(...)
  return easycomplete#DoLspDefinition(["zig","zon"])
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction
