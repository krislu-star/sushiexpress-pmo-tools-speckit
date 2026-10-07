# Implementation Plan: 爭鮮 IT 案件追蹤與管理層呈報儀表板

> **Branch**: `001-pmo-dashboard`
> **Spec**: `specs/001-pmo-dashboard/spec.md`
> **Status**: Draft
> **Author**: Evan
> **Date**: 2026-09-23

---

## Phase -1: 憲法閘門檢查 (Constitution Gates)

- [x] **Article I**：技術棧與所有依賴均列於第 1.1 節與第 8 節，版本一律鎖定精確版本（無 `^`、`~`、`latest`）
- [x] **Article II**：TypeScript strict；公開函式／元件寫 JSDoc；單一函式 ≤ 50 行（以 ESLint `max-lines-per-function` 強制）；資料轉換採純函式、不可變寫法
- [x] **Article III**：每個階段先寫失敗測試再實作；unit 覆蓋率門檻 80%，關鍵路徑（資料轉換、篩選排序、會議本機儲存、呈報分頁）100%；本功能無資料庫，不涉及「禁止 mock 資料庫」條款
- [x] **Article IV**：無 API 端點、無憑證；快照與本機儲存在邊界以 schema 驗證（第 6 節）
- [x] **Article V**：`spec.md` 已完成，無未解決的 `[NEEDS CLARIFICATION]`（CSP／iframe 已轉為 spec 第 8 節部署假設，見風險 R-1）
- [x] **Article V**：前後端範圍已於 2.3 分開描述；後端寫明「本功能不涉及」
- [x] **Article VI**：在 `001-pmo-dashboard` 分支進行；前端 repo 另開同名分支；AI 不執行 push／merge
- [x] **Article XII**：`cms/` 唯讀；僅**參考並複製**其 UI 元件原始碼到新前端 repo，不修改 `cms/`、不以套件引用
- [x] **Article XIII**：`Owner` 為 `@evan`（一人），Layout = single，與本檔配置相符
- [x] **Article VIII**：spec／plan／tasks 與程式碼同步版控

---

## 1. 技術背景 (Technical Context)

### 1.1 技術棧選擇

> 原則：**沿用 `cms/apps/admin` 的架構與版本**（Next.js App Router＋shadcn/Radix＋Tailwind 3＋Jest），版本取自 `cms` 的 `pnpm-lock.yaml`（commit `0a0a5e2c`）並鎖定精確版本。差異有三處：單一 app 不採 monorepo；路由採 **Pages Router**（cms 為 App Router）；輸出模式為靜態匯出（見 ADR-002）。

| 層次 | 技術 | 版本 | 選擇原因 |
|------|------|------|---------|
| 前端框架 | Next.js（Pages Router，靜態匯出） | 14.2.28 | 與 cms 同版；Pages Router 靜態輸出無行內腳本（ADR-002） |
| UI 函式庫 | React / React DOM | 18.3.1 | 與 cms 相同 |
| 語言 | TypeScript（strict） | 5.6.3 | 與 cms 相同；Article II 強制型別 |
| 樣式 | Tailwind CSS | 3.4.17 | 與 cms 相同，複製的元件 class 免改寫 |
| UI 元件 | 複製自 `cms/apps/admin/src/components/ui`（shadcn 風格，Radix primitives） | 見第 8 節 | 對話框、下拉、開關、分頁籤、表格、輸入等皆已有成熟實作 |
| 資料驗證 | zod | 3.24.4 | 與 cms 相同；快照與本機儲存的邊界驗證（Article IV） |
| 單元／元件測試 | Jest（`next/jest`）+ Testing Library + jsdom | 29.7.0 / 14.3.1 | 與 cms 相同 |
| E2E／列印／無障礙 | Playwright + axe-core | 1.52.0 / 4.13.0 | Playwright 與 cms 同版；驗證 Chrome、列印 PDF、WCAG |
| 快照轉換 | Node CLI（csv-parse） | 7.0.2 | 將工作表匯出的 CSV 轉為快照 JSON，無需 Google 憑證 |
| 套件管理 | pnpm | 10.19.0 | 與 cms 相同 |
| 後端 | 本功能不涉及 | - | - |
| 資料庫 | 本功能不涉及 | - | - |
| CI/CD | GitHub Actions | - | lint、型別檢查、unit（含覆蓋率門檻）、E2E、建置 |

