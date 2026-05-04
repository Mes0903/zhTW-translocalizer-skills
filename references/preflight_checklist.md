# 開工前檢查表 v2.1

本檔把 `references/workflow.md` 需要先檢查的事項整理成操作清單，不重複展開規則正文

本檔中的欄位名、Mode 名與其他 workflow 標籤，只供 agent 在內部判定，不是正式中文輸出的推薦用詞。 若正式輸出需要提到這些概念，改寫成完整句子，說明實際要做的事

只有在相關核取方塊都實質滿足後，才可開始起草

## 1. 輸入與模式

- [ ] 確認來源檔案與來源範圍，或確認它們可從 `action` / task state 推導
- [ ] 確認輸出檔路徑，或確認它可從 `action` / active file / task state 推導
- [ ] 確認 baseline：
  - [ ] explicit path / path list
  - [ ] `auto`
  - [ ] 欄位缺漏，視為 `auto`
- [ ] 確認這次最後要交付什麼形式的內容：
  - [ ] 完整正式輸出
  - [ ] review / report 類中介成品
  - [ ] 其他特殊結構輸出
- [ ] 確認 `action` 已提供
- [ ] 整理使用者這一輪明確要求你做的事：
  - [ ] 本輪工作目的
  - [ ] 額外必讀 file / dir / source paths
  - [ ] 自訂輸出章節、區塊順序或標題骨架
  - [ ] 原文 + 譯文 / 譯文 + 解釋 / 其他雙層輸出形式
  - [ ] custom CSS / raw HTML / artifact allowance
- [ ] 整理 linter 要怎麼跑，以及是否有 rule-level 例外
- [ ] 檢查 Lua runtime：
  - [ ] `lua5.4` 可用
  - [ ] 或 `lua` 可用
  - [ ] 若兩者都不可用，已回報 linter 無法執行，且未宣稱 lint 已跑完
- [ ] 確認 linter 入口路徑：
  - [ ] skill root 下的 `scripts/lint.lua`
  - [ ] 或 repo root 下的 `skills/zhTW-Translocalizer/scripts/lint.lua`
- [ ] 判斷這一輪是不是在接續同一個任務，還是使用者已經明確改成另一個任務
- [ ] 若這仍是同一個任務，沿用既有的 source paths / output / scope / baseline / 交付形式 / action / mode / citation / 已接受例外
- [ ] 若任務已被明確 rebind，重新跑對應的開工前檢查，不可默默沿用舊 task 狀態
- [ ] 檢查使用者是否給了任何與 workspace spec 衝突的明確特殊要求
- [ ] 區分目前的 action 哪些只是任務參數，哪些其實是在要求破例
- [ ] 若有衝突，起草前先停下並列出：
  - [ ] 使用者要求
  - [ ] 衝突條款
  - [ ] 接受 override 後的影響
- [ ] 詢問是否仍要在該 override 下繼續
- [ ] 在使用者明確確認或撤回衝突要求前，不可開始起草
- [ ] 檢查 `context memory dir`：
  - [ ] `none`
  - [ ] 已提供 path
- [ ] 若提供了 path，且 `<PATH>/context_memory.md` 已存在，先讀它
- [ ] 若提供了 path 但檔案尚不存在，規劃在第一個穩定 checkpoint 建立它
- [ ] 判斷本輪主要工作重點：
  - [ ] 主要在翻譯或重寫 source
  - [ ] 主要在解說 code / repo / workflow
  - [ ] 主要在 review / revision 既有文字
  - [ ] 主要在調整規則 / linter / prompt / workflow
- [ ] 判斷這次是新檔還是續改：
  - [ ] Mode A：output file 不存在或為空
  - [ ] Mode B：output file 已存在且非空
- [ ] 檢查專案附近是否存在 project-local glossary

## 2. 規則堆疊已載入

- [ ] 閱讀 `references/output_guide.md`
- [ ] 閱讀 `references/workflow.md`
- [ ] 閱讀 `references/glossary.md`
- [ ] 閱讀 `references/preferred_taiwan_terms.md`
- [ ] 若存在 project-local glossary，先讀它
- [ ] `references/output_guide.md` 已涵蓋預設必讀的句型改寫例子與中文句法規則，不需再另外讀 appendix

