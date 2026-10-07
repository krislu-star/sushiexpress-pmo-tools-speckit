# Task List: [FEATURE_TITLE]

> **Branch**: `NNN-feature-name`
> **Plan**: `specs/NNN-feature-name/plan.md`
> **Total Tasks**: [N]
> **Estimated Complexity**: [Low | Medium | High]

標記說明（見憲法 Article XIII）:

一行任務有兩組方括號，前者是**狀態**、後者是**執行方式**，互不相干（實際書寫時行首加 `- `）：

```
[x] [S] **TASK-001**: 建立資料模型
─┬─ ─┬─
 │   └── 執行方式：[P] 可平行執行 (Parallelizable) / [S] 必須循序執行 (Sequential)
 └────── 狀態（見下）
```

| 狀態 | 意義 |
|---|---|
| `[ ]` | 待完成 |
| `[~]` | 進行中——現在有人在動這一條 |
| `[r]` | 待審核——等關卡放行（code review、驗證、內部環境阻塞） |
| `[c]` | 等客戶——等客戶回覆或決策 |
| `[x]` | 已完成 |

書寫規則:
- 本檔用於**不拆檔**的功能（`spec.md` 的 `Owner` 為一人），負責人即該 `Owner`，任務文字不寫人名。
  前後端由不同人負責時改用 `tasks-overview-template.md` 與分邊任務清單。
- 任務必須是 `-` 清單項目。寫成 `###` 標題**不會被任何 PM 視圖解析**。
- `[r]` / `[c]` 必須在任務文字寫出**在等什麼**，讓半年後的人知道要催誰。例如：
  - `- [r] **TASK-003**: 實作分享按鈕（等 PR #42 review）` — GitHub
  - `- [r] **TASK-013**: 驗證清單（阻塞：待 stage 環境）`
  - `- [c] **TASK-008**: 串接金流（等客戶提供測試帳號）`
- 可選或跳過的任務維持 `[ ]`，原因寫在文字裡，不要用勾選狀態表達。
- **先建立後打勾**：任務先以 `[ ]` 提交，完成時才改 `[x]`。禁止新增時直接寫 `[x]`
  ——完成時間是從「改為 `[x]` 的那個 commit」推導的，出生即打勾就沒有完成時間。
- `TASK-NNN` 在同一 spec 內唯一、不重用；子任務可用字母後綴（`TASK-006a`）。

---

## Phase 0: 環境設置 (Environment Setup)

- [ ] [S] **TASK-001**: 安裝並設定必要依賴
  - 執行 `[安裝指令]`
  - 確認版本符合 `plan.md` 中的規格
  - _驗收_: `[驗證指令]` 正常執行

- [ ] [S] **TASK-002**: 設定環境變數
  - 根據 `plan.md` 中的清單建立 `.env.example`
  - 設定本地 `.env` 檔案
  - _驗收_: 應用程式可成功載入設定

- [ ] [P] **TASK-003**: 初始化資料庫連線
  - 建立資料庫實例
  - 確認連線設定
  - _驗收_: 連線測試通過

## Phase 1: 資料層 (Data Layer)

> 注意：先寫測試，再寫實作

- [ ] [S] **TASK-004**: 建立資料模型測試（先寫測試）
  - 建立 `tests/unit/models/[model].test.[ext]`
  - 測試所有欄位驗證規則
  - 測試關聯關係
  - _驗收_: 所有測試 RED（失敗）

- [ ] [S] **TASK-005**: 實作資料模型
  - 建立 `src/models/[model].[ext]`
  - 實作欄位定義與驗證
  - 實作關聯關係
  - _驗收_: TASK-004 的測試全部 GREEN（通過）

- [ ] [S] **TASK-006**: 建立資料庫 Migration
  - 建立 migration 檔案
  - 包含 up 和 down 遷移
  - _驗收_: `migrate up` 和 `migrate down` 都成功執行

- [ ] [P] **TASK-007**: 建立資料存取層測試（先寫測試）
  - 建立 `tests/integration/repositories/[repo].test.[ext]`
  - 測試 CRUD 操作
  - 測試查詢過濾
  - _驗收_: 所有測試 RED（失敗）