### 1.2 架構決策記錄 (ADR)

**ADR-001：新建爭鮮專用前端 repo 取代 `frontend` submodule，架構比照 cms**
- **狀態**: Accepted
- **背景**: 現有 `frontend` 指向 `kiitzu-theme-builder-web`（對外網站 starter，含 i18n、全站 Header/Footer、GA），不適合內部工具；且快照含爭鮮真實工作資料，不應進入 Kiitzu 共用 repo。
- **決策**: 使用 `git@github.com:Kiitzu/sushiexpress-pmo-tools-web.git`（已建立、目前為空），依 AGENTS.md「更換 Submodule」程序替換 `frontend/`，追蹤分支 `master`。
- **結果**: 前端 repo 只包含本產品。

**ADR-002：Next.js Pages Router＋靜態匯出，產物不含行內腳本**
- **狀態**: Accepted
- **背景**: 使用者要求**不使用行內腳本**。本工具要放進 BPM 的靜態網頁空間，cms 的 `standalone`（Node／Docker）不適用。2026-09-23 以 Next 14.2.28 實測 `output: 'export'`：App Router 輸出的 HTML 含 4 段可執行行內腳本（`self.__next_f.push`）；Pages Router 只有 1 段 `<script id="__NEXT_DATA__" type="application/json">` 資料區塊，瀏覽器不執行、CSP `script-src` 不管制，其餘皆為 `<script src>` 外部檔。
- **決策**: 採 Pages Router 與 `output: 'export'`，產出 `tracker.html`、`management.html`、`meeting.html`（`trailingSlash: false`）與 `_next/static/*`；互動在瀏覽器端進行，快照於建置時打包。`basePath` 以環境變數設定，對應 BPM 放置路徑。不使用 `next/script` 的 inline 寫法、`dangerouslySetInnerHTML`、行內事件處理屬性。
- **結果**:
  - 檔名與 PoC 相同，BPM 入口設定不變；CSP 風險大幅降低（R-1）。
  - CI 加入「產物無可執行行內腳本」檢查（掃描 `out/*.html`，除 `type="application/json"` 外，`<script>` 不得有內容），防止日後退化。
  - 與 cms 的差異僅在路由慣例（`src/pages/*` vs `src/app/*`）；元件、樣式、測試工具皆相同。

**ADR-003：UI 元件以「複製」方式取自 `cms`**
- **背景**: `cms` 為唯讀（Article XII）；`@kiibase/design` 為未發佈的 workspace 套件且元件不足。
- **決策**: 比照 cms 目錄結構（`src/components/ui`、`src/hooks`、`src/lib`；頁面放 `src/pages`），將 `button`、`dialog`、`select`、`switch`、`tabs`、`table`（含 `table.css`）、`input`、`textarea`、`badge`與 `cn` 工具複製過來，移除 `fullscreen-controller`、`@kiibase/i18n` 等 cms 專屬依賴，並以爭鮮主題 token 取代色彩。檔頭註明來源 commit（`cms@0a0a5e2c`）。
- **結果**: 不動 `cms/`；日後 cms 元件更新不會自動同步（可接受）。
- **實作調整（TASK-013、TASK-014）**:
  - cms 的 `use-local-storage` 未複製：會議紀錄的逐筆驗證與儲存失敗處理由 `src/lib/pmo/meetingStore.ts` 純函式負責，改寫為 `src/hooks/use-meeting-entries.ts`（掛載後讀取本機紀錄，FR-015、FR-016）。
  - `table.css` 改由 `src/pages/_app.tsx` 載入（Pages Router 不允許元件 import 全域 CSS）。
  - `text-default`、`icon-secondary` 改用 `achromatic-700`，Switch 未開啟狀態改深灰，以符合 WCAG AA／1.4.11；表頭加 `scope="col"`。
  - 複製的元件視同第三方程式碼，排除於覆蓋率統計，以 smoke test 驗證。

**ADR-004：快照於建置時打包，更新走「CSV → 快照 → 重建」**
- **背景**: spec 排除即時讀取 Sheets；FR-020 要求換快照不需改程式；Article IV 禁止在程式中放憑證。
- **決策**: 維運者從 Google Sheets 將四個分頁各下載為 CSV，執行 `snapshot:build` CLI 產生 `data/snapshot.json`（含擷取日期、spreadsheetId、各分頁 sheetId），建置時打包進頁面。CLI 與頁面共用同一份 schema 驗證。
- **結果**: 無需任何金鑰；更新資料需重新建置與部署（以 npm script 一鍵完成）。

