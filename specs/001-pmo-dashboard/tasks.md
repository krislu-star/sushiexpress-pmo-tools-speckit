# Task List: 爭鮮 IT 案件追蹤與管理層呈報儀表板

> **Branch**: `001-pmo-dashboard`
> **Plan**: `specs/001-pmo-dashboard/plan.md`
> **Total Tasks**: 25
> **Estimated Complexity**: High

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
- 任務必須是 `-` 清單項目。寫成 `###` 標題**不會被任何 PM 視圖解析**。
- `[r]` / `[c]` 必須在任務文字寫出**在等什麼**。
- 可選或跳過的任務維持 `[ ]`，原因寫在文字裡，不要用勾選狀態表達。
- **先建立後打勾**：任務先以 `[ ]` 提交，完成時才改 `[x]`。
- `TASK-NNN` 在同一 spec 內唯一、不重用；子任務可用字母後綴（`TASK-006a`）。

> 路徑說明：除特別註明外，程式碼路徑皆相對於 `frontend/`（`Kiitzu/sushiexpress-pmo-tools-web`）。前端 repo 的工作分支同為 `001-pmo-dashboard`。

---

## Phase 0: 環境設置 (Environment Setup)

- [x] [S] **TASK-001**: 以新 repo 替換 `frontend` submodule（plan ADR-001）
  - 於 speckit repo 依 AGENTS.md「更換 Submodule」：`git submodule deinit -f frontend`、`git rm -f frontend`、刪除 `.git/modules/frontend`、`git submodule add -b master git@github.com:Kiitzu/sushiexpress-pmo-tools-web.git frontend`
  - 更新 AGENTS.md submodule 表格中的前台前端 URL 描述
  - 不 push（Article VI）
  - 註：新 repo 原為空，無法直接 `submodule add`；改為本機 clone、在 `master` 建初始 commit（`29c7734`）後以既有 repo 加入。該 commit 需使用者自行 push
  - _驗收_: `.gitmodules` 的 frontend URL 為新 repo、`branch = master`；`git submodule status` 正常

- [x] [S] **TASK-002**: 建立 Next.js 14 Pages Router 骨架（plan 1.1、ADR-002、第 8 節）
  - pnpm 專案，依 plan 第 8 節安裝**精確版本**依賴（`package.json` 無 `^`／`~`）
  - `next.config.js`：`output: 'export'`、`trailingSlash: false`、`basePath` 取自 `NEXT_PUBLIC_BASE_PATH`；比照 cms 建 `config/env`
  - TS strict、Tailwind 3（含 `tailwindcss-animate`）、ESLint（`eslint-config-next` + `max-lines-per-function: 50`）、Prettier
  - `src/pages/tracker.tsx`、`management.tsx`、`meeting.tsx` 佔位頁；`.gitignore` 排除 `data/raw/*.csv`
  - _驗收_: `pnpm lint`、`pnpm check:types`、`pnpm build` 通過，`out/` 產出三個 HTML

- [x] [S] **TASK-003**: 建立測試與 CI 骨架，含「無行內腳本」檢查（plan 第 5、6 節）
  - Jest（`next/jest`、jsdom、jest-dom、user-event），覆蓋率門檻 80%，`src/lib/pmo/**` 100%
  - Playwright（Chrome）＋ axe，以 `out/` 靜態伺服器執行
  - `scripts/check-inline-scripts.ts`：掃描 `out/*.html`，除 `type="application/json"` 外，`<script>` 不得有內容；無行內事件屬性。先寫其單元測試（含違規樣本）再實作
  - GitHub Actions：lint → types → jest（覆蓋率）→ build → inline 檢查 → Playwright
  - _驗收_: CI 於骨架上全綠；故意加入行內腳本時檢查失敗
  - 註：本機依 CI 步驟完整執行皆通過（含 E2E 於 `script-src 'self'` 的 CSP 下）；GitHub Actions 實跑待 frontend repo push 後確認

- [ ] [S] **TASK-004**: 骨架頁交 BPM 實測 CSP／iframe（plan R-1）（略過：2026-09-23 使用者決定不等 BPM 實測、繼續後續工作；產物已通過 `script-src 'self'` CSP 的 E2E，上線前仍建議由 Herbert 實測 iframe 列印）
  - 以 `NEXT_PUBLIC_BASE_PATH` 建置骨架，交 Herbert 放入 BPM 靜態網頁空間
  - 驗證三個入口可開、外部 JS／CSS 可載入、iframe 內 `window.print()` 是否可用、是否可開新視窗
  - 將結果記錄於 `plan.md` 第 9 節 R-1
  - _驗收_: 三頁於 BPM 內正常顯示；列印可用性已記錄（不可用時 TASK-023 須含「在新視窗開啟」）

