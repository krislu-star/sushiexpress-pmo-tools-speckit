# Frontend Common Rules

> 本文件包含**所有 framework profiles 通用**的實作規則。
> Framework-specific 規則（React/Vue/Angular 的狀態管理、路由、表單）請讀 `.agents/skills/<framework_profile>/SKILL.md`。
> 優先級：安全 > 架構正確 > 視覺還原 > 程式碼風格。

---

## 0. Prototype 視覺優先原則

Prototype 是唯一的視覺真相來源。

| Spec 條目類型 | 說明 | 處理方式 |
|---|---|---|
| **Behavioral** | prototype 看不出來的行為細節（驗證規則、錯誤訊息、API 格式） | ✅ 依 spec 實作 |
| **Additive** | spec 要求新增 prototype 沒有的功能欄位或互動 | ✅ 在 prototype 結構基礎上新增 |
| **Visual（衝突）** | spec 描述的頁面結構、元件選型與 prototype 不同 | ❌ 跟 prototype，並記錄至 `comparison/DEVIATION_REPORT.md` |

## 0.1 使用前：確認技術棧

開始任何實作前，先查看 `package.json` 確認 framework 與 UI 技術棧，再讀對應的 `.agents/skills/<framework_profile>/SKILL.md`。

> **`ui_stack` 必須在 prototype / spec 階段就定案並帶進 init，不要產到一半才決定或發現不符。** 原型用哪種 styling 範式（手寫 CSS / Tailwind+shadcn / 元件庫）決定 § 5.0 的落地機制；中途換範式 = 大阻力。init 後三者必須一致：`package.json` 相依 ↔ `_index.md` 的 `ui_stack` ↔ 實際 styling 範式。**反例**：宣稱 `tailwind-shadcn` 卻因 prototype 是手寫 scoped CSS、又缺轉換 recipe，最後整包抄進 `globals.css`（shadcn 從沒 init）→ 標籤名實不符、globals.css 養成數千行 monolith。

---

## 1. 禁止事項

### 1.1 禁止直接搬移 SVG path 字串

```
// ❌ 禁止 — Figma Make 產出的 SVG path 常數檔
// ✅ 正確 — 使用 UI 框架的 icon library（@ant-design/icons、lucide-react、@heroicons/vue 等）
// ✅ 或：放成靜態 SVG 檔於 public/，用 <img> 引用
```

### 1.2 禁止 inline style 魔術數字

```
// ❌ <div style={{ minHeight: 'calc(100vh - 64px)' }}>
// ✅ 從 src/constants/layout.ts 取常數，或使用 Tailwind spacing token
```

### 1.3 禁止 hardcode 顏色值

```
// ❌ style={{ color: '#00AEEF' }}  /  className="text-[#00AEEF]"
// ✅ 從 UI 框架 token 或 src/constants/colors.ts 取色
```

### 1.4 禁止將 CSS class 以 `<style>` 標籤注入元件

使用 CSS Module / utility class / 元件庫 theme（依 ui_stack），不用 `<style>` 標籤。放置策略見 § 5.0：元件專屬樣式一律 local 到元件、globals.css 只留 token / 共用 primitive。

### 1.5 禁止 module-level 可變狀態作為 ID 產生器

```ts
// ❌ let _counter = 0; function genId() { return ++_counter; }
// ✅ crypto.randomUUID() 或框架提供的 useId()
```

### 1.6 快速登入 / 測試後門

開發模式快速登入必須包在 `DEV` guard 內（Vite: `import.meta.env.DEV`；Next.js: `process.env.NODE_ENV === 'development'`）。禁止出現在正式分支。

### 1.7 禁止在 URL query string 中傳遞敏感資訊

透過 session / cookie 或 server action 傳遞，不走 URL。

---

## 2. 架構規則

### 2.1 資料夾結構原則（各 profile 有具體目錄名，概念通用）

