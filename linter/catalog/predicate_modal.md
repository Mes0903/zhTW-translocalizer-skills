# 判斷、存在與情態

本目錄保存各 ID 的判準、來源條款、提示與風險說明。 執行時的規則狀態與訊息保存在 `linter/data/rule-map.json`，詞表保存在 `linter/data/lexicons.json`

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

