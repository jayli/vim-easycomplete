# Vim-EasyComplete

![](https://img.shields.io/badge/VimScript-Only-orange.svg) ![](https://img.shields.io/badge/MacOS-available-brightgreen.svg) ![](https://img.shields.io/badge/license-MIT-blue.svg)

简单到爆的自动补全插件

<img src="https://gw.alicdn.com/imgextra/i4/O1CN01fz8bi11L9I81HjnfR_!!6000000001256-1-tps-843-448.gif" width=600>

### 安装

基于 vim-plug 安装

    Plug 'jayli/vim-easycomplete'

执行 `PlugInstall`，（兼容版本：vim 8.2 及以上，nvim 0.4.0 以上版本）

### 配置

默认 Tab 键唤醒补全，如果有冲突，修改默认配置可以用`let g:easycomplete_tab_trigger="<tab>"`来设置

插件自带了三种样式：最常用的是`let g:easycomplete_scheme="dark"`，可留空，其他什么也不用配置

### 使用

使用 <kbd>Tab</kbd> 键呼出补全菜单，用 <kbd>Shift-Tab</kbd> 在插入模式下输入 Tab。

使用 <kbd>Ctrl-]</kbd> 来跳转到变量定义，<kbd>Ctrl-t</kbd> 返回（跟 tags 操作一样），也可以自行绑定快捷键`:EasyCompleteGotoDefinition`

字典来源于`set dictionary={你的字典文件}`配置。敲入路径前缀`./`或者`../`可自动弹出路径和文件匹配。

`:h easycomplete` 打开帮助文档

> - 注意：不能和 [SuperTab](https://github.com/ervandew/supertab) 一起使用

### 支持的语言和插件

#### 代码片段展开：

    Plug 'SirVer/ultisnips'
    Plug 'honza/vim-snippets'

EasyComplete 已经兼容这两个插件，`PlugInstall` 安装完成后直接可用

#### 语言插件

EasyComplete 默认支持 Go、JS/TS、Python 补全，每种语言需要单独安装各自依赖的 language server 服务

- JS/TS 补全需要安装 tsserver，`npm -g install typescript`
- Go 补全需要安装 [Gocode](https://github.com/nsf/gocode)：`go get -u github.com/nsf/gocode`
- Python 补全需要安装 [Jedi](https://pypi.org/project/jedi/)：`pip3 install jedi` （TODO）

其他补全可以自己开发插件

### 插件开发

插件文件位置，以 snip 为例，插件路径：`autoload/easycomplete/sources/snip.vim`，[参考样例](https://github.com/jayli/vim-easycomplete/blob/master/autoload/easycomplete/sources/snips.vim)

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
- gotodefinition: {string | function}，可以是字符串也可以是function类型，goto 跳转到定义处的函数，可选配置

Enjoy yourself
