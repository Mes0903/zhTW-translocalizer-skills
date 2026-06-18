# zhTW-Translocalizer Lua Linter

本檔是 `scripts/lint.lua` 的 README，也是 linter 的 rule catalog 與偵測策略目錄。 它一方面說明 CLI 怎麼跑、warning 該怎麼解讀，另一方面保留了每條 `Lxxx` 規則目前使用的 surface signal、heuristic 與誤報風險，讓使用者與其他 LLM 都能快速判斷這個 linter 在檢查什麼

中文輸出規則本身不以本檔為準。 本 skill 的入口在根目錄的 `SKILL.md`

文法、句法、標點、Markdown、citation 與輸出污染看 `references/output_grammar.md`。 忠實度、自然化、語氣與段落節奏看 `references/output_style.md`

工作流程、術語與臺灣用語偏好則看 `references/workflow.md`、`references/glossary.md` 與 `references/preferred_taiwan_terms.md`。 本檔只負責記錄 lint rule 的定位、偵測策略、warning 介面與維護資訊

## 這個 linter 是什麼

- 這是一個 warning-only 的 Lua linter，不會發 `error`
- 它把檢查範圍分成幾個高階 domain：Markdown 結構與輸出污染、字形標點與 spacing、術語穩定與 glossary 對齊、中文句法與 function-word reread trigger
- 不少 `lint-hybrid` 規則本質上只是 reread trigger，因此它不是 prose 品質總分器，也不是規則正文
- `review-only` 條目會留在本檔當 backlog，但目前不會出現在 `--list-rules`
- 預設停用的規則目前有兩條：`L005 raw_html_presentational_wrapper`（CSS / HTML 標籤檢查）與 `L025 halfwidth_parentheses_without_spacing`（半形括號貼合中文）。 兩者都要靠 `--rules` 手動指定才會跑

## 位置

以下路徑皆以 skill root 為基準：

- CLI 入口：`scripts/lint.lua`
- 核心工具：`scripts/lintlib/core.lua`
- 規則註冊：`scripts/lintlib/rules.lua`
- smoke test：`scripts/lint_smoke.lua`

## 快速開始

以下命令假設目前工作目錄是 skill root。 若目前不在 skill root，請把 `scripts/lint.lua` 改成 `<skill-root>/scripts/lint.lua`，並依實際位置調整被檢查檔案的路徑：

- `lua5.4 scripts/lint.lua working/foo/output.md`
  - 用預設啟用的規則檢查這份 Markdown，輸出一般文字格式的 warning
- `lua5.4 scripts/lint.lua --format markdown working/foo/output.md`
  - 輸出 Markdown 報表，按檔案分組並把同一條 warning 合併成一列，列出所有 `Lx:Cy` 位置，適合人工 review 或直接存成報告
  - 建議使用此選項，輸出比較乾淨
- `lua5.4 scripts/lint.lua --format json working/foo/output.md`
  - 一樣跑 lint，但把結果改成 JSON，方便拿去接 editor 或其他自動化流程
- `lua5.4 scripts/lint.lua --rules L022,L032,L125 working/foo/output.md`
  - 只跑指定規則，適合局部複查某一批 warning
- `lua5.4 scripts/lint.lua --profile spec references/output_grammar.md references/output_style.md`
  - 對 spec / workflow / preflight 這類 meta 文件用 `spec` profile，先扣掉容易誤報的 workflow / taxonomy 相關規則
- `lua5.4 scripts/lint.lua --exclude L017,L027 working/foo/output.md`
  - 保留預設規則集但扣掉指定規則，適合先整檔跑再壓掉已知 false positive
- `lua5.4 scripts/lint.lua --list-rules`
  - 列出目前已實作的規則、狀態與預設啟用狀態，不檢查任何檔案
- `lua5.4 scripts/lint_smoke.lua`
  - 跑 linter 自己的 smoke test，用來確認規則與 CLI 沒壞，不是拿來檢查你的文章

## CLI 旗標

