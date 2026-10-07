# Frontend Plan: [FEATURE_TITLE]

> **Branch**: `NNN-feature-name`
> **Spec**: `specs/NNN-feature-name/spec.md`
> **共用計劃**: `specs/NNN-feature-name/plan.md`（範圍切分、API 合約、跨邊測試與部署）
> **任務清單**: `specs/NNN-feature-name/tasks-frontend.md`

> 本檔只寫**前端**的 HOW（憲法 Article V）。不得重複寫專案管理欄位（負責人、排程見 `spec.md`），
> 也不得另寫 API 合約（只能引用 `plan.md` 第 3 節）。

---

## 1. 技術選型 (Tech Stack)

| 項目 | 技術 | 版本 | 選擇原因 |
|------|------|------|---------|
| 框架 | [技術名稱] | [版本] | [原因] |
| 狀態管理 | [技術名稱] | [版本] | [原因] |
| 測試 | [技術名稱] | [版本] | [原因] |

### 1.1 前端架構決策記錄 (ADR)

**ADR-FE-001**: [決策標題]
- **狀態**: Accepted
- **背景**: [為什麼需要做這個決策]
- **決策**: [選擇了什麼]
- **結果**: [預期的後果]

## 2. 頁面與路由 (Pages & Routes)

| 頁面 | 路由 | 對應使用者故事 | 使用的 API（引用 `plan.md` 第 3 節） |
|------|------|--------------|----------------------------------|
| [頁面名稱] | `/[path]` | US-001 | [HTTP_METHOD] /api/v1/[resource] |

## 3. 元件設計 (Components)

```
[PageName]
├── [ComponentA]        # [職責]
│   └── [ComponentA1]   # [職責]
└── [ComponentB]        # [職責]
```

## 4. 狀態管理與資料流 (State & Data Flow)

- **伺服器狀態**: [取得、快取、重新整理策略]
- **本地狀態**: [表單、UI 狀態放在哪裡]
- **載入／錯誤／空狀態**: [各頁面如何呈現]

## 5. 契約未定案前的 mock 策略 (Mocking)

- **mock 方式**: [如 MSW、本地 fixture]
- **mock 依據**: 僅依 `plan.md` 第 3 節的合約撰寫，不得自行補欄位
- **移除時機**: 後端部署 stage 後，由對應的前端任務移除

## 6. 測試策略 (Testing Strategy)

| 層次 | 工具 | 覆蓋目標 | 測試類型 |
|------|------|---------|---------|
| Unit | [工具] | 80% | 元件、純函式、hooks |
| Integration | [工具] | 關鍵路徑 100% | 頁面層級互動 |

| 驗收場景 | 測試類型 | 測試檔案位置 |
|---------|---------|------------|
| SC-001 | Integration | `tests/[file]` |

## 7. 安全、效能與無障礙 (Security, Performance & Accessibility)

- **輸入驗證**: [前端驗證僅為體驗，後端仍須驗證（Article IV）]
- **敏感資訊**: [token 存放方式]
- **效能**: [程式碼分割、圖片、快取]
- **無障礙**: [鍵盤操作、語意標籤]

## 8. 依賴清單 (Dependencies)

| 套件名稱 | 版本 | 用途 | 評估狀態 |
|---------|------|------|---------|
| [package] | [version] | [用途] | Approved |

## 9. 實作階段 (Implementation Phases)

| 階段 | 內容 | 預估複雜度 |
|------|------|-----------|
| Phase 0 | 環境設置、依賴安裝 | Low |
| Phase 1 | 元件與頁面（含測試，以 mock 開發） | High |
| Phase 2 | 狀態管理與互動（含測試） | Medium |
| Phase 3 | 串接真 API、移除 mock、聯調 | Medium |
| Phase 4 | 文件與收尾 | Low |

---

## 計劃品質核對清單 (Plan Quality Checklist)

- [ ] 技術選型有明確的理由，版本已鎖定（Article I）
- [ ] 每個頁面都對應使用者故事，使用的 API 皆引用 `plan.md` 第 3 節
- [ ] mock 策略與移除時機已寫明
- [ ] 測試場景對應所有前端負責的驗收場景
- [ ] 未修改 `cms/`（Article XII）
- [ ] 無低階程式碼（plan 只到架構層）
