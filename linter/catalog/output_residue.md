# 正式輸出殘留

本目錄保存各 ID 的判準、來源條款、提示與風險說明。 執行時的規則狀態與訊息保存在 `linter/data/rule-map.json`，詞表保存在 `linter/data/lexicons.json`

### L006 `source_extraction_artifact_leftover`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 4.2、5.2
- signal：正式輸出殘留來源抽取產生的頁碼或 `_page_` 類中介檔名
- detection strategy：檔名樣式與頁碼樣式。 一般 Markdown 圖片語法不算命中
- needs source context：否
- auxiliary inputs：來源抽取 artifact 樣式清單
- warning message：`偵測到來源抽取中介痕跡，正式輸出不應保留`
- false positive risk：中
- autofix：部分可行

### L017 `preflight_or_selfcheck_leftover`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 5.2、`references/workflow.md` 5.1、5.2
- signal：正式輸出殘留 `開工前檢查`、`preflight`、`自檢`、`驗證關卡`、`TODO` 等工作中介區塊
- detection strategy：掃描 heading、blockquote、task note 與 checklist 項中的 meta-work 關鍵詞
- needs source context：否
- auxiliary inputs：可選的允許標題白名單
- warning message：`正式輸出不應保留 preflight / 自檢 / TODO 類中介區塊`
- false positive risk：中
- autofix：否

### L018 `dialogue_trace_leftover`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 5.2
- signal：正式輸出殘留對話痕跡，如 `使用者：`、`assistant:`、`user:`、`system:`
- detection strategy：行首角色標籤樣式比對，排除 code fence
- needs source context：否
- auxiliary inputs：無
- warning message：`正式輸出不應保留對話痕跡或角色標籤`
- false positive risk：低
- autofix：部分可行

### L019 `source_text_block_leftover`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 5.2
- signal：正式輸出殘留 `原文`、`source text`、`譯文對照`、雙欄對照或原文區塊
- detection strategy：heading / label 關鍵詞比對，搭配相鄰區塊是否出現 quoted source、雙語成對段落或 `原文：` / `譯文：` 樣式
- needs source context：是
- auxiliary inputs：output contract、是否允許雙語對照 artifact
- warning message：`正式輸出可能殘留原文或對照區塊，請確認這不是中介草稿內容`
- false positive risk：中
- autofix：否

### L130 `internal_control_label_leaked_into_formal_prose`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.10、`references/output_style.md` 3
- signal：直接把內部 workflow 控制標籤寫進正式中文，例如用 `前一輪已確認的決定`、`這次輸出要交付的內容`、`遇到規則衝突時先停下確認` 這類標籤化說法取代完整句子
- detection strategy：掃描可見 prose line。 若命中內部控制詞名單，就警告使用者改成完整句子，說明誰在什麼情況下做什麼
- needs source context：否
- auxiliary inputs：內部控制詞名單
- warning message：`這裡可能把內部 workflow 控制詞直接寫進正式中文，建議改成完整句子，說明誰在什麼情況下做什麼`
- false positive risk：中
- autofix：否

