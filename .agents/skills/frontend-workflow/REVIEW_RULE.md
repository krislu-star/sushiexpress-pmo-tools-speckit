# FSM Web — AI 前端驗收規則

> 本文件供 AI 在完成前端產出後，執行系統性驗收使用。
> 驗收順序：程式碼靜態審查 → 視覺像素比對 → 功能流程驗收。
> 每個 section 獨立可執行，可依需求選擇全跑或單跑。

---

## 0. 執行前：確認環境變數

開始任何驗收前，先確認以下資訊（不確定時詢問使用者）：

| 變數 | 說明 | 取得方式 |
|------|------|---------|
| `OURS_PORT` | 本次產出的 dev server port | 讀 `package.json` 的 `dev` script，解析 `-p <port>`；找不到則詢問使用者 |
| `REF_SOURCE` | 視覺比對的 ref 來源（見 Section 2.1） | 詢問使用者，選項：`server` / `figma` / `existing` |
| `REF_PORT` | 若 REF_SOURCE=server，prototype 工具產出的 server port | 詢問使用者；Vite 專案預設 `5173`（若被佔用自動遞增），其他工具依實際情況確認 |
| `SPEC_DIR` | features / use-cases md 檔所在目錄 | 詢問使用者，範例：`../unitech-e-fsm-pm/tracking/unitech-e-fsm-admin` |

---

## 0.1 Phase 3 開始前：Artifact 完整性確認（MANDATORY）

**Phase 3 驗收開始前，必須先確認以下 artifact 均已存在。任一缺失 → 補齊後才能繼續。**

```bash
# 確認截圖與報告存在
ls comparison/ours/ 2>&1       # ours 截圖（Section 2 中才產出，可先確認目錄存在）
ls comparison/diff/ 2>&1       # diff 圖（Section 2.5 才產出）
ls comparison/DEVIATION_REPORT.md 2>&1
```

| 項目 | 期望 | 缺失時的行動 |
|------|------|------------|
| `comparison/ref/` | **Section 2 中才截**（與 ours 同步進行），Phase 3 開始時不需存在 | — |
| `comparison/ours/` 有截圖 | 至少 1 個 .png | 補截圖（Section 2.3 流程）再繼續 |
| `comparison/DEVIATION_REPORT.md` 存在 | 檔案存在（可為空表格） | 立即建立，再繼續 |

> `comparison/ref/` 與 `comparison/diff/` 在 Section 2.5 才執行，Phase 3 開始時可以是空目錄或不存在，但 Section 2 結束前必須有每頁 ref 圖與 diff 圖。

---

## 1. 程式碼靜態審查

對照 `FRONTEND_RULE.md` 逐條掃描產出的程式碼，**不需要啟動 server**。

### 1.1 執行方式

依序檢查以下項目，每項回報 ✅ 通過 / ❌ 違規（附檔案路徑與行號）：

