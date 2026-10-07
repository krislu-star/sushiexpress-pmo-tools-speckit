# Frontend Tasks: [FEATURE_TITLE]

> **Branch**: `NNN-feature-name`
> **Plan**: `specs/NNN-feature-name/plan-frontend.md`
> **總覽**: `specs/NNN-feature-name/tasks.md`（跨邊依賴與里程碑）

標記說明（見憲法 Article XIII）:

一行任務有兩組方括號，前者是**狀態**、後者是**執行方式**，互不相干（實際書寫時行首加 `- `）：

```
[x] [S] **TASK-FE-NNN**: 建立列表元件
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
- 本檔只放**前端**任務，負責人 = `spec.md` 中標註 `(frontend)` 的 `Owner`，任務文字不寫人名。
- 任務必須是 `-` 清單項目。寫成 `###` 標題**不會被任何 PM 視圖解析**。
- `[r]` / `[c]` 必須在任務文字寫出**在等什麼**，讓半年後的人知道要催誰。例如：
  - `- [r] **TASK-FE-NNN**: 串接訂單 API（阻塞：等後端部署 stage，見 TASK-BE-NNN）`
  - `- [r] **TASK-FE-NNN**: 實作分享按鈕（等 PR #42 review）`
  - `- [c] **TASK-FE-NNN**: 首頁視覺（等客戶確認設計稿）`
- 需要後端配合的工作拆成兩條分邊任務；跨檔依賴寫在文字裡，如「依賴 TASK-BE-NNN」。
- 可選或跳過的任務維持 `[ ]`，原因寫在文字裡，不要用勾選狀態表達。
- **先建立後打勾**：任務先以 `[ ]` 提交，完成時才改 `[x]`。禁止新增時直接寫 `[x]`
  ——完成時間是從「改為 `[x]` 的那個 commit」推導的，出生即打勾就沒有完成時間。
- `TASK-FE-NNN` 在同一 spec 內唯一、不重用；子任務可用字母後綴（`TASK-FE-006a`）。

---

## Phase 0: 環境設置 (Environment Setup)

- [ ] [S] **TASK-FE-001**: 安裝並設定必要依賴
  - 執行 `[安裝指令]`
  - 確認版本符合 `plan-frontend.md` 中的規格
  - _驗收_: `[驗證指令]` 正常執行

- [ ] [S] **TASK-FE-002**: 確認 API 契約並建立 mock
  - 審閱後端產出的 `contracts/openapi.yaml`，有疑義回報後端
  - 依契約建立 mock（見 `plan-frontend.md` 第 5 節）
  - _驗收_: 契約已確認；mock 回應符合契約

## Phase 1: 元件與頁面 (Components & Pages)

> 注意：先寫測試，再寫實作

- [ ] [S] **TASK-FE-003**: 建立元件測試（先寫測試）
  - 建立 `tests/[component].test.[ext]`
  - 測試 US-001 的呈現、互動、載入／錯誤／空狀態
  - _驗收_: 所有測試 RED（失敗）

- [ ] [S] **TASK-FE-004**: 實作元件
  - 建立 `src/components/[component].[ext]`
  - _驗收_: TASK-FE-003 的測試全部 GREEN（通過）

- [ ] [S] **TASK-FE-005**: 建立頁面測試（先寫測試）
  - 測試 SC-001（正常流程）、SC-002（邊界）、SC-003（錯誤）
  - _驗收_: 所有測試 RED（失敗）

- [ ] [S] **TASK-FE-006**: 實作頁面與路由（以 mock 開發）
  - _驗收_: TASK-FE-005 的測試全部 GREEN（通過）

## Phase 2: 狀態管理 (State Management)

- [ ] [S] **TASK-FE-007**: 建立狀態管理測試（先寫測試）
  - _驗收_: 所有測試 RED（失敗）

- [ ] [S] **TASK-FE-008**: 實作狀態管理與資料流
  - _驗收_: TASK-FE-007 的測試全部 GREEN（通過）

## Phase 3: 串接與聯調 (Integration)

- [ ] [S] **TASK-FE-009**: 串接 stage API、移除 mock
  - 依賴後端部署 stage 的任務完成
  - _驗收_: 所有頁面改接真 API，mock 已移除

- [ ] [S] **TASK-FE-010**: 前後端聯調
  - 發現的後端問題回報給後端修正任務
  - _驗收_: 主要使用者旅程在 stage 走得通

## Phase 4: 收尾 (Polish)

- [ ] [P] **TASK-FE-011**: 測試覆蓋率報告
  - _驗收_: 覆蓋率 >= 80%，關鍵路徑 100%

- [ ] [S] **TASK-FE-012**: 最終審查
  - 確認前端負責的驗收場景皆通過、憲法條款遵守
  - _驗收_: PR 可以合併

---

## 進度追蹤

| Phase | 任務數 | 完成數 | 狀態 |
|-------|--------|--------|------|
| Phase 0: 環境設置 | 2 | 0 | Not Started |
| Phase 1: 元件與頁面 | 4 | 0 | Not Started |
| Phase 2: 狀態管理 | 2 | 0 | Not Started |
| Phase 3: 串接與聯調 | 2 | 0 | Not Started |
| Phase 4: 收尾 | 2 | 0 | Not Started |
| **總計** | **12** | **0** | **0%** |
