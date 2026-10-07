# 被動與受動表述

本目錄保存各 ID 的判準、來源條款、提示與風險說明。 執行時的規則狀態與訊息保存在 `linter/data/rule-map.json`，詞表保存在 `linter/data/lexicons.json`

被動表述的保留條件依 [grammar 2.6](../../references/output_grammar.md#26-把--被--受)。 審閱者逐句核對受事是否為敘述重點，並記錄文章問題或前後文的依據。 來源語態、施事不明及受害語義不能單獨作為保留理由

目前 L010 以同一句出現至少兩個「被」作為提示條件。 審閱者仍須依 grammar 檢查全部被動候選句，包含短被字句與「由」等被動表述。 L111 提示的改寫方向也須符合 grammar 的保留條件

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
