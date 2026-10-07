# 的字修飾鏈與名物化

L105 與 L108 共用事件名詞候選，沿用詞表順序及每個名詞的首個位置。 L105 另要求全行至少兩個「的」，且前 18 位元組內另有「的」。 兩個判準各自選取合格候選，同位置才合併診斷。 L008 的修飾鏈密度條件保留為另一個問題

本目錄保存各 ID 的判準、來源條款、提示與風險說明。 執行時的規則狀態與訊息保存在 `linter/data/rule-map.json`，詞表保存在 `linter/data/lexicons.json`

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

