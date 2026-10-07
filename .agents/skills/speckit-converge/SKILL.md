---
name: speckit-converge
description: 評估目前程式碼相對於功能 spec/plan/tasks 的落差，並把尚未完成的工作以新任務附加到任務清單末端（前後端拆檔時附加到對應的分邊檔），讓 implement 能補齊。當 implement 跑過一輪後、想確認實作是否真的滿足規格、需要收斂剩餘工作時使用。
argument-hint: "（可選）指定分支名稱；否則使用當前 git 分支"
user-invocable: true
disable-model-invocation: false
metadata:
  source: "adapted from github-spec-kit converge command → kiitzu 慣例"
---

# /speckit-converge

## 輸入

$ARGUMENTS（可選：指定分支名稱；否則使用當前 git 分支）

## 目標

收斂「規格要求」與「程式碼實作」之間的落差。以 spec、plan、tasks 文件
為**唯一的意圖來源**（並以 `constitution.md` 為治理約束），評估目前程式碼狀態，
判斷哪些功能需求、驗收標準、計劃決策、既有任務尚未滿足或只部分滿足，
然後**把每一項剩餘工作以新的、可追溯的任務附加到任務清單末端**，讓
`/speckit-implement` 能補完。

本指令應在 `/speckit-implement` 已對目前任務清單執行過、且 `/speckit-tasks`
已產出完整任務清單之後才使用。

> 這**不是** diff 工具，不追蹤變更歷史。它評估的是程式碼**當下的狀態**相對於功能文件的落差 —— 不看 git、不比較分支、不看歷史。

## Layout（拆檔方式）

依 `spec.md` 的 `Owner` 決定（憲法 Article V、XIII），`check-prerequisites.sh` 輸出的 `Layout from Owner:` 一行會告知：

| Layout | 計劃 | 任務清單（附加目標） |
|---|---|---|
| `single` | `plan.md` | `tasks.md` |
| `split` | `plan.md`（共用）＋ `plan-frontend.md`、`plan-backend.md` | `tasks-frontend.md`、`tasks-backend.md`（`tasks.md` 為總覽，**不得附加任務**） |

## 操作限制

**只附加，永不改寫**：本指令**唯一**的寫入動作是把新的 `## Phase N: 收斂 (Convergence)`
區段附加到任務清單末端（split 時為對應的分邊檔）。它**不得**：

- 以任何方式修改 `spec.md` 或任何計劃檔；
- 改寫、重新編號、重新排序或刪除任何既有任務（包含先前收斂階段產生的任務）；
- split 時在 `tasks.md` 總覽中新增任何勾選項目；
- 修改、建立或刪除任何應用程式碼 —— 完成這些附加任務是 `/speckit-implement` 的職責。

當程式碼已滿足所有要求時，本指令必須讓**所有任務清單一個位元組都不變**（不留空的收斂標頭），並回報「已收斂」。
split 時若只有一邊有落差，只附加到那一邊，另一邊維持不變。

**憲法權威**：`.specify/memory/constitution.md` 中的 MUST 條款**不可協商**。
違反 MUST 的程式碼是最高嚴重度發現，並產生對應的修正任務。若憲法仍是未填寫的模板，則優雅地略過憲法檢查，而非報錯。

## 執行步驟

### Step 1: 先決條件檢查

執行：
```bash
bash .specify/scripts/bash/check-prerequisites.sh
```

解析輸出，取得目前功能目錄與 Layout，推導絕對路徑：
- SPEC = `specs/NNN-feature-name/spec.md`
- PLAN = `plan.md`；split 時另有 PLAN_FE = `plan-frontend.md`、PLAN_BE = `plan-backend.md`
- TASKS = `tasks.md`（single）；split 時為 TASKS_FE = `tasks-frontend.md`、TASKS_BE = `tasks-backend.md`，`tasks.md` 僅作總覽參考
- CONSTITUTION = `.specify/memory/constitution.md`（若存在）

若檢查失敗或任一必要文件缺少，**停止**並明確告知要先執行哪個指令
（缺 spec → `/speckit-specify`；缺 plan → `/speckit-plan`；缺 tasks → `/speckit-tasks`；Owner 與檔案配置不符 → 依錯誤訊息修正）。
不要產出部分結果。

### Step 2: 載入文件（漸進揭露）

只載入每份文件的最小必要內容：

- **spec.md**：功能需求（FR-###）、驗收標準（SC-###，只取需要實作的項目，排除上線後的成效指標與商業 KPI）、使用者故事與其驗收場景、邊界情況。
- **計劃**：架構/技術棧選擇與技術決策、資料模型、各 Phase 與被點名的接觸點（計劃說會建立/修改的檔案或元件）、技術約束。split 時另從 `plan.md` 取 API 合約與 2.3 範圍切分（用來判斷落差屬於哪一邊）。
- **任務清單**：任務編號（用來算下一個 ID 與下一個 Phase 編號）、描述、Phase 分組、引用到的檔案路徑。split 時兩份分邊檔**各自**計算。忽略 code block 內的範例。
- **constitution.md**（若非未填模板）：條款名稱與 MUST/SHOULD 規範性語句。

### Step 3: 建立意圖清單

在內部建立模型（不要原封輸出文件內容）：

- **需求清單**：每個 FR-### / SC-### / 使用者故事驗收場景（如 `US1/AC2`）一個穩定的 key，加上 plan 決策與憲法條款所帶來的可實作義務。
- **程式碼範圍地圖**：從計劃與任務清單點名的檔案路徑，加上針對每個需求概念的關鍵字搜尋，推導出要評估的原始碼檔案與元件集合。評估**只**限這個範圍，不要超出文件所定義的範圍去推測。

