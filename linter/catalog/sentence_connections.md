# 句讀、列舉與連接詞

本目錄保存各 ID 的判準、來源條款、提示與風險說明。 執行時的規則狀態與訊息保存在 `linter/data/rule-map.json`，詞表保存在 `linter/data/lexicons.json`

### L021 `semicolon_overuse`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 3.5
- signal：prose 過度依賴分號串接子句，或短句中出現低價值的單一分號
- detection strategy：偵測一般 prose line 與 list item 中的 `；` / `;` 數量。 若有兩個以上就直接警告，包含可能合法的平行列舉。 單一分號則只在短句且前後都像完整子句時警告
- needs source context：否
- auxiliary inputs：分號次數門檻
- warning message：`這裡的分號可能沒有必要，若不是平行列舉同一目的下的不同對象，請拆句、改逗號或重寫`
- false positive risk：中。 平行列舉不同對象時，分號可能合法，warning 只要求 LLM 或人工複查
- autofix：否

### L027 `terminal_fullwidth_period_in_markdown_prose`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 3.4
- signal：Markdown 技術 prose 習慣省略段末全形句號，但段落或列點仍大量保留 `。`
- detection strategy：統計非引文、非 code、非 house-style override 區塊的句末 `。` 密度
- needs source context：否
- auxiliary inputs：task-local style override、file-level style profile
- warning message：`本 workspace 的 Markdown 技術 prose 通常省略段末句號，請檢查這裡是否需要保留`
- false positive risk：高
- autofix：否

### L028 `dash_as_punctuation`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 3.5
- signal：出現任何破折號（`──`、`—`、`–`）作為 prose 插入或中斷標記
- detection strategy：逐行掃描 masked_text，每個出現點都發 warning。 code block、inline code、blockquote 與 table 內不觸發
- needs source context：否
- auxiliary inputs：無
- warning message：`偵測到破折號，請改用逗號、冒號、括號、分句或重寫處理`
- false positive risk：低
- autofix：否

### L029 `inline_enumeration_without_final_conjunction`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 4.1
- signal：中文 prose 內的 inline enumeration 以 `A、B、C` 直接收尾，最後一項前沒有 `與 / 及 / 或`
- detection strategy：偵測三項以上的中文並列樣式，並接受最後一段中已用 `與 / 及 / 或` 接最後一項的寫法。 排除 literal code、field list、固定名稱與 raw data
- needs source context：否
- auxiliary inputs：固定搭配白名單
- warning message：`中文 prose 的行內列舉最後一項前通常建議補「與 / 及 / 或」，請檢查這裡是否需要`
- false positive risk：中
- autofix：部分可行

### L043 `terminal_continuation_punctuation`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 3.4
- signal：中文 Markdown prose 或 list item 句末以 `，`、`、`、`；`、`,`、`;` 等延續標點收尾
- detection strategy：由行尾往前找最後一個可見 prose 字元，略過空白、inline code、Markdown link URL 語法與閉引號 / 閉括號。 若最後可見句尾是延續標點就發 warning。 `：` 不在本規則內，因為常用來引出後續 code block、list 或說明
- needs source context：否
- auxiliary inputs：句尾延續標點名單、閉合符號名單
- warning message：`Markdown prose 句末不應以逗號、頓號或分號等延續標點收尾`
- false positive risk：低
- autofix：可行

### L125 `paired_conjunction_incomplete`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.8
- signal：高信號的對比 / 遞進型成對連接詞只出現一半，例如 `雖然`、`不但 / 不僅`
- detection strategy：在句內或相鄰分句視窗中做成對匹配，偵測 `雖然` 缺 `但 / 仍然`、`不但 / 不僅 / 不只` 缺 `而且 / 還 / 也` 等樣式。 `因為 / 由於`、`如果` 一類在自然中文中常可不補第二半，因此目前不直接由本規則發 warning
- needs source context：否
- auxiliary inputs：成對連接詞對照表
- warning message：`這裡的成對連接詞可能沒有補完整，請檢查中文的對比 / 因果骨架是否清楚`
- false positive risk：中
- autofix：否

### L126 `stacked_discourse_marker_chain`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 2.8
- signal：連續堆疊兩個以上 discourse marker，如 `因此所以`、`然而但是`
- detection strategy：掃描 clause 開頭或局部片語中的連接詞連續樣式，使用小型 discourse marker lexicon
- needs source context：否
- auxiliary inputs：連接詞詞表
- warning message：`這裡可能把連接詞堆成一串，請保留最小必要的一個就好`
- false positive risk：低
- autofix：部分可行

