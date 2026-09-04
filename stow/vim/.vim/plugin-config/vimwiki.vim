if !exists('g:vimwiki_list')
	let g:vimwiki_list = []

	if isdirectory('./vimwiki')
		call add(g:vimwiki_list, {'path': './vimwiki/', 'syntax': 'markdown', 'ext': '.md'})
	endif

	call add(g:vimwiki_list, {'path': '~/vimwiki/', 'syntax': 'markdown', 'ext': '.md'})
endif

function! s:AddWiki()
	if !isdirectory('./vimwiki')
		call mkdir('./vimwiki', 'p')
		call insert(g:vimwiki_list, {'path': './vimwiki/', 'syntax': 'markdown', 'ext': '.md'})
	endif
endfunction

command! AddWiki call <SID>AddWiki()
