# Task List: 爭鮮 PMO 儀表板－工作表自動更新與存取保護

> **Branch**: `002-pmo-data-sync-and-access`
> **Plan**: `specs/002-pmo-data-sync-and-access/plan.md`
> **Total Tasks**: 24
> **Estimated Complexity**: Medium

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

> 路徑說明：除特別註明外，程式碼路徑皆相對於 `frontend/`（`Kiitzu/sushiexpress-pmo-tools-web`）。前端 repo 的工作分支同為 `002-pmo-data-sync-and-access`（自 `001-pmo-dashboard` 開出）。

---

## Phase 0: 環境設置 (Environment Setup)

- [x] [S] **TASK-001**: 建立 frontend 分支並安裝新依賴（plan 1.1、第 8 節）
  - frontend repo 自 `001-pmo-dashboard` 開 `002-pmo-data-sync-and-access`
  - 精確版本安裝 `google-auth-library@11.1.0`、`nodemailer@10.0.10`、`@types/nodemailer@8.0.2`（dev）
  - _驗收_: `package.json` 無浮動版本；`pnpm lint`、`pnpm check:types`、`pnpm test` 通過

- [x] [S] **TASK-002**: 真實快照移出版控，設定檔改為 v2（plan ADR-002、ADR-007）
  - `data/snapshot.json` 自版控移除並列入 `.gitignore`；本機建置預設改用測試快照（無 `data/snapshot.json` 時的處理寫進 README）
  - `data/snapshot.config.json` 改為 `{ spreadsheetId, sheets: { Group: { title, sheetId? } } }`，CSV 流程沿用 `sheetId`
  - 先寫設定檔驗證測試（RED），再實作（GREEN）
  - _驗收_: 設定檔測試通過；`git ls-files data/` 不含真實快照；`pnpm build` 在無真實快照時有明確錯誤訊息

## Phase 1: 讀取工作表 (Sheets Fetch)

> 注意：先寫測試，再寫實作

- [x] [S] **TASK-003**: 資料列解析重構與 API 讀取測試（先寫測試；spec FR-003、SC-003、SC-004、SC-005；plan ADR-001、ADR-002）
  - `scripts/snapshot/parseSheetRows.test.ts`：二維陣列輸入（省略尾端空白格／空白列）與 001 CSV 行為一致：13／15 欄、Progress／燈號驗證、錯誤含分頁與列號
  - `scripts/snapshot/fetchSnapshot.test.ts`（注入假 `fetch`）：中繼資料取得四個分頁 sheetId；`batchGet` 回應轉快照 v2；找不到分頁、403、404、網路錯誤皆回傳讀取失敗與原因；缺欄分頁產生警告；`capturedAt` 為台北時區當日
  - fixture：由 `tests/fixtures/csv/*.csv` 轉成 `values` 格式的錄製回應
  - _驗收_: 新增測試全部 RED；001 既有測試不受影響

- [x] [S] **TASK-004**: 實作 `parseSheetRows` 與 `snapshot:fetch`
  - 自 `buildSnapshot.ts` 抽出 `parseSheetRows`（CSV 與 API 共用）；新增 `scripts/snapshot/fetchSnapshot.ts`：權杖（`google-auth-library`，scope `spreadsheets.readonly`）→ 中繼資料 → `values:batchGet`（`FORMATTED_VALUE`）→ schema v2 → `data/snapshot.json`
  - `package.json` 加 `snapshot:fetch`；讀取 `GOOGLE_SERVICE_ACCOUNT_KEY` 環境變數，log 不輸出金鑰
  - _驗收_: TASK-003 測試 GREEN；`scripts/snapshot` 覆蓋率 100%

## Phase 2: 更新報告與通知 (Report & Notify)

- [x] [P] **TASK-005**: 更新報告與 Email 內容測試（先寫測試；spec FR-005、FR-012、NFR-006、SC-001～SC-005；contracts/update-report.schema.json）
  - `scripts/snapshot/updateReport.test.ts`：trigger（schedule／manual）、status（success／warning／failed）、件數、警告、錯誤；Job Summary Markdown 內容；報告不含任何 Secret
  - `scripts/snapshot/notify.test.ts`（nodemailer JSON transport）：失敗與警告時寄出、成功時不寄；主旨含狀態與日期；內文含分頁、列號、欄位、原值；SMTP 設定缺漏時略過並回傳「未設定通知」
  - _驗收_: 新增測試全部 RED

