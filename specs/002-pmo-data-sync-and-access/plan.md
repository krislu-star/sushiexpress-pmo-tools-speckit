# Implementation Plan: 爭鮮 PMO 儀表板－工作表自動更新與存取保護

> **Branch**: `002-pmo-data-sync-and-access`
> **Spec**: `specs/002-pmo-data-sync-and-access/spec.md`
> **Status**: Draft
> **Author**: Evan
> **Date**: 2026-09-23

---

## Phase -1: 憲法閘門檢查 (Constitution Gates)

- [x] **Article I**：新增依賴僅 `google-auth-library`、`nodemailer`、`@types/nodemailer`，精確版本列於第 8 節；其餘沿用 001
- [x] **Article II**：沿用 001 規則（TS strict、JSDoc、單函式 ≤ 50 行、純函式優先）
- [x] **Article III**：各階段先寫失敗測試；加密／解密、工作表讀取轉換、更新報告為關鍵路徑，覆蓋率 100%；外部服務（Google、SMTP）以假服務測試，不涉及資料庫
- [x] **Article IV**：工作表授權、存取密碼、SMTP 帳密只存 GitHub Secrets；產物不含明文案件資料（CI 檢查）；工作表只授予唯讀
- [x] **Article V**：`spec.md` 無未解決的 `[NEEDS CLARIFICATION]`（BPM 能力相關兩項已轉為 spec 第 8 節假設，見風險 R-1、R-2）
- [x] **Article V**：前後端範圍已於 2.3 分開描述；後端寫明「本功能不涉及」
- [x] **Article VI**：在 `002-pmo-data-sync-and-access` 分支進行（自 001 分支開出，001 合併後 rebase）；frontend repo 另開同名分支
- [x] **Article XII**：不涉及 `cms/`
- [x] **Article XIII**：`Owner` 為 `@evan`（一人），Layout = single
- [x] **Article VIII**：spec／plan／tasks 與程式碼同步版控

---

## 1. 技術背景 (Technical Context)

### 1.1 技術棧選擇

沿用 001 的前端技術棧（Next.js 14 Pages Router 靜態匯出、React 18、TypeScript、Tailwind 3、Jest、Playwright）。本功能新增：

| 層次 | 技術 | 版本 | 選擇原因 |
|------|------|------|---------|
| 排程與手動觸發 | GitHub Actions（`schedule` + `workflow_dispatch`） | - | 已是 frontend repo 的 CI；免另建主機；Secrets 保存授權 |
| 讀取工作表 | Google Sheets API v4（REST，`values:batchGet` 與試算表中繼資料） | v4 | 以服務帳號唯讀讀取；回傳二維陣列，可直接沿用 001 的欄位驗證 |
| 服務帳號驗證 | google-auth-library | 11.1.0 | 取得存取權杖；只用驗證功能，以內建 `fetch` 呼叫 REST，不引入整包 `googleapis` |
| 資料加密（建置端） | Node.js 內建 `crypto`（PBKDF2-SHA256 + AES-256-GCM） | Node 22 | 無需新增套件 |
| 資料解密（瀏覽器） | Web Crypto API（`crypto.subtle`） | Chrome 內建 | 無需新增套件；不使用行內腳本，符合 001 的 CSP 要求 |
| Email 通知 | nodemailer（SMTP） | 10.0.10 | 以公司或指定 SMTP 帳號寄送更新失敗／警告報告 |

### 1.2 架構決策記錄 (ADR)

**ADR-001：讀取與建置分成兩步：先取快照，再建置**
- **狀態**: Accepted
- **背景**: 可在 Next 的 `getStaticProps` 內直接呼叫 Sheets API，但三個頁面會各呼叫一次（建置平行執行），擷取時間可能不一致，錯誤也較難集中處理。
- **決策**: 新增 `pnpm snapshot:fetch`：以服務帳號讀取四個分頁 → 沿用 001 的欄位解析與 schema v2 驗證 → 寫出 `data/snapshot.json` 與更新報告；之後才執行 `next build`。讀取或驗證失敗時流程中止，不進入建置。
- **結果**: 一次讀取、一個擷取日期；001 的 `parseSheetCsv` 拆為「CSV 解析」與「資料列解析」兩層，CSV 與 API 共用同一套驗證與錯誤訊息（spec SC-003、SC-004）。

