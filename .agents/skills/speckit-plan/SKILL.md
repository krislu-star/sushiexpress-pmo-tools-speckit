---
name: speckit-plan
description: 將 spec.md 的業務需求轉化為技術實作計劃（plan.md；前後端由不同人負責時另有 plan-frontend.md／plan-backend.md）。當 spec 已完成、要決定技術架構與設計（HOW）、進行 Phase -1 憲法閘門檢查時使用。
argument-hint: "（可選）指定分支名稱；否則使用當前 git 分支"
user-invocable: true
disable-model-invocation: false
metadata:
  source: ".claude/commands/speckit.plan.md (ported to skill)"
---

# /speckit-plan

將 spec.md 的業務需求轉化為技術實作計劃。

## 輸入

$ARGUMENTS（可選，指定分支名稱；否則使用當前 git 分支）

## 你的任務

### Step 1: 讀取所有必要文件

1. 讀取 `.specify/memory/constitution.md`（取得技術棧和架構約束）
2. 讀取當前功能的 `specs/NNN-feature-name/spec.md`
3. 確認 spec.md 品質核對清單已完成

### Step 2: 執行腳本建立計劃檔案

```bash
bash .specify/scripts/bash/setup-plan.sh
```

腳本依 `spec.md` 的 `Owner` 決定拆檔方式（憲法 Article V、XIII），並在輸出的 `Layout:` 一行告知結果：

| `Owner` | Layout | 建立的檔案 |
|---|---|---|
| `@bob`（一人） | `single` | `plan.md`（完整計劃模板）、`contracts/` |
| `@alice (frontend), @bob (backend)` | `split` | `plan.md`（共用模板）、`plan-frontend.md`、`plan-backend.md`、`contracts/` |

- 腳本報錯（`Owner` 未填、多人未標註、只標一邊）時，**停止**並請使用者先修正 `spec.md` 的 `Owner`，不要自行猜測負責人。
- 腳本回報「任務清單已產出，不得轉換」時，**停止**並說明：需另開新 spec，以 `DependsOn` 指向本 spec。
- 腳本對既有檔案發出警告（例如不拆檔卻有分邊計劃）時，向使用者報告並詢問如何處理，不要自行刪檔。

後續步驟依 Layout 分流。

### Step 3: Phase -1 憲法閘門檢查

在填充計劃之前，逐一確認憲法中的每個 Article：

- **Article I**: 確認選用的技術棧不違反禁止清單
- **Article II**: 確認程式碼品質標準已納入設計
- **Article III**: 確認 TDD 方式已計劃（測試先於實作）
- **Article IV**: 確認安全措施已識別
- **Article V**: 確認 spec.md 已完成（無未解決的 [NEEDS CLARIFICATION]）
- **Article XIII**: 確認 `Owner` 格式有效，且 Layout 與 Owner 相符

若任何閘門未通過，**停止**並通知使用者需要先解決的問題。閘門清單寫在 `plan.md` 的 Phase -1。

### Step 4A: 填充 plan.md（Layout = single）

根據 spec.md 的需求和 constitution.md 的約束，填充：

1. **技術棧選擇表**：列出每層技術和選擇原因
2. **架構決策記錄（ADR）**：重要決策的 背景/決策/結果
3. **系統架構圖**：ASCII 或 Mermaid 圖示元件關係
4. **前後端範圍切分（2.3）**：**必填**，見 Step 4C
5. **資料模型**：實體定義和資料庫 Schema
6. **API 合約**：每個端點的 Request/Response 格式
7. **測試策略**：每個驗收場景對應的測試類型和位置，並標註歸屬（前端／後端）
8. **安全考量**：對應 spec 中的安全需求
9. **依賴清單**：新增的套件，附版本和用途
10. **實作階段**：每個階段都要標註歸屬（前端／後端／兩者）

### Step 4B: 填充三份計劃（Layout = split）

**`plan.md` 只放兩邊共用的內容**：

1. Phase -1 閘門
2. 技術棧總覽與**跨邊** ADR（認證方式、API 風格、錯誤格式等影響兩邊的決策）
3. 系統架構全貌（元件圖、執行流程）
4. **前後端範圍切分（2.3）**：**必填**，見 Step 4C
5. **API 合約（第 3 節）**：**API 合約只能寫在這裡與 `contracts/`**
6. 跨邊測試策略：契約測試、E2E，**每項都要指定由哪一邊撰寫**（每條任務恰好屬於一邊）
7. 跨邊安全考量、部署與上線順序
8. 實作階段總覽：只列跨邊依賴順序，供 `tasks.md` 總覽引用

**`plan-backend.md`** 只寫後端的 HOW：技術選型、後端 ADR、資料模型與 Schema、模組與業務邏輯、後端測試策略、安全／效能、依賴、部署、實作階段。

**`plan-frontend.md`** 只寫前端的 HOW：技術選型、前端 ADR、頁面與路由、元件設計、狀態管理、契約定案前的 mock 策略、前端測試策略、安全／效能／無障礙、依賴、實作階段。

拆檔時的硬性規則：
- 分邊計劃**不得另寫 API 合約**，只能引用 `plan.md` 第 3 節的端點。
- 分邊計劃**不得寫任何專案管理欄位**（負責人、開始日、工期），這些只在 `spec.md`。
- 兩份分邊計劃都要有實質內容；若其中一邊其實不涉及，代表不該拆檔，**停止**並請使用者把 `Owner` 改成一人。
- 單邊細節（資料模型、元件設計）不得留在 `plan.md`。

### Step 4C: 前後端範圍切分（兩種 Layout 皆必填）

依憲法 Article V，`plan.md` 的 2.3 節必須把前端與後端分開描述，讓任一方能單獨看懂自己的範圍：

- **前端範圍**與**後端範圍**各自寫出「負責」與「不負責」；「不負責」不得留白，
  它才是真正劃清界線的欄位。
- 不拆檔的單邊功能仍要保留另一側，寫明「本功能不涉及」，不得整節刪除。
- 交界只能是 API 合約；若某項需求無法用契約描述雙方責任，
  代表切分還不夠清楚，回頭修正而非含糊帶過。
- 依 Article XII，`cms/` 為唯讀模組，不得列入任何一側的實作範圍。

### Step 5: 生成 API 合約文件（若有 API）

在 `specs/NNN-feature-name/contracts/` 目錄下：
- 建立 `openapi.yaml` 或 `schema.graphql`（依技術棧）
- 完整定義所有端點、請求體、回應格式、錯誤碼
- 內容必須與 `plan.md` 的 API 合約一致

### Step 6: 輸出摘要

向使用者展示：
- Layout（不拆檔／拆檔）與建立的檔案
- 技術棧選擇摘要
- 主要架構決策
- **前端範圍／後端範圍各一段摘要**（各自負責什麼、不負責什麼）
- 資料模型摘要
- API 端點清單
- 下一步提示：完善 plan 後執行 `/speckit-tasks`；並提醒**任務產出後不得再轉換拆檔方式**

## 重要原則

- 計劃描述 **HOW**，但只到架構層次，不寫具體程式碼
- 前端與後端的範圍必須分開描述，任何人只讀其中一側就能知道自己的工作邊界
- 技術選擇必須符合 constitution.md 中的約束
- 拆檔與否只看 `spec.md` 的 `Owner`，不得自行決定
- 所有 plan 決策必須能追溯到 spec.md 中的具體需求
