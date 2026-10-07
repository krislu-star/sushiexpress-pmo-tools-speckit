# Implementation Plan: [FEATURE_TITLE]

> **Branch**: `NNN-feature-name`
> **Spec**: `specs/NNN-feature-name/spec.md`
> **Status**: Draft | In Review | Approved
> **Author**: [AUTHOR]
> **Date**: [DATE]

---

## Phase -1: 憲法閘門檢查 (Constitution Gates)

> 在繼續之前，確認以下所有憲法條款：

- [ ] **Article I**: 所使用的技術棧已在此文件中明確列出
- [ ] **Article II**: 程式碼品質標準已納入任務設計
- [ ] **Article III**: 測試策略符合 TDD 要求（測試先於實作）
- [ ] **Article IV**: 安全需求已識別並計劃處理
- [ ] **Article V**: `spec.md` 已完成並通過品質核對清單
- [ ] **Article V**: 前後端範圍已於 2.3 分開描述（含「不負責」與交界契約）
- [ ] **Article XIII**: `spec.md` 的 `Owner` 為一人（不拆檔）；前後端由不同人負責時改用拆檔模板
- [ ] **Article VIII**: 所有文件將與程式碼同步版控

---

## 1. 技術背景 (Technical Context)

### 1.1 技術棧選擇

| 層次 | 技術 | 版本 | 選擇原因 |
|------|------|------|---------|
| 前端 | [技術名稱] | [版本] | [原因] |
| 後端 | [技術名稱] | [版本] | [原因] |
| 資料庫 | [技術名稱] | [版本] | [原因] |
| 測試 | [技術名稱] | [版本] | [原因] |
| CI/CD | [技術名稱] | [版本] | [原因] |

### 1.2 架構決策記錄 (ADR)

**ADR-001**: [決策標題]
- **狀態**: Accepted
- **背景**: [為什麼需要做這個決策]
- **決策**: [選擇了什麼]
- **結果**: [預期的後果]

**ADR-002**: [決策標題]
- **狀態**: Accepted
- **背景**: [為什麼需要做這個決策]
- **決策**: [選擇了什麼]
- **結果**: [預期的後果]

## 2. 系統架構 (System Architecture)

### 2.1 元件圖

```
[使用 ASCII 或 Mermaid 描述架構]

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
> 若本功能為單邊（只有前端或只有後端），仍需保留另一側並寫明「本功能不涉及」。

**前端範圍（`frontend/`）**

- 負責：[畫面、元件、狀態管理、互動行為]
- 不負責：[明確列出交由後端處理的事項]
- 涉及頁面／元件：[清單]
- 依賴的 API：[對應第 4 節的端點]

**後端範圍（`backend/`）**

- 負責：[資料模型、業務邏輯、API、排程]
- 不負責：[明確列出交由前端處理的事項]
- 涉及模組／服務：[清單]
- 對外提供的 API：[對應第 4 節的端點]

**交界與契約**

- 前後端唯一的交界是第 4 節的 API 合約；任一方變更契約都必須同步更新該節並通知對方。
- 契約未定案前，前端得以 mock 進行，但不得將 mock 行為當成最終規格。
- 依憲法 Article XII，`cms/` 為唯讀模組，不得列入任何一側的實作範圍；涉及 CMS 的需求改由後端以 API 或設定介面達成。

## 3. 資料模型 (Data Model)

### 3.1 實體定義

```
Entity: [實體名稱]
├── id: UUID (PK)
├── [欄位名]: [型別] [約束]
├── [欄位名]: [型別] [約束]
├── created_at: Timestamp
└── updated_at: Timestamp

Relationships:
- [實體A] has many [實體B]
- [實體B] belongs to [實體A]
```

### 3.2 資料庫 Schema

```sql
CREATE TABLE [table_name] (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  [column_name] [DATA_TYPE] [CONSTRAINTS],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_[table_name]_[column] ON [table_name]([column]);
```

## 4. API 合約 (API Contracts)

### 4.1 端點定義

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

## 5. 測試策略 (Testing Strategy)

### 5.1 測試層次

| 層次 | 歸屬 | 工具 | 覆蓋目標 | 測試類型 |
|------|------|------|---------|---------|
| Unit | 前端 | [工具] | 80% | 元件、純函式 |
| Unit | 後端 | [工具] | 80% | 業務邏輯、純函式 |
| Integration | 後端 | [工具] | 關鍵路徑 100% | API、資料庫 |
| E2E | 前端＋後端 | [工具] | 主要使用者旅程 | 完整流程 |

### 5.2 測試場景對應

| 驗收場景 | 測試類型 | 測試檔案位置 |
|---------|---------|------------|
| SC-001 | Integration | `tests/integration/[file]` |
| SC-002 | Unit | `tests/unit/[file]` |
| SC-003 | Unit | `tests/unit/[file]` |

## 6. 安全考量 (Security Considerations)

- **認證**: [認證機制]
- **授權**: [授權策略]
- **輸入驗證**: [驗證方式]
- **資料加密**: [加密策略]
- **速率限制**: [限制策略]

## 7. 效能考量 (Performance Considerations)

- **資料庫查詢優化**: [索引策略、查詢優化]
- **快取策略**: [快取層、TTL 設定]
- **非同步處理**: [需要非同步的操作]

## 8. 依賴清單 (Dependencies)

### 新增依賴

| 套件名稱 | 版本 | 用途 | 評估狀態 |
|---------|------|------|---------|
| [package] | [version] | [用途] | Approved |

### 現有依賴使用

| 套件名稱 | 用途 |
|---------|------|
| [package] | [用途] |

## 9. 部署考量 (Deployment Considerations)

- **環境變數**: 列出所有新增的環境變數
- **資料庫遷移**: 說明 migration 策略
- **向後相容性**: 說明 API 版本策略
- **監控與告警**: 說明監控指標

## 10. 實作階段 (Implementation Phases)

| 階段 | 內容 | 歸屬 | 預估複雜度 |
|------|------|------|-----------|
| Phase 0 | 環境設置、依賴安裝 | 前端＋後端 | Low |
| Phase 1 | 資料模型與資料庫 Schema | 後端 | Medium |
| Phase 2 | 核心業務邏輯（含測試） | 後端 | High |
| Phase 3 | API 端點實作（含測試） | 後端 | High |
| Phase 4 | 前端畫面與 API 串接（含測試） | 前端 | High |
| Phase 5 | 整合測試 | 前端＋後端 | Medium |
| Phase 6 | 文件與收尾 | 前端＋後端 | Low |

---

## 計劃品質核對清單 (Plan Quality Checklist)

- [ ] 所有憲法閘門已通過
- [ ] 技術棧選擇有明確的理由
- [ ] 資料模型涵蓋所有規格中的實體
- [ ] API 合約對應所有功能需求
- [ ] 測試場景對應所有驗收場景
- [ ] 安全考量已識別所有威脅
- [ ] 無低階程式碼（plan 只到架構層）
- [ ] 前端與後端範圍已分開描述（2.3），雙方的「負責／不負責」都寫明
- [ ] 每個實作階段都標註歸屬（前端／後端／兩者）
