# Vim-EasyComplete

[中文](./README.md)|[English](README-en.md)

![Vim](https://img.shields.io/badge/vim-awesome-brightgreen.svg) [![Gitter](https://img.shields.io/badge/gitter-join%20chat-yellowgreen.svg)](https://gitter.im/jayli/vim-easycomplete) ![](https://img.shields.io/badge/Linux-available-brightgreen.svg) ![](https://img.shields.io/badge/MacOS-available-brightgreen.svg) ![](https://img.shields.io/badge/:%20h-easycomplete-orange.svg) ![](https://img.shields.io/badge/license-MIT-blue.svg)

代码自动补全插件，把代码片段展开、字典提醒、Tab 唤醒以及语法补全合并在一起。（注意不要和 [SuperTab](https://github.com/ervandew/supertab) 一起使用）

![](https://gw.alicdn.com/tfs/TB1po..ilr0gK0jSZFnXXbRRXXa-559-261.gif?t=1)

灵感来自这些优秀的插件：

- [YouCompleteMe](https://github.com/Valloric/YouCompleteMe)：语法补全权威插件。
- [SnipMate](https://github.com/garbas/vim-snipmate)：仅做代码展开，完全基于 VimL 实现，不支持语法嗅探。
- [Deoplete](https://github.com/Shougo/deoplete.nvim)：该插件只能运行在 [VIM8](https://github.com/vim/vim/releases/tag/v8.1.0408) 和 [Neovim](https://github.com/neovim/neovim) 上，配置麻烦，不兼容vim7。
- [Completor](https://github.com/maralla/completor.vim)：一个全新的自动补全插件，作者是中国人 [Wei Zhang](https://github.com/maralla/completor.vim)，同时支持了关键词匹配和代码片段缩写匹配，体验很赞。
- [Zencoding](https://github.com/mattn/emmet-vim)：一个古董，代码展开。

依赖：补全和字典分别依赖 vim-snipmate 和 vim-dictionary。这里支持了 Go、Python 和 JavaScript 的语法补全。

### 安装

可选 Pathogen、Vundle 等很棒的插件管理器，这里以 Pathogen 为例：

#### - 基于 [Pathogen.vim](https://github.com/tpope/vim-pathogen)（VIM 8）

同时安装 EasyComplete、vim-dictionary

    cd ~/.vim/bundle/
    git clone https://github.com/tomtom/tlib_vim.git
    git clone https://github.com/MarcWeber/vim-addon-mw-utils.git
    git clone https://github.com/garbas/vim-snipmate.git
    git clone https://github.com/honza/vim-snippets.git
    git clone https://github.com/jayli/vim-easycomplete.git
    git clone https://github.com/jayli/vim-dictionary.git

安装语言自动匹配插件：

    cd ~/.vim/bundle/
    git clone https://github.com/davidhalter/jedi-vim.git
    git clone https://github.com/ternjs/tern_for_vim.git
    git clone https://github.com/fatih/vim-go.git

> Python 需要安装 [Jedi](https://pypi.org/project/jedi/)：`pip3 install jedi`
> JavaScript 需要安装 [tern](https://ternjs.net/)：进入`~/.vim/bundle/tern_for_vim/`后执行`npm i`
> Go 需要安装 [Gocode](https://github.com/nsf/gocode)：`go get -u github.com/nsf/gocode`

### 配置

使用 <kbd>Tab</kbd> 键呼出补全菜单，用 <kbd>Shift-Tab</kbd> 在插入模式下输入 Tab。在`.vimrc`中加入：

    imap <Tab>   <Plug>EasyCompTabTrigger
    imap <S-Tab> <Plug>EasyCompShiftTabTrigger

弹窗样式配置，这里提供了两个默认样式配置，暗：`dark`，亮：`light`，通用：`rider`，在`.vimrc`里增加下面这行

    let g:pmenu_scheme = 'dark'

SnipMate 可选配置，主要是配置 JavaScript 的类型映射集合：

    let g:snipMate = {}
    let g:snipMate.scope_aliases = {}
    let g:javascript_scope_aliases = 'javascript,javascript-react,javascript-es6-react'
    let g:snipMate.scope_aliases['javascript'] = g:javascript_scope_aliases
    let g:snipMate.scope_aliases['javascript.jsx'] = g:javascript_scope_aliases

Tern 可选配置：

    let g:tern_show_argument_hints = 'on_move'
    let g:tern_show_argument_hints = 'yes'
    let g:tern_show_signature_in_pum = 1
    let g:tern_set_omni_function=0

Jedi 可选配置：

    " Jedi 配置
    let g:jedi#auto_initialization = 1
    let g:jedi#popup_on_dot = 1
    let g:jedi#popup_select_first = 0
    let g:jedi#show_call_signatures = "1"
    autocmd FileType python setlocal completeopt-=preview

Go 可选配置：

    let g:go_disable_autoinstall = 0
    let g:go_highlight_functions = 1
    let g:go_highlight_methods = 1
    let g:go_highlight_structs = 1
    let g:go_highlight_operators = 1
    let g:go_highlight_build_constraints = 1
    let g:go_version_warning = 0
    " Go 结构体名字高亮
    let g:go_highlight_types = 1
    " Go 结构体成员高亮
    let g:go_highlight_fields = 1
    " Go 函数名高亮
    let g:go_highlight_function_calls = 1

### 使用

EasyComplete 目前有四种常见用法：关键词补全、字典补全、文件路径补全和代码片段补全，除了代码片段补全之外，其他三种补全逻辑参照了 YCM 的实现，比如文件路径补全和关键词补全是解耦开的。

关键字和字典补全和 <kbd>C-X C-N</kbd> 一致，字典来源于`set dictionary={你的字典文件}`配置。

路径补全和 <kbd>C-X C-F</kbd> 类似，这里参照 YCM 重写了路径匹配的逻辑。插件会判断你是否正在输入一个路径，尤其是当你输入`./`或者`/`，也可紧跟要匹配的文件名或者目录名片段，点击 <kbd>Tab</kbd> 呼出匹配项。

<img src="https://gw.alicdn.com/tfs/TB1maZ9ihn1gK0jSZKPXXXvUXXa-1010-586.png" width=550>

#### - 代码片段补全（基于 SnipMate）

代码片段补全，这里支持的代码段来自于 [vim-snippets](https://github.com/honza/vim-snippets)，可以[在这里](https://github.com/honza/vim-snippets/tree/master/snippets)查看有哪些可用的代码片段。

<img src="https://gw.alicdn.com/tfs/TB1KXw9iXP7gK0jSZFjXXc5aXXa-1048-486.png" width=550>

代码片段内的占位符填充的动作和 SnipMate 保持一样，用 <kbd>Tab</kbd> 键切换下一个占位符。比如[这个例子](https://gw.alicdn.com/tfs/TB1PJtCbQzoK1RjSZFlXXai4VXa-1000-513.gif)展示了代码补全的情形。