### Step 4: 評估程式碼並分類發現

對意圖清單中的每一項，檢查目前範圍內的程式碼，只在有落差時產生一筆 `Finding`。
以**落差類型**分類：

- **`missing`**：所需工作在程式碼中完全不存在。
- **`partial`**：工作存在，但尚未完全滿足需求／驗收標準／計劃決策。
- **`contradicts`**：程式碼所做的事與陳述意圖或憲法 MUST 條款相衝突。
- **`unrequested`**：程式碼含有 spec/plan/tasks 未要求的工作（提出以供留意 —— converge 不刪程式碼，只附加一個任務去審查/正當化或移除）。

每筆 `Finding` 記錄：穩定 id、可追溯的 `source-ref`、`gap-type`、嚴重度，以及含證據（觀察到的檔案/區域）的簡短人類可讀描述。

**split 時另外記錄 `side`（`frontend`／`backend`）**，依 `plan.md` 2.3 範圍切分與證據所在位置判斷：
- 落差只在一邊 → 該邊。
- 需要兩邊都動（例如契約欄位缺漏）→ **拆成兩筆發現**，各自一個 side；不得產生共用任務。
- 無法判斷屬於哪一邊 → 在摘要中標記並詢問使用者，暫不附加該筆。

**邊界情況：**
- **幾乎沒有程式碼**：把整個規格範圍當作 `missing` 的剩餘工作，而非報錯。
- **沒有剩餘**：產生零筆發現，走 Step 7 的「已收斂」分支。

### Step 5: 指派嚴重度

- **CRITICAL**：違反憲法 MUST 條款，或阻擋 P1 使用者故事基本功能的 `missing`/`contradicts` 落差。
- **HIGH**：核心功能需求或驗收標準的 `missing` 或 `partial` 落差。
- **MEDIUM**：次要需求的 `partial` 落差，或正當性不明的 `unrequested` 新增。
- **LOW**：輕微的部分落差、打磨，或低風險的 `unrequested` 新增。

### Step 6: 呈現本次發現摘要

在附加任何內容之前，先輸出精簡、依嚴重度排序的摘要（尚未寫檔）：

```markdown
## 收斂發現 (Convergence Findings)

| ID | 邊 | 落差類型 | 嚴重度 | 來源 | 證據 | 剩餘工作 |
|----|----|---------|-------|------|------|---------|
| F1 | backend | missing | HIGH  | FR-008 | 範例：path/to/module 未偵測到附加保護 | 加入附加式強制檢查 |
```

（single 時「邊」欄可省略。）

**摘要指標：**
- 檢查的需求／驗收標準數
- 檢查的計劃決策數
- 檢查的憲法條款數（或「略過 —— 模板」）
- 依落差類型的發現數（missing / partial / contradicts / unrequested）
- 依嚴重度的發現數
- split 時：各邊的發現數

### Step 7: 附加收斂任務（或回報已收斂）

**若有一筆以上可行動的發現**（`tasks_appended` 結果）：

對每一份**有發現**的任務清單（single：`tasks.md`；split：`tasks-frontend.md`／`tasks-backend.md` 各自處理），依附加契約附加到**末端**：

1. 掃描該檔所有既有任務編號，令 `M` 為最大值；決定下一個 Phase 編號 `N`（該檔現有最大 Phase + 1）。
2. 寫入單一新區段標頭 `## Phase N: 收斂 (Convergence)`。
3. 每筆可行動發現輸出一個 checklist 項目，CRITICAL/HIGH 優先，指派零填補編號：
   - single：`TASK-{M+1}`、`TASK-{M+2}`…
   - split：前端 `TASK-FE-{M+1}`…、後端 `TASK-BE-{M+1}`…

   ```markdown
   - [ ] [S] **TASK-BE-042**: <祈使句描述> — 依據 <source-ref>（<gap-type>）
   ```

   `<source-ref>` 追溯任務來源：如 `FR-003`、`SC-002`、`US1/AC2`、`plan: 儲存決策`、`Constitution IV`。
   `<gap-type>` 為 `missing`、`partial`、`contradicts`、`unrequested` 之一。
   違反憲法的任務必須**最先**輸出，並標為 `CRITICAL`。
   split 時若一筆發現被拆成兩邊，兩條任務文字互相引用對方編號（如「依賴 TASK-BE-042」）。
4. 絕不重用或重編既有編號。若已存在先前的收斂 Phase，在其下方新增一個**另外編號**的新 Phase，不要動舊的。
5. 更新該檔底部的進度追蹤表。
6. split 時若新增了跨邊依賴，**不要修改** `tasks.md` 總覽，而是在回報中提醒使用者手動更新總覽的依賴順序。

**若沒有可行動的發現**（`converged` 結果）：

- **完全不修改**任何任務清單（不留空的 Phase 標頭）。
- 回報：**「✅ 已收斂 —— 實作已滿足 spec、plan 與 tasks。」**
- 附上檢查了哪些項目的統計。

### Step 8: 下一步交接

- `tasks_appended`：說明在哪個檔案的哪個 Phase 附加了幾個任務，建議執行 `/speckit-implement` 補完（split 時註明是哪一邊）；並提示再跑一次 converge 會找到更少或沒有剩餘項目。
- `converged`：建議進入審查／開 PR，本功能的規格範圍不需要再跑一輪 implement。