## 3. 參考依據收集

- [ ] 在起草前先依本輪工作重點整理要讀哪些參考資料
- [ ] 若使用者明確指定 must-read file / dir / docs，先把它們放進閱讀計畫，不可被 generic 預設覆蓋
- [ ] 決定這次真正要沿用的 baseline：
  - [ ] 若使用者明確指定 path 或 path list，讀那些 Markdown baseline
  - [ ] 若為 `auto`，且這是新任務，讀 `references/baseline.md`
  - [ ] 若為 `auto`，且這不是新任務，讀目前 task 中先前已接受的 Markdown，包括目前 output scope 前面緊鄰的已接受內容，以及同一 task 中明確相關的較早 Markdown
- [ ] 確認 baseline 只作為文風 / 結構參考與延續性錨點，不覆蓋 source text、glossary 或 citation 決策

若本輪主要在翻譯或重寫 source：

- [ ] 閱讀相關的 `assets/translation-pair`
- [ ] 閱讀相關的 `assets/native`
- [ ] 在筆記中分開保存這兩條參考依據軌
- [ ] 參考依據數量符合目前 mode
- [ ] Mode A：至少 4 組相關的 `assets/translation-pair`
- [ ] Mode A：至少 4 篇相關的 `assets/native`
- [ ] Mode B：至少 2 組相關的 `assets/translation-pair`
- [ ] Mode B：至少 2 篇相關的 `assets/native`
- [ ] 若 translation scope 為中到大型，將 `assets/translation-pair` 提高到至少 12 組
- [ ] 若 translation scope 為中到大型，將 `assets/native` 提高到至少 3 篇
- [ ] 若 translation scope 為中到大型，起草前已準備批次一致性計畫

若本輪主要在解說 code / repo / workflow：

- [ ] 先閱讀相關的 source code / project docs / README
- [ ] 若存在可比對的 `assets/native` 風格參考，則閱讀：
  - [ ] Mode A：至少 2 篇，目標 2-3 篇
  - [ ] Mode B：至少 1 篇，目標 1-2 篇
- [ ] 只有在本次 explanation 涉及偏翻譯分析的解說或原文與譯文的措辭決策時，才閱讀 `assets/translation-pair`
- [ ] 確認沒有把翻譯型閱讀門檻硬套到本 task

若本輪主要在 review / revision 既有文字：

- [ ] 把被 review 的文字本身當成主要依據
- [ ] 若不是新任務，將目前 task 中先前已接受的 Markdown 視為必讀 baseline
- [ ] 若有 source text，對忠實度敏感問題先讀 source text
- [ ] 只有在行文節奏或結構需要比對參考時，才閱讀 `assets/native`
- [ ] 只有在被 review 的文章是翻譯稿，或正在檢查原文與譯文的術語問題時，才閱讀 `assets/translation-pair`
- [ ] 確認沒有把翻譯型閱讀門檻硬套到本 task

若本輪主要在調整規則 / linter / prompt / workflow：

- [ ] 先讀使用者明示的問題、benchmark、退化案例與 target-scope docs
- [ ] 只有在需要驗證具體退化時，才讀 `assets/native` 或 `assets/translation-pair`
- [ ] 確認翻譯型閱讀門檻不適用於本 task

## 4. 續改既有輸出時，先整理哪些決定已經穩定

- [ ] 若為 Mode B，先閱讀目前 output scope 前面緊鄰、且已接受的 output
- [ ] 整理這份既有輸出已經穩定下來的交付形式、區塊骨架與已接受 action
- [ ] 擷取穩定的術語邊界
- [ ] 擷取章節內定義術語的處理方式
- [ ] 擷取 citation 的編號 / 呈現風格
- [ ] 擷取行文節奏與 bullet/list 風格
- [ ] 若本輪會修訂既有正式輸出檔，標記受影響範圍：
  - [ ] 動到 opening sentence / opening paragraph
  - [ ] 動到 explanation-oriented paragraph
  - [ ] 動到 citation 或 hyperlink 行為
  - [ ] 動到 LaTeX / Markdown / HTML 結構
  - [ ] 動到對 baseline 敏感的段落