**ADR-002：分頁 gid 由 API 取得，設定只保留試算表 ID 與分頁名稱**
- **決策**: 讀取試算表中繼資料取得各分頁 `sheetId`，不再手寫 gid；`data/snapshot.config.json` 改為 `spreadsheetId` 與四個分頁名稱。找不到分頁時視為讀取失敗（SC-005）。
- **結果**: 分頁改名或新增不需改程式；CSV 流程仍可用（手動備援），gid 從設定檔讀取。

**ADR-003：建置時加密、瀏覽器端解密（spec US-003 方案 B）**
- **背景**: 產物為靜態檔，僅在前端比對密碼無法保護資料（spec FR-007、SC-006）。
- **決策**:
  - 頁面不再於用戶端 import `data/snapshot.json`；改由 `getStaticProps` 在建置時讀取快照，以 `PMO_ACCESS_PASSWORD` 加密後只把密文傳給頁面。
  - 金鑰：PBKDF2-SHA256（600,000 次、16 位元組隨機 salt）→ AES-256-GCM（12 位元組隨機 IV）。同一次建置三頁共用同一組 salt 與密文。
  - 瀏覽器：密碼輸入畫面 → Web Crypto 推導金鑰並解密 → GCM 驗證失敗即顯示「密碼不正確」（SC-008）。
  - 金鑰（不是密碼）存於 `sessionStorage`，同一分頁切換三頁不需重輸入；關閉分頁即失效（US-004）。salt 每次建置不同，所以更換密碼或每日重建後，舊金鑰自動失效並要求重新輸入。
  - 未設定 `PMO_ACCESS_PASSWORD` 時建置失敗（本機開發可設 `PMO_ALLOW_PLAINTEXT=1` 顯式略過，CI 與正式建置禁止）。
- **結果**: 產物只有密文；CI 新增「無明文」檢查（以快照中的案件名稱、負責人、LOG 片段搜尋 `out/`，一律不得出現）。會議頁本機紀錄（001）仍為明文存在使用者瀏覽器，不在本次保護範圍（見風險 R-4）。

**ADR-004：排程與手動觸發**
- **決策**: 新增 workflow `update-data.yml`：`schedule: cron '0 1 * * *'`（UTC 01:00 = 台北 09:00）與 `workflow_dispatch`（手動，spec FR-002）。步驟：安裝 → `snapshot:fetch` → `build`（帶密碼）→ `check:inline` 與「無明文」檢查 → 上傳頁面檔案為 artifact → 產出更新報告 → 失敗或有警告時寄 Email。
- **結果**: 任一步失敗即不產出新的可交付檔案，線上維持上一版（FR-004、NFR-004）。GitHub 排程可能延遲數分鐘至十數分鐘（R-3）。

**ADR-005：交付方式——GitHub Pages 自動發佈（spec FR-013；2026-09-23 修訂）**
- **狀態**: Accepted（原「artifact＋人工上傳 BPM」改為自動發佈）
- **背景**: Kiitzu 為 Team 方案，私有 repo 的 Pages 網站為公開；資料已加密（ADR-003），公開網址只暴露密文。使用者已將 Pages 來源設為 GitHub Actions，並綁定自訂網域 `pmo-sync.evanwang.cc`（CNAME → `kiitzu.github.io`）。
- **決策**:
  - `update-data.yml` 於檢查通過後以 `actions/configure-pages`、`actions/upload-pages-artifact`、`actions/deploy-pages` 發佈 `out/`；job 權限加上 `pages: write`、`id-token: write`，環境 `github-pages`。
  - 新增 `push: master` 觸發：程式合併後立即以最新資料重新發佈，不必等隔天排程。
  - 自訂網域位於根目錄，`NEXT_PUBLIC_BASE_PATH` 留空；網域設定存於 repo Pages 設定，不需 `CNAME` 檔。
  - 新增根頁 `index.html`：以 `<meta http-equiv="refresh">` 轉到 `tracker`（不使用腳本，符合 CSP 設計）。
  - 通知 Email 附網站網址（`PMO_SITE_URL`，取自部署結果）。
  - 通知 Email 不含任何 Secret（含存取密碼）；通知步驟不讀取 `PMO_ACCESS_PASSWORD`（2026-09-24 撤回附密碼，spec FR-005）。
  - 仍上傳 artifact 供 BPM 等其他空間人工使用。
