augroup filetypedetect_custom
  autocmd!
  autocmd BufRead,BufNewFile *.xdb setfiletype xml
  autocmd BufRead,BufNewFile *.cr setfiletype xml
  autocmd BufRead,BufNewFile *.clo setfiletype xml
  autocmd BufRead,BufNewFile *.csproj setfiletype xml
augroup END
