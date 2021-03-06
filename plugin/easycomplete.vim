" File:         easycomplete.vim
" Author:       @jayli <https://github.com/jayli/>
"               更多信息请访问 <https://github.com/jayli/vim-easycomplete>
"               帮助信息请执行
"                :helptags ~/.vim/doc
"                :h EasyComplete

" hack for tsserver initialize speed

augroup FileTypeChecking
  let ext = substitute(expand('%p'),"^.\\+[\\.]","","g")
  if ext ==# "ts"
    finish
  endif
augroup END

if has('vim_starting') " vim 启动时加载
  augroup EasyCompleteStart
    autocmd!
    autocmd SourcePost * call easycomplete#Enable()
  augroup END
else " 通过 :packadd 手动加载
  call easycomplete#Enable()
endif


