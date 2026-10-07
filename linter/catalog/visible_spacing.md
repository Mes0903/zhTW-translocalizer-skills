# 可見文字邊界與空格

本目錄保存各 ID 的判準、來源條款、提示與風險說明。 執行時的規則狀態與訊息保存在 `linter/data/rule-map.json`，詞表保存在 `linter/data/lexicons.json`

### L037 `missing_space_after_sentence_punctuation`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 3.4
- signal：同一 Markdown 行內的 `。`、`？`、`；` 後面還有後續 prose，但中間沒有半形空格
- detection strategy：掃描非 code / 非 table / 非 heading / 非 blockquote 的 prose 與 list item，排除 inline code 內的標點。 若標點後先接閉括號，會跳過閉合符號後再檢查是否有半形空格。 若標點後先接中文閉引號，則視為引文內標點，不要求引號外側空格，交由 L051 檢查中文引號貼合。 若後面緊接全形逗號、頓號或其他中文標點，則不要求額外空格
- needs source context：否
- auxiliary inputs：無
- warning message：`同一行內的句號、問號、分號後若還有後續 prose，應保留一個半形空格`
- false positive risk：低
- autofix：可考慮

### L038 `missing_space_between_cjk_and_latin_or_number`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 3.3
- signal：中文 prose 或 list item 中，CJK 字元與獨立拉丁字詞 / 阿拉伯數字直接相鄰
- detection strategy：逐字掃描 masked_text 的相鄰 codepoint，偵測 `中文API`、`API呼叫`、`中文2`、`2中文`、`第10`、`3個` 類型。 排除 inline code、Markdown image、code block、table、heading、blockquote、tag/directive。 含 URL / path / email / code identifier 特徵的 ASCII token 先放行。 Markdown link 與外側文字的邊界空格由 L040 檢查
- needs source context：否
- auxiliary inputs：URL / path / code identifier 白名單
- warning message：`中文與獨立拉丁字詞或阿拉伯數字之間一般應保留一個半形空格`
- false positive risk：中
- autofix：部分可行

### L040 `markdown_link_spacing_follows_visible_label`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 4.4
- signal：Markdown link 前後空格沒有依照 `[]` 內的 visible label 判斷，例如 `[論文](...) 在` 多了空格，或 `看[draft](...)版本` 少了空格
- detection strategy：解析非 image 的 inline Markdown link，忽略 URL，只取 label 的第一個與最後一個可見 CJK / ASCII token 邊界。 若 label 邊界與外側文字為中英相接，要求一個半形空格。 若為中文連中文，要求不留空格
- needs source context：否
- auxiliary inputs：無
- warning message：`Markdown link 前後空格應以 [] 內的可見文字判斷。 中文連中文不留空格，中英相接才留空格`
- false positive risk：中
- autofix：可考慮

### L041 `halfwidth_spaces_around_fullwidth_comma`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 3.1、3.3
- signal：全形逗號 `，` 前或後有半形空格
- detection strategy：逐字掃描非 code / 非 table / 非 heading / 非 blockquote 的 prose 與 list item，排除 inline code 與 Markdown image。 若 `，` 前後直接接半形空格就發 warning
- needs source context：否
- auxiliary inputs：無
- warning message：`全形逗號前後不應有半形空格`
- false positive risk：低
- autofix：可行

### L045 `spaces_around_fullwidth_parentheses`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 3.2
- signal：中文 Markdown 可見文字行中，全形括號前後仍保留半形空格，例如 `環境上 （mingw-gcc 11.2.0） 也是`
- detection strategy：解析非 image、非 code 的可見文字行，包含一般段落、list item、heading、blockquote 與 table。 若全形 `（` 前一字元是半形空格，或全形 `）` 後一字元是半形空格，則發 warning。 若該空格是 `。`、`？`、`；` 後的同一行句界空格，則交由 L037 處理並允許保留
- needs source context：否
- auxiliary inputs：無
- warning message：`全形括號前後不應保留半形空格`
- false positive risk：低
- autofix：可行

### L047 `halfwidth_space_between_cjk`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 3.3
- signal：中文可見文字行中，兩個 CJK 字元之間殘留半形空格，例如 `我 們`、`測試 結果`
- detection strategy：解析非 image、非 code 的可見文字行，包含一般段落、list item、heading、blockquote 與 table。 若某半形空格左右兩側都是 CJK 字元，則發 warning。 不影響中英 / 中數之間正常的半形空格
- needs source context：否
- auxiliary inputs：無
- warning message：`中文與中文之間不應殘留半形空格`
- false positive risk：低
- autofix：可行

### L048 `spaces_around_title_marks`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 3.2
- signal：中文書名號 `《》` 或章名號 `〈〉` 內外側殘留半形空格，例如 `請看 《手冊》`、`《 第一章 》`
- detection strategy：解析非 image、非 code、非 table 的可見文字行。 若開標前後或閉標前後直接接半形空格就發 warning
- needs source context：否
- auxiliary inputs：無
- warning message：`書名號《》與章名號〈〉內外側不應保留半形空格`
- false positive risk：低
- autofix：可行

### L051 `spaces_around_fullwidth_quotes`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 3.2
- signal：中文引號 `「」` 或 `『』` 內外側殘留半形空格，例如 `計算 「平均」搜尋距離`、`「誰最先提出？」 這個問題`
- detection strategy：逐字掃描非 code / 非 tag / 非 directive 的可見文字行，排除 inline code、inline math、Markdown link URL 與 Markdown image。 若開引號前後或閉引號前後直接接半形空格就發 warning，但允許 list marker / blockquote marker / heading marker 後接開引號的必要語法空格
- needs source context：否
- auxiliary inputs：無
- warning message：`中文引號「」與『』內外側不應保留半形空格`
- false positive risk：低
- autofix：可行

### L052 `internal_consecutive_halfwidth_spaces`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 4.1
- signal：一般 prose 行內出現連續兩個半形空白，例如 `而  \`poll()\` 系統呼叫`
- detection strategy：逐字掃描非 code / 非 tag / 非 directive 的可見文字行，排除 table、blockquote、Markdown image、inline code、inline math 與 Markdown link URL。 只檢查前後都有非空白內容的行內空白，因此不會把 list continuation 的前導縮排或行尾 hard-break 空白當成此規則的 warning。 display math / LaTeX block 在 parser 中歸為 code-like 區塊，不由本規則檢查
- needs source context：否
- auxiliary inputs：無
- warning message：`一般 prose 行內不應出現連續兩個半形空白`
- false positive risk：低
- autofix：可行

