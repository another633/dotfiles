function! s:dbInit()
    let repoPath = '~/.dict'
    let dbFile = '/misc/pinyin.txt'
    let dbCountFile = '/misc/pinyin_count.txt'

    let db = ZFVimIM_dbInit({
                \   'name' : 'pinyin',
                \ })
    call ZFVimIM_cloudRegister({
                \   'mode' : 'git',
                \   'dbId' : db['dbId'],
                \   'repoPath' : repoPath,
                \   'dbFile' : dbFile,
                \   'dbCountFile' : dbCountFile,
                \ })
endfunction

if exists('*ZFVimIME_initFlag') && ZFVimIME_initFlag()
    call s:dbInit()
else
    autocmd User ZFVimIM_event_OnDbInit call s:dbInit()
endif

" 命令行中文输入支持
function! ZF_Setting_cmdEdit()
    let cmdtype = getcmdtype()
    if cmdtype != ':' && cmdtype != '/'
        return ''
    endif
    call feedkeys("\<c-c>q" . cmdtype . 'k0' . (getcmdpos() - 1) . 'li', 'nt')
		if exists('*ZFVimIME_started') && !ZFVimIME_started()
			  call ZFVimIME_keymap_toggle_i()
		endif
    return ''
endfunction
cnoremap <silent><expr> ;; ZF_Setting_cmdEdit()

" 在插入模式退出时自动切换输入法
if exists('*ZFVimIME_started') && ZFVimIME_started()
    augroup ZFVimIME_AutoToggle
        autocmd!
        autocmd InsertLeave * call ZFVimIME_stop()
    augroup END
endif
