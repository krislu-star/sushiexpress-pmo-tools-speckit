# Backend Plan: [FEATURE_TITLE]

> **Branch**: `NNN-feature-name`
> **Spec**: `specs/NNN-feature-name/spec.md`
> **共用計劃**: `specs/NNN-feature-name/plan.md`（範圍切分、API 合約、跨邊測試與部署）
> **任務清單**: `specs/NNN-feature-name/tasks-backend.md`

> 本檔只寫**後端**的 HOW（憲法 Article V）。不得重複寫專案管理欄位（負責人、排程見 `spec.md`），
> 也不得另寫 API 合約（只能引用 `plan.md` 第 3 節）。

---

## 1. 技術選型 (Tech Stack)

| 項目 | 技術 | 版本 | 選擇原因 |
|------|------|------|---------|
| 語言／框架 | [技術名稱] | [版本] | [原因] |
| 資料庫 | [技術名稱] | [版本] | [原因] |
| 測試 | [技術名稱] | [版本] | [原因] |

### 1.1 後端架構決策記錄 (ADR)

**ADR-BE-001**: [決策標題]
- **狀態**: Accepted
- **背景**: [為什麼需要做這個決策]
- **決策**: [選擇了什麼]
- **結果**: [預期的後果]

## 2. 資料模型 (Data Model)

### 2.1 實體定義

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

### 2.2 資料庫 Schema

```sql
CREATE TABLE [table_name] (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  [column_name] [DATA_TYPE] [CONSTRAINTS],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_[table_name]_[column] ON [table_name]([column]);
```

## 3. 模組與業務邏輯 (Modules & Business Logic)

| 模組／服務 | 職責 | 對應 API（引用 `plan.md` 第 3 節） |
|-----------|------|----------------------------------|
| [模組名稱] | [職責] | [HTTP_METHOD] /api/v1/[resource] |

## 4. 測試策略 (Testing Strategy)

| 層次 | 工具 | 覆蓋目標 | 測試類型 |
|------|------|---------|---------|
| Unit | [工具] | 80% | 業務邏輯、純函式 |
| Integration | [工具] | 關鍵路徑 100% | API、資料庫（不得以 mock 取代真實資料庫，Article III） |

| 驗收場景 | 測試類型 | 測試檔案位置 |
|---------|---------|------------|
| SC-001 | Integration | `tests/integration/[file]` |

## 5. 安全考量 (Security)

- **輸入驗證**: [驗證方式]
- **授權檢查**: [授權策略實作位置]
- **資料加密**: [加密策略]
- **速率限制**: [限制策略]

## 6. 效能考量 (Performance)

- **資料庫查詢優化**: [索引策略、查詢優化]
- **快取策略**: [快取層、TTL 設定]
- **非同步處理**: [需要非同步的操作]

## 7. 依賴清單 (Dependencies)

| 套件名稱 | 版本 | 用途 | 評估狀態 |
|---------|------|------|---------|
| [package] | [version] | [用途] | Approved |

## 8. 部署考量 (Deployment)

- **環境變數**: [後端新增的環境變數]
- **資料庫遷移**: [migration 策略]
- **監控與告警**: [監控指標]

## 9. 實作階段 (Implementation Phases)

| 階段 | 內容 | 預估複雜度 |
|------|------|-----------|
| Phase 0 | 環境設置、依賴安裝 | Low |
| Phase 1 | 資料模型與資料庫 Schema | Medium |
| Phase 2 | 核心業務邏輯（含測試） | High |
| Phase 3 | API 端點實作（含測試） | High |
| Phase 4 | 部署 stage、支援聯調 | Medium |
| Phase 5 | 文件與收尾 | Low |

---

## 計劃品質核對清單 (Plan Quality Checklist)

- [ ] 技術選型有明確的理由，版本已鎖定（Article I）
- [ ] 資料模型涵蓋所有規格中的實體
- [ ] 每個模組都對應到 `plan.md` 第 3 節的端點，未另寫合約
- [ ] 測試場景對應所有後端負責的驗收場景
- [ ] 未修改 `cms/`（Article XII）
- [ ] 無低階程式碼（plan 只到架構層）