| 檢查項目 | 對應規則 |
|---------|---------|
| 有無 SVG path 字串直接搬入 | FRONTEND_RULE § 1.1 |
| 有無 inline style 魔術數字 | FRONTEND_RULE § 1.2 |
| 有無 hardcode 顏色值（hex / rgba） | FRONTEND_RULE § 1.3 |
| 有無 `<style>` 標籤注入 JSX | FRONTEND_RULE § 1.4 |
| 有無 module-level 可變 ID 產生器 | FRONTEND_RULE § 1.5 |
| 有無快速登入 / 測試後門 | FRONTEND_RULE § 1.6 |
| 有無敏感資訊經由 URL query string 傳遞 | FRONTEND_RULE § 1.7 |
| `page.tsx` 有無包含 UI JSX | FRONTEND_RULE § 2.1 |
| `middleware.ts` 是否存在且保護正確路由 | FRONTEND_RULE § 2.2 |
| 資料夾結構是否符合規定分層（執行 `find src/ -type f -name "*.tsx" \| sort`，確認無檔案落在 `components/`、`app/`、`lib/`、`types/`、`constants/` 以外） | FRONTEND_RULE § 2.3 |
| Zustand store 有無混入伺服器資料 | FRONTEND_RULE § 2.4 |
| 表單是否使用 React Hook Form + Zod | FRONTEND_RULE § 3 |
| API 請求是否使用 TanStack Query，且有 loading / error 狀態 | FRONTEND_RULE § 4 |
| 有無 `as any` | FRONTEND_RULE § 5.1 |
| 共用型別是否集中在 `src/types/` | FRONTEND_RULE § 5.2 |
| 有無重複語意欄位 | FRONTEND_RULE § 5.3 |
| 是否先執行 Section 6.1 token 萃取（constants 檔是否存在且有值） | FRONTEND_RULE § 6.1 |
| 顏色取用優先序是否正確 | FRONTEND_RULE § 6.2 |
| 日期是否使用 dayjs + 集中常數 | FRONTEND_RULE § 6.5 |
| 有無 prototype 殘留（setTimeout mock、hardcode 帳號等） | FRONTEND_RULE § 9 |
| `src/lib/utils/` 內每個函式是否有對應 `*.test.ts`，且執行 `npm test` 全數通過 | FRONTEND_RULE § 8.4 |
| 產出後重構 pass 是否執行（style / JSX / 邏輯函式重複檢查） | FRONTEND_RULE § 8 |
| prototype 元件類型是否有被替換（Table → Collapse 等） | FRONTEND_RULE § 10 |
| 視覺輸出是否與原型一致（component 可優化，但視覺不可改變） | FRONTEND_RULE § 2.6 |
| 所有 UI 文字是否與原型逐字一致（無縮寫、意譯） | FRONTEND_RULE § 2.7 |
| 有替換或功能性差異時，`comparison/DEVIATION_REPORT.md` 是否存在並記錄 | FRONTEND_RULE § 10.1 |
| 每個 Table 的欄位（columns）是否與 prototype 完全一致（不多也不少）；刻意新增或移除的欄位須有 DEVIATION_REPORT 記錄 | FRONTEND_RULE § 10 |
| 元件專屬樣式是否 local 到元件（依 ui_stack：module / utility / theme），未把 feature CSS 全塞 globals.css | FRONTEND_RULE § 5.0 |
| 每張表格是否包 `overflow-x:auto` 捲動容器（RWD mobile-safe）| FRONTEND_RULE § 2.5 |

### 1.2 輸出格式

```
## 靜態審查結果

✅ 通過：14 項
❌ 違規：2 項

### 違規明細

1. [FRONTEND_RULE § 1.3] hardcode 顏色值
   - src/components/dashboard/screens/UserList.tsx:42
     `style={{ color: '#00AEEF' }}`

2. [FRONTEND_RULE § 9] prototype 殘留
   - src/components/auth/screens/LoginPage.tsx:88
     `const handleQuickLogin = () => { onLogin('test@example.com'); };`
```

### 1.3 Section 1 Acceptance

靜態審查完成條件：

- [ ] §1.1 表格中所有 26 個項目均已逐一核對並回報 ✅/❌
- [ ] 所有 ❌ 違規已列出檔案路徑與行號
- [ ] `npx tsc --noEmit` 已執行，無 TypeScript 錯誤
- [ ] `npm test` 已執行，`src/lib/utils/` 測試全數通過

**機械性項目 grep 驗證（必須執行，空輸出 = ✅ 通過，有輸出 = ❌ 違規）：**