## Phase 1: 快照契約 (Snapshot Contract)

> 注意：先寫測試，再寫實作

- [x] [S] **TASK-005**: 快照 schema 與 CSV 轉換測試（先寫測試；FR-003、FR-020、contracts/snapshot.schema.json）
  - `src/lib/pmo/snapshotSchema.test.ts`：合法快照通過；缺分頁、欄數≠13、`sourceRow` < 2、`capturedAt` 格式錯、案件名稱空白皆失敗
  - `scripts/snapshot/buildSnapshot.test.ts`：CSV 標題列對應、原列號保留、略過案件名稱空白的列、尾端欄位補空字串、儲存格內換行保留、輸出通過 schema、錯誤時列出分頁與列號
  - fixture：`tests/fixtures/csv/*.csv`（由 PoC 16 件資料改寫）
  - _驗收_: 所有測試 RED（失敗）

- [x] [S] **TASK-006**: 實作快照 schema 與 `snapshot:build` CLI
  - `src/lib/pmo/snapshotSchema.ts`（zod，與 contracts JSON Schema 一致）
  - `scripts/snapshot/buildSnapshot.ts`：讀 `data/raw/{Frontend,Project,BPM,SAP}.csv`＋`data/snapshot.config.json`（spreadsheetId、各分頁 sheetId）→ `data/snapshot.json`；參數 `--captured-at YYYY-MM-DD`；失敗以非零碼結束
  - `package.json` 加 `snapshot:build`
  - _驗收_: TASK-005 測試全部 GREEN

- [x] [S] **TASK-007**: 產出首份全部案件快照
  - 由使用者從 Google Sheets 下載四分頁 CSV 放入 `data/raw/`（不提交）
  - 執行 `pnpm snapshot:build`，提交 `data/snapshot.json`
  - 另產生合成 500 件快照 `tests/fixtures/snapshot.500.json` 供效能測試
  - _驗收_: 快照通過 schema；各分頁案件數與原表非空案件列數一致（人工抽查 3 列）
  - 結果：2026/09/16 試作 CSV → Frontend 23、Project 18、BPM 22、SAP 14，共 77 件，與 CSV 非空案件列數一致；抽查 Frontend 第 2 列、Project 第 10 列、SAP 第 15 列一致
  - 註：Frontend、BPM、SAP 分頁尚無 Progress／燈號欄（轉換時警告並視為空白），補欄後重新匯出即可；試算表 ID 與 gid 沿用 PoC 設定，若試作檔為另一份試算表需更新 `data/snapshot.config.json`

## Phase 2: 資料處理邏輯 (Domain Logic)

- [x] [S] **TASK-008**: 案件轉換、篩選、排序測試（先寫測試；US-001、FR-003～FR-006、SC-002）
  - `src/lib/pmo/cases.test.ts`：`toCases` 的 id、project（空分類→未分類）、latest（LOG 前三個非空行／原表尚無 LOG）、空值→未提供、`progress`／`updated` 為 null、`sourceUrl` 格式
  - `src/lib/pmo/filterCases.test.ts`：關鍵字比對 BPM 單號／名稱／負責人／類型／完整 LOG（不分大小寫），專案／小組／狀態篩選
  - `src/lib/pmo/sortCases.test.ts`：升降冪、缺值（null、空字串、未提供、—）排最後、同值依原列序、中文自然排序（數字依數值）
  - _驗收_: 所有測試 RED

- [x] [S] **TASK-009**: 實作 `toCases`、`filterCases`、`sortCases`
  - `src/lib/pmo/cases.ts`、`filterCases.ts`、`sortCases.ts`，純函式、JSDoc、單函式 ≤ 50 行
  - _驗收_: TASK-008 測試全部 GREEN，`src/lib/pmo` 覆蓋率 100%

- [x] [P] **TASK-010**: 專案彙整、分頁、排序移動測試（先寫測試；US-003、US-004、FR-009、FR-011、FR-021）
  - `src/lib/pmo/projects.test.ts`：依「小組｜分類」分組、phase 固定待確認、summary 串接、owners 去重以「、」連接
  - `src/lib/pmo/paginate.test.ts`：每頁 2 件／3 件、空陣列回傳 1 頁空頁
  - `src/lib/pmo/reorder.test.ts`：移到指定位置、越界夾限、不存在項目回傳原陣列
  - _驗收_: 所有測試 RED

- [x] [S] **TASK-011**: 實作 `groupProjects`、`paginate`、`reorder`
  - _驗收_: TASK-010 測試全部 GREEN