- `--format <text|json|markdown>`：切換輸出格式，預設是 `text`
- `--rules <IDS>`：只跑指定的 `Lxxx` 規則，也可用來手動開啟預設停用的規則，例如 `L005`、`L025`
- `--exclude <IDS>`：從預設規則集中排除指定的 `Lxxx`，適合先整檔跑再扣掉已知高誤報
- `--profile <NAME>`：套用預先設定的排除集。 目前支援 `spec`（跳過 `L017`、`L027`、`L002`、`L130`）、`glossary`（跳過 `L044`、`L045`、`L046`、`L022`）、`meta`（跳過 `L017`、`L018`、`L130`）、`final` / `default`（不額外排除）
- `--list-rules`：列出目前已實作規則、狀態與預設啟用狀態
- `--fail-on-warning`：只要有 warning 就以 exit code `1` 結束
- `--help`：顯示 CLI 用法

## 輸出格式

- 文字格式：`path:line:col [Lxxx] message`
- JSON 格式：每筆 warning 會帶 `path`、`line`、`col`、`lint_id`、`message`、`severity`
- `col` 一律是 1-based 的 UTF-8 字元欄位，不是 byte offset
- Markdown 格式：先給總表，再按檔案輸出 grouped table。 同一檔內若 `severity + lint_id + message` 相同，會合併成一列並把位置整理成 `Lx:Cy, ...`
- `severity` 目前固定是 `warning`

## 會測什麼

- Markdown 結構與輸出污染：段落切分、list 空行、preflight / dialogue leftover、source extraction artifact、citation apparatus
- 字形與標點：簡繁、引號、半形 / 全形標點、括號、破折號、技術 Markdown 的句號習慣
- 術語穩定：雙語術語順序、雙語術語重複、glossary preferred form、workspace jargon、taxonomy 摘要、內部控制詞外溢、關鍵術語誤用
- 中文句法與 function word：`把 / 被 / 受`、`是 / 有`、`自己`、`的 / 地 / 得`、`了`、成對連接詞、段落密度

## 怎麼讀 Warning

- 先看低誤報規則，再看高誤報的 `lint-hybrid` 規則
- 同一檔如果被少數規則洗版，先懷疑 heuristic 過寬或文件 profile 不合，不要直接大改 prose
- meta-doc、glossary、對照稿、baseline 這類文件，天生比較容易撞到 workflow / terminology 類規則
- golden 或 benchmark 文章應該有少量 warning，但不應大量集中在單一 `Lxxx`

## 可靠度地圖

- 高信賴，通常值得直接修：`L001`、`L003`、`L004`、`L006`、`L014-L018`、`L022-L026`、`L028`、`L030`、`L036-L043`、`L045-L052`、`L113`、`L126`
- 中信賴，適合人工快速複查：`L002`、`L007`、`L020`、`L021`、`L027`、`L029`、`L031`、`L032`、`L033`、`L035`、`L044`、`L054`、`L125`、`L127`、`L130`
- 高誤報，應視為 reread trigger：`L009-L013`、`L019`、`L034`，以及 `L101-L129` 中大多數 `lint-hybrid` 中文句法規則
- 這些高誤報規則常需要前後文、局部上下文或 glossary 才能決定要不要改

## 目前實作範圍

- CLI 已實作本目錄中所有非 `review-only` 規則
- 預設啟用：除了 `L005` 與 `L025` 以外的所有已實作規則
- 預設停用：`L005 raw_html_presentational_wrapper`、`L025 halfwidth_parentheses_without_spacing`
- 尚未接進 CLI、僅保留 spec 種子的規則：`L104`、`L109`、`L110`、`L117`、`L119`、`L131`、`L132`、`L133`、`L134`
- 若本檔的長描述與 CLI 狀態不一致，請以 `lua5.4 scripts/lint.lua --list-rules` 為準

## Workflow 建議

- 先跑整檔，確認總 warning 數與 top rules
- 再用 `--rules` 針對低誤報規則分批清理
- 如果 warning 集中在密度、taxonomy、術語漂移這類規則，請回頭看對應段落，而不是把 warning 當成硬性錯誤
- 規則若要加進 gating workflow，建議先只挑高信賴組，不要直接把所有 `lint-hybrid` 都視為 must-fix
- 在檢查自己寫的 spec、workflow、preflight、rule catalog 這類 meta 文件時，請加上 `--profile spec` 或 `--profile meta`，先扣掉 `L017`、`L130` 這類會把 meta vocabulary 誤判成正式輸出的規則。 在檢查 glossary 表格時，則用 `--profile glossary`

## 收錄原則

