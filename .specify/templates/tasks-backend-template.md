# Backend Tasks: [FEATURE_TITLE]

> **Branch**: `NNN-feature-name`
> **Plan**: `specs/NNN-feature-name/plan-backend.md`
> **總覽**: `specs/NNN-feature-name/tasks.md`（跨邊依賴與里程碑）

標記說明（見憲法 Article XIII）:

一行任務有兩組方括號，前者是**狀態**、後者是**執行方式**，互不相干（實際書寫時行首加 `- `）：

```
[x] [S] **TASK-BE-NNN**: 建立資料模型
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
- 本檔只放**後端**任務，負責人 = `spec.md` 中標註 `(backend)` 的 `Owner`，任務文字不寫人名。
- 任務必須是 `-` 清單項目。寫成 `###` 標題**不會被任何 PM 視圖解析**。
- `[r]` / `[c]` 必須在任務文字寫出**在等什麼**，讓半年後的人知道要催誰。例如：
  - `- [r] **TASK-BE-NNN**: 契約草案（等前端確認，見 TASK-FE-NNN）`
  - `- [r] **TASK-BE-NNN**: 實作訂單 API（等 PR #42 review）`
  - `- [c] **TASK-BE-NNN**: 串接金流（等客戶提供測試帳號）`
- 需要前端配合的工作拆成兩條分邊任務；跨檔依賴寫在文字裡，如「依賴 TASK-FE-NNN」。
- 可選或跳過的任務維持 `[ ]`，原因寫在文字裡，不要用勾選狀態表達。
- **先建立後打勾**：任務先以 `[ ]` 提交，完成時才改 `[x]`。禁止新增時直接寫 `[x]`
  ——完成時間是從「改為 `[x]` 的那個 commit」推導的，出生即打勾就沒有完成時間。
- `TASK-BE-NNN` 在同一 spec 內唯一、不重用；子任務可用字母後綴（`TASK-BE-006a`）。

---

## Phase 0: 環境設置 (Environment Setup)

- [ ] [S] **TASK-BE-001**: 安裝並設定必要依賴
  - 執行 `[安裝指令]`
  - 確認版本符合 `plan-backend.md` 中的規格
  - _驗收_: `[驗證指令]` 正常執行

- [ ] [S] **TASK-BE-002**: 設定環境變數
  - 根據 `plan-backend.md` 中的清單建立 `.env.example`
  - _驗收_: 應用程式可成功載入設定

- [ ] [S] **TASK-BE-003**: 撰寫 API 契約草案
  - 依 `plan.md` 第 3 節產出 `contracts/openapi.yaml`
  - _驗收_: 契約檔通過格式驗證；狀態改 `[r]` 等前端確認（對應前端的契約確認任務）

## Phase 1: 資料層 (Data Layer)

> 注意：先寫測試，再寫實作

- [ ] [S] **TASK-BE-004**: 建立資料模型測試（先寫測試）
  - 建立 `tests/unit/models/[model].test.[ext]`
  - 測試所有欄位驗證規則與關聯關係
  - _驗收_: 所有測試 RED（失敗）

- [ ] [S] **TASK-BE-005**: 實作資料模型
  - 建立 `src/models/[model].[ext]`
  - _驗收_: TASK-BE-004 的測試全部 GREEN（通過）

- [ ] [S] **TASK-BE-006**: 建立資料庫 Migration
  - 包含 up 和 down 遷移
  - _驗收_: `migrate up` 和 `migrate down` 都成功執行

## Phase 2: 業務邏輯 (Business Logic)

- [ ] [S] **TASK-BE-007**: 建立業務邏輯測試（先寫測試）
  - 建立 `tests/unit/services/[service].test.[ext]`
  - 測試 US-001 的核心邏輯、邊界情況與錯誤處理
  - _驗收_: 所有測試 RED（失敗）

- [ ] [S] **TASK-BE-008**: 實作核心業務邏輯
  - 建立 `src/services/[service].[ext]`
  - _驗收_: TASK-BE-007 的測試全部 GREEN（通過）

## Phase 3: API 層 (API Layer)

- [ ] [S] **TASK-BE-009**: 建立 API 端點測試（先寫測試）
  - 建立 `tests/integration/api/[endpoint].test.[ext]`
  - 測試 SC-001（正常流程）、SC-002（邊界）、SC-003（錯誤）
  - 測試驗證失敗與認證／授權
  - _驗收_: 所有測試 RED（失敗）

- [ ] [S] **TASK-BE-010**: 實作 API 端點
  - 依 `contracts/openapi.yaml` 實作路由、驗證、控制器
  - _驗收_: TASK-BE-009 的測試全部 GREEN（通過）

## Phase 4: 部署與聯調 (Stage & Integration)

- [ ] [S] **TASK-BE-011**: 部署 stage 並支援前端聯調
  - _驗收_: stage 上所有端點可呼叫；通知前端可開始串接

- [ ] [S] **TASK-BE-012**: 修正聯調回報的後端問題
  - 依賴前端聯調任務完成回報
  - _驗收_: 回報問題皆已修正並有測試覆蓋

## Phase 5: 收尾 (Polish)

- [ ] [P] **TASK-BE-013**: 測試覆蓋率報告
  - _驗收_: 覆蓋率 >= 80%，關鍵路徑 100%

- [ ] [S] **TASK-BE-014**: 最終審查
  - 確認後端負責的驗收場景皆通過、憲法條款遵守
  - _驗收_: PR 可以合併

---

## 進度追蹤

| Phase | 任務數 | 完成數 | 狀態 |
|-------|--------|--------|------|
| Phase 0: 環境設置 | 3 | 0 | Not Started |
| Phase 1: 資料層 | 3 | 0 | Not Started |
| Phase 2: 業務邏輯 | 2 | 0 | Not Started |
| Phase 3: API 層 | 2 | 0 | Not Started |
| Phase 4: 部署與聯調 | 2 | 0 | Not Started |
| Phase 5: 收尾 | 2 | 0 | Not Started |
| **總計** | **14** | **0** | **0%** |
