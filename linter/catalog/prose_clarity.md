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
- warning message：`這段教學式說明可能理論負載過高，請先交代理解所需的背景與問題，再介紹核心規則、進階條件與例外`
- false positive risk：高
- autofix：否

### L137 `unsolicited_assurance_or_exclusion_candidate`

- 狀態：lint-hybrid
- owner spec：`references/output_style.md` 3
- signal：閱讀本文不必離開或另查文件、各階段無須各建類別，以及原有目錄、使用者修改或既有檔案未遭覆寫等保證／排除句型
- detection strategy：在可見正文逐行匹配有限詞形與有限距離。 閱讀類句型需同時出現閱讀／理解／讀者、免除需要及離開本文／另開其他文件等訊號。 類別句型需同時有無須／不要求、逐一配置及建立類別。 保留類句型需有原有檔案、文章目錄或使用者修改，以及未覆寫／更動。 定位在否定訊號起點，以 Unicode code point 計欄
- needs source context：是
- auxiliary inputs：相鄰正文、來源位置、使用者的具體提問
- warning message：`這句可能附加保證或排除內容，請核對這項補充的任務用途與來源，保留時記錄具體理由`
- false positive risk：高。 使用者要求確認是否保留檔案，或來源明示相同限制時，表面句型仍會命中。 審閱者應以 `kept-with-reason` 記錄依據。 例如使用者明問修改是否保留時，可以保留「原本的文章目錄與使用者修改沒有被覆寫」
- autofix：否

L137 不掃描所有 `不`、`沒`、`未` 或獨立 `不會`。 `此函式不修改輸入資料`、`尚未凍結為實作 spec`、`未執行測試` 等必要否定可正常使用。 窄模式也會漏掉換詞、跨行拆開的保證、沒有上述實體詞的排除句。 完整判斷仍依來源與任務用途完成

### L138 `article_or_section_opening_orientation_candidate`

- 狀態：lint-hybrid
- owner spec：`references/output_style.md` 4.1
- signal：文章及每個 ATX（井號）標題之後，首個可見正文段落的首句為泛稱觀看指令，或以作者／本章將依次介紹多項主題的行程預告開始
- detection strategy：沿用行分類，跳過 metadata、程式碼、表格、區塊引用、列表與結構標記。 首個有可見文字的正文段落形成檢查位置。 每個 ATX 標題會重新開始判定。 泛稱指令需首句符合有限詞形，例如 `先看一個可見的事件。`。 行程預告需首句同時符合本章／我們等前綴、先／從、介紹／建立等動作及至少三項的列舉形狀。 單純句子短或出現 `先` 不會命中
- needs source context：是
- auxiliary inputs：相鄰章節、文章目的、讀者背景、來源與任務要求
- warning message：`這個文章或章節開頭可能只有觀看指令或行程預告，請核對上下文、來源與任務所需的問題、對象及背景`
- false positive risk：高。 來源刻意使用導覽，或前章已給足背景時仍可能命中。 審閱者需記錄具體理由保留
- autofix：否

`快取會保存近期讀取的資料。` 與 `先驗證權杖，再寫入資料` 不符合這兩種表面形狀。 首段已有主題句，下一段才出現導覽時不會命中。 同段先有主題句再列導覽也不會命中。 泛稱觀看指令後同段接上檔名、命令或其他句子時，首句仍會提示人工檢查。 同段後續提供了實質背景時，也由審閱者判斷該首句是否有必要，並可附理由保留。 加上 `因為` 或 `問題` 等字眼也不會自動解除首句行程預告候選

兩條規則共用字元等長遮罩，保護 inline code、現有 parser 可辨認的連結目的地、簡單自動連結、參照式連結定義、HTML comment 與成對引號。 顯式 `例如：`、`例句：`、`範例：` 等行首標記所在行視為例句。 L137 會檢查可見連結標籤。 L138 的首句若完整包在連結標籤內，仍可能漏報。 多行引號與 comment 會延續遮罩。 未閉合引號可能遮住後續正文。 未明示的例子、複雜 Markdown 與跨行句型仍可能誤報或漏報，須由審閱者核對

L138 目前以 ATX（井號）標題辨認章節起點。 Setext（底線式）標題、只列兩項的導覽，以及有限詞形以外的開頭，沿 style 4.1 重新閱讀時檢查