- **結果**: 交付全自動；任一步失敗即不發佈，網站維持上一版。HTTPS 憑證於首次部署後核發，核發後於 Pages 設定勾選 Enforce HTTPS。

**ADR-006：更新報告與通知**
- **決策**: `snapshot:fetch` 與後續檢查寫出 `update-report.json`（觸發方式、時間、各分頁件數、警告、錯誤）。報告同時寫入 GitHub Actions 的 Job Summary（FR-012、NFR-006，保存於 workflow 執行紀錄），並附於 artifact。每次執行（成功、有警告、失敗）皆以 nodemailer 寄給 `PMO_NOTIFY_EMAIL`（spec FR-005，2026-09-23 修訂：原為僅失敗或有警告時寄送）；收件地址存於 GitHub Actions Variables，SMTP 帳密存於 Secrets。
- **結果**: 無新增資料庫或主機；更新紀錄以 GitHub 執行紀錄保存（預設 90 天）。

**ADR-009：頁首三頁導覽（spec FR-018、SC-013；2026-09-24）**
- 背景：001 以三個獨立入口為前提（BPM 分別建入口）；改為單一網站後需要頁間切換。
- 決策：`AppShell` 頁首以 `next/link` 提供三個連結（自動套用 basePath），以頁面名稱判定目前頁並設 `aria-current="page"`；手機寬度換行成整列；列印隱藏（沿用頁首 `print:hidden`）。
- 結果：同一分頁 sessionStorage 已有金鑰，切換不需重輸密碼；不引入路由狀態或新套件。

**ADR-007：真實快照不再進版控**
- **決策**: 每日快照只存在 CI 執行環境與 artifact；repo 的 `data/snapshot.json` 改為建置用的預設位置，不提交真實資料（改列入 `.gitignore`）。本機開發以 `tests/fixtures/snapshot.sample.json` 或手動 `snapshot:fetch` 產生。
- **結果**: 版本庫不含真實案件資料；001 已提交的 `data/snapshot.json` 於本功能移除（git 歷史仍保留，repo 為 private）。

**ADR-008：會議編輯以建置時設定開關（spec US-005、FR-017）**
- **決策**: `NEXT_PUBLIC_PMO_MEETING_EDIT=true` 時開啟會議編輯，其他值或未設定皆為唯讀；於 `config/env.js` 讀取，建置時決定（靜態匯出）。唯讀時 `useMeetingEntries` 不讀寫 localStorage，燈號一律為原表燈號；表格不渲染燈號按鈕、「更新」按鈕與操作欄。
- **結果**: 預設所有人看到一致的原表燈號；要開啟時於 GitHub Variables（排程）或 `.env.local`（本機）設定後重新建置。E2E 以開啟狀態建置以涵蓋 001 的編輯流程，唯讀以元件測試涵蓋。

## 2. 系統架構 (System Architecture)

### 2.1 元件圖

