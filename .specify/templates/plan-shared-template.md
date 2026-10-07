# Implementation Plan: [FEATURE_TITLE]

> **Branch**: `NNN-feature-name`
> **Spec**: `specs/NNN-feature-name/spec.md`
> **Status**: Draft | In Review | Approved
> **Author**: [AUTHOR]
> **Date**: [DATE]
> **分邊計劃**: `plan-frontend.md`、`plan-backend.md`

> 本模板用於**拆檔**的功能（`spec.md` 的 `Owner` 為前後端各一人）。本檔只放**前後端共用**的內容（憲法 Article V），
> 各自的 HOW 寫在 `plan-frontend.md`／`plan-backend.md`。負責人、排程等專案管理欄位只寫在 `spec.md` 標頭（Article XIII）。

---

## Phase -1: 憲法閘門檢查 (Constitution Gates)

> 在繼續之前，確認以下所有憲法條款：

- [ ] **Article I**: 所使用的技術棧已在本檔或分邊計劃中明確列出
- [ ] **Article II**: 程式碼品質標準已納入任務設計
- [ ] **Article III**: 測試策略符合 TDD 要求（測試先於實作）
- [ ] **Article IV**: 安全需求已識別並計劃處理
- [ ] **Article V**: `spec.md` 已完成並通過品質核對清單
- [ ] **Article V**: 前後端範圍已於 2.3 分開描述（含「不負責」與交界契約）
- [ ] **Article V**: `plan-frontend.md`、`plan-backend.md` 皆已建立；API 合約只寫在本檔第 3 節與 `contracts/`
- [ ] **Article XIII**: `spec.md` 的 `Owner` 為兩人，分別標註 `(frontend)`、`(backend)`
- [ ] **Article VIII**: 所有文件將與程式碼同步版控

---

## 1. 技術背景 (Technical Context)

### 1.1 技術棧總覽

> 各層細節與選擇原因寫在分邊計劃；此處只列總覽與跨邊共用的工具。

| 層次 | 技術 | 版本 | 細節見 |
|------|------|------|-------|
| 前端 | [技術名稱] | [版本] | `plan-frontend.md` |
| 後端 | [技術名稱] | [版本] | `plan-backend.md` |
| 資料庫 | [技術名稱] | [版本] | `plan-backend.md` |
| E2E 測試 | [技術名稱] | [版本] | 本檔第 4 節 |
| CI/CD | [技術名稱] | [版本] | 本檔第 6 節 |

### 1.2 跨邊架構決策記錄 (ADR)

> 只記錄影響兩邊的決策（如認證方式、API 風格、錯誤格式）。單邊決策寫在分邊計劃。

**ADR-001**: [決策標題]
- **狀態**: Accepted
- **背景**: [為什麼需要做這個決策]
- **決策**: [選擇了什麼]
- **結果**: [預期的後果]

## 2. 系統架構 (System Architecture)

### 2.1 元件圖

```
[使用 ASCII 或 Mermaid 描述架構全貌]

┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   [元件 A]       │────>│   [元件 B]       │────>│   [元件 C]       │
│                 │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

### 2.2 執行流程 (Execution Flow)

```
1. [步驟 1]: [描述資料/控制流]
2. [步驟 2]: [描述資料/控制流]
3. [步驟 3]: [描述資料/控制流]
```

### 2.3 前後端範圍切分 (Frontend / Backend Scope)

> **必填**。前端與後端必須分開描述，使任一方能單獨看懂自己要做什麼、不做什麼。
> 拆檔代表前後端各有負責人，兩側都必須有實際範圍；若其中一側其實不涉及，應改為不拆檔（`Owner` 只寫一人）。

**前端範圍（`frontend/`）** — 細節見 `plan-frontend.md`

- 負責：[畫面、元件、狀態管理、互動行為]
- 不負責：[明確列出交由後端處理的事項]
- 涉及頁面／元件：[清單]
- 依賴的 API：[對應第 3 節的端點]

**後端範圍（`backend/`）** — 細節見 `plan-backend.md`

- 負責：[資料模型、業務邏輯、API、排程]
- 不負責：[明確列出交由前端處理的事項]
- 涉及模組／服務：[清單]
- 對外提供的 API：[對應第 3 節的端點]

**交界與契約**

- 前後端唯一的交界是第 3 節的 API 合約；任一方變更契約都必須同步更新該節並通知對方。
- 契約未定案前，前端得以 mock 進行，但不得將 mock 行為當成最終規格。
- 依憲法 Article XII，`cms/` 為唯讀模組，不得列入任何一側的實作範圍；涉及 CMS 的需求改由後端以 API 或設定介面達成。

## 3. API 合約 (API Contracts)

> **API 合約只能寫在這裡與 `contracts/`**（憲法 Article V）。分邊計劃只能引用，不得另寫一份。

### 3.1 端點定義

```yaml
# [端點描述]
[HTTP_METHOD] /api/v1/[resource]

