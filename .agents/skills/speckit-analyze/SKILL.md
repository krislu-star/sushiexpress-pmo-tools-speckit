---
name: speckit-analyze
description: 跨文件一致性分析，檢查 spec、plan、tasks 之間的對齊程度（含前後端拆檔時的分邊檔與 Owner 一致性）。當任務清單已生成、要在實作前做一致性/品質檢查、確認需求覆蓋與可追溯性時使用。
argument-hint: "（可選）指定分支名稱；否則使用當前 git 分支"
user-invocable: true
disable-model-invocation: false
metadata:
  source: ".claude/commands/speckit.analyze.md (ported to skill)"
---

# /speckit-analyze

跨文件一致性分析：檢查 spec、plan、tasks 之間的對齊程度。

## 輸入

$ARGUMENTS（可選：指定分支名稱；否則使用當前 git 分支）

## 你的任務

### Step 1: 判斷 Layout 並載入所有文件

依 `spec.md` 的 `Owner` 判斷 Layout（憲法 Article V、XIII）：`Owner` 一人 → `single`；`@alice (frontend), @bob (backend)` → `split`。

讀取：
1. `.specify/memory/constitution.md`
2. `specs/NNN-feature-name/spec.md`
3. `plan.md`（若存在）；split 時另讀 `plan-frontend.md`、`plan-backend.md`（若存在）
4. single：`tasks.md`；split：`tasks.md`（總覽）、`tasks-frontend.md`、`tasks-backend.md`（若存在）
5. `specs/NNN-feature-name/contracts/`（若存在）

可先執行 `bash .specify/scripts/bash/check-prerequisites.sh`，把腳本報出的錯誤直接列入報告的「錯誤」。

### Step 2: 執行一致性分析

#### 2.1 Spec vs Constitution

- [ ] 技術棧規範：spec 沒有提到被禁止的技術？
- [ ] 規格優先：spec 只描述 WHAT/WHY？
- [ ] 分支命名：分支名稱符合 `NNN-feature-name` 格式？
- [ ] **Owner 格式**：一人不標註；或恰好兩人、分別標註 `(frontend)` 與 `(backend)`？

#### 2.2 Plan vs Spec

- [ ] **需求覆蓋**：plan 中每個架構決策都對應到 spec 中的功能需求？
- [ ] **技術合規**：plan 選用的技術符合 constitution 的約束？
- [ ] **驗收對應**：每個驗收場景（SC-NNN）都在 plan 的測試策略中有對應？（split 時可分散在三份計劃，但每個 SC 都要有歸屬的一邊）
- [ ] **孤立決策**：plan 中是否有無法追溯到 spec 需求的架構決策？

#### 2.3 Tasks vs Plan

- [ ] **完整性**：tasks 涵蓋了 plan 中所有的技術元件？（split 時：`plan-frontend.md` 的元件由 `tasks-frontend.md` 涵蓋，`plan-backend.md` 由 `tasks-backend.md` 涵蓋）
- [ ] **TDD 順序**：每個實作任務之前都有對應的測試任務？
- [ ] **依賴正確性**：任務的 `[S]/[P]` 標記反映了真實的依賴關係？
- [ ] **驗收可追溯**：每個任務都有明確的完成條件？
- [ ] **編號格式**：single 為 `TASK-NNN`；split 為 `TASK-FE-NNN`／`TASK-BE-NNN`，且不重複？

#### 2.4 跨文件一致性

- [ ] **實體命名**：spec、plan、tasks 中使用的實體名稱是否一致？
- [ ] **API 端點**：plan 和 contracts 中的端點定義是否匹配？
- [ ] **使用者故事對應**：每個 US-NNN 都在 tasks 的至少一個任務中被處理？

#### 2.5 拆檔一致性（Layout = split 才檢查）

- [ ] **檔案配置**：三份計劃與三份任務檔都存在，且與 `Owner` 相符？
- [ ] **API 合約唯一**：只有 `plan.md` 第 3 節與 `contracts/` 定義端點？分邊計劃是否另寫了一份（重複定義視為錯誤）？
- [ ] **專案管理欄位**：分邊計劃與任務檔是否寫了負責人、開始日、工期等欄位（只能在 `spec.md`）？
- [ ] **單邊細節歸位**：`plan.md` 是否殘留資料模型、元件設計等單邊內容？
- [ ] **總覽不含任務**：`tasks.md` 沒有任何勾選項目（code block 外）？
- [ ] **任務歸屬**：每條任務只屬於一邊？是否有描述明顯屬於另一邊的任務（例如 `tasks-frontend.md` 裡寫 migration）？
- [ ] **合作工作已拆分**：`plan.md` 列出的跨邊工作（契約確認、聯調、E2E）都已拆成分邊任務，或歸到 plan 指定的撰寫方？
- [ ] **跨檔依賴有效**：任務文字與 `tasks.md` 總覽引用的 `TASK-FE-*`／`TASK-BE-*` 編號都實際存在？
- [ ] **里程碑可達成**：總覽的每個里程碑都以存在的任務編號定義？

### Step 3: 生成分析報告

輸出格式：

```markdown
# 一致性分析報告

## 日期: [今天日期]
## 功能: [功能名稱]
## Layout: single | split（Owner: [Owner]）

### ✅ 通過的檢查項目
- [項目清單]

### ⚠️ 警告（建議修正，但不阻擋進行）
- [警告描述]: [具體位置] → [建議修正]

### ❌ 錯誤（必須修正後才能繼續）
- [錯誤描述]: [具體位置] → [必要修正]

### 總結
- 通過: N 項
- 警告: N 項
- 錯誤: N 項
- 整體狀態: ✅ 準備就緒 | ⚠️ 需要注意 | ❌ 需要修正
```

### Step 4: 建議行動

根據分析結果：
- **若有錯誤**: 列出必須修正的具體步驟
- **若只有警告**: 說明風險並讓使用者決定
- **若全部通過**: 確認可以繼續下一步
- **若 Owner 與已產出的任務格式不符**: 說明任務產出後不得轉換拆檔方式，需另開新 spec 並以 `DependsOn` 指向本 spec