- [x] [P] **TASK-012**: 會議本機儲存測試（先寫測試；US-006、FR-015、FR-016、SC-008、SC-009、ADR-005）
  - `src/lib/pmo/meetingStore.test.ts`：讀寫 key `sushi-pmo-meeting-v1`；JSON 損毀回傳空集合＋錯誤訊息；逐筆驗證（燈號值、欄位型別），不符者忽略、其餘保留；名稱指紋不符者忽略；`localStorage` 拋錯時儲存回傳失敗狀態但資料留在記憶體；儲存時寫入當日 `updated`
  - 燈號排序：紅 → 黃 → 待評估 → 綠
  - _驗收_: 所有測試 RED

- [x] [S] **TASK-013**: 實作 `meetingStore` 與改寫自 cms 的 `useLocalStorage`
  - `src/lib/pmo/meetingStore.ts`；`src/hooks/use-local-storage.ts`（來源註明 `cms@0a0a5e2c`，移除 `lodash-es`，加上解析失敗與儲存不可用防護）
  - _驗收_: TASK-012 測試全部 GREEN
  - 註：實作時改為 `src/hooks/use-meeting-entries.ts`，未複製 cms 的 `useLocalStorage`（其驗證與失敗處理已由 meetingStore 純函式負責，複製會成為未使用的程式碼）

## Phase 3: UI 基礎 (UI Foundation)

- [x] [S] **TASK-014**: 複製並調整 cms UI 元件（ADR-003、ADR-008）
  - 自 `cms/apps/admin/src/components/ui` 複製 `button`、`dialog`、`select`、`switch`、`tabs`、`table`（含 `table.css`）、`input`、`textarea`、`badge` 與 `lib/utils` 的 `cn`；**不修改 `cms/`**
  - 移除 `fullscreen-controller`、`@kiibase/i18n` 依賴；每檔頭註明來源 commit
  - Tailwind 主題 token：主色 #E95529、深色頂欄、狀態色；確認對比度符合 WCAG AA
  - _驗收_: `pnpm check:types`、`pnpm lint` 通過；每個元件有一個渲染 smoke test 通過

- [x] [S] **TASK-015**: 共用元件測試（先寫測試；US-002、US-005、US-007、FR-002、FR-007、FR-008、FR-013、FR-017、SC-006）
  - `src/components/shared/*.test.tsx`：AppShell（品牌字、頁面名稱、版本說明入口）、AboutDialog、DataBanner（擷取日期、案件總數、示意說明）、StatusBadge、ProgressMeter（null → 未提供）、CaseDetailDialog（完整 LOG、原表連結 `rel="noreferrer"`、無 LOG 文案、LOG 內 HTML 以純文字呈現）、TeamsNoticeDialog（說明「未開啟或傳送任何訊息」、關閉後焦點回到觸發按鈕）
  - _驗收_: 所有測試 RED

- [x] [S] **TASK-016**: 實作共用元件
  - `src/components/shared/`：AppShell、AboutDialog、DataBanner、StatusBadge、ProgressMeter、CaseDetailDialog、TeamsNoticeDialog、CaseTable（欄名排序按鈕含 `aria-sort`）
  - _驗收_: TASK-015 測試全部 GREEN

## Phase 4: 案件追蹤頁 (Tracker)

- [x] [S] **TASK-017**: 案件追蹤頁測試（先寫測試；US-001、US-002、SC-001、SC-003）
  - `src/components/tracker/TrackerView.test.tsx`：搜尋「POS」的結果與件數、專案／小組／狀態篩選、重設、欄名切換升降冪、BPM 單號排序、回到原表順序、目前排序文字、查無結果畫面與「清除篩選」、點案件開啟詳細內容
  - _驗收_: 所有測試 RED

- [x] [S] **TASK-018**: 實作案件追蹤頁
  - `src/components/tracker/TrackerView.tsx`、`src/pages/tracker.tsx`
  - _驗收_: TASK-017 測試全部 GREEN；`out/tracker.html` 通過 inline 檢查

## Phase 5: 主管頁－專案呈報 (Management: Projects)

- [x] [S] **TASK-019**: 主管頁專案列表、工作列表與專案呈報測試（先寫測試；US-003～US-005、FR-009～FR-013、FR-024、SC-004、SC-005、SC-006）
  - `src/components/management/ManagementView.test.tsx`：分頁籤切換、專案搜尋、狀態篩選選「執行中」顯示「沒有符合條件的專案」、重設、關聯案件對話框、工作列表搜尋、Teams 說明、呈報開關預設全選、全部取消時「預覽報告」不可用且顯示 0
  - `src/components/management/ProjectReport.test.tsx`：每頁 2 件、頁碼「n / 總頁數」、呈報對象「副董」、鍵盤上／下／Home／End 移動與朗讀文字、Esc 取消拖曳、指標拖曳移動
  - _驗收_: 所有測試 RED

