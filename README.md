# Vim-EasyComplete 

![Vim](https://img.shields.io/badge/vim-awesome-brightgreen.svg) [![Gitter](https://img.shields.io/badge/gitter-join%20chat-yellowgreen.svg)](https://gitter.im/jayli/vim-easycomplete) ![](https://img.shields.io/badge/Linux-available-brightgreen.svg) ![](https://img.shields.io/badge/MacOS-available-brightgreen.svg) ![](https://img.shields.io/badge/:%20h-easycomplete-orange.svg) ![](https://img.shields.io/badge/license-MIT-blue.svg)

字典 VIM 自动补全 && SnipMate。注意不要和 SuperTab 共用。

![](https://raw.githubusercontent.com/jayli/jayli.github.com/master/photo/assets/vim-easycomplete-1.gif?t=1)

已有的 VIM 自动补全能力不够用吗：

- [Omni-Completion](http://vim.wikia.com/wiki/Omni_completion)：VIM 默认代码补全，VIM 自带，使用 <kbd>C-X C-O</kbd> 呼出
- [YouCompleteMe](https://github.com/Valloric/YouCompleteMe)：最权威的补全插件。不支持 [Ultisnips](https://github.com/SirVer/ultisnips) 不支持，启动速度太慢，在 MacBookPro 上打开 VIM 要卡上 600 毫秒至少。
- [SnipMate](https://github.com/garbas/vim-snipmate)：仅做代码展开，完全基于 VimL 实现，便携性很好，不带补全提示。
- [Deoplete](https://github.com/Shougo/deoplete.nvim)：该插件只能运行在 [VIM8](https://github.com/vim/vim/releases/tag/v8.1.0408) 和 [Neovim](https://github.com/neovim/neovim) 上，必须依赖 Python3，配置太麻烦了，不兼容vim7。
- [Completor](https://github.com/maralla/completor.vim)：一个全新的自动补全插件，作者是中国人 [Wei Zhang](https://github.com/maralla/completor.vim)，同时支持了关键词匹配和代码片段缩写匹配，不兼容vim7。
- [Zencoding](https://github.com/mattn/emmet-vim)：一个古董。

我的需求是，第一，浮窗提示，第二，支持代码片段提示+展开，第三，优先选择关键词和词表匹配，第四，因为经常登录服务器，除了要支持 VIM7 以外，还要便于携带和安装，要纯 VimL 实现。最后，我不需要输入跟随提示（太干扰），我更习惯 <kbd>Tab</kbd> 提示。

[Vim-EasyComplete](https://github.com/jayli/vim-easycomplete) +  [Vim-Dictionary](https://github.com/jayli/vim-dictionary) 满足这些需求。

> - Vim-EasyComplete 只对 SnipMate 有依赖
> - 兼容 Linux 和 MacOS，暂不支持 CygWin

### 安装

可选 Pathogen、Vundle 等很棒的插件管理器：

#### - 基于 [Pathogen.vim](https://github.com/tpope/vim-pathogen) 安装（VIM7 & 8）

同时安装 EasyComplete、vim-dictionary、snipmate 和 jedi-vim（可选）

	cd ~/.vim/bundle/
	git clone https://github.com/tomtom/tlib_vim.git
	git clone https://github.com/MarcWeber/vim-addon-mw-utils.git
	git clone https://github.com/garbas/vim-snipmate.git
	git clone https://github.com/honza/vim-snippets.git
	git clone https://github.com/jayli/vim-easycomplete.git
	git clone https://github.com/jayli/vim-dictionary.git
	git clone https://github.com/davidhalter/jedi-vim.git

Python 语言的联想需要安装 Jedi

	pip3 install jedi

#### - 基于 [Vundle.vim](https://github.com/VundleVim/Vundle.vim) 安装（VIM7 & 8）

在`.vimrc`中添加下面代码，进入`vim`后执行`:PluginInstall`

	" SnipMate 携带的四个插件
	Plugin 'MarcWeber/vim-addon-mw-utils'
	Plugin 'tomtom/tlib_vim'
	Plugin 'garbas/vim-snipmate'
	Plugin 'honza/vim-snippets'

	" Jedi
	Plugin 'davidhalter/jedi-vim'

	" EasyComplete 插件和 Dictionary 词表
	Plugin 'jayli/vim-easycomplete'
	Plugin 'jayli/vim-dictionary'

安装jedi：pip3 install jedi

#### - 也可以直接基于 VIM8 安装

执行如下脚本：

	git clone https://github.com/jayli/vim-easycomplete.git \
		~/.vim/pack/dist/start/vim-easycomplete
	git clone https://github.com/jayli/vim-dictionary.git \
		~/.vim/pack/dist/start/vim-dictionary
	git clone https://github.com/MarcWeber/vim-addon-mw-utils.git \
		~/.vim/pack/dist/start/vim-addon-mw-utils
	git clone https://github.com/tomtom/tlib_vim.git \
		~/.vim/pack/dist/start/tlib_vim
	git clone https://github.com/garbas/vim-snipmate.git \
		~/.vim/pack/dist/start/vim-snipmate
	git clone https://github.com/honza/vim-snippets.git \
		~/.vim/pack/dist/start/vim-snippets

最后安装jedi：pip3 install jedi

### 配置

使用 <kbd>Tab</kbd> 键呼出补全菜单，如果遇到 <kbd>Tab</kbd> 键在插入模式下不能输出原始 `Tab`，我个人习惯敲入 <kbd>Shift-Tab</kbd> 。这里以配置 <kbd>Tab</kbd> 键唤醒补全菜单为例：在`.vimrc`中加入：

	imap <Tab>   <Plug>EasyCompTabTrigger
	imap <S-Tab> <Plug>EasyCompShiftTabTrigger

这里起主要作用的是第一行，第二行 <kbd>Shift-Tab</kbd> 为可选，我这里将 <kbd>Shift-Tab</kbd> 也定义为了插入模式下前进一个 <kbd>Tab</kbd>。

弹窗样式配置，这里提供了两个默认样式配置，暗：`dark`，亮：`light`，通用：`rider`，在`.vimrc`里增加下面这行

	let g:pmenu_scheme = 'dark'

> 不用针对 SnipMate 做额外配置，安装好就可以用了

帮助 Tags 生成（可选）：安装完成后进入 VIM 执行`:helptags ~/.vim/bundle/vim-easycomplete/doc`，便可`:help easycomplete`来阅读文档

### 使用

EasyComplete 目前有四种常见用法：关键词补全、字典补全、文件路径补全和代码片段补全，除了代码片段补全之外，其他三种补全逻辑参照了 YCM 的实现，比如文件路径补全和关键词补全是解耦开的。

#### - 关键字补全和字典补全

和 VIM 自带的智能补全 <kbd>C-X C-N</kbd> 能力一致，从当前缓冲区和字典中解析出关键词匹配出来，速度也是最快的。单词输入时按 <kbd>Tab</kbd> 呼出补全菜单，字典配置方法`set dictionary={你的字典文件}`，样例如下，用 <kbd>Tab</kbd> 和 <kbd>Shift-Tab</kbd> 键来切换下一个和上一个匹配词。

<img src="https://gw.alicdn.com/tfs/TB1UqTwckzoK1RjSZFlXXai4VXa-1580-616.png" width=550>

#### - 文件路径补全

VIM 自带 <kbd>C-X C-F</kbd> 来呼出文件路径匹配窗，也很好用，但补全窗口的起点是整个路径匹配的起点，占太多屏幕面积，这里参照 YCM 重写了路径匹配的逻辑。插件会判断你是否正在输入一个路径，尤其是当你输入`./`或者`/`，也可紧跟要匹配的文件名或者目录名片段，点击 <kbd>Tab</kbd> 呼出匹配项。

<img src="https://gw.alicdn.com/tfs/TB1WifrcgTqK1RjSZPhXXXfOFXa-1576-886.png" width=550>

#### - 代码片段补全（基于 SnipMate）

当安装了 SnipMate，补全窗口中会自动带上可匹配的代码片段缩写，比如下图示例一个 VIM 文件中输入`he`点击 <kbd>Tab</kbd> ，匹配窗里第一行是可展开的代码片段，点击回车将插入代码段，支持的代码段来自于[vim-snippets](https://github.com/honza/vim-snippets)，可以[在这里](https://github.com/honza/vim-snippets/tree/master/snippets)查看有哪些可用的代码片段。

<img src="https://gw.alicdn.com/tfs/TB1Pp_scmzqK1RjSZFjXXblCFXa-1522-646.png" width=550>

代码片段内的占位符填充的动作和 SnipMate 保持一样，用 <kbd>Tab</kbd> 键切换下一个占位符。比如[这个例子](https://gw.alicdn.com/tfs/TB1PJtCbQzoK1RjSZFlXXai4VXa-1000-513.gif)展示了代码补全的情形。

此外，我整理了一份常用编程语言的词表 [vim-dictionary](https://github.com/jayli/vim-dictionary)，安装完成无需配置直接生效，配合 EasyComplete 使用体验最佳。

Ps：感谢 YCM、SnipMate、Deoplete、Completor.. 这些优秀的 VIM 开源工具作者！为我带来很棒的灵感！~

### For Help！？需要帮助

→ [在这里提 ISSUE](https://github.com/jayli/vim-easycomplete/issues)

> 更多好玩的 VIM 碎碎，参照[我的 VIM 配置](https://github.com/jayli/vim)
