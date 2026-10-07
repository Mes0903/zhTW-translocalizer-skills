# 臺灣用語、術語與雙語一致性

本目錄保存各 ID 的判準、來源條款、提示與風險說明。 執行時的規則狀態與訊息保存在 `linter/data/rule-map.json`，詞表保存在 `linter/data/lexicons.json`

### L022 `simplified_chinese_present`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 3.7
- signal：正式輸出出現簡體中文字形
- detection strategy：使用簡繁差異字表或正規化詞典掃描 prose，排除 code / path / quote literal
- needs source context：否
- auxiliary inputs：簡繁對照表
- warning message：`偵測到疑似簡體中文寫法，請改回繁體臺灣用語`
- false positive risk：低
- autofix：部分可行

### L030 `repeated_bilingual_term_pair`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 1.3
- signal：同一個 `中文（English）` 或 `English（中文）` 雙語對在檔內反覆完整重複
- detection strategy：收集 term-like 雙語對樣式，偵測第二次以上的完全重複，排除 glossary table、索引或術語表段落
- needs source context：否
- auxiliary inputs：無
- warning message：`這個雙語術語已經介紹過，後文通常應固定單一形式，不必重複整組雙語對`
- false positive risk：低
- autofix：部分可行

### L031 `term_form_drift_after_first_bilingual`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 1.3
- signal：某個術語首次雙語後，後文在 English-only、Chinese-only 與另一個中文變體之間漂移
- detection strategy：先收集首次 term-like 雙語對，再比對後續同一 English token 周圍是否出現多個不一致的中文候選或反覆切換單雙語形式
- needs source context：否
- auxiliary inputs：可選的 term normalization、project-local glossary、global glossary
- warning message：`這個術語在首次介紹後可能出現形式漂移，請固定 downstream form`
- false positive risk：高
- autofix：否

### L032 `glossary_preferred_form_mismatch`

- 狀態：lint-ready
- owner spec：`references/glossary.md`、`references/workflow.md` 3.1、3.4、`references/output_grammar.md` 1.1、1.3
- signal：術語用法與 project-local glossary 或 global glossary 的偏好映射衝突
- detection strategy：優先載入 project-local glossary，再 fallback 到 global glossary。 對 exact match 或 normalized term 做比對，排除 code identifier、path、label 與非 term-like 雙語對
- needs source context：否
- auxiliary inputs：project-local glossary、global glossary
- warning message：`這個術語可能偏離 glossary 的既有穩定譯法，請檢查是否應回到既有映射`
- false positive risk：高
- autofix：否

### L033 `unexpanded_workspace_jargon`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.10、`references/output_style.md` 3
- signal：`參考依據`、`規則優先序`、`術語邊界`、`工作模式`、`開工前檢查關卡`、`baseline` 等內部術語首次出現時沒有展開
- detection strategy：維護 jargon 名單。 偵測首次出現後同句或下一句是否缺少展開訊號，如 `指的是`、`也就是`、`例如`、`會`、`用來`、具體檔名、路徑或 rule id
- needs source context：否
- auxiliary inputs：workspace jargon 名單
- warning message：`這個內部術語首次出現時可能沒有展開，請補一句白話說明或具體例子`
- false positive risk：中
- autofix：否

### L035 `huixie_lexical_misuse_outside_write_back_term`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 2.9、`references/glossary.md`
- signal：把 `回寫` 當成一般 workflow 或寫入動詞使用，而不是 `write-back` 類術語
- detection strategy：偵測 prose line 中的 `回寫`。 若同句沒有 `write-back`、`回寫快取`、`回寫策略`、`快取回寫` 等術語訊號，就警告
- needs source context：否
- auxiliary inputs：`write-back` 術語白名單
- warning message：`「回寫」通常保留給 write-back 類技術術語。 若這裡只是一般寫入、寫回或更新動作，建議改成更精確的詞`
- false positive risk：中
- autofix：否

### L046 `bilingual_term_chinese_first`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 1.3
- signal：中文上下文中的一般雙語術語寫成 `English（中文）`，例如 `Direct Proof（直接證明）`
- detection strategy：解析非 image、非 code、非 table 的可見文字行，包含一般段落、list item、heading 與 blockquote。 若全形括號外層是英文、括號內層是 term-like 中文，則發 warning
- needs source context：否
- auxiliary inputs：雙語術語抽取器、中文 term-like 判定器
- warning message：`中文上下文中的雙語術語應寫成「中文（English）」。 若不是 true name / label / token，請調整順序`
- false positive risk：中。 true name / label / token 本身必須以英文為主形時可人工放行
- autofix：可考慮

### L053 `preferred_taiwan_technical_terms`

- 狀態：lint-ready
- owner spec：`references/preferred_taiwan_terms.md`、`references/output_grammar.md` 1.1、3.7
- signal：中文技術 prose 使用了 workspace 中文用詞偏好表中標成避免使用或高風險漂移的詞，例如 `當前`、`物理位址`、`命令行`、`程序`、`訪問`、`代碼`
- detection strategy：逐行掃描非 code / 非 tag / 非 directive 的可見文字，排除 inline code 與 Markdown image。 字面明確的詞直接警告。 語境型詞加上啟發式例外，例如 `分配` 只在記憶體配置語境警告，`通過` 會放行 `通過測試` 類 pass 用法，`個核心` 只在前方像數量詞時提示，`場景` 只在 IT 語境提示，`設備 / 程序 / 異常 / 地址` 則只在硬體、process、exception、memory-address 類語境警告
- needs source context：部分需要。 沒有 source context 時只提示人工確認，不做 autofix
- auxiliary inputs：workspace 用詞偏好表、少量語境白名單
- warning message：`「X」建議改為「Y」。 必要時附語境說明`
- false positive risk：中。 `設備`、`程序`、`異常`、`地址` 等詞在非目標語境可能正確，需人工判斷
- autofix：否

### L054 `bare_english_drift_after_bilingual_anchor`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 1.2、1.3
- signal：某術語首次以 `中文（English）` 介紹後，下游在中文語境中又直接滑回 bare English
- detection strategy：先記錄 document 內首次出現的 `中文（English）` anchor，再往後掃描非 code / 非 table / 非 heading 的可見文字行。 若 bare English 出現在 CJK 鄰接語境就發 warning。 目前支援單字、多詞與含數字的 English term，例如 `scheduler`、`Direct Proof`、`L1 cache`。 inline code、重複的 `中文（English）`、URL / path / code-like token，以及 acronym-heavy English anchor（如 `SIMD`、`PTX`、`CUDA`）不納入此規則
- needs source context：否
- auxiliary inputs：雙語術語抽取器、bare English boundary matcher
- warning message：`這個英文詞在首次雙語介紹後又在中文語境中出現成 bare English，請確認下游是否固定用中文單一形式`
- false positive risk：中
- autofix：否

