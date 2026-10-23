# 臺灣繁體中文 Linter

linter 掃描 Markdown 中可定位的格式、術語與局部句法訊號。 報告提供原規則 ID、來源條款與檢查狀態，修稿者依所在段落判斷如何處理。 完整的段落檢查流程見 `references/workflow.md` 5.2

## 執行

Python 3.10 以上即可執行，使用標準函式庫：

```bash
python3 linter/lint.py --format markdown article.md
python3 linter/lint.py --format json --profile spec references/workflow.md
python3 linter/lint.py --rules L011,L107 --exclude L011 article.md
python3 linter/lint.py --list-rules
```

從其他目錄啟動時使用程式的完整路徑。 輸入檔的路徑依目前工作目錄解析，報告保留輸入字串。 多檔輸入沿用指定順序，每檔內的命中依行、欄及 ID 排序

## 選擇範圍

| 參數 | 行為 |
| --- | --- |
| `--format text/json/markdown` | 預設為 text |
| `--rules IDS` | 以逗號分隔原 ID，取代預設集合 |
| `--exclude IDS` | 從所選集合排除原 ID |
| `--profile NAME` | 加上該 profile 的排除集合 |
| `--fail-on-warning` | 有命中時退出 1 |
| `--list-rules` | 列出實作規則、狀態、預設啟用及摘要 |
| `--help` | 顯示命令列說明 |

| Profile | 排除 ID |
| --- | --- |
| `spec` | L017、L027、L002、L130 |
| `glossary` | L044、L045、L046、L022 |
| `meta` | L017、L018、L130 |
| `final`、`default` | 使用原預設集合 |

profile 與明示排除在合併診斷前作用於子判準。 例如 `--rules L001,L002 --profile spec` 只執行 L001。 L005 與 L025 保留預設停用，明示選取時可以執行。 未知 ID、人工審閱 ID、未知 profile 或檔案錯誤會回報原因並退出非零

一般 warning 退出 0。 指定 `--fail-on-warning` 且有命中時退出 1。 多檔都成功讀取並檢查後才輸出報告，讀檔錯誤會回報尚未完成的本次檢查

## 報告與段落檢查

JSON 保留逐條結果。 每個 warning 有 `path`、`line`、`col`、`lint_id`、`message` 及 `severity`，summary 有 `warning_count` 與 `files`。 行與欄從 1 開始，欄位計算 Unicode code point。 內部視窗仍保留原位元組意義，例如 L105 的 18 位元組條件

文字與 Markdown 報告依「檔案、行、欄、共同問題」合併診斷，分別計算問題數與原規則命中數。 首批合併為 L001／L002、L011／L107 及 L105／L108，各項理由仍有原 ID、訊息、狀態與來源條款。 同行不同位置及同位置不同問題會分別呈現

`lint-ready` 表示可直接執行的表面檢查，`lint-hybrid` 表示需依上下文判斷的提示，`review-only` 表示人工審閱項目。 `severity` 保留 warning 等級，規則狀態另列。 每項診斷依 workflow 記錄修正、附理由保留或待確認，修改後讀取最新段落及相鄰內容再驗證

## 主題導覽

這 15 個主題用於查找相關規則。 95 個原 ID 均有保存，另新增 L137、L138，共 97 個 ID，88 條有自動實作，86 條預設啟用。 9 條人工審閱項目為 L104、L109、L110、L117、L119、L131、L132、L133 及 L134

| 主題 | 原 ID |
| --- | --- |
| [Markdown 區塊與換行](catalog/markdown_structure.md) | L001、L002、L003、L004、L005、L014、L036、L039 |
| [正式輸出殘留](catalog/output_residue.md) | L006、L017、L018、L019、L130 |
| [文風與說明負擔](catalog/prose_clarity.md) | L007、L020、L034、L134、L137、L138 |
| [句讀、列舉與連接詞](catalog/sentence_connections.md) | L021、L027、L028、L029、L043、L125、L126 |
| [引號、標點與括號字形](catalog/punctuation_forms.md) | L023、L024、L025、L026、L044、L049、L050 |
| [可見文字邊界與空格](catalog/visible_spacing.md) | L037、L038、L040、L041、L045、L047、L048、L051、L052 |
| [臺灣用語、術語與雙語一致性](catalog/terminology.md) | L022、L030、L031、L032、L033、L035、L046、L053、L054 |
| [引用、書目與連結](catalog/citations_references.md) | L015、L016、L042、L055、L056、L057、L058、L059、L060、L061 |
| [話題、指涉與代詞](catalog/topic_reference.md) | L009、L101、L102、L109、L116、L117、L118、L132、L133 |
| [被動與受動表述](catalog/passive_voice.md) | L010、L104、L110、L111、L119 |
| [把字句](catalog/ba_construction.md) | L011、L106、L107 |
| [的字修飾鏈與名物化](catalog/nominalization.md) | L008、L105、L108 |
| [詞組、助詞與補語](catalog/modifiers_complements.md) | L012、L114、L115、L122、L123、L124、L131 |
| [判斷、存在與情態](catalog/predicate_modal.md) | L103、L112、L113、L121 |
| [事件體貌與否定](catalog/aspect_negation.md) | L013、L120、L127、L128、L129 |

## 執行資料與實作

- `lintlib/core.py` 提供文件視圖與定位介面，`document_views.py` 保存行分類與 glossary 解析
- `lintlib/clauses.py` 共用保護區、書目、子句及語言訊號。 `byte_patterns.py` 保留原 ASCII 類別與位元組匹配語義
- `lintlib/rules/` 的九個模組按共用分析分配 88 條實作。 三組重疊規則共用候選掃描，原 ID 在條件判斷後仍各自產生理由
- `lintlib/rules/prose_clarity.py` 以窄句型找 L137 保證／排除候選，並檢查文件及每個標題後首個正文段落的 L138 開頭候選。 兩者皆為人工核對上下文、來源與任務用途的提示，限制與誤報見[文風目錄](catalog/prose_clarity.md)
- `lintlib/lexicons.py` 從 `linter/data/lexicons.json` 載入唯一的領域詞表
- `lintlib/registry.py` 選擇及分派原 ID，`report.py` 產生原始 JSON 與合併報告
- `linter/data/rule-map.json` 保存執行所需的規則 ID、狀態、預設設定、提示與來源條款
