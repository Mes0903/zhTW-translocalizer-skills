# 引號、標點與括號字形

本目錄保存各 ID 的判準、來源條款、提示與風險說明。 執行時的規則狀態與訊息保存在 `linter/data/rule-map.json`，詞表保存在 `linter/data/lexicons.json`

### L023 `ascii_quote_in_cjk_prose`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 3.2
- signal：中文 prose 用 ASCII 雙引號標示中文引文或強調
- detection strategy：比對 `\"...\"` 包住 CJK 內容的樣式，排除 code span、literal config 與 JSON
- needs source context：否
- auxiliary inputs：可選的 code-context 排除器
- warning message：`中文 prose 的引號建議使用「」或『』，不要直接沿用 ASCII 雙引號`
- false positive risk：中
- autofix：部分可行

### L024 `halfwidth_punctuation_in_cjk_prose`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 3.1
- signal：中文 prose 中用半形 `,` `:` `;` 承擔一般標點或清單引介功能
- detection strategy：偵測 CJK 字元之間、或 CJK 句末引介 list 時的半形標點，排除時間、URL、path、code span、數值格式
- needs source context：否
- auxiliary inputs：時間 / path / URL 白名單
- warning message：`中文 prose 可能誤用了半形標點，請檢查是否應改成全形中文標點`
- false positive risk：中
- autofix：部分可行

### L025 `halfwidth_parentheses_without_spacing`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 3.2、3.3
- signal：半形括號出現在中文 prose 中，但括號與周圍中文之間沒有半形空格
- detection strategy：偵測 `中(`、`)文`、`中(English)` 這類鄰接樣式，排除 code / path 與 Markdown link 的 URL 括號
- needs source context：否
- auxiliary inputs：無
- warning message：`半形括號若出現在中文 prose 中，括號與周圍中文之間應保留半形空格。 注意：本 workspace 的標準修法是改成全形括號（見 L044），本條僅在選擇保留半形括號時使用`
- false positive risk：低
- autofix：部分可行
- runtime note：目前預設停用。 本 workspace 的標準修法是把半形括號改成全形（由 `L044` 處理），若刻意保留半形括號才用 `--rules L025` 手動開啟

### L026 `fullwidth_parentheses_around_code_like_latin`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 3.2
- signal：非中文 prose 上下文中，全形括號包住 code-like 純英文、數字或符號內容
- detection strategy：偵測 `（...）` 內部只含 code-like ASCII token 的樣式。 Markdown 圖片 caption 行與含 CJK 的中文 prose 行不檢查，中文上下文中的括號樣式由 L044 管
- needs source context：否
- auxiliary inputs：code-like token 判定器
- warning message：`code-like 純英文、數字或符號內容建議改用半形括號`
- false positive risk：中
- autofix：部分可行

### L044 `halfwidth_parentheses_in_cjk_prose_context`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 3.2
- signal：中文 Markdown prose 或 list item 中使用可見半形括號作補充說明，例如 `bit(lowest-order bit of the first byte)` 或 `環境上 (mingw-gcc 11.2.0)`
- detection strategy：解析非 image 的 prose / list item，略過 inline code、inline math 與 Markdown link URL。 若整行含 CJK，且半形括號不是明確 function call / raw syntax 或 standalone URL 形狀，則發 warning。 Markdown link 外層補充括號不視為 standalone URL 例外
- needs source context：否
- auxiliary inputs：function call / raw syntax 判定器
- warning message：`中文 prose 上下文中的補充括號建議使用全形括號`
- false positive risk：中
- autofix：可考慮

### L049 `halfwidth_exclamation_question_in_cjk_prose`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 3.1
- signal：中文 prose 中的 `!` 與 `?` 使用半形而非全形「！」「？」
- detection strategy：逐 codepoint 掃描非 code / 非 table / 非 heading / 非 blockquote 的 prose 與 list item，排除 inline code 與 Markdown image。 若 `!` 或 `?` 前後兩側皆為 CJK 字元，或前為 CJK 且後續無內容，就發 warning
- needs source context：否
- auxiliary inputs：無
- warning message：`中文 prose 的 !/? 建議使用全形「！」「？」`
- false positive risk：低
- autofix：部分可行

### L050 `curly_double_quote_in_cjk_prose`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 3.2
- signal：中文 prose 使用全形彎引號 `“…”`（U+201C / U+201D）包住中文內容，而非臺灣慣用的「」或『』
- detection strategy：逐行搜尋 `“` 與配對的 `”`，若引號內含 CJK 字元就發 warning，排除 inline code 與 Markdown image
- needs source context：否
- auxiliary inputs：無
- warning message：`中文 prose 的引號建議使用「」或『』，不要使用全形彎引號「“”」`
- false positive risk：低
- autofix：部分可行

