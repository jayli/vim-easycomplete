# Vim-EasyComplete VIM/NVIM 补全插件

![](https://img.shields.io/badge/VimScript-Only-orange.svg) ![](https://img.shields.io/badge/MacOS-available-brightgreen.svg) ![](https://img.shields.io/badge/license-MIT-blue.svg)

<img src="https://gw.alicdn.com/imgextra/i1/O1CN01ldj7Zb1xovXKSOfXY_!!6000000006491-2-tps-640-477.png" width=300>

[余杭区](https://baike.baidu.com/item/%E4%BD%99%E6%9D%AD%E5%8C%BA/161196)最好用的 VIM/NVIM 自动补全插件

<img src="https://gw.alicdn.com/imgextra/i3/O1CN01Pjgr601zUR2hBpiXd_!!6000000006717-1-tps-793-413.gif" width=580>

### 一）安装

基于 vim-plug 安装

```
Plug 'jayli/vim-easycomplete'
```

执行 `:PlugInstall`，（兼容版本：vim 8.2 及以上，nvim 0.4.4 及以上版本）

### 二）配置

唤醒补全按键：默认 Tab 键，如果希望更换掉，通过`g:easycomplete_tab_trigger`来设置：

```
let g:easycomplete_tab_trigger="<c-space>"
```

菜单样式可以使用插件自带的四种样式（`dark`, `light`, `rider`, `sharp`）：最常用的是`sharp`，这样配置：

```
let g:easycomplete_scheme="sharp"
```

自带的样式仅仅是 vim 默认样式不合适时使用，一般留空即可。

此外无其他配置。

### 三）使用

- 补全唤醒：默认使用 <kbd>Tab</kbd> 唤醒补全菜单，用 <kbd>Shift-Tab</kbd> 在插入模式下输入 Tab。
- 定义跳转：使用 <kbd>Ctrl-]</kbd> 来跳转到变量定义，<kbd>Ctrl-t</kbd> 返回（跟 tags 操作一样），也可以自行绑定快捷键`:EasyCompleteGotoDefinition`。
- 环境检查：检查语言补全的命令依赖是否安装`:EasyCompleteCheck`。
- LSP 安装：如果当前语言需要配套 LSP Server 支持，一般使用`:EasyCompleteInstallServer ${Plugin_Name}`来安装 LSP Server 依赖
- 字典配置：关键词匹配会携带字典中的关键词，字典配置来源于`set dictionary=${Your_Dictionary_File}`，通常留空即可。
- 目录匹配：敲入路径前缀`./`或者`../`可自动弹出路径和文件匹配。
- 帮助文档：`:h easycomplete` 打开帮助文档

> - 注意：不能和 [SuperTab](https://github.com/ervandew/supertab) 一起使用，coc.nvim 的默认配置最好也删掉（tab键配置可能会有冲突）

### 四）支持的编程语言和配套插件

EasyComplete 支持常用编程语言的自动补全，且默认支持这三类补全：

- 关键字补全：默认所有类型文件都支持
- 文件路径补全：默认支持
- 字典单词补全：默认支持

依赖 [LSP Server](https://microsoft.github.io/language-server-protocol/implementors/servers/) 的编程语言补全，通常需要对应 LSP 引擎支持，一般可以在 Vim 中执行 `:EasyCompleteInstallServer ${Plugin_Name}` 安装依赖。Plugin Name 为对应补全插件名称：

| 插件名称         | 补全类型/支持语言     | LSP Server 命令      | 快捷安装 LSP 依赖  | 环境依赖       |
|------------------|-----------------------|:--------------------:|:------------------:|:--------------:|
| directory        | 文件路径补全          | 不需要               | 不需要             | 不需要         |
| buf              | 关键词/字典补全       | 不需要               | 不需要             | 不需要         |
| ts               | JavaScript/TypeScript | tsserver             | Yes                | node/npm       |
| vim              | Vim                   | vim-language-server  | Yes                | node/npm       |
| cpp              | C/C++                 | ccls                 | Yes                | ruby/brew      |
| css              | CSS                   | css-languageserver   | Yes                | node/npm       |
| sh               | Bash                  | bash-language-server | Yes                | node/npm       |
| json             | JSON                  | json-languageserver  | Yes                | node/npm       |
| py               | Python                | pyls                 | Yes                | python/pip     |
| java             | Java                  | eclipse-jdt-ls       | Yes                | java/jdk       |
| go               | Go                    | gopls                | Yes                | go             |
| snips            | 代码片段补全          |ultisnips/vim-snippets| 不需要             | 不需要         |

比如安装 tsserver，在 vim 中执行

```
:EasyCompleteInstallServer ts
```

或者直接在打开的 ts 文件中执行`:EasyCompleteInstallServer`

### 五）各语言 LSP 依赖安装说明

#### 1) 代码片段补全和展开

依赖 ultisnips 和 vim-snippets，这是我用过所有代码片段补全方案中最完整的，安装：

    Plug 'SirVer/ultisnips'
    Plug 'honza/vim-snippets'

EasyComplete 已经兼容这两个插件，`PlugInstall` 安装完成后直接可用。

在 Neovim 0.4.4 中运行 ultisnips 如果报如下错误：

```
Error detected while processing /home/xxx/.vim/plugged/ultisnips/autoload/UltiSnips.vim:
line    7:
E319: No "python3" provider found. Run ":checkhealth provider"
```

说明缺少 python neovim 包，安装 neovim 解决： `pip install neovim`

#### 2) 各语言 LSP 安装说明

- JavaScript 和 TypeScript：依赖 [tsserver](https://github.com/microsoft/TypeScript)
- Python：依赖 [pyls](https://github.com/palantir/python-language-server) (`pip install python-language-server`)
- Go：依赖 [gopls](https://github.com/golang/tools/tree/master/gopls) (go get golang.org/x/tools/gopls`)
- Vim Script：依赖 [vim-language-server](https://github.com/iamcco/vim-language-server)
- C++/C：`brew install ccls` 安装非新版 ccls，如果需要最新版 ccls，需手动安装 [ccls](https://github.com/MaskRay/ccls)，[参照这里](https://github.com/MaskRay/ccls)
- CSS：依赖 [vscode-css-languageserver-bin](https://github.com/vscode-langservers/vscode-css-languageserver-bin) (css-languageserver)，由于 css-languageserver 默认不包含 completionProvider，必须要安装 [Snippets](https://github.com/neovim/nvim-lspconfig/wiki/Snippets-support) 依赖，Snippets 脚本基于 lua 实现，用户可自行选择安装。
- JSON：依赖 [json-languageserver](https://github.com/vscode-langservers/vscode-json-languageserver-bin)
- Shell：依赖 [bash-language-server](https://github.com/bash-lsp/bash-language-server)
- Java：依赖 [eclipse-jdt-ls](https://github.com/eclipse/eclipse.jdt.ls/)，[eclipse-jdt-ls-latest.tar.gz](http://download.eclipse.org/jdtls/snapshots/jdt-language-server-latest.tar.gz) 的下载如果很慢，建议手动安装 eclipse-jdt-ls。

### 六）支持新语言的插件开发

方便起见，EasyComplete 也支持自己实现新的语言插件，只要遵循 lsp 规范即可。

插件文件位置（以 snip 为例）：`autoload/easycomplete/sources/snip.vim`，[参考样例](https://github.com/jayli/vim-easycomplete/blob/master/autoload/easycomplete/sources/snips.vim)，这个例子是没有依赖 lsp 服务的，依赖 lsp 服务的实现更简单，参照 [py.vim](https://github.com/jayli/vim-easycomplete/blob/master/autoload/easycomplete/sources/py.vim)

在 vimrc 中添加插件注册的代码：

```
au User easycomplete_plugin call easycomplete#RegisterSource({
    \ 'name': 'snips',
    \ 'whitelist': ['*'],
    \ 'completor': 'easycomplete#sources#snips#completor',
    \ 'constructor': 'easycomplete#sources#snips#constructor',
    \  })
```

配置项：

- name: {string}，插件名
- whitelist: {list}，适配的文件类型的列表，"*" 匹配所有类型
- completor: {string | function}，可以是字符串也可以是function类型，补全函数的具体实现
- constructor: {string | function}，可以是字符串也可以是function类型，插件构造器，BufEnter 时调用，可选配置
- gotodefinition: {string | function}，可以是字符串也可以是function类型，goto 跳转到定义处的函数，可选配置，如果跳转成功则返回 `v:true`，如果跳转未成功则返回`v:false`，交还给`tag` 命令来处理
- command: {string}，如果有依赖命令行，这里填写，在执行`:EasyCompleteCheck` 时检查命令是否 Ready。
- trigger: {string}，是否永远跟随光标执行全量补全（FirstComplete），默认为空，如果需要的话，设为"always"，注意'always'会很大程度影响性能，如非必要请不要使用"always"
- `semantic_triggers`: {list}，触发补全动作的字符，比如`['.','->',':']`等，可以匹配正则表达式

### 七）介绍

- [如何打造一款极简的 Vim 补全插件](https://zhuanlan.zhihu.com/p/366496399)

### 八）反馈

→ [创建 issue](https://github.com/jayli/vim-easycomplete/issues/new)

### 九）License

MIT

-----

Enjoy yourself~
