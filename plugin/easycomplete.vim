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

if !exists("g:easycomplete_nerd_font")
  let g:easycomplete_nerd_font = 0
endif

if !exists("g:easycomplete_kind_icons")
  let g:easycomplete_kind_icons = {}
endif
let kind_icons = g:easycomplete_kind_icons

if g:easycomplete_nerd_font == 1
  let g:easycomplete_menu_skin = {
        \   "buf": {
        \      "kind":get(kind_icons, "buf", ""),
        \      "menu":"Text",
        \    },
        \   "snip": {
        \      "kind":get(kind_icons, "snip", ""),
        \      "menu":"Code"
        \    },
        \   "dict": {
        \      "kind":get(kind_icons, "dict", "󰈍"),
        \      "menu":"Dict",
        \    },
        \   "tabnine": {
        \      "kind":get(kind_icons, "tabnine", "󰕃"),
        \      "menu":"𝘛𝘕"
        \    }
        \ }
  let g:easycomplete_sign_text = {
        \   'error':       "",
        \   'warning':     "",
        \   'information': '',
        \   'hint':        ''
        \ }
  let g:easycomplete_lsp_type_font = {
        \ 'class':     get(kind_icons, "class", ""),     'color':         get(kind_icons, "color", ""),
        \ 'constant':  get(kind_icons, "constant", ""),  'constructor':   get(kind_icons, "constructor", ""),
        \ 'enum':      get(kind_icons, "enum", ""),      'enummember':    get(kind_icons, "enummember", ""),
        \ 'field':     get(kind_icons, "field", ""),     'file':          get(kind_icons, "file", ''),
        \ 'folder':    get(kind_icons, "folder", ""),    'function':      get(kind_icons, "function", "󰊕"),
        \ 'interface': get(kind_icons, "interface", ""), 'keyword':       get(kind_icons, "keyword", ""),
        \ 'snippet':   get(kind_icons, "snippet", ""),   'struct':        get(kind_icons, "struct", "󰙅"),
        \ 'text':      get(kind_icons, "text", ""),      'typeparameter': get(kind_icons, "typeparameter", "§"),
        \ 'variable':  get(kind_icons, "variable", ""),  'module':        get(kind_icons, "module", ''),
        \ 'event':     get(kind_icons, "event", ''),     'var':           get(kind_icons, "var", ""),
        \ 'const':     get(kind_icons, "const", ""),     'alias':         get(kind_icons, 'alias', ""),
        \ 'let':       get(kind_icons, "let", ""),       'parameter':     get(kind_icons, 'parameter', "󰏗"),
        \ 'operator':  get(kind_icons, 'operator', "󱧕"),  'property':      get(kind_icons, 'property', "󰙅"),
        \ 'local':     get(kind_icons, 'local', ""),
        \ 'r':'',     't':'',
        \ 'f':'f',     'c':'',
        \ 'u':'𝘶',     'e':'𝘦',
        \ 's':'󰙅',     'v':'',
        \ 'i':'𝘪',     'm':'',
        \ 'p':'𝘱',     'k':'𝘬',
        \ 'o':"󱧕",     'd':'𝘥',
        \ 'l':"",     'a':"𝘢",
        \ }
endif

if !exists("g:easycomplete_pum_format")
  let g:easycomplete_pum_format = ["kind", "abbr", "menu"]
endif

if !exists("g:easycomplete_menu_skin")
  let g:easycomplete_menu_skin = {}
endif