```bash
# §1.3 hardcode 顏色值（hex / rgba）
grep -rn --include="*.tsx" --include="*.ts" '#[0-9a-fA-F]\{3,6\}\|rgba(' src/components/ src/app/

# §1.4 <style> 標籤注入 JSX
grep -rn --include="*.tsx" '<style>' src/components/

# §1.6 快速登入 / 測試後門（DEV guard 外才算違規）
grep -rn --include="*.tsx" --include="*.ts" 'skipAuth' src/
# handleQuickLogin 本身不違規，但若出現在 import.meta.env.DEV 條件外則違規
# 手動確認：若 grep 找到 handleQuickLogin，檢查它是否被 {import.meta.env.DEV && ...} 包圍
grep -rn --include="*.tsx" 'handleQuickLogin' src/

# §1.7 敏感資訊經由 URL query string 傳遞
grep -rn --include="*.tsx" --include="*.ts" 'router.push.*email=\|router.push.*token=\|router.push.*password=' src/

# §9 prototype 殘留（setTimeout mock / hardcode 帳號）
grep -rn --include="*.tsx" --include="*.ts" 'setTimeout\|console\.log' src/components/ src/stores/
```

所有項目確認 → Section 1 完成，記錄違規數量，進入 Section 2。
有 ❌ 違規 → 進入 Phase 4 修正，修正後重跑 Section 1。

---

## 2. 視覺像素比對

截取每個頁面的截圖，與 ref 逐像素比對，產出差異報告。

### 2.1 選擇 ref 來源

執行前依照當前情況選擇其中一個來源：

| REF_SOURCE | 適用情境 | 操作 |
|-----------|---------|------|
| `server` | Prototype 工具產出的專案仍可啟動 | `cd <ref-project-dir> && npm run dev`（port 依工具而異，詢問使用者確認）|
| `figma` | 無法啟動 ref server，但有 Figma 設計檔 | 使用 Figma MCP `get_screenshot` 取得每個畫面截圖，存入 `comparison/ref/` |
| `existing` | `comparison/ref/` 已有截圖（重複驗收） | 直接使用現有截圖，跳過截圖步驟 |

### 2.2 截圖前：可存取性預檢（REF_SOURCE=server 時執行）

**先確認 ref server 仍在回應（跨 session 或長時間後可能已停止）：**

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:${REF_PORT}
```

回傳非 2xx → ref server 已停止，重新啟動：`cd <PROTOTYPE_DIR> && npm run dev -- --port <REF_PORT>`，再繼續。

截圖前先逐頁訪問 ref server 各路由，確認實際落點：

| 狀況 | 處理方式 |
|------|---------|
| 路由正確渲染目標頁面 | 正常截圖 |
| 路由被 redirect（如 SPA 不支援 deep link） | 於 REPORT.md 標記「⚠️ ref 截圖無效（deep link 不支援）」，該頁跳過像素比對 |
| 路由需要登入才能存取 | 先執行登入 flow（走完 auth 步驟），再截圖 |

### 2.3 截圖規格

- **視窗尺寸**：1440 × 900
- **截圖模式**：**全頁截圖**（`fullPage: true`）— 捲動超過 viewport 的內容必須一併納入，禁止只截 viewport
- **工具**：使用 Playwright（`fullPage: true`）；其他截圖工具需確認是否支援全頁截圖再使用
- **存放路徑**：
  - ref 截圖：`comparison/ref/<序號>-<畫面名稱>.png`
  - ours 截圖：`comparison/ours/<序號>-<畫面名稱>.png`
  - diff 截圖：`comparison/diff/<序號>-<畫面名稱>.png`
- **截圖時機**：頁面完全載入後（等待 network idle 或關鍵元素出現）

```js
// Playwright 截圖標準寫法
await page.screenshot({
  path: 'comparison/ours/07-CustomerDetailPage.png',
  fullPage: true,   // 必要：捲動全頁
});
```

### 2.4 互動狀態截圖

初始頁面截圖完成後，掃描 prototype 原始碼，確認是否有以下互動元件。有的話需**額外截一張觸發後的狀態**，與 ref 的對應狀態逐像素比對：

| 互動類型 | 觸發方式 | 截圖命名規則 |
|---------|---------|------------|
| **Drawer**（側滑面板） | 點擊對應觸發按鈕 / 連結 | `<序號>-<畫面名稱>-drawer.png` |
| **Modal**（對話框） | 點擊新增 / 編輯按鈕 | `<序號>-<畫面名稱>-modal.png` |
| **Tab 切換** | 點擊非預設的 Tab | `<序號>-<畫面名稱>-tab-<name>.png` |
| **展開面板**（Collapse / Accordion） | 展開第一個 Panel | `<序號>-<畫面名稱>-expanded.png` |
| **表單錯誤狀態** | 送出空白或不合法輸入 | `<序號>-<畫面名稱>-error.png` |

> 以 prototype 原始碼為準判斷是否存在該互動元件，不以 ours 產出為準（避免因元件替換造成漏驗）。

```js
// 以 Drawer 為例
await page.click('text=檢視');                          // 觸發互動
await page.waitForSelector('.ant-drawer-content');     // 等待出現
await page.screenshot({
  path: 'comparison/ours/08-StoreRegionPage-drawer.png',
  fullPage: true,
});
```

### 2.5 比對方式

ref 與 ours 截圖在同一個 session 中依序截取，然後執行 ImageMagick 比對：

```bash
# 安裝確認
which magick || which convert

