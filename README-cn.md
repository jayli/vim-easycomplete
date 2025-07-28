# Vim-EasyComplete

> [中文](README-cn.md) | [English](README.md) | [Wiki](https://github.com/jayli/vim-easycomplete/wiki)

快速极简的 Vim/Nvim 补全插件

![](https://img.shields.io/badge/VimScript-Only-orange.svg?style=flat-square) ![](https://img.shields.io/badge/MacOS-available-brightgreen.svg?style=flat-square) ![](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square) ![](https://img.shields.io/github/workflow/status/jayli/vim-easycomplete/easycomplete.CI?style=flat-square)

## What

Vim-easycomplete 是一个快速极简的自动补全插件，兼容 vim 和 neovim，支持 Linux 和 MacOS. 基于 Vimscript 实现，配置简单。

<img src="https://github.com/user-attachments/assets/12ddc3b0-4bc3-40c8-8044-3f57c97261fb" width=700 />


包含特性:

- 支持 [lsp]([language-server-protocol](https://github.com/microsoft/language-server-protocol)). 通过单命令安装 LSP 服务。
- 支持关键词和字典
- 代码片段的补全
- 高性能
- 基于 TabNine 的 AI 补全助手
- 命令行补全

## 安装

Vim 8.2 及以上版本，Neovim 0.7.0 及以上，支持 MacOS/Linux/FreeBSD。

lua 配置（基于 Packer.nvim ），通过 `require("easycomplete").config(opt)` 配置:

```lua
use { 'jayli/vim-easycomplete', requires = {'L3MON4D3/LuaSnip'}}
-- snippet 可选方案还有 'SirVer/ultisnips'
-- `tabnine_enable = 0` 等同于 `vim.g.easycomplete_tabnine_enable = 0`
require("easycomplete").config({
    cmdline = 1,
    pum_noselect = 0,
    tabnine_enable = 0,
    nerd_font = 1,
    enable = 1,
    winborder = 1,
    ghost_text = 1,
    menu_abbr = 0,
    pum_format = {"abbr", "kind", "menu"},
    setup = function()
      vim.keymap.set('n', 'gr', ':EasyCompleteReference<CR>')
      vim.keymap.set('n', 'gd', ':EasyCompleteGotoDefinition<CR>')
      vim.keymap.set('n', 'rn', ':EasyCompleteRename<CR>')
      -- Plugin has already bind shift-k to `:EasyCompleteHover`
      -- vim.keymap.set('n', 'gh', ':EasyCompleteHover<CR>')
      vim.keymap.set('n', 'gb', ':BackToOriginalBuffer<CR>')
    end
  })
```

执行 `:PackerInstall`

[完整配置](https://github.com/jayli/vim-easycomplete/wiki/2.-%E5%AE%89%E8%A3%85%E5%92%8C%E9%85%8D%E7%BD%AE#%E5%9F%BA%E4%BA%8E-lua-%E7%9A%84%E5%AE%8C%E6%95%B4%E9%85%8D%E7%BD%AE)

还可以通过全局变量的方式来配置，这段lua配置和上面这段代码作用完全一样：

```lua
-- lua
use { 'jayli/vim-easycomplete', requires = {'L3MON4D3/LuaSnip'}}
-- 代码片段方案可选 'SirVer/ultisnips'，兼容 vim/nvim
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
-- 插件默认绑定 shift-k 至 `:EasyCompleteHover`
-- vim.keymap.set('n', 'gh', ':EasyCompleteHover<CR>')
vim.keymap.set('n', 'gb', ':BackToOriginalBuffer<CR>')

-- cmdline 补全
vim.g.easycomplete_cmdline = 1

-- 关闭 pum 菜单
-- vim.keymap.set('i', '<C-M>', '<Plug>EasycompleteClosePum')

-- 重新定义 Tab/s-tab 建（选择上一个和下一个）
-- vim.g.easycomplete_tab_trigger = "<C-J>"
-- vim.g.easycomplete_shift_tab_trigger = "<C-K>"

-- 重新定义回车键
-- vim.g.easycomplete_use_default_cr = 0
-- vim.keymap.set('i', '<C-L>', '<Plug>EasycompleteCR')
```
执行 `:PackerInstall`

在非 lua 中，可以使用 viml 配置，Vimscript 配置（基于vim-plug）:

```vim
" vim
Plug 'jayli/vim-easycomplete'
Plug 'L3MON4D3/LuaSnip'
" 代码片段方案可选'SirVer/ultisnips'
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
" 插件默认绑定 shift-k 至 `:EasyCompleteHover`
" noremap gh :EasyCompleteHover<CR>
noremap gb :BackToOriginalBuffer<CR>

" cmdline 补全
let g:easycomplete_cmdline = 1

" 关闭 pum 菜单
" inoremap <C-M> <Plug>EasycompleteClosePum

" 选择上一个和下一个的快捷键
" let g:easycomplete_tab_trigger = "<C-J>"
" let g:easycomplete_shift_tab_trigger = "<C-K>"

" 重新定义回车键
" let g:easycomplete_use_default_cr = 0
" inoremap <C-L> <Plug>EasycompleteCR
```
执行 `:PlugInstall`.

[一个例子](custom-config.md).

## 使用

输入过程中自动显示匹配菜单，并通过 `Tab` 来选择下一个匹配项，`Shift-Tab` 选择上一个匹配项。`Ctrl-]` 跳转到定义处，`Ctrl-t`跳回（和 tags 跳转快捷键一致）。

使用`Ctrl-N`/`Shift-Ctrl-N` 跳转到下一个/上一个错误提示位置。`Ctrl-E`关闭匹配菜单。

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
| `:EasyCompleteHover`              | 查看更多信息                                        |
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
| `g:easycomplete_kind_icons`          | `{}`          | Kind 图标.                                                   |
| `g:easycomplete_sign_text`           | `{}`          | 提示图标配置.                                               |
| `g:easycomplete_lsp_type_font`       | ...           | lsp 图标配置                                                |
| `g:easycomplete_lsp_server`          | `{}`          | 给特定的源使用 不同的 lsp server                            |
| `g:easycomplete_tabnine_suggestion`  | 0             | Tabnine 行内补全(for nvim only)                             |
| `g:easycomplete_lsp_checking`        | 1             | 打开文件时是否立即检查 lsp 是否安装                         |
| `g:easycomplete_tabnine_enable`      | 1             | 启用 Tabnine：启用后补全菜单里会出现 Tabnine 补全项         |
| `g:easycomplete_path_enable`         | 1             | 目录匹配                                                    |
| `g:easycomplete_snips_enable`        | 1             | 代码片段匹配                                                |
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
| `g:easycomplete_pum_border_style`    | `"rounded"`   | Pum 边框样式                                                |
| `g:easycomplete_info_border_style`   | `"single"`    | 辅助信息边框样式                                            |
| `g:easycomplete_ghost_text`          | 1             | 幽灵文本                                                    |
| `g:easycomplete_pum_maxheight`       | 20            | 补全窗口最大高度                                            |
| `g:easycomplete_pum_fix_width`       | 0             | pum 窗口是否固定宽度                                        |
| `g:easycomplete_pum_format`          | `["abbr", "kind", "menu"]`| 匹配项格式                                      |
| `g:easycomplete_menu_abbr`           | 0             | 匹配菜单里menu字段是否显示简写，否则显示全称                |
| `g:easycomplete_custom_snippet`      | `""`          | 自定义 snippets 路径                                        |
| `g:easycomplete_use_default_cr`      | 1             | 是否使用默认回车的事件绑定                                  |
| `g:easycomplete_pum_pretty_style`    | 1             | 开启 border 时自适应 pum 样式                               |
| `g:easycomplete_cmdline`             | 1             | cmdline 匹配                                                |
| `g:easycomplete_pum_maxlength`       | 35            | 匹配列表单词最长的字符数                                    |
| `g:easycomplete_pum_noselect`        | 0             | 是否不自动选中第一个匹配项. 同 `set &completeopt+=noselect` |

## 语言支持

两种方法安装 lsp 服务.

1. 同时支持vim/nvim: `:InstallLspServer`.
2. 只支持nvim: 基于 [mason.nvim](https://github.com/mason-org/mason.nvim), 执行 `:MasonInstall {lsp-server-name}`

LSP 服务会安装在本地路径： `~/.config/vim-easycomplete/servers`。

执行`InstallLspServer`命令时可以带上（语言）插件名称，也可以不带，下面两种都可以：

- `:InstallLspServer`
- `:InstallLspServer lua`

所有支持的语言:

| 名称        | 语言      | LSP 服务                 | LSP 是否需要安装   | 依赖         | URL |
|-------------|-----------|:------------------------:|:------------------:|:------------:|:--------:|
| path        | path      | No Need                  | 内置               | 无           |          |
| buf         | buf & dict| No Need                  | 内置               | 无           |          |
| snips       | Snippets  | ultisnips/LuaSnip        | 内置               | python3/lua  |          |
| ts          | js/ts     | tsserver                 | Yes                | node/npm     |          |
| deno        | js/ts     | denols                   | Yes                | deno         |          |
| tn          | TabNine   | TabNine                  | Yes                | 无           |          |
| vim         | Vim       | vimls                    | Yes                | node/npm     |          |
| cpp         | C/C++/OC  | clangd                   | Yes                | 无           |          |
| css         | CSS       | cssls                    | Yes                | node/npm     |          |
| html        | HTML      | html                     | Yes                | node/npm     |          |
| yml         | YAML      | yamlls                   | Yes                | node/npm     |          |
| xml         | Xml       | lemminx                  | Yes                | java/jdk     |          |
| sh          | Bash      | bashls                   | Yes                | node/npm     |          |
| json        | JSON      | json-languageserver      | Yes                | node/npm     |          |
| php         | php       | intelephense             | Yes                | node/npm     |          |
| dart        | dart      | dartls                   | Yes                | 无           |          |
| py          | Python    | pylsp                    | Yes                | python3/pip3 |          |
| java        | Java      | jdtls                    | Yes                | java11/jdk   |          |
| go          | Go        | gopls                    | Yes                | go           |          |
| r           | R         | r-languageserver         | Yes                | R            |          |
| rb          | Ruby      | solargraph               | Yes                | ruby/bundle  |          |
| lua         | Lua       | `sumneko_lua`            | Yes                | Lua          |          |
| nim         | Nim       | nimls                    | Yes                | nim/nimble   |          |
| rust        | Rust      | `rust_analyzer`          | Yes                | 无           |          |
| kt          | Kotlin    | `kotlin_language_server` | Yes                | java/jdk     |          |
| grvy        | Groovy    | groovyls                 | Yes                | java/jdk     |          |
| cmake       | cmake     | cmake                    | Yes                | python3/pip3 |          |
| c#          | C#        | omnisharp-lsp            | Yes                | 无           |          |
| zig         | zig       | zls                      | Yes                | zig          |          |
| docker      | docker    |dockerfile-language-server| Mason              | node/npm     |[easycomplete-docker](https://github.com/jayli/easycomplete-docker) |

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
- zig: [zls](https://zigtools.org/zls/install/) required.
- docker: 安装插件 [easycomplete-docker](https://github.com/jayli/easycomplete-docker), 依赖 [dockerfile-language-server](https://github.com/rcjsuen/dockerfile-language-server).
- TabNine: [TabNine](https://www.tabnine.com/)

自定义增加某种 lsp 所支持的语言类型，通常情况下不需要这么做：

vimscript

```vim
" vim
let g:easycomplete_filetypes = {
      \   "sh": {
      \     "whitelist": ["shell"]
      \   },
      \   "r": {
      \     "whitelist": ["rmd", "rmarkdown"]
      \   },
      \ }
```

luascript

```lua
-- lua
vim.g.easycomplete_filetypes = {
    sh = {
        whitelist = {"shell"}
    },
    r = {
        whitelist = {"rmd", "rmarkdown"}
    }
}
```

### Snippets 代码片段支持

Vim-Easycomplete 的代码片段支持依赖 [ultisnips](https://github.com/SirVer/ultisnips) 或 [LuaSnip](https://github.com/L3MON4D3/LuaSnip)。只需在依赖字段中引用进来即可。性能考虑，推荐优先使用 `L3MON4D3/LuaSnip`（只支持 nvim），兼容考虑使用 `SirVer/ultisnips`（支持 vim/nvim）。 你可以增加 snippets 目录到 &runtimepath 中。

你可以设置自己的 snippets 路径：

vimscript

```vim
" vim
let g:easycomplete_custom_snippet = "./path/to/your/snippets"
```

luascript

```lua
-- lua
vim.g.easycomplete_custom_snippet = "./path/to/your/snippets"
```

## AI 编程助手

除了补全菜单中包含 AI 建议项之外，插件还支持行内 AI 补全提醒。有这几种方案：

### 1）Tabnine

Vim-easycomplete 默认支持 Tabnine。Tabnine 是本地运算补全结果的比较好的选择（最新版已经更新至 deep-tabnine，只支持云端补全），速度考虑，插件只支持了 Tabnine 的本地补全的版本。

安装 `:InstallLspServer tabnine`.

<img src="https://gw.alicdn.com/imgextra/i2/O1CN01Qjk2tV2A20Ss9jtcq_!!6000000008144-0-tps-792-470.jpg" width="300px" />

配置Tabnine: `g:easycomplete_tabnine_config`，两个配置:

- *line_limit*: 参与计算的行数. 越小速度越快，越大补全更准. (默认: 1000)
- *max_num_result*: 在补全菜单中显示几个推荐项. (默认: 3)

vimscript

```vim
" vim
let g:easycomplete_tabnine_config = {
    \ 'line_limit': 1000,
    \ 'max_num_result' : 3,
    \ }
```

luascript

```lua
-- lua
vim.g.easycomplete_tabnine_config = {
    line_limit = 1000,
    max_num_result = 3
}
```

TabNine 不使用 APIKey 就可以运行。如果你是 Tabnine 的付费用户，可以配置 API key 获得行内补全的增强。通过在文件中敲入魔术字符`Tabnine::config`来激活配置面板。[文档](https://www.tabnine.com/faq#special_commands)

启用 Tabnine 的行内补全: `let g:easycomplete_tabnine_suggestion = 1`.

### 2) [copilot.nvim](https://github.com/jayli/copilot.nvim/)

Tabnine 虽然运行速度快且稳定，但比较古老，行内补全推荐使用 [Copilot.nvim](https://github.com/jayli/copilot.nvim)

### 3) Aone Copilot

阿里巴巴工程师，无脑使用 Aone Copilot，速度和质量都很高，ATA 上搜一下就有用 copilot.nvim 的配置方法。

---------------------

## 补全菜单的定制

使用 `g:easycomplete_nerd_font = 1` 来支持 [Nerdfont](https://nerdfonts.com) 字体. 图标配置方法参照 [Examples](custom-config.md).

You can add custom Pmenu styles by defining these highlight groups:

补全菜单的样式定义：

- `EasyFuzzyMatch`: 匹配字符高亮. 默认 link 到 "PmenuMatch"
- `EasyPmenu`: Pmenu 菜单样式. 默认 link 到 "Pmenu".
- `EasyPmenuKind`: PmenuKind 样式. 默认 link 到 "PmenuKind".
- `EasyPmenuExtra`: PmenuExtra 样式. 默认link到 "PmenuExtra".
- `EasyFunction`: Function 图标样式. 默认link到 "Conditional".
- `EasySnippet`: Snippet 图标样式. 默认link到 "Keyword".
- `EasyTabNine`: TabNine 图标样式. 默认link到 "Character".
- `EasySnippets`: 行内补全样式. 默认link到 "LineNr"
- `EasyNormal`: 默认图标样式，默认link到 Normal.
- `EasyKeyword`: 默认Keyword图标，默认links 到 "Define".
- `EasyModule`: 默认Module 图标. 默认links到"Function".

当 `g:easycomplete_winborder` 设置为 `1`. Pmenu 匹配菜单的背景色会自动设置成和文档背景色一致。如果你不想被自动设置 pum 背景色，可以这样关掉: `let g:easycomplete_pum_pretty_style = 0`，然后定义新的“Pmenu, FloatBorder, PmenuExtra, PmenuKind” 等样式。

更多例子: [例子](custom-config.md)

![截屏2023-12-30 20 25 06](https://github.com/jayli/vim-easycomplete/assets/188244/597db686-d4fe-4b25-8c39-d9b90db184cb)

## 开发新的语言插件

→ [参照文档](add-custom-plugin.md)

### License

MIT
