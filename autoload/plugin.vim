
function! plugin#init()
  call easycomplete#RegisterSource({
      \ 'name': 'buf',
      \ 'completor': 'easycomplete#sources#buf#completor',
      \ })

      " \ 'whitelist': ['javascript','typescript','javascript.jsx'],
  call easycomplete#RegisterSource(easycomplete#sources#ts#getConfig({
      \ 'name': 'ts',
      \ 'completor': function('easycomplete#sources#ts#completor'),
      \ 'constructor' :function('easycomplete#sources#ts#constructor')
      \  }))

  call easycomplete#RegisterSource(easycomplete#sources#nextword#get_source_options({
      \   'name': 'nextword',
      \   'allowlist': ['*'],
      \   'args': ['-n', '10000'],
      \   'completor': function('easycomplete#sources#nextword#completor')
      \   }))
endfunction