- [ ] 對每個受影響區塊，決定寫入前要重新檢查哪些關卡
- [ ] 若有動到開頭，規劃重新檢查開頭段落直接性
- [ ] 若有動到 explanation-oriented passage，規劃重新檢查解說段落具體性
- [ ] 若在修訂已接受的 output，規劃重新檢查 baseline 錨定、輸出檔延續性與對照 baseline 的退化檢查
- [ ] 若有動到 citation 行為，規劃重新檢查 citation 一致性與不虛構引用
- [ ] 若有動到公式或帶結構的 markup，規劃重新檢查 LaTeX 保留 / 來源正規化 / HTML 正規化
- [ ] 不可假設先前可接受的段落在局部重寫後仍然安全

## 5. 術語規劃

- [ ] 區分 true name / label / token、section-defined term 與 general concept
- [ ] 若存在 project-local glossary，套用它
- [ ] 對尚未解決的一般概念詞，套用 global glossary
- [ ] 決定首次雙語候選詞
- [ ] 決定首次出現後的穩定 downstream form
- [ ] 若某個一般概念詞會在整章高頻重複，先決定中文主形式，避免同章內在 English-only 與 Chinese-only 之間漂移
- [ ] 對高頻概念先明確決定是否採中文主形式，例如 `concurrency / 並行`、`lock / 鎖`、`critical section / 臨界區`
- [ ] 列出可能漂移的高風險術語

## 6. Citation 決策

- [ ] 判斷 source scope：
  - [ ] formal citation apparatus present
  - [ ] ordinary hyperlink only
  - [ ] no citation / no link
- [ ] 決定是否允許 formal citation apparatus
- [ ] 決定各局部區塊應沿用哪種引用形式
- [ ] 若同一份檔案內同時有 formal citation apparatus 與 ordinary hyperlink，確認各自對應的 source 角色清楚且局部自洽

## 7. 自然化與 Markdown 規劃