- [x] [S] **TASK-006**: 實作更新報告、Job Summary 與 Email 通知
  - `scripts/snapshot/updateReport.ts`（zod 驗證）、`scripts/snapshot/notify.ts`；讀取 `PMO_NOTIFY_EMAIL`、`PMO_SMTP_HOST`、`PMO_SMTP_PORT`（465 → SSL、587 → STARTTLS）、`PMO_SMTP_FROM`、`PMO_SMTP_USER`、`PMO_SMTP_PASSWORD`
  - `package.json` 加 `snapshot:report`、`snapshot:notify`
  - _驗收_: TASK-005 測試 GREEN；覆蓋率 100%

## Phase 3: 加密與產物檢查 (Encryption)

- [x] [P] **TASK-007**: 加解密與無明文檢查測試（先寫測試；spec FR-007、SC-006、SC-008；plan ADR-003；contracts/encrypted-snapshot.schema.json）
  - `src/lib/pmo/crypto.test.ts`：Node 端加密 → Web Crypto 端解密往返一致；密碼錯誤拋出可辨識錯誤；每次加密 salt／IV 不同；格式符合契約；衍生金鑰匯出／匯入後可解密；salt 不符的金鑰無法使用
  - `scripts/check-plaintext.test.ts`：以快照中的案件名稱、負責人、LOG 片段搜尋產物，找到任一即違規；密文產物通過
  - _驗收_: 新增測試全部 RED

- [x] [S] **TASK-008**: 實作 `encryptSnapshot`／`decryptSnapshot` 與 `check:plaintext`
  - `src/lib/pmo/crypto.ts`：共用格式與解密（瀏覽器可用）；加密函式僅供建置端使用
  - `scripts/check-plaintext.ts`，`package.json` 加 `check:plaintext`
  - _驗收_: TASK-007 測試 GREEN；`src/lib/pmo` 覆蓋率 100%
  - 註：建置端改用 Node 內建的 Web Crypto（與瀏覽器同一份程式），未使用 Node `crypto` 模組；plan 1.1 所述「Node 內建 crypto」以此實作

## Phase 4: 密碼保護頁面 (Access Gate)

- [x] [S] **TASK-009**: AccessGate 與頁面資料流測試（先寫測試；spec US-003、US-004、SC-007、SC-008）
  - `src/components/shared/AccessGate.test.tsx`：未驗證時只顯示密碼畫面、無任何案件文字；正確密碼顯示子內容；錯誤顯示「密碼不正確」；sessionStorage 有同 salt 金鑰時直接解密；salt 不符時要求重新輸入；解密中顯示進度
  - `src/lib/pmo/pageData.test.ts`：建置端讀快照並加密；未設 `PMO_ACCESS_PASSWORD` 時拋錯，`PMO_ALLOW_PLAINTEXT=1` 時回傳明文（僅本機）
  - 註：為讓三頁共用同一組 salt 與密文（同分頁驗證一次即可切換三頁），加密改為建置前單次執行的 `snapshot:encrypt`（寫出 `.pmo/page-data.json`），`getStaticProps` 只讀取該檔；測試改寫於 `scripts/encryptSnapshot.test.ts`（含 `readPageData`）。CI 環境禁止明文模式
  - _驗收_: 新增測試全部 RED

- [x] [S] **TASK-010**: 實作 AccessGate 並改寫三個入口頁
  - `src/components/shared/AccessGate.tsx`（密碼輸入、錯誤提示、焦點與無障礙標籤）、`src/hooks/use-session-key.ts`
  - `src/pages/{tracker,management,meeting}.tsx` 改用 `getStaticProps` 取得密文；移除 `src/lib/pmo/data.ts` 的用戶端快照 import
  - `build:e2e`／`build:perf` 以測試密碼建置
  - _驗收_: TASK-009 測試 GREEN；`pnpm build` 產物通過 `check:inline` 與 `check:plaintext`

- [x] [S] **TASK-011**: 更新 001 既有 E2E 並新增存取保護 E2E（spec SC-006、SC-007、SC-008）
  - `e2e/helpers.ts`：輸入測試密碼的共用步驟；001 既有 E2E（tracker、management-print、meeting、a11y、performance、smoke）先輸入密碼
  - `e2e/access.spec.ts`：未輸入密碼時頁面與網路回應搜不到案件文字；錯誤密碼提示；正確密碼後切換三頁不需重輸；關閉分頁（新 context）需重輸；密碼畫面通過 axe
  - _驗收_: `pnpm e2e`、`pnpm e2e:perf` 全數通過（效能自輸入密碼後起算）

