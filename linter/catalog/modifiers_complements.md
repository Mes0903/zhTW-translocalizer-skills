# 詞組、助詞與補語

本目錄保存各 ID 的判準、來源條款、提示與風險說明。 執行時的規則狀態與訊息保存在 `linter/data/rule-map.json`，詞表保存在 `linter/data/lexicons.json`

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

