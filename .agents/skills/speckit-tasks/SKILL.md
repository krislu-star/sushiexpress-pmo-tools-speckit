---
name: speckit-tasks
description: 從 plan 生成可執行、依賴排序、遵循 TDD 的任務清單（tasks.md；前後端由不同人負責時為 tasks-frontend.md／tasks-backend.md 加總覽）。當技術計劃已完成、要把架構拆解成 TASK 微任務時使用。
argument-hint: "（可選）指定分支名稱；否則使用當前 git 分支"
user-invocable: true
disable-model-invocation: false
metadata:
  source: ".claude/commands/speckit.tasks.md (ported to skill)"
---

# /speckit-tasks

從計劃生成可執行的任務清單。

## 輸入

$ARGUMENTS（可選，指定分支名稱；否則使用當前 git 分支）

## 你的任務

### Step 1: 判斷 Layout 並讀取規格文件

依 `spec.md` 的 `Owner` 判斷 Layout（憲法 Article V、XIII）：

- `Owner` 為一人（如 `@bob`）→ **single**
- `Owner` 為 `@alice (frontend), @bob (backend)` → **split**
- 格式無效（未填、多人未標註、只標一邊）→ **停止**，請使用者先修正 `spec.md`

確認計劃檔案與 Layout 相符（single 只有 `plan.md`；split 另有 `plan-frontend.md`、`plan-backend.md`），不符時**停止**並請使用者重新執行 `/speckit-plan`。

若任務清單**已經存在**且格式與 Layout 不符，**停止**：任務產出後不得轉換拆檔方式，需另開新 spec 並以 `DependsOn` 指向本 spec。

讀取：
1. `specs/NNN-feature-name/spec.md`（取得驗收場景和使用者故事）
2. `plan.md`；split 時另讀 `plan-frontend.md`、`plan-backend.md`
3. `specs/NNN-feature-name/contracts/`（取得 API 合約，若有）
4. `.specify/memory/constitution.md`（取得測試策略與 Article XIII 任務書寫規範）

### Step 2A: 生成 tasks.md（Layout = single）

從模板 `.specify/templates/tasks-template.md` 建立 `tasks.md`，並填入：

**Phase 0: 環境設置**
- 依賴安裝任務
- 環境變數設定
- 資料庫/服務連線確認

**Phase 1: 資料層**（每個實體一組任務對）
- 先寫測試（RED），再寫實作（GREEN）
- Migration 任務
- Repository 任務

**Phase 2: 業務邏輯**（每個使用者故事一組任務對）
- 先寫服務層測試，再寫實作
- 驗證邏輯測試

**Phase 3: API 層**（每個端點一組任務對）
- 先寫 API 測試（覆蓋 SC-001~SC-00N），再寫實作
- 錯誤處理任務

**Phase 4: 整合測試**
- 端到端場景測試
- 效能驗證
- 安全驗證

**Phase 5: 收尾**
- 文件更新
- 覆蓋率報告
- 最終審查

任務編號為 `TASK-NNN`。

### Step 2B: 生成三份任務檔（Layout = split）

1. **`tasks-backend.md`**：從 `.specify/templates/tasks-backend-template.md` 建立，依 `plan-backend.md` 拆解。
   典型階段：環境設置 → API 契約草案 → 資料層 → 業務邏輯 → API 層 → 部署 stage 與聯調修正 → 收尾。
2. **`tasks-frontend.md`**：從 `.specify/templates/tasks-frontend-template.md` 建立，依 `plan-frontend.md` 拆解。
   典型階段：環境設置與契約確認／mock → 元件與頁面 → 狀態管理 → 串接真 API 與聯調 → 收尾。
3. **`tasks.md`**：從 `.specify/templates/tasks-overview-template.md` 建立，**只寫總覽**：
   - 指向兩份分邊任務清單
   - 跨邊依賴順序（依 `plan.md` 第 7 節，用實際任務編號）
   - 里程碑（以任務編號定義達成條件，不寫日期）

拆檔時的硬性規則：
- **每條任務恰好屬於一邊**。需要兩邊合作的工作（契約確認、聯調、E2E）必須拆成兩條分邊任務，
  或依 `plan.md` 指定的撰寫方歸到那一邊；**不得**在 `tasks.md` 寫共用任務。
- **`tasks.md` 不得出現任何勾選項目**（`- [ ]` 等），否則會被 PM 視圖誤計。
- 前端編號 `TASK-FE-NNN`、後端編號 `TASK-BE-NNN`，兩邊各自從 001 遞增。
- 跨檔依賴寫在任務文字中，如「依賴 TASK-BE-010」；被引用的編號必須實際存在。
- 任務文字不寫人名；負責人由分邊檔對應到 `spec.md` 的 `Owner`。

### Step 3: 標記任務屬性

每個任務必須（憲法 Article XIII）：
- 是 `-` 清單項目，**不可寫成 `###` 標題**——標題形式不會被任何 PM 視圖解析
- 不可放在 code block（```）內——code block 內的內容不算任務
- 有唯一編號（single：`TASK-NNN`；split：`TASK-FE-NNN`／`TASK-BE-NNN`），同一 spec 內不重用
  （子任務可用字母後綴，如 `TASK-006a`、`TASK-BE-006a`）
- 一律以 `[ ]` 建立，**絕不可直接產生 `[x]`**——完成時間靠 `[ ]`→`[x]` 的 commit 推導
- 標記 `[P]`（可平行）或 `[S]`（必須循序），位置在狀態標記之後
- 有明確的**驗收條件**（完成的定義）
- 對應到 spec.md 中的驗收場景或功能需求

**標記規則**:
- 相互依賴的任務標記 `[S]`
- 獨立可並行的任務標記 `[P]`
- 寫測試的任務永遠在對應實作之前

### Step 4: 更新進度追蹤表並驗證

1. 計算每個 Phase 的任務數並填入每份任務清單底部的進度表（split 時兩份分邊檔各自計算；`tasks.md` 總覽沒有進度表）。
2. 執行檢查，確認 Layout、編號格式與重複都通過：

   ```bash
   bash .specify/scripts/bash/check-prerequisites.sh
   ```

   忽略「uncommitted changes」警告；其餘錯誤必須修正後再提交。

3. 提交所有任務檔（此時全部為 `[ ]`），再開始實作。
   先提交才會有「未完成」的基準，之後的翻勾才留得下完成時間。

### Step 5: 輸出摘要

向使用者展示：
- Layout 與產出的檔案
- 總任務數和各 Phase 分布（split 時前後端分開列）
- 可平行執行的任務數（提示效率機會）
- 預估的實作順序；split 時列出跨邊依賴與里程碑
- 提醒：**任務已產出，之後不得轉換拆檔方式**
- 下一步提示：執行 `/speckit-implement` 開始實作（split 時可指定 `frontend` 或 `backend`）

## 重要原則

- **TDD 優先**: 測試任務永遠在實作任務之前
- **原子性**: 每個任務對應一個 commit 或一個獨立的檔案變更
- **可驗證**: 每個任務都有明確的完成條件
- **可追溯**: 每個任務都能對應到 spec 或 plan 中的具體需求
- 一般產生 10-20 個微任務（split 時為每一邊）；超過 25 個需要考慮拆分功能
