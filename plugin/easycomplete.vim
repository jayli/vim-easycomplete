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
let g:env_is_iterm = !empty($ITERM_PROFILE) ? v:true : v:false
" Info 这里 g:env_is_gui 在 vim 下计算正确，在 nvim 下计算错误，原因未知
" 用 easycomplete#util#IsGui() 代替
let g:env_is_gui = (has("termguicolors") && &termguicolors == 1) ? v:true : v:false

if !exists("g:easycomplete_menuflag_buf")
  let g:easycomplete_menuflag_buf = "[B]"
endif
if !exists("g:easycomplete_kindflag_buf")
  let g:easycomplete_kindflag_buf = ""
endif
if !exists("g:easycomplete_menuflag_dict")
  let g:easycomplete_menuflag_dict = "[D]"
endif
if !exists("g:easycomplete_menuflag_snip")
  let g:easycomplete_menuflag_snip = "[S]"
endif
if !exists("g:easycomplete_kindflag_snip")
  let g:easycomplete_kindflag_snip = "s"
endif
if !exists("g:easycomplete_kindflag_dict")
  let g:easycomplete_kindflag_dict = ""
endif
if !exists("g:easycomplete_kindflag_tabnine")
  let g:easycomplete_kindflag_tabnine = ""
endif
if !exists("g:easycomplete_lsp_checking")
  let g:easycomplete_lsp_checking = 1
endif
if !exists("g:easycomplete_lsp_type_font")
  let g:easycomplete_lsp_type_font = {}
endif
if !exists("g:easycomplete_tabnine_enable")
  let g:easycomplete_tabnine_enable = 1
endif
if !exists("g:easycomplete_tabnine_config")
  let g:easycomplete_tabnine_config = {}
endif
if !exists("g:easycomplete_enable")
  let g:easycomplete_enable = 1
endif
if !exists("g:easycomplete_tab_trigger")
  let g:easycomplete_tab_trigger = "<Tab>"
endif
if !exists("g:easycomplete_shift_tab_trigger")
  let g:easycomplete_shift_tab_trigger = "<S-Tab>"
endif
let g:easycomplete_config = {
      \ 'g:easycomplete_diagnostics_hover':  1,
      \ 'g:easycomplete_diagnostics_enable': 1,
      \ 'g:easycomplete_signature_enable':   1,
      \ 'g:easycomplete_tabnine_enable':     g:easycomplete_tabnine_enable,
      \ 'g:easycomplete_enable':             g:easycomplete_enable,
      \ 'g:easycomplete_lsp_checking':       g:easycomplete_lsp_checking,
      \ 'g:easycomplete_menuflag_buf':       g:easycomplete_menuflag_buf,
      \ 'g:easycomplete_kindflag_buf':       g:easycomplete_kindflag_buf,
      \ 'g:easycomplete_menuflag_dict':      g:easycomplete_menuflag_dict,
      \ 'g:easycomplete_kindflag_dict':      g:easycomplete_kindflag_dict,
      \ 'g:easycomplete_menuflag_snip':      g:easycomplete_menuflag_snip,
      \ 'g:easycomplete_kindflag_snip':      g:easycomplete_kindflag_snip,
      \ 'g:easycomplete_kindflag_tabnine':   g:easycomplete_kindflag_tabnine,
      \ 'g:easycomplete_lsp_type_font':      g:easycomplete_lsp_type_font,
      \ 'g:easycomplete_tabnine_config':     g:easycomplete_tabnine_config,
      \ }

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

augroup easycomplete#CustomAutocmd
  autocmd!
  autocmd User easycomplete_default_plugin silent
  autocmd User easycomplete_custom_plugin silent
augroup END