# 單頁比對（回傳不同像素數）
magick compare -metric AE -fuzz 5% \
  comparison/ref/<N>-<name>.png \
  comparison/ours/<N>-<name>.png \
  comparison/diff/<N>-<name>.png 2>&1

# 差異率計算（fullPage 截圖高度不固定，需動態取得尺寸）
# W=$(magick identify -format "%w" comparison/ref/<N>-<name>.png)
# H=$(magick identify -format "%h" comparison/ref/<N>-<name>.png)
# 差異率 = 不同像素數 / (W × H) × 100
```

> **Section 2 gate — diff 檔是必要產出**：Section 2 的完成條件是 `comparison/diff/` 中存在每一頁對應的 diff 圖。僅憑目視截圖宣告通過（不產生 diff 檔）不算完成 Section 2，即使截圖看起來一致也不行。diff 檔缺失 = ImageMagick 未執行 = 視覺比對未完成。

### 2.5.1 模型看圖規則（Token 節省）

執行 ImageMagick 後，**只讀取差異數字**（像素數與差異率），不直接看 `ref/` 或 `ours/` 圖片。

| 差異率 | 模型動作 |
|-------|---------|
| 0–3% | 不看任何圖，直接記錄通過 |
| 3–10% | 裁切 diff 圖至差異區域，**只看裁切後的小圖** |
| > 10% | 看完整 `diff/` 圖（**不看** `ref/` 或 `ours/`），進入 Phase 4 auto-fix loop |

**差異區域裁切指令（3–10% 時執行）：**

```bash
# 取得 diff 圖中非零像素的 bounding box
BBOX=$(magick identify -format "%@" comparison/diff/<N>-<name>.png 2>/dev/null)
# 裁切並存為 crop 檔
magick comparison/diff/<N>-<name>.png -crop "$BBOX" +repage comparison/diff/<N>-<name>-crop.png
```

裁切後只讀 `*-crop.png`，說明紅色區域原因後即可記錄。

### 2.6 輸出格式

產出或更新 `comparison/REPORT.md`，格式參考：

```markdown
# Pixel-perfect 對照報告

**比對日期**：YYYY-MM-DD
**視窗尺寸**：1440 × 900
**比對方法**：ImageMagick `compare -metric AE -fuzz 5%`
**ref 來源**：<server:<REF_PORT> / figma-mcp / existing>
**ours**：localhost:<OURS_PORT>

## 逐頁數據

| # | 畫面 | 不同像素 | 差異率 | 主要原因 |
|---|------|--------:|------:|---------|
| 01 | AccountLoginPage | ... | ...% | ... |

## 差異來源分析
...

