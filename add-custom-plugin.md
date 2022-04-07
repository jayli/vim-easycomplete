## Add custom completion plugin

Take snip as an example ([source file](https://github.com/jayli/vim-easycomplete/blob/master/autoload/easycomplete/sources/snips.vim)) without lsp server.

```vim
au User easycomplete_custom_plugin call easycomplete#RegisterSource({
    \ 'name':        'snips',
    \ 'whitelist':   ['*'],
    \ 'completor':   'easycomplete#sources#snips#completor',
    \ 'constructor': 'easycomplete#sources#snips#constructor',
    \  })
```

Another example with lsp server support is easier. [source file](https://github.com/jayli/vim-easycomplete/blob/master/autoload/easycomplete/sources/py.vim). By the way, you don't have to writing an omnifunc for Vim's omnicomplete.

You can redefine a completion plugin via `easycomplete_custom_plugin` event with the same name of default lsp plugin. For example. We replace `ts` plugin's lsp server `tsserver` by `typescript-language-server`. Copy this code in your `.vimrc`:

```vim
au User easycomplete_custom_plugin call easycomplete#RegisterSource({
    \ 'name': 'ts',
    \ 'whitelist': ['javascript','typescript','javascript.jsx',
    \               'typescript.tsx', 'javascriptreact', 'typescriptreact'],
    \ 'completor': function('g:Tss_Completor'),
    \ 'constructor': function('g:Tss_Constructor'),
    \ 'gotodefinition': function('g:Tss_GotoDefinition'),
    \ 'command': 'typescript-language-server'
    \  })

function! g:Tss_Constructor(opt, ctx)
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
    call easycomplete#util#log(printf("'typescript-language-server'".
          \ "is not avilable, Please install: '%s'",
          \ 'npm -g install typescript-language-server'))
  endif
endfunction

function! g:Tss_Completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! g:Tss_GotoDefinition(...)
  return easycomplete#DoLspDefinition(["js","ts","jsx","tsx"])
endfunction
```
