# Vim-EasyComplete

> A Fast & Minimalism Style Code Completion Plugin for vim/nvim.

![](https://img.shields.io/badge/VimScript-Only-orange.svg) ![](https://img.shields.io/badge/MacOS-available-brightgreen.svg) ![](https://img.shields.io/badge/license-MIT-blue.svg) ![](https://img.shields.io/github/workflow/status/jayli/vim-easycomplete/easycomplete.CI)

### Why

There are many excellent vim auto-completion plugins such as [nvim-cmp](https://github.com/hrsh7th/nvim-cmp), [vim-lsp](https://github.com/prabirshrestha/vim-lsp), [YouCompleteMe](https://github.com/ycm-core/YouCompleteMe) and [coc.nvim](https://github.com/neoclide/coc.nvim) etc. However I want a more conncise style plugin without any uneccessary configurations. What's more, it would be a good idea to incorporate the capabilities of an AI coding assistant as well.

### What

Vim-easycomplete is a fast and minimalism style completion plugin for vim/nvim. The goal is to work everywhere out of the box with high-speed performance. It requires pure vim script. You don’t need to configure anything uneccessary. Especially, You don’t have to install Node and a bunch of Node modules unless you’re a javascript/typescript programmer.

<img src="https://gw.alicdn.com/imgextra/i2/O1CN01OA1VV41QHbd7Y2WKu_!!6000000001951-1-tps-1209-693.gif" width=650 />

It is easy to install and use. It contains these features:

- AI coding assistant via tabnine(#TabNine-Support). (Highly Recommend!)
- Buffer Keywords/Directory support
- LSP([language-server-protocol](https://github.com/microsoft/language-server-protocol)) support
- Easy to install LSP Server with one command
- Written in pure vim script for vim8 and neovim
- Snippet support with ultisnips.
- Fast performance

The reason I decided to use pure vim script instead of lua or python is that I want a wider range of compatibility. And I made a lot of async handling with vim script to avoid the block of vim.

### Installation

Easycomplete requires Vim 8.2 or higher version with MacOS/Linux/FreeBSD. For neovim users, 0.4.4 or higher is required.

For vim-plug:

```vim
Plug 'jayli/vim-easycomplete'
Plug 'SirVer/ultisnips'
```

Run `:PlugInstall`.

For dein.vim

```vim
call dein#add('jayli/vim-easycomplete')
call dein#add('SirVer/ultisnips')
```

For Packer.nvim

```lua
use { 'jayli/vim-easycomplete' }
use { 'SirVer/ultisnips' }
```

Run `:PackerInstall`

You can use my default configuration [here](my-custom-config.md) with lua.

### All Supported Commands

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

### Configuration

The plugin is out of box and config nothing. (If you want full features, please refer to [my full configuration](https://gist.github.com/jayli/75d9c68cdfd286dd84a85c44cf3f9085))

### Usage

Use Tab to trigger the completion suggestions and select matched items. By default use `Ctrl-]` for definition jumping, `Ctrl-t` for jumping back (Same as tags jumping).

With vim script:

```vim
noremap gr :EasyCompleteReference<CR>
noremap gd :EasyCompleteGotoDefinition<CR>
noremap rn :EasyCompleteRename<CR>
noremap gb :BackToOriginalBuffer<CR>
```

or with lua:

```lua
vim.keymap.set('n', 'gr', ':EasyCompleteReference<CR>')
vim.keymap.set('n', 'gd', ':EasyCompleteGotoDefinition<CR>')
vim.keymap.set('n', 'rn', ':EasyCompleteRename<CR>')
vim.keymap.set('n', 'gb', ':BackToOriginalBuffer<CR>')
```

Set trigger completion mapping:

```vim
let g:easycomplete_tab_trigger="<c-space>"
```

The plugin has already map diagnostic jumping to `<C-n>` and `<S-C-n>`. You can change these mapping via:

```vim
let g:easycomplete_diagnostics_next = "<C-J>"
let g:easycomplete_diagnostics_prev = "<C-k>"
```

- Set `let g:easycomplete_diagnostics_enable = 0` to disable lsp diagnostics.
- Set `let g:easycomplete_lsp_checking = 0` to disable lsp checking for installation.
- Set `let g:easycomplete_signature_enable = 0` to disable lsp signature checking.

Typing `:h easycomplete` for help.

### Language Support

It support keywords/dictionary/directory completion by default.

Disable directory completion via `let g:easycomplete_directory_enable = 0`.

#### Semantic Completion for Other Languages

There are tow ways to install lsp server.

1. For vim/nvim: via integrated installer by `:InstallLspServer`.
2. For nvim only: via [nvim-lsp-installer](https://github.com/williamboman/nvim-lsp-installer) by `:LspInstall`

```vim
Plug 'williamboman/nvim-lsp-installer'
```

LSP Server will all be installed in `~/.config/vim-easycomplete/servers`.

You can give a specified plugin name for `InstallLspServer` command. Both of the following useage are avilable:

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

More info about semantic completion for each supported language:

- JavaScript & TypeScript: [tsserver](https://github.com/microsoft/TypeScript) required.
- Python: [pylsp](https://github.com/palantir/python-language-server) required. (`pip install python-language-server`)
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
- Kotlin: [kotlin_language_server](https://github.com/fwcd/kotlin-language-server) required.
- Rust: [rust-analyzer](https://github.com/rust-analyzer/rust-analyzer) required.
- Lua: [sumneko_lua](https://github.com/sumneko/lua-language-server) required. Local configuration file path is `~/.config/vim-easycomplete/servers/lua/config.json`. Get more information [here](https://github.com/xiyaowong/coc-sumneko-lua/blob/main/settings.md).
- Xml: [lemminx](https://github.com/eclipse/lemminx) required.
- Groovy: [groovyls](https://github.com/prominic/groovy-language-server) required.
- Yaml: [yamlls](https://github.com/redhat-developer/yaml-language-server) required.
- Ruby: [solargraph](https://github.com/castwide/solargraph) required.
- Nim: [nimlsp](https://github.com/PMunch/nimlsp) required. [packages.json](https://github.com/nim-lang/packages/blob/master/packages.json) downloading is very slow, You'd better intall minlsp manually via `choosenim` follow [this guide](https://github.com/jayli/vim-easycomplete/issues/155#issuecomment-1041581629).
- Deno: [denols](https://morioh.com/p/84a54d70a7fa) required. Use `:DenoCache` command for `deno cache` current ts/js file.
- C# : [omnisharp](http://www.omnisharp.net/) required.
- R: [r-languageserver](https://github.com/REditorSupport/languageserver) required.
- TabNine: [TabNine](https://www.tabnine.com/)

Add filetypes whitelist for specified language plugin:

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

#### Snippet Support

Vim-EasyComplete does not support snippets by default. If you want snippet integration, you will first have to install `ultisnips`. UltiSnips is compatible with Vim-EasyComplete out of the box. UltiSnips required python3 installed.

> [Solution of "E319: No python3 provider found" Error in neovim 0.4.4 with ultisnips](https://github.com/jayli/vim-easycomplete/issues/171)

#### AI Coding via TabNine Support

Install TabNine: `:InstallLspServer tabnine`. Then restart your vim/nvim.

Set `let g:easycomplete_tabnine_enable = 0` to disable TabNine. You can config TabNine by `g:easycomplete_tabnine_config` witch contains two properties:

- *line_limit*: The number of lines before and after the cursor to send to TabNine. If the option is smaller, the performance may be improved. (default: 1000)
- *max_num_result*: Max results from TabNine. (default: 10)

```vim
let g:easycomplete_tabnine_config = {
    \ 'line_limit': 1000,
    \ 'max_num_result' : 10,
    \ }
```

TabNine works well without APIKey. If you have a Tabnine's Pro API key or purchased a subscription license. To configure, you'll need to use the [TabNine' magic string](https://www.tabnine.com/faq#special_commands). Type `Tabnine::config` in insert mode to open the configuration panel.

Disable TabNine inline suggestion: `let g:easycomplete_tabnine_suggestion = 0`.

---------------------

### Beautify the vim completion menu

There are four build-in popup menu themes in cterm: `blue`,`light`,`rider` and `sharp`(for iterm). (`let g:easycomplete_scheme="sharp"`). Customise vim completion menu via these configurations:

If you just want to use default nerdfonts configuration, you can simplily config `g:easycomplete_nerd_font`

```vim
let g:easycomplete_nerd_font = 1
```

In most cases, the configuration "`g:easycomplete_nerd_font = 1`" is already enough, but if you want to customize the kind icon, you can modify the configuration like this with <https://nerdfonts.com> installed:

```vim
let g:easycomplete_menu_skin = {
      \   "buf": {
      \      "kind":"⚯",
      \      "menu":"[B]",
      \    },
      \   "snip": {
      \      "kind":"<>",
      \      "menu":"[S]",
      \    },
      \   "dict": {
      \      "kind":"d",
      \      "menu":"[D]",
      \    },
      \   "tabnine": {
      \      "kind":"",
      \    },
      \ }
let g:easycomplete_lsp_type_font = {
      \ 'text' : '⚯',         'method':'m',    'function': 'f',
      \ 'constructor' : '≡',  'field': 'f',    'default':'d',
      \ 'variable' : '𝘤',     'class':'c',     'interface': 'i',
      \ 'module' : 'm',       'property': 'p', 'unit':'u',
      \ 'value' : '𝘧',        'enum': 'e',     'keyword': 'k',
      \ 'snippet': '𝘧',       'color': 'c',    'file':'f',
      \ 'reference': 'r',     'folder': 'f',   'enummember': 'e',
      \ 'constant':'c',       'struct': 's',   'event':'e',
      \ 'typeparameter': 't', 'var': 'v',      'const': 'c',
      \ 'operator':'o',
      \ 't':'𝘵',   'f':'𝘧',   'c':'𝘤',   'm':'𝘮',   'u':'𝘶',   'e':'𝘦',
      \ 's':'𝘴',   'v':'𝘷',   'i':'𝘪',   'p':'𝘱',   'k':'𝘬',   'r':'𝘳',
      \ 'o':"𝘰",   'l':"𝘭",   'a':"𝘢",   'd':'𝘥',
      \ }
```

Config error sign text:

```vim
let g:easycomplete_sign_text = {
      \   'error':       "◉",
      \   'warning':     "▲",
      \   'information': '◎',
      \   'hint':        '▧'
      \ }
```

You can define icon alias via giving fullnames and shortname.

Enable colorful styled menu (experimental):

```
let g:easycomplete_colorful = 1
```

### Add custom completion plugin

→ [add custom completion plugin](add-custom-plugin.md)


### Issues

[WIP] If you have bug reports or feature suggestions, please use the [issue tracker](https://github.com/jayli/vim-easycomplete/issues/new). In the meantime feel free to read some of my thoughts at <https://zhuanlan.zhihu.com/p/366496399>, <https://zhuanlan.zhihu.com/p/425555993>, [https://medium.com/@lijing00333/vim-easycomplete](https://dev.to/jayli/how-to-improve-your-vimnvim-coding-experience-with-vim-easycomplete-29o0)

### More Examples:

Update Deno Cache via `:DenoCache`

<img src="https://img.alicdn.com/imgextra/i4/O1CN01kjPu4M1FVNbRKVrUD_!!6000000000492-1-tps-943-607.gif" width=600 />

Directory selecting:

<img src="https://img.alicdn.com/imgextra/i2/O1CN01FciC1Q1WHV4HJ79qn_!!6000000002763-1-tps-1027-663.gif" width=600 />

Handle backsapce typing

<img src="https://img.alicdn.com/imgextra/i3/O1CN01obuQnJ1tIAoUNv8Up_!!6000000005878-1-tps-880-689.gif" width=600 />

Snip Support

<img src="https://img.alicdn.com/imgextra/i3/O1CN01dGIJZW204A0MpESbI_!!6000000006795-1-tps-750-477.gif" width=600 />

Diagnostics jumping

<img src="https://img.alicdn.com/imgextra/i1/O1CN01g7PWjZ1q7EVKVpxno_!!6000000005448-1-tps-902-188.gif" width=600 />

Signature

<img src="https://img.alicdn.com/imgextra/i4/O1CN01kNd19n1k7nINy4SQT_!!6000000004637-1-tps-862-228.gif" width=600 />

TabNine supporting:

<img src="https://img.alicdn.com/imgextra/i3/O1CN013nBG6n1WjRE8rgMNi_!!6000000002824-1-tps-933-364.gif" width=600 />

### License

MIT
