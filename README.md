# Vim-EasyComplete 

![Vim](https://img.shields.io/badge/vim-awesome-brightgreen.svg) [![Gitter](https://img.shields.io/badge/gitter-join%20chat-yellowgreen.svg)](https://gitter.im/jayli/vim-easycomplete) ![](https://img.shields.io/badge/Linux-available-brightgreen.svg) ![](https://img.shields.io/badge/MacOS-available-brightgreen.svg) ![](https://img.shields.io/badge/:%20h-easycomplete-orange.svg) ![](https://img.shields.io/badge/license-MIT-blue.svg)

一个简单轻便的 VIM 自动补全插件。@author：[Jayli](https://github.com/jayli)

![](https://raw.githubusercontent.com/jayli/jayli.github.com/master/photo/assets/vim-easycomplete-1.gif?t=1)

为什么又一个轮子？已有的 VIM 自动补全能力不够用吗：

- [Omni-Completion](http://vim.wikia.com/wiki/Omni_completion)：VIM 默认代码补全，内置了一些常用语言的关键词，由于词表不能自由增减而且很古老，准确度已经大大下降了，但对于 HTML 和 CSS 来说还是很好的一个选择，优点是 VIM 自带，不用再安装了，使用 <kbd>C-X C-O</kbd> 呼出
- [YouCompleteMe](https://github.com/Valloric/YouCompleteMe)：这是一个非常棒的代码提示引擎，由 Google 工程师 Val Markovic 开发。YCM 非常适合写 C、CPP 和 Python，因为插件是基于 Python 的，编译安装后运行时速度很快，能够做到跟指敲击的自动补全，能够对 Python 做到一定程度的词义分析，给出更智能的提示，是 Python 编程最佳选择。YCM 有三点我不习惯，第一是强依赖 Python，每次安装必须要重新编译，不够轻便携带，第二是语法上的支持稍弱，必须整合 [Ultisnips](https://github.com/SirVer/ultisnips) 才能做代码片段展开，第三，启动速度是最慢的，在 MacBookPro 上打开 VIM 要卡上 600 到 800 毫秒。
- [SnipMate](https://github.com/garbas/vim-snipmate)：非常棒的代码展开补全工具，完全基于 VimL 实现，便携性很好，但它是一个类似 Zencoding 的代码展开工具，不带补全提示。
- [Deoplete](https://github.com/Shougo/deoplete.nvim)：和 YouCompleteMe 齐名的补全框架，作者是日本人。该插件只能运行在 [VIM8](https://github.com/vim/vim/releases/tag/v8.1.0408) 或者 [Neovim](https://github.com/neovim/neovim) 之上，而且必须依赖 Python3，便携性不佳，配置起来超级复杂，适合 VIM 深度玩家。
- [Completor](https://github.com/maralla/completor.vim)：一个全新的自动补全插件，作者是中国人 [Wei Zhang](https://github.com/maralla/completor.vim)，同时支持了关键词匹配和代码片段缩写匹配，交互设计上最符合我的习惯，基于 VIM8 和 Python，社区支持很不错，当前项目依然活跃，比较看好。因为使用了很多 VIM8 的新特性，对 VIM7 兼容不好。
- [Zencoding](https://github.com/mattn/emmet-vim)：古老但很酷的 html 编程利器，适合写标签，自定义代码片段难度极高，毕竟太古老了，轻易用不到。
- [TernJS](http://ternjs.net/)：TernJS 不是一个完整的插件，是一个 JavaScript 解释器，用来生成 JS 语法树，可以内嵌到一些插件里，辅助做到 JS 的上下文语义的提示补全，这个项目已经不维护了，另外两个缺陷是配置相对复杂，不够所见所得，还有就是不能做到 100% 的基于语义的补全，比如`var a = require("http")`，`a.`也做不到补全`http`模块成员，这个是 JS 这类脚本编程的通病。

我的需求散落在各个插件里，四个主要需求，第一，浮窗提示，第二，支持代码片段提示+展开，第三，优先选择关键词和词表匹配，第四，因为经常登录服务器，除了要支持 VIM7 以外，还要便于携带和安装，登录一台裸机，一个命令快速搞定，所以不能有 Python 依赖，要纯 VimL 实现。最后，相比于输入跟随提示（略干扰），我更习惯 <kbd>Tab</kbd> 提示。以上这些插件均不能同时满足我这四个需求，不得已我造了 [Vim-EasyComplete](https://github.com/jayli/vim-easycomplete)，以及常用词表 [Vim-Dictionary](https://github.com/jayli/vim-dictionary)（配合 EasyComplete 使用体验最佳）。

因为要用到代码片段展开，Vim-EasyComplete 只对 SnipMate 有依赖，SnipMate 也是干净的 VimL 实现。当然，SnipMate 没有安装，EasyComplete 也是可以正常工作的。

### 安装

VIM 插件安装极其方便，可选 Pathogen、Vundle 等很棒的插件管理器：

> EasyComplete 兼容 Linux 和 MacOS，暂不支持 CygWin

#### - 基于 [Pathogen.vim](https://github.com/tpope/vim-pathogen) 安装（VIM7 & 8）

同时安装 EasyComplete、vim-dictionary 和 snipmate

	cd ~/.vim/bundle/
	git clone https://github.com/tomtom/tlib_vim.git
	git clone https://github.com/MarcWeber/vim-addon-mw-utils.git
	git clone https://github.com/garbas/vim-snipmate.git
	git clone https://github.com/honza/vim-snippets.git
	git clone https://github.com/jayli/vim-easycomplete.git
	git clone https://github.com/jayli/vim-dictionary.git

#### - 基于 [Vundle.vim](https://github.com/VundleVim/Vundle.vim) 安装（VIM7 & 8）

在`.vimrc`中添加下面代码，进入`vim`后执行`:PluginInstall`

	" SnipMate 携带的四个插件
	Plugin 'MarcWeber/vim-addon-mw-utils'
	Plugin 'tomtom/tlib_vim'
	Plugin 'garbas/vim-snipmate'
	Plugin 'honza/vim-snippets'  

	" EasyComplete 插件和 Dictionary 词表
	Plugin 'jayli/vim-easycomplete'
	Plugin 'jayli/vim-dictionary'

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
	
Done!

> 代码片段补全插件 SnipMate 支持尽管是可选项，但强烈建议安装。以上安装示例也包含 SnipMate 的安装，它同时也是 VIM 官方推荐插件，独立使用请参照[它的文档](https://github.com/garbas/vim-snipmate)。

### 配置

我习惯使用 <kbd>Tab</kbd> 键呼出补全菜单，如果遇到 <kbd>Tab</kbd> 键在插入模式下不能输出原始 `Tab`，我个人习惯敲入 <kbd>Shift-Tab</kbd> 。这里以配置 <kbd>Tab</kbd> 键唤醒补全菜单为例：在`.vimrc`中加入：

	imap <Tab>   <Plug>EasyCompTabTrigger
	imap <S-Tab> <Plug>EasyCompShiftTabTrigger

这里起主要作用的是第一行，第二行 <kbd>Shift-Tab</kbd> 为可选，我这里将 <kbd>Shift-Tab</kbd> 也定义为了插入模式下前进一个 <kbd>Tab</kbd>。

弹窗样式配置，这里提供了两个默认样式配置，暗：`dark`，亮：`light`，在`.vimrc`里增加下面这行，如果不配，跟全局样式一致

	let g:pmenu_scheme = 'dark'

> SnipMate 的代码补全功能已经整合入了 EasyComplete，原则上是不用针对 SnipMate 做额外配置的，安装好就好了。

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

### 关于 VIM 代码补全的一些思考

原生 VIM 不适合做 IDE，VIM 最擅长做“文本编辑”，根据我个人的使用场景，对编辑器的要求有三点：

- 第一，随进随退，轻便开发。由于我在服务器编程时间时间较多，VIM 常被用来阅读源码、微调试和写快捷脚本，完成一个任务后就离开了，随即进入下一个任务，这个过程中，VIM 的文本编辑效率非常重要，所谓轻便开发，就是我 ssh 到一个新的机器，用一个命令就可以快速将 VIM 环境配置完成，随即进入任务，完成任务后离开服务器，有可能一阵子不会再回到这台机器。所以 VIM 一定要易于配置，且不适于携带过多三方依赖，包括对 Python 的依赖，因此要有取舍。
- 第二，VIM 并不经常装载工程。也就是说对于包含大量源文件的源码工程，并不首先适于由原生 VIM 来装载。类似 Eclipse 和 Visual Studio 等等或许是更好的选择。VIM 的绝大多数特性和配置依赖于 VimL，VimL 作为脚本，性能上是有瓶颈的，装载工程是一件吃力的事情。比如最常用的自动补全功能，越希望它智能，就越需要框定工程边界，以防止查找溢出。而在 VIM 中做智能的语义补全，也因普遍缺少工程边界而变得很困难，比如 NodeJS 中的 `node_modules` 目录中的层层引用，如果需要在 JavaScript 中匹配出正确的对象成员，一次匹配相当于运行一次整个（边界不确定的）“工程”，消耗是巨大的。做不到精确，就无法带来更好的体验。
- 第三，VIM 最适合脚本编程。特别是当编程语言（诸如 Swift、Kotlin、Go..）越来越“脚本化”，VIM 将会发挥其独特的价值，越灵活、越简洁、越脚本化，VIM 就越适合。让 VIM 专注于文本编辑，配合 Unix 强大的工具平台，可以很好的搭配完成更复杂的业务，很好的适应快进快出、随时随地进入编程状态，满足部分人“碎片编程”的情况。

因此 EasyComplete 会尝试实现一定程度的词法分析的代码补全，但不会深入做。从某种角度讲，VIM 原生的 <kbd>C-X C-N</kbd>、<kbd>C-X C-O</kbd>、<kbd>C-X C-F</kbd> 以及 <kbd>C-X C-L</kbd> 就已经是最好的补全工具了。

此外，我整理了一份常用编程语言的词表 [vim-dictionary](https://github.com/jayli/vim-dictionary)，安装完成无需配置直接生效，配合 EasyComplete 使用体验最佳。

> 当然 VIM 很多派生版本诸如 [SpaceVim](https://github.com/SpaceVim/SpaceVim) 和 [NeoVim](https://neovim.io/) 借助更强的 GUI 外壳也很好的满足工程型的编程。<br />也远超过我当下的需要 : )

Ps：感谢 YCM、SnipMate、Deoplete、Completor.. 这些优秀的 VIM 开源工具作者！为我带来很棒的灵感！~

### For Help！？需要帮助

→ [在这里提 ISSUE](https://github.com/jayli/vim-easycomplete/issues)

> 更多好玩的 VIM 碎碎，参照[我的 VIM 配置](https://github.com/jayli/vim)
