" File:         easycomplete.vim
" Author:       @jayli <https://github.com/jayli/>
" Description:  easycomplete.vim 是 vim-easycomplete 插件的启动文件，
"               easycomplete 实现了针对字典和 buff keyword 的自动补全，不依赖
"               于其他语言，完全基于 VimL 实现，安装比较干净，同时该插件兼容了
"               snipMate 和其携带的 snipets 代码片段，VIM 默认补全包含了代码片
"               段的缩写，这类缩写越熟练，代码书写速度越快，带给开发者很好的体
"               验。同时该插件配置超级简单。该插件兼容 Vim7.4+和VIM8
"
"               更多信息请访问 <https://github.com/jayli/vim-easycomplete>
"
"               帮助信息请执行
"                :helptags ~/.vim/doc
"                :h EasyComplete

if has( 'vim_starting' ) " vim 启动时加载
  augroup EasyCompleteStart
    autocmd!
    autocmd VimEnter * call easycomplete#Enable()
  augroup END
else " 通过 :packadd 手动加载
  call easycomplete#Enable()
endif

