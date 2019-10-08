# Vim-EasyComplete 

[中文](./README.md)|[English](README-en.md)

![Vim](https://img.shields.io/badge/vim-awesome-brightgreen.svg) [![Gitter](https://img.shields.io/badge/gitter-join%20chat-yellowgreen.svg)](https://gitter.im/jayli/vim-easycomplete) ![](https://img.shields.io/badge/Linux-available-brightgreen.svg) ![](https://img.shields.io/badge/MacOS-available-brightgreen.svg) ![](https://img.shields.io/badge/:%20h-easycomplete-orange.svg) ![](https://img.shields.io/badge/license-MIT-blue.svg)

Dictionary autocomplete with SnipMate support. Incompatible with [SuperTab](https://github.com/ervandew/supertab).

![](https://gw.alicdn.com/tfs/TB1po..ilr0gK0jSZFnXXbRRXXa-559-261.gif?t=1)

Why another completion plugin.

- [YouCompleteMe](https://github.com/Valloric/YouCompleteMe): The most popular as-you-type code completion engin. Without [Ultisnips](https://github.com/SirVer/ultisnips) supported. It requires python and it's sometime unresponsive while typing. It's too "Big And All-embracing". I want a lighter one.
- [SnipMate](https://github.com/garbas/vim-snipmate): A popular code expanding plugin. It was implemented with pure vimscript. That's cool.
- [Deoplete](https://github.com/Shougo/deoplete.nvim): Only compatible with vim8 and neovim, And requires python3. Not support vim7 and lower.
- [Completor](https://github.com/maralla/completor.vim): A new completion plugin, it's fast but no support vim 7 and lower.
- [Zencoding](https://github.com/mattn/emmet-vim): An antique.

What I wanted:

- No suggestions popup with typing. Use "tab" to invoke popup menu.
- Use my own keywords and text dictionary.
- Support vim7 and lower.
- Pure vimscript without python compiled.
- Path and file completation
- Code suggestion with python only.

Here it is:  [Vim-EasyComplete](https://github.com/jayli/vim-easycomplete)  +  [Vim-Dictionary](https://github.com/jayli/vim-dictionary) .

### Install 

#### - With [Pathogen.vim](https://github.com/tpope/vim-pathogen)

```
cd ~/.vim/bundle/
git clone https://github.com/tomtom/tlib_vim.git
git clone https://github.com/MarcWeber/vim-addon-mw-utils.git
git clone https://github.com/garbas/vim-snipmate.git
git clone https://github.com/honza/vim-snippets.git
git clone https://github.com/jayli/vim-easycomplete.git
git clone https://github.com/jayli/vim-dictionary.git
git clone https://github.com/davidhalter/jedi-vim.git
```

Install Jedi: pip3 install jedi

#### -With [Vundle.vim](https://github.com/VundleVim/Vundle.vim) 

Add these code to `~/.vimrc`

```
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
```

Execuate `:PluginInstall` in vim. Then install jedi: pip3 install jedi

### Configure

I use Shift-Tab as Normal Tab in insert mode. Use "Tab" to invoke suggestion popup menu. Add these code to `~/.vimrc`

```
imap <Tab>   <Plug>EasyCompTabTrigger
imap <S-Tab> <Plug>EasyCompShiftTabTrigger
```

It gives three colorschemes for popup menu: "dark"、"light" and "rider"

```
let g:pmenu_scheme = 'dark'
```

### Useage

Keywords and dictionary completion is same as Ctrl-X Ctrl-N.

File and dir completion: Typing Tab after "./" or "/" can invoke file suggestion popup. 

<img src="https://gw.alicdn.com/tfs/TB1maZ9ihn1gK0jSZKPXXXvUXXa-1010-586.png" width=550>

SnipMate support: SnipMate shortcuts are mixed with keywords and dictionary suggestion.

<img src="https://gw.alicdn.com/tfs/TB1KXw9iXP7gK0jSZFjXXc5aXXa-1048-486.png" width=550>

--EOF--