let g:easycomplete_menuflag_buf = empty(    easycomplete#util#get(g:easycomplete_menu_skin, "buf", "menu")) ?
                                  \ "[B]" : easycomplete#util#get(g:easycomplete_menu_skin, "buf", "menu")
let g:easycomplete_kindflag_buf = empty(    easycomplete#util#get(g:easycomplete_menu_skin, "buf", "kind")) ?
                                  \ ""    : easycomplete#util#get(g:easycomplete_menu_skin, "buf", "kind")
let g:easycomplete_menuflag_dict = empty(   easycomplete#util#get(g:easycomplete_menu_skin, "dict", "menu")) ?
                                  \ "[D]" : easycomplete#util#get(g:easycomplete_menu_skin, "dict", "menu")
let g:easycomplete_kindflag_dict = empty(   easycomplete#util#get(g:easycomplete_menu_skin, "dict", "kind")) ?
                                  \ "" :    easycomplete#util#get(g:easycomplete_menu_skin, "dict", "kind")
let g:easycomplete_menuflag_snip = empty(   easycomplete#util#get(g:easycomplete_menu_skin, "snip", "menu")) ?
                                  \ "[S]" : easycomplete#util#get(g:easycomplete_menu_skin, "snip", "menu")
let g:easycomplete_kindflag_snip = empty(   easycomplete#util#get(g:easycomplete_menu_skin, "snip", "kind")) ?
                                  \ "s" :   easycomplete#util#get(g:easycomplete_menu_skin, "snip", "kind")
let g:easycomplete_menuflag_tabnine = empty(easycomplete#util#get(g:easycomplete_menu_skin, "tabnine", "menu")) ?
                                  \ "[TN]": easycomplete#util#get(g:easycomplete_menu_skin, "tabnine", "menu")
let g:easycomplete_kindflag_tabnine = empty(easycomplete#util#get(g:easycomplete_menu_skin, "tabnine", "kind")) ?
                                  \ "" :    easycomplete#util#get(g:easycomplete_menu_skin, "tabnine", "kind")

if !exists("g:easycomplete_fuzzymatch_hlgroup")
  let g:easycomplete_fuzzymatch_hlgroup = ""
endif
if !exists("g:easycomplete_tabnine_suggestion")
  let g:easycomplete_tabnine_suggestion = 0
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
if !exists("g:easycomplete_ghost_text")
  let g:easycomplete_ghost_text = 1
endif
if g:env_is_vim
  let g:easycomplete_ghost_text = 0
endif
if !exists("g:easycomplete_winborder")
  let g:easycomplete_winborder = 0
endif
if g:env_is_vim || !has('nvim-0.11.0')
  let g:easycomplete_winborder = 0
endif
if !exists("g:easycomplete_directory_enable")
  let g:easycomplete_directory_enable = 1
endif
if !exists("g:easycomplete_tabnine_config")
  let g:easycomplete_tabnine_config = {}
endif
if !exists("g:easycomplete_snips_enable")
  " 为了防止代码阻塞，在主函数中定义
endif
if !exists("g:easycomplete_filetypes")
  let g:easycomplete_filetypes = {"r": {
        \ "whitelist": []
        \ }}
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
if !exists("g:easycomplete_sign_text")
  let g:easycomplete_sign_text = {}
endif
if !exists("g:easycomplete_cursor_word_hl")
  let g:easycomplete_cursor_word_hl = 0
endif
if !exists("g:easycomplete_colorful")
  let g:easycomplete_colorful= 0
endif
if !exists("g:easycomplete_signature_offset")
  let g:easycomplete_signature_offset = 0
endif
if !exists("g:easycomplete_diagnostics_next")
  let g:easycomplete_diagnostics_next = "<C-n>"
endif
if !exists("g:easycomplete_diagnostics_prev")
  let g:easycomplete_diagnostics_prev= "<S-C-n>"
endif
if !exists("g:easycomplete_diagnostics_enable")
  let g:easycomplete_diagnostics_enable = 1
endif
if !exists("g:easycomplete_signature_enable")
  let g:easycomplete_signature_enable = 1
endif
if !exists("g:easycomplete_diagnostics_hover")
  let g:easycomplete_diagnostics_hover = 1
endif
if !exists("g:easycomplete_pum_maxheight")
  let g:easycomplete_pum_maxheight = 20
endif

let g:easycomplete_config = {
      \ 'g:easycomplete_diagnostics_hover':  g:easycomplete_diagnostics_hover,
      \ 'g:easycomplete_signature_enable':   g:easycomplete_signature_enable,
      \ 'g:easycomplete_diagnostics_enable': g:easycomplete_diagnostics_enable,
      \ 'g:easycomplete_tabnine_enable':     g:easycomplete_tabnine_enable,
      \ 'g:easycomplete_tabnine_suggestion': g:easycomplete_tabnine_suggestion,
      \ 'g:easycomplete_enable':             g:easycomplete_enable,
      \ 'g:easycomplete_lsp_checking':       g:easycomplete_lsp_checking,
      \ 'g:easycomplete_menuflag_buf':       g:easycomplete_menuflag_buf,
      \ 'g:easycomplete_kindflag_buf':       g:easycomplete_kindflag_buf,
      \ 'g:easycomplete_menuflag_dict':      g:easycomplete_menuflag_dict,
      \ 'g:easycomplete_kindflag_dict':      g:easycomplete_kindflag_dict,
      \ 'g:easycomplete_menuflag_snip':      g:easycomplete_menuflag_snip,
      \ 'g:easycomplete_kindflag_snip':      g:easycomplete_kindflag_snip,
      \ 'g:easycomplete_kindflag_tabnine':   g:easycomplete_kindflag_tabnine,
      \ 'g:easycomplete_menuflag_tabnine':   g:easycomplete_menuflag_tabnine,
      \ 'g:easycomplete_lsp_type_font':      g:easycomplete_lsp_type_font,
      \ 'g:easycomplete_tabnine_config':     g:easycomplete_tabnine_config,
      \ 'g:easycomplete_ghost_text':         g:easycomplete_ghost_text,
      \ 'g:easycomplete_cursor_word_hl':     g:easycomplete_cursor_word_hl,
      \ 'g:easycomplete_signature_offset':   g:easycomplete_signature_offset,
      \ 'g:easycomplete_directory_enable':   g:easycomplete_directory_enable,
      \ 'g:easycomplete_winborder':          g:easycomplete_winborder,
      \ 'g:easycomplete_pum_maxheight':      g:easycomplete_pum_maxheight
      \ }

" VIM 最低版本 8.2
" Neo 最低版本 0.4.0
" TODO：不支持 Windows，Gvim 中未完整测试
if (g:env_is_vim && v:version < 802) || (g:env_is_nvim && !has('nvim-0.4.0'))
  echom "EasyComplete requires vim version upper than 802".
        \ " or nvim version upper than 0.4.0"
  finish
endif

if has('win32') || has('win64')
  echom "EasyComplete does not support windows."
  finish
endif

if has('vim_starting')
  augroup EasyCompleteStart
    autocmd!
    autocmd BufReadPost,BufNewFile * call easycomplete#Enable()
    autocmd QuitPre * call easycomplete#action#reference#CloseQF()
  augroup END
  if g:easycomplete_cursor_word_hl
    augroup EasyCompleteCursorWordHL
      autocmd!
      autocmd! CursorHold * call easycomplete#ui#HighlightWordUnderCursor()
    augroup END
  endif
else
  call easycomplete#Enable()
endif

augroup easycomplete#CustomAutocmd
  autocmd!
  autocmd User easycomplete_default_plugin silent
  autocmd User easycomplete_custom_plugin silent
  autocmd User easycomplete_after_constructor silent
augroup END

if g:env_is_nvim && has("nvim-0.5.0")
  autocmd User easycomplete_after_constructor lua require('easycomplete').init()
endif

" Buildin Plugins
augroup easycomplete#PluginRegister

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'directory',
      \ 'whitelist': ['*'],
      \ 'completor': function('easycomplete#sources#directory#completor'),
      \  })

  if g:easycomplete_tabnine_enable
    au User easycomplete_default_plugin call easycomplete#RegisterSource({
          \ 'name': 'tn',
          \ 'whitelist': ['*'],
          \ 'completor': function('easycomplete#sources#tn#completor'),
          \ 'constructor': function('easycomplete#sources#tn#constructor'),
          \ 'command': 'TabNine',
          \ })
  endif

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
      \ 'whitelist': easycomplete#FileTypes("dart", ["dart"]),
      \ 'completor': function('easycomplete#sources#dart#completor'),
      \ 'constructor' :function('easycomplete#sources#dart#constructor'),
      \ 'gotodefinition': function('easycomplete#sources#dart#GotoDefinition'),
      \ 'command': 'analysis-server-dart-snapshot'
      \  })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'vim',
      \ 'whitelist': easycomplete#FileTypes("vim", ["vim","vimrc","nvim"]),
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
      \ 'whitelist': easycomplete#FileTypes("cpp", ["c", "cc", "cpp", "c++", "objc", "objcpp", "hpp"]),
      \ 'completor': 'easycomplete#sources#cpp#completor',
      \ 'constructor' :'easycomplete#sources#cpp#constructor',
      \ 'gotodefinition': 'easycomplete#sources#cpp#GotoDefinition',
      \ 'command': 'clangd',
      \ "root_uri_patterns": [
      \    "compile_flags.txt", "compile_commands.json"
      \ ],
      \ 'semantic_triggers':["[^->]->$", "[^:]::$"]
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'php',
      \ 'whitelist': easycomplete#FileTypes("php", ["php"]),
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
      \ 'whitelist': easycomplete#FileTypes("css", ['css', 'less', 'sass', 'scss']),
      \ 'completor': 'easycomplete#sources#css#completor',
      \ 'constructor' :'easycomplete#sources#css#constructor',
      \ 'gotodefinition': 'easycomplete#sources#css#GotoDefinition',
      \ 'command': 'css-languageserver',
      \ 'semantic_triggers':['[^:]:$']
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'html',
      \ 'whitelist': easycomplete#FileTypes("html", ["html", "htm", "xhtml"]),
      \ 'completor': 'easycomplete#sources#html#completor',
      \ 'constructor' :'easycomplete#sources#html#constructor',
      \ 'gotodefinition': 'easycomplete#sources#html#GotoDefinition',
      \ 'command': 'html-languageserver',
      \ 'semantic_triggers':['[^<]<$']
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'yml',
      \ 'whitelist': easycomplete#FileTypes("yml", ["yaml", "yml"]),
      \ 'completor': 'easycomplete#sources#yaml#completor',
      \ 'constructor' :'easycomplete#sources#yaml#constructor',
      \ 'gotodefinition': 'easycomplete#sources#yaml#GotoDefinition',
      \ 'command': 'yaml-language-server',
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'sh',
      \ 'whitelist': easycomplete#FileTypes("sh", ["sh"]),
      \ 'completor': 'easycomplete#sources#bash#completor',
      \ 'constructor' :'easycomplete#sources#bash#constructor',
      \ 'gotodefinition': 'easycomplete#sources#bash#GotoDefinition',
      \ 'command': 'bash-language-server',
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'json',
      \ 'whitelist': easycomplete#FileTypes("json", ['json','jsonc']),
      \ 'completor': 'easycomplete#sources#json#completor',
      \ 'constructor' :'easycomplete#sources#json#constructor',
      \ 'gotodefinition': 'easycomplete#sources#json#GotoDefinition',
      \ 'command': 'json-languageserver',
      \ 'semantic_triggers':['[^:]:$', '\(^"\|[^"]"\)$']
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'py',
      \ 'whitelist': easycomplete#FileTypes("py", ["py","python","pyi"]),
      \ 'completor': 'easycomplete#sources#py#completor',
      \ 'constructor' :'easycomplete#sources#py#constructor',
      \ 'gotodefinition': 'easycomplete#sources#py#GotoDefinition',
      \ 'command': 'pylsp'
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'java',
      \ 'whitelist': easycomplete#FileTypes("java", ["java"]),
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
      \ 'whitelist': easycomplete#FileTypes("go", ["go"]),
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
      \ 'whitelist': easycomplete#FileTypes("nim", ["nim"]),
      \ 'completor': 'easycomplete#sources#nim#completor',
      \ 'constructor' :'easycomplete#sources#nim#constructor',
      \ 'gotodefinition': 'easycomplete#sources#nim#GotoDefinition',
      \ 'command': 'nimlsp'
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'grvy',
      \ 'whitelist': easycomplete#FileTypes("grvy", ["groovy"]),
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
      \ 'whitelist': easycomplete#FileTypes("lua", ["lua"]),
      \ 'completor': 'easycomplete#sources#lua#completor',
      \ 'constructor' :'easycomplete#sources#lua#constructor',
      \ 'gotodefinition': 'easycomplete#sources#lua#GotoDefinition',
      \ 'command': 'sumneko-lua-language-server',
      \ 'semantic_triggers':['[0-9a-zA-Z]:$']
      \ })
      " \ 'command': 'emmylua-ls',
  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'rb',
      \ 'whitelist': easycomplete#FileTypes("rb", ["ruby"]),
      \ 'completor': 'easycomplete#sources#ruby#completor',
      \ 'constructor' :'easycomplete#sources#ruby#constructor',
      \ 'gotodefinition': 'easycomplete#sources#ruby#GotoDefinition',
      \ 'command': 'solargraph'
      \ })
  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'kt',
      \ 'whitelist': easycomplete#FileTypes("kt", ["kotlin"]),
      \ 'completor': 'easycomplete#sources#kotlin#completor',
      \ 'constructor' :'easycomplete#sources#kotlin#constructor',
      \ 'gotodefinition': 'easycomplete#sources#kotlin#GotoDefinition',
      \ 'command': 'kotlin-language-server'
      \  })
  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'rust',
      \ 'whitelist': easycomplete#FileTypes("rust", ["rust"]),
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
      \ 'whitelist': easycomplete#FileTypes("xml", ["xml"]),
      \ 'completor': 'easycomplete#sources#xml#completor',
      \ 'constructor' :'easycomplete#sources#xml#constructor',
      \ 'gotodefinition': 'easycomplete#sources#xml#GotoDefinition',
      \ 'command': 'lemminx',
      \ 'semantic_triggers':['[0-9a-zA-Z]:$']
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'c#',
      \ 'whitelist': easycomplete#FileTypes("c#", ["cs"]),
      \ 'completor': 'easycomplete#sources#cs#completor',
      \ 'constructor' :'easycomplete#sources#cs#constructor',
      \ 'gotodefinition': 'easycomplete#sources#cs#GotoDefinition',
      \ 'command': 'omnisharp-lsp',
      \ 'semantic_triggers':[]
      \ })

  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'r',
      \ 'whitelist': easycomplete#FileTypes("r", ['r', 'rmd', 'rmarkdown']),
      \ 'completor': 'easycomplete#sources#r#completor',
      \ 'constructor' :'easycomplete#sources#r#constructor',
      \ 'gotodefinition': 'easycomplete#sources#r#GotoDefinition',
      \ 'command': 'r-languageserver',
      \ 'semantic_triggers':[]
      \ })

  " TODO cmake-languageserver 本身有 bug，等其更新
  au User easycomplete_default_plugin call easycomplete#RegisterSource({
      \ 'name': 'cmake',
      \ 'whitelist': easycomplete#FileTypes("cmake", ['cmake', 'make','mak', 'CMakeLists.txt']),
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
  autocmd TextChangedI * call easycomplete#TextChangedI()
  autocmd TextChanged * call easycomplete#Textchanged()
  autocmd InsertEnter * call easycomplete#InsertEnter()
  autocmd ExitPre * call easycomplete#finish()
  " SecondComplete Entry
  autocmd CompleteChanged * noa call easycomplete#CompleteChanged()
  autocmd TextChangedP * noa call easycomplete#TextChangedP()
  autocmd InsertCharPre * call easycomplete#InsertCharPre()
  autocmd CompleteDone * call easycomplete#CompleteDone()
  autocmd InsertLeave * call easycomplete#InsertLeave()
  autocmd CursorHold * call easycomplete#CursorHold()
  autocmd CursorHoldI * call easycomplete#CursorHoldI()
  autocmd CursorMovedI * call easycomplete#CursorMovedI()
  autocmd CmdlineEnter * noa call easycomplete#CmdlineEnter()
  autocmd CmdlineLeave * noa call easycomplete#CmdlineLeave()
  autocmd BufLeave * noa call easycomplete#BufLeave()
  if has("nvim")
    autocmd WinScrolled * noa call easycomplete#WinScrolled()
    autocmd ColorScheme * noa call easycomplete#ColorScheme()
  endif
  autocmd User easycomplete_pum_show call easycomplete#CompleteShow()
  " 下面自定义事件只在 nvim 下有效
  autocmd User easycomplete_pum_done noa call easycomplete#CompleteDone()
  autocmd User easycomplete_pum_textchanged_p noa call easycomplete#TextChangedP()
  autocmd User easycomplete_pum_completechanged noa call easycomplete#CompleteChanged()
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
command! EasyCompleteReference : call easycomplete#reference()
command! EasyCompleteRename : call easycomplete#rename()
command! EasyCompleteAiCoding : call easycomplete#AiCoding()
command! BackToOriginalBuffer : call easycomplete#BackToOriginalBuffer()

inoremap <expr> <CR> easycomplete#TypeEnterWithPUM()
inoremap <expr> <Up> easycomplete#Up()
inoremap <expr> <Down> easycomplete#Down()
if g:env_is_nvim
  inoremap <expr> <C-N> easycomplete#CtlN()
  inoremap <expr> <C-P> easycomplete#CtlP()
  inoremap <expr> <Left> easycomplete#Left()
  inoremap <expr> <Right> easycomplete#Right()
endif
inoremap <silent><expr> <BS> easycomplete#BackSpace()
inoremap  <Plug>EasycompleteTabTrigger <c-r>=easycomplete#CleverTab()<cr>
inoremap  <Plug>EasycompleteShiftTabTrigger <c-r>=easycomplete#CleverShiftTab()<cr>
inoremap  <silent><Plug>EasycompleteRefresh <C-r>=easycomplete#refresh()<CR>
inoremap  <Plug>EasycompleteNill <C-r>=easycomplete#nill()<CR>
inoremap  <Plug>EasycompleteExpandSnippet  <C-R>=UltiSnips#ExpandSnippet()<cr>