- 路由層（`pages/`、`app/`、`router/`）：**薄層**，只讀取資料、處理導航、傳 props。
- 業務 UI 邏輯放在 `components/{feature}/screens/`。
- 共用小元件放在 `components/{feature}/ui/`。
- 版面元件放在 `components/{feature}/layout/` 或 `components/layout/`。
- Store：`src/stores/`（Zustand / Pinia 等）。
- 型別：`src/types/`（共用 TypeScript types）。
- API adapter：`src/lib/api/`。
- Mock data：`src/lib/mocks/`（串接 API 後刪除）。
- 工具函式：`src/lib/utils/`。
- 常數：`src/constants/`（colors, layout, typography, formats）。

禁止在 `components/` 子目錄放 mock data 或 store 定義。

### 2.2 Component Props 依賴前置檢查

實作任何 Screen 前，先確認依賴已存在：

| 依賴 | 必須先存在 |
|---|---|
| TypeScript 型別 | `src/types/<entity>.ts` |
| Mock 資料 | `src/lib/mocks/<entity>.ts` |
| API adapter | `src/lib/api/<entity>.ts` |

### 2.3 視覺輸出優先原則（元件選型）

元件實作可優化，但渲染結果必須與 prototype 視覺一致。更換元件類型需記錄至 `comparison/DEVIATION_REPORT.md`。

### 2.4 UI 文字字串逐字還原（CRITICAL）

所有可見 UI 文字（按鈕、標題、欄位標頭）必須與 prototype **逐字一致**，禁止縮寫、意譯、自行命名。

### 2.5 RWD / 響應式（mobile-safe · 所有畫面一致）

目標層級 = **mobile-safe**（桌機優先 + 縮到平板 OK + 手機不破版）。**非目標**：手機完整優化（表格改卡片式、逐頁為小螢幕重排）——admin 工具不做。每個畫面都要達到：

- **表格**一律包 `overflow-x: auto` 捲動容器（內層設 `min-width`），窄螢幕水平捲、不撐破頁面。
- **多欄容器**（`grid-template-columns: repeat(N, ...)`、summary 卡、KV grid、filter-bar）在 breakpoint 收欄。統一 breakpoint：**`640px`（手機）/ `900px`（平板）**。
- **layout shell**：sidebar 窄螢幕收合（drawer / 收合態），不擠壓主內容。
- **modal**：寬度 `min(<px>, calc(100vw - 32px))`，小螢幕留邊。
- **驗收**：375px 無水平溢出（REVIEW_RULE § 2 gate）。

**一致性要求**：禁止「有些畫面做 RWD、有些不做」——所有畫面同一標準。

---

## 3. API 請求規則

### 3.1 建立 API 用戶端（axios + humps）

```ts
// src/lib/api/client.ts
import axios from 'axios';
import { camelizeKeys, decamelizeKeys } from 'humps';

export const apiClient = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL ?? import.meta.env.VITE_API_URL,
  headers: { 'Content-Type': 'application/json' },
  timeout: 30000,
});

apiClient.interceptors.request.use(config => {
  if (config.data && !(config.data instanceof FormData)) {
    config.data = decamelizeKeys(config.data);
  }
  if (config.params) config.params = decamelizeKeys(config.params);
  return config;
});

apiClient.interceptors.response.use(response => {
  if (response.data) response.data = camelizeKeys(response.data);
  return response;
});
```

UI 型別一律 camelCase；adapter 不需手動 rename key。

### 3.2 Adapter Pattern

```ts
// src/lib/api/customers.ts
export async function fetchCustomers(): Promise<CustomerRecord[]> {
  // TODO: 串接真實 API 時替換下方 mock
  // const { data } = await apiClient.get<CustomerApiItem[]>('/customers');
  // return data.map(adaptCustomer);
  return MOCK_CUSTOMERS.map(adaptCustomer);
}
```

- 對外簽名永遠不變（UI 不感知 mock vs 真實 API）
- Mock data 放 `src/lib/mocks/`，不與 adapter 混寫
- Mock 也過 `adapt*` 函式

### 3.3 Loading / Error 狀態

