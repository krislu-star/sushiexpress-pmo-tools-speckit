# Feature Specification: [FEATURE_TITLE]

> **Branch**: `NNN-feature-name`
> **Status**: Draft | In Review | Approved | Implemented
> **Author**: [AUTHOR]
> **Date**: [DATE]
> **Owner**: [OWNER]                 <!-- 專案管理：/speckit-specify 時填（實際執行的工程師）。一人負責寫 @bob；前後端由不同人負責寫 @alice (frontend), @bob (backend)，plan/tasks 會拆檔。見憲法 Article XIII -->
> **DependsOn**: [NNN, NNN]          <!-- 專案管理：/speckit-plan 時填（相依 feature） -->
> **Start**: [YYYY-MM-DD]            <!-- 專案管理：/speckit-tasks 時填（開始日） -->
> **Estimate**: [Nd]                 <!-- 專案管理：/speckit-tasks 時填（工期，如 8d） -->
> **Due**: [YYYY-MM-DD]              <!-- 專案管理：選填（外部硬上線日） -->

---

## 1. 概述 (Overview)

[用 2-3 句話描述此功能的核心目的，聚焦在 WHAT 和 WHY，不涉及 HOW]

## 2. 問題陳述 (Problem Statement)

**目前狀況**: [描述現有的問題或缺口]

**期望狀況**: [描述理想的結果]

**影響範圍**: [此問題影響哪些使用者或流程]

## 3. 使用者故事 (User Stories)

### US-001: [使用者故事標題]
```
身為 [使用者角色],
我希望 [執行某個動作],
以便 [達到某個目標/獲得某個價值]。
```

**驗收標準**:
- [ ] [具體可驗證的條件 1]
- [ ] [具體可驗證的條件 2]
- [ ] [具體可驗證的條件 3]

### US-002: [使用者故事標題]
```
身為 [使用者角色],
我希望 [執行某個動作],
以便 [達到某個目標/獲得某個價值]。
```

**驗收標準**:
- [ ] [具體可驗證的條件 1]
- [ ] [具體可驗證的條件 2]

## 4. 功能需求 (Functional Requirements)

| ID | 需求描述 | 優先級 | 使用者故事 |
|----|---------|--------|-----------|
| FR-001 | [需求描述] | Must Have | US-001 |
| FR-002 | [需求描述] | Should Have | US-001 |
| FR-003 | [需求描述] | Could Have | US-002 |
| FR-004 | [需求描述] | Won't Have | - |

## 5. 非功能需求 (Non-Functional Requirements)

| ID | 類別 | 需求描述 |
|----|------|---------|
| NFR-001 | 效能 | [例: API 回應時間 < 200ms] |
| NFR-002 | 可用性 | [例: 系統可用性 99.9%] |
| NFR-003 | 安全性 | [例: 所有端點需要 JWT 驗證] |
| NFR-004 | 可擴展性 | [例: 支援 10,000 並發使用者] |

## 6. 驗收場景 (Acceptance Scenarios)

### 場景 SC-001: [正常流程]
```
Given: [初始狀態/前提條件]
When:  [使用者執行的動作]
Then:  [預期的系統回應]
And:   [額外的預期狀態]
```

### 場景 SC-002: [邊界情況]
```
Given: [初始狀態/前提條件]
When:  [使用者執行的動作]
Then:  [預期的系統回應]
```

### 場景 SC-003: [錯誤情況]
```
Given: [初始狀態/前提條件]
When:  [使用者執行無效的動作]
Then:  [預期的錯誤回應]
And:   [系統的恢復狀態]
```

## 7. 範圍限制 (Out of Scope)

> 以下內容明確排除在此功能之外：

- [排除項目 1]
- [排除項目 2]
- [排除項目 3]

## 8. 依賴與假設 (Dependencies & Assumptions)

**依賴**:
- [依賴的其他功能或服務]

**假設**:
- [假設已存在的條件]

## 9. 成功指標 (Success Criteria)

| SC | 指標 | 目標值 | 測量方式 |
|----|------|--------|---------|
| SC-001 | [指標名稱] | [目標] | [如何測量] |
| SC-002 | [指標名稱] | [目標] | [如何測量] |

## 10. 待釐清事項 (Open Questions)

- [ ] [NEEDS CLARIFICATION] [待釐清的問題 1]
- [ ] [NEEDS CLARIFICATION] [待釐清的問題 2]

---

## 規格品質核對清單 (Spec Quality Checklist)

在提交 `spec.md` 之前，確認以下所有項目：

- [ ] 所有使用者故事都有明確的驗收標準
- [ ] 功能需求使用 WHAT/WHY 語言，沒有 HOW
- [ ] 沒有提及任何具體技術棧（框架、資料庫、語言）
- [ ] 所有模糊點都標記了 `[NEEDS CLARIFICATION]`
- [ ] 成功指標是可量化的
- [ ] 範圍限制明確列出了不做的事情
- [ ] 驗收場景覆蓋了正常、邊界、錯誤三種情況
