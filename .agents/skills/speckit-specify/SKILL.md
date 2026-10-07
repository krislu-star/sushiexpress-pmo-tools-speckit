---
name: speckit-specify
description: 將功能描述轉化為完整的規格文件（spec.md）。當使用者描述一個新功能需求、想建立功能規格、或啟動 SDD 流程的第一步時使用。只描述 WHAT 與 WHY，不涉及技術實作。
argument-hint: "描述你想要規格化的功能"
user-invocable: true
disable-model-invocation: false
metadata:
  source: ".claude/commands/speckit.specify.md (ported to skill)"
---

# /speckit-specify

將功能描述轉化為完整的規格文件（`spec.md`）。

## 輸入

$ARGUMENTS（使用者提供的功能描述，可以是簡短描述或詳細需求）

## 你的任務

### Step 1: 確認模組歸屬並建立功能目錄

先詢問使用者（若未在 $ARGUMENTS 中指明）：此功能屬於 `frontend`、`backend`，還是跨模組？

> **不得建立 `cms` 功能規格。** 依憲法 Article XII，`cms/` submodule 為唯讀，
> 禁止任何程式碼修改。若需求涉及 CMS，一律歸類為 `backend` 或跨模組，
> 並在 spec 中說明改以 API 或設定介面達成。

執行 bash 腳本：
```bash
# 前端功能
bash .specify/scripts/bash/create-new-feature.sh "Feature Title" frontend

# 後端功能
bash .specify/scripts/bash/create-new-feature.sh "Feature Title" backend

# 跨模組功能
bash .specify/scripts/bash/create-new-feature.sh "Feature Title"
```

這將：
- 計算下一個功能編號（001、002、003…；跨模組統一遞增）
- 建立 `specs/NNN-feature-name/` 目錄（一律位於 `specs/` 根目錄，不分模組子資料夾）
- 從模板複製 `spec.md`
- 建立並切換到 git 分支 `NNN-feature-name`（不加模組 prefix）

> 第二個參數（`frontend`／`backend`）僅作分類參考，不影響目錄結構與分支名稱，也不會寫入 `spec.md`；省略即為跨模組（shared）。腳本雖然仍接受 `cms`，但依 Article XII 不得使用。
> 依憲法 Article VI，後續的 plan／tasks／實作都必須留在這個分支上進行。

### Step 2: 確認 Owner（負責執行的工程師）

`Owner` 由 PM 在此步驟決定，並且**決定後續 plan／tasks 是否拆檔**（憲法 Article V、XIII）。
若 $ARGUMENTS 未指明，詢問使用者：

- 誰負責實際執行？（填工程師，不是 PM）
- 若同時涉及前後端，是否由**不同人**負責？

依回答填入 `spec.md` 標頭的 `Owner`：

| 情況 | 寫法 | 後續 |
|---|---|---|
| 一人負責（只做前端、只做後端，或兩邊都做） | `@bob` | 不拆檔 |
| 前後端由不同人負責 | `@alice (frontend), @bob (backend)` | plan／tasks 拆成前後端各一份 |

- 拆檔時必須**恰好兩人**，分別標註 `(frontend)` 與 `(backend)`；不得只標一邊，也不得多人未標註。
- 同一邊有多人時，只列一位主要 Owner；無法決定就標記 `[NEEDS CLARIFICATION]`，不要猜。
- 使用者尚未決定 Owner 時，保留 `[OWNER]` 並在摘要中提醒：`/speckit-plan` 前必須補齊。
- 提醒使用者：**任務清單產出後不得轉換拆檔方式**，之後才加入另一人負責另一邊，需另開新 spec。

### Step 3: 分析並填充 spec.md

讀取新建立的 `specs/NNN-feature-name/spec.md`，然後：

1. **詢問澄清問題**（若輸入不夠清楚）：
   - 主要使用者是誰？
   - 核心使用場景是什麼？
   - 有什麼明確的限制或禁止行為？
   - 成功的定義是什麼？

2. **填充所有章節**：
   - 概述：2-3 句清晰的 WHAT 和 WHY
   - 使用者故事：至少 2-3 個，格式為「身為…我希望…以便…」
   - 功能需求：用 MoSCoW 排序（Must/Should/Could/Won't）
   - 非功能需求：效能、安全、可用性
   - 驗收場景：正常/邊界/錯誤各至少一個
   - 範圍限制：明確說明不做什麼

3. **品質檢查**：
   - 確認沒有技術實作細節（不提 React、PostgreSQL 等）
   - 確認所有模糊點都標記了 `[NEEDS CLARIFICATION]`
   - 確認驗收標準是可驗證的
   - 確認 `Owner` 格式符合 Step 2 的規則

### Step 4: 輸出摘要

向使用者展示：
- 建立的分支名稱和目錄
- `Owner` 與對應的拆檔方式（不拆檔／拆檔）
- spec.md 的摘要（使用者故事清單、功能需求數量）
- 任何需要使用者確認的 `[NEEDS CLARIFICATION]` 項目
- 下一步提示：完善 spec 後執行 `/speckit-plan`

## 重要原則

- `spec.md` **只描述 WHAT 和 WHY**，絕對不提 HOW
- 不提具體的技術棧、框架、資料庫選型
- 使用 `[NEEDS CLARIFICATION]` 而非假設或猜測
- 驗收場景必須能夠直接轉化為測試案例
- 負責人、排程等專案管理欄位只寫在 `spec.md` 標頭，不分前後端各寫一份
