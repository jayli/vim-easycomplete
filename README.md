# Vim-EasyComplete

![](https://img.shields.io/badge/MacOS-available-brightgreen.svg) ![](https://img.shields.io/badge/license-MIT-blue.svg)

简单到爆的自动补全插件，代码补全依赖 vim-snippets，推荐安装

### 安装

基于 vim-plug 安装

  Plug 'SirVer/ultisnips'
  Plug 'honza/vim-snippets'
  Plug 'jayli/vim-easycomplete'

其中 ultisnips 和 vim-snippets 是代码片段补全用的，推荐安装，不强制

> - Python 补全需要安装 [Jedi](https://pypi.org/project/jedi/)：`pip3 install jedi`
> - JS 补全需要安装 tsserver，`npm -g install typescript`
> - Go 补全需要安装 [Gocode](https://github.com/nsf/gocode)：`go get -u github.com/nsf/gocode`

### 配置

使用 <kbd>Tab</kbd> 键呼出补全菜单，用 <kbd>Shift-Tab</kbd> 在插入模式下输入 Tab。
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

关键字和字典补全和 <kbd>C-X C-N</kbd> 一致，字典来源于`set dictionary={你的字典文件}`配置。路径补全和 <kbd>C-X C-F</kbd> 一致。

> 注意：不能和 [SuperTab](https://github.com/ervandew/supertab) 一起使用）
