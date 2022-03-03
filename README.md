# Vim-EasyComplete

> A Fast & Minimalism Style Code Completion Plugin for vim/nvim.

![](https://img.shields.io/badge/VimScript-Only-orange.svg) ![](https://img.shields.io/badge/MacOS-available-brightgreen.svg) ![](https://img.shields.io/badge/license-MIT-blue.svg) ![](https://img.shields.io/github/workflow/status/jayli/vim-easycomplete/easycomplete.CI)

### Why

There are many excellent vim auto-completion plugins such as [nvim-cmp](https://github.com/hrsh7th/nvim-cmp), [vim-lsp](https://github.com/prabirshrestha/vim-lsp), [YouCompleteMe](https://github.com/ycm-core/YouCompleteMe) and [coc.nvim](https://github.com/neoclide/coc.nvim) etc. I used coc.nvim for a long time. It’s experience is good. But there are a few things I don’t like. These plugins tend to have too much dependencies and do not have minimal configuration. For example, I don't want to install Node when programming c++ or golang. In my opinion vim is more lightweight than vscode so I don’t need the fully integrated features of it. Besides other completion plugins neither have good experiences enough nor compatible with vim and nvim at the same time. Therefor I created [vim-easycomplete](https://github.com/jayli/vim-easycomplete) according to my personal habits.

### What

Vim-easycomplete is a fast and minimalism style completion plugin for vim/nvim. The goal is to work everywhere out of the box with high-speed performance. It requires pure vim script. You don’t need to configure anything. Especially, You don’t have to install Node and a bunch of Node modules unless you’re a javascript/typescript programmer.

<img src="https://img.alicdn.com/imgextra/i3/O1CN01dGIJZW204A0MpESbI_!!6000000006795-1-tps-750-477.gif" width=650 />

It is easy to install and use. It contains these features:

- Buffer Keywords/Directory support
- LSP([language-server-protocol](https://github.com/microsoft/language-server-protocol)) support
- [TabNine support](#TabNine-Support). (Highly Recommend!)
- Easy to install LSP Server with one command
- Written in pure vim script for vim8 and neovim
- Snippet support with ultisnips.
- Fast performance

The reason I decided to use pure vim script instead of lua or python is that I want a wider range of compatibility. And I made a lot of async handling with vim script to avoid the block of vim.

### Installation

Easycomplete requires Vim 8.2 and higher version with MacOS/Linux/FreeBSD. For neovim users, 0.4.4 and higher is required.

For vim-plug:

```vim
Plug 'jayli/vim-easycomplete'
```

Run `:PlugInstall`.

For dein.vim

```vim
call dein#add('jayli/vim-easycomplete')
```

### Configuration

The plugin is out of box and config noghting.


### Useage

By default it use Tab to trigger the completion suggestions. Alse use Tab and Shift-Tab to select matched items. Use `Ctrl-]` for definition jumping, `Ctrl-t` for jumping back (Same as tags jumping). Or you can map `:EasyCompleteGotoDefinition` by yourself.

If you don't want use `Tab` to trigger completion suggestions. You can change this setting by:

```vim
let g:easycomplete_tab_trigger="<c-space>"
```

Use `:EasyCompleteNextDiagnostic` and `:EasyCompletePreviousDiagnostic` for diagnostics jumping. The plugin has already map diagnostic jumping to `<C-j>` and `<C-k>`. You can change these mapping via:

```vim
nnoremap <silent> <C-n> :EasyCompleteNextDiagnostic<CR>
nnoremap <silent> <C-p> :EasyCompletePreviousDiagnostic<CR>
```

You only have to set custom diagnostic HOTKEYs manually in case of there was a conflict. By default press `<C-j>` or `<C-k>` for diagnostics jumping like this:

<img src="https://img.alicdn.com/imgextra/i1/O1CN01g7PWjZ1q7EVKVpxno_!!6000000005448-1-tps-902-188.gif" width=650 />

- Set `let g:easycomplete_diagnostics_enable = 0` to disable lsp diagnostics.
- Set `let g:easycomplete_lsp_checking = 0` to disable lsp checking for installation.

Checking if LSP server is installed via `:EasyCompleteCheck`. If current LSP Server is not ready, Use `:EasyCompleteInstallServer` to install.

Typing `./` or `../` to trigger directory completion suggestion.

Dictionary suggestion support via `set dictionary=${Your_Dictionary_File}` if you need.

Vim-Easycomplete also support signature popup (Use `let g:easycomplete_signature_enable = 0` to disable):

<img src="https://img.alicdn.com/imgextra/i4/O1CN01kNd19n1k7nINy4SQT_!!6000000004637-1-tps-862-228.gif" width=650 />

Typing `:h easycomplete` for help.

All commands:

| Command                           | Description                              |
|-----------------------------------|------------------------------------------|
| `:EasyCompleteInstallServer`      | Install LSP server for current fileytpe  |
| `:InstallLspServer`               | Same as `EasyCompleteInstallServer`      |
| `:EasyCompleteDisable`            | Disable EasyComplete                     |
| `:EasyCompleteEnable`             | Enable EasyComplete                      |
| `:EasyCompleteGotoDefinition`     | Goto definition position                 |
| `:EasyCompleteCheck`              | Checking LSP server                      |
| `:EasyCompletePreviousDiagnostic` | Goto Previous diagnostic                 |
| `:EasyCompleteNextDiagnostic`     | Goto Next diagnostic                     |
| `:EasyCompleteProfileStart`       | Start record diagnostics message         |
| `:EasyCompleteProfileStop`        | Stop record diagnostics  message         |
| `:EasyCompleteLint`               | Do diagnostic                            |
| `:LintEasyComplete`               | Do diagnostic                            |
| `:DenoCache`                      | Do Deno Cache for downloading modules    |

### Language Support

EasyComplete support keywords/dictionary/directory completion by default.

#### Semantic Completion for Other Languages

Most Language require LSP Server. Install missing LSP Server with `:InstallLspServer` for current filetype (recommended). LSP Server will be installed in `~/.config/vim-easycomplete/servers`.

```vim
:InstallLspServer
```

Or you can install a lsp server with specified plugin name (not recommended). Take typescript/javascript for example:

```vim
:InstallLspServer ts
```

All supported languages:


| Plugin Name      | Languages             | Language Server               | Installer          | Env requirements|
|------------------|-----------------------|:-----------------------------:|:------------------:|:---------------:|
| directory        | directory suggestion  | No Need                       | Integrated         | None            |
| buf              | keywords & dictionary | No Need                       | Integrated         | None            |
| snips            | Snippets Support      | ultisnips                     | Manually           | python3         |
| ts               | JavaScript/TypeScript | tsserver                      | Yes                | node/npm        |
| deno             | JavaScript/TypeScript | deno                          | Yes                | deno            |
| tn               | TabNine               | TabNine                       | Yes                | None            |
| vim              | Vim                   | vim-language-server           | Yes                | node/npm        |
| cpp              | C/C++                 | ccls                          | Yes                | ruby/brew       |
| css              | CSS                   | css-languageserver            | Yes                | node/npm        |
| html             | HTML                  | html-languageserver           | Yes                | node/npm        |
| yml              | YAML                  | yaml-language-server          | Yes                | node/npm        |
| xml              | Xml                   | lemminx                       | Yes                | java/jdk        |
| sh               | Bash                  | bash-language-server          | Yes                | node/npm        |
| json             | JSON                  | json-languageserver           | Yes                | node/npm        |
| php              | php                   | intelephense                  | Yes                | node/npm        |
| dart             | dart                  | analysis-server-dart-snapshot | Yes                | None            |
| py               | Python                | pyls                          | Yes                | python3/pip3    |
| java             | Java                  | eclipse-jdt-ls                | Yes                | java11/jdk      |
| go               | Go                    | gopls                         | Yes                | go              |
| r                | R                     | r-languageserver              | Yes                | R               |
| rb               | Ruby                  | solargraph                    | Yes                | ruby/bundle     |
| lua              | Lua                   | emmylua-ls                    | Yes                | java/jdk        |
| nim              | Nim                   | nimlsp                        | Yes                | nim/nimble      |
| rust             | Rust                  | rust-analyzer                 | Yes                | None            |
| kt               | Kotlin                | kotlin-language-server        | Yes                | java/jdk        |
| grvy             | Groovy                | groovy-language-server        | Yes                | java/jdk        |
| cmake            | cmake                 | cmake-language-server         | Yes                | python3/pip3    |
| cs               | C#                    | omnisharp-lsp                 | Yes                | None            |

More info about semantic completion for each supported language:

- JavaScript & TypeScript: [tsserver](https://github.com/microsoft/TypeScript) required.
- Python: [pyls](https://github.com/palantir/python-language-server) required. (`pip install python-language-server`)
- Go: [gopls](https://github.com/golang/tools/tree/master/gopls) required. (`go get golang.org/x/tools/gopls`)
- Vim Script: [vim-language-server](https://github.com/iamcco/vim-language-server) required.
- C++/C：Install ccls with `brew install ccls`. If you want to install latest version. Please install it manually [following this guide](https://github.com/MaskRay/ccls).
- CSS: [vscode-css-languageserver-bin](https://github.com/vscode-langservers/vscode-css-languageserver-bin) required. (css-languageserver)，Css-languageserver dose not support CompletionProvider by default as it requires [Snippets](https://github.com/neovim/nvim-lspconfig/wiki/Snippets-support)，You must install it manually.
- JSON: [json-languageserver](https://github.com/vscode-langservers/vscode-json-languageserver-bin) required.
- PHP: [intelephense](https://www.npmjs.com/package/intelephense)
- Dart: [analysis-server-dart-snapshot](https://storage.googleapis.com/dart-archive/)
- HTML: [html-languageserver](https://github.com/vscode-langservers/vscode-html-languageserver-bin) required. html-languageserver dose not support CompletionProvider by default. You must install [Snippets](https://github.com/neovim/nvim-lspconfig/wiki/Snippets-support) manually.
- Shell: [bash-language-server](https://github.com/bash-lsp/bash-language-server) required.
- Java: [eclipse-jdt-ls](https://github.com/eclipse/eclipse.jdt.ls/), java 11 and upper version required.
- Cmake: [cmake-language-server](https://github.com/regen100/cmake-language-server) required.
- Kotlin: [kotlin-language-server](https://github.com/fwcd/kotlin-language-server) required.
- Rust: [rust-analyzer](https://github.com/rust-analyzer/rust-analyzer) required.
- Lua: [emmylua-ls](https://github.com/EmmyLua/EmmyLua-LanguageServer) required.
- Xml: [lemminx](https://github.com/eclipse/lemminx) required.
- Groovy: [groovy-language-server](https://github.com/prominic/groovy-language-server) required.
- Yaml: [yaml-language-server](https://github.com/redhat-developer/yaml-language-server) required.
- Ruby: [solargraph](https://github.com/castwide/solargraph) required.
- Nim: [nimlsp](https://github.com/PMunch/nimlsp) required. [packages.json](https://github.com/nim-lang/packages/blob/master/packages.json) downloading is very slow, You'd better intall minlsp manually via `choosenim` follow [this guide](https://github.com/jayli/vim-easycomplete/issues/155#issuecomment-1041581629).
- Deno: [Deno](https://morioh.com/p/84a54d70a7fa) required. Use `:DenoCache` command for `deno cache` current ts/js file.
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

Vim-EasyComplete does not support snippets by default. If you want snippet integration, you will first have to install `ultisnips`. UltiSnips is compatible with Vim-EasyComplete out of the box. UltiSnips required python3 installed. Install with vim-plug:

```vim
Plug 'SirVer/ultisnips'
```

> [Solution of "E319: No python3 provider found" Error in neovim 0.4.4 with ultisnips](https://github.com/jayli/vim-easycomplete/issues/171)

#### TabNine Support

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

By default, an API key is not required to use TabNine in vim-easycomplete. If you have a Tabnine's Pro API key or purchased a subscription license. To configure, you'll need to use the [TabNine' magic string](https://www.tabnine.com/faq#special_commands). Type `Tabnine::config` in insert mode to open the configuration panel.

---------------------

### Add custom completion plugin

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

So you should redefine at least three functions `completor`/`constructor`/`gotodefinition`.

### Beautify the vim completion menu

There are four build-in popup menu themes in cterm: `blue`,`light`,`rider` and `sharp`. (`let g:easycomplete_scheme="sharp"`). Customise vim completion menu via these configurations:

- Set `let g:easycomplete_menuflag_buf = '[B]'` for keywords menu flag.
- Set `let g:easycomplete_kindflag_buf = ''` for keywords kind flag.
- Set `let g:easycomplete_menuflag_dict = '[D]'` for dictionary menu flag.
- Set `let g:easycomplete_kindflag_dict = ''` for dictionary kind flag.
- Set `let g:easycomplete_menuflag_snip = '[S]'` for snippets menu flag.
- Set `let g:easycomplete_kindflag_snip = 's'` for snippets kind flag.
- Set `let g:easycomplete_kindflag_tabnine = ''` for TabNine kind flag.
- Set `let g:easycomplete_lsp_type_font = {...}` for custom fonts.

Example configuration with <https://nerdfonts.com>:

```vim
let g:easycomplete_menuflag_buf = ""
let g:easycomplete_kindflag_buf = "⚯"
let g:easycomplete_menuflag_snip = ""
let g:easycomplete_kindflag_snip = "ട"
let g:easycomplete_kindflag_dict = "≡"
let g:easycomplete_menuflag_dict = ""
let g:easycomplete_kindflag_tabnine = ""
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

You can define icon alias via giving fullnames and shortname.

screenshots:

<img src="https://gw.alicdn.com/imgextra/i4/O1CN01IZzToV1iOccEVRsqm_!!6000000004403-2-tps-1720-1026.png" width=650 />

### Issues

[WIP] If you have bug reports or feature suggestions, please use the [issue tracker](https://github.com/jayli/vim-easycomplete/issues/new). In the meantime feel free to read some of my thoughts at <https://zhuanlan.zhihu.com/p/366496399>, <https://zhuanlan.zhihu.com/p/425555993>, [https://medium.com/@lijing00333/vim-easycomplete](https://dev.to/jayli/how-to-improve-your-vimnvim-coding-experience-with-vim-easycomplete-29o0)

### More Examples:

Update Deno Cache via `:DenoCache`

<img src="https://img.alicdn.com/imgextra/i4/O1CN01kjPu4M1FVNbRKVrUD_!!6000000000492-1-tps-943-607.gif" width=600 />

Directory selecting:

<img src="https://img.alicdn.com/imgextra/i2/O1CN01FciC1Q1WHV4HJ79qn_!!6000000002763-1-tps-1027-663.gif" width=600 />

Handle backsapce typing

<img src="https://img.alicdn.com/imgextra/i3/O1CN01obuQnJ1tIAoUNv8Up_!!6000000005878-1-tps-880-689.gif" width=600 />

TabNine supporting:

<img src="https://img.alicdn.com/imgextra/i3/O1CN013nBG6n1WjRE8rgMNi_!!6000000002824-1-tps-933-364.gif" width=600 />

### License

MIT