- [x] [S] **TASK-020**: 實作主管頁專案列表、工作列表與專案呈報
  - `src/components/management/`：ManagementView、ProjectList、WorkList、ProjectReport、`useDragOrder`；`src/pages/management.tsx`
  - A4 列印樣式（`@page A4 portrait`、案件不跨頁、列印時隱藏頂欄與操作元件、黑白可辨識）
  - _驗收_: TASK-019 測試全部 GREEN

## Phase 6: 主管頁－逐案呈報 (Management: Case Report)

- [x] [S] **TASK-021**: 逐案呈報測試與實作（先寫測試再實作；FR-021、ADR-006）
  - 先寫 `src/components/management/CaseReport.test.tsx`（RED）：逐案勾選、切換篩選保留選取、只看已選、選取目前結果、清空選案、預覽每頁 3 件、上移／下移／移除、未選時不可預覽
  - 再實作 `CaseReport.tsx`，掛到主管頁第三個分頁籤「逐案呈報」
  - _驗收_: 測試先 RED 後 GREEN（兩個 commit）

## Phase 7: 會議頁 (Meeting)

- [x] [S] **TASK-022**: 會議頁測試與實作（先寫測試再實作；US-006、FR-014～FR-016、SC-007～SC-009）
  - 先寫 `src/components/meeting/MeetingView.test.tsx`（RED）：燈號統計與點選篩選、再點取消、預設排序、各欄排序、搜尋、小組／燈號篩選、重設、編輯對話框儲存後排序與統計更新、更新日期為今天、儲存成功與不可用的提示文字
  - 再實作 `MeetingView.tsx`、`src/pages/meeting.tsx`
  - _驗收_: 測試先 RED 後 GREEN（兩個 commit）

## Phase 8: 整合驗證與收尾 (Integration & Polish)

- [x] [P] **TASK-023**: E2E 與列印測試（SC-001、SC-004、SC-007、NFR-005）
  - `e2e/tracker.spec.ts`、`e2e/management-print.spec.ts`（`page.pdf()` 產出 A4，驗證頁數、無頂欄／按鈕文字）、`e2e/meeting.spec.ts`（儲存後重新整理仍保留；封鎖 localStorage 時顯示提示）
  - 若 TASK-004 記錄 iframe 無法列印：加入「在新視窗開啟」連結並測試
  - 註：TASK-004 尚未有 BPM 實測結果，「在新視窗開啟」連結未加入；待實測後以 `/speckit-converge` 補任務
  - _驗收_: Playwright 全數通過

- [x] [P] **TASK-024**: 效能、無障礙與手機版面驗證（NFR-001、NFR-002、FR-018）
  - `e2e/performance.spec.ts`：以 500 件快照建置，頁面 2 秒內可操作、輸入搜尋後 < 100ms 更新
  - `e2e/a11y.spec.ts`：三頁 axe 0 個 serious／critical；全程鍵盤可操作
  - 390px 寬度下三頁無水平捲動（表格區可內部捲動）
  - _驗收_: 上述測試全數通過

- [x] [S] **TASK-025**: 部署文件、覆蓋率與最終審查
  - `frontend/README.md`：安裝、`snapshot:build` 資料更新流程、建置、交付 `out/` 給 BPM 的步驟與 `NEXT_PUBLIC_BASE_PATH`
  - 覆蓋率報告：整體 ≥ 80%，`src/lib/pmo` 100%
  - 對照 spec 第 3、6 節逐條驗收；確認憲法條款（精確版本、JSDoc、函式長度、無行內腳本、未修改 `cms/`）
  - _驗收_: 報告與檢查全數通過，PR 可送審
  - 驗收紀錄：lint、型別、格式、Jest 159 項（整體 98%／`src/lib/pmo` 100%）、無行內腳本檢查、Playwright 31 項（3 項依設計略過）、500 件效能 3 項皆通過；精確版本、JSDoc、單函式 ≤ 50 行、未修改 `cms/` 已確認
  - spec 對照：US-001～US-007、SC-001～SC-009 皆有對應測試；FR-003（全部案件）待 TASK-007 提供 CSV、FR-019（BPM 部署與 iframe）待 TASK-004 實測，其餘 Must／Should 需求已實作


## Phase 9: 收斂 (Convergence)

