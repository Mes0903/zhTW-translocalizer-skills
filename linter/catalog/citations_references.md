# 引用、書目與連結

本目錄保存各 ID 的判準、來源條款、提示與風險說明。 執行時的規則狀態與訊息保存在 `linter/data/rule-map.json`，詞表保存在 `linter/data/lexicons.json`

### L015 `academic_citation_missing_reference_section`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 4.3
- signal：正文已使用 academic citation apparatus，但缺少對應的 reference section，或正文 citation 與 reference block 明顯不成對
- detection strategy：解析 `<sup>...</sup>` 內的 formal citation link，例如 `<sup>[[L09]](#7)</sup>` 或 `<sup>[[L09]](#7), [[S09]](#14)</sup>`，再檢查是否同時存在 `## 引用文獻` / `## References` 與 `- <a id="7">[L09]</a>` 這類 anchor entry。 單獨存在 reference heading 不直接視為命中
- needs source context：否
- auxiliary inputs：無
- warning message：`academic citation apparatus 似乎不完整，請檢查正文標記與 reference section 是否成對出現`
- false positive risk：低
- autofix：部分可行

### L016 `academic_citation_broken_mapping`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 4.3
- signal：正文 formal citation 的顯示 label / target 與文末 anchor entry 對不上，例如 `[[L09]](#7)` 指到的 entry 不是 `[L09]`，或引用 target 根本不存在
- detection strategy：收集正文 `<sup>...</sup>` 內所有 `[[label]](#target)`，再比對 `References` 區段中的 `- <a id="target">[label]</a>`。 會檢查缺漏、重複 anchor id、重複 label 與 label-target mismatch。 單純存在未被正文引用的 reference entry 不算 warning
- needs source context：否
- auxiliary inputs：無
- warning message：`citation 編號與 reference list 可能沒有一一對上，請檢查缺漏、重複項或 id 與顯示編號不一致`
- false positive risk：低
- autofix：部分可行

### L042 `tracking_query_parameter_in_markdown_link`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 4.4
- signal：Markdown link URL 內含外部來源或廣告追蹤 query 參數，例如 `fbclid`、`utm_source=chatgpt.com`、`utm_*`、`gclid`、`msclkid`
- detection strategy：解析非 image 的 inline Markdown link，只檢查 URL 的 query string，不檢查 fragment。 若 query parameter 名稱屬 tracking 參數，則發 warning。 `#:~:text=...`、`#section` 等 fragment 保留不視為 tracking
- needs source context：否
- auxiliary inputs：tracking query parameter 名單
- warning message：`Markdown link URL 不應保留 fbclid、utm_* 等外部來源追蹤參數，請只保留原始連結`
- false positive risk：低
- autofix：可行

### L055 `bibliography_entry_structure`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 4.3
- signal：formal `References` entry 把 bibliographic 主行、URL 與中文說明擠在同一行，或把 URL 和說明塞進同一個子列點
- detection strategy：只檢查 `## 引用文獻` / `## References` 區段。 top-level reference item 若主行含 URL、Markdown link 或 CJK 內容就發 warning。 子列點若含 URL 但不是純 URL 單行，也發 warning。 URL 子列點只接受裸 URL，不接受 `網址：...`、`Available at: ...` 或 URL 後面殘留說明文字
- needs source context：否
- auxiliary inputs：reference-section 邊界判定、URL 偵測
- warning message：`formal reference entry 的 bibliographic 主行、URL 子列點與中文說明應分開，不要把它們擠在同一行或同一個子列點`
- false positive risk：低
- autofix：部分可行

### L056 `bibliography_initials_spacing`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 4.3
- signal：bibliography 主行的人名 initials 黏在一起，例如 `D.B.G. Edwards`、`M.J. Lanigan`、`Edward L.Glaser`
- detection strategy：只檢查 `References` 區段的 bibliographic 主行，搜尋 `A.B` / `A.Bc` 類黏連 initials 樣式
- needs source context：否
- auxiliary inputs：reference-entry 邊界判定
- warning message：`bibliography 主行的人名縮寫建議寫成「A. B. C. Surname」，不要把 initials 黏在一起`
- false positive risk：中
- autofix：可行

### L057 `bibliography_abbreviation_number_spacing`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 4.3
- signal：bibliography 主行出現 `Vol.15`、`No.3`、`p.12`、`pp.45-52` 這類縮寫後直接黏數字
- detection strategy：只檢查 `References` 區段的 bibliographic 主行，搜尋 `Vol.` / `No.` / `p.` / `pp.` 後方直接接數字的樣式
- needs source context：否
- auxiliary inputs：reference-entry 邊界判定
- warning message：`bibliography 主行中的 `Vol.` / `No.` / `p.` / `pp.` 若後面接數字，縮寫後應保留半形空格`
- false positive risk：低
- autofix：可行

### L058 `bibliography_year_shorthand_spacing`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 4.3
- signal：年份簡寫 `'95`、`'02` 直接黏在前一個字後面，例如 `USENIX ATC'95`
- detection strategy：只檢查 `References` 區段的 bibliographic 主行，搜尋英數字元後直接接 `'` 與兩位數年份的樣式
- needs source context：否
- auxiliary inputs：reference-entry 邊界判定
- warning message：`年份簡寫如 `'95` 前通常要有半形空格，例如 `USENIX ATC '95``
- false positive risk：低
- autofix：可行

### L059 `bibliography_possessive_apostrophe_spacing`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 4.3
- signal：英文所有格 `'s` 前面多了一格空白，例如 `Developer 's Manuals`
- detection strategy：只檢查 `References` 區段的 bibliographic 主行，搜尋 `word 's` 樣式
- needs source context：否
- auxiliary inputs：reference-entry 邊界判定
- warning message：`英文所有格 `'s` 應直接接在前一個字後面，例如 `Developer's Manuals``
- false positive risk：低
- autofix：可行

### L060 `bibliography_curly_quotes_or_apostrophes`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 4.3
- signal：bibliography 主行保留英文引號或 apostrophe 時用了彎引號 / 彎 apostrophe，例如 `“Title”`、`O’Hallaron`
- detection strategy：只檢查 `References` 區段的 bibliographic 主行，搜尋 `“”‘’`
- needs source context：否
- auxiliary inputs：reference-entry 邊界判定
- warning message：`bibliography 主行保留英文引號時，請使用 ASCII `"` 與 `'`，不要使用彎引號或彎 apostrophe`
- false positive risk：低
- autofix：可行

### L061 `bibliography_explanation_uses_chinese_punctuation`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 4.3
- signal：`References` 中文說明子列點混入英文半形標點，例如 `時, OSSpinLock ...`，或整行以半形 `.` 收尾
- detection strategy：只檢查 `## 引用文獻` / `## References` 區段中「不是純 URL」且含 CJK 的子列點。 若半形 `,` / `:` / `;` 的前後非空白鄰接字元有任一側是 CJK，或最後一個非空白字元是半形 `.`，就發 warning
- needs source context：否
- auxiliary inputs：reference-section 邊界判定、URL 子列點排除
- warning message：`References 的中文說明子列點應使用中文標點，避免半形 `,` / `:` / `;`，且一般不以半形 `.` 收尾`
- false positive risk：低
- autofix：部分可行
- runtime note：`References` 中文說明子列點現在視同一般中文 prose，因此除了本條外，也會套用 `prose_lines()` 系列規則，例如 `L023`、`L024`、`L044`