## 結論
```

### 2.7 驗收標準

| 差異率 | 判定 |
|-------|------|
| 0–3% | ✅ 通過（通常為字體 sub-pixel 或 dev overlay） |
| 3–10% | ⚠️ 留意（**必須**開啟 diff 圖，逐一說明每個紅色區域的原因，確認人眼可接受後方可留意通過） |
| > 10% | ❌ 需修正（結構或顏色有明顯差異） |

### 2.7.1 延後視覺細節的追蹤（deferred polish 紀律）

適用於 **3–10% ⚠️ 留意通過** 的頁面。若紅色區域是「與 ref 有真實視覺落差、但本次選擇不修」（padding / 對齊 / 間距 / 尺寸等細節），**不得只在 REPORT.md 解釋後放過**——必須同時把這筆落差登錄成可追蹤的延後項，否則本頁 §2 不算通過。

- **登錄位置**：`comparison/VISUAL_POLISH_BACKLOG.md`（首次有延後項時 just-in-time 建立；為最終視覺收斂 pass 的唯一來源，見 FRONTEND_RULE § 6）。**不寫進 `DEVIATION_REPORT.md`**——後者記「刻意的結構 / 功能偏離」，與「暫緩的視覺細節」語意不同，混寫會稀釋兩者。
- **每筆須含**：畫面 / 元素 / 觀察值 vs 期望值。範例：
  `- [ ] InventoryLedgerScreen · filter-bar：padding 12px，ref 為 16px`
- **哪些必須當場修、哪些可延後**：
  - **hygiene 違規（§ 1.2 inline 魔術數字 / § 1.3 hardcode 色）= 硬 gate，不得延後**。它是共用 token 的原料，越晚修範圍越炸；且 § 1 靜態審查未過本來就會擋下，不會走到這裡。
  - **systemic（共用 class / 間距 scale / token）**：適合延後到最後一次統一收斂（一次定義、全域套用，避免逐頁各自為政），**但仍須登錄**。
  - **local（單頁獨有、修正成本低）**：順手當場修，別囤。

### 2.8 Section 2 Acceptance

視覺比對完成條件：

- [ ] `comparison/ours/` 中有每頁初始狀態截圖（fullPage，1440×900）
- [ ] `comparison/ours/` 中有每個互動狀態截圖（Drawer / Modal / Tab / Error 等，依 prototype 原始碼為準）
- [ ] `comparison/diff/` 中有每頁對應的 ImageMagick diff 圖（缺圖 = 比對未執行 = Section 2 未完成）
- [ ] `comparison/REPORT.md` 中有每頁差異率數字（不同像素數 + 差異率 %）
- [ ] 差異率 3–10% 的頁面：已逐一說明每個紅色區域原因
- [ ] 差異率 3–10% 的頁面若含延後的真實視覺落差：已登錄為 `comparison/VISUAL_POLISH_BACKLOG.md` 追蹤項（§ 2.7.1）
- [ ] 差異率 > 10% 的頁面：已進入 Phase 4 auto-fix loop，或標記 ⚠️ 自動修正達上限需人工介入
- [ ] **RWD mobile-safe gate（FRONTEND_RULE § 2.5）**：每頁另截一張 375px 寬截圖，確認**無水平溢出**（表格在捲動容器內、多欄容器已收欄）；有溢出 = 未通過，需修

所有項目確認 → Section 2 完成，進入 Section 3。
有差異率 > 10% 未處理 → 進入 Phase 4，修正後重跑 Section 2。

---

## 3. 功能流程驗收

**重要：** 本 section 執行前，所有 BUILD task 的 AC（Acceptance Criteria）已包含「Browser smoke test」步驟。
此 section 的角色是**確認和二次驗證**，而非首次發現問題。

如發現新的功能缺陷 → 應回報為 BLOCKER 讓 BUILD subagent 修正，而非在此 section 修正。

依據 features（F-xxx）與 use-cases（UC-xxx）的規格逐項驗收，**需要啟動 ours dev server**。

### 3.1 spec 目錄位置

```
<SPEC_DIR>/
├── features/    F-001.md  F-002.md  ...   # Acceptance Criteria
└── use-cases/   UC-001.md UC-002.md ...   # 操作流程
```

### 3.2 驗收流程

每個 Feature（F-xxx）執行以下步驟：

**Step 1 — 讀取 F-xxx 的 Acceptance Criteria**

逐條核對，可靜態讀 code 判斷的先做，需要實際操作的進 Step 2。

**Step 2 — 執行相關 UC-xxx 的 Main Flow**

1. 確認 **Preconditions**（頁面狀態、登入狀態等）
2. 用 headless browser 逐步執行 **Main Flow**
3. 每步驟後確認畫面狀態符合預期
4. 完成後核對 **Postconditions**

**Step 3 — 執行 Alternate Flows**

依照 UC 中列出的 Alternate Flows，逐一測試異常路徑（錯誤訊息、邊界條件等）。

**Step 4 — 寫入路徑的重複觸發（每個寫入動作必做）**

Step 1–3 問的都是「**行為對不對**」——擋下了嗎、payload 形狀對不對、狀態怎麼轉、權限守得住嗎。
這一步問的是另一個維度：「**同一個動作被觸發兩次會怎樣？**」

> **為什麼要獨立成一步**：2026-08-02 REVIEW-084 的 §3 有 27 個驗收項、反向驗證 12 條全紅、
> 「新可達狀態」14 種組合全過——**仍然漏掉一個重複提交缺陷**（規格級提交鈕繞過 RHF 的
> `handleSubmit`，`formState.isSubmitting` 永遠 `false`，連點三次送出三張價格變更 request，
> 由 PR reviewer 抓到）。根因不是漏看某一行，而是**這個問法不在清單上**，所以 27 項全綠也擋不住。

逐一列出本次 Coverage 涵蓋的**每個寫入動作**（提交 / 儲存 / 重試 / 刪除 / 批次操作），各自確認：

| # | 檢查 | 判準 |
|---|---|---|
| 1 | 送出期間按鈕有 disabled 嗎 | 有可見的 loading 文案或 disabled 狀態，**涵蓋整段 async**（含成功後的重抓） |
| 2 | 這個 disabled 是**誰**驅動的 | ⚠️ `formState.isSubmitting` **只由 `handleSubmit` 驅動**。任何 `type="button"` + `onClick` 的提交路徑（表格式批次輸入很常見）**拿不到它**——那種地方必須有自己的 state |
| 3 | 同一 tick 內的連點擋得住嗎 | `disabled={state}` 要等 re-render 才生效，**第二次點擊比它早**。高風險寫入（金額 / 庫存 / 狀態轉移）要再加一個**同步的 `useRef` 旗標** |
| 4 | 失敗後會解鎖嗎 | 解鎖必須放 **`finally`**。若放在 try 尾端，任何 early return 的錯誤分支（409 / 403 就地處理）都會讓按鈕**永久鎖死** |
| 5 | 後端有去重嗎 | 有 `Idempotency-Key` → 重複送出只是 UX 瑕疵；**沒有 → 會真的建出兩筆**，嚴重度升級。沒有的話同時確認契約層是否該補（這是前端補不完的：UI 守衛擋不住重整、兩個分頁、超時重試） |

**測法**（兩層要分開測，否則會誤以為有覆蓋）：

```js
// 第 1 層：一般連點 —— `fireEvent` 每次事件後都會 flush act，
// 所以這一案測到的是「state 那層」。
fireEvent.click(btn); fireEvent.click(btn)
expect(submitFn).toHaveBeenCalledTimes(1)

