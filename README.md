# Vim-EasyComplete

[中文](README-cn.md) | [English](README.md)

> A Fast Code Completion Plugin for VIM/NVIM with no redundancy.

![](https://img.shields.io/badge/VimScript-Only-orange.svg) ![](https://img.shields.io/badge/MacOS-available-brightgreen.svg) ![](https://img.shields.io/badge/license-MIT-blue.svg) ![](https://img.shields.io/github/workflow/status/jayli/vim-easycomplete/easycomplete.CI)

Vim-Easycomplete is a minimalism style completion plugin for vim/nvim. In order to provide the best performance and experience. I remove all non-essential requirements and environment dependencies so that it has minimum redundancy. For example, it requires vim script only, and you don't even have to add one line of configuration if you want.

<img src="https://gw.alicdn.com/imgextra/i4/O1CN01b9yaSh1hINXsztxUy_!!6000000004254-1-tps-699-394.gif" width=580>

Vim-Easycomplete is easy to install and use. It contains these features:

- Buffer keywords and dictionary support
- Directory and file completion support
- Goto definition support for all languages
- Full LSP([language-server-protocol](https://github.com/microsoft/language-server-protocol)) support
- LSP Server installation with one command
- Snippet support with ultisnips.

### Installation

Easycomplete requires Vim 8.2 and higher version with MacOS/Linux/FreeBSD. For neovim users, 0.4.4 is required (Of course, latest is recommended).

For vim-plug:

```
Plug 'jayli/vim-easycomplete'
```

Run `:PlugInstall`.

For dein.vim

```
call dein#add('jayli/vim-easycomplete')
```

### Configuration

It use Tab to trigger completion suggestions. You can change this setting by

```
let g:easycomplete_tab_trigger="<c-space>"
```

There are four build-in popup menu themes for default styles confliction: `dark`,`light`,`rider` and `sharp`. (`let g:easycomplete_scheme="sharp"`). It can be ignored in most cases.

### Useage

You can use Tab to trigger the completion suggestions anywhere. Alse use Tab and Shift-Tab to select matched items. Use `Ctrl-]` for definition jumping, `Ctrl-t` for jumping back (Same as tags jumping). Or you can use `:EasyCompleteGotoDefinition` command.

Checking if LSP server is installed via `:EasyCompleteCheck`. If current LSP Server is not ready, Use `:EasyCompleteInstallServer` to install.

Typing `./` or `../` to trigger directory completion suggestion.

Dictionary suggestion support via `set dictionary=${Your_Dictionary_File}` if you need.

Typing `:h easycomplete` for help.

All commands:

| Command                           | Description                              | 
|-----------------------------------|------------------------------------------|
| `:EasyCompleteInstallServer`      | Install LSP server for current fileytpe  |
| `:EasyCompleteGotoDefinition`     | Goto definition position                 |
| `:EasyCompleteCheck`              | Checking LSP server                      |
| `:EasyCompleteProfileStart`       | Start record diagnostics message         |
| `:EasyCompleteProfileStop`        | Stop record diagnostics  message         |

### Language Support

EasyComplete support keywords/dictionary/directory completion by default.

#### Semantic Completion for Other Languages

Most Language require LSP Server. Install missing LSP Server with `:EasyCompleteInstallServer` for current filetype (recommended). LSP Server will be installed in `~/.config/vim-easycomplete/servers`.

```
:EasyCompleteInstall
```

Or you can install a lsp server with specified plugin name (not recommended). Take typescript/javascript for example:

```
:EasyCompleteInstallServer ts
```

All supported languages:


| Plugin Name      | Languages             | Language Server        | Installer          | Env requirements|
|------------------|-----------------------|:----------------------:|:------------------:|:---------------:|
| directory        | directory suggestion  | No Need                | No                 | None            |
| buf              | keywords & dictionary | No Need                | No                 | None            |
| ts               | JavaScript/TypeScript | tsserver               | Yes                | node/npm        |
| vim              | Vim                   | vim-language-server    | Yes                | node/npm        |
| cpp              | C/C++                 | ccls                   | Yes                | ruby/brew       |
| css              | CSS                   | css-languageserver     | Yes                | node/npm        |
| html             | HTML                  | html-languageserver    | Yes                | node/npm        |
| yml              | YAML                  | yaml-language-server   | Yes                | node/npm        |
| sh               | Bash                  | bash-language-server   | Yes                | node/npm        |
| json             | JSON                  | json-languageserver    | Yes                | node/npm        |
| py               | Python                | pyls                   | Yes                | python/pip      |
| java             | Java                  | eclipse-jdt-ls         | Yes                | java/jdk        |
| go               | Go                    | gopls                  | Yes                | go              |
| rb               | Ruby                  | solargraph             | Yes                | ruby/bundle     |
| lua              | Lua                   | emmylua-ls             | Yes                | java/jdk        |
| nim              | Nim                   | nimlsp                 | Yes                | nim/nimble      |
| grvy             | Groovy                | groovy-language-server | Yes                | java/jdk        |
| snips            | Snippets Support      | ultisnips/vim-snippets | No                 | None            |

More info about semantic completion for each supported language:

- JavaScript & TypeScript: [tsserver](https://github.com/microsoft/TypeScript) required.
- Python: [pyls](https://github.com/palantir/python-language-server) required. (`pip install python-language-server`)
- Go: [gopls](https://github.com/golang/tools/tree/master/gopls) required. (`go get golang.org/x/tools/gopls`)
- Vim Script: [vim-language-server](https://github.com/iamcco/vim-language-server) required.
- C++/C：Install ccls with `brew install ccls`. If you want to install latest version. Please install it manually [following this guide](https://github.com/MaskRay/ccls).
- CSS: [vscode-css-languageserver-bin](https://github.com/vscode-langservers/vscode-css-languageserver-bin) required. (css-languageserver)，Css-languageserver dose not support CompletionProvider by default as it requires [Snippets](https://github.com/neovim/nvim-lspconfig/wiki/Snippets-support)，You must install it manually.
- JSON: [json-languageserver](https://github.com/vscode-langservers/vscode-json-languageserver-bin) required.
- HTML: [html-languageserver](https://github.com/vscode-langservers/vscode-html-languageserver-bin) required. html-languageserver dose not support CompletionProvider by default. You must install [Snippets](https://github.com/neovim/nvim-lspconfig/wiki/Snippets-support) manually.
- Shell: [bash-language-server](https://github.com/bash-lsp/bash-language-server) required.
- Java: [eclipse-jdt-ls](https://github.com/eclipse/eclipse.jdt.ls/) required.
- Lua: [emmylua-ls](https://github.com/EmmyLua/EmmyLua-LanguageServer) required.
- Groovy: [groovy-language-server](https://github.com/prominic/groovy-language-server) required.
- Yaml: [yaml-language-server](https://github.com/redhat-developer/yaml-language-server) required.
- Ruby: [solargraph](https://github.com/castwide/solargraph) required.
- Nim: [nimlsp](https://github.com/PMunch/nimlsp) required. [packages.json](https://github.com/nim-lang/packages/blob/master/packages.json) downloading is very slow, You'd better intall minlsp manually.

#### Snippet Support

EasyComplete needs [ultisnips](https://github.com/SirVer/ultisnips) and [vim-snippets](https://github.com/honza/vim-snippets) for snippets support. This two plugin is compatible with EasyComplete out of the box. Install with vim-plug:

```
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
```

You may meet this error in neovim 0.4.4 with ultisnips:

```
Error detected while processing /home/xxx/.vim/plugged/ultisnips/autoload/UltiSnips.vim:
line    7:
E319: No "python3" provider found. Run ":checkhealth provider"
```

Which means python neovim package is missing. Fix it via `pip install neovim`.

### Add custom completion plugin

Take snip as an example ([source file](https://github.com/jayli/vim-easycomplete/blob/master/autoload/easycomplete/sources/snips.vim)) without lsp server.

```
au User easycomplete_plugin call easycomplete#RegisterSource({
    \ 'name': 'snips',
    \ 'whitelist': ['*'],
    \ 'completor': 'easycomplete#sources#snips#completor',
    \ 'constructor': 'easycomplete#sources#snips#constructor',
    \  })
```

Another example with lsp server support is easier. [source file](https://github.com/jayli/vim-easycomplete/blob/master/autoload/easycomplete/sources/py.vim). By the way, you don't have to writing an omnifunc for Vim's omnicomplete.

### Issues

[WIP] If you have bug reports or feature suggestions, please use the [issue tracker](https://github.com/jayli/vim-easycomplete/issues/new). In the meantime feel free to read some of my thoughts at <https://zhuanlan.zhihu.com/p/366496399>.

### License

MIT
