# 話題、指涉與代詞

本目錄保存各 ID 的判準、來源條款、提示與風險說明。 執行時的規則狀態與訊息保存在 `linter/data/rule-map.json`，詞表保存在 `linter/data/lexicons.json`

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

