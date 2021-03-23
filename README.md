# Vim-EasyComplete

![](https://img.shields.io/badge/MacOS-available-brightgreen.svg) ![](https://img.shields.io/badge/license-MIT-blue.svg)

简单到爆的自动补全插件

![](https://gw.alicdn.com/imgextra/i4/O1CN01fz8bi11L9I81HjnfR_!!6000000001256-1-tps-843-448.gif)

### 安装

基于 vim-plug 安装

    Plug 'SirVer/ultisnips'
    Plug 'honza/vim-snippets'
    Plug 'jayli/vim-easycomplete'

其中 ultisnips 和 vim-snippets 是代码片段补全用的（非强制）

> - JS/TS 补全需要安装 tsserver，`npm -g install typescript`
> - Python 补全需要安装 [Jedi](https://pypi.org/project/jedi/)：`pip3 install jedi` （TODO）
> - Go 补全需要安装 [Gocode](https://github.com/nsf/gocode)：`go get -u github.com/nsf/gocode`（TODO）

### 配置

什么都不用配置，默认 Tab 键唤醒补全，修改默认配置可以用`g:easycomplete_tab_trigger="<tab>"`来设置

### 使用

使用 <kbd>Tab</kbd> 键呼出补全菜单，用 <kbd>Shift-Tab</kbd> 在插入模式下输入 Tab。

使用 <kbd>Ctrl-]</kbd> 来跳转到变量定义，<kbd>Ctrl-t</kbd> 返回（跟 tags 操作一样），如果是 JS Python 等语言，可以使用`:EasyCompleteGotoDefinition`

关键字和字典补全和 <kbd>C-X C-N</kbd> 一致，字典来源于`set dictionary={你的字典文件}`配置。路径补全和 <kbd>C-X C-F</kbd> 一致。

> 注意：不能和 [SuperTab](https://github.com/ervandew/supertab) 一起使用）

Enjoy yourself