```
GitHub Actions：update-data.yml（每天 09:00 台北 ／ 手動）
 ├─ snapshot:fetch ──(服務帳號，唯讀)──> Google Sheets（Frontend／Project／BPM／SAP）
 │    ├─ 中繼資料 → 分頁 sheetId
 │    ├─ values:batchGet A:O → parseSheetRows（001 驗證）→ data/snapshot.json
 │    └─ update-report.json（件數、警告、錯誤）
 ├─ next build（PMO_ACCESS_PASSWORD）
 │    └─ getStaticProps：讀快照 → encryptSnapshot → props { encrypted }
 ├─ check:inline ＋ check:plaintext
 ├─ upload artifact：out/ ＋ update-report.json
 ├─ Job Summary：更新報告
 └─ notify（失敗或有警告）──SMTP──> Owner 信箱

瀏覽器（BPM 靜態空間）
 tracker.html ／ management.html ／ meeting.html
   └─ AccessGate：輸入密碼 → Web Crypto 解密 → 001 的三個 View
        └─ sessionStorage：本分頁的解密金鑰
```

### 2.2 執行流程 (Execution Flow)

```
1. 觸發：cron 01:00 UTC 或 workflow_dispatch（記錄 trigger=schedule|manual）
2. 讀取：取得權杖 → 讀中繼資料 → batchGet 四個分頁（FORMATTED_VALUE，保留「90%」等原文）
3. 驗證：parseSheetRows（13／15 欄、Progress、燈號、空白列、列號）→ schema v2；失敗 → 報告錯誤 → 通知 → 結束
4. 建置：getStaticProps 加密 → 靜態匯出；檢查無行內腳本、無明文
5. 產出：artifact＋Job Summary；有警告（如缺欄分頁）→ 仍產出並通知
6. 使用：開頁 → 密碼 → 解密 → 顯示；同分頁內三頁共用金鑰
```

### 2.3 前後端範圍切分 (Frontend / Backend Scope)

**前端範圍（`frontend/`）**

- 負責：`snapshot:fetch` 讀取工作表與驗證、更新報告與 Email 通知、GitHub Actions 排程與手動觸發、建置時加密、密碼輸入與瀏覽器解密、無明文檢查、artifact 產出
- 不負責：建立 Google Cloud 專案與服務帳號、分享工作表（由工作表擁有者操作）；SMTP 帳號提供；BPM 伺服器設定與上傳管道（由維運負責）；工作表內容與欄位維護（資料維護者）
- 涉及頁面／元件：三個入口頁改由 `getStaticProps` 取得密文；新增 `AccessGate`；001 的 View 元件不變
- 依賴的 API：Google Sheets API v4（外部服務，唯讀）；無自有後端 API

**後端範圍（`backend/`）**

- 本功能不涉及。
- 不負責：本功能沒有伺服器端元件；即時讀取、回寫工作表、個人帳號權限皆為範圍外（spec 第 7 節），若日後需要另開規格。
- 涉及模組／服務：無
- 對外提供的 API：無

**交界與契約**

- 無自有 API。資料交界為：快照格式 v2（沿用 `specs/001-pmo-dashboard/contracts/snapshot.schema.json`）、加密後的頁面資料（`contracts/encrypted-snapshot.schema.json`）、更新報告（`contracts/update-report.schema.json`）。
- 依憲法 Article XII，`cms/` 不列入任何實作範圍。

## 3. 資料模型 (Data Model)

### 3.1 實體定義

```
SnapshotConfig（data/snapshot.config.json，v2）
├── spreadsheetId: 字串
└── sheets: Record<Group, { title: 字串, sheetId?: 整數 }>   // title 供 API；sheetId 供 CSV 備援

Snapshot（沿用 001 v2，不變）

EncryptedSnapshot（頁面 props，contracts/encrypted-snapshot.schema.json）
├── version: 1
├── kdf: { name: 'PBKDF2', hash: 'SHA-256', iterations: 600000, salt: base64(16 bytes) }
├── cipher: { name: 'AES-GCM', iv: base64(12 bytes) }
└── data: base64（密文＋GCM tag；明文為 Snapshot 的 JSON）
    // 不含任何明文欄位；擷取日期等資訊一律在解密後由 Snapshot 取得

UpdateReport（update-report.json，contracts/update-report.schema.json）
├── trigger: 'schedule' | 'manual'
├── startedAt, finishedAt: ISO 8601
├── status: 'success' | 'warning' | 'failed'
├── capturedAt: YYYY-MM-DD | null
├── counts: Record<Group, 整數> | null
├── warnings: 字串[]      // 例：SAP 分頁尚未有 Progress 與燈號欄…
└── errors: 字串[]        // 例：Project 分頁第 10 列 Progress「約九成」無法辨識…

SessionKey（瀏覽器 sessionStorage，key `sushi-pmo-key`）
└── { salt: base64, key: base64（匯出的 AES 金鑰） }   // salt 不符即視為失效
```