**ADR-005：案件識別與會議本機紀錄的對應**
- **背景**: PoC 以「小組＋原表列號」為案件 ID；全部案件後，工作表插列會使列號位移，本機會議紀錄可能套到錯誤案件。
- **決策**: 案件 ID 維持 `{group}-row-{sourceRow}`；會議紀錄另存案件名稱指紋，載入時名稱不符即忽略該筆（與 FR-015「格式不符忽略」同一路徑）。本機儲存 key 採新版號 `sushi-pmo-meeting-v1`，不讀 PoC 舊 key。
- **結果**: 快照更新後不會錯置結論；列號變動的案件需重新標記。

**ADR-006：逐案呈報（FR-021）放在主管頁第三個分頁籤**
- **背景**: PoC 的逐案選取程式未啟用；spec 決定保留。
- **決策**: 主管頁分頁籤為「專案列表／工作列表／逐案呈報」，逐案呈報沿用案件追蹤頁的表格與篩選，加上選取欄與 A4 預覽（每頁 3 件）。
- **結果**: 案件追蹤頁維持一般同仁用途；PoC 既有兩個分頁籤行為不變。

**ADR-008：PoC 只作為版面與互動參考，不沿用其 CSS／JS**
- **狀態**: Accepted
- **背景**: PoC 三個 HTML 為打包後的單檔，含 Tailwind v4 產物與 Base UI 元件；使用者指示 HTML 只保留 layout 架構，CSS／JS 不必保留。
- **決策**: 以 PoC 的畫面結構、文案、欄位與互動行為為參考重新實作；視覺改用 cms 元件＋Tailwind 3 與爭鮮主題 token（主色 #E95529），不移植 PoC 的 CSS 或壓縮後程式。A4 報告的列印樣式依 NFR-005 重新撰寫。
- **結果**: 程式碼可維護、與 cms 一致；外觀細節可能與 PoC 截圖略有差異，以 spec 驗收標準為準。

**ADR-007：完成度與燈號取自原表；專案彙整狀態**
- **狀態**: Accepted（2026-09-23 修訂：原「完成度一律未提供」作廢）
- **背景**: 2026/09/16 試作 CSV 的 Project 分頁在 Note 之後多了 Progress（如 `90%`）與燈號（🟢 綠燈／🟡 黃燈）兩欄；使用者決定四個分頁都要有這兩欄。
- **決策**:
  - 快照每列固定 **15 欄**（原 13 欄＋Progress＋燈號），`schemaVersion` 升為 2。
  - Progress 解析為 0～100 的整數（接受 `90%` 或 `90`；小數如 `0.9` 與超出 0～100 者視為錯誤），空白為 null；燈號解析為 red／yellow／green／gray（接受「🔴 紅燈」等顯示文字或單純「紅燈」），空白為 gray。
  - 轉換 CLI 逐列驗證這兩欄，無法辨識或超出範圍時以分頁與列號報錯（spec SC-010）；頁面端 zod schema 再驗一次。
  - CSV 只有 13 欄（尚未補上兩欄）的分頁：兩欄視為空白並輸出警告，不中止，方便分頁陸續補欄。
  - 會議頁燈號：本機紀錄優先，否則用原表燈號；並標示來源（本機修改／原表）。
  - 專案彙整狀態維持固定「待確認」，篩選器保留（FR-010）。
- **結果**: 完成度與預設燈號反映工作表；會議本機修改仍不回寫。

## 2. 系統架構 (System Architecture)

### 2.1 元件圖

```
 Google Sheets（四分頁）
        │ 維運手動下載 CSV
        ▼
 ┌──────────────────────┐   zod 驗證   ┌──────────────────────┐
 │ scripts/snapshot CLI │────────────>│ data/snapshot.json    │
 └──────────────────────┘             └──────────┬───────────┘
                                                 │ 建置時打包
                                                 ▼
 ┌───────────────────────────────────────────────────────────────┐
 │ src/lib/pmo（純函式）                                         │
 │  toCases() · filterCases() · sortCases() · groupProjects()    │
 │  paginate() · meetingStore（localStorage 讀寫＋驗證）          │
 └───────────────┬───────────────────┬───────────────────┬───────┘
                 ▼                   ▼                   ▼
   pages/tracker.tsx     pages/management.tsx     pages/meeting.tsx
     → tracker.html        → management.html        → meeting.html
                 └──────── 共用：AppShell、CaseTable、CaseDetailDialog、
                           ProgressMeter、StatusBadge、ReportPaper、
                           TeamsNoticeDialog、AboutDialog、ui/*（複製自 cms）
```

