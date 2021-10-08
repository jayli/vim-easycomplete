" File:         easycomplete.vim
" Author:       @jayli <https://github.com/jayli/>
"               更多信息请访问 <https://github.com/jayli/vim-easycomplete>
"               帮助信息请执行
"                :helptags ~/.vim/doc
"                :h EasyComplete

if get(g:, 'easycomplete_default_plugin_init')
  finish
endif
let g:easycomplete_default_plugin_init = 1

let g:env_is_vim = has('nvim') ? v:false : v:true
let g:env_is_nvim = has('nvim') ? v:true : v:false
let g:env_is_gui = has("gui_running") ? v:true : v:false
let g:env_is_cterm = has("gui_running") ? v:false : v:true
let g:easycomplete_config = {}

" VIM 最低版本 8.2
" Neo 最低版本 0.4.0
" TODO：不支持 Windows，Gvim 中未完整测试
if (g:env_is_vim && v:version < 802) ||
      \ (g:env_is_nvim && !has('nvim-0.4.0')) ||
      \ (has('win32') || has('win64'))
  echom "EasyComplete requires vim version upper than 802".
        \ " or nvim version upper than 0.4.0"
  finish
endif

if has('vim_starting')
  augroup EasyCompleteStart
    autocmd!
    autocmd BufReadPost,BufNewFile * call easycomplete#Enable()
  augroup END
else
  call easycomplete#Enable()
endif