- 因為 linter 只發 warning，本檔可以收錄 false positive 風險偏高的啟發式，但至少要有穩定的 surface signal、檔內一致性檢查，或可綁 glossary / 檔內一致性的檢查路徑
- 若某條規則主要依賴 source 語意、外部事實或純語感，且目前沒有可接受的局部訊號，就標成 `review-only` 或暫不收錄
- 若規則正文給的是一個大方向，但其中只有部分子情況適合機器檢查，優先拆成較窄、較容易落地的 lint 種子，而不是留下過寬的總稱規則

## 狀態分類

- `lint-ready`：可用靜態規則或局部啟發式直接警告
- `lint-hybrid`：可用啟發式初篩，但通常需要前後文或 source 輔助
- `review-only`：暫時不適合自動檢查，只能提示人工 review

## 規則欄位

下方每條規則都盡量維持同一組欄位，方便之後繼續擴充或讓其他 LLM 直接讀取。 固定欄位如下：

- `lint_id`
- `status`
- `owner_spec`
- `signal`
- `detection_strategy`
- `needs_source_context`
- `auxiliary_inputs`
- `warning_message`
- `false_positive_risk`
- `autofix`

填寫時請注意：

- `owner_spec` 應指向目前仍在使用的規則文件，不要指向已刪除或已退場的文件
- `signal` 只描述 linter 觀察到的 surface signal，不重述完整規則正文
- 若規則還需要 project-local glossary 或 global glossary，建議集中記在 `auxiliary_inputs`

## 規則目錄

下方保留 checklist 形式的逐條說明。 `status` 與 `false positive risk` 主要用來幫你判斷 warning 該怎麼看，而不是表示它一定能或一定不能自動修

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

### L007 `anti_pattern_stock_phrase`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 2.10、`references/output_style.md` 3
- signal：使用 stock anti-pattern 句型，包括首段 bare opener（`不是`、`所謂`、`這也意味著`），以及文中任意位置的 paired `不是 / 並非……而是 / 其實 / 真正……` 與 `所謂……就是……`，還有 standalone 的 `這也意味著`
- detection strategy：首段前 12 col 的 bare prefix 匹配。 全文段落掃描 paired 與 standalone 片語，paired 需在同段落內同時命中前後兩半。 否定句加補充句的形式只抓明確 `不是 / 並非` 搭配 `而是 / 其實 / 真正`
- needs source context：否
- auxiliary inputs：無
- warning message：`偵測到 stock anti-pattern 句型，建議改為直接陳述`
- false positive risk：中
- autofix：否

### L008 `long_de_chain`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 2.9
- signal：過長 `的` 鏈
- detection strategy：局部短語內連續兩次以上 `的` 或三層以上前置修飾
- needs source context：否
- auxiliary inputs：無
- warning message：`可能存在過長的「的」鏈，建議改寫成子句、拆句或後置說明`
- false positive risk：中
- autofix：否

### L009 `repeated_subject_chain`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.3
- signal：相鄰子句重複同一主語
- detection strategy：相鄰子句或相鄰句的主語片語重複
- needs source context：部分需要
- auxiliary inputs：可選的句界 / 子句界定器
- warning message：`相鄰子句可能重複主語，請檢查是否可改為 topic chain`
- false positive risk：高
- autofix：否

### L010 `passive_overuse`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.3、2.6
- signal：`被` 句密度過高或不自然
- detection strategy：`被` 出現位置、與事件類型搭配、是否連續出現
- needs source context：部分需要
- auxiliary inputs：可選的句法切分
- warning message：`這裡可能機械沿用了被動句，請檢查是否應改為主動、無主句或框架先行`
- false positive risk：高
- autofix：否

### L011 `ba_without_result_state`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.6
- signal：`把` 字句缺乏明確處置 / 結果感
- detection strategy：`把 + 名詞組 + 動詞組` 結構，但後段缺少完成、結果或明確處置
- needs source context：是
- auxiliary inputs：可選的結果補語 / 完成標記詞表
- warning message：`這個「把」字句可能沒有清楚的處置 / 結果語義，請再確認`
- false positive risk：高
- autofix：否

### L012 `de_di_de_confusion`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.4
- signal：`的 / 地 / 得` 可能誤用
- detection strategy：局部詞性啟發式與固定搭配白名單 / 黑名單
- needs source context：部分需要
- auxiliary inputs：常見搭配詞表
- warning message：`這裡可能有「的 / 地 / 得」使用問題`
- false positive risk：高
- autofix：否

