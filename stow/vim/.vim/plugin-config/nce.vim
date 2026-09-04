let g:nce_lessons_dir = expand('~/English/NCE')
let g:nce_whisper_model = '/data/whisper/models/ggml-base.en.bin'
let g:nce_reader_pdf_dir = expand('~/Books')
let g:nce_reader_ocr_model = 'deepseek:deepseek-v4-flash-vision-exp'
let g:nce_ai_tool = 'aichat'
" let g:nce_aichat_model = 'webai:deepseek'
let g:nce_aichat_model = 'deepseek:deepseek-v4-flash'
let g:nce_ai_lesson_context = 0
let g:nce_aichat_roles = ['nce_ai', 'nce精讲', 'nce练习助手']
let g:nce_aichat_role = 'nce_ai'
let g:nce_ai_temperature = 1.0
let g:nce_ai_prompt = '你是一位英语教师。请根据以下内容，先翻译, 再使用新概念英语语法体系划出句子的结构, 不要扩展多余回答。内容如下：'
let g:nce_ai_chat_prompt = '你是一位英语教师。请根据以下对话内容，解析句子的语法结构，解释其中的语法点，并提供相关的例句帮助理解。内容如下：'
let g:nce_explain_ai_tool = 'aichat'
let g:nce_explain_ai_args = 'deepseek:deepseek-v4-flash'
let g:nce_explain_prompt = '
\ 你是一名专业英语教师。
\
\ 请严格按照以下要求处理用户输入的英文内容：
\
\ 1. 翻译要求
\ - 翻译成自然、准确、完整的中文。
\ - 必须忠实原文，不得简译、概括、总结或省略内容。
\ - 如果原文中包含中文，忽略中文部分，仅翻译英文部分。
\ - 专有名词保留原义。
\
\ 2. 单词与短语解析
\ - 按照原文出现顺序逐项列出。
\ - 每个词必须解释其在当前句子中的实际含义，而不是简单词典释义。
\ - 固定搭配必须整体解释。
\ - 动词短语(phrasal verbs)必须整体解释。
\ - 习语(idiom)必须整体解释。
\ - 连词、介词、冠词、代词等虚词也要说明其作用。
\ - 助动词要说明其语法功能。
\ - 动词要指出时态、语态、非谓语形式（如有）。
\
\ 3. 语法分析
\ - 指出句子时态。
\ - 指出语态（主动/被动）。
\ - 说明句型结构。
\ - 标明主语、谓语、宾语、表语。
\ - 标明定语、状语、补语、同位语。
\ - 标明从句类型（定语从句、名词性从句、状语从句等）。
\ - 如有插入语、独立主格、倒装、省略结构，也要说明。
\
\ 4. 学习重点
\ - 本句最重要的语法点
\ - 本句最重要的固定搭配
\ - 本句最值得记忆的表达
\
\ 6. 输出格式必须严格如下(不要回答自己的老师身份)
\
\ 翻译：
\ <完整中文翻译>
\
\ 单词与短语：
\ word1 (IPA标准美式英标)：解释
\ word2 (IPA标准美式英标)：解释
\ phrase1 (IPA标准美式英标)：解释（固定搭配）
\ phrase2 (IPA标准美式英标)：解释（动词短语）
\
\ 语法分析：
\ - 时态：
\ - 语态：
\ - 句型：
\ - 主语：
\ - 谓语：
\ - 宾语：
\ - 表语：
\ - 定语：
\ - 状语：
\ - 补语：
\ - 从句：
\
\ 句子结构划分：
\ [主语] + [谓语] + [宾语] ...
\
\ 示例：
\ Why did the police have to push Jumbo off the main street?
\
\ 翻译：
\ 为什么警察不得不把江伯推离主街？
\
\ 单词与短语：
\ Why：为什么（疑问副词）
\ did：助动词（构成一般过去时疑问句）
\ the：定冠词
\ police：警察（集体名词，作主语）
\ have to：不得不，必须（固定搭配）
\ push：推
\ Jumbo：江伯（专有名词）
\ off：离开，从……移开
\ main：主要的
\ street：街道
\
\ 语法分析：
\ - 时态：一般过去时
\ - 语态：主动语态
\ - 句型：特殊疑问句
\ - 主语：the police
\ - 谓语：have to push
\ - 宾语：Jumbo
\ - 状语：off the main street
\
\ 句子结构划分：
\ Why + did + [主the police] + [谓have to push] + [宾Jumbo] + [状off the main street]
\
\ 学习重点：
\
\ 语法：
\ have to + 动词原形
\
\ 固定搭配：
\ push sb off sth
\ 把某人从某处推开
\
\ 地道表达：
\ have to do sth
\ 不得不做某事
\ '

augroup NceShortcut
	autocmd!
	autocmd BufEnter NCE:Lesson nnoremap <silent><buffer> <C-d> :call feedkeys(":Dict ", "n")<CR>
	autocmd BufEnter NCE:Lesson nnoremap <silent><buffer> <C-a> :NCEAIToggle<CR>
	autocmd BufEnter NCEAI nnoremap <silent><buffer> <C-a> :NCEAIToggle<CR>
	autocmd BufEnter NCE:Lesson nnoremap <silent> <buffer> c :call nce#ai#ClearCurrent()<CR>
augroup END

command! -nargs=1 -complete=customlist,nce#reader#CompleteSession NR NCEReader
command! -nargs=1 -complete=customlist,nce#reader#CompleteBook NRB NCEReaderPage <args>
command! -nargs=+ NRP NCEReaderPage <args>
command! -nargs=0 NRS NCEReaderShot
