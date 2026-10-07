# 事件體貌與否定

本目錄保存各 ID 的判準、來源條款、提示與風險說明。 執行時的規則狀態與訊息保存在 `linter/data/rule-map.json`，詞表保存在 `linter/data/lexicons.json`

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

