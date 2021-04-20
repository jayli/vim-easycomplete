# Vim-EasyComplete VIM/NVIM 补全插件

![](https://img.shields.io/badge/VimScript-Only-orange.svg) ![](https://img.shields.io/badge/MacOS-available-brightgreen.svg) ![](https://img.shields.io/badge/license-MIT-blue.svg)

<img src="https://gw.alicdn.com/imgextra/i1/O1CN01ldj7Zb1xovXKSOfXY_!!6000000006491-2-tps-640-477.png" width=300>

余杭区最好用的 VIM/NVIM 自动补全插件

<img src="https://gw.alicdn.com/imgextra/i3/O1CN01Pjgr601zUR2hBpiXd_!!6000000006717-1-tps-793-413.gif" width=580>

### 一）安装

基于 vim-plug 安装

    Plug 'jayli/vim-easycomplete'

执行 `PlugInstall`，（兼容版本：vim 8.2 及以上，nvim 0.4.0 以上版本）

### 二）配置

默认 Tab 键唤醒补全，如果有冲突，修改默认配置可以用`let g:easycomplete_tab_trigger="<tab>"`来设置

插件自带了四种样式（`dark`, `light`, `rider`, `sharp`）：最常用的是`sharp`，这样配置：

```
let g:easycomplete_scheme="sharp"
```

自带的样式仅仅是 vim 默认样式不太适合的时候使用，一般留空即可。

此外无其他配置。

### 三）使用

使用 <kbd>Tab</kbd> 键呼出补全菜单，用 <kbd>Shift-Tab</kbd> 在插入模式下输入 Tab。

使用 <kbd>Ctrl-]</kbd> 来跳转到变量定义，<kbd>Ctrl-t</kbd> 返回（跟 tags 操作一样），也可以自行绑定快捷键`:EasyCompleteGotoDefinition`。

检查语言补全的命令依赖是否安装`:EasyCompleteCheck`。

字典来源于`set dictionary={你的字典文件}`配置。

敲入路径前缀`./`或者`../`可自动弹出路径和文件匹配。

`:h easycomplete` 打开帮助文档

> - 注意：不能和 [SuperTab](https://github.com/ervandew/supertab) 一起使用，coc.nvim 的默认配置最好也删掉（tab键配置可能会有冲突）

### 四）支持的编程语言和配套插件

easycomplete 支持常用编程语言的自动补全，且默认支持这三类补全：

- 关键字补全：默认所有类型文件都支持
- 文件路径补全：默认支持
- 字典单词补全：默认支持

依赖 lsp 的编程语言补全：

#### 1) 代码片段补全和展开

依赖 ultisnips 和 vim-snippets，这是我用过所有代码片段补全方案中最完整的，安装：

    Plug 'SirVer/ultisnips'
    Plug 'honza/vim-snippets'

EasyComplete 已经兼容这两个插件，`PlugInstall` 安装完成后直接可用

#### 2) JavaScript 和 TypeScript

安装 [tsserver](https://github.com/microsoft/TypeScript)：`npm -g install typescript`

#### 3) Python 补全

安装 [pyls](https://github.com/palantir/python-language-server)：`pip install python-language-server`

#### 4) Go 补全

安装 [gopls](https://github.com/golang/tools/tree/master/gopls)：`go get golang.org/x/tools/gopls`

#### 5) VimL 补全

安装 [vim-language-server](https://github.com/iamcco/vim-language-server)，`npm -g install vim-language-server`

#### 6) C++/C 补全

安装 [ccls](https://github.com/MaskRay/ccls)，[参照这里进行安装](https://github.com/MaskRay/ccls)

### 五）支持新语言的插件开发

方便起见，EasyComplete 也支持自己实现新的语言插件，只要遵循 lsp 规范即可。

插件文件位置（以 snip 为例）：`autoload/easycomplete/sources/snip.vim`，[参考样例](https://github.com/jayli/vim-easycomplete/blob/master/autoload/easycomplete/sources/snips.vim)，这个例子是没有依赖 lsp 服务的，依赖 lsp 服务的实现更简单，参照 [py.vim](https://github.com/jayli/vim-easycomplete/blob/master/autoload/easycomplete/sources/py.vim)

在 vimrc 中添加插件注册的代码：

```
call easycomplete#RegisterSource({
    \ 'name': 'snips',
    \ 'whitelist': ['*'],
    \ 'completor': 'easycomplete#sources#snips#completor',
    \ 'constructor': 'easycomplete#sources#snips#constructor',
    \  })
```

配置项：

- name: {string}，插件名
- whitelist: {list}，适配的文件类型，`*`为匹配所有类型，如果只匹配"javascript"，则这样写`["javascript"]`
- completor: {string | function}，可以是字符串也可以是function类型，补全函数的具体实现
- constructor: {string | function}，可以是字符串也可以是function类型，插件构造器，BufEnter 时调用，可选配置
- gotodefinition: {string | function}，可以是字符串也可以是function类型，goto 跳转到定义处的函数，可选配置，如果跳转成功则返回 `v:true`，如果跳转未成功则返回`v:false`，交还给`tag` 命令来处理
- command: {string}，如果有依赖命令行，这里填写，在执行`:EasyCompleteCheck` 时检查命令是否 Ready。
- trigger: {string}，是否永远跟随光标执行全量补全（FirstComplete），默认为 ""，如果需要的话，设为"always"
- `trigger_keys`: {list}，触发补全动作的字符，比如`['.','->',':']`等（暂未实现）

### 六）License

MIT

-----

Enjoy yourself~
