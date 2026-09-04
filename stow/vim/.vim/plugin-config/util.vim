if !exists('*util#redir_execute')
  function! util#redir_execute(cmd) abort
    redir => l:out
    silent execute a:cmd
    redir END
    return l:out
  endfunction
endif
