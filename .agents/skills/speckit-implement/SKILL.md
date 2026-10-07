---
name: speckit-implement
description: 依任務清單按 TDD 順序執行任務並生成實作程式碼。當任務清單已就緒、要開始實作或繼續執行某個 TASK 時使用；前後端拆檔時可指定 frontend 或 backend。嚴格遵守 red-green、憲法與計劃約束。
argument-hint: "（可選）任務編號如 TASK-005／TASK-BE-005，或 frontend／backend"
user-invocable: true
disable-model-invocation: false
metadata:
  source: ".claude/commands/speckit.implement.md (ported to skill)"
---

# /speckit-implement

執行任務清單中的任務，生成實作程式碼。

## 輸入

$ARGUMENTS（可選）：
- 任務編號，如 `TASK-005`、`TASK-FE-003`、`TASK-BE-007`
- 或邊別 `frontend`／`backend`（僅拆檔時有效）
- 省略則從第一個可承接的任務開始

## 你的任務

### Step 1: 執行先決條件檢查

```bash
bash .specify/scripts/bash/check-prerequisites.sh
```

若有任何先決條件未通過，**停止**並告知使用者需要先解決的問題。
從輸出的 `Layout from Owner:` 一行取得 Layout（`single` 或 `split`）。

### Step 2: 決定要處理的任務清單

**Layout = single**：任務清單為 `tasks.md`。若 $ARGUMENTS 是 `frontend`／`backend` 或 `TASK-FE-`／`TASK-BE-` 編號，告知使用者本功能未拆檔，改用 `TASK-NNN`。

**Layout = split**：決定本次處理哪一邊（`SIDE`）：
- $ARGUMENTS 為 `TASK-FE-*` → `frontend`；`TASK-BE-*` → `backend`
- $ARGUMENTS 為 `frontend`／`backend` → 該邊
- 未指定 → **詢問使用者**要處理哪一邊（通常是 `spec.md` 中標註該邊的 Owner），不要自行決定

本次只處理 `tasks-${SIDE}.md`，**不得修改另一邊的任務清單**，也不得在 `tasks.md` 總覽中打勾或新增任務。

### Step 3: 讀取實作上下文

1. 讀取 `.specify/memory/constitution.md`
2. 讀取 `specs/NNN-feature-name/spec.md`
3. 讀取 `plan.md`；split 時另讀 `plan-${SIDE}.md`
4. 讀取任務清單（single：`tasks.md`；split：`tasks-${SIDE}.md`，並讀 `tasks.md` 總覽取得跨邊依賴）
5. 讀取 `specs/NNN-feature-name/contracts/`（若有）

### Step 4: 確定下一個任務

若未指定特定任務：
- 找到任務清單中第一個 `[ ]` 的任務（只有 `[ ]` 算可承接；code block 內的範例不算）
- 確認其所有前置任務都已完成 `[x]`
  - split 時，任務文字若寫「依賴 TASK-BE-010」這類**另一邊**的編號，要到另一邊的任務清單確認其狀態；
    未完成就不可承接，向使用者報告在等另一邊的哪條任務
- `[~]` 代表已有人在動、`[r]`／`[c]` 代表卡住，都不可逕自承接。
  若前面存在這類任務，先向使用者報告卡在哪、等什麼，再問要不要跳過往下做

若指定了特定任務：
- 跳至指定任務
- 警告若前置任務（含另一邊的依賴）尚未完成

### Step 5: 執行任務

對每個任務：

1. **宣告**正在執行的任務（任務編號: 任務標題）
2. **實作**任務內容，嚴格遵守：
   - constitution.md 中的程式碼品質標準
   - 計劃中的架構決策（split 時以 `plan-${SIDE}.md` 為主，API 以 `plan.md` 第 3 節與 `contracts/` 為準）
   - TDD: 測試任務先寫測試（讓測試 RED），實作任務再寫程式碼（讓測試 GREEN）
3. **驗證**任務的完成條件
4. **更新**任務清單，將該任務的 `[ ]` 改為 `[x]`，並將這次變更提交
   - 完成時間是從「改為 `[x]` 的那個 commit」推導的（憲法 Article XIII），
     所以翻勾必須實際進 git，不能只留在工作區
   - 若任務尚未完成但已卡住，改成 `[r]`（等審核／驗證／環境／另一邊）或 `[c]`（等客戶），
     並在任務文字補上阻塞對象（如「等後端部署 stage，見 TASK-BE-011」）；不要用 `[~]` 當作待辦的暫存區
5. split 時若發現需要另一邊修改（例如契約有誤），**不要替另一邊改程式碼或任務清單**，
   向使用者報告，由另一邊的 Owner 處理或透過 `/speckit-converge` 補任務

### Step 6: 循序執行

按照以下規則執行：
- `[S]` 任務：逐一循序執行
- `[P]` 任務：可在同一輪次中並行說明，但仍逐一確認完成

每完成一個 Phase，暫停並向使用者報告進度。

### Step 7: 完成確認

完成本次範圍內所有任務後：
1. 執行完整的測試套件
2. 確認所屬的驗收場景通過
3. 更新任務清單的進度表
4. split 時，回報另一邊的完成狀況與尚未達成的里程碑（依 `tasks.md` 總覽）
5. 兩邊（或 single 的全部）任務都完成後，提示使用者執行 `/speckit-checklist` 進行最終品質檢查

## 重要原則

- **永不跳過 RED 階段**: 測試任務必須先讓測試失敗，確認測試真的在測對的東西
- **一次一個任務**: 不要跳躍，按照拓撲順序執行
- **失敗就停**: 若測試無法通過，停下來分析原因，不要繼續下一個任務
- **只動自己這一邊**: 拆檔時不修改另一邊的任務清單或程式碼範圍
- **程式碼必須符合憲法**: 任何違反 constitution.md 的程式碼都需要立即修正
