augroup easycomplete#sources#nextword#augroup
    autocmd!
    autocmd VimLeave * call s:stop_nextword()
augroup END

function! easycomplete#sources#nextword#get_source_options(opt) abort
    if !exists('a:opt["args"]')
        let a:opt['args'] = ['-n', '10000']
    endif

    if !exists('s:nextword_job')
        let s:nextword_job = 1 " async#job#start(['nextword'] + a:opt['args'], {'on_stdout': function('s:on_event')})
        if s:nextword_job <= 0
            echoerr "nextword launch failed"
        endif
        let s:ctx = {}
    endif

    return a:opt
endfunction

function! easycomplete#sources#nextword#completor(opt, ctx) abort
    if s:nextword_job <= 0
        return
    endif

    let l:typed = s:get_typed_string(a:ctx)
    let s:ctx = a:ctx
    let s:opt = a:opt
    " call async#job#send(s:nextword_job, l:typed . "\n")
endfunction

function! s:get_typed_string(ctx)
    let l:first_lnum = max([1, a:ctx['lnum']-4])
    let l:cur_lnum = a:ctx['lnum']

    let l:lines = []
    for l:lnum in range(l:first_lnum, l:cur_lnum)
        call add(l:lines, getline(l:lnum))
    endfor

    return join(l:lines, ' ')
endfunction

function! s:on_event(job_id, data, event)
    if a:event != 'stdout' || !has_key(s:ctx, 'typed')
        return
    endif

    let l:startcol = strridx(s:ctx['typed'], " ") + 2
    let l:candidates = split(a:data[0], " ")
    let l:items = s:generate_items(l:candidates)
    call easycomplete#complete(s:opt['name'], s:ctx, l:startcol, l:items)
endfunction

function! s:generate_items(candidates)
    return map(a:candidates, '{"word": v:val, "kind": "[Nextword]"}')
endfunction

function! s:stop_nextword()
    if exists('s:nextword_job') && s:nextword_job > 0
        call easycomplete#job#stop(s:nextword_job)
    endif
endfunction