### 2.2 執行流程 (Execution Flow)

```
1. 資料更新：CSV ×4 → snapshot CLI（驗證欄位、略過無案件名稱的列、保留原列號）→ snapshot.json → 建置
2. 建置：`next build`（export）時以 zod 驗證快照 → toCases() → 預先輸出三個靜態 HTML（僅外部腳本）；瀏覽器載入後 hydrate 為可互動頁面
3. 案件追蹤：搜尋／篩選／排序狀態存在頁面元件；結果由 filterCases → sortCases 推導
4. 主管頁：groupProjects(Case[]) → Project[]；呈報選取與順序存在元件狀態；預覽用 paginate(2)；列印時只顯示報告區
5. 逐案呈報：同 3 的表格加選取；預覽用 paginate(3)
6. 會議：meetingStore.load() 驗證每筆（燈號值、欄位型別、名稱指紋）→ 合併到 Case → 編輯儲存寫回；儲存失敗時保留在記憶體並提示
```

### 2.3 前後端範圍切分 (Frontend / Backend Scope)

**前端範圍（`frontend/`，新 repo）**

- 負責：三個入口頁的畫面與互動、搜尋／篩選／排序、專案彙整、A4 呈報預覽與列印樣式、拖曳與鍵盤排序、會議燈號本機儲存、快照 schema 與快照轉換 CLI、靜態建置產物
- 不負責：即時讀取或回寫 Google Sheets、跨電腦同步、BPM 登入與權限、發送 Teams 訊息、Teams 帳號對照、BPM 伺服器與 CSP 設定（由維運負責）
- 涉及頁面／元件：`tracker.html`、`management.html`、`meeting.html`；元件見 2.1
- 依賴的 API：無（僅依賴第 4 節的快照資料契約）

**後端範圍（`backend/`）**

- 本功能不涉及。
- 不負責：本功能全部需求皆為前端靜態頁面；未來若要即時讀取 Sheets 或回寫會議結論，另開新 spec。
- 涉及模組／服務：無
- 對外提供的 API：無

**交界與契約**

- 本功能沒有 API；唯一的資料交界是**快照 JSON 契約**（第 4 節、`contracts/snapshot.schema.json`），由快照 CLI 產生、頁面讀取，兩端共用同一份 schema。
- 依憲法 Article XII，`cms/` 不列入任何實作範圍；只複製其元件原始碼到新 repo。

## 3. 資料模型 (Data Model)

### 3.1 實體定義

```
Snapshot（快照，契約見第 4 節）
├── capturedAt: 日期字串 YYYY-MM-DD
├── spreadsheetId: 字串
└── sheets: Record<Group, { sheetId: 整數, headers: 字串[15], rows: SourceRow[] }>

SourceRow
├── sourceRow: 整數 ≥ 2（原表列號）
└── values: 字串[15]（S/N, Type, Project/Catalog, Description, BPM單號, Priority,
                      Raised by, Opened Date, Owned by, Due Date, LOG, Status, Note,
                      Progress, 燈號）

Case（由 SourceRow 推導，唯讀）
├── id: `${group}-row-${sourceRow}`
├── group: 'Frontend' | 'Project' | 'BPM' | 'SAP'
├── title, category, department, owner, status, due, bpmId, log: 字串（空值→「未提供」，bpmId/log 可空）
├── project: `${group}｜${Project/Catalog || '未分類'}`
├── latest: LOG 前三個非空行，或「原表尚無 LOG」
├── progress: number | null（原表 Progress，0～100；空白為 null）
├── sheetLight: 'red' | 'yellow' | 'green' | 'gray'（原表燈號；空白為 gray）
├── updated: string | null（本版一律 null）
├── sourceRow, sourceSheetId
└── sourceUrl: 指向原表 D{row}:M{row} 的連結

Project（由 Case 分組推導）
├── name: Case.project
├── phase: '待確認'（本版固定）
├── cases: Case[]
├── summary: 「案件名稱：最新進度」逐行串接
└── owners: 去重後的負責人，以「、」連接

MeetingEntry（本機儲存，每個 Case 至多一筆）
├── light: 'red' | 'yellow' | 'green' | 'gray'
├── risk, next, due: 字串
├── updated: YYYY-MM-DD
└── titleFingerprint: 案件名稱（ADR-005）

Relationships:
- Project has many Case（以 project 名稱分組）
- Case has zero or one MeetingEntry（以 id 對應，指紋不符則視為無）
```