### L013 `aspect_le_mismatch`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.5
- signal：`了` 疑似只為對應英文 past tense 而出現，或完成體 / 句尾 `了` 混用
- detection strategy：句型啟發式、常見靜態敘述 / 定義句 / 慣常行為黑名單
- needs source context：部分需要
- auxiliary inputs：事件 / 狀態動詞黑白名單
- warning message：`這裡的「了」可能不自然，請檢查是完成體還是句尾狀態變化`
- false positive risk：高
- autofix：否

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

## 中文語法檢查種子

### L101 `nonspecific_np_fronted_as_topic`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.3
- signal：無定數量短語直接前置到話題位置
- detection strategy：數詞 + 量詞 + 名詞 + 逗號 / 句首前置模式
- needs source context：是
- auxiliary inputs：量詞詞表、句界判定器
- warning message：`這個前置名詞可能是無定短語，請檢查是否真的適合當話題`
- false positive risk：高
- autofix：否

### L102 `self_ziji_ambiguity`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.7
- signal：`自己` 前有多個第三人稱候選先行詞
- detection strategy：同句或鄰近句的第三人稱名詞組數量檢查
- needs source context：是
- auxiliary inputs：可選的照應視窗大小設定
- warning message：`「自己」可能有多重先行詞歧義，請檢查照應是否清楚`
- false positive risk：高
- autofix：否

### L103 `shi_you_confusion`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.3
- signal：存在句與判斷句功能混淆
- detection strategy：`是` / `有` 的句型分布啟發式
- needs source context：是
- auxiliary inputs：可選的主語 / 謂語詞類判定器
- warning message：`這裡可能混用了「是」與「有」的功能，請檢查是判斷、存在還是焦點句`
- false positive risk：高
- autofix：否

### L104 `bei_shou_confusion`

- 狀態：review-only
- owner spec：`references/output_grammar.md` 2.6
- signal：`被` / `受` 的受動結構選擇不自然
- detection strategy：暫無穩定靜態檢查
- needs source context：是
- auxiliary inputs：source 事件語義、視角判定
- warning message：`這裡可能需要檢查「被」與「受」的受動表述是否自然`
- false positive risk：高
- autofix：否

### L105 `de_nominalization_overuse`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.2、2.9
- signal：動詞名物化與 `名詞組 + 的 + 動詞組` 結構過重
- detection strategy：`的` 字結構密度、抽象名詞化樣式
- needs source context：部分需要
- auxiliary inputs：抽象名詞詞尾 / 詞表
- warning message：`這裡可能有過重的「的」字結構或名物化，請檢查是否應改回事件子句`
- false positive risk：高
- autofix：否

### L106 `ba_object_lacks_clear_reference`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.6
- signal：`把` 後名詞疑似為一般無定短語
- detection strategy：`把 + 數詞 / 量詞 / 不定名詞` 的局部樣式比對
- needs source context：是
- auxiliary inputs：量詞詞表、不定詞提示詞
- warning message：`這個「把」字句後面的名詞可能不是定指或殊指，請檢查是否自然`
- false positive risk：高
- autofix：否

### L107 `ba_clause_without_bounded_endpoint`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.6、2.9
- signal：`把` 字句缺少明確終點、結果或完成界線
- detection strategy：`把` 結構後段缺少結果補語、完成標記或終點語義
- needs source context：是
- auxiliary inputs：結果補語 / 去向補語詞表
- warning message：`這個「把」字句可能缺少有界事件或結果狀態，請檢查是否應改回一般動詞句`
- false positive risk：高
- autofix：否

### L108 `np_de_vp_overcompression`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.2、2.9
- signal：`名詞組 + 的 + 動詞組` 結構過密或過重
- detection strategy：`名詞組 + 的 + 動詞組` 樣式、相鄰名物化密度、抽象名詞密度
- needs source context：部分需要
- auxiliary inputs：可選的抽象詞表與 chunker
- warning message：`這裡可能把事件過度壓成「名詞組 + 的 + 動詞組」書面結構，請檢查是否應還原成事件子句`
- false positive risk：高
- autofix：否

### L109 `fronted_phrase_without_clear_frame`

