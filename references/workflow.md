# 工作流程

本檔定義 agent 在本 workspace 內的工作流程、閱讀路徑、輸入模型與驗證關卡

執行任務時直接遵守本檔：

- 中文輸出規則看 `references/output_guide.md`
- 術語與臺灣用語偏好看 `references/glossary.md` 與 `references/preferred_taiwan_terms.md`
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
  - 新任務預設使用 `references/baseline.md`
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
2. `references/output_guide.md`
3. project-local glossary 的明確映射
4. `references/glossary.md`
5. `references/preferred_taiwan_terms.md`
6. `references/preflight_checklist.md`

視任務需要再補讀：

- `assets/translation-pair`
- `assets/native`
- source code / project docs / README
- task-local `context_memory.md`

原則：

- 規則文件高於任務暫存筆記
- project-local glossary 在該專案內優先於全域 glossary
- `baseline` 只提供文風與延續性錨點，不覆蓋 source、glossary 或 citation 決策

各檔分別負責什麼：

- `references/output_guide.md`
  - 定義中文輸出規則、Markdown / citation 邊界與最小必要例子
- `references/workflow.md`
  - 定義閱讀路徑、task continuity、驗證關卡與輸入模型
- `references/glossary.md`
  - 定義全域預設術語映射
- `references/preferred_taiwan_terms.md`
  - 定義 workspace 層級的臺灣用語偏好與高風險詞
- `references/preflight_checklist.md`
  - 定義起草前檢查表，不重複定義規則正文
- `references/baseline.md` 與其他 baseline 材料
  - 只提供補充性示例與風格錨點，不單獨定義工作流程

不要把任務暫存筆記誤當成全域規則：

- 本地環境（如 `working/`）下的任務暫存筆記、分析筆記與 continuity 檔，不是全域規則文件
- 除非使用者明確指定，否則不要從任務暫存筆記反推 workspace 規則、workflow 或 project architecture
- 若任務暫存筆記與規則文件衝突，以規則文件為準。 若使用者要求沿用某份任務暫存筆記的設定，先重新跑 preflight 並確認必要 override

### 3.2 依工作重點選擇閱讀材料

先判定本輪主要工作重點，再決定閱讀路徑：

- 翻譯或重寫 source
  - 必讀相關 source
  - 必讀相關 `assets/translation-pair`
  - 必讀相關 `assets/native`
  - Mode A 至少讀 4 組 translation-pair、4 篇 native
  - Mode B 至少讀 2 組 translation-pair、2 篇 native
  - 中大型翻譯 scope，尤其是 5-10 頁，起草前先準備批次一致性計畫
  - 中大型翻譯 scope 的最低門檻提高到至少 5 組 translation-pair、5 篇 native
- code report / repo guide / workflow explanation
  - 必讀 source code / project docs / README
  - 至少讀 4 篇 native 作為輸出文風的參考
  - `assets/translation-pair` 只在真的需要原文與譯文措辭對照時使用
- review / revision
  - 必讀被 review 的文字本身
  - 至少讀 4 篇 native 作為輸出文風的參考
  - 非新任務時，先前已接受的 Markdown 是必讀 baseline
  - source text 視實際需求補讀
- 規則 / linter / prompt / workflow 調整
  - 必讀 benchmark、退化案例、目標文件與目前系統狀態
  - `assets/*` 只在驗證具體退化時使用

對中大型翻譯 scope 的批次一致性計畫，至少涵蓋：

- 重複出現的 true name / label / token
- 章節內定義術語
- general concept 的中文策略
- citation continuation 策略
- bullet-list 使用策略

### 3.3 `assets/native` 與 `assets/translation-pair`

- `assets/translation-pair`
  - 用於術語映射、英文保留邊界、章節內定義術語的處理
- `assets/native`
  - 用於中文文風、段落切分、列點節奏與自然表達
- 兩者衝突時：
  - 術語 / 名稱保留 / 雙語邊界 -> 優先看 `assets/translation-pair`
  - 段落節奏 / 分段 / 可讀性 -> 優先看 `assets/native`
- 不可讓 `assets/native` 覆蓋 `assets/translation-pair` 已提供的直接原文與譯文對照依據
- 對 code report 與 explanation 任務，source code / project docs / current output structure 的優先序高於不相關的翻譯對照依據
- 對 style review，正在被 review 的文字、baseline 與 source text 的優先序高於不相關的一般參考材料

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
- `baseline` 不是 source of truth，也不單獨決定工作流程
- 它只提供文風與延續性錨點

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
  - 確認 Lua runtime 與 linter 入口是否可用

### 5.2 自檢與 reread

- 寫入前至少做一次受影響範圍的 reread
- 即使改動很小，也必須重新掃過：
  - 片語自然度
  - 虛詞與結構助詞
  - 直譯僵硬
  - AI 腔 anti-pattern
- 若動到特定區塊，還要額外重跑：
  - lead sentence / opening paragraph：開頭直接性檢查
  - explanation-oriented passage：具體性檢查
  - citation / hyperlink：引用一致性與不虛構引用檢查
  - 公式 / 帶結構 markup：LaTeX / Markdown / HTML 正規化檢查
  - 既有正式輸出：baseline 錨定與退化檢查

### 5.3 Linter profile、停用條件與例外

- 使用本 skill 後，開工前必須先檢查目前環境是否可執行 Lua：
  - 優先使用 `lua5.4`
  - 若沒有 `lua5.4`，才改用 `lua`
  - 兩者都不存在時，必須先回報，且不可宣稱 linter 已跑完
- linter 路徑以 skill root 為基準是 `scripts/lint.lua`。 若目前在 repo root，常用完整路徑是 `skills/zhTW-Translocalizer/scripts/lint.lua`
- 若輸出目標是一般 Markdown 段落或可由 linter 解析的 Markdown 檔，完成前必須至少規劃並執行一次適用的 `scripts/lint.lua`
- 若 task 會刻意保留 custom CSS、raw HTML、雙語對照區塊或其他特殊結構，必須先決定：
  - 哪些規則仍是 must-review
  - 哪些只保留 advisory warning
  - 是否使用 `--rules`、`--exclude` 或 `--profile` 收斂範圍
- 常用 profile：
  - `spec`
  - `glossary`
  - `meta`
  - `final` / `default`
- 不可忽視 `scripts/lint.lua` 的輸出，應嚴格檢查每個 warning，確認是否為誤判，並根據對應的上下文來做輸出的修正，達到 reread trigger 的效果
- 完成回覆必須交代 linter 狀態：
  - 實際執行的命令
  - warning 是否已檢查
  - 若未執行，具體原因與後續阻擋點

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
  - `references/output_guide.md`
  - `references/workflow.md`
  - `references/glossary.md`
  - `references/preferred_taiwan_terms.md`
  - `references/preflight_checklist.md`