- [ ] [S] **TASK-008**: 實作資料存取層 (Repository/DAO)
  - 建立 `src/repositories/[repo].[ext]`
  - 實作 CRUD 方法
  - 實作查詢方法
  - _驗收_: TASK-007 的測試全部 GREEN（通過）

## Phase 2: 業務邏輯 (Business Logic)

- [ ] [S] **TASK-009**: 建立業務邏輯測試（先寫測試）
  - 建立 `tests/unit/services/[service].test.[ext]`
  - 測試 US-001 的核心邏輯
  - 測試邊界情況
  - 測試錯誤處理
  - _驗收_: 所有測試 RED（失敗）

- [ ] [S] **TASK-010**: 實作核心業務邏輯
  - 建立 `src/services/[service].[ext]`
  - 實作 US-001 相關邏輯
  - _驗收_: TASK-009 的測試全部 GREEN（通過）

- [ ] [P] **TASK-011**: 建立 US-002 業務邏輯測試（先寫測試）
  - 建立或更新 `tests/unit/services/[service].test.[ext]`
  - 測試 US-002 的核心邏輯
  - _驗收_: 所有測試 RED（失敗）

- [ ] [S] **TASK-012**: 實作 US-002 業務邏輯
  - 擴展 `src/services/[service].[ext]`
  - _驗收_: TASK-011 的測試全部 GREEN（通過）

## Phase 3: API 層 (API Layer)

- [ ] [S] **TASK-013**: 建立 API 端點測試（先寫測試）
  - 建立 `tests/integration/api/[endpoint].test.[ext]`
  - 測試 SC-001（正常流程）
  - 測試 SC-002（邊界情況）
  - 測試 SC-003（錯誤情況）
  - 測試驗證失敗情況
  - 測試認證/授權
  - _驗收_: 所有測試 RED（失敗）

- [ ] [S] **TASK-014**: 實作 API 端點
  - 建立路由定義
  - 實作請求驗證中介層
  - 實作控制器/處理器
  - 串接業務邏輯層
  - _驗收_: TASK-013 的測試全部 GREEN（通過）

- [ ] [P] **TASK-015**: 實作錯誤處理
  - 統一錯誤回應格式
  - 實作適當的 HTTP 狀態碼
  - _驗收_: 錯誤情況測試全部通過

## Phase 4: 整合測試 (Integration Tests)

- [ ] [P] **TASK-016**: 端到端流程測試
  - 測試完整的使用者流程（US-001）
  - 測試完整的使用者流程（US-002）
  - _驗收_: 所有整合測試通過

- [ ] [P] **TASK-017**: 效能測試
  - 確認 NFR-001（效能需求）
  - _驗收_: API 回應時間符合規格

- [ ] [P] **TASK-018**: 安全測試
  - 確認 NFR-003（安全需求）
  - 測試未授權存取被拒絕
  - _驗收_: 安全測試全部通過

## Phase 5: 收尾 (Polish)

- [ ] [P] **TASK-019**: 程式碼文件
  - 為所有公開 API 添加文件
  - 更新 API 文件（如 OpenAPI spec）
  - _驗收_: 文件完整且準確

- [ ] [P] **TASK-020**: 測試覆蓋率報告
  - 執行測試覆蓋率工具
  - 確認覆蓋率 >= 80%
  - _驗收_: 覆蓋率報告顯示符合目標

- [ ] [S] **TASK-021**: 最終審查
  - 確認所有驗收場景通過
  - 確認所有憲法條款遵守
  - Code review 完成
  - _驗收_: PR 可以合併

---

## 進度追蹤

| Phase | 任務數 | 完成數 | 狀態 |
|-------|--------|--------|------|
| Phase 0: 環境設置 | 3 | 0 | Not Started |
| Phase 1: 資料層 | 5 | 0 | Not Started |
| Phase 2: 業務邏輯 | 4 | 0 | Not Started |
| Phase 3: API 層 | 3 | 0 | Not Started |
| Phase 4: 整合測試 | 3 | 0 | Not Started |
| Phase 5: 收尾 | 3 | 0 | Not Started |
| **總計** | **21** | **0** | **0%** |
