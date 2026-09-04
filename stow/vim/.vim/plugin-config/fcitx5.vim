let arch = substitute(system('uname -m'), '\n', '', 'g')

function! RunBeforeExit()
		silent! call system("fcitx5-remote -c")
endfunction

function! ExecuteAndEsc()
	call system("fcitx5-remote -c")
	return "\<ESC>"
endfunction

if arch ==# 'x86_64'
		autocmd InsertLeave * call system("fcitx5-remote -c")
		" inoremap <ESC> <C-o>:call RunBeforeExit()<CR><ESC>
		" inoremap <C-[> <C-o>:call RunBeforeExit()<CR><C-[>
		" inoremap <expr> <ESC> ExecuteAndEsc()
		" inoremap <expr> <C-[> ExecuteAndEsc()
endif