### 3.2 資料庫 Schema

本功能不涉及資料庫。

## 4. API 合約 (API Contracts)

### 4.1 端點定義

本功能無自有 HTTP 端點。呼叫的外部 API（唯讀）：

```yaml
# 試算表中繼資料（取得分頁 sheetId）
GET https://sheets.googleapis.com/v4/spreadsheets/{spreadsheetId}?fields=sheets.properties(sheetId,title)
Authorization: Bearer {服務帳號權杖，scope: spreadsheets.readonly}

# 讀取四個分頁
GET https://sheets.googleapis.com/v4/spreadsheets/{spreadsheetId}/values:batchGet
    ?ranges=Frontend!A:O&ranges=Project!A:O&ranges=BPM!A:O&ranges=SAP!A:O
    &valueRenderOption=FORMATTED_VALUE&majorDimension=ROWS
Response 200: { valueRanges: [{ range, values: string[][] }] }   // 省略尾端空白列與空白格
Response 403／404：視為讀取失敗（SC-005），錯誤訊息含分頁或原因
```

內部契約檔：`contracts/encrypted-snapshot.schema.json`、`contracts/update-report.schema.json`。

## 5. 測試策略 (Testing Strategy)

### 5.1 測試層次

| 層次 | 歸屬 | 工具 | 覆蓋目標 | 測試類型 |
|------|------|------|---------|---------|
| Unit | 前端 | Jest | 80%；`src/lib/pmo`（含加密）與 `scripts/snapshot` 100% | 資料列解析、API 回應轉換、加解密往返、報告與通知內容 |
| Component | 前端 | Jest + Testing Library | AccessGate 全部分支 | 密碼正確／錯誤、sessionStorage 共用與失效 |
| E2E | 前端 | Playwright | 密碼保護與三頁使用 | 以測試密碼建置 `out-e2e`，驗證輸入、錯誤、跨頁不需重輸 |
| 產物檢查 | 前端 | `check:plaintext` | 每次建置 | 產物中搜不到快照明文 |
| Workflow | 前端 | 手動 `workflow_dispatch` | 上線前一次 | 真實工作表、Secrets、通知、artifact |

外部服務一律以假服務測試：Sheets API 以注入的 `fetch` 回傳錄製的回應（由 001 的 fixture CSV 轉成 `values` 格式）；SMTP 以 nodemailer 的 JSON transport 驗證郵件內容。

### 5.2 測試場景對應

| 驗收場景 | 測試類型 | 測試檔案位置 |
|---------|---------|------------|
| SC-001 排程自動更新 | Unit + Workflow | `scripts/snapshot/fetchSnapshot.test.ts`、`update-data.yml` 手動驗證 |
| SC-002 手動觸發 | Unit + Workflow | `scripts/snapshot/updateReport.test.ts`（trigger=manual） |
| SC-003 資料錯誤不上線 | Unit | `scripts/snapshot/fetchSnapshot.test.ts`、`scripts/snapshot/notify.test.ts` |
| SC-004 分頁缺欄 | Unit | `scripts/snapshot/fetchSnapshot.test.ts`、`scripts/snapshot/notify.test.ts` |
| SC-005 工作表無法讀取 | Unit | `scripts/snapshot/fetchSnapshot.test.ts`（403／404／缺分頁） |
| SC-006 未授權取得資料 | Unit + 產物檢查 + E2E | `src/lib/pmo/crypto.test.ts`、`scripts/check-plaintext.test.ts`、`e2e/access.spec.ts` |
| SC-007 驗證後正常使用 | Component + E2E | `src/components/shared/AccessGate.test.tsx`、`e2e/access.spec.ts`，並更新 001 既有 E2E 先輸入測試密碼 |
| SC-008 密碼錯誤與更換 | Unit + Component + E2E | `src/lib/pmo/crypto.test.ts`、`AccessGate.test.tsx`、`e2e/access.spec.ts` |

