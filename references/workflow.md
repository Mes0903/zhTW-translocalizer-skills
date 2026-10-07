# 工作流程

本檔定義 agent 在本 workspace 內的工作流程、閱讀路徑、輸入模型與驗證關卡

執行任務時直接遵守本檔：

- 中文輸出規則看 `references/output_grammar.md` 與 `references/output_style.md`
- 術語對照看 `references/glossary.md`，禁用詞及臺灣用語偏好看 `references/preferred_taiwan_terms.md`
- 起草前檢查看 `references/preflight_checklist.md`
- 本檔中的欄位名、Mode 名與其他 workflow 標籤，只供 agent 在內部判定
- 若正式輸出需要提到這些概念，改寫成完整句子，不要直接把標籤當成中文術語

## 1. 使用者要求和全域規則衝突時怎麼處理

### 1.1 使用者要求與 workspace 規約衝突時

- 若使用者要求與 workspace 規約衝突，起草、修訂或寫入前必須先停下，並給出衝突報告
- 衝突報告至少要指出：
  - 使用者要求
  - 衝突條款
  - 接受 override 後的實際影響
- 只有在使用者明確確認後，才可把該 override 視為目前 task 的狹義例外
- 未確認前不可默默覆蓋規則，也不可默默忽略使用者要求
- task-local override 不會凌駕更高層的 system、安全或平台限制

### 1.2 怎麼判斷後續回合是不是同一個任務

- 除非使用者明確重設或重新綁定 task，否則同一段對話中的後續回合都視為目前 task 的延續
- 小型 rewrite、局部修稿、語氣調整與補充要求，不應默默被當成全新 task
- 若這仍然是同一個任務，至少要延續下列已經確定的內容：
  - 目前的主要工作重點
  - `source_paths` / `output_file` / `scope`
  - `baseline`
  - 已接受的 `action`
  - 已接受的 override
  - citation 決策
  - glossary 與 terminology 決策
- 若 task 被明確 rebind，必須重新跑對應的 preflight 與閱讀路徑判定
- 即使同一個 task 有 continuity，每次要再寫入前，還是要重新檢查這次改動會影響的範圍

## 2. 任務輸入模型

### 2.1 模型內部需要先判定的欄位

- `source_paths`
- `output_file`
- `baseline`
- `scope`
- `context_memory_dir`
- `action`

這些欄位分別用來決定：

- `source_paths`
  - 決定來源範圍與附近 project context
- `output_file`
  - 決定正式輸出路徑
- `baseline`
  - 決定文風與延續性參考錨點
- `scope`
  - 決定這一輪實際要處理 source / output 的哪一塊
- `context_memory_dir`
  - 決定是否讀寫 task-local `context_memory.md`
- `action`
  - 承載本輪工作目的與 task-local 附加要求，例如額外必讀資料、輸出形式、lint 例外與 custom structure allowance

### 2.2 預設值與缺漏時的推導

- `baseline` 缺漏時視為 `auto`
- `context_memory_dir` 缺漏時視為 `none`
- `output_file` 不存在或為空時，走 Mode A
- `output_file` 存在且非空時，走 Mode B
- 若 `baseline = auto`：
  - 新任務使用相關守則中的段落示範
  - 非新任務預設使用目前 task 中先前已接受的 Markdown
- 若使用者未顯式提供欄位，但 `action`、active file、目前工作目錄或既有 task state 已足以推導，則可直接推導，不必為了表單完整性而中斷
- 若欄位推導存在實質歧義，且不同解讀會改變讀寫邊界，才需要回頭確認

### 2.3 對外只要求 `action`，其餘欄位必要時再明示

- 對外輸入介面可以只暴露 `action`
- 其他欄位改為模型推導的內部語義，而不是使用者每次必填的表單
- 若使用者需要明確指定特殊行為，可附 optional overrides，例如：
  - `baseline`
  - `context_memory_dir`
  - `scope`
  - 額外 must-read file / dir
- `action` 應保留自然語言描述空間，不要求使用者學習固定 DSL
- skill 只需要把「如何從 `action` 解析到內部欄位」說清楚，不需要再暴露完整六欄模板
- 若使用者直接把 `source_paths`、`output_file`、`baseline`、`scope`、`context_memory_dir` 與 `action` 明寫出來，可把它視為同一組內部欄位的顯式展開

## 3. 參考依據與閱讀路徑

### 3.1 預設要先讀哪些規則與參考資料

預設先讀下列規則文件：

