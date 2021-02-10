# Vim-EasyComplete

![](https://img.shields.io/badge/MacOS-available-brightgreen.svg) ![](https://img.shields.io/badge/license-MIT-blue.svg)

一个简单的自动补全插件，把代码片段展开、字典提醒、Tab 唤醒以及语法补全合并在一起。

> 我重写了 Tab 的逻辑，不能和 [SuperTab](https://github.com/ervandew/supertab) 一起使用）

灵感来自这些优秀的插件：

- [YouCompleteMe](https://github.com/Valloric/YouCompleteMe)：语法补全权威插件。配置太复杂了，不爱用。
- [SnipMate](https://github.com/garbas/vim-snipmate)：仅做代码展开，完全基于 VimL 实现。
- [Deoplete](https://github.com/Shougo/deoplete.nvim)：该插件只能运行在 [VIM8](https://github.com/vim/vim/releases/tag/v8.1.0408) 和 [Neovim](https://github.com/neovim/neovim) 上，配置麻烦，不兼容vim7。
- [Completor](https://github.com/maralla/completor.vim)：一个全新的自动补全插件，作者是中国人 [Wei Zhang](https://github.com/maralla/completor.vim)，同时支持了关键词匹配和代码片段缩写匹配。强依赖 python
- [Zencoding](https://github.com/mattn/emmet-vim)：一个古董，代码展开。

依赖 vim-snipmate。我支持了 Go、Python 和 JavaScript 的语法补全。Popup 菜单如下：

<img src="https://gw.alicdn.com/tfs/TB19wGlx.Y1gK0jSZFMXXaWcVXa-1460-1022.png" width=600>

### 安装

可选 Pathogen、Vundle 等很棒的插件管理器，以 Pathogen 为例：

#### - 基于 [Pathogen.vim](https://github.com/tpope/vim-pathogen)（VIM 8）

同时安装 EasyComplete、vim-dictionary

    cd ~/.vim/bundle/
    git clone https://github.com/tomtom/tlib_vim.git
    git clone https://github.com/MarcWeber/vim-addon-mw-utils.git
    git clone https://github.com/garbas/vim-snipmate.git
    git clone https://github.com/honza/vim-snippets.git
    git clone https://github.com/jayli/vim-easycomplete.git

进入 `~/.vim/bundle` 安装语言自动匹配插件（根据自己的技术栈选择）：

- Python `git clone https://github.com/davidhalter/jedi-vim.git`
- Go `git clone https://github.com/fatih/vim-go.git`
- JavaScript & TypeScript `git clone https://github.com/jayli/tsuquyomi.git`

> - Python 需要安装 [Jedi](https://pypi.org/project/jedi/)：`pip3 install jedi`
> - JavaScript 需要安装 tsserver，直接执行 `npm -g install typescript`
> - Go 需要安装 [Gocode](https://github.com/nsf/gocode)：`go get -u github.com/nsf/gocode`

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

Typescript 和 Javascript 可选配置：

    let g:tsuquyomi_completion_detail = 1
    let g:tsuquyomi_javascript_support = 1
    let g:easycomplete_typing_popup = 1 " 是否输入跟随补全提示

Jedi （Python）可选配置：

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

JavaScript 和 TypeScript 的语法补全基于 TSServer，建议配置`tsconfig.json`

    {
      "compilerOptions": {
        "noImplicitAny": true,
        "target": "es5",
        "module": "commonjs"
      }
    }

和 VSCode 的语法嗅探的比较：

![](https://gw.alicdn.com/tfs/TB1YpXfyYY1gK0jSZTEXXXDQVXa-2026-752.png)

关键字和字典补全和 <kbd>C-X C-N</kbd> 一致，字典来源于`set dictionary={你的字典文件}`配置。

路径补全和 <kbd>C-X C-F</kbd> 类似，这里参照 YCM 重写了路径匹配的逻辑。插件会判断你是否正在输入一个路径，尤其是当你输入`./`或者`/`，也可紧跟要匹配的文件名或者目录名片段，点击 <kbd>Tab</kbd> 呼出匹配项。

<img src="https://gw.alicdn.com/tfs/TB15JJWxQP2gK0jSZPxXXacQpXa-1204-446.png" width=600>

关于代码片段补全，这里支持的代码段来自于 [vim-snippets](https://github.com/honza/vim-snippets)，可以[在这里](https://github.com/honza/vim-snippets/tree/master/snippets)查看有哪些可用的代码片段。代码片段内的占位符填充的动作和 SnipMate 保持一样，用 <kbd>Tab</kbd> 键切换下一个占位符。比如[这个例子](https://gw.alicdn.com/tfs/TB1PJtCbQzoK1RjSZFlXXai4VXa-1000-513.gif)。