- 狀態：review-only
- owner spec：`references/output_grammar.md` 2.3
- signal：前置成分疑似沒有清楚的話題 / 評論關係
- detection strategy：暫無穩定靜態檢查
- needs source context：是
- auxiliary inputs：資訊結構判定、source 對齊
- warning message：`這個前置結構可能只是表面換序，請檢查是否真的形成自然的話題結構`
- false positive risk：高
- autofix：否

### L110 `shou_as_generic_passive_substitute`

- 狀態：review-only
- owner spec：`references/output_grammar.md` 2.6
- signal：把 `受 / 受到` 當成一般 `被` 句替代品
- detection strategy：暫無穩定靜態檢查
- needs source context：是
- auxiliary inputs：source 事件語義、影響事件詞表
- warning message：`這裡可能把「受 / 受到」當成一般被動替代項，請檢查語義是否真的自然`
- false positive risk：高
- autofix：否

### L111 `shou_with_bare_event_or_resultative_complement`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.6
- signal：`受 / 受到` 後面直接接 bare V、結果補語或疑似 caused-result 片段
- detection strategy：`受(到)? + 動詞`、`受(到)? + V + 補語` 的局部樣式比對
- needs source context：是
- auxiliary inputs：動詞 / 補語詞表
- warning message：`這個「受 / 受到」後面可能接了不自然的動詞事件或結果結構，請檢查是否應改回主動或「被」句`
- false positive risk：高
- autofix：否

### L112 `you_sentence_with_definite_np`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.3
- signal：存在句 `有` 後疑似直接接定指名詞組
- detection strategy：`有 + 這 / 那 / 該 / 此 / 專名` 等定指模式
- needs source context：是
- auxiliary inputs：定指提示詞表、NER
- warning message：`這個存在句後面的名詞可能是定指成分，請檢查是否其實不適合用「有」引入`
- false positive risk：高
- autofix：否

### L113 `focus_shi_inside_predicate`

- 狀態：lint-ready
- owner spec：`references/output_grammar.md` 2.3
- signal：`是` 出現在述賓、`把`、`被`、述補或其他謂語內部位置
- detection strategy：`把.+是`、`被.+是`、`V.+是.+賓語` 一類局部樣式比對
- needs source context：否
- auxiliary inputs：無
- warning message：`這裡的「是」可能插進了不自然的謂語內部位置，請檢查是否應改回普通句`
- false positive risk：中
- autofix：否

### L114 `descriptive_v_de_with_overt_object`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.9
- signal：描寫補語型 `V 得 ...` 後仍保留顯性賓語
- detection strategy：`動詞 + 得 + 名詞組 + 程度 / 描寫詞` 的局部樣式比對
- needs source context：是
- auxiliary inputs：結果補語 / 描寫補語詞表
- warning message：`這個「V得...」結構後面可能保留了不自然的顯性賓語，請檢查它是否其實不是結果補語`
- false positive risk：高
- autofix：否

### L115 `overloaded_postverbal_stack`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.9
- signal：動詞後同時堆了賓語、頻率 / 持續短語、結果補語或其他後置成分
- detection strategy：連續動詞後成分數量、`動詞 + 名詞組 + 數量 / 持續 + 補語` 樣式
- needs source context：是
- auxiliary inputs：量詞 / 時長詞表
- warning message：`這裡的動詞後成分可能過度擁擠，請檢查是否應重排語序或拆句`
- false positive risk：高
- autofix：否

### L116 `local_pronoun_used_for_reflexive_meaning`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.7
- signal：`他 / 她 / 它` 疑似在局部從句裡承擔反身指涉
- detection strategy：同句主語與受詞 / 領屬代詞之間的局部共指樣式比對
- needs source context：是
- auxiliary inputs：人稱代詞詞表、簡易共指視窗
- warning message：`這個代詞可能在承擔局部反身指涉，請檢查是否應改成「自己」或明示名詞`
- false positive risk：高
- autofix：否

### L117 `ziji_under_attitude_verb_without_clear_anchor`

- 狀態：review-only
- owner spec：`references/output_grammar.md` 2.7
- signal：言說 / 態度動詞下的單寫 `自己` 缺少單一明確先行語
- detection strategy：`說 / 想 / 相信 / 覺得 / 埋怨` 等觸發詞 + 單寫 `自己` 的局部樣式比對
- needs source context：是
- auxiliary inputs：態度動詞詞表
- warning message：`這個「自己」可能引入不必要的主語 / 說話者觀點，請檢查照應錨點是否清楚`
- false positive risk：高
- autofix：否