1. `references/workflow.md`
2. `references/output_grammar.md`
3. `references/output_style.md`
4. project-local glossary 的明確映射
5. `references/glossary.md`
6. `references/preferred_taiwan_terms.md`
7. `references/preflight_checklist.md`

視任務需要再補讀：

- 使用者指定的外部文風參考或原文／譯文對照
- source code / project docs / README
- task-local `context_memory.md`

原則：

- 規則文件高於任務暫存筆記
- project-local glossary 在該專案內優先於全域 glossary
- `baseline` 只提供文風與延續性錨點，不覆蓋 source、glossary 或 citation 決策

各檔分別負責什麼：

- `references/output_grammar.md`
  - 定義術語、句法、虛詞、標點、Markdown、citation、link label 與正式輸出檔污染邊界
- `references/output_style.md`
  - 定義忠實度、自然化、語氣、AI 腔、解說具體性、段落節奏與 baseline 的文風角色
- `references/workflow.md`
  - 定義閱讀路徑、task continuity、驗證關卡與輸入模型
- `references/glossary.md`
  - 定義全域預設術語映射
- `references/preferred_taiwan_terms.md`
  - 定義 workspace 層級的中文禁用詞、臺灣用語偏好與高風險詞
- `references/preflight_checklist.md`
  - 定義起草前檢查表，不重複定義規則正文
- 守則內的段落示範與使用者指定的文風材料
  - 提供具體選擇及延續性參考，閱讀用途依 3.3

不要把任務暫存筆記誤當成全域規則：

- 本地環境（如 `working/`）下的任務暫存筆記、分析筆記與 continuity 檔，不是全域規則文件
- 除非使用者明確指定，否則不要從任務暫存筆記反推 workspace 規則、workflow 或 project architecture
- 若任務暫存筆記與規則文件衝突，以規則文件為準。 若使用者要求沿用某份任務暫存筆記的設定，先重新跑 preflight 並確認必要 override

### 3.2 依工作重點選擇閱讀材料

依任務讀取來源與相關守則示範：

- 翻譯或重寫 source
  - 讀取本輪來源及理解它所需的相鄰內容
  - 依 source 的實際難點回查 grammar，以及 style 4.1 至 4.4 的判準與段落示範
  - 使用者指定原文／譯文對照或文風參考時，按指定範圍讀取
  - 中大型翻譯 scope，尤其是 5-10 頁，起草前準備批次一致性計畫
- code report / repo guide / workflow explanation
  - 讀取相關程式、project docs 與 README，以檔案、責任與行為支持說明
  - 依介紹目的、背景與推導的難點使用相關守則示範
- review / revision
  - 讀取目標文字與判斷忠實度所需的來源
  - 續改時讀取目前章節與相鄰已接受內容，擷取穩定的行文與術語決策
  - 依實際問題回查相應守則與示範
- 規則 / linter / prompt / workflow 調整
  - 讀取 benchmark、退化案例、目標文件與目前系統狀態
  - 具體退化需要的原件與來源依任務讀取

中大型翻譯的批次一致性計畫至少涵蓋：

- 重複出現的 true name / label / token
- 章節內定義術語
- general concept 的中文策略
- citation continuation 策略
- bullet-list 使用策略

### 3.3 選材與使用示範