### 3.2 資料庫 Schema

本功能不涉及資料庫。持久化僅有瀏覽器本機儲存：key `sushi-pmo-meeting-v1`，值為 `Record<CaseId, MeetingEntry>` 的 JSON。

## 4. API 合約 (API Contracts)

### 4.1 端點定義

本功能無 HTTP 端點。唯一契約為快照檔：

- 檔案：`data/snapshot.json`
- Schema：`specs/001-pmo-dashboard/contracts/snapshot.schema.json`（JSON Schema 2020-12）
- 產生者：`snapshot:build` CLI；讀取者：三個頁面
- 驗證失敗行為：CLI 以非零結束碼並列出錯誤列；頁面建置時的測試失敗即阻擋建置（不會產出壞資料的頁面）
- 版本：`schemaVersion: 2`（v2 新增 Progress 與燈號兩欄，每列 15 欄）；欄位新增須升版並同步更新 schema 與轉換函式

## 5. 測試策略 (Testing Strategy)

### 5.1 測試層次

| 層次 | 歸屬 | 工具 | 覆蓋目標 | 測試類型 |
|------|------|------|---------|---------|
| Unit | 前端 | Jest | 80%；domain 與 meetingStore 100% | 純函式、schema、CLI 轉換 |
| Component | 前端 | Jest + Testing Library | 三頁主要互動 | 篩選、排序、對話框、選取、鍵盤排序 |
| E2E | 前端 | Playwright（Chrome） | 主要使用者旅程＋列印 | 真實瀏覽器、PDF 輸出、axe 無障礙 |
| Unit／Integration | 後端 | - | - | 本功能不涉及 |

測試資料：測試不依賴真實資料。
- 單元／元件測試：`tests/fixtures/snapshot.sample.json`（由 `tests/fixtures/csv/*.csv` 以 CLI 產生，16 件，含 Progress／燈號樣本；SAP 分頁保留 13 欄以驗證缺欄警告）。
- E2E：以上述測試快照另建 `out-e2e/`（`pnpm build:e2e`，透過 `PMO_SNAPSHOT`／`PMO_OUT_DIR`），不使用 `data/snapshot.json`。
- 效能：500 件合成快照 `tests/fixtures/snapshot.500.json` 建置到 `out-perf/`（`pnpm build:perf`，`PMO_PERF=1 pnpm e2e:perf`）。
- 正式建置（`pnpm build` → `out/`）使用真實快照，只做「無行內腳本」檢查。
- a11y E2E 以 reduced motion 執行，避免 axe 在對話框淡入動畫途中量到半透明色。

### 5.2 測試場景對應

| 驗收場景 | 測試類型 | 測試檔案位置 |
|---------|---------|------------|
| SC-001 搜尋並查閱案件 | Component + E2E | `src/components/tracker/TrackerView.test.tsx`、`e2e/tracker.spec.ts` |
| SC-002 排序與缺值 | Unit | `src/lib/pmo/sortCases.test.ts` |
| SC-003 查無結果 | Component | `src/components/tracker/TrackerView.test.tsx` |
| SC-004 主管呈報與列印 | Component + E2E（PDF） | `src/components/management/ProjectReport.test.tsx`、`e2e/management-print.spec.ts` |
| SC-005 未選任何專案 | Component | `src/components/management/ManagementView.test.tsx` |
| SC-006 Teams 未設定 | Component | `src/components/shared/TeamsNoticeDialog.test.tsx` |
| SC-007 會議燈號編輯與保存 | Component + E2E（重新整理） | `src/components/meeting/MeetingView.test.tsx`、`e2e/meeting.spec.ts` |
| SC-008 本機儲存不可用 | Unit | `src/lib/pmo/meetingStore.test.ts` |
| SC-009 本機資料損毀 | Unit + E2E | `src/lib/pmo/meetingStore.test.ts`、`e2e/meeting.spec.ts` |
| FR-021 逐案呈報 | Component | `src/components/management/CaseReport.test.tsx` |
| FR-003／FR-020 快照轉換 | Unit | `scripts/snapshot/buildSnapshot.test.ts` |
| SC-010 原表完成度與燈號 | Unit + Component | `src/lib/pmo/sheetFields.test.ts`、`scripts/snapshot/buildSnapshot.test.ts`、`src/components/meeting/MeetingView.test.tsx` |
| NFR-001 500 件效能 | E2E | `e2e/performance.spec.ts` |
| NFR-002 無障礙 | E2E（axe） | `e2e/a11y.spec.ts` |