### L118 `ziji_in_bei_clause_dual_antecedent_ambiguity`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.6、2.7
- signal：`X 被 Y ... 自己 ...` 一類被動結構中，`自己` 可能同時回指主語與 `被` 後名詞
- detection strategy：`被 + 名詞組 + ... + 自己` 的局部樣式比對
- needs source context：是
- auxiliary inputs：被字句 chunker
- warning message：`這個「自己」在被字句中可能同時有兩個候選先行語，請檢查是否需要主動消歧`
- false positive risk：高
- autofix：否

### L119 `bei_with_added_harm_tone`

- 狀態：review-only
- owner spec：`references/output_grammar.md` 2.6
- signal：草稿使用帶受害 / 蒙受語氣的 `被` 句，但原文缺少對應的受影響者視角線索
- detection strategy：暫無穩定靜態檢查
- needs source context：是
- auxiliary inputs：source 視角對齊
- warning message：`這個「被」字句可能平白加重了受害語氣，請檢查原文是否真的要求受影響者視角`
- false positive risk：高
- autofix：否

### L120 `you_v_as_generic_aspect_marker`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.3、2.5
- signal：`有 + V` 被拿來當一般完成體、存在補強器或口氣填充物
- detection strategy：偵測 `有 + 動詞` 樣式，排除真正的領屬句、存在句與少數語域白名單。 特別標記 `有完成`、`有支援`、`有初始化` 這類技術 prose 高風險搭配
- needs source context：部分需要
- auxiliary inputs：動詞詞表、語域白名單
- warning message：`這裡的「有 + V」可能只是口氣填充或泛用完成標記，請檢查是否應改成普通句、已、曾或句尾「了」`
- false positive risk：高
- autofix：否

### L121 `nonagentive_subject_with_control_modal`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.3
- signal：非施事、非意志主語搭配 `敢 / 肯 / 願意`
- detection strategy：偵測系統、欄位、錯誤、流程、模組等非人稱 / 非意志主語，與控制型情態詞的組合
- needs source context：部分需要
- auxiliary inputs：主語語意類別詞表、控制型情態詞表
- warning message：`這個主語看起來不像能承擔意志或主動選擇，請檢查是否應改成「會 / 可能 / 可以 / 應該」`
- false positive risk：高
- autofix：否

### L122 `missing_associative_de_after_modifier`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.4
- signal：定中修飾結構疑似缺少 `的`
- detection strategy：用固定高風險片語、修飾語 + 名詞樣式與 mixed-script 修飾樣式比對，例如 `複雜控制流程`、`跨 lane predicate 測試` 一類
- needs source context：部分需要
- auxiliary inputs：高風險缺 `的` 片語黑名單 / 白名單
- warning message：`這裡可能少了結構助詞「的」，請檢查修飾邊界是否清楚`
- false positive risk：高
- autofix：否

### L123 `missing_adverbial_di_after_modifier`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.4
- signal：狀語修飾結構疑似缺少 `地`
- detection strategy：比對常見 `清楚 說明`、`有系統 整理`、`系統性 比較` 等樣式，排除詞彙化固定搭配
- needs source context：部分需要
- auxiliary inputs：高風險缺 `地` 片語黑名單 / 白名單
- warning message：`這裡可能少了結構助詞「地」，請檢查修飾關係是否足夠清楚`
- false positive risk：高
- autofix：否

### L124 `missing_complement_de_after_verb`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.4、2.9
- signal：補語關係疑似缺少 `得`
- detection strategy：偵測 `看出來`、`整理很清楚`、`寫很完整` 這類高風險結構，判斷是否其實需要 `看得出來`、`整理得很清楚`
- needs source context：部分需要
- auxiliary inputs：高風險補語樣式詞表
- warning message：`這裡可能少了結構助詞「得」，請檢查是否需要明確標出補語關係`
- false positive risk：高
- autofix：否

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

### L127 `imminent_event_without_sentence_final_le`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.5
- signal：`快要 / 就要` 觸發了將至事件語氣，但句內沒有對應的句尾 `了`
- detection strategy：在同一子句內偵測 `快要` / `就要` 到句末標點之間是否缺少 `了`
- needs source context：否
- auxiliary inputs：子句界定器
- warning message：`這個將至事件句可能少了句尾「了」，請檢查是否應寫成「快要……了 / 就要……了」`
- false positive risk：中
- autofix：否

