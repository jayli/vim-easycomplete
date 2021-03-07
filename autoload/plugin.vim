
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

endfunction