// 第 2 層：同一 tick 內連點 —— 兩次 dispatch 包進**同一個 act**，state 還沒 flush，
// 第二次點擊看到的仍是 disabled=false → 只有同步的 ref 擋得住。
act(() => {
  btn.dispatchEvent(new MouseEvent('click', { bubbles: true }))
  btn.dispatchEvent(new MouseEvent('click', { bubbles: true }))
})
expect(submitFn).toHaveBeenCalledTimes(1)
```

> 讓 `submitFn` 回一個**未 resolve 的 promise**，否則第一次呼叫就結束了、視窗根本沒打開。
> 兩案要**分別**反向驗證：拿掉 state 只有第 1 案轉紅、拿掉 ref 只有第 2 案轉紅。
> 若拿掉任一層兩案都還綠，代表這兩案其實在測同一件事。
>
> 命名慣例：提交用 `submittingRef`、重試用 `retryingRef`；測試四案（一般連點 ×2、同 tick ×2）
> 放在與 screen 同名的 `.test.tsx`。

### 3.3 執行順序

依照 Feature 編號由小到大執行。有相依關係（如需先登入）時，先執行前置 UC。

### 3.4 輸出格式

```
## 功能流程驗收結果

### F-001 管理員使用 Microsoft 帳號登入 FSM 後台