- [ ] 標記被動句過重或名詞化過重、需要做結構改寫的句子
- [ ] 標記 `preposition + V-ing` 或事件名詞化片語，判斷是否應還原成動詞子句 / 時間框架
- [ ] 標記 `名詞組 + 的 + 動詞組` 與其他高密度 `的` 字名物化，確認它們是否真的有資訊壓縮價值，而不是把事件硬壓成書面名詞短語
- [ ] 標記看似術語、其實仍可拆開或擴充的中文組合，確認是否不該硬寫成固定詞
- [ ] 標記若改用不同中文詞類會改變 `很`、`對`、賓語或補語配置的句子，確認目前詞類選擇是否自然
- [ ] 標記沿來源線性順序寫會切錯修飾範圍或成分邊界的句子，必要時先重排
- [ ] 標記可能更適合改成主動、無主句或框架先行中文，而不是 `被` 的被動句
- [ ] 標記 `被` 句是否真的需要受事者前景化。 若不需要，規劃改回主動、無主句或框架先行
- [ ] 標記未明說施事者的 `被` 句是否被草稿自行補出做事者。 若是，檢查來源或上下文是否真的提供依據
- [ ] 標記 `被` 句是否額外製造了受害 / 蒙受語氣。 若來源只是中性事件，不要平白加重成受害式 `被` 句
- [ ] 標記 `受 / 受到` 是否只是被動句替代詞。 若語義不是真正的承受或受影響，不要硬改成 `受` 句
- [ ] 標記 `受 / 受到` 後面是否其實接了 bare V、結果補語、雙賓語或內外賓語結構。 若是，不要硬改成 `受` 句
- [ ] 標記 `受 / 受到` 是否更適合接名詞化補語，如 `批評 / 攻擊 / 影響 / 責備 / 處罰`
- [ ] 標記名詞修飾堆疊或長 `...的...的...` 鏈，判斷是否應改寫成動詞結構或拆開
- [ ] 標記帶有明顯結果狀態的操作，判斷是否更適合結果補語
- [ ] 標記可能用 `把` 字句表達得更清楚的處置 + 結果句
- [ ] 標記 `把` 後名詞是否其實是一般無定短語。 若是，優先保留普通主動句
- [ ] 標記 `把` 字句是否缺乏明確終點、結果或收束點。 若缺乏，不要只為了中文化而硬套 `把`
- [ ] 標記 `是` 在句中究竟是在做普通判斷，還是在標出焦點。 若只是一般敘述，不要硬加焦點標記
- [ ] 標記 `A 是 B` 究竟是在分類、等同辨識，還是在說明部分與整體。 不要把普通判斷句當成可逆等號句
- [ ] 標記 `有` 在句中究竟是領屬、存在，還是完成貌。 若後接定指名詞，檢查是否其實不適合存在句
- [ ] 標記 `是...的` 與 `...的是...` 是否真的承擔焦點 / 辨識功能，而不是只是增加句型花樣
- [ ] 標記單寫 `自己` 是否同時有多個第三人稱候選先行語。 若有，規劃改成明示名詞或 `他自己 / 她自己`
- [ ] 標記局部從句裡的 `我 / 你` 是否會阻斷原本想要的第三人稱 `自己` 照應
- [ ] 標記句內其他第三人稱參與者、領屬者或多個 `自己` 是否讓照應路徑變得不穩
- [ ] 標記言說 / 態度動詞下的單寫 `自己` 是否不必要地引入主語或說話者觀點
- [ ] 標記 `他 / 她 / 它` 是否其實在承擔局部反身指涉。 若是，規劃改成 `自己`、`他自己 / 她自己` 或重複名詞
- [ ] 標記 `V 得 ...` 後是否保留了不自然的顯性賓語，確認它是結果補語還是描寫補語
- [ ] 標記動詞後是否同時堆了賓語、結果、頻率或持續短語。 若動詞後結構過重，先規劃重寫
- [ ] 標記同一主題連續出現、可減少重複主語的子句序列
- [ ] 標記前置的名詞組、賓語或數量短語，確認它們是否真的形成自然的話題 / 情境框架，而不是只是表面換序
- [ ] 標記前置的 `[數詞 + 量詞 + 名詞]` 數量短語，確認句子焦點是否真的落在數量本身。 若不是，避免直接話題化
- [ ] 標記若省略 `的 / 地 / 得` 會讓修飾或補語結構模糊的地方
- [ ] 標記高風險虛詞與小標記：
  - [ ] `的 / 地 / 得`
  - [ ] `了`
  - [ ] `把 / 被`
  - [ ] `就 / 才 / 再 / 還`
  - [ ] `因此 / 然而 / 於是 / 此外`
