let g:run_target = ""

if filereadable(getcwd() . '/.vimrc.local')
    source %:p:h/.vimrc.local
endif

function! Run()

	if empty(g:run_target)
		let g:run_target = expand("build/%:r")
	" else
		" let output = system(g:run_target)
		" echom output
	endif
		execute "!" . g:run_target

endfunction

command! Run call Run()