" Buildin Plugins
augroup easycomplete#PluginRegister

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'directory',
      \ 'whitelist': ['*'],
      \ 'completor': function('easycomplete#sources#directory#completor'),
      \  })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'tn',
      \ 'whitelist': ['*'],
      \ 'completor': function('easycomplete#sources#tn#completor'),
      \ 'constructor' :function('easycomplete#sources#tn#constructor'),
      \ 'command': 'TabNine',
      \  })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'buf',
      \ 'whitelist': ['*'],
      \ 'completor': 'easycomplete#sources#buf#completor',
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'ts',
      \ 'whitelist': ['javascript','typescript','javascript.jsx','typescript.tsx',
      \               'javascriptreact', 'typescriptreact'],
      \ 'completor': function('easycomplete#sources#ts#completor'),
      \ 'constructor' :function('easycomplete#sources#ts#constructor'),
      \ 'gotodefinition': function('easycomplete#sources#ts#GotoDefinition'),
      \ "root_uri_patterns": [
      \    "package.json", "tsconfig.json"
      \ ],
      \ 'command': 'tsserver'
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'deno',
      \ 'whitelist': ['javascript','typescript','javascript.jsx','typescript.tsx',
      \               'javascriptreact', 'typescriptreact'],
      \ 'completor': 'easycomplete#sources#deno#completor',
      \ 'constructor' : 'easycomplete#sources#deno#constructor',
      \ 'gotodefinition': 'easycomplete#sources#deno#GotoDefinition',
      \ "root_uri_patterns": [
      \    "deno.jsonc", "deno.json"
      \ ],
      \ 'command': 'deno'
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': "dart",
      \ 'whitelist': ['dart'],
      \ 'completor': function('easycomplete#sources#dart#completor'),
      \ 'constructor' :function('easycomplete#sources#dart#constructor'),
      \ 'gotodefinition': function('easycomplete#sources#dart#GotoDefinition'),
      \ 'command': 'analysis-server-dart-snapshot'
      \  })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'vim',
      \ 'whitelist': ['vim'],
      \ 'completor': 'easycomplete#sources#vim#completor',
      \ 'constructor' :'easycomplete#sources#vim#constructor',
      \ 'gotodefinition': 'easycomplete#sources#vim#GotoDefinition',
      \ 'command': 'vim-language-server',
      \ 'semantic_triggers':[
      \      "\\W\\(w\\|t\\|a\\|b\\|v\\|s\\|g\\):$",
      \      "^\\(w\\|t\\|a\\|b\\|v\\|s\\|g\\):$",
      \      "\\w.$"
      \    ]
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'cpp',
      \ 'whitelist': ["c", "cc", "cpp", "c++", "objc", "objcpp"],
      \ 'completor': 'easycomplete#sources#cpp#completor',
      \ 'constructor' :'easycomplete#sources#cpp#constructor',
      \ 'gotodefinition': 'easycomplete#sources#cpp#GotoDefinition',
      \ 'command': 'ccls',
      \ 'semantic_triggers':["[^->]->$", "[^:]::$"]
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'php',
      \ 'whitelist': ["php"],
      \ 'completor': 'easycomplete#sources#php#completor',
      \ 'constructor' :'easycomplete#sources#php#constructor',
      \ 'gotodefinition': 'easycomplete#sources#php#GotoDefinition',
      \ 'command': 'intelephense',
      \ "root_uri_patterns": [
      \    "psalm.xml", "psalm.xml.dist"
      \ ],
      \ 'semantic_triggers':["\\$"]
      \ })

  " css-languageserver 默认不带 completionProvider，必须要安装
  " snippets-supports
  " https://github.com/neovim/nvim-lspconfig/wiki/Snippets-support
  " 用户自行安装
  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'css',
      \ 'whitelist': ['css', 'less', 'sass', 'scss'],
      \ 'completor': 'easycomplete#sources#css#completor',
      \ 'constructor' :'easycomplete#sources#css#constructor',
      \ 'gotodefinition': 'easycomplete#sources#css#GotoDefinition',
      \ 'command': 'css-languageserver',
      \ 'semantic_triggers':['[^:]:$']
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'html',
      \ 'whitelist': ['html'],
      \ 'completor': 'easycomplete#sources#html#completor',
      \ 'constructor' :'easycomplete#sources#html#constructor',
      \ 'gotodefinition': 'easycomplete#sources#html#GotoDefinition',
      \ 'command': 'html-languageserver',
      \ 'semantic_triggers':['[^<]<$']
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'yml',
      \ 'whitelist': ['yaml'],
      \ 'completor': 'easycomplete#sources#yaml#completor',
      \ 'constructor' :'easycomplete#sources#yaml#constructor',
      \ 'gotodefinition': 'easycomplete#sources#yaml#GotoDefinition',
      \ 'command': 'yaml-language-server',
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'sh',
      \ 'whitelist': ['sh'],
      \ 'completor': 'easycomplete#sources#bash#completor',
      \ 'constructor' :'easycomplete#sources#bash#constructor',
      \ 'gotodefinition': 'easycomplete#sources#bash#GotoDefinition',
      \ 'command': 'bash-language-server',
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'json',
      \ 'whitelist': ['json'],
      \ 'completor': 'easycomplete#sources#json#completor',
      \ 'constructor' :'easycomplete#sources#json#constructor',
      \ 'gotodefinition': 'easycomplete#sources#json#GotoDefinition',
      \ 'command': 'json-languageserver',
      \ 'semantic_triggers':['[^:]:$', '\(^"\|[^"]"\)$']
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'py',
      \ 'whitelist': ['py','python'],
      \ 'completor': 'easycomplete#sources#py#completor',
      \ 'constructor' :'easycomplete#sources#py#constructor',
      \ 'gotodefinition': 'easycomplete#sources#py#GotoDefinition',
      \ 'command': 'pyls'
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'java',
      \ 'whitelist': ['java'],
      \ 'completor': 'easycomplete#sources#java#completor',
      \ 'constructor' :'easycomplete#sources#java#constructor',
      \ 'gotodefinition': 'easycomplete#sources#java#GotoDefinition',
      \ "root_uri_patterns": [
      \    "pom.xml", "build.gradle"
      \ ],
      \ 'command': 'eclipse-jdt-ls'
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'go',
      \ 'whitelist': ['go'],
      \ 'completor': 'easycomplete#sources#go#completor',
      \ 'constructor' :'easycomplete#sources#go#constructor',
      \ 'gotodefinition': 'easycomplete#sources#go#GotoDefinition',
      \ "root_uri_patterns": [
      \    "go.mod",
      \ ],
      \ 'command': 'gopls'
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'nim',
      \ 'whitelist': ['nim'],
      \ 'completor': 'easycomplete#sources#nim#completor',
      \ 'constructor' :'easycomplete#sources#nim#constructor',
      \ 'gotodefinition': 'easycomplete#sources#nim#GotoDefinition',
      \ 'command': 'nimlsp'
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'grvy',
      \ 'whitelist': ['groovy'],
      \ 'completor': 'easycomplete#sources#grvy#completor',
      \ 'constructor' :'easycomplete#sources#grvy#constructor',
      \ 'gotodefinition': 'easycomplete#sources#grvy#GotoDefinition',
      \ "root_uri_patterns": [
      \    "build.gradle",
      \ ],
      \ 'command': 'groovy-language-server'
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'lua',
      \ 'whitelist': ['lua'],
      \ 'completor': 'easycomplete#sources#lua#completor',
      \ 'constructor' :'easycomplete#sources#lua#constructor',
      \ 'gotodefinition': 'easycomplete#sources#lua#GotoDefinition',
      \ 'command': 'emmylua-ls',
      \ 'semantic_triggers':['[0-9a-zA-Z]:$']
      \ })
  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'rb',
      \ 'whitelist': ['ruby'],
      \ 'completor': 'easycomplete#sources#ruby#completor',
      \ 'constructor' :'easycomplete#sources#ruby#constructor',
      \ 'gotodefinition': 'easycomplete#sources#ruby#GotoDefinition',
      \ 'command': 'solargraph'
      \ })
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
      \ "root_uri_patterns": [
      \    "Cargo.toml",
      \ ],
      \ 'semantic_triggers':["::$"]
      \ })
  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'xml',
      \ 'whitelist': ['xml'],
      \ 'completor': 'easycomplete#sources#xml#completor',
      \ 'constructor' :'easycomplete#sources#xml#constructor',
      \ 'gotodefinition': 'easycomplete#sources#xml#GotoDefinition',
      \ 'command': 'lemminx',
      \ 'semantic_triggers':['[0-9a-zA-Z]:$']
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'c#',
      \ 'whitelist': ['cs'],
      \ 'completor': 'easycomplete#sources#cs#completor',
      \ 'constructor' :'easycomplete#sources#cs#constructor',
      \ 'gotodefinition': 'easycomplete#sources#cs#GotoDefinition',
      \ 'command': 'omnisharp-lsp',
      \ 'semantic_triggers':[]
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'r',
      \ 'whitelist': ['r'],
      \ 'completor': 'easycomplete#sources#r#completor',
      \ 'constructor' :'easycomplete#sources#r#constructor',
      \ 'gotodefinition': 'easycomplete#sources#r#GotoDefinition',
      \ 'command': 'r-languageserver',
      \ 'semantic_triggers':[]
      \ })

  " TODO cmake-languageserver 本身有 bug，等其更新
  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'cmake',
      \ 'whitelist': ['cmake','make'],
      \ 'completor': 'easycomplete#sources#cmake#completor',
      \ 'constructor' :'easycomplete#sources#cmake#constructor',
      \ 'gotodefinition': 'easycomplete#sources#cmake#GotoDefinition',
      \ 'command': 'cmake-language-server'
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'snips',
      \ 'whitelist': ['*'],
      \ 'completor': 'easycomplete#sources#snips#completor',
      \ })