### L128 `completed_event_negated_with_bu`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.5
- signal：已完成事件疑似用 `不` 來否定
- detection strategy：比對 `不 + 完成類動詞`、`不 + V + 了`、`不初始化` 這類高風險模式，排除真正的一般習慣否定
- needs source context：部分需要
- auxiliary inputs：完成事件動詞表
- warning message：`這裡若是否定已完成事件，通常應優先用「沒 / 沒有」而不是「不」`
- false positive risk：高
- autofix：否

### L129 `count_phrase_after_sentence_final_le`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.5
- signal：`V + 數量短語 + 了` 看起來想表完成體，但實際上更像句尾 `了` 的新情況語氣
- detection strategy：偵測 `動詞 + 數詞 + 量詞(+名詞) + 了` 樣式，提示與 `V了 + 數量短語` 的完成體差異
- needs source context：是
- auxiliary inputs：量詞詞表、句界判定器
- warning message：`這裡的「了」可能落在句尾位置。 若你想表完成體，請檢查是否應改成「V了 + 數量短語」`
- false positive risk：高
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

### L131 `word_boundary_or_separable_verb_needs_review`

- 狀態：review-only
- owner spec：`references/output_grammar.md` 2.1
- signal：詞、詞素、複合詞或離合詞邊界可能影響譯文自然度
- detection strategy：暫無穩定靜態檢查
- needs source context：是
- auxiliary inputs：source term、project glossary、上下文搭配
- warning message：`這個詞彙邊界可能需要人工檢查：請確認它是固定詞、可拆短語、複合詞、離合詞，還是新詞 / 專名用法`
- false positive risk：高
- autofix：否

### L132 `quantified_pronoun_reading_needs_review`

- 狀態：review-only
- owner spec：`references/output_grammar.md` 2.7
- signal：代詞可能是 fixed reference、bound variable 或 donkey pronoun
- detection strategy：暫無穩定靜態檢查
- needs source context：是
- auxiliary inputs：source quantifier、條件句邊界、篇章 referent
- warning message：`這個代詞可能不只是普通共指，請檢查是否受量化詞、條件句或前文無定名詞限制`
- false positive risk：高
- autofix：否

### L133 `nonhuman_men_plural_needs_review`

- 狀態：review-only
- owner spec：`references/output_grammar.md` 2.3
- signal：非人名詞加 `們`，或英文 plural 被機械式轉成 `們`
- detection strategy：暫無穩定靜態檢查
- needs source context：是
- auxiliary inputs：名詞語意類別、source plural、語境中的群體化線索
- warning message：`這個「們」可能只是機械式 plural，請檢查名詞是否為人稱、人類或已群體化用法`
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

## 實作順序

1. 先實作 `lint-ready` 的 Markdown、source-noise、citation 結構與輸出污染檢查
2. 再實作 `lint-ready` / `lint-hybrid` 的語言形式與標點檢查，例如簡繁、引號、括號、半形標點、段落密度
3. 再實作術語穩定、glossary 對齊、workspace jargon 展開與 taxonomy 摘要檢查
4. 最後擴充中文句法與 function-word 類啟發式，例如 `把 / 被 / 受`、`是 / 有`、`自己`、`的 / 地 / 得`、`了`、連接詞與動詞後成分

## 維護原則

- 先補規則正文，再新增或調整 lint rule。 不要反過來讓本檔變成規則 owner
- 文法、句法、標點、Markdown、citation 與輸出污染規則優先寫進 `references/output_grammar.md`
- 忠實度、自然化、語氣、AI 腔與段落節奏規則優先寫進 `references/output_style.md`
- workflow、preflight、continuity 與驗證規則優先寫進 `references/workflow.md`
- glossary 與用語表資料分別維護在 `references/glossary.md` 與 `references/preferred_taiwan_terms.md`
- 若某條規則暫時不可 lint，也應明確標成 `review-only`
- 若某條規則其實依賴 source text context 或 glossary，規則定義裡要明寫，避免實作時把它誤當成純字面規則
- 未來 Lua linter 的規則 ID，應盡量沿用本檔的 `Lxxx` 編號