Acceptance Criteria：
- [x] 應用程式啟動進入 AccountLoginPage，顯示 UNITECH Logo 與 "Sign in with Microsoft" 按鈕
- [x] 按 "Sign in with Microsoft" 切到 LoginPage 的 email 步驟
- [ ] ❌ consent 步驟按 "No" → 回到 email 步驟並清空 email/密碼欄位
      實際結果：按 "No" 後畫面停留在 consent 頁，未清空欄位

Use Cases：
- UC-001 首次登入（走完 OAuth + Consent）：✅ 通過
- UC-002 email 格式驗證失敗：✅ 通過
- UC-003 密碼長度不足驗證失敗：✅ 通過
- UC-004 consent 拒絕回到起點：❌ 失敗（同上）
```

### 3.5 驗收標準

- 所有 Acceptance Criteria 勾選完成 → ✅ Feature 通過
- 有任一未通過 → ⛔ **BLOCKER**：立即停止，回報給相關 BUILD subagent 修正
  - 清楚描述：[實際行為] vs [預期行為]
  - 不在此 section 修正；等待 BUILD subagent 修正後重新測試

### 3.6 Section 3 Acceptance

功能流程驗收完成條件：

- [ ] 所有 F-xxx Feature 均已執行 Step 1–4（AC 核對 + Main Flow + Alternate Flows + **重複觸發**）
- [ ] Coverage 涵蓋的**每個寫入動作**都已逐一過 Step 4 的 5 個檢查，並有兩層連點測試
- [ ] 每個 F-xxx 的所有 Acceptance Criteria 均已標記 `[x]` 通過或 `[ ] ❌`（含實際結果說明）
- [ ] 每個 UC-xxx 的 Main Flow 均已執行並回報 ✅/❌
- [ ] 所有 Alternate Flow 均已執行並回報 ✅/❌
- [ ] `comparison/REPORT.md` 的功能驗收摘要已更新

所有項目確認 → Section 3 完成，進入 Section 4。
有 ❌ / BLOCKER → 回報至 Phase 4，由對應 BUILD task 修正。

---

## 4. 驗收總結報告

三個 section 都執行完後，輸出一份總結：

```
# 驗收總結

**日期**：YYYY-MM-DD
**產出版本**：<git commit hash 或版本說明>

## 總覽

| Section | 結果 | 備註 |
|---------|------|------|
| 1. 程式碼靜態審查 | ✅ / ❌ | X 項違規 |
| 2. 視覺像素比對 | ✅ / ⚠️ / ❌ | 最高差異率 X% |
| 3. 功能流程驗收 | ✅ / ❌ | X 個 Feature 通過，Y 個失敗 |

## 待修清單

1. [程式碼] ...
2. [視覺] ...
3. [功能] ...

## 結論

> 是否達到可交付標準（三個 section 皆通過）
```

> **驗收完成後必須關閉所有為驗收啟動的 dev server**（ours 與 ref），避免佔用 port：
> ```bash
> # 查詢並關閉
> lsof -i :<OURS_PORT> -P -n | awk 'NR>1 {print $2}' | xargs kill
> lsof -i :<REF_PORT>  -P -n | awk 'NR>1 {print $2}' | xargs kill
> ```
