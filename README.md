# Vim-EasyComplete

![](https://img.shields.io/badge/MacOS-available-brightgreen.svg) ![](https://img.shields.io/badge/license-MIT-blue.svg)

简单到爆的自动补全插件，代码补全依赖 vim-snippets，推荐安装

### 安装

可选 Pathogen、Vundle 等很棒的插件管理器，以 Pathogen 为例：

#### - 基于 [Pathogen.vim](https://github.com/tpope/vim-pathogen)（VIM 8）

同时安装 EasyComplete、vim-dictionary

    cd ~/.vim/bundle/
    git clone https://github.com/honza/vim-snippets.git
    git clone https://github.com/jayli/vim-easycomplete.git

进入 `~/.vim/bundle` 安装语言自动匹配插件（根据自己的技术栈选择）：

> - Python 需要安装 [Jedi](https://pypi.org/project/jedi/)：`pip3 install jedi`
> - JavaScript 需要安装 tsserver，`npm -g install typescript`
> - Go 需要安装 [Gocode](https://github.com/nsf/gocode)：`go get -u github.com/nsf/gocode`

### 配置

使用 <kbd>Tab</kbd> 键呼出补全菜单，用 <kbd>Shift-Tab</kbd> 在插入模式下输入 Tab。在`.vimrc`中加入：

    imap <Tab>   <Plug>EasyCompTabTrigger
    imap <S-Tab> <Plug>EasyCompShiftTabTrigger

### 使用

JavaScript 和 TypeScript 的语法补全基于 TSServer，建议配置`tsconfig.json`，也可以不配

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

路径补全和 <kbd>C-X C-F</kbd> 一致。

> 注意：不能和 [SuperTab](https://github.com/ervandew/supertab) 一起使用）
