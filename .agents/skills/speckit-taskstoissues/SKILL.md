---
name: speckit-taskstoissues
description: 把任務清單（tasks.md，或前後端拆檔時的 tasks-frontend.md／tasks-backend.md）中既有的任務轉換成依賴排序的 GitHub Issues。當使用者想把功能任務清單同步成 GitHub issues、追蹤或分派工作時使用。僅在遠端為 GitHub repo 時執行，並會去重避免重複建立。
argument-hint: "（可選）GitHub issue 的篩選條件或標籤"
user-invocable: true
disable-model-invocation: false
metadata:
  source: "adapted from github-spec-kit taskstoissues command → kiitzu 慣例"
---

# /speckit-taskstoissues

## 輸入

$ARGUMENTS（可選：GitHub issue 的篩選條件或標籤）

## 你的任務

### Step 1: 先決條件檢查

執行：
```bash
bash .specify/scripts/bash/check-prerequisites.sh
```

取得目前功能目錄，並從 `Layout from Owner:` 取得 Layout（`single`／`split`）。所有路徑使用絕對路徑。
檢查失敗時**停止**並回報，不要從格式錯誤的任務清單建立 issue。

### Step 2: 載入文件

1. **若存在**：讀取 `.specify/memory/constitution.md`（專案原則與治理約束）。
2. 讀取 `specs/NNN-feature-name/spec.md` 標頭的 `Owner`。
3. 讀取任務清單：
   - single：`tasks.md`
   - split：`tasks-frontend.md` 與 `tasks-backend.md`（`tasks.md` 為總覽，**不含任務，不建立 issue**）
4. 只取 code block 外、以狀態勾選框開頭的清單項目作為任務。

### Step 3: 確認 Git 遠端

執行：
```bash
git config --get remote.origin.url
```

> ⚠️ **只有在遠端是 GitHub URL 時才繼續後續步驟。**

### Step 4: 抓取既有 Issues 以去重

在建立任何東西之前，先蒐集你即將處理的任務編號集合：
- single：`TASK-` 後接數字，如 `TASK-001`
- split：`TASK-FE-` 或 `TASK-BE-` 後接數字，如 `TASK-FE-001`、`TASK-BE-003`

然後用 `gh issue list`（或 GitHub MCP 的 `list_issues`）查詢已涵蓋這些編號的 issue：

```bash
gh issue list --state all --limit 100 --json number,title
```

- 對每個 issue 標題，用邊界比對任務編號樣式 `\bTASK-(?:FE-|BE-)?\d+[a-z]?\b`（避免像 `XTASK-001` 被誤配，也避免 `TASK-001` 誤配到 `TASK-FE-001`），同時能辨識寫成 `TASK-001 …`、`TASK-001: …` 或 `[TASK-001] …` 的標題。
- 命中你的任務編號時，把該編號標記為「已有 issue」。
- 一旦所有任務編號都比對到、或沒有下一頁時就停止分頁，避免在 issue 歷史龐大的 repo 反覆抓取。

### Step 5: 決定指派對象

依 `Owner` 決定每個任務的 assignee（憲法 Article XIII：任務文字不寫人名，負責人取自 `spec.md`）：
- single：所有任務指派給唯一的 `Owner`
- split：`tasks-frontend.md` 的任務指派給標註 `(frontend)` 的 Owner，`tasks-backend.md` 指派給 `(backend)` 的 Owner

去掉 `@` 後以 `gh api users/<name>` 確認是有效的 GitHub 帳號：
- 有效 → 建立 issue 時加上 `--assignee <name>`
- 無效或不是 GitHub 帳號（例如填的是中文姓名）→ **不指派**，照常建立 issue，並在摘要中列出未指派的原因

### Step 6: 為每個任務建立 Issue

依任務清單中的順序建立（split 時先後端、再前端，跨邊依賴寫在 body 中）。對每個任務：

- 任務行以 markdown checkbox 開頭，先剝除前綴 `- [ ]`（以及任何 `[P]`/`[S]`/`[US#]` 標記與粗體 `**`），還原出任務編號與描述。
- 以單一標準標題格式建立 issue：`<任務編號>: <描述>`（編號寫一次，後接任務描述）。
  例如 `- [ ] [S] **TASK-BE-001**: 建立專案結構` → 標題 `TASK-BE-001: 建立專案結構`。
- body 包含任務描述、驗收條件，以及任務文字中提到的依賴編號。

```bash
gh issue create --title "TASK-BE-001: 建立專案結構" --body "<任務描述、驗收條件與依賴>" --assignee <name>
```

- **略過**編號已存在於 Step 4 集合中的任務，並回報（例如：`TASK-BE-001 已有 issue，略過`）。
- 只為尚無對應 issue 的任務建立。
- 若 $ARGUMENTS 提供了標籤，用 `--label` 一併加上。

> ⚠️ **在任何情況下，都絕不在與遠端 URL 不符的 repo 建立 issue。**

### Step 7: 輸出摘要

向使用者回報：
- Layout 與讀取的任務清單
- 新建立的 issue 數量與連結（split 時依前端／後端分組）
- 略過（已存在）的任務數量
- 指派結果；未能指派的 Owner 與原因
- 目標 repo 與遠端 URL 確認
