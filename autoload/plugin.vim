
function! plugin#init()
  call easycomplete#RegisterSource({
      \ 'name': 'buf',
      \ 'whitelist': ['*'],
      \ 'completor': 'easycomplete#sources#buf#completor',
      \ })

  call easycomplete#RegisterSource(easycomplete#sources#ts#getConfig({
      \ 'name': 'ts',
      \ 'whitelist': ['javascript','typescript','javascript.jsx'],
      \ 'completor': function('easycomplete#sources#ts#completor'),
      \ 'constructor' :function('easycomplete#sources#ts#constructor')
      \  }))

  call easycomplete#RegisterSource({
      \ 'name': 'directory',
      \ 'whitelist': ['*'],
      \ 'completor': function('easycomplete#sources#directory#completor'),
      \  })

  call easycomplete#RegisterSource({
      \ 'name': 'snips',
      \ 'whitelist': ['*'],
      \ 'completor': 'easycomplete#sources#snips#completor',
      \  })

endfunction


" let winid = popup_create('sdfdsfdsfdsf', {
"         \ "line": "cursor+1",
"         \ "col": col('.') + 10,
"         \ "pos":"topleft",
"         \ "maxwidth": 30,
"         \ "border": [1, 1, 1, 1],
"         \ "moved": "word",
"         \ })
" "  call winbufnr(winid)
"
" call popup_create('hello', {})