## Phase 5: 排程工作流程 (Workflow)

- [x] [S] **TASK-012**: 新增 `update-data.yml`（plan ADR-004～ADR-006）
  - 觸發：`schedule: cron '0 1 * * *'`（台北 09:00）、`workflow_dispatch`
  - 步驟：安裝 → `snapshot:fetch` → `build`（`PMO_ACCESS_PASSWORD`）→ `check:inline`、`check:plaintext` → 上傳 artifact `pmo-site-YYYY-MM-DD`（`out/` ＋ `update-report.json`，保留 30 天）→ Job Summary → 失敗或有警告時 `snapshot:notify`（`if: always()`）
  - 預留自動上傳 BPM 的步驟（未設定相關 Secrets 時略過）
  - `concurrency` 避免重疊執行；權限最小化（`contents: read`）
  - _驗收_: `actionlint` 或 GitHub 語法檢查通過；每個步驟對應的 script 皆已有測試
  - 註：以官方 actionlint 1.7.12 檢查通過（npm 版 actionlint 2.0.6 為舊版，不認得 `vars` 而誤報）；BPM 放置路徑以 Variable `NEXT_PUBLIC_BASE_PATH` 設定（選填）

- [x] [P] **TASK-013**: 調整既有 CI（`.github/workflows/ci.yml`）
  - 測試與 E2E 以測試快照與測試密碼執行，不需要任何 Google 或 SMTP Secrets
  - 加入 `check:plaintext`
  - _驗收_: 本機依 CI 步驟完整執行通過

## Phase 6: 上線驗證與收尾 (Go-live & Polish)

- [r] [S] **TASK-014**: 一次性設定（等使用者操作：建立服務帳號並分享工作表、設定 Secrets／Variables、push frontend `002-pmo-data-sync-and-access`）
  - 建立服務帳號並將工作表分享為檢視者
  - 於 frontend repo 設定 Secrets（`GOOGLE_SERVICE_ACCOUNT_KEY`、`PMO_ACCESS_PASSWORD`、`PMO_SMTP_USER`、`PMO_SMTP_PASSWORD`）與 Variables（`PMO_NOTIFY_EMAIL`、`PMO_SMTP_HOST`、`PMO_SMTP_PORT`、`PMO_SMTP_FROM`）
  - push frontend `002-pmo-data-sync-and-access` 分支
  - _驗收_: 使用者確認設定完成（不提供金鑰內容）

- [ ] [S] **TASK-015**: 手動觸發驗證（真實工作表；spec SC-001、SC-002、SC-004、SC-005）
  - `workflow_dispatch` 執行一次：確認 77 件以上、三個分頁缺欄警告與 Email、artifact 可下載、下載後以密碼可開啟三頁
  - 暫時移除服務帳號分享（或填錯試算表 ID）再執行一次，確認失敗時不產生 artifact 且收到 Email
  - _驗收_: 兩次執行結果記錄於本任務註記；排程已啟用

- [x] [P] **TASK-016**: 文件更新
  - `frontend/README.md`：自動更新流程、手動觸發、Secrets／Variables 設定、密碼更換步驟、無真實快照時的本機開發方式、artifact 交付 BPM 步驟
  - `frontend/CHANGELOG.md` 新增 0.2.0
  - _驗收_: 依 README 可從零完成設定與一次更新

- [ ] [S] **TASK-017**: 覆蓋率與最終審查
  - 整體 ≥ 80%，`src/lib/pmo`、`scripts/snapshot` 100%
  - 對照 spec 第 3、6 節逐條驗收；憲法條款（精確版本、JSDoc、函式長度、無行內腳本、無明文、無 Secret 外洩）
  - _驗收_: 全數通過，PR 可送審


## Phase 7: 收斂 (Convergence)

> 來源：使用者要求會議頁編輯與存檔先關閉、改由環境設定開啟（spec US-005、FR-017、SC-009、SC-010；plan ADR-008）。

- [x] [S] **TASK-018**: 會議頁唯讀設定測試（先寫測試）— 依據 FR-017、SC-009（missing）
  - `src/hooks/use-meeting-entries.test.tsx`：停用時不讀取、不寫入 localStorage，燈號為原表燈號，`save` 無作用
  - `src/components/meeting/MeetingView.test.tsx`：`editable={false}` 時無燈號按鈕、無「更新」、無操作欄、統計與篩選照常、說明文字為唯讀；既有測試以 `editable` 執行
  - `config/env` 讀取：僅 `true` 開啟
  - _驗收_: 新增測試全部 RED

