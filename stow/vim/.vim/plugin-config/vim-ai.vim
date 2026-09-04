let g:vim_ai_token_file_path = '~/.config/deepseek.key'
let g:vim_ai_roles_config_file = "~/.vim/ai-roles/roles.ini"

let g:vim_ai_complete = {
\  "provider": "openai",
\  "prompt": "",
\  "options": {
\    "model": "deepseek-chat",
\    'endpoint_url': 'https://api.deepseek.com/v1/chat/completions',
\    "max_tokens": 0,
\    "max_completion_tokens": 0,
\    "temperature": 0.1,
\    "request_timeout": 20,
\    "stream": 1,
\    "auth_type": "bearer",
\    "token_file_path": "",
\    "token_load_fn": "",
\    "selection_boundary": "#####",
\    "initial_prompt": "",
\    "frequency_penalty": "",
\    "logit_bias": "",
\    "logprobs": "",
\    "presence_penalty": "",
\    "reasoning_effort": "",
\    "seed": "",
\    "stop": "",
\    "top_logprobs": "",
\    "top_p": "",
\    "reasoning": "",
\  },
\  "ui": {
\    "paste_mode": 1,
\  },
\}

let g:vim_ai_edit = {
\  "provider": "openai",
\  "prompt": "",
\  "options": {
\    "model": "deepseek-chat",
\    'endpoint_url': 'https://api.deepseek.com/v1/chat/completions',
\    "max_tokens": 0,
\    "max_completion_tokens": 0,
\    "temperature": 0.1,
\    "request_timeout": 20,
\    "stream": 1,
\    "auth_type": "bearer",
\    "token_file_path": "",
\    "token_load_fn": "",
\    "selection_boundary": "#####",
\    "initial_prompt": "",
\    "frequency_penalty": "",
\    "logit_bias": "",
\    "logprobs": "",
\    "presence_penalty": "",
\    "reasoning_effort": "",
\    "seed": "",
\    "stop": "",
\    "top_logprobs": "",
\    "top_p": "",
\    "reasoning": "",
\  },
\  "ui": {
\    "paste_mode": 1,
\  },
\}

" 让 :AIChat 走 DeepSeek（OpenAI-兼容后端）
let g:vim_ai_chat = {
\  "provider": "openai",
\  "prompt": "",
\  "options": {
\    'model': 'deepseek-chat',
\    'endpoint_url': 'https://api.deepseek.com/v1/chat/completions',
\    "max_tokens": 0,
\    "max_completion_tokens": 0,
\    "temperature": 1,
\    "request_timeout": 20,
\    "stream": 1,
\    "auth_type": "bearer",
\    "token_file_path": "",
\    "token_load_fn": "",
\    "selection_boundary": "",
\    "initial_prompt": "",
\    "frequency_penalty": "",
\    "logit_bias": "",
\    "logprobs": "",
\    "presence_penalty": "",
\    "reasoning_effort": "",
\    "seed": "",
\    "stop": "",
\    "top_logprobs": "",
\    "top_p": "",
\    "reasoning": "",
\  },
\  "ui": {
\    "open_chat_command": "preset_below",
\    "scratch_buffer_keep_open": 0,
\    "populate_options": 0,
\    "populate_all_options": 0,
\    "force_new_chat": 0,
\    "paste_mode": 1,
\  },
\}

" let g:vim_ai_roles_config_function = 'VimAIGetRoles'
" " let g:vim_ai_roles_yaml_file = $XDG_CONFIG_HOME . '/aichat/roles.yaml'
" let g:vim_ai_roles_md_folder = expand('~/.config/aichat/roles')

" function! VimAIGetRoles() abort
"   let folder = g:vim_ai_roles_md_folder
"   if !isdirectory(folder) | throw 'Cannot read folder '..folder | endif

"   let roles = {}
"   let files = split(globpath(folder, '*.md'), '\n')

"   for file in files
"     let role = fnamemodify(file, ':t:r')
"     let roles[role] = {}

"     " read Aichat roles into Vim dictionary
"     let lines = readfile(file)
"     let separation_line_count = 0
"     for line in lines
"       if line == '---'
"         let separation_line_count += 1
"         if separation_line_count == 2
"           let roles[role]['prompt'] = []
"         endif
"       elseif separation_line_count == 1
"         let parts = split(line, '\v^[^:]+\zs:\s+')
"         if len(parts) == 2
"           let roles[role][trim(parts[0])] = trim(parts[1])
"         endif
"       elseif separation_line_count == 2
"         call add(roles[role]['prompt'], line)
"       endif
"     endfor
"     if has_key(roles[role], 'prompt')
"       let roles[role]['prompt'] = join(roles[role]['prompt'], "\n").."\n"
"     endif
"   endfor

"   " convert this Vim dictionary to Vim-ai config dictionary
"   for role in keys(roles)
"     let roles[role].options = {}

"     if has_key(roles[role], 'model')
"       " only keep OpenAI models
"       if roles[role].model =~# '\v^openai:'
"         let roles[role].options.model = roles[role].model[len('openai:'):]
"       endif
"       unlet roles[role].model
"     endif
"     if has_key(roles[role], 'temperature')
"       let roles[role].options.temperature = roles[role].temperature
"       unlet roles[role].temperature
"     " override temperature to default value for OpenAI's O1/3... models as
"     " these do not support temperature
"     elseif has_key(roles[role].options, 'model') && roles[role].options.model =~# '^o[1-9]'
"       let roles[role].options.temperature = 1
"     endif
"   endfor

"   return roles
" endfunction