> 來源：2026/09/16 試作 CSV 的 Project 分頁多了 Progress 與燈號兩欄，使用者決定四個分頁都要有（spec FR-003、FR-008、SC-010；plan ADR-007 修訂）。

- [x] [S] **TASK-026**: 快照 v2（15 欄）與原表欄位解析測試（先寫測試）— 依據 FR-003、FR-008、SC-010、plan ADR-007（contradicts／missing，F1、F2）
  - `src/lib/pmo/sheetFields.test.ts`：`parseProgress`（`90%`、`90`、空白→null；`0.9`、`101%`、`約九成`→錯誤）、`parseLight`（`🔴 紅燈`／`紅燈`／`🟢 綠燈`／`⚪ 待評估`、空白→gray；其他→錯誤）
  - `src/lib/pmo/snapshotSchema.test.ts`：`schemaVersion` 2、每列 15 欄；Progress／燈號不合法時失敗
  - `scripts/snapshot/buildSnapshot.test.ts`：15 欄（燈號欄無標題）通過；13 欄分頁補空白並輸出警告；第 14 欄標題需含 Progress；Progress／燈號不合法時錯誤訊息含分頁與列號
  - fixture：`tests/fixtures/csv/*.csv` 改為 15 欄並含 Progress／燈號樣本，保留一個 13 欄分頁驗證警告
  - _驗收_: 新增測試全部 RED

- [x] [S] **TASK-027**: 實作快照 v2、`sheetFields` 與 CLI — 依據 FR-003、FR-020、SC-010（contradicts，F1、F2、F5）
  - `src/lib/pmo/sheetFields.ts`、`snapshotSchema.ts`（v2、15 欄、欄位驗證）、`scripts/snapshot/buildSnapshot.ts`（15 欄、13 欄警告、逐列驗證）
  - 更新 `makeSynthetic.ts`（含 Progress／燈號）、`tests/factories.ts`；重新產生 `tests/fixtures/snapshot.sample.json`、`snapshot.500.json` 與暫用 `data/snapshot.json`
  - _驗收_: TASK-026 測試全部 GREEN；`src/lib/pmo` 覆蓋率 100%

- [x] [S] **TASK-028**: 案件完成度、會議預設燈號與說明文字測試（先寫測試）— 依據 FR-008、US-006、US-007、SC-007、SC-010（missing／contradicts，F2、F3、F4）
  - `cases.test.ts`：`progress` 取自原表、`sheetLight` 取自原表
  - `meetingStore.test.ts`：無本機紀錄時燈號為原表燈號、有紀錄時本機優先；`lightSource` 為 `sheet`／`local`
  - `MeetingView.test.tsx`：初始統計反映原表燈號；本機修改後標示「本機修改」
  - `DataBanner`／`AboutDialog` 測試：說明完成度與燈號來自原表、空白顯示未提供／待評估
  - _驗收_: 新增測試全部 RED

- [x] [S] **TASK-029**: 實作案件完成度、會議預設燈號與說明文字 — 依據 FR-008、US-006、US-007（missing／contradicts，F2、F3、F4）
  - `toCases`、`applyEntries`、MeetingTable（燈號來源標示）、DataBanner、AboutDialog
  - _驗收_: TASK-028 測試全部 GREEN；lint（單函式 ≤ 50 行）、型別、格式通過

- [x] [S] **TASK-030**: SC-010 E2E 與完整驗證 — 依據 SC-010、NFR-001（missing，F6）
  - `e2e/tracker.spec.ts` 驗證有 Progress 的案件顯示百分比與進度條；`e2e/meeting.spec.ts` 驗證初始燈號取自原表
  - 重新跑 lint、型別、格式、Jest 覆蓋率、build、無行內腳本檢查、E2E、`build:perf`＋`e2e:perf`
  - _驗收_: 全數通過

---

## 進度追蹤

| Phase | 任務數 | 完成數 | 狀態 |
|-------|--------|--------|------|
| Phase 0: 環境設置 | 4 | 3 | Done（TASK-004 略過） |
| Phase 1: 快照契約 | 3 | 3 | Done |
| Phase 2: 資料處理邏輯 | 6 | 6 | Done |
| Phase 3: UI 基礎 | 3 | 3 | Done |
| Phase 4: 案件追蹤頁 | 2 | 2 | Done |
| Phase 5: 主管頁－專案呈報 | 2 | 2 | Done |
| Phase 6: 主管頁－逐案呈報 | 1 | 1 | Done |
| Phase 7: 會議頁 | 1 | 1 | Done |
| Phase 8: 整合驗證與收尾 | 3 | 3 | Done |
| Phase 9: 收斂 | 5 | 5 | Done |
| **總計** | **30** | **29** | **97%** |