## 6. 安全考量 (Security Considerations)

- **認證**：共用密碼（ADR-003）；無個人帳號（spec 範圍外）。
- **授權資訊保存**：`GOOGLE_SERVICE_ACCOUNT_KEY`、`PMO_ACCESS_PASSWORD`、`PMO_SMTP_USER`、`PMO_SMTP_PASSWORD` 存 GitHub Secrets；`PMO_NOTIFY_EMAIL`、`PMO_SMTP_HOST`、`PMO_SMTP_PORT`、`PMO_SMTP_FROM` 存 Variables。程式與 log 不輸出任何 Secret；錯誤訊息只含分頁、列號、欄位與儲存格原值。
- **工作表權限**：服務帳號只取得「檢視者」，權杖 scope 限 `spreadsheets.readonly`。
- **資料保護**：產物只含密文；`check:plaintext` 於 CI 阻擋。密碼強度：測試階段可用簡易密碼，正式上線前換為 ≥ 16 字元（spec NFR-003）；離線暴力破解風險以 PBKDF2 600,000 次提高成本。
- **金鑰保存**：瀏覽器只存衍生金鑰於 `sessionStorage`，不存密碼；每次建置更換 salt，使舊金鑰失效。
- **輸出安全**：沿用 001（文字節點渲染、無行內腳本）。

## 7. 效能考量 (Performance Considerations)

- 讀取四個分頁為一次 `batchGet`，數秒內完成；整個 workflow 目標 < 15 分鐘（NFR-001）。
- 瀏覽器解密：PBKDF2 600,000 次約 0.3～1 秒，只在輸入密碼時執行一次；之後以 sessionStorage 的金鑰直接解密（AES-GCM 對數百 KB 資料 < 50ms）。
- 001 的 500 件效能測試改為「輸入密碼後」起算。

## 8. 依賴清單 (Dependencies)

### 新增依賴（精確版本）

| 套件名稱 | 版本 | 用途 | 評估狀態 |
|---------|------|------|---------|
| google-auth-library | 11.1.0 | 服務帳號權杖（僅 CI 與 `snapshot:fetch` 使用，不進瀏覽器 bundle） | Approved |
| nodemailer | 10.0.10 | 更新失敗／警告 Email（僅 CI 使用） | Approved |
| @types/nodemailer | 8.0.2 | 型別（dev） | Approved |

### 現有依賴使用

| 套件名稱 | 用途 |
|---------|------|
| zod | 更新報告、加密資料、設定檔 v2 驗證 |
| Node `crypto`／Web Crypto | 加密與解密（內建） |

## 9. 部署考量 (Deployment Considerations)

- **GitHub Secrets**（frontend repo → Settings → Secrets and variables → Actions → Secrets）：

  | 名稱 | 內容 |
  |------|------|
  | `GOOGLE_SERVICE_ACCOUNT_KEY` | 服務帳號 JSON 金鑰完整內容 |
  | `PMO_ACCESS_PASSWORD` | 頁面共用密碼（測試階段可用簡易密碼，正式上線前 ≥ 16 字元） |
  | `PMO_SMTP_USER` | SMTP 登入帳號 |
  | `PMO_SMTP_PASSWORD` | SMTP 密碼（Google Workspace／Gmail 使用應用程式密碼） |

