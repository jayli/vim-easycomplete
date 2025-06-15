# Vim-EasyComplete

> [中文](README-cn.md) | [English](README.md)

快速极简的 Vim/Nvim 补全插件

![](https://img.shields.io/badge/VimScript-Only-orange.svg?style=flat-square) ![](https://img.shields.io/badge/MacOS-available-brightgreen.svg?style=flat-square) ![](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square) ![](https://img.shields.io/github/workflow/status/jayli/vim-easycomplete/easycomplete.CI?style=flat-square)

## What

Vim-easycomplete 是一个快速极简的自动补全插件，兼容 vim 和 neovim，支持 Linux 和 MacOS. 基于 Vimscript 实现，配置简单。

https://github.com/user-attachments/assets/30c265f3-e65c-47d0-8762-e9e8250d7b4d


包含特性:

- 支持 [lsp]([language-server-protocol](https://github.com/microsoft/language-server-protocol)). 通过单命令安装 LSP 服务。
- 支持关键词和字典
- 通过 [Snippets](https://github.com/neovim/nvim-lspconfig/wiki/Snippets) 来兼容代码片段的补全
- 高性能
- 基于 TabNine 的 AI 补全助手

## 安装

Vim 8.2 及以上版本，Neovim 0.6.0 及以上，支持 MacOS/Linux/FreeBSD。

lua 配置（基于 Packer.nvim ）：

```lua
use { 'jayli/vim-easycomplete', requires = {'SirVer/ultisnips'}}
-- Tabnine AI 补全支持, 默认值 1
-- 安装 tabnine ":InstallLspServer tabnine"
vim.g.easycomplete_tabnine_enable = 1
-- Tabnine 代码行内提醒，默认值 0
vim.g.easycomplete_tabnine_suggestion = 0
-- 使用 Nerdfont，默认值 0
vim.g.easycomplete_nerd_font = 1
-- Add window border for pum, default is 1 (for nvim 0.11 or higher)
-- 窗口边框，默认值 1，只支持 nvim 0.11 及更高版本
vim.g.easycomplete_winborder = 1
-- 匹配项格式, 默认值 {"abbr", "kind", "menu"}
vim.g.easycomplete_pum_format = {"kind", "abbr", "menu"}
-- 最常用的 keymap 配置
vim.keymap.set('n', 'gr', ':EasyCompleteReference<CR>')
vim.keymap.set('n', 'gd', ':EasyCompleteGotoDefinition<CR>')
vim.keymap.set('n', 'rn', ':EasyCompleteRename<CR>')
vim.keymap.set('n', 'gb', ':BackToOriginalBuffer<CR>')

```
执行 `:PackerInstall`

Vimscript 配置（基于vim-plug）:

```vim
Plug 'jayli/vim-easycomplete'
Plug 'SirVer/ultisnips'
" Tabnine AI 补全支持, 默认值 1
" 安装 Tabnine ":InstallLspServer tabnine"
let g:easycomplete_tabnine_enable = 1
" Tabnine 行内提醒，默认值 0
let g:easycomplete_tabnine_suggestion = 0
" Using nerdfont for lsp icons, default is 0
" 使用 Nerdfont，默认值 0
let g:easycomplete_nerd_font = 1
" 窗口边框，默认值 1，（只支持 nvim 0.11 及更高版本）
let g:easycomplete_winborder = 1
" 匹配项格式，默认值 ["abbr", "kind", "menu"]
let g:easycomplete_pum_format = ["kind", "abbr", "menu"]
" 最常用的 keymap 配置
noremap gr :EasyCompleteReference<CR>
noremap gd :EasyCompleteGotoDefinition<CR>
noremap rn :EasyCompleteRename<CR>
noremap gb :BackToOriginalBuffer<CR>
```
执行 `:PlugInstall`.

[一个例子](custom-config.md).

## 使用

`Tab` 触发匹配，并通过 `Tab` 来选择下一个匹配项，`Shift-Tab` 选择上一个匹配项。`Ctrl-]` 跳转到定义处，`Ctrl-t`跳回（和 tags 跳转快捷键一致）。

使用`Ctrl-N`/`Shift-Ctrl-N` 跳转到下一个/上一个错误提示位置。

其他可选配置：

- 建议：`set updatetime=150` (lua: `vim.opt.updatetime = 150`).
- 默认设置 noselected：`setlocal completeopt+=noselect`（lua: `vim.cmd('setlocal completeopt+=noselect')`）

## 命令

所有命令:

| 命令                              | 说明                                                |
|-----------------------------------|-----------------------------------------------------|
| `:EasyCompleteInstallServer`      | 安装当前文件所属的 LSP 服务                         |
| `:InstallLspServer`               | 同 `EasyCompleteInstallServer`                      |
| `:EasyCompleteDisable`            | 禁用插件                                            |
| `:EasyCompleteEnable`             | 启用插件                                            |
| `:EasyCompleteGotoDefinition`     | 跳转到定义                                          |
| `:EasyCompleteReference`          | 跳转到引用                                          |
| `:EasyCompleteRename`             | 重命名                                              |
| `:EasyCompleteCheck`              | 检查 LSP 是否安装                                   |
| `:EasyCompletePreviousDiagnostic` | 跳转到上一个错误提示                                |
| `:EasyCompleteNextDiagnostic`     | 跳转到下一个错误提示                                |
| `:EasyCompleteProfileStart`       | 性能check起始时刻                                   |
| `:EasyCompleteProfileStop`        | 性能check结束时刻，并生成 profile.log               |
| `:EasyCompleteLint`               | 语法检查                                            |
| `:LintEasyComplete`               | 语法检查                                            |
| `:BackToOriginalBuffer`           | 返回引用跳转前最初的位置                            |
| `:DenoCache`                      | 拉取 Deno 文件依赖文件并缓存                        |
| `:CleanLog`                       | 关闭跳转文件列表窗口                                |

全局配置：

| 全局变量                             | 默认值        |  说明                                                       |
|--------------------------------------|---------------|-------------------------------------------------------------|
| `g:easycomplete_nerd_font`           | 0             | 使用 nerdfont                                               |
| `g:easycomplete_menu_skin`           | `{}`          | 菜单图标配置.                                               |
| `g:easycomplete_sign_text`           | `{}`          | 提示图标配置.                                               |
| `g:easycomplete_lsp_type_font`       | ...           | lsp 图标配置                                                |
| `g:easycomplete_tabnine_suggestion`  | 0             | Tabnine 行内补全(for nvim only)                             |
| `g:easycomplete_lsp_checking`        | 1             | 打开文件时是否立即检查 lsp 是否安装                         |
| `g:easycomplete_tabnine_enable`      | 1             | 启用 Tabnine：启用后补全菜单里会出现 Tabnine 补全项         |
| `g:easycomplete_directory_enable`    | 1             | 目录匹配                                                    |
| `g:easycomplete_tabnine_config`      | `{}`          | [TabNine 配置](#ai-coding-via-tabnine-support)              |
| `g:easycomplete_filetypes`           | `{}`          | [自定义文件类型配置](#language-support)                     |
| `g:easycomplete_enable`              | 1             | 是否启用插件                                                |
| `g:easycomplete_tab_trigger`         | `<Tab>`       | 触发并选择下一项的按键                                      |
| `g:easycomplete_shift_tab_trigger`   | `<S-Tab>`     | 选择上一项的按键                                            |
| `g:easycomplete_cursor_word_hl`      | 0             | 光标停留处的单词高亮                                        |
| `g:easycomplete_signature_offset`    | 0             | 错误提示的偏移量                                            |
| `g:easycomplete_diagnostics_next`    | `<C-N>`       | 跳转到下一个错误提示                                        |
| `g:easycomplete_diagnostics_prev`    | `<S-C-n>`     | 跳转到上一个错误提示                                        |
| `g:easycomplete_diagnostics_enable`  | 1             | 启用语法检查                                                |
| `g:easycomplete_signature_enable`    | 1             | 启用函数参数说明提醒                                        |
| `g:easycomplete_diagnostics_hover`   | 1             | 光标停住所在行显示错误提醒                                  |
| `g:easycomplete_winborder`           | 1             | 窗口边框 (支持 nvim 0.11 和更高版本)                        |
| `g:easycomplete_ghost_text`          | 1             | 幽灵文本                                                    |
| `g:easycomplete_pum_maxheight`       | 20            | 补全窗口最大高度                                            |
| `g:easycomplete_pum_format`          | `["abbr", "kind", "menu"]`| 匹配项格式                                      |

## 语言支持

两种方法安装 lsp 服务.

1. 同时支持vim/nvim: `:InstallLspServer`.
2. 只支持nvim: 基于 [nvim-lsp-installer](https://github.com/williamboman/nvim-lsp-installer)，命令 `:LspInstall`

LSP 服务会安装在本地路径： `~/.config/vim-easycomplete/servers`。

执行`InstallLspServer`命令时可以带上（语言）插件名称，也可以不带，下面两种都可以：

- `:InstallLspServer`
- `:InstallLspServer lua`

所有支持的语言:

| 名称        | 语言      | LSP 服务                 | LSP 是否需要安装   | 依赖         | 是否支持nvim-lsp-installer|
|-------------|-----------|:------------------------:|:------------------:|:------------:|:-------------------------:|
| directory   | directory | No Need                  | 内置               | 无           | -                         |
| buf         | buf & dict| No Need                  | 内置               | 无           | -                         |
| snips       | Snippets  | ultisnips                | 内置               | python3      | -                         |
| ts          | js/ts     | tsserver                 | Yes                | node/npm     | Yes                       |
| deno        | js/ts     | denols                   | Yes                | deno         | Yes                       |
| tn          | TabNine   | TabNine                  | Yes                | 无           | No                        |
| vim         | Vim       | vimls                    | Yes                | node/npm     | Yes                       |
| cpp         | C/C++/OC  | clangd                   | Yes                | 无           | Yes                       |
| css         | CSS       | cssls                    | Yes                | node/npm     | Yes                       |
| html        | HTML      | html                     | Yes                | node/npm     | Yes                       |
| yml         | YAML      | yamlls                   | Yes                | node/npm     | Yes                       |
| xml         | Xml       | lemminx                  | Yes                | java/jdk     | Yes                       |
| sh          | Bash      | bashls                   | Yes                | node/npm     | Yes                       |
| json        | JSON      | json-languageserver      | Yes                | node/npm     | No                        |
| php         | php       | intelephense             | Yes                | node/npm     | Yes                       |
| dart        | dart      | dartls                   | Yes                | 无           | Yes                       |
| py          | Python    | pylsp                    | Yes                | python3/pip3 | Yes                       |
| java        | Java      | jdtls                    | Yes                | java11/jdk   | Yes                       |
| go          | Go        | gopls                    | Yes                | go           | Yes                       |
| r           | R         | r-languageserver         | Yes                | R            | No                        |
| rb          | Ruby      | solargraph               | Yes                | ruby/bundle  | No                        |
| lua         | Lua       | `sumneko_lua`            | Yes                | Lua          | Yes                       |
| nim         | Nim       | nimls                    | Yes                | nim/nimble   | Yes                       |
| rust        | Rust      | `rust_analyzer`          | Yes                | 无           | Yes                       |
| kt          | Kotlin    | `kotlin_language_server` | Yes                | java/jdk     | Yes                       |
| grvy        | Groovy    | groovyls                 | Yes                | java/jdk     | Yes                       |
| cmake       | cmake     | cmake                    | Yes                | python3/pip3 | Yes                       |
| c#          | C#        | omnisharp-lsp            | Yes                | 无           | No                        |

更多 lsp 服务相关信息:

- JavaScript & TypeScript:依赖 [tsserver](https://github.com/microsoft/TypeScript).
- Python: 两个 python-language-server 分支可用:
    - [pyls](https://github.com/palantir/python-language-server) 支持 python 3.5 ~ 3.10 ([pyls breaks autocomplete on Python 3.11](https://github.com/palantir/python-language-server/issues/959)), `pip3 install python-language-server`
    - [pylsp](https://github.com/python-lsp/python-lsp-server) 支持 python 3.11, `pip3 install python-lsp-server`, (推荐)
- Go: [gopls](https://github.com/golang/tools/tree/master/gopls). (`go get golang.org/x/tools/gopls`)
- Vim Script: [vimls](https://github.com/iamcco/vim-language-server).
- C++/C/OC：[Clangd](https://github.com/clangd/clangd).
- CSS: [cssls](https://github.com/vscode-langservers/vscode-css-languageserver-bin). (css-languageserver)，Css-languageserver 要想支持 CompletionProvider，必须依赖 [Snippets](https://github.com/neovim/nvim-lspconfig/wiki/Snippets)，需要提前手动安装.
- JSON: [json-languageserver](https://github.com/vscode-langservers/vscode-json-languageserver-bin).
- PHP: [intelephense](https://www.npmjs.com/package/intelephense)
- Dart: [dartls](https://storage.googleapis.com/dart-archive/)
- HTML: [html](https://github.com/vscode-langservers/vscode-html-languageserver-bin). html-languageserver 要想支持 CompletionProvider. 必须手动安装 [Snippets](https://github.com/neovim/nvim-lspconfig/wiki/Snippets).
- Shell: [bashls](https://github.com/bash-lsp/bash-language-server).
- Java: [jdtls](https://github.com/eclipse/eclipse.jdt.ls/), 依赖 java 11 以及更高版本.
- Cmake: [cmake](https://github.com/regen100/cmake-language-server).
- Kotlin: [kotlin language server](https://github.com/fwcd/kotlin-language-server).
- Rust: [rust-analyzer](https://github.com/rust-analyzer/rust-analyzer).
- Lua: [sumneko lua](https://github.com/sumneko/lua-language-server). 本地配置文件路径 `~/.config/vim-easycomplete/servers/lua/config.json`. [更多信息](https://github.com/xiyaowong/coc-sumneko-lua/blob/main/settings.md).
- Xml: [lemminx](https://github.com/eclipse/lemminx).
- Groovy: [groovyls](https://github.com/prominic/groovy-language-server).
- Yaml: [yamlls](https://github.com/redhat-developer/yaml-language-server).
- Ruby: [solargraph](https://github.com/castwide/solargraph).
- Nim: [nimlsp](https://github.com/PMunch/nimlsp). [packages.json](https://github.com/nim-lang/packages/blob/master/packages.json) 下载非常慢, 最好手动安装，执行`choosenim`，参照 [文档](https://github.com/jayli/vim-easycomplete/issues/155#issuecomment-1041581629).
- Deno: [denols](https://morioh.com/p/84a54d70a7fa). 使用 `:DenoCache` 命令来缓存当前 ts/js file.
- C# : [omnisharp](http://www.omnisharp.net/).
- R: [r-languageserver](https://github.com/REditorSupport/languageserver).
- TabNine: [TabNine](https://www.tabnine.com/)

自定义增加某种 lsp 所支持的语言类型，通常情况下不需要这么做：

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

### 代码片段支持

Vim-Easycomplete 没有自带代码片段，但做了对`ultisnips`的兼容，参照文档[UltiSnips](https://github.com/SirVer/ultisnips)。

> [关于 "E319: No python3 provider found" (neovim 0.4.4 ) 安装 ultisnips 的错误的解决方案](https://github.com/jayli/vim-easycomplete/issues/171)


## AI 编程助手

除了补全菜单中包含 AI 建议项之外，插件还支持行内 AI 补全提醒。有这几种方案：

### 1）Tabnine

Vim-easycomplete 默认支持 Tabnine。Tabnine 是本地运算补全结果的比较好的选择（最新版已经更新至 deep-tabnine，只支持云端补全），速度考虑，插件只支持了 Tabnine 的本地补全的版本。

安装 `:InstallLspServer tabnine`.

<img src="https://gw.alicdn.com/imgextra/i2/O1CN01Qjk2tV2A20Ss9jtcq_!!6000000008144-0-tps-792-470.jpg" width="300px" />

配置Tabnine: `g:easycomplete_tabnine_config`，两个配置:

- *line_limit*: 参与计算的行数. 越小速度越快，越大补全更准. (默认: 1000)
- *max_num_result*: 在补全菜单中显示几个推荐项. (默认: 3)

基于 vimscript 配置：

```vim
let g:easycomplete_tabnine_config = {
    \ 'line_limit': 1000,
    \ 'max_num_result' : 3,
    \ }
```

TabNine 不使用 APIKey 就可以运行。如果你是 Tabnine 的付费用户，可以配置 API key 获得行内补全的增强。通过在文件中敲入魔术字符`Tabnine::config`来激活配置面板。[文档](https://www.tabnine.com/faq#special_commands)

启用 Tabnine 的行内补全: `let g:easycomplete_tabnine_suggestion = 1`.

### 2) [deepseek-coder.nvim](https://github.com/jayli/deepseek-coder.nvim/)

Tabnine 虽然运行速度快且稳定，但比较古老，行内补全推荐使用 [Copilot.nvim](https://github.com/jayli/copilot.nvim)

### 3) Aone-Copilot.nvim

阿里巴巴工程师，无脑使用 Aone-Copilot.nvim，ATA 上搜一下就有。

---------------------

## 补全菜单的定制

使用 `g:easycomplete_nerd_font = 1` 来支持 [Nerdfont](https://nerdfonts.com) 字体. 图标配置方法参照 [Examples](custom-config.md).

You can add custom Pmenu styles by defining these highlight groups:

补全菜单的样式定义：

- `EasyFuzzyMatch`: 匹配字符高亮. 默认 link 到 "Constant"
- `EasyPmenu`: Pmenu 菜单样式. 默认 link 到 "Pmenu".
- `EasyPmenuKind`: PmenuKind 样式. 默认 link 到 "PmenuKind".
- `EasyPmenuExtra`: PmenuExtra 样式. 默认link到 "PmenuExtra".
- `EasyFunction`: Function 图标样式. 默认link到 "Conditional".
- `EasySnippet`: Snippet 图标样式. 默认link到 "Keyword".
- `EasyTabNine`: TabNine 图标样式. 默认link到 "Character".
- `EasySnippets`: 行内补全样式. 默认link到 "LineNr"

当 `g:easycomplete_winborder` 设置为 `1`. Pmenu 匹配菜单的背景色会设置成和文档背景色一致。

更多例子: [例子](custom-config.md)

![截屏2023-12-30 20 25 06](https://github.com/jayli/vim-easycomplete/assets/188244/597db686-d4fe-4b25-8c39-d9b90db184cb)

## 开发新的语言插件

→ [参照文档](add-custom-plugin.md)

### License

MIT