- [x] [S] **TASK-019**: 實作會議頁唯讀設定 — 依據 FR-017、SC-009、SC-010（missing）
  - `config/env.js` 新增 `meetingEditable`；`useMeetingEntries` 支援停用；`MeetingView`／`MeetingTable` 依 `editable` 渲染；`pages/meeting.tsx` 傳入設定
  - `build:e2e`／`build:perf` 以開啟狀態建置；`.env.example`、README、`update-data.yml`（`vars.NEXT_PUBLIC_PMO_MEETING_EDIT`）更新
  - _驗收_: TASK-018 測試 GREEN；lint、型別、E2E 通過
  - 註：設定改由 `pages/meeting.tsx` 的 `getStaticProps` 以 `meetingEditableOf(process.env)` 讀取（`src/lib/pmo/features.ts`），未放在 `config/env.js`；另新增唯讀建置 E2E（`build:e2e:readonly`、`e2e:readonly`，CI 已加入）


## Phase 8: 收斂 (Convergence)

> 來源：使用者要求排程每次執行都寄信（spec FR-005 修訂、SC-011；plan ADR-006）。

- [x] [S] **TASK-020**: 成功也寄通知的測試（先寫測試）— 依據 FR-005、SC-011（contradicts）
  - `scripts/snapshot/notify.test.ts`：成功時也產生郵件（主旨「工作表更新成功（日期）」、各分頁件數、執行紀錄連結）並寄出；失敗與警告維持原內容
  - _驗收_: 新增或修改的測試 RED

- [x] [S] **TASK-021**: 實作每次更新皆寄通知 — 依據 FR-005、SC-011（contradicts）
  - `notify.ts`：移除「成功不寄」；成功郵件內容；workflow 步驟名稱與 README 說明同步
  - _驗收_: TASK-020 測試 GREEN；`scripts/snapshot` 覆蓋率 100%


## Phase 9: 收斂 (Convergence)

> 來源：使用者改以 GitHub Pages 發佈至 `https://pmo-sync.evanwang.cc`（spec FR-013 修訂、SC-012；plan ADR-005 修訂）。

- [x] [S] **TASK-022**: 網站發佈相關測試（先寫測試）— 依據 FR-013、FR-005、SC-012（missing）
  - `e2e/root.spec.ts`：開啟 `/` 轉到 `/tracker` 並出現密碼畫面；根頁不含腳本
  - `scripts/snapshot/notify.test.ts`：有 `PMO_SITE_URL` 時成功與警告信附網站網址；失敗信不附
  - _驗收_: 新增測試全部 RED

- [x] [S] **TASK-023**: 實作 GitHub Pages 自動發佈 — 依據 FR-013、SC-012（missing）
  - `src/pages/index.tsx`：meta refresh 轉到 `tracker`（依 basePath）
  - `notify.ts`：附網站網址
  - `update-data.yml`：`push: master` 觸發、Pages 權限與環境、configure／upload／deploy-pages、以部署網址設定 `PMO_SITE_URL`
  - README、`.env.example`
  - _驗收_: TASK-022 測試 GREEN；actionlint、lint、型別、E2E 通過

- [ ] [S] **TASK-024**: 首次發佈後啟用 HTTPS 並驗證（等使用者合併到 master 並完成首次部署）
  - repo Settings → Pages 勾選 Enforce HTTPS
  - 開啟 `https://pmo-sync.evanwang.cc/` 轉到案件追蹤頁、以密碼開啟三頁；收到含網站網址的通知信
  - _驗收_: 使用者確認 HTTPS 已啟用且網站可用

## Phase 10: 收斂 (Convergence)

> 來源：使用者要求通知信附存取密碼以便確認（spec FR-005、NFR-002、SC-011 修訂；plan ADR-005）。

- [x] [S] **TASK-025**: 通知信附存取密碼測試（先寫測試）— 依據 FR-005、SC-011（missing）
  - `scripts/snapshot/notify.test.ts`：有 `PMO_ACCESS_PASSWORD` 時成功與警告信含「存取密碼：…」；失敗信與未設定時不含；SMTP 密碼仍不入信
  - _驗收_: 新增測試 RED

