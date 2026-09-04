let g:vimspector_enable_mappings = 'HUMAN'
let g:vimspector_install_gadgets = [ 'debugpy', 'vscode-cpptools', 'CodeLLDB' ]
nmap <F5> <Plug>VimspectorContinue
nmap <F8> <Plug>VimspectorToggleBreakpoint
nmap <F9> <Plug>VimspectorStepOver
nmap <F10> <Plug>VimspectorStepInto
nmap <F12> <Plug>VimspectorStepOut