每個 API 呼叫都要有 loading 和 error 狀態，不能靜默失敗。

---

## 4. TypeScript 規則

### 4.1 禁止 `as any`

完整定義型別，不使用 type assertion 繞過型別系統。

### 4.2 型別定義集中在 `src/types/`

跨元件共用的型別放 `src/types/*.ts`。禁止在多個檔案重複定義同一個 interface。

### 4.3 避免重複語意欄位

同一概念不同名稱並存（如 `assignee` + `assigneeId`）需明確選擇一個，migration 完後刪舊欄位。

---

## 5. 設計系統規則

開始寫任何元件前，必須先完成設計 token 萃取。

### 5.0 CSS 放置策略（所有 profile 通用 · CRITICAL）

**通用禁令**：🚫 禁止把各 feature 的 CSS class 一段段倒進單一 monolithic `globals.css`。這會養出數千行 monolith、成為 merge-conflict 磁鐵、無 scope 靠命名避撞、dead CSS 難清。

**通用原則**：元件**專屬**樣式一律 **local 到元件**（scope 化）；`globals.css` 只留 token（CSS custom properties）、CSS reset、跨多 feature 的共用 primitive（`.btn` base、`UiPill` / `UiModal` 等 shared 元件樣式）。動態值走 inline `style={{ color: 'var(--x)' }}`——只准 token 值（禁魔術數字 § 1.2、禁 hardcode 色 § 1.3）。

**「local」怎麼實現，依 `ui_stack` 範式而定**（styling 範式綁 stack，別硬套單一機制）：

| ui_stack | styling 範式 | 元件專屬樣式放哪 |
|---------|-------------|----------------|
| `none`（手寫 CSS）| 自己寫 class | **co-located `*.module.css`**，class 以 `styles.xxx` 引用（recipe 見 § 5.3）|
| `tailwind-shadcn` | Tailwind utility 寫在 JSX + shadcn cva | utility class 天生 local（跟著元件走、無獨立 CSS 檔）；共用 pattern 用 `@layer components`；**不手寫 per-feature class 進 globals** |
| 元件庫（antd / MUI 等）| 用庫 component + theme token | 靠 theme（ConfigProvider）客製；少量剩餘客製才 co-located（module 或庫的 styled API），不進 globals |

**判準速記**：「這段樣式只有這個元件用」→ local（依上表範式）；「全站都可能用」→ globals。

### 5.1 萃取原則

相近數值（色碼差 < 5% 或尺寸差 < 2px）收斂為單一 token，避免冗餘變數。

### 5.2 建立常數檔

```ts
// src/constants/colors.ts
export const COLOR_PRIMARY = '從設計稿取得';
export const COLOR_BG_PAGE = '從設計稿取得';

// src/constants/layout.ts
export const HEADER_HEIGHT = 0; // 從設計稿量取
export const SIDER_WIDTH = 0;

// src/constants/typography.ts — React/CSS-in-JS
export const TEXT_PAGE_TITLE: React.CSSProperties = { fontSize: 20, fontWeight: 500 };
// 或 Tailwind
export const TEXT_PAGE_TITLE = 'text-xl font-medium text-foreground';

// src/constants/formats.ts
export const DATE_FORMAT = 'YYYY-MM-DD';
export const DATETIME_FORMAT = 'YYYY-MM-DD HH:mm';
```

### 5.3 CSS Module 撰寫 recipe（`ui_stack = none` / 手寫 CSS 範式）

> 這是 § 5.0 表中「手寫 CSS」範式（`ui_stack = none`）的 co-located `*.module.css` 具體寫法。**`tailwind-shadcn`（utility-first）/ 元件庫（antd 等）範式不適用本節**——依 § 5.0 表用各自機制（utility class / theme token）。

prototype 的 CSS 直接移植，不替換成第三方元件。

**色彩與尺寸 token — 用 CSS custom properties 集中定義：**