文風判準與段落示範由 [style 第 4 節](output_style.md#4-段落節奏與-markdown-prose)保存，局部句法沿用 grammar 的既有例句。 起草時依要解決的問題閱讀相應示範，重新閱讀時核對自己作了哪些選擇及其根據

原文、程式與專案文件提供技術事實，project-local 與全域 glossary 提供術語映射及名稱保留邊界。 使用者指定的原文／譯文對照可補充措辭依據，文風參考可補充分段、節奏與自然表達。 判斷術語時優先使用直接的來源、對照與 glossary，判斷行文時使用相關示範與已接受內容

解說程式或 repo 時，讀取目前程式、文件與輸出結構。 審稿時，讀取目標文字、相關來源與延續性參考。 材料的用途與優先序隨正在判斷的問題決定

### 3.4 Project-local glossary

- 若本地環境下（如 `working/<project>/`）存在 `glossary.md`，起草前要先讀完它
- project-local glossary 在該專案內優先於全域 glossary
- 穩定的 project-level terminology 決策，應在翻譯或 review 後寫回 project-local glossary

## 4. 工作模式

### 4.1 新檔 bootstrap（Mode A）

當 `output_file` 不存在或為空時使用

起草前必做：

1. 判定主要工作重點與閱讀路徑
2. 檢查 project-local glossary
3. 收集相關參考依據
4. 建立起始摘要或工作筆記
5. 完成 preflight
6. 決定 output contract 與必要的 lint 策略

### 4.2 續改既有輸出（Mode B）

當 `output_file` 已存在且非空時使用

起草前必做：

1. 閱讀目前輸出範圍前面緊鄰、且已接受的內容
2. 判定主要工作重點與閱讀路徑
3. 檢查 project-local glossary
4. 收集相關參考依據
5. 擷取延續性決策：
  - 術語邊界
  - 章節內定義術語的處理方式
  - citation 呈現方式
  - 段落與列點風格
6. 規劃寫入前的受影響範圍重驗證

### 4.3 Baseline 與延續性錨點

- 若這次是在續改既有輸出，預設把目前輸出範圍前面緊鄰、且已接受的內容當成這一輪延續寫法的參考
- 若沒有明確理由改變，沿用穩定的術語、引用形式、行文節奏與列點風格
- `baseline` 可以是 explicit path、path list 或 `auto`
- 新任務的 `auto` 使用守則中的相關段落示範，explicit path / path list 按指定範圍讀取
- 文風參考提供行文與延續性錨點，技術事實、術語及引用依各自的來源判斷

### 4.4 `context_memory.md`

- `context_memory_dir = none` 時跳過
- 若提供 path，則 task-local memory file 為 `<PATH>/context_memory.md`
- 檔案存在時，處理同一 task 的後續指示前先讀
- 檔案不存在時，等到第一個穩定 checkpoint 再建立
- `context_memory.md` 可保存：
  - 主要工作重點摘要
  - 目前 spec stack
  - `source_paths` / `output_file` / `scope`
  - `baseline`
  - 工作模式與 citation 決策
  - 穩定術語與風格決策
  - 已確認的 override
  - 尚待處理要求
 - `context_memory.md` 不是第二份 prompt、不是對話逐字稿，也不是全域規則文件
- 只在穩定 checkpoint 更新，不要每個 micro-turn 都寫

## 5. 寫入前後關卡

### 5.1 Preflight

- 起草、修稿或改規則前必須完成 `references/preflight_checklist.md`
- checklist 是開工前的操作清單，不是第二份規則書
- preflight 的核心工作包括：
  - 確認輸入欄位與 output contract
  - 判定工作模式與主要工作重點
  - 收集參考依據
  - 擷取延續性決策
  - 完成術語規劃、citation 決策與自然化計畫
  - 確認 Python runtime 與 linter 入口是否可用

### 5.1.1 起草前的文章與段落安排

讀完來源後，整理文章要回答的問題及讀者已知的背景。 為各段記錄核心問題、講述對象、所需前提、這段增加的資訊，以及下一段將依賴什麼。 篇幅與欄位依任務縮放，局部修稿可只記受影響段落與相鄰銜接

依這份安排回查適用 grammar，記下選擇的理由與來源位置：主詞與省略、語態、體貌、修飾範圍、事件關係及術語。 例如，完成事件依 2.5 判斷「了」，受事主線依 2.3 與 2.6 選擇句骨，時間與條件依 2.8 表達。 來源缺少的前提另記待查證事項，忠實度沿 style 第 0 節檢查

安排與查核紀錄放在任務筆記中。 起草沿已確認的資訊展開，讓讀者在使用新概念前取得理解它的前提

### 5.2 重新閱讀段落與處理診斷

修稿者會先重新閱讀文章，確認文章要回答的問題與內容順序，再逐段檢查句法及 linter 提示。 檢查段落時，一併閱讀目前段落與前後相鄰內容，確認讀者能沿著已交代的資訊理解下一句。 受影響範圍至少完成下列檢查：

1. 說明這段要回答的問題，核對背景、對象與必要術語是否已在前文交代。 首次出現的概念需要足以理解後續動作的說明
2. 核對例子中的條件、動作與結果如何支持正文。 例子引入的新資訊要接回正在解釋的問題，推導中的必要步驟也要能從文字或來源找到
3. 找出每句的動作主體與代詞所指。 主詞可由緊鄰上下文辨認時，保留自然省略。 主體切換或有多個候選時，明示有來源依據的主詞
4. 核對事件之間的時間、條件、轉折或因果關係。 連接語應表達已有依據的關係。 對完成事件與狀態變化，依 grammar 2.5 判斷動詞後或句尾的「了」是否自然。 定義、慣常行為與能力敘述也依該節判斷
5. 依 style 4.2、4.3 核對句首承接、段落主線、主詞與主要動作的距離，以及重要新資訊是否位於完整的收束處。 多項重點各自取得可辨認的位置。 逐句標記被動表述，依 grammar 2.6 核對受事是否為需要強調或持續追蹤的對象，保留時記錄文章問題或前後文的依據。 不符合條件時，改用主動、無主句或框架先行，改寫不得補入來源未交代的施事
6. 核對片語自然度、虛詞、修飾範圍、直譯句骨與制式句型。 依 style 第 3 節檢查補充內容的來源與任務用途，包含附註、獨立否定句、跨句與跨段敘述。 保留澄清時，記錄來源明示的內容或使用者已提出的具體問題。 找不到依據時，刪除自行追加的排除內容

來源缺少背景、主體、因果或中間步驟時，記錄需要確認的資訊。 翻譯或修稿新增的事實仍須符合 `references/output_style.md` 第 0 節的忠實度要求

linter 的合併診斷也按所在段落處理。 修稿者展開該診斷的全部子理由，核對原 ID、狀態與來源條款，再讀取最新文字及相鄰內容。 同一位置的不同問題分別判斷，每個仍啟用的理由都要記錄處理結果

處理紀錄放在任務筆記或審閱報告中，使用下列三種狀態：

- `fixed`：記錄修改內容及重驗結果
- `kept-with-reason`：記錄支持保留的上下文、來源或適用例外
- `unresolved`：記錄缺少的資訊與待確認問題，交付時明示

修改後重新讀取檔案，重跑受影響段落及相鄰銜接的檢查。 舊診斷的處理紀錄保留，新一輪判斷使用最新文字。 開頭、解說、引用、公式或已接受的段落若有改動，繼續執行 5.4 的對應關卡

### 5.3 Linter profile、停用條件與例外

開工前檢查 `python3`，必要版本為 Python 3.10 以上。 linter 使用標準函式庫，入口是 skill root 下的 `linter/lint.py`。 從其他目錄啟動時，使用完整的程式路徑：

```bash
python3 <skill-root>/linter/lint.py --profile final --format markdown <output-file>
```

一般 Markdown 輸出在完成前至少執行一次適用的 linter。 常用 profile 為 `spec`、`glossary`、`meta` 與 `final`／`default`。 `--rules` 與 `--exclude` 接受原 ID，profile 與排除先作用於子判準，再合併診斷

任務需要保留 custom CSS、raw HTML、雙語對照或其他特殊結構時，依任務範圍決定必須審閱的規則、提示用途的規則及明確排除項目。 停用範圍與理由記錄在任務筆記中

JSON 保存逐條命中，文字與 Markdown 合併同一位置的共同問題並保留各子理由。 `severity` 與規則狀態分別表示警告等級及檢查性質，閱讀報告時一併核對。 修稿者仍須依 5.2 的流程重新閱讀上下文，檢查背景、例子、推導、主體與語氣。 9 條人工審閱項目也依相關 grammar 條款檢查

完成回覆交代實際命令、警告的處理結果及待確認事項。 runtime 或路徑錯誤造成驗證缺口時，說明具體原因與尚未完成的檢查

### 5.4 寫入前重新檢查受影響範圍

- 任何對既有正式輸出檔的修改，在寫入前都必須重跑對應驗證關卡
- 重新做的驗證可以聚焦在受影響的範圍，但不可跳過這次改動可能波及的檢查
- 若影響範圍不明確，寧可重跑較大範圍，也不要只信任句子層級的小修改
- 目標是避免局部修訂把段落退化回模板句、抽象摘要或不一致的 baseline 風格
- 若修稿動到 opening sentence、opening paragraph、explanation-heavy passage 或其他高風險段落，必須重新用同一套段落規則檢查該段
- 不可把曾經通過 review 的段落視為局部改寫後仍必然安全

## 6. Skill 的對外介面

### 6.1 Action-first 與 skill 封裝

- 對外輸入以 `action` 為主
- 其他欄位改為模型推導或 optional override
- skill 本身只放工作流程與必讀檔案的入口，不重複規則全文
- 若輸入中直接明寫各欄位，視為同一組內部欄位的顯式展開，而不是另一套輸入格式
- skill 啟動後的最小必讀集合應是：
  - `references/output_grammar.md`
  - `references/output_style.md`
  - `references/workflow.md`
  - `references/glossary.md`
  - `references/preferred_taiwan_terms.md`
  - `references/preflight_checklist.md`
