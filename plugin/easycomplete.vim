" File:         easycomplete.vim
" Author:       @jayli <https://github.com/jayli/>
"               更多信息请访问 <https://github.com/jayli/vim-easycomplete>
"               帮助信息请执行
"                :helptags ~/.vim/doc
"                :h EasyComplete

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
augroup EasyCompleteRegistSources
  call easycomplete#RegisterSource({
      \ 'name': 'buf',
      \ 'whitelist': ['*'],
      \ 'completor': 'easycomplete#sources#buf#completor',
      \ })

  call easycomplete#RegisterSource(easycomplete#sources#ts#getConfig({
      \ 'name': 'ts',
      \ 'whitelist': ['javascript','typescript','javascript.jsx'],
      \ 'completor': function('easycomplete#sources#ts#completor'),
      \ 'constructor' :function('easycomplete#sources#ts#constructor'),
      \ 'gotodefinition': function('easycomplete#sources#ts#GotoDefinition')
      \  }))

  call easycomplete#RegisterSource({
      \ 'name': 'py',
      \ 'whitelist': ['py','python'],
      \ 'completor': 'easycomplete#sources#py#completor',
      \ 'constructor' :'easycomplete#sources#py#constructor'
      \  })

  call easycomplete#RegisterSource({
      \ 'name': 'go',
      \ 'whitelist': ['go'],
      \ 'completor': 'easycomplete#sources#go#completor',
      \ 'constructor' :'easycomplete#sources#go#constructor'
      \  })

  call easycomplete#RegisterSource({
      \ 'name': 'directory',
      \ 'whitelist': ['*'],
      \ 'completor': function('easycomplete#sources#directory#completor'),
      \  })

  call easycomplete#RegisterSource({
      \ 'name': 'snips',
      \ 'whitelist': ['*'],
      \ 'completor': 'easycomplete#sources#snips#completor',
      \  })
augroup END
