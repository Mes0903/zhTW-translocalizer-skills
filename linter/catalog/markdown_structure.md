# Markdown 區塊與換行

L001 與 L002 共用段落掃描。 L002 檢查至少兩行的 prose 段落。 L001 另要求至少三行、每行 8 至 60 個可見字，以及至少兩行具有句末標記。 同段重疊時合成一項診斷，各理由保留原 ID 與狀態。 `spec` 排除 L002，L001 仍可執行

本目錄保存各 ID 的判準、來源條款、提示與風險說明。 執行時的規則狀態與訊息保存在 `linter/data/rule-map.json`，詞表保存在 `linter/data/lexicons.json`

### L001 `sentence_per_line_artifact`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 4.1
- signal：正式輸出殘留 sentence-per-line 或 extraction 痕跡
- detection strategy：連續短行、每行都像完整句、無正常段落結構
- needs source context：否
- auxiliary inputs：無
- warning message：`可能殘留 sentence-per-line / extraction artifact，建議改回正常段落`
- false positive risk：中
- autofix：否

### L002 `prose_hard_wrap_without_blank_line`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 4.1
- signal：一般 prose 只換行、不留空行
- detection strategy：非 list / 非 code / 非 table 的相鄰兩行共同構成一段
- needs source context：否
- auxiliary inputs：無
- warning message：`一般 prose 不應只換行不分段，請合併成單段或補空行`
- false positive risk：低
- autofix：可考慮

### L003 `colon_followed_by_list_without_blank_line`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 3.5、4.1
- signal：一般段落用全形 `：` 引出清單，但冒號後未留空行
- detection strategy：段落行以 `：` 結尾，下一個非空行為 top-level list item
- needs source context：否
- auxiliary inputs：無
- warning message：`一般段落以全形冒號引出清單時，冒號後應保留空行`
- false positive risk：低
- autofix：可考慮

### L004 `extra_blank_lines_between_list_items`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 4.1
- signal：相鄰 list item 間多出空行，或 list item 和巢狀清單之間多出空行
- detection strategy：list block 內的空行模式檢查，長 bibliography item 之間的分隔空行可視情況放行
- needs source context：否
- auxiliary inputs：無
- warning message：`相鄰 list item 或巢狀清單前不應有多餘空行`
- false positive risk：低
- autofix：可考慮

### L005 `raw_html_presentational_wrapper`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 4.2、5.2
- signal：保留純呈現用 HTML wrapper
- detection strategy：檢查常見 wrapper tag、inline style、style block
- needs source context：否
- auxiliary inputs：常見 presentational tag / attribute 清單
- warning message：`偵測到純呈現層 HTML / CSS，應改為 Markdown 或移除`
- false positive risk：中
- autofix：否
- runtime note：目前預設停用。 若要檢查，請用 `--rules L005` 手動開啟

### L014 `missing_eof_newline`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 4.1
- signal：非空 Markdown 檔案沒有以 EOF newline 結尾
- detection strategy：檢查檔案原始內容最後一個 byte 是否為 `\n`
- needs source context：否
- auxiliary inputs：無
- warning message：`檔案結尾應保留 EOF newline，請在文末補上一個換行`
- false positive risk：低
- autofix：可考慮

### L036 `top_level_code_fence_missing_surrounding_blank_line`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 4.1
- signal：一般 top-level code fence 前一行或後一行不是空行
- detection strategy：逐行追蹤 fenced code block 的 opening / closing fence。 只檢查沒有縮排的 top-level fence。 縮排在 list item 內的 fence 先放行，讓上下文決定是否需要空行。 若 code fence 直接貼著 custom container opener / closer，則由 custom container 的內側空行規則決定，不由本規則另外要求空行
- needs source context：否
- auxiliary inputs：無
- warning message：`一般 code block 前後應保留空行。 若位於 list item 內可依上下文省略`
- false positive risk：低
- autofix：可考慮

### L039 `custom_container_fence_formatting`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 4.1
- signal：三個以上 `:` 形成的 Markdown custom container / directive fence 沒有像 code fence 一樣獨立成行，例如 opener 黏了說明文字、closer 黏在 prose 行尾、opener 後或 closer 前多留空行
- detection strategy：逐行掃描非 code block 行的 `:{3,}` marker。 opener 允許任意非空 label token，但標準形式為 `:::label`。 closer 標準形式為 `:::`。 top-level container 外側比照 code fence 檢查空行，區塊內側不要求也不保留 opener 後與 closer 前的空行
- needs source context：否
- auxiliary inputs：無
- warning message：`Markdown custom container fence 應像 code fence 一樣獨立成行：opener/closer 不黏內容，區塊內側不多留空行`
- false positive risk：中
- autofix：可考慮

