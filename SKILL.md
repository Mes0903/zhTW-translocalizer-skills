---
name: zhtw-translocalizer
description: 用於此 repo 內的臺灣繁體中文翻譯、改寫、修稿、審閱，以及規則、linter、workflow 相關維護工作。
---

# zhTW-Translocalizer

這份 skill 只作為入口與導引，不重複規則正文

## 啟動後立即確認

1. 判定 skill root，也就是本 `SKILL.md` 所在目錄
2. 檢查 Lua runtime：
   - 優先使用 `lua5.4`
   - 若沒有 `lua5.4`，才改用 `lua`
   - 兩者都不存在時，先回報「Lua 不可用，linter 無法執行」
3. 若本輪會起草、修稿、審閱或寫入可 lint 的 Markdown，Lua / linter 不可用就是阻擋條件。 不要默默跳過 lint gate

建議檢查命令：

```bash
command -v lua5.4 || command -v lua
```

## 安裝 / 配置

- 將此 skill repo 安裝成一個 skill root；在 `hanaya-workspace` 內的預設位置是 `skills/zhTW-Translocalizer/`。若安裝到其他平台，保持 `SKILL.md`、`references/`、`scripts/`、`assets/` 的相對位置不變。
- 必要 runtime 只有 Lua linter：優先安裝或提供 `lua5.4`，否則可退回 `lua`。不要把 PDF/OCR/Ollama/qwen3.5 安裝視為本 skill 的必要條件；那些屬於 To-markdown / `environment-bootstrap`。
- 安裝後先跑 linter smoke：

```bash
cd <skill-root>
lua5.4 scripts/lint_smoke.lua
```

若目前工作目錄是 workspace root，則使用：

```bash
lua5.4 skills/zhTW-Translocalizer/scripts/lint_smoke.lua
```

- 若 workspace 另外提供 `tools/zhtw-mcp`，它可以作為補充檢查工具；先 `source tools/bootstrap/env.sh` 再檢查 `zhtw-mcp`。但 `zhtw-mcp` 不取代本 skill 的 Lua linter gate。

## 啟動後先讀

1. `references/workflow.md`
2. `references/output_guide.md`
3. `references/glossary.md`
4. `references/preferred_taiwan_terms.md`
5. `references/preflight_checklist.md`

## 視情況補讀

- 若 task scope 附近有 project-local glossary，先讀它
- 若任務涉及 linter 規則、warning 解讀或 CLI 用法，補讀 `scripts/README.md`
- 若需要 baseline 或延續中的文風參考，依 `references/workflow.md` 補讀 `references/baseline.md`、既有輸出或其他相關材料
- 其他 task-specific source、`assets/translation-pair`、`assets/native`、benchmark、退化案例與目前實作狀態，一律依 `references/workflow.md` 的閱讀路徑決定是否補讀

## 執行原則

- 對外輸入、欄位推導、閱讀路徑、Mode A / Mode B、override gate、reread、lint gate 與寫入前後驗證，一律直接遵守 `references/workflow.md`
- 中文輸出、Markdown、citation、正式輸出邊界與自然化規則，一律直接遵守 `references/output_guide.md`
- 起草、修稿或改規則前，必須先完成 `references/preflight_checklist.md`
- 對任何正式 Markdown 輸出檔的新增或修改，完成前必須實際執行 linter，並在回覆中說明使用的命令與結果。 若因 Lua 或路徑問題無法執行，必須明確回報為未完成的驗證缺口
- 欄位名、模式名與其他 workflow 控制標籤只供內部判定。 若正式輸出需要提到相關概念，改寫成完整句子，不要直接把標籤當成中文術語
- 不要在 skill 內重複規則全文，也不要把 task-local 筆記誤當成全域規則