## 6. 安全考量 (Security Considerations)

- **認證／授權**：本版無（spec 範圍外）；存取控制依賴 BPM 展示空間。
- **輸入驗證**：快照在 CLI 與頁面兩端以 zod 驗證；本機儲存逐筆驗證，不符即忽略（FR-015）。
- **輸出安全**：所有文字（含 LOG、使用者輸入）一律以文字節點渲染，禁止插入 HTML；外部連結加 `rel="noreferrer"`。
- **資料外洩**：`data/snapshot.json` 含真實工作資料，新 repo 設為 private；CSV 原始檔列入 `.gitignore`，只提交轉換後快照。
- **憑證**：無任何金鑰；spreadsheetId 非憑證。
- **CSP**：產物不含可執行行內腳本與行內事件處理（ADR-002，CI 檢查）；只需允許同源 `script-src`／`style-src`。

## 7. 效能考量 (Performance Considerations)

- 以 500 件為設計上限：篩選排序為記憶化推導（`useMemo`），不做虛擬捲動；E2E 驗證輸入後 < 100ms 更新。
- 快照於建置時打包；三頁共用 chunk，單頁 JS gzip 目標 < 250KB（含 React 18 與 Next runtime）。

## 8. 依賴清單 (Dependencies)

### 新增依賴（新 repo，精確版本；除標註外皆與 cms lockfile 相同）

| 套件名稱 | 版本 | 用途 | 評估狀態 |
|---------|------|------|---------|
| next | 14.2.28 | 框架 | Approved |
| react / react-dom | 18.3.1 | UI | Approved |
| typescript | 5.6.3 | 型別 | Approved |
| @types/react / @types/react-dom / @types/node / @types/jest | 18.3.21 / 18.3.7 / 20.17.46 / 29.5.14 | 型別定義（dev） | Approved |
| tailwindcss / postcss / autoprefixer | 3.4.17 / 8.4.31 / 10.4.21 | 樣式 | Approved |
| tailwindcss-animate | 1.0.7 | 對話框動畫（cms 元件使用） | Approved |
| @radix-ui/react-dialog | 1.1.13 | 對話框 | Approved |
| @radix-ui/react-select | 2.2.4 | 下拉選單 | Approved |
| @radix-ui/react-switch | 1.2.4 | 呈報開關 | Approved |
| @radix-ui/react-tabs | 1.1.11 | 主管頁分頁籤 | Approved |
| @radix-ui/react-slot | 1.2.2 | 按鈕 asChild | Approved |
| class-variance-authority / clsx / tailwind-merge | 0.7.1 / 2.1.1 / 2.6.0 | 元件樣式變體 | Approved |
| lucide-react | 0.321.0 | 圖示 | Approved |
| zod | 3.24.4 | Schema 驗證 | Approved |
| csv-parse | 7.0.2 | 快照 CLI（dev；cms 無，新增） | Approved |
| tsx | 4.23.15 | 執行 TypeScript CLI（dev；新增） | Approved |
| jest / jest-environment-jsdom | 29.7.0 / 29.7.0 | 測試（dev） | Approved |
| @testing-library/react / @testing-library/jest-dom | 14.3.1 / 6.9.1 | 元件測試（dev） | Approved |
| @testing-library/user-event | 14.6.7 | 使用者互動模擬（dev；新增） | Approved |
| @playwright/test | 1.52.0 | E2E、列印 PDF（dev） | Approved |
| @axe-core/playwright | 4.13.0 | 無障礙檢查（dev；新增） | Approved |
| eslint / eslint-config-next | 8.57.1 / 14.2.28 | Lint，另加 `max-lines-per-function: 50`（dev） | Approved |
| prettier / prettier-plugin-tailwindcss | 3.5.3 / 0.5.7 | 格式（dev） | Approved |