- **GitHub Variables**（同頁 Variables 分頁）：

  | 名稱 | 內容 |
  |------|------|
  | `PMO_NOTIFY_EMAIL` | 通知收件人，多人以逗號分隔（Owner 信箱） |
  | `PMO_SMTP_HOST` | SMTP 主機（Google Workspace：`smtp.gmail.com`；Microsoft 365：`smtp.office365.com`） |
  | `PMO_SMTP_PORT` | `465`（SSL）或 `587`（STARTTLS），依埠號決定連線方式 |
  | `PMO_SMTP_FROM` | 寄件人，例：`爭鮮 PMO 儀表板 <寄件地址>` |

  任一 SMTP 設定缺漏時仍更新資料，通知步驟略過並於 Job Summary 標示（R-5）。
- **一次性設定（非本功能程式）**：建立服務帳號並分享工作表為檢視者；於 frontend repo 設定上述 Secrets／Variables；確認 workflow 已啟用。
- **交付**：GitHub Pages 自動發佈至 `https://pmo-sync.evanwang.cc`（ADR-005）；repo Settings → Pages 的 Source 為 GitHub Actions、Custom domain 為 `pmo-sync.evanwang.cc`，首次部署後勾選 Enforce HTTPS。
- **風險**：
  - **R-1 存取方式**：本版採共用密碼；若 Herbert 確認 BPM 可於伺服器端把關，另開規格評估，屆時可移除加密層。
  - **R-2 交付**：已解決，改為 GitHub Pages 自動發佈（ADR-005）。BPM 若仍需放置，下載 artifact 人工上傳。
  - **R-3 排程延遲**：GitHub 排程在尖峰可能延遲；若需準時，可改為 08:30 觸發或改用其他排程器。
  - **R-4 會議本機紀錄**：001 的會議燈號、風險、下一步以明文存在使用者瀏覽器，不受密碼保護；如需保護另開規格。
  - **R-6 公開網址**：網站公開、僅以共用密碼保護；正式上線前須換強密碼，並取得爭鮮同意。
  - **R-5 SMTP 帳號**：需提供可寄信的 SMTP 帳號（公司郵件或專用帳號）；未設定時 workflow 仍執行，通知步驟略過並於 Job Summary 標示。

## 10. 實作階段 (Implementation Phases)

| 階段 | 內容 | 歸屬 | 預估複雜度 |
|------|------|------|-----------|
| Phase 0 | frontend repo 開 `002-pmo-data-sync-and-access` 分支；安裝新依賴；設定檔 v2；`data/snapshot.json` 移出版控 | 前端 | Low |
| Phase 1 | 資料列解析重構（CSV 與 API 共用）；`snapshot:fetch`（中繼資料、batchGet、錯誤處理）＋測試 | 前端 | Medium |
| Phase 2 | 更新報告與 Email 通知＋測試 | 前端 | Medium |
| Phase 3 | 加解密（建置端與瀏覽器共用格式）、`check:plaintext`＋測試 | 前端 | Medium |
| Phase 4 | 頁面改用 `getStaticProps` 密文、`AccessGate`、sessionStorage 金鑰＋測試；001 E2E 改為先輸入測試密碼 | 前端 | Medium |
| Phase 5 | `update-data.yml`（排程、手動、建置、檢查、artifact、Job Summary、通知）；CI 調整 | 前端 | Medium |
| Phase 6 | 上線前手動觸發一次（真實工作表）、文件（README、維運步驟）、最終驗證 | 前端 | Low |

---

## 計劃品質核對清單 (Plan Quality Checklist)

- [x] 所有憲法閘門已通過
- [x] 技術棧選擇有明確的理由
- [x] 資料模型涵蓋所有規格中的實體
- [x] API 合約對應所有功能需求（無自有 API；外部 API 與內部契約已列出）
- [x] 測試場景對應所有驗收場景
- [x] 安全考量已識別所有威脅
- [x] 無低階程式碼（plan 只到架構層）
- [x] 前端與後端範圍已分開描述（2.3），雙方的「負責／不負責」都寫明
- [x] 每個實作階段都標註歸屬（前端／後端／兩者）