```css
/* src/styles/tokens.css */
:root {
  --color-primary: /* 從 references/DESIGN.md 取 */;
  --color-bg-page: /* 從 references/DESIGN.md 取 */;
  --color-text: /* 從 references/DESIGN.md 取 */;
  --header-height: 64px;
  --sider-width: 240px;
}
```

在 `src/styles/globals.css` 最頂部 `@import './tokens.css'`。所有元件的 CSS Module 檔透過 `var(--color-primary)` 等引用，禁止 hardcode hex。

**元件結構規則：**

- prototype 的每個 `<div class="xxx">` 對應一個 CSS Module class，不強制換成 `<Button>` / `<Card>` 等元件庫 component。
- 把 prototype 的 CSS block 複製進對應的 `*.module.css`，再將 prototype HTML 結構轉成 JSX / Vue template，class 名改用 `styles.xxx` 引用。
- 若 prototype 用 `<style>` 標籤或 inline style 定義樣式，移入對應的 `*.module.css`；inline style 的 px 值若出現 3 次以上，抽進 `tokens.css`。
- 元件型別不替換（`<input>` 保持 `<input>`，不換 antd `<Input>`），但可包薄薄一層 wrapper component 加上 TypeScript props 型別。

### 5.4 日期處理

必須使用 **dayjs**，禁止手動拼接日期字串。格式集中定義於 `src/constants/formats.ts`。

---

## 6. 產出後重構 Pass

所有 screens 完成後執行一次重構掃描：

| 類型 | 觸發條件 | 抽出目標 |
|---|---|---|
| Style 物件 | 相同 `style={{ ... }}` 出現 3 次以上 | `src/constants/` 或 Tailwind config |
| JSX 片段 | 相同結構 JSX 出現 3 次以上 | `src/components/{feature}/ui/` |
| 邏輯函式 | 相同邏輯出現 2 次以上 | `src/lib/utils/` |

`src/lib/utils/` 的每個函式必須補對應 `*.test.ts`（Jest 或 Vitest）：happy path + edge cases。

此 pass 同時**清空 `comparison/VISUAL_POLISH_BACKLOG.md`** 中 review 階段登錄的延後視覺細節（見 REVIEW_RULE § 2.7.1）：**以該檔為唯一邊界**，逐筆修正並勾除——不是無邊界重掃全站。systemic 類（共用 class / 間距 scale / token）在此一次定義、全域套用。全部勾除後該 backlog 應為空。

---

## 7. 禁止殘留 Prototype 程式碼

以下不可存在於非 prototype 分支：

- `setTimeout` 模擬 API delay
- 繞過驗證的快速登入函式（無 DEV guard）
- hardcode 使用者帳號或操作人員名稱
- `console.log`（除 error boundary logging）

---

## 8. Prototype 產出處理

| Prototype 產出 | 處理方式 |
|---|---|
| SVG path 常數檔（`svgPaths*.ts`）| 找對應 icon library；找不到放 `public/` |
| Figma 整頁視覺元件（`imports/*.tsx`）| 先確認是否 active render；是則重建或記錄 DEVIATION |
| `style={{ ... }}` 魔術數字 | 抽進 `src/constants/` |
| hardcode 語系字串 | 集中到 `src/constants/labels.ts` |
| 絕對定位 | 評估改 flexbox/grid；只有裝飾性元素保留 |

### 8.1 偏差記錄

遇到以下偏差，必須在 `comparison/DEVIATION_REPORT.md` 記錄：
- 元件類型替換
- 功能性差異（新增 / 刪除 / 改動業務邏輯）
- Figma 整頁元件視覺縮減

---

## 9. 專案配置檔

### 9.1 `.gitignore`

使用 `profiles/<framework_profile>/templates/` 中的 Dockerfile 對應的 `.gitignore`，或參考本 template 根目錄的 `.gitignore`。

### 9.2 `.env.example`

必須存在，所有 env key 都要列出（值留空或填範例格式）。禁止在程式碼中 hardcode API domain。每新增一個 env 變數，同步更新 `.env.example`。
