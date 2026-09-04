function! FindCommandSource(cmd)
    execute 'verbose command ' . a:cmd
endfunction

command! -nargs=1 -complete=command FindCmd call FindCommandSource(<f-args>)