### 現有依賴使用

| 套件名稱 | 用途 |
|---------|------|
| `cms/apps/admin/src/components/ui/*`（原始碼參考，commit `0a0a5e2c`） | 複製為本專案 UI 元件，不作為依賴 |

## 9. 部署考量 (Deployment Considerations)

- **環境變數**：`NEXT_PUBLIC_BASE_PATH`（BPM 放置路徑，比照 cms `config/env`）；無任何機密。
  - 僅供測試：`PMO_SNAPSHOT`（以其他快照取代 `data/snapshot.json`）、`PMO_OUT_DIR`（輸出目錄），由 `build:e2e`／`build:perf` 使用；webpack 快取版本依快照來源區隔，避免與正式建置互相污染。
- **資料庫遷移**：無；本機儲存 key 以版號區隔（`-v1`）。
- **產物**：`out/tracker.html`、`out/management.html`、`out/meeting.html`、`out/_next/static/*`，交給 Herbert 放入 BPM 靜態網頁空間並各自建立入口；`NEXT_PUBLIC_BASE_PATH` 設為放置路徑。
- **資料更新**：下載四分頁 CSV → `snapshot:build` → `build` → 交付 `out/`。
- **上線版本**：依 Article VI，合併至主分支時打 tag，並記錄 `frontend` submodule 對應 tag。
- **風險**：
  - **R-1 CSP／iframe**：產物已無可執行行內腳本（ADR-002），只需 BPM 允許載入同源外部 `.js`／`.css`；E2E 已在 `script-src 'self'` 的 CSP 下驗證。BPM 實測（TASK-004）依使用者 2026-09-23 決定略過，iframe 內能否列印仍未確認；若不能列印，需補「在新視窗開啟」連結。
  - **R-2 列號位移**：見 ADR-005。
  - **R-3 前端 repo**：已解決，`Kiitzu/sushiexpress-pmo-tools-web` 已建立（ADR-001）。

## 10. 實作階段 (Implementation Phases)

| 階段 | 內容 | 歸屬 | 預估複雜度 |
|------|------|------|-----------|
| Phase 0 | 以 `sushiexpress-pmo-tools-web` 替換 `frontend` submodule；比照 cms 建立 Next.js 14 Pages Router 骨架（TS strict、Tailwind、ESLint、Jest、Playwright、CI）、`output: export`、「無行內腳本」檢查；骨架頁交 BPM 實測（R-1，已略過） | 前端 | Low |
| Phase 1 | 快照契約：schema、CSV → 快照 CLI、以真實 CSV 產出首份全部案件快照（含測試） | 前端 | Medium |
| Phase 2 | Domain 純函式：toCases、filterCases、sortCases、groupProjects、paginate、meetingStore（含測試） | 前端 | Medium |
| Phase 3 | UI 基礎：複製並調整 cms 元件、爭鮮主題 token、AppShell、共用元件（含測試） | 前端 | Medium |
| Phase 4 | 案件追蹤頁（US-001、US-002、US-007） | 前端 | Medium |
| Phase 5 | 主管頁：專案列表、工作列表、Teams 說明、專案呈報拖曳排序與列印（US-003～US-005） | 前端 | High |
| Phase 6 | 主管頁：逐案呈報（FR-021） | 前端 | Medium |
| Phase 7 | 會議頁（US-006） | 前端 | Medium |
| Phase 8 | E2E、列印 PDF、無障礙、500 件效能、手機版面；部署文件 | 前端 | Medium |
| Phase 9 | 收斂：原表 Progress 與燈號兩欄（快照 v2、15 欄）、完成度與會議預設燈號取自原表（ADR-007 修訂） | 前端 | Medium |

---

## 計劃品質核對清單 (Plan Quality Checklist)

- [x] 所有憲法閘門已通過
- [x] 技術棧選擇有明確的理由
- [x] 資料模型涵蓋所有規格中的實體
- [x] API 合約對應所有功能需求（本功能無 API，以快照契約取代）
- [x] 測試場景對應所有驗收場景
- [x] 安全考量已識別所有威脅
- [x] 無低階程式碼（plan 只到架構層）
- [x] 前端與後端範圍已分開描述（2.3），雙方的「負責／不負責」都寫明
- [x] 每個實作階段都標註歸屬（前端／後端／兩者）
