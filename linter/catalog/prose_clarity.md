# 文風與說明負擔

本目錄保存各 ID 的判準、來源條款、提示與風險說明。 執行時的規則狀態與訊息保存在 `linter/data/rule-map.json`，詞表保存在 `linter/data/lexicons.json`

### L007 `anti_pattern_stock_phrase`

L007 提供固定句型的位置提示。 審閱者另依 [style 第 3 節](../../references/output_style.md#3-ai-腔與解說具體性)核對補充內容的來源與任務依據，包含附註、獨立否定句、跨句與跨段敘述。 保留時須指出來源明示的內容或使用者已提出的具體問題

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 2.10、`references/output_style.md` 3
- signal：使用 stock anti-pattern 句型，包括首段 bare opener（`不是`、`所謂`、`這也意味著`），以及文中任意位置的 paired `不是 / 並非……而是 / 其實 / 真正……` 與 `所謂……就是……`，還有 standalone 的 `這也意味著`
- detection strategy：首段前 12 col 的 bare prefix 匹配。 全文段落掃描 paired 與 standalone 片語，paired 需在同段落內同時命中前後兩半。 否定句加補充句的形式只抓明確 `不是 / 並非` 搭配 `而是 / 其實 / 真正`
- needs source context：否
- auxiliary inputs：無
- warning message：`偵測到 stock anti-pattern 句型，建議改為直接陳述`
- false positive risk：中
- autofix：否

### L020 `paragraph_too_dense`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 4.1
- signal：單段 prose 過長、過密
- detection strategy：對非 list / 非 code / 非 table 段落計算行數、長度與句子密度。 目前偏向抓很長段落、多個分號串接的段落，或四句以上且已達中長篇幅的高密度段落
- needs source context：否
- auxiliary inputs：段落長度門檻設定
- warning message：`這段可能過密，請檢查是否應拆段或重排資訊`
- false positive risk：中
- autofix：否

### L034 `taxonomy_only_summary`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.10、`references/output_style.md` 3
- signal：段落主要只列抽象分類名稱或像 `baseline` 這類內部術語，缺少具體檔案、規則、行為或例子
- detection strategy：段落內抽象名詞列表密度高，但缺少路徑、rule id、檔名、動作動詞或例子訊號時警告
- needs source context：否
- auxiliary inputs：抽象術語名單、具體錨點樣式
- warning message：`這段可能退化成純 taxonomy 摘要，請補一個具體檔案、規則、決策或例子`
- false positive risk：高
- autofix：否

### L134 `teaching_explanation_overloads_theory`

- 狀態：review-only
- owner spec：`references/output_style.md` 3
- signal：教學式說明一次塞入過多理論標籤、文獻背景或例外
- detection strategy：暫無穩定靜態檢查
- needs source context：是
- auxiliary inputs：task output contract、目標讀者、source scope
- warning message：`這段教學式說明可能理論負載過高，請先寫核心規則，再寫進階條件與例外`
- false positive risk：高
- autofix：否
