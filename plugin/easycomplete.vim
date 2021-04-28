" File:         easycomplete.vim
" Author:       @jayli <https://github.com/jayli/>
"               更多信息请访问 <https://github.com/jayli/vim-easycomplete>
"               帮助信息请执行
"                :helptags ~/.vim/doc
"                :h EasyComplete

" finish

if get(g:, 'easycomplete_plugin_init')
  finish
endif
let g:easycomplete_plugin_init = 1

let g:env_is_vim = has('nvim') ? v:false : v:true
let g:env_is_nvim = has('nvim') ? v:true : v:false

if (g:env_is_vim && v:version < 802) || (g:env_is_nvim && !has('nvim-0.4.0'))
  echom "EasyComplete requires vim version upper than 802".
        \ " or nvim version upper than 0.4.0"
  finish
endif

" augroup FileTypeChecking
"   let ext = substitute(expand('%p'),"^.\\+[\\.]","","g")
"   if ext ==# "ts"
"     finish
"   endif
" augroup END

if has('vim_starting')
  augroup EasyCompleteStart
    autocmd!
    autocmd BufReadPost * call easycomplete#Enable()
  augroup END
else
  call easycomplete#Enable()
endif

" Buildin Plugins
augroup easycomplete#register

  au User easycomplete_plugin call easycomplete#RegisterSource({
      \ 'name': 'buf',
      \ 'whitelist': ['*'],
      \ 'completor': 'easycomplete#sources#buf#completor',
      \ })

  au User easycomplete_plugin call easycomplete#RegisterSource({
      \ 'name': 'ts',
      \ 'whitelist': ['javascript','typescript','javascript.jsx','typescript.tsx'],
      \ 'completor': function('easycomplete#sources#ts#completor'),
      \ 'constructor' :function('easycomplete#sources#ts#constructor'),
      \ 'gotodefinition': function('easycomplete#sources#ts#GotoDefinition'),
      \ 'command': 'tsserver'
      \  })

  au User easycomplete_plugin call easycomplete#RegisterSource({
      \ 'name': 'vim',
      \ 'whitelist': ['vim'],
      \ 'completor': 'easycomplete#sources#vim#completor',
      \ 'constructor' :'easycomplete#sources#vim#constructor',
      \ 'gotodefinition': 'easycomplete#sources#vim#GotoDefinition',
      \ 'command': 'vim-language-server',
      \ 'semantic_triggers':["\\W\\(w\\|t\\|a\\|b\\|v\\|s\\|g\\):$"]
      \  })
      " \ 'trigger' : 'always'

  au User easycomplete_plugin call easycomplete#RegisterSource({
      \ 'name': 'cpp',
      \ 'whitelist': ['c', 'cpp', 'objc', 'objcpp', 'cc'],
      \ 'completor': 'easycomplete#sources#cpp#completor',
      \ 'constructor' :'easycomplete#sources#cpp#constructor',
      \ 'gotodefinition': 'easycomplete#sources#cpp#GotoDefinition',
      \ 'command': 'ccls',
      \ 'semantic_triggers':["->$", "::$"]
      \  })

  " TODO not ready
  au User easycomplete_plugin call easycomplete#RegisterSource({
      \ 'name': 'css',
      \ 'whitelist': ['css', 'less', 'sass', 'scss'],
      \ 'completor': 'easycomplete#sources#css#completor',
      \ 'constructor' :'easycomplete#sources#css#constructor',
      \ 'gotodefinition': 'easycomplete#sources#css#GotoDefinition',
      \ 'command': 'css-languageserver',
      \ 'semantic_triggers':[":$"]
      \  })

  " easycompelte#lsp
  au User easycomplete_plugin call easycomplete#RegisterSource({
      \ 'name': 'py',
      \ 'whitelist': ['py','python'],
      \ 'completor': 'easycomplete#sources#py#completor',
      \ 'constructor' :'easycomplete#sources#py#constructor',
      \ 'gotodefinition': 'easycomplete#sources#py#GotoDefinition',
      \ 'command': 'pyls'
      \  })

  au User easycomplete_plugin call easycomplete#RegisterSource({
      \ 'name': 'go',
      \ 'whitelist': ['go'],
      \ 'completor': 'easycomplete#sources#go#completor',
      \ 'constructor' :'easycomplete#sources#go#constructor',
      \ 'gotodefinition': 'easycomplete#sources#go#GotoDefinition',
      \ 'command': 'gopls'
      \  })

  au User easycomplete_plugin call easycomplete#RegisterSource({
      \ 'name': 'directory',
      \ 'whitelist': ['*'],
      \ 'completor': function('easycomplete#sources#directory#completor'),
      \  })

  au User easycomplete_plugin call easycomplete#RegisterSource({
      \ 'name': 'snips',
      \ 'whitelist': ['*'],
      \ 'completor': 'easycomplete#sources#snips#completor',
      \  })

augroup END