augroup END

augroup easycomplete#NormalBinding
  autocmd!
  autocmd BufWritePost * call easycomplete#BufWritePost()
  autocmd CursorMoved * call easycomplete#CursorMoved()
  autocmd BufEnter * call easycomplete#BufEnter()
  " FirstComplete Entry
  autocmd TextChangedI * : call easycomplete#TextChangedI()
  autocmd TextChanged * call easycomplete#Textchanged()
  autocmd InsertEnter * call easycomplete#InsertEnter()
  " SecondComplete Entry
  autocmd CompleteChanged * noa call easycomplete#CompleteChanged()
  autocmd TextChangedP * : noa call easycomplete#TextChangedP()
  autocmd InsertCharPre * call easycomplete#InsertCharPre()
  autocmd CompleteDone * call easycomplete#CompleteDone()
  autocmd InsertLeave * call easycomplete#InsertLeave()
  autocmd CursorHold * call easycomplete#CursorHold()
  autocmd CursorMovedI * call easycomplete#CursorMovedI()
  autocmd CmdlineEnter * noa call easycomplete#CmdlineEnter()
  autocmd CmdlineLeave * noa call easycomplete#CmdlineLeave()
augroup END

command! -nargs=? EasyCompleteInstallServer :call easycomplete#installer#install(<q-args>)
command! -nargs=? InstallLspServer :call easycomplete#installer#install(<q-args>)
command! EasyCompleteGotoDefinition :call easycomplete#defination()
command! EasyCompleteCheck :call easycomplete#checking()
command! EasyCompleteLint :call easycomplete#lint()
command! LintEasycomplete :call easycomplete#lint()
command! EasyCompleteSignature :call easycomplete#signature()
command! EasyCompleteProfileStart :call easycomplete#util#ProfileStart()
command! EasyCompleteProfileStop :call easycomplete#util#ProfileStop()
command! EasyCompleteNextDiagnostic : call easycomplete#sign#next()
command! EasyCompletePreviousDiagnostic : call easycomplete#sign#previous()
command! EasyCompleteDisable : call easycomplete#disable()
command! EasyCompleteEnable : call easycomplete#StartUp()

inoremap <expr> <CR> easycomplete#TypeEnterWithPUM()
inoremap <expr> <Up> easycomplete#Up()
inoremap <expr> <Down> easycomplete#Down()
" inoremap <expr> <BS> easycomplete#BackSpace()
inoremap <silent> <Plug>EasycompleteTabTrigger <c-r>=seasycomplete#CleverTab()<cr>
inoremap <silent> <Plug>EasycompleteShiftTabTrigger <c-r>=seasycomplete#CleverShiftTab()<cr>
inoremap <silent> <Plug>EasycompleteRefresh <C-r>=easycomplete#refresh()<CR>
inoremap <silent> <Plug>EasycompleteNill <C-r>=easycomplete#nill()<CR>
inoremap <silent> <Plug>EasycompleteExpandSnippet  <C-R>=UltiSnips#ExpandSnippet()<cr>