- [x] [S] **TASK-026**: 實作通知信附存取密碼 — 依據 FR-005、SC-011（missing）
  - `notify.ts`：成功／警告信加入存取密碼
  - `update-data.yml`：通知步驟傳入 `PMO_ACCESS_PASSWORD`；README 說明
  - _驗收_: TASK-025 測試 GREEN；actionlint、lint、型別、覆蓋率通過

## Phase 11: 收斂 (Convergence)

> 來源：使用者要求頁首加上三頁導覽（spec FR-018、SC-013；plan ADR-009；修訂 001 FR-001）。

- [x] [S] **TASK-027**: 頁首導覽測試（先寫測試）— 依據 FR-018、SC-013（missing）
  - `AppShell.test.tsx`：頁首導覽含三個連結（`/tracker`、`/management`、`/meeting`），目前頁 `aria-current="page"`
  - `e2e/nav.spec.ts`：從案件追蹤頁點導覽依序切到另外兩頁，不需重輸密碼；導覽通過 axe
  - _驗收_: 新增測試 RED

- [x] [S] **TASK-028**: 實作頁首導覽 — 依據 FR-018、SC-013（missing）
  - `AppShell.tsx`：以導覽取代頁面名稱文字；手機換行；列印隱藏
  - _驗收_: TASK-027 測試 GREEN；lint、型別、覆蓋率、E2E 通過

## Phase 12: 收斂 (Convergence)

> 來源：通知收件人可為多人，使用者撤回「通知信附存取密碼」（spec FR-005、NFR-002、SC-011 回復；plan ADR-005）。取代 TASK-025～026 的行為。

- [x] [S] **TASK-029**: 通知信不含存取密碼測試（先寫測試）— 依據 FR-005、NFR-002、SC-011（missing）
  - `scripts/snapshot/notify.test.ts`：即使環境有 `PMO_ACCESS_PASSWORD`，成功、警告、失敗信都不含密碼與「存取密碼」字樣
  - _驗收_: 新增測試 RED

- [x] [S] **TASK-030**: 移除通知信的存取密碼 — 依據 FR-005、NFR-002、SC-011（missing）
  - `notify.ts`：移除密碼行；`update-data.yml` 通知步驟不再傳入 `PMO_ACCESS_PASSWORD`；README 同步
  - _驗收_: TASK-029 測試 GREEN；actionlint、lint、型別、覆蓋率通過

## Phase 13: 收斂 (Convergence)

> 來源：正式資料出現很長的案件名稱（含多段需求說明），表格依內容撐寬，其他欄被擠出畫面（使用者 2026-10-06 回報；001 FR-018 版面支援桌機與手機寬度）。

- [x] [S] **TASK-031**: 長案件名稱欄寬測試（先寫測試）— 依據 001 FR-018（missing）
  - `e2e/column-width.spec.ts`：案件追蹤、管理層呈報（工作列表）、IT 內部會議三個表格，將第一列案件名稱換成 300 字長文後，名稱欄寬不超過 480px，且名稱折行顯示
  - _驗收_: 新增測試 RED

- [x] [S] **TASK-032**: 限制案件名稱欄最大寬度 — 依據 001 FR-018（missing）
  - `CaseTable`、`MeetingTable`：案件名稱設最大寬度、折行，超過 3 行截斷（完整名稱見詳細內容）
  - _驗收_: TASK-031 測試 GREEN；lint、型別、覆蓋率、E2E 通過

---

## 進度追蹤

| Phase | 任務數 | 完成數 | 狀態 |
|-------|--------|--------|------|
| Phase 0: 環境設置 | 2 | 2 | Done |
| Phase 1: 讀取工作表 | 2 | 2 | Done |
| Phase 2: 更新報告與通知 | 2 | 2 | Done |
| Phase 3: 加密與產物檢查 | 2 | 2 | Done |
| Phase 4: 密碼保護頁面 | 3 | 3 | Done |
| Phase 5: 排程工作流程 | 2 | 2 | Done |
| Phase 6: 上線驗證與收尾 | 4 | 1 | In Progress（TASK-014 等使用者設定） |
| Phase 7: 收斂 | 2 | 2 | Done |
| Phase 8: 收斂 | 2 | 2 | Done |
| Phase 9: 收斂 | 3 | 2 | In Progress（TASK-024 等首次部署） |
| Phase 10: 收斂 | 2 | 2 | Done |
| Phase 11: 收斂 | 2 | 2 | Done |
| Phase 12: 收斂 | 2 | 2 | Done |
| Phase 13: 收斂 | 2 | 2 | Done |
| **總計** | **32** | **28** | **88%** |
