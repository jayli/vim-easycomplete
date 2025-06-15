# Vim-EasyComplete

> [中文](README-cn.md) | [English](README.md)

It's a Fast and Minimalism Style Completion Plugin for vim/nvim. 

![](https://img.shields.io/badge/VimScript-Only-orange.svg?style=flat-square) ![](https://img.shields.io/badge/MacOS-available-brightgreen.svg?style=flat-square) ![](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square) ![](https://img.shields.io/github/workflow/status/jayli/vim-easycomplete/easycomplete.CI?style=flat-square)

## What

Vim-easycomplete is a fast and minimalism style completion plugin for both vim and nvim. It aims to be available out of the box on linux and mac. It is implemented in pure VimScript and is extremely simple to configure without installing Node and a bunch of Node modules. Thank [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) and [coc.nvim](https://github.com/neoclide/coc.nvim). They inspired me a lot.

https://github.com/user-attachments/assets/30c265f3-e65c-47d0-8762-e9e8250d7b4d


It contains these features:

- Full [lsp]([language-server-protocol](https://github.com/microsoft/language-server-protocol)) support. Easy to install LSP Server with one command
- Keywords/Directory support
- Implemented based on pure vimscript
- Snippet support via [Snippets](https://github.com/neovim/nvim-lspconfig/wiki/Snippets).
- Fast performance
- AI coding assistant via [tabnine](#TabNine-Support).

## Installation

Requires Vim 8.2 or higher version on MacOS/Linux/FreeBSD. Neovim 0.6.0 or higher.

Lua config with Packer.nvim:

```lua
use { 'jayli/vim-easycomplete', requires = {'SirVer/ultisnips'}}
-- Tabnine aicoding support, default is 1
-- You should install tabnine first by ":InstallLspServer tabnine"
vim.g.easycomplete_tabnine_enable = 1
-- Tabnine coding suggestion, default is 0
vim.g.easycomplete_tabnine_suggestion = 0
-- Using nerdfont for lsp icons, default is 0
vim.g.easycomplete_nerd_font = 1
-- Add window border for pum, default is 1 (for nvim 0.11 or higher)
vim.g.easycomplete_winborder = 1
-- Pmenu format, default is {"abbr", "kind", "menu"}
vim.g.easycomplete_pum_format = {"kind", "abbr", "menu"}
-- Useful keymap
vim.keymap.set('n', 'gr', ':EasyCompleteReference<CR>')
vim.keymap.set('n', 'gd', ':EasyCompleteGotoDefinition<CR>')
vim.keymap.set('n', 'rn', ':EasyCompleteRename<CR>')
vim.keymap.set('n', 'gb', ':BackToOriginalBuffer<CR>')

```
Run `:PackerInstall`

Vimscript config with vim-plug:

```vim
Plug 'jayli/vim-easycomplete'
Plug 'SirVer/ultisnips'
" Tabnine aicoding support, default is 1
" You should install tabnine first by ":InstallLspServer tabnine"
let g:easycomplete_tabnine_enable = 1
" Tabnine coding suggestion, default is 0
let g:easycomplete_tabnine_suggestion = 0
" Using nerdfont for lsp icons, default is 0
let g:easycomplete_nerd_font = 1
" Add window border for pum, default is 1 (for nvim 0.11 or higher)
let g:easycomplete_winborder = 1
" Pmenu format, default is ["abbr", "kind", "menu"]
let g:easycomplete_pum_format = ["kind", "abbr", "menu"]
" Useful keymap
noremap gr :EasyCompleteReference<CR>
noremap gd :EasyCompleteGotoDefinition<CR>
noremap rn :EasyCompleteRename<CR>
noremap gb :BackToOriginalBuffer<CR>
```
Run `:PlugInstall`.

[Full configuration example](custom-config.md).

## Useage

Use `Tab` to trigger the completion suggestions and select matched items. Use `Ctrl-]` for definition jumping, `Ctrl-t` for jumping back (Same as tags jumping).

Use `Ctrl-N`/`Shift-Ctrl-N` to jump to the next/previous diagnostic position.

Other optional configurations:

- `set updatetime=150` (lua: `vim.opt.updatetime = 150`) is highly recommended.
- Menu noselected by default: `setlocal completeopt+=noselect`, (lua: `vim.cmd('setlocal completeopt+=noselect')`)

## Commands

All commands:

| Command                           | Description                                         |
|-----------------------------------|-----------------------------------------------------|
| `:EasyCompleteInstallServer`      | Install LSP server for current fileytpe             |
| `:InstallLspServer`               | Same as `EasyCompleteInstallServer`                 |
| `:EasyCompleteDisable`            | Disable EasyComplete                                |
| `:EasyCompleteEnable`             | Enable EasyComplete                                 |
| `:EasyCompleteGotoDefinition`     | Goto definition position                            |
| `:EasyCompleteReference`          | Find references                                     |
| `:EasyCompleteRename`             | Rename                                              |
| `:EasyCompleteCheck`              | Checking LSP server                                 |
| `:EasyCompletePreviousDiagnostic` | Goto Previous diagnostic                            |
| `:EasyCompleteNextDiagnostic`     | Goto Next diagnostic                                |
| `:EasyCompleteProfileStart`       | Start record diagnostics message                    |
| `:EasyCompleteProfileStop`        | Stop record diagnostics  message                    |
| `:EasyCompleteLint`               | Do diagnostic                                       |
| `:LintEasyComplete`               | Do diagnostic                                       |
| `:BackToOriginalBuffer`           | Return to the position before the reference jump    |
| `:DenoCache`                      | Do Deno Cache for downloading modules               |
| `:CleanLog`                       | close quickfix window                               |

Global configurations:

| Global Configure                     | Default       | Description                                                   |
|--------------------------------------|---------------|---------------------------------------------------------------|
| `g:easycomplete_nerd_font`           | 0             | Using nerdfont for lsp icons                                  |
| `g:easycomplete_menu_skin`           | `{}`          | Menu skin.                                                    |
| `g:easycomplete_sign_text`           | `{}`          | Sign icons.                                                   |
| `g:easycomplete_lsp_type_font`       | ...           | lsp icons configuration                                       |
| `g:easycomplete_tabnine_suggestion`  | 0             | Tabnine inline suggestion(for nvim only)                      |
| `g:easycomplete_lsp_checking`        | 1             | Check whether the lsp is installed while opening a file       |
| `g:easycomplete_tabnine_enable`      | 1             | Enable Tabnine                                                |
| `g:easycomplete_directory_enable`    | 1             | Directory complete                                            |
| `g:easycomplete_tabnine_config`      | `{}`          | [TabNine Configuration](#ai-coding-via-tabnine-support)       |
| `g:easycomplete_filetypes`           | `{}`          | [Custom filetyps configuration](#language-support)            |
| `g:easycomplete_enable`              | 1             | Enable this plugin                                            |
| `g:easycomplete_tab_trigger`         | `<Tab>`       | Use tab to trigger completion and select next item            |
| `g:easycomplete_shift_tab_trigger`   | `<S-Tab>`     | Use s-tab to select previous item                             |
| `g:easycomplete_cursor_word_hl`      | 0             | Highlight the symbol when holding the cursor                  |
| `g:easycomplete_signature_offset`    | 0             | Signature offset                                              |
| `g:easycomplete_diagnostics_next`    | `<C-N>`       | Goto next diagnostic position                                 |
| `g:easycomplete_diagnostics_prev`    | `<S-C-n>`     | Goto previous diagnostic position                             |
| `g:easycomplete_diagnostics_enable`  | 1             | Enable diagnostics                                            |
| `g:easycomplete_signature_enable`    | 1             | Enable signature                                              |
| `g:easycomplete_diagnostics_hover`   | 1             | Gives a diagnostic prompt when the cursor holds               |
| `g:easycomplete_winborder`           | 1             | Add window border for pum (for nvim 0.11 or higher)           |
| `g:easycomplete_ghost_text`          | 1             | Ghost text                                                    |
| `g:easycomplete_pum_maxheight`       | 20            | Pum window max height                                         |
| `g:easycomplete_pum_format`          | `["abbr", "kind", "menu"]`| Pmenu format                                      |

Typing `:h easycomplete` for help.

## Language Support

There are tow ways to install lsp server.

1. For vim/nvim: use command`:InstallLspServer`.
2. For nvim only: use [nvim-lsp-installer](https://github.com/williamboman/nvim-lsp-installer) by `:LspInstall`

LSP Server will all be installed in local path: `~/.config/vim-easycomplete/servers`.

You can give a specified plugin name for `InstallLspServer` command. Both of the following useage are ok:

- `:InstallLspServer`
- `:InstallLspServer lua`

All supported languages:

| Plugin Name | Languages | Language Server          | Installer          | Requirements | nvim-lsp-installer support|
|-------------|-----------|:------------------------:|:------------------:|:------------:|:-------------------------:|
| directory   | directory | No Need                  | Integrated         | None         | -                         |
| buf         | buf & dict| No Need                  | Integrated         | None         | -                         |
| snips       | Snippets  | ultisnips                | Integrated         | python3      | -                         |
| ts          | js/ts     | tsserver                 | Yes                | node/npm     | Yes                       |
| deno        | js/ts     | denols                   | Yes                | deno         | Yes                       |
| tn          | TabNine   | TabNine                  | Yes                | None         | No                        |
| vim         | Vim       | vimls                    | Yes                | node/npm     | Yes                       |
| cpp         | C/C++/OC  | clangd                   | Yes                | None         | Yes                       |
| css         | CSS       | cssls                    | Yes                | node/npm     | Yes                       |
| html        | HTML      | html                     | Yes                | node/npm     | Yes                       |
| yml         | YAML      | yamlls                   | Yes                | node/npm     | Yes                       |
| xml         | Xml       | lemminx                  | Yes                | java/jdk     | Yes                       |
| sh          | Bash      | bashls                   | Yes                | node/npm     | Yes                       |
| json        | JSON      | json-languageserver      | Yes                | node/npm     | No                        |
| php         | php       | intelephense             | Yes                | node/npm     | Yes                       |
| dart        | dart      | dartls                   | Yes                | None         | Yes                       |
| py          | Python    | pylsp                    | Yes                | python3/pip3 | Yes                       |
| java        | Java      | jdtls                    | Yes                | java11/jdk   | Yes                       |
| go          | Go        | gopls                    | Yes                | go           | Yes                       |
| r           | R         | r-languageserver         | Yes                | R            | No                        |
| rb          | Ruby      | solargraph               | Yes                | ruby/bundle  | No                        |
| lua         | Lua       | `sumneko_lua`            | Yes                | Lua          | Yes                       |
| nim         | Nim       | nimls                    | Yes                | nim/nimble   | Yes                       |
| rust        | Rust      | `rust_analyzer`          | Yes                | None         | Yes                       |
| kt          | Kotlin    | `kotlin_language_server` | Yes                | java/jdk     | Yes                       |
| grvy        | Groovy    | groovyls                 | Yes                | java/jdk     | Yes                       |
| cmake       | cmake     | cmake                    | Yes                | python3/pip3 | Yes                       |
| c#          | C#        | omnisharp-lsp            | Yes                | None         | No                        |

More info about supported language:

- JavaScript & TypeScript: [tsserver](https://github.com/microsoft/TypeScript) required.
- Python: There are 2 avilable python-language-server branches:
    - [pyls](https://github.com/palantir/python-language-server) support python 3.5 ~ 3.10 ([pyls breaks autocomplete on Python 3.11](https://github.com/palantir/python-language-server/issues/959)), `pip3 install python-language-server`
    - [pylsp](https://github.com/python-lsp/python-lsp-server) work well with python 3.11, `pip3 install python-lsp-server`, (Recommend)
- Go: [gopls](https://github.com/golang/tools/tree/master/gopls) required. (`go get golang.org/x/tools/gopls`)
- Vim Script: [vimls](https://github.com/iamcco/vim-language-server) required.
- C++/C/OC：[Clangd](https://github.com/clangd/clangd) required.
- CSS: [cssls](https://github.com/vscode-langservers/vscode-css-languageserver-bin) required. (css-languageserver)，Css-languageserver dose not support CompletionProvider by default as it requires [Snippets](https://github.com/neovim/nvim-lspconfig/wiki/Snippets)，You must install it manually.
- JSON: [json-languageserver](https://github.com/vscode-langservers/vscode-json-languageserver-bin) required.
- PHP: [intelephense](https://www.npmjs.com/package/intelephense)
- Dart: [dartls](https://storage.googleapis.com/dart-archive/)
- HTML: [html](https://github.com/vscode-langservers/vscode-html-languageserver-bin) required. html-languageserver dose not support CompletionProvider by default. You must install [Snippets](https://github.com/neovim/nvim-lspconfig/wiki/Snippets) manually.
- Shell: [bashls](https://github.com/bash-lsp/bash-language-server) required.
- Java: [jdtls](https://github.com/eclipse/eclipse.jdt.ls/), java 11 and upper version required.
- Cmake: [cmake](https://github.com/regen100/cmake-language-server) required.
- Kotlin: [kotlin language server](https://github.com/fwcd/kotlin-language-server) required.
- Rust: [rust-analyzer](https://github.com/rust-analyzer/rust-analyzer) required.
- Lua: [sumneko lua](https://github.com/sumneko/lua-language-server) required. Local configuration file path is `~/.config/vim-easycomplete/servers/lua/config.json`. Get more information [here](https://github.com/xiyaowong/coc-sumneko-lua/blob/main/settings.md).
- Xml: [lemminx](https://github.com/eclipse/lemminx) required.
- Groovy: [groovyls](https://github.com/prominic/groovy-language-server) required.
- Yaml: [yamlls](https://github.com/redhat-developer/yaml-language-server) required.
- Ruby: [solargraph](https://github.com/castwide/solargraph) required.
- Nim: [nimlsp](https://github.com/PMunch/nimlsp) required. [packages.json](https://github.com/nim-lang/packages/blob/master/packages.json) downloading is very slow, You'd better intall minlsp manually via `choosenim` follow [this guide](https://github.com/jayli/vim-easycomplete/issues/155#issuecomment-1041581629).
- Deno: [denols](https://morioh.com/p/84a54d70a7fa) required. Use `:DenoCache` command for `deno cache` current ts/js file.
- C# : [omnisharp](http://www.omnisharp.net/) required.
- R: [r-languageserver](https://github.com/REditorSupport/languageserver) required.
- TabNine: [TabNine](https://www.tabnine.com/)

You can  add filetypes whitelist for specified language plugin. In most cases, it is not necessary to do so:

```vim
let g:easycomplete_filetypes = {
      \   "sh": {
      \     "whitelist": ["shell"]
      \   },
      \   "r": {
      \     "whitelist": ["rmd", "rmarkdown"]
      \   },
      \ }
```

### Snippet Support

Vim-EasyComplete does not integration snippets by default. If you want snippet support, please install `ultisnips`. UltiSnips is compatible with Vim-EasyComplete. UltiSnips required python3 installed.

> [Solution of "E319: No python3 provider found" Error in neovim 0.4.4 with ultisnips](https://github.com/jayli/vim-easycomplete/issues/171)



## AI Coding Suggestions

In addition to associating AI matching words in the complete menu, there are multiple options for AI coding suggestions.

### 1）Tabnine

Vim-easycomplete integrates Tabnine built-in.Install TabNine: `:InstallLspServer tabnine`. Then restart your vim/nvim.

<img src="https://gw.alicdn.com/imgextra/i2/O1CN01Qjk2tV2A20Ss9jtcq_!!6000000008144-0-tps-792-470.jpg" width="500px" />

You can config TabNine by `g:easycomplete_tabnine_config` witch contains two properties:

- *line_limit*: The number of lines before and after the cursor to send to TabNine. If the option is smaller, the performance may be improved. (default: 1000)
- *max_num_result*: Max results from TabNine showing in the complete menu. (default: 3)

```vim
let g:easycomplete_tabnine_config = {
    \ 'line_limit': 1000,
    \ 'max_num_result' : 3,
    \ }
```

TabNine works well without APIKey. If you have a Tabnine's Pro API key or purchased a subscription license. To configure, you'll need to use the [TabNine' magic string](https://www.tabnine.com/faq#special_commands). Type `Tabnine::config` in insert mode to open the configuration panel.

Enable TabNine inline suggestion: `let g:easycomplete_tabnine_suggestion = 1`.

### 2) [deepseek-coder.nvim](https://github.com/jayli/deepseek-coder.nvim/)

Vim-easycomplete is working well with [deepseek-coder.nvim](https://github.com/jayli/deepseek-coder.nvim/).

### 3) Aone-Copilot.nvim

If you are an Alibaba engineer, then Aone-copilot is the best choice. 

---------------------

## Beautify completion menu

Set `g:easycomplete_nerd_font = 1` to enable default nerdfonts configuration.

If you want to customize the kind icon, you can modify the configuration with <https://nerdfonts.com> installed. [Examples](custom-config.md).

You can add custom Pmenu styles by defining these highlight groups:

- `EasyFuzzyMatch`: highlight fuzzy matching character. It links to "Constant" by default if it's not defined.
- `EasyPmenu`: Pmenu style. It links to "Pmenu" by default.
- `EasyPmenuKind`: PmenuKind style. It links to "PmenuKind" by default.
- `EasyPmenuExtra`: PmenuExtra style. It links to "PmenuExtra" by default.
- `EasyFunction`: Function kind icon style. links to "Conditional" by default.
- `EasySnippet`: Snippet kind icon style. links to "Keyword" by default.
- `EasyTabNine`: TabNine kind icon style. links to "Character" by default.
- `EasySnippets`: TabNine snippets suggestion style. links to "LineNr" by default

When `g:easycomplete_winborder` is set to `1`. The guibg of Pmenu will be set to be the same as the Normal guibg.

More examples here: [full config example](custom-config.md)

![截屏2023-12-30 20 25 06](https://github.com/jayli/vim-easycomplete/assets/188244/597db686-d4fe-4b25-8c39-d9b90db184cb)

## Add custom completion plugin

→ [add custom completion plugin](add-custom-plugin.md)

### License

MIT