" Buildin Plugins
augroup easycomplete#register

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'directory',
      \ 'whitelist': ['*'],
      \ 'completor': function('easycomplete#sources#directory#completor'),
      \  })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'buf',
      \ 'whitelist': ['*'],
      \ 'completor': 'easycomplete#sources#buf#completor',
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'ts',
      \ 'whitelist': ['javascript','typescript','javascript.jsx','typescript.tsx', 'javascriptreact', 'typescriptreact'],
      \ 'completor': function('easycomplete#sources#ts#completor'),
      \ 'constructor' :function('easycomplete#sources#ts#constructor'),
      \ 'gotodefinition': function('easycomplete#sources#ts#GotoDefinition'),
      \ 'command': 'tsserver'
      \  })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'vim',
      \ 'whitelist': ['vim'],
      \ 'completor': 'easycomplete#sources#vim#completor',
      \ 'constructor' :'easycomplete#sources#vim#constructor',
      \ 'gotodefinition': 'easycomplete#sources#vim#GotoDefinition',
      \ 'command': 'vim-language-server',
      \ 'semantic_triggers':[
      \                      "\\W\\(w\\|t\\|a\\|b\\|v\\|s\\|g\\):$",
      \                      "^\\(w\\|t\\|a\\|b\\|v\\|s\\|g\\):$",
      \  ]
      \  })
      " \ 'trigger' : 'always'

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'cpp',
      \ 'whitelist': ["c", "cc", "cpp", "c++", "objc", "objcpp"],
      \ 'completor': 'easycomplete#sources#cpp#completor',
      \ 'constructor' :'easycomplete#sources#cpp#constructor',
      \ 'gotodefinition': 'easycomplete#sources#cpp#GotoDefinition',
      \ 'command': 'ccls',
      \ 'semantic_triggers':["[^->]->$", "[^:]::$"]
      \  })

  " css-languageserver 默认不带 completionProvider，必须要安装
  " snippets-supports
  " https://github.com/neovim/nvim-lspconfig/wiki/Snippets-support
  " 用户自行安装
  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'css',
      \ 'whitelist': ['css', 'less', 'sass', 'scss'],
      \ 'completor': 'easycomplete#sources#css#completor',
      \ 'constructor' :'easycomplete#sources#css#constructor',
      \ 'gotodefinition': 'easycomplete#sources#css#gotodefinition',
      \ 'command': 'css-languageserver',
      \ 'semantic_triggers':['[^:]:$']
      \  })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'html',
      \ 'whitelist': ['html'],
      \ 'completor': 'easycomplete#sources#html#completor',
      \ 'constructor' :'easycomplete#sources#html#constructor',
      \ 'gotodefinition': 'easycomplete#sources#html#gotodefinition',
      \ 'command': 'html-languageserver',
      \ 'semantic_triggers':['[^<]<$']
      \  })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'yml',
      \ 'whitelist': ['yaml'],
      \ 'completor': 'easycomplete#sources#yaml#completor',
      \ 'constructor' :'easycomplete#sources#yaml#constructor',
      \ 'gotodefinition': 'easycomplete#sources#yaml#gotodefinition',
      \ 'command': 'yaml-language-server',
      \  })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'sh',
      \ 'whitelist': ['sh'],
      \ 'completor': 'easycomplete#sources#bash#completor',
      \ 'constructor' :'easycomplete#sources#bash#constructor',
      \ 'gotodefinition': 'easycomplete#sources#bash#gotodefinition',
      \ 'command': 'bash-language-server',
      \  })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'json',
      \ 'whitelist': ['json'],
      \ 'completor': 'easycomplete#sources#json#completor',
      \ 'constructor' :'easycomplete#sources#json#constructor',
      \ 'gotodefinition': 'easycomplete#sources#json#gotodefinition',
      \ 'command': 'json-languageserver',
      \ 'semantic_triggers':['[^:]:$', '\(^"\|[^"]"\)$']
      \  })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'py',
      \ 'whitelist': ['py','python'],
      \ 'completor': 'easycomplete#sources#py#completor',
      \ 'constructor' :'easycomplete#sources#py#constructor',
      \ 'gotodefinition': 'easycomplete#sources#py#GotoDefinition',
      \ 'command': 'pyls'
      \  })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'java',
      \ 'whitelist': ['java'],
      \ 'completor': 'easycomplete#sources#java#completor',
      \ 'constructor' :'easycomplete#sources#java#constructor',
      \ 'gotodefinition': 'easycomplete#sources#java#GotoDefinition',
      \ 'command': 'eclipse-jdt-ls'
      \  })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'go',
      \ 'whitelist': ['go'],
      \ 'completor': 'easycomplete#sources#go#completor',
      \ 'constructor' :'easycomplete#sources#go#constructor',
      \ 'gotodefinition': 'easycomplete#sources#go#GotoDefinition',
      \ 'command': 'gopls'
      \  })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'nim',
      \ 'whitelist': ['nim'],
      \ 'completor': 'easycomplete#sources#nim#completor',
      \ 'constructor' :'easycomplete#sources#nim#constructor',
      \ 'gotodefinition': 'easycomplete#sources#nim#GotoDefinition',
      \ 'command': 'nimlsp'
      \  })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'grvy',
      \ 'whitelist': ['groovy'],
      \ 'completor': 'easycomplete#sources#grvy#completor',
      \ 'constructor' :'easycomplete#sources#grvy#constructor',
      \ 'gotodefinition': 'easycomplete#sources#grvy#GotoDefinition',
      \ 'command': 'groovy-language-server'
      \  })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'lua',
      \ 'whitelist': ['lua'],
      \ 'completor': 'easycomplete#sources#lua#completor',
      \ 'constructor' :'easycomplete#sources#lua#constructor',
      \ 'gotodefinition': 'easycomplete#sources#lua#GotoDefinition',
      \ 'command': 'emmylua-ls',
      \ 'semantic_triggers':['[0-9a-zA-Z]:$']
      \  })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'rb',
      \ 'whitelist': ['ruby'],
      \ 'completor': 'easycomplete#sources#ruby#completor',
      \ 'constructor' :'easycomplete#sources#ruby#constructor',
      \ 'gotodefinition': 'easycomplete#sources#ruby#GotoDefinition',
      \ 'command': 'solargraph'
      \  })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'kt',
      \ 'whitelist': ['kotlin'],
      \ 'completor': 'easycomplete#sources#kotlin#completor',
      \ 'constructor' :'easycomplete#sources#kotlin#constructor',
      \ 'gotodefinition': 'easycomplete#sources#kotlin#GotoDefinition',
      \ 'command': 'kotlin-language-server'
      \  })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'rust',
      \ 'whitelist': ['rust'],
      \ 'completor': 'easycomplete#sources#rust#completor',
      \ 'constructor' :'easycomplete#sources#rust#constructor',
      \ 'gotodefinition': 'easycomplete#sources#rust#GotoDefinition',
      \ 'command': 'rust-analyzer',
      \ 'semantic_triggers':["::$"]
      \  })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'xml',
      \ 'whitelist': ['xml'],
      \ 'completor': 'easycomplete#sources#xml#completor',
      \ 'constructor' :'easycomplete#sources#xml#constructor',
      \ 'gotodefinition': 'easycomplete#sources#xml#GotoDefinition',
      \ 'command': 'lemminx',
      \ 'semantic_triggers':['[0-9a-zA-Z]:$']
      \  })

  " TODO cmake-languageserver 本身有 bug，等其更新
  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'cmake',
      \ 'whitelist': ['cmake','make'],
      \ 'completor': 'easycomplete#sources#cmake#completor',
      \ 'constructor' :'easycomplete#sources#cmake#constructor',
      \ 'gotodefinition': 'easycomplete#sources#cmake#GotoDefinition',
      \ 'command': 'cmake-language-server'
      \  })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'snips',
      \ 'whitelist': ['*'],
      \ 'completor': 'easycomplete#sources#snips#completor',
      \  })

augroup END
