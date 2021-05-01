if exists('g:easycomplete_json')
  finish
endif
let g:easycomplete_json = 1

function! easycomplete#sources#json#constructor(opt, ctx)
  if executable('json-languageserver')
    " TODO 不好使
    call easycomplete#lsp#register_server({
        \ 'name': 'json-languageserver',
        \ 'cmd': {server_info->lsp_settings#get('json-languageserver', 'cmd', [lsp_settings#exec_path('json-languageserver'), '--stdio'])},
        \ 'root_uri':{server_info->lsp_settings#get('json-languageserver', 'root_uri', lsp_settings#root_uri('json-languageserver'))},
        \ 'initialization_options': lsp_settings#get('json-languageserver', 'initialization_options', {'provideFormatter': v:true}),
        \ 'allowlist': lsp_settings#get('json-languageserver', 'allowlist', ['json', 'jsonc']),
        \ 'blocklist': lsp_settings#get('json-languageserver', 'blocklist', []),
        \ 'config': lsp_settings#get('json-languageserver', 'config', lsp_settings#server_config('json-languageserver')),
        \ 'workspace_config': lsp_settings#get('json-languageserver', 'workspace_config', {name, key->{'json': {'format': {'enable': v:true}, 'schemas': lsp_settings#utils#load_schemas('json-languageserver') + [{'fileMatch':['/vim-lsp-settings/settings.json', '/.vim-lsp-settings/settings.json'], 'url': 'https://mattn.github.io/vim-lsp-settings/local-schema.json'}]}}}),
        \ 'semantic_highlight': lsp_settings#get('json-languageserver', 'semantic_highlight', {}),
        \ })
  endif
endfunction

function! easycomplete#sources#json#completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! easycomplete#sources#json#GotoDefinition(...)
  return easycomplete#DoLspDefinition(["json"])
endfunction