Request:
  Headers:
    Authorization: Bearer {token}
    Content-Type: application/json
  Body:
    {
      "[field]": "[type]",
      "[field]": "[type]"
    }

Response 200:
  {
    "data": {
      "[field]": "[type]"
    },
    "meta": {
      "timestamp": "ISO8601"
    }
  }

Response 400:
  {
    "error": {
      "code": "VALIDATION_ERROR",
      "message": "[描述]",
      "details": []
    }
  }

Response 401:
  {
    "error": {
      "code": "UNAUTHORIZED",
      "message": "Authentication required"
    }
  }
```

## 4. 跨邊測試策略 (Cross-side Testing Strategy)

> 單邊的 unit／integration 測試寫在分邊計劃；此處只放需要兩邊都到位才能跑的測試。

| 層次 | 工具 | 覆蓋目標 | 負責撰寫的一邊 |
|------|------|---------|--------------|
| 契約測試 | [工具] | 第 3 節所有端點 | [frontend / backend] |
| E2E | [工具] | 主要使用者旅程 | [frontend / backend] |

> 依憲法 Article XIII，每條任務恰好屬於一邊，因此跨邊測試也必須指定由哪一邊撰寫。

### 4.1 驗收場景對應

| 驗收場景 | 測試類型 | 撰寫的一邊 |
|---------|---------|-----------|
| SC-001 | E2E | [frontend / backend] |

## 5. 跨邊安全考量 (Cross-side Security)

- **認證**: [認證機制，前後端如何配合]
- **授權**: [授權策略]
- **資料傳輸**: [HTTPS、敏感欄位處理]

## 6. 部署與上線順序 (Deployment)

- **上線順序**: [如：後端先上線並相容舊前端 → 前端上線]
- **向後相容性**: [API 版本策略]
- **環境變數**: [跨兩邊共用的設定；單邊的寫在分邊計劃]

## 7. 實作階段總覽 (Implementation Phases)

> 細部階段在分邊計劃；此處只列跨邊的依賴順序，供 `tasks.md` 總覽引用。

| 順序 | 內容 | 歸屬 | 前置條件 |
|------|------|------|---------|
| 1 | API 契約定案 | 後端撰寫、前端確認 | — |
| 2 | 後端 API 實作 ／ 前端依契約以 mock 開發 | 後端 ／ 前端 | 1 |
| 3 | 後端部署 stage | 後端 | 2 |
| 4 | 前端串接真 API、聯調 | 前端 | 3 |
| 5 | E2E 與驗收 | [frontend / backend] | 4 |

---

## 計劃品質核對清單 (Plan Quality Checklist)

- [ ] 所有憲法閘門已通過
- [ ] 前端與後端範圍已分開描述（2.3），雙方的「負責／不負責」都寫明
- [ ] API 合約對應所有功能需求，且只存在於本檔與 `contracts/`
- [ ] 跨邊測試都已指定撰寫的一邊
- [ ] 兩份分邊計劃皆存在，且與 `spec.md` 的 `Owner` 標註一致
- [ ] 本檔不含單邊細節（資料模型、元件設計等已放到分邊計劃）
- [ ] 無低階程式碼（plan 只到架構層）