- [ ] 標記事實敘述、慣常行為、定義句與能力敘述，避免英文時態觸發多餘的 `了`
- [ ] 標記已完成、界線明確且帶結果的事件，判斷是否可使用動詞後 `了`
- [ ] 標記狀態變更或 discourse update 句，判斷是否可使用句尾 `了`
- [ ] 標記 `about to / soon / nearly / on the verge of`，判斷是否更適合 `快要……了 / 就要……了`
- [ ] 標記被否定的完成事件，判斷是否應用 `沒 / 沒有` 而不是 `不`
- [ ] 標記含數量詞的子句，確認 `V了 + 數量短語` 與句尾 `了` 是否會帶來不同解讀
- [ ] 標記可能需要簡潔連接詞如 `同時 / 但 / 因此 / 此外` 的子句關係
- [ ] 標記採用框架先行順序後會更聚焦的地方
- [ ] 標記仍依賴 stock contrast / exposition template，而非直接陳述主題的 opening sentence 或 opening paragraph
- [ ] 若本 task 是 explanation-oriented writing，標記那些只列抽象類別名稱、卻沒說明它們實際做什麼的 layer / folder / rule 摘要
- [ ] 若本 task 是 explanation-oriented writing，標記那些首次出現卻沒展開解釋的內部 workspace 術語
- [ ] 若本 task 是 explanation-oriented writing，為每個 major layer 或 subsystem 至少規劃一個具體錨點
- [ ] 標記可能踩到 anti-pattern template 的地方
- [ ] 標記需要 glue word 的位置
- [ ] 若本輪有 `References` 中文解釋或其他帶評論性的短解說，標記其中的保留詞、輕評價與玩笑，確認沒有被升級成更強的稱讚、命令或加戲
- [ ] 檢查正式輸出是否仍有分號。 預設改成句號、逗號、冒號、bullet 或重寫句子
- [ ] 若規劃保留分號，確認它是在同一說明目的下平行列舉多個對象，而且改成句號或 bullet 會明顯降低可讀性
- [ ] 若本輪有 `References` 中文解釋，預設把分號視為可疑。 有兩個重點時優先拆成兩句或兩個子列點
- [ ] 規劃邏輯過密處的段落重分
- [ ] 規劃平行短說明的 bullet 用法
- [ ] 確認一般 prose 沒有出現只換行、不留空行的句間硬斷行。 同一段內容直接續寫，分段則保留空行
- [ ] 確認一般 prose 行內沒有連續兩個半形空白。 list continuation 前導縮排、行尾 hard break 空白、inline code、code block 與 display math / LaTeX block 例外
- [ ] 確認一般段落若以全形 `：` 引出後續清單，冒號後與清單之間有保留空行。 若是列點項目內的巢狀清單，則不多插空行
- [ ] 確認相鄰的 list item 之間沒有多餘空行。 同一個 list item 若直接接巢狀清單，也沒有多餘空行
- [ ] 確認非空 Markdown 檔案以 EOF newline 結尾
- [ ] 標記含 LaTeX / TeX 公式的 source 段落，決定各公式應保留 inline 或 display
- [ ] 若 display math / LaTeX block 為多行排版，確認沒有為了 prose hard-wrap 規則而強行合併
- [ ] 標記來自手動 copy/paste 或 raw HTML 的 source-format noise，並在起草前先正規化
- [ ] 標記來源端 custom CSS 與 inline style，確認它們應被丟棄而不是進入輸出
- [ ] 標記純呈現層 HTML wrapper，確認哪些應轉成 Markdown 結構，而不是保留 raw HTML
- [ ] 確認 paragraph policy 沒有被誤解成 sentence-per-line 格式
- [ ] 確認自然化計畫沒有補入原文未明示的步驟、因果或時間順序

## 8. 起草前關卡

- [ ] 對應模式的前置條件已完成
- [ ] output contract 與 task-local action 已定案
- [ ] citation 決策已完成
- [ ] 術語規劃已完成
- [ ] 高風險句子已有自然化計畫
- [ ] 若 scope 較大，批次一致性計畫已存在
- [ ] 起草前已理解正式輸出一致性邊界
- [ ] 已明確檢查高風險虛詞與結構標記
- [ ] 已檢查開頭策略，確保開頭不依賴制式 anti-pattern 開頭
- [ ] explanation-oriented passage 在 relevant 時已有具體化計畫與術語展開計畫
- [ ] 已將 `了` 視為體貌 / 狀態變化標記檢查，而不是只是對應英文時態
- [ ] 起草前已明確解決任何 user-vs-spec 衝突
- [ ] 起草前已釐清任務延續性狀態
- [ ] revision turn 在寫入前已有受影響範圍重驗證計畫
- [ ] 起草前已決定 `context_memory.md` 的 read / create 計畫
- [ ] 起草前已理解 LaTeX 保留 / 來源正規化 / 忽略 CSS 的邊界
- [ ] 已決定 draft 完成後的 linter gate：
  - [ ] 要跑哪個 `scripts/lint.lua` 命令
  - [ ] 已決定 profile / `--rules` / `--exclude` 等範圍控制方式
  - [ ] 若本次 action 會刻意保留 CSS、raw HTML、雙語對照區塊或 artifact 結構，已決定哪些 lint rule 要停用、縮限或只當 advisory warning
  - [ ] 完成回覆會交代 linter 命令與結果
