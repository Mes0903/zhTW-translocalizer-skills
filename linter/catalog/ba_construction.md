# 把字句

L011 與 L107 共用每行首個「把」的子句分析、動詞表與結果標記。 L011 另有 22 個可見字及文法解說詞的排除條件。 L106 檢查賓語指涉，會保留為另一個問題。 `請把設定改。` 可有兩個結果理由。 `把一個設定改。` 還需要審閱賓語指涉

本目錄保存各 ID 的判準、來源條款、提示與風險說明。 執行時的規則狀態與訊息保存在 `linter/data/rule-map.json`，詞表保存在 `linter/data/lexicons.json`

### L011 `ba_without_result_state`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.6
- signal：`把` 字句缺乏明確處置 / 結果感
- detection strategy：`把 + 名詞組 + 動詞組` 結構，但後段缺少完成、結果或明確處置
- needs source context：是
- auxiliary inputs：可選的結果補語 / 完成標記詞表
- warning message：`這個「把」字句可能沒有清楚的處置 / 結果語義，請再確認`
- false positive risk：高
- autofix：否

### L106 `ba_object_lacks_clear_reference`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.6
- signal：`把` 後名詞疑似為一般無定短語
- detection strategy：`把 + 數詞 / 量詞 / 不定名詞` 的局部樣式比對
- needs source context：是
- auxiliary inputs：量詞詞表、不定詞提示詞
- warning message：`這個「把」字句後面的名詞可能不是定指或殊指，請檢查是否自然`
- false positive risk：高
- autofix：否

### L107 `ba_clause_without_bounded_endpoint`

- 狀態：lint-hybrid
- owner spec：`references/output_grammar.md` 2.6、2.9
- signal：`把` 字句缺少明確終點、結果或完成界線
- detection strategy：`把` 結構後段缺少結果補語、完成標記或終點語義
- needs source context：是
- auxiliary inputs：結果補語 / 去向補語詞表
- warning message：`這個「把」字句可能缺少有界事件或結果狀態，請檢查是否應改回一般動詞句`
- false positive risk：高
- autofix：否

