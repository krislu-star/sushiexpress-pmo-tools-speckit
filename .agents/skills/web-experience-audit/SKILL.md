---
name: web-experience-audit
description: 用 Playwright 爬取並走訪一個網站，產出 sitemap、頁面模板、區塊解剖、使用者旅途、站台能力清單與機會缺口的稽核報告，同時輸出機器可讀的 pages.json 供後續模板配對與改版前後比對使用。Use this skill whenever the user wants to analyze, audit, teardown, benchmark, or understand an existing website — including 網站分析、網站健檢、競品分析、競業研究、資訊架構盤點、UX 稽核、改版前現況調查、sitemap 整理、user journey 梳理、版型／模板適配評估 — even if they don't mention Playwright or a report by name. Also trigger when the user pastes a URL and asks 幫我看一下這個網站 / 這個網站在講什麼 / 整理一下他們的結構跟文案 / 這個客戶適合套哪個版型.
---

# Web Experience Audit

把一個線上網站，變成兩份東西：一份給人看的稽核報告，一份給機器用的結構化資料。

## 核心紀律

**事實與判斷分層。** 爬到的東西進 `pages.json`，你的標籤與評價進 `analysis.json`。兩者分開，是因為下游要靠事實層做改版前後 diff 與跨站比較——判斷混進去，判準一改動整份資料就對不起來。

**證據可追溯。** 報告裡每個結論都要能指回 URL 或截圖（selector 這類技術證據留機器層，別寫進報告正文）。沒抓到的東西標記為「未涵蓋」，不要用「看起來應該有」補足。

**不編造數字。** 絕對不出現「約 78% 的同類網站」「業界標準是」這類量化措辭，除非數字真的來自實際累積的稽核資料。要講理由，不要假統計——一旦客戶追問來源，整份報告的可信度會一起崩掉。

**報告是給客戶看的交付物，不是工作底稿。** 驗證過程——抽樣了哪些代表頁、每頁切出幾塊、幾何數值、selector——留在 `pages.json`／`analysis.json` 機器層，**不寫進 `report.html`**。客戶要看的是「網站現況＋判斷＋建議」，不是稽核怎麼做出來的。方法與可追溯性壓縮進報告最後的「方法與限制」一段帶過即可。別為了展示工作量把覆蓋率、抽樣清單、區塊統計搬進正文——那只會讓客戶失焦、看不懂。

**但「精簡」精簡的是方法與過程，不是實質內容。** 這條紀律最容易被反向誤用成「把報告寫薄」——把缺口清單砍到只剩幾條、把逐塊 TYPE 配對縮成一句總結、把關鍵商業數字（方案價格、費率、售價、方案名）省略不抄。這些**不是**工作底稿，是交付物的核心價值。界線很清楚：**該壓縮的是「怎麼做的」（抽樣、幾何、selector）；該完整的是「看到什麼、缺什麼、原文怎麼寫」**——缺口比對 expectations 要逐項寫完（含「已有」與「不需要」），關鍵商業數字要照抄原文（`$29/mo`、`Interchange + 0.09%` 這類），模板配對要逐塊配。精簡到讓客戶失焦是錯，精簡到讓報告變單薄、資訊量輸給上一版也是錯。

---

## Phase 0：確認範圍

動手前先確認這幾項。缺的用一次提問補齊，不要一題一題問。

| 項目 | 沒說時的預設 |
|---|---|
| 目標網址與語系 | 使用者給的 URL，只爬同 origin + 同語系 |
| **網站類型** | 需問，見下方 |
| **主要轉換目標** | 需問（詢價 / 捐款 / 購買 / 註冊 / 報名 / 內容閱讀） |
| 覆蓋範圍 | 抽樣至「每模板有 2–3 代表 ＋ 所有列表頁完整計數」為止，**無硬性頁數上限**（見 Phase 2 的抽樣驅動與安全閥） |
| 稽核目的 | 改版前現況盤點 |
| 是否需登入 | 否。需要時由使用者提供並確認授權，不嘗試繞過驗證 |

網站類型是必問的，因為 Phase 7 的缺口判斷完全依賴它。可選：`品牌官網` / `服務型` / `電商` / `非營利` / `媒體內容` / `SaaS`。

稽核目的會改變報告重心：改版前盤點看模板數量與可重用區塊；競品分析看文案策略與 CTA 密度；轉換診斷看旅途摩擦點；模板配對看容量、量體、素材與硬性門檻。

### 取用規範

只爬公開頁面，遵守 `robots.txt` 的 `Disallow`，請求間隔至少 1 秒。表單可**填入測試值以觀察即時驗證行為**（必填提示、inline error、格式檢查），但**不按下會產生副作用的最終動作**（送出、付款、註冊、留言）——走旅途走到那一步就停下來截圖。這會寫進報告的方法章節，讓客戶知道稽核是怎麼做出來的。

---

## Phase 1：環境與輸出結構

```bash
pip install playwright --break-system-packages -q && playwright install chromium
```

若安裝失敗，改用靜態抓取，並在報告限制章節明確標註「未執行 JS，SPA 內容可能缺漏」。不要假裝有跑瀏覽器。

```
audit/
├── data/pages.json       # 事實層：可重跑、可 diff
├── data/analysis.json    # 判斷層：標籤、旅途、缺口
├── data/traces/          # 機器層：每條實走旅途一個 trace zip（見 Phase 6）
├── shots/                # 截圖 desktop 1440 / mobile 390
└── report.html           # 單檔交付物
```

---

## Phase 2：頁面發現

依序嘗試，找到就停：`{origin}/robots.txt` 的 `Sitemap:` 指向 → `/sitemap.xml`（可能是 index，要展開）→ 從首頁同源 BFS，深度上限 3。

過濾：非同源、`#` 錨點、`mailto:`/`tel:`、檔案下載。正規化時移除 `utm_*`、`fbclid`、`gclid` 再去重。

**內頁抽樣，列表頁完整計數。** 同模板的內頁（`/case/123`）各留 2–3 個代表即可。但列表頁本身要準確記錄項目總數——「服務有幾項、案例有幾則」是下游容量判斷的直接輸入，抽樣會讓那個判斷失效。

**覆蓋由抽樣規則決定，不設固定頁數上限。** 爬到「每個模板都有 2–3 個代表、且所有列表頁都完整計數」就停——這支 skill 的覆蓋是**以模板為單位**，同模板內頁全爬只會產出流水帳、讓 `pages.json` 爆炸，不增加報告價值。兩個不受此限的例外：

- **列表頁的項目完整計數永遠不受任何上限影響**——它是容量判斷的直接輸入，一律數準。
- **安全閥（非覆蓋截斷）**：實際抓取頁數若超過 **200**，不要靜默停止；記錄「已達安全上限，剩餘同模板內頁未全抓」進報告「方法與限制」章節，並確認每個模板與所有列表頁都已涵蓋（符合「不靜默截斷、未涵蓋要標記」的紀律）。若使用者另有指定上限，以使用者的為準。

順便記錄**孤兒頁面**：在 sitemap 內但沒有任何內部連結指向的頁面。這些常是客戶自己忘記的舊活動頁，範圍界定時很好用。

---

## Phase 3：逐頁抓取（事實層）

每頁都要先滾到底再抓——大量網站下半部是 lazy load，不滾動只會拿到空殼。

### 3.0 網路證據（掛在 goto 之前）

跟 Phase 4 能力盤點同一個紀律：**先全記，後歸納，清單只當 backstop。** 不要只記「認得的服務」——把所有第三方請求按網域記下來，爬完再歸納這個網站接了什麼。技術棧偵測光靠 HTML 特徵會漏掉動態載入的第三方服務與 API，實際錄請求才把偵測從「猜」升級成「觀察到」。

每頁 `goto` 前掛監聽，事實進 `pages.json`：

```python
from urllib.parse import urlparse

def make_network_logger(page_record, site_origin):
    def on_request(request):
        url = request.url
        host = urlparse(url).netloc
        # 1) 第三方網域：全記，按網域聚合，只留一個範例 URL（去 query string）
        if not host.endswith(urlparse(site_origin).netloc):
            page_record.setdefault('third_party_domains', {})
            if host not in page_record['third_party_domains']:
                page_record['third_party_domains'][host] = {
                    'example_url': url.split('?')[0], 'resource_types': [],
                }
            rt = request.resource_type
            rts = page_record['third_party_domains'][host]['resource_types']
            if rt not in rts:
                rts.append(rt)
        # 2) API 呼叫（同源或第三方都記）
        if request.resource_type in ('xhr', 'fetch'):
            page_record.setdefault('api_calls', []).append({
                'method': request.method,
                'url': url.split('?')[0],   # 一律去除 query string，避免記到追蹤識別碼
            })
    return on_request

page.on('request', make_network_logger(record, ORIGIN))
# 換頁前務必 page.remove_listener('request', ...) 或每頁開新 page，
# 否則請求會記到錯的頁面上，證據鏈錯亂。
```

`third_party_domains`（按網域聚合、去重、URL 去 query string）與 `api_calls` 兩個欄位進事實層。歸納與報告規則見 Phase 4。

### 3.1 區塊切點

不要用 class 名稱找區塊。`[class*=section]` 在 Tailwind 或 CSS Modules 的站台上完全撈不到，而那類站台佔比很高。改用**幾何判斷**，因為它跟人眼看到的一致。

規則：從內容根節點往下鑽，沿途遇到單一子節點就繼續（那是包裝層），遇到**兩個以上接近容器寬度、垂直堆疊的子節點**就在該層切開。

```js
function segmentBlocks(root) {
  const R = e => e.getBoundingClientRect();
  const vis = e => { const r = R(e); return r.height > 40 && r.width > 0
    && getComputedStyle(e).display !== 'none' && (e.innerText || '').trim().length > 0
    && !e.closest('[data-audit-shell]'); };   // 排除已標記的固定外殼
  let node = root;
  for (let depth = 0; depth < 12; depth++) {
    const kids = [...node.children].filter(vis);
    if (!kids.length) break;
    const wide = kids.filter(k => R(k).width > R(node).width * 0.7);
    if (wide.length >= 2) return wide;
    node = wide[0] || kids[0];
  }
  return [node];
}
// 切分前先按語意角色剝掉固定外殼，剩下的才交給幾何切分——剝橘子先去皮，再分瓣。
// 沒有 <main> 時退到 body 會把頁首/頁尾/側欄混進內容塊，污染切分。
function contentRoot() {
  const main = document.querySelector('main, [role=main]');
  if (main) return main;
  document.querySelectorAll(
    'header, [role=banner], nav, [role=navigation], footer, [role=contentinfo], aside, [role=complementary]'
  ).forEach(e => e.dataset.auditShell = '1');   // 標記外殼，vis() 會排除
  return document.body;
}
const root = contentRoot();

// 剝下來的外殼「不進內容幾何切分」，但仍要各自成為一個區塊，
// 供 Phase 5 標 nav-header / footer——否則這兩個標籤會消失（無論有無 <main> 都適用）。
function shellBlocks() {
  return [...document.querySelectorAll(
    'header, [role=banner], nav, [role=navigation], footer, [role=contentinfo]'
  )].filter(e => (e.innerText || '').trim().length > 0);
}
// 最終區塊清單 = 內容區塊 segmentBlocks(root) ＋ 外殼區塊 shellBlocks()（後者直接標 nav-header/footer）
```

**驗收：一個典型行銷頁應切出 5–15 個區塊。** 切出 2 個代表停太淺（整頁被當一塊），切出 40 個代表鑽太深（把卡片當區塊）。落在範圍外就換一層重切——往上取 `node.parentElement`，或對最高的那個區塊再切一次。這條規則很土，但抓得到絕大多數失敗案例。

**順手加抓的品質訊號**（進 `pages.json`，與既有 `has_alt` 並列）：

```js
quality_signals: {
  unlabeled_buttons: [...document.querySelectorAll('button,[role=button]')]
    .filter(b => !(b.innerText || '').trim() && !b.getAttribute('aria-label')).length,
  heading_skips: null   // h1→h3 這類跳級，可從 outline 序列檢查，未做時留 null
}
```

邊界維持「刻意不做的」不變：這些**只進「素材品質訊號」，不宣稱做了無障礙檢測**。

### 3.2 每個區塊要抓的欄位

```js
const txt = e => e ? (e.innerText || '').trim().replace(/\s+/g, ' ') : '';
const sig = e => e.tagName + '.' + [...e.classList].slice(0, 2).join('.');

function repeatUnit(block) {
  let best = null;
  for (const p of [block, ...block.querySelectorAll('*')]) {
    const kids = [...p.children];
    if (kids.length < 3) continue;
    const groups = {};
    kids.forEach(k => (groups[sig(k)] ||= []).push(k));
    for (const items of Object.values(groups))
      if (items.length >= 3 && (!best || items.length > best.length)) best = items;
  }
  if (!best) return null;
  const tops = best.map(e => Math.round(e.getBoundingClientRect().top / 10));
  const titles = best.map(e => txt(e.querySelector('h2,h3,h4,strong')));
  return {
    item_count: best.length,
    columns: tops.filter(t => t === tops[0]).length,
    fields: [
      best[0].querySelector('img,svg,video') && 'image',
      titles[0] && 'title',
      txt(best[0]).length > (titles[0] || '').length + 10 && 'excerpt',
      best[0].querySelector('a') && 'link'
    ].filter(Boolean),
    avg_title_length: Math.round(titles.reduce((s, t) => s + t.length, 0) / best.length),
    avg_text_length: Math.round(best.reduce((s, e) => s + txt(e).length, 0) / best.length)
  };
}

// TYPE_9 訊號：有底色的「色塊/文字卡」壓在內容圖上、遮掉一部分（≠TYPE_2 的完整圖）。
// 這是 TYPE_9 vs TYPE_2 唯一可測的結構訊號——判準不是長寬比，是「圖需不需要完整」。
function colorBlockOverlap(block) {
  const rect = e => e.getBoundingClientRect();
  const imgs = [...block.querySelectorAll('img')].filter(im => {
    const r = rect(im); return r.width > 200 && r.height > 100; // 真內容圖，濾掉 icon/logo
  });
  if (!imgs.length) return { over_image: false };
  const solidBg = e => {
    const s = getComputedStyle(e), bg = s.backgroundColor;
    return s.backgroundImage === 'none' && bg && bg !== 'transparent'
      && !/rgba\(0, 0, 0, 0\)/.test(bg); // 有實心底色（非透明）
  };
  const inter = (a, b) => Math.max(0, Math.min(a.right, b.right) - Math.max(a.left, b.left))
    * Math.max(0, Math.min(a.bottom, b.bottom) - Math.max(a.top, b.top));
  for (const im of imgs) {
    const ir = rect(im), iarea = ir.width * ir.height;
    for (const e of block.querySelectorAll('*')) {
      if (e === im || e.contains(im) || !solidBg(e)) continue;
      if ((e.innerText || '').trim().length < 10) continue; // 色塊要承載文字卡
      const cov = inter(ir, rect(e)) / iarea;
      if (cov >= 0.15) return { over_image: true, coverage: +cov.toFixed(2) };
    }
  }
  return { over_image: false };
}

function blockData(b, i) {
  const r = b.getBoundingClientRect();
  const h = b.querySelector('h1,h2,h3');
  return {
    index: i,
    geometry: { height: Math.round(r.height), full_bleed: r.width > innerWidth * 0.95 },
    copy: {
      heading: txt(h),
      heading_length: txt(h).length,
      body: txt(b).slice(0, 1500),
      body_length: txt(b).length,
      ctas: [...b.querySelectorAll('a[class*=btn],a[class*=button],button,[role=button]')]
        .map(e => ({ text: txt(e), href: e.href || null })).filter(c => c.text)
    },
    repeat_unit: repeatUnit(b),
    color_block_overlap: colorBlockOverlap(b),
    media: [...b.querySelectorAll('img')].map(im => ({
      type: 'img', src: im.currentSrc || im.src,
      natural: [im.naturalWidth, im.naturalHeight],
      ratio: +(im.naturalWidth / (im.naturalHeight || 1)).toFixed(2),
      has_alt: !!im.alt
    })).concat([...b.querySelectorAll('video,iframe')].map(v => ({ type: v.tagName.toLowerCase(), src: v.src }))),
    evidence: { selector: b.tagName.toLowerCase() + ':nth-child(' + (i + 1) + ')' }
  };
}
```

三個欄位是為了下游配對而抓，缺一不可：

- **`repeat_unit.item_count`** — 沒有這個就答不出「服務列表裡有 14 張卡」，容量比對做不了。這是第一版最大的漏洞。
- **`copy.heading_length` 分欄位計算** — 模板的版位限制是按欄位設的（主標 15 字上限），所以量體也要按欄位量。區塊總字數沒有意義。
- **`media.natural`** — 「模板要 2400px 滿版主視覺、客戶手上最大 900px」這種問題必須提早發現，否則會在交付前爆炸。

**要做模板配對（第 8 章「選配」）就再抓一組「結構簽章」——因為 TYPE 判定完全靠它，不能靠標題語意猜。** 每區塊加抓：`repeat_unit.columns`（第一列 item 數＝真實欄數，決定 TYPE_2 單圖文 vs TYPE_3 並列卡）、**媒體型別分流**（前景內容影片／背景影片 vide.js／地圖／reCAPTCHA 各自分開計，只有前景影片觸發 TYPE_2 影片閘）、`bg_image`（圖是否滿版/背景，決定 TYPE_6 vs TYPE_2）、**`color_block_overlap`**（有底色色塊壓在內容圖上、遮掉 ≥15%＝TYPE_9 訊號；判準是「圖需不需要完整」不是長寬比）、`is_form`（≥3 個非隱藏輸入＋送出鈕，抓非語意 `<form>` 的內嵌表單→TYPE_13）、**每項圖的份量**（`圖佔卡面積比`、渲染圖尺寸、是否僅 SVG/字型 icon＝圖不重要→TYPE_5 vs 圖為主→TYPE_3）、CTA 數。判定規則見第 8 章 rubric。事實層抓準，判斷層才判得對——這就是「事實與判斷分層」在配對上的體現。

### 3.3 頁面層級

`url` / `title` / `meta` / `lang` / `outline`（h1–h3 序列）/ `nav` / `forms`（含欄位名稱）/ `links_internal`。

每頁存兩張全頁截圖：desktop `1440x900`、mobile `390x844`。截圖是報告可信度的來源，也是給設計師看配置用的，不要省。很多摩擦點只在 390px 下才會出現。

---

## Phase 4：站台能力（網站的商業邏輯）

站台能力就是**這個網站的商業邏輯**——它靠什麼運作、能對使用者做什麼（金流、預約、會員、訂閱、推薦計畫、經銷入口……）。結果放在 `pages.json` 的 `site_capabilities`，並在報告獨立成段，因為它同時是**給客戶看的商業邏輯**與**下游模板配對的篩選器**（缺金流的模板不該靠其他項目拿高分，所以不能混進區塊清單被平均掉）。

**做法是歸納，不是拿清單打勾。** 先把頁面爬完（Phase 2–3），再**由下而上**從實際觀察到的東西歸納這個網站能做什麼——**不要**拿一張固定清單逐項檢查「有沒有這個功能」，那會把你錨定在清單上、漏掉這個網站真正的商業邏輯（referral 計畫、reseller portal、預約引擎這類清單外能力就是這樣消失的）。每一項能力記成：**白話名稱 + 支撐證據**（在哪一頁、什麼元素／路徑／文案／iframe／HTTP 或技術訊號）。

**事後才用常見能力表做完整性回顧（是 backstop，不是偵測起點）。** 歸納完之後，拿下表掃一遍「有沒有漏掉常見的」；有就補、確認沒有也值得寫「無」。順序是**先歸納，再對照**，不是反過來。

| 常見能力（提示用，非窮舉、非封閉清單） | 常見訊號 |
|---|---|
| 多語系 | `link[hreflang]`、語系切換連結、URL 語系前綴 |
| 會員登入 | 登入連結、`input[type=password]` |
| 金流購物車 | 購物車圖示、`/cart` `/checkout` 路徑、價格格式 |
| 搜尋 | `input[type=search]`、搜尋結果頁 |
| 篩選排序 | 列表頁的 `select` 或勾選控制項 |
| 表單類型 | 依欄位組成判斷：聯絡 / 訂閱 / 報名 / 詢價 / 捐款 |
| 第三方嵌入 | 地圖、YouTube、Calendly、外掛表單 iframe |
| 技術棧 | `meta[name=generator]`、`wp-content` 路徑、HTTP header、framework 特徵 |

**清單外但這個網站有的能力，照 Phase 5 對待 `other` 的方式照實記下來**（白話名＋證據），別因為不在表上就丟掉。反覆在多次稽核出現的新能力，再沉澱進這張表——介面不變（同 Phase 7「判斷升級為統計」的思路）。

**Phase 3.0 收集的 `third_party_domains` 是新的證據來源**，跟頁面元素、路徑、文案並列一起由下而上歸納。歸納完之後，才拿下表做完整性回顧（backstop，不是偵測起點——順序與上面能力表相同）。這張網域表與上面的常見能力表是**互補**關係：一張看**網域**、一張看**能力**，不是要對兩次清單；金流這類會同時出現在兩張表，以能力表的結論為準、網域表只補證據等級。

| 網域特徵（提示用，非窮舉） | 常見對應 |
|---|---|
| googletagmanager / google-analytics | GTM / GA4 |
| connect.facebook.net | Meta Pixel |
| clarity.ms / hotjar | 行為錄影工具 |
| shoplineapp / cdn.shopify | 電商平台 |
| stripe / tappaysdk / 藍新 newebpay | 金流 |
| recaptcha | 機器人驗證 |
| calendly | 預約 |

清單外的第三方網域照上面「對待清單外能力」的方式處理：白話名＋證據照實記，反覆出現的再沉澱進表，介面不變。

**報告端規則：**
- 第 4 章技術棧與第三方服務，每項標注證據等級：「有網路請求證據」或「僅 HTML 特徵推測」（例：「GA4（本站實際載入 google-analytics 請求）」）。
- `api_calls` 非空且頁面初載 `blocks` 稀疏 → 方法章節註明「前端動態載入內容，已等待網路閒置後擷取」。
- API 網域與主站不同源 → 能力記為「內容/資料由外部服務供應」，列網域即可、不猜廠商版本。

技術棧影響內容搬遷難度——WordPress 有匯出路徑，自幹 CMS 沒有，這是報價差很多的變數。

---

## Phase 5：區塊分類（判斷層）

以下標籤是封閉清單。**不在清單內的一律標 `other` 並附說明**，不要自創標籤——標籤一旦每次跑都不一樣，跨站比較和前後 diff 就全部失效。

| 標籤 | 判準 |
|---|---|
| `hero` | 頁面第一個滿版區塊，通常含 h1 |
| `value-prop` | 陳述主張或差異化，無重複單元 |
| `feature-list` | 功能或特色，重複單元 ≥3 |
| `service-list` | 服務項目列表，項目指向內頁 |
| `case-list` | 案例／作品列表 |
| `process-steps` | 帶編號或箭頭的流程說明 |
| `stats-impact` | 數字為主的成果呈現 |
| `social-proof` | 推薦語、評價，含人名或頭像 |
| `logo-wall` | 多個尺寸相近的小圖，通常為合作單位 |
| `team` | 人物列表，含職稱 |
| `pricing` | 含金額的方案比較 |
| `faq` | 問句標題或 `details` 元素 |
| `cta-banner` | 以單一 CTA 為主體的窄區塊 |
| `form` | 含 `form` 元素 |
| `donation` | 含金額選項的捐款區 |
| `newsletter` | 單一 email 欄位訂閱 |
| `article-list` | 文章列表，含日期 |
| `rich-text` | 長篇圖文內容 |
| `media-embed` | 影片、地圖等嵌入為主體 |
| `timeline` | 帶年份的沿革 |
| `nav-header` / `footer` | 頁首／頁尾 |
| `other` | 以上皆非，須附一句說明 |

少數可用訊號硬判（`form`、`faq`、`logo-wall`），**其餘一律用讀的**。把 `heading + copy + repeat_unit` 丟給模型判斷比寫規則準太多，而且「這個區塊想達成什麼」本來就是判斷題。

同時記下區塊**順序**——區塊序列是事實層資料，照實記錄即可。至於「這個排列反映什麼說服策略」的解讀，留到 Phase 6 使用者旅途一起做，不在這章下判斷。區塊解剖是現況記錄，混入推測會污染那章的可信度。

---

## Phase 6：使用者旅途

**旅途是 Phase 4 站台能力（商業邏輯）的動態延伸——先讀懂生意怎麼運作，再看使用者怎麼走過它。** 這是這章的起點：Phase 4 盤出的每一條商業邏輯／營收路徑（獲客、金流收單、訂閱、硬體、推薦、經銷夥伴、既有客戶留存…），原則上都該有一條旅途對應；反過來用它做**覆蓋檢查**——某條商業邏輯沒有對應動線，本身就是缺口（例：有推薦計畫卻沒有推薦人動線）。每條旅途明確**標注它走的是哪條商業邏輯路徑**。

在「商業邏輯路徑」這個骨架上，再用四個證據來源把步驟填實：導覽列結構、CTA 連結圖、表單位置（表單通常是轉換終點）、**區塊順序**（Phase 5 記下的序列，反映敘事／說服策略）。先找出主要轉換動作，再回推 3–5 條旅途。導覽結構與 CTA 連結圖是這章的**證據**，不另立「資訊架構」章；結構級問題則升級成「發現與建議」（見 Phase 8 章節說明）。這章也是承接「區塊順序＝說服策略」判斷的地方——同一組區塊排成 Hero → 案例 → CTA，跟排成 Hero → 價格 → FAQ → CTA，是兩種完全不同的說服策略，在這裡講。

**旅途 ≠ 流程圖，但配一張流程圖當底圖。** 本章開頭放一張「轉換地圖」——把各營收路徑畫成 flowchart（節點＝頁面/狀態、菱形＝系統判斷分岔、標出**離線/轉人工**與**摩擦/斷點/死路**）。它是**系統邏輯視角**的底圖；旅途則是**人的經歷視角**在這張圖上走的一條有血有肉的路（含情緒、摩擦、取捨）。兩者分工：flowchart 回答「系統會怎麼跑」，旅途回答「一個人會怎麼經歷」——別把第 5 章做成乾巴巴的頁面跳轉圖而失去「指出摩擦點」的價值。轉換地圖也讓**結構級斷點**（如主 CTA 全導向同一頁、購物車無結帳、入口撞後台）在圖上當場現形，再升級進第 7 章。實作以**單檔內嵌 SVG**呈現（無外部相依、可列印），調色語意固定：入口/主CTA、頁面/狀態、判斷菱形、線上完成、離線轉人工、摩擦斷點，並附圖例。

報告第 5 章開頭加一句橋接，明講「以下旅途是第 4 章商業邏輯的動態延伸」，讓兩章連成一條敘事，而不是各自獨立。

**CTA 連結圖是必產出的機器層 artifact，不是散文。** 把每個 CTA 記成 `analysis.json.cta_graph`（`來源頁 → 目標 URL → 分類`），並據此做兩件事：
- **同模板頁面必須 diff CTA 去向**：版型相同不代表動線相同。若同一組模板的頁面 CTA 導向不同終點（例：A 組導 `/hardware` 走線上購買、B 組導 `/contact` 走客服），那是**兩種轉換模式，必須分開描述**，不可因「同版型」就一視同仁帶過——這是最容易在「模板盤點」階段把不同動線壓成一個模板的地方。
- **CTA 去向分佈要當訊號讀**：多個 CTA 指向**同一個裸 URL、且未帶預期參數**（如 4 顆「選方案」鈕全連到 `/hardware` 卻不帶 `?plan`）＝**斷點／漏水／context 未傳遞**，升級為第 7 章「發現與建議」，不可略過。

```
旅途：初次接觸的潛在客戶 → 送出詢價
情境：搜尋服務關鍵字進入服務頁
步驟：
  1. /services — 6 張服務卡片，無價格資訊
  2. /services/web — 第 3 個區塊出現「立即詢價」
  3. /contact — 表單 7 欄，含「公司統編」必填
摩擦點：
  ⚠️ 1→2 缺篩選機制，服務名稱抽象（證據：/services block 2）
  ⚠️ 3 必填過多，個人接洽者無統編（證據：/contact forms[0]）
轉換後未驗證步驟：
  送出後的確認頁／錯誤處理未驗證（填了測試值，未按最終送出）
證據：shots/services.png、shots/contact.png
驗證方式：Playwright 實走 / 由結構推導
```

步驟用**白話描述動作**，不要把 selector 當成步驟主體——selector、CSS 類名這類技術證據降級成括號附註。最後一行的驗證方式必須標明。實走的旅途每步存 `shots/journey-N-step-M.png`。

**實走旅途錄 trace（機器層備查）。** 讓「實走」從自我聲明變成可驗證：

```python
context.tracing.start(screenshots=True, snapshots=True, sources=False)
# ... 實走旅途：遵守既有規範，表單可填測試值，送出前停住截圖 ...
context.tracing.stop(path='audit/data/traces/journey-{名稱}.zip')
```

1. **「實走」標記按檔案存在核對**：有對應 trace 檔的旅途才能標「Playwright 實走」，沒有的一律標「由結構推導」，交付前核對不憑記憶。
2. **trace 是機器層，不進報告**：報告正文不出現 trace、回放指令這類字眼（工作底稿紀律）；「方法與限制」可一句帶過「實走旅途留有完整操作紀錄備查」。
3. **隱私禁令**：trace 快照會完整錄下表單填入的測試值與頁面上任何個資——含表單互動的 trace **一律不得作為交付物外流**，僅內部留存；若途中顯示真實個資（即使來自測試帳號），該 trace 直接刪除，證據退回截圖並打碼。
4. trace zip 每條約 2–10 MB，不 embed 進 `report.html`。

**主要轉換動線必須實走，不能只用結構推導。** Phase 4 盤出的每一條主要轉換動線，都要用 Playwright **實際點擊走到副作用邊界**——這是「靜態盤點」與「真的懂這個站怎麼運作」的分水嶺：
- **只造成頁面跳轉／狀態切換的點擊不是副作用，必須點**：PICK YOUR DEVICE、加入購物車、下一步、選方案這類，要點下去觀察 runtime（URL 參數有沒有帶、sessionStorage、購物車真實內容、按鈕是不是其實失效）。很多斷點只有點下去才現形。
- **只有真正產生副作用的動作才在其前停住**：送出表單、付款、註冊、留言。
- **「由結構推導」只能用在確實無法實走的動線**；能走而沒走、卻標成推導，不允許。
- **無法實走時（登入牆、需付費帳號、需真實金流）不要靜靜略過**：在報告第 8 章「方法與限制」明確列一張 **「未能實走的動線 ＋ 原因 ＋ 需向誰取得（如測試帳號）」** 清單，並在該條旅途的「轉換後未驗證步驟」標「需帳號實走」。讓這個邊界對讀者與客戶可見、可補，而不是被當成沒問題。

**表單可填入測試值以驗證即時驗證行為**（必填提示、inline error），但**走到送出／付款／註冊等有副作用的動作前就停住並截圖**，不按最終按鈕。因此每條旅途都要明列一段**「轉換後未驗證步驟」**：送出後的確認／錯誤頁、結帳的運費稅金、付款流程——把盤點停在哪講清楚。這是誠實揭露界線，不是缺漏。

報告要明講：**旅途分析是專業判斷，不是使用者研究**。這份資料沒有流量、停留時間、實際流失點，能指出摩擦點，不能證明使用者真的在那裡離開。要回答後者得接 GA4 或錄影工具。

---

## Phase 7：機會缺口

依 Phase 0 的網站類型，載入 `references/expectations/{type}.md`，比對現況與預期清單。

每條缺口固定這個格式，**判斷依據與現況證據必須分成兩行**：

```
缺口：定期定額捐款機制
分級：幾乎必備 / 視情況 / 通常不需要
判斷依據：非營利組織常見模式（判斷，非本次爬取證據）
現況證據：/donate 僅有單次金額選項（shots/donate.png#2）
影響：無法建立經常性收入，每年需重新獲取捐款者
建議：新增定期定額選項，需確認金流商支援
信心：高 / 中 / 低
```

預期清單裡的「通常不需要」那一類要一起寫進報告。**只會加東西的稽核報告會膨脹專案範圍**——寫下「這個你不需要做」對客戶和對你都有價值。

報告中這一章獨立命名為「機會缺口」，放在「發現與建議」之前，**不要混進區塊解剖**。區塊解剖是現況記錄，混入推測會污染那章的可信度。排版上證據型發現與判斷型建議要有明顯視覺區別，讓客戶一眼看得出哪些是看到的、哪些是認為的。

---

## Phase 8：報告

交付物是**單檔 HTML**（CSS 內嵌、圖以相對路徑或 base64），客戶要能直接開、列印成 PDF、寄出去。同時交付 `data/pages.json`。

```
1. 稽核摘要                — 網站、日期、涵蓋範圍、3–5 條最重要發現（先講結論）
2. 網站結構                — sitemap 樹（現況導覽階層，`├─└─` 做上下層級的視覺區分，URL 對齊；標出 nav 標籤/URL 不符處）+ 孤兒／失聯頁面 + 現況數量（幾類頁、幾款產品）。⚠ **不放「代表頁一覽／頁面抽樣表」**——那是工作底稿，客戶看不懂，留機器層
3. 頁面模板盤點與區塊解剖   — 每個模板一張卡：**必須內嵌至少一張代表頁截圖**（`shots/` 相對路徑或 base64；桌機或手機皆可，手機版常更能顯示問題），下接該模板的逐（邏輯）區塊表：順序 / 類型 / 素材 / 主要 CTA。純結構現況，不下策略判斷。⚠ **幾何數值、重複單元數、頁面區塊數、selector 這類抽取產物不進報告**（留 `pages.json`）。有目標模板詞彙表就**逐塊**加配對三欄（見下方「模板配對」，是預設章、非選配）。截圖是報告可信度來源、也是給設計師看的——一份零截圖的模板盤點是工作底稿、不是交付物。
4. 站台能力                — 能力清單 + 技術棧
5. 使用者旅途              — 開頭一句橋接（承接第 4 章商業邏輯）＋一張「轉換地圖」flowchart（內嵌 SVG 底圖，見 Phase 6：入口/判斷菱形/離線/斷點＋圖例），下接 3–5 條旅途；每條標**商業邏輯路徑**，含摩擦點、轉換後未驗證步驟、敘事／說服策略、證據、驗證方式。旅途是在轉換地圖上走的「人的經歷」，不是頁面跳轉圖
6. 機會缺口                — 判斷層，與前面明顯區隔
7. 發現與建議              — P0 / P1 / P2，每條含「證據 → 影響 → 建議」
8. 方法與限制              — 範圍、工具、未涵蓋部分、資料日期；**含「未能實走的動線 ＋ 原因 ＋ 需取得帳號」具名清單**（登入牆/金流等觸及不到者）
```

**沒有獨立的「資訊架構與導覽」章。** 導覽結構與 CTA 連結圖若只是替旅途鋪路，就併進第 5 章當底圖、不另開一章（純描述結構對讀者沒價值，旅途會自然走過）。但**結構級的問題**——導覽超載、重要頁被埋深、CTA 指向不一致／漏水（單一旅途看不到、要在連結圖層級才浮現）——是**發現**，寫進第 7 章「發現與建議」配「證據→影響→建議」。孤兒頁仍放第 2 章。⚠ **例外**：若 Phase 0 的稽核目的**就是「資訊架構盤點」**，IA taxonomy 本身即交付物，這時才把它獨立成章（視目的而定，不是永遠都在）。

第 3 章把原本的「模板盤點」與「區塊解剖」**合併成一章**：以模板為單位，先給該模板的容量門檻，再逐（邏輯）區塊列出結構細節。**過切的頁面（長文、比較表、購物車等被幾何切成數十塊者）要先收斂回邏輯區塊**再呈現——報告給的是邏輯區塊，原始逐塊幾何留在 `pages.json`。

**模板分析的覆蓋率錨定在 sitemap，不是你抽樣的頁面集。** 這是防「虎頭蛇尾」（前幾個模板做滿、其餘塞摘要）的根本紀律：拿 Phase 2 的 sitemap 當底本，把**每一個主要頁面／區段逐一分類**成三態之一，缺一不可：
- **配到 TYPE**：成一張模板卡，逐塊配對（同模板只留 2–3 代表頁做深度區塊分析，但分類本身要涵蓋全 sitemap）。
- **非模板**：走非模板閘（Nav/Footer→003、產品→007、購物車→009、會員→008），成卡並逐塊標【非模板／00x】，**不可只用一行帶過**。
- **無對應模板＝缺口**：誠實標記。
三態都是合格結論——**「這頁沒有可用模板」本來就合理**；唯一不合格的是「某頁沒被交代」或「多個模板被併成一張摘要表」。深度分析可抽樣，但**每一個辨識出的模板都必須有自己的模板卡（截圖＋逐塊表），不得合併摘要**。章末附一張 **「頁面 → 模板對照表」**，把 sitemap 每個主要頁面對回其模板與狀態，讓覆蓋率可當場檢核。

**模板配對（給下游拼頁／版型系統）。** 觸發條件不是「使用者有沒有開口」——**只要 `references/target-template-vocab.md` 這個指標檔存在且能解析到 canonical 詞彙（或使用者直接給了 TYPE 清單），模板配對就是預設要做的一章，不是選配**。這是最容易被當成 optional 而整章跳過的地方（真的發生過：第 3 章只寫了結構現況、沒配 TYPE，交付後才被抓出來）。做法：在第 3 章**每個模板卡的每一個邏輯區塊**後加三欄——`對應 TYPE`、`契合度`（貼近／勉強／缺口／非模板）、`備註/缺口`——把每個來源區塊配到目標詞彙，配不上的標【缺口】，**別硬湊**；逐塊配、不要只給整頁一個總結。這份對應表與 `analysis.json` 的 `template_mapping` 是下游自動拼頁的直接輸入。配對前務必先收斂邏輯區塊——用幾何碎片配會產出整頁垃圾對應。只有使用者明講「不用配 TYPE」時才略過。

目標詞彙表**用指標、不要複製進本專案**（詞彙是活文件，副本會默默過期）。指標檔見 `references/target-template-vocab.md`，它記錄 canonical 路徑與配對紀律。**每次配對前務必去讀 canonical 最新版對照欄位定義再判契合度**，不要憑記憶配 TYPE；並在報告方法章節記下來源路徑＋讀取日期。

**配 TYPE 的判準（依序套用，以區塊實測欄位為準，不要憑標題語意猜）：** 這是最容易出錯的地方——曾把「單圖＋段落」誤判成牌卡、把「3 欄特色」誤判成圖文，就是因為看標題不看結構。務必以 `pages.json` 的 `repeat_unit.columns`、每項 `fields`、`media` 型別為準：

0. **非模板閘**：導覽/頁尾/登入/購物車/結帳/產品購買/部落格 → 路由到 003/002/電商系統。
1. **影片閘（硬規則）**：區塊以影片為主體 → **TYPE_2**（唯一有 `video_url`；TYPE_3/4/5/6/8/9 皆無影片欄位）。
2. **並列重複**（`repeat_unit.columns ≥ 2`）→ 牌卡類，先走 ladder：純圖無字→ **TYPE_4**（照片牆）、logo 列→ **TYPE_7**、**有文字的並列卡**再依「**圖的份量**」分 TYPE_3／TYPE_5（>3 會輪播）——這是最容易配錯、也是 TYPE_5 被結構性低估的地方：
   - **圖是內容主角**（大圖、產品/情境照，圖本身在傳達訊息、佔卡面積比高）→ **TYPE_3**（牌卡）。
   - **圖只是 icon／小圖／裝飾，內容以文字為主**（標題＋說明、姓名/職稱、一句話）→ **TYPE_5**（定位為「小圖/icon＋文字為主」的**通用版型，不限人物/證言**）。
   - 可測訊號（擇強者判、邊界標 §8）：**主訊號＝渲染圖絕對尺寸**（大圖、如高 ≥ ~200px → TYPE_3；icon 級 ≤ ~96px → TYPE_5）；`圖佔卡面積比`只當輔助——**它在 full-bleed／很長的卡會失真**（大圖除以超高卡面積會變很小，別因此誤判 TYPE_5）。`avg_text_length` 高而圖小 → TYPE_5。⚠ **`<img>` 抓到 0 不代表沒圖**——很多卡用 CSS 背景圖，`raster=0` 要交 §8 視覺確認，不可直接判 TYPE_5；只有「確實只有 SVG/字型 icon ＋ 大量文字」才算 icon-led → TYPE_5。圓形頭像只是「圖不重要」的特例佐證，**不再當主判準**。
   - ⚠ 別把 icon-led 特色格（icon＋標＋文、圖不重要）一律丟 TYPE_3——那正是讓 TYPE_5 幾乎用不到的原因。圖份量落在邊界時看文字重心、標 §8 視覺確認。
3. **色塊 overlap 閘（放在「單一圖文」之前）**：`columns=1`、有完整文字卡（標＋內文＋鈕），且**有一塊色塊/文字卡壓在圖上、遮掉部分圖** → **TYPE_9 候選**。事實層可判的訊號（優先序）：`color_block_overlap.over_image=true`（有底色元素蓋住內容圖 ≥15%，最直接）＞ `media_sig.bg_image=true` 且 `geometry.full_bleed=false`。⚠ **不要用長寬比判 TYPE_9**——21:9 只是設計常見裁切、不是判準且難套用；唯一判準是「這張圖**需不需要完整呈現**」：圖被色塊遮掉一塊還可以＝TYPE_9、圖要完整不被遮＝TYPE_2（canonical §5.10）。滿版背景＝TYPE_6。
4. **單一圖文**：只有 1 個 media、`columns=1`、每項只有 title、且**未觸發規則 3 的色塊 overlap** → **TYPE_2**。⚠ 若 `color_block_overlap` 抓不到（色塊用漸層/圖片底、或前端結構特殊），這仍是「圖需不需要完整」的視覺題——**預設 TYPE_2，交 §8 視覺確認「是否有色塊壓住圖、遮掉一塊」再改判 TYPE_9**。
5. **純文字**（無 media、無並列卡）→ **TYPE_1**。
6. **表單閘**：**任何內嵌 ≥3 欄輸入＋送出鈕的表單 → TYPE_13**（含首圖疊表單、頁中/頁尾的名單表單；`bg_pic`＋`big_title`＋`form_fields`，非缺口）。表單常非語意 `<form>`，要靠「≥3 個非隱藏輸入＋送出鈕」偵測，別漏。
7. **語意專用**：FAQ→**TYPE_10**、定價／功能比較表→**【缺口】**。
8. **CTA 區塊 TYPE_6 vs TYPE_2 vs TYPE_9（易錯）**：TYPE_6 頁中 Banner **必須是滿版/背景圖**＋浮字＋鈕；若圖片是**含入式、圖文並排、圖要完整不被遮**，即使有按鈕也是 **TYPE_2**；若含入圖被**色塊壓住、遮掉一塊（圖不需要完整）**，走規則 3 的 **TYPE_9**。判準：滿版背景/CSS 背景→TYPE_6、非滿版被色塊遮住→TYPE_9、並排完整內容圖→TYPE_2。**不看長寬比。**

TYPE_2 vs TYPE_3 的分水嶺：**多欄並列卡（columns≥2、每項自帶圖文）＝TYPE_3；單一圖文（1 media、可含影片）＝TYPE_2**。guide 的判準散在 §2–3，配對時把它當「資料契約」，視覺契合度再靠 §8（Playwright/Figma 比對）確認。

**影片訊號要分清**：`<img>` vs 前景影片（YouTube iframe / 內容 `<video>`）vs 背景影片（vide.js / 滿版 `<video>`）vs 非內容 iframe（reCAPTCHA、Google Maps）。只有**前景內容影片**才觸發 TYPE_2 影片閘；reCAPTCHA/地圖不算「有影片」，別誤標。

**報告語言：** 敘述文字一律用使用者的語言（對方講中文就通篇中文）。只有在**引用網站現有文案、URL、selector** 時保留原文、逐字照抄不改寫，並用引號或等寬字標示，讓讀者一眼分辨哪些是網站原文、哪些是你的判斷。

表格優先於長段落，截圖要有編號並在內文引用。建議一律寫成「證據 → 影響 → 建議」三段式。

---

## 刻意不做的

- **效能與 Core Web Vitals** — 該獨立成 skill，Lighthouse 有現成的
- **完整無障礙稽核** — 只記 alt 缺漏當素材品質訊號，不宣稱做了 a11y 檢測。做半套比不做傷害更大
- **SEO 全項** — title/meta/h1 是結構資料的副產品，不等於 SEO 稽核
- **行為數據** — 抓不到，報告要明講

共同點：都很誘人，都會讓這個 skill 從「一件事做好」變成「什麼都做一點」。

## 常見失誤

- 沒滾動就抓 → 只拿到 hero，漏掉半個網站
- 用 class 名稱找區塊 → 在 Tailwind／CSS Modules 站台上整片失效
- 沒抓 `repeat_unit` → 下游容量判斷無法進行，且事後補不回來
- 把每個內容頁當獨立頁面分析 → 同模板頁面流水帳，看不出模板結構（同模板內頁只留 2–3 代表）
- 拿幾何過切的碎片（pricing 的 90 列、長文的每段）直接配模板 → 產出整頁垃圾對應表；配對前要先收斂邏輯區塊
- 用長寬比（21:9）判 TYPE_9 → 難套用又抓錯（會把頁尾 logo 條、寬產品照全掃進來）；TYPE_9 是「圖需不需要完整」的視覺題，預設 TYPE_2、由 §8 視覺確認「有色塊壓住圖、遮掉一塊」才翻案
- icon-led／小圖＋文字為主的並列卡一律配 TYPE_3 → TYPE_5 被結構性低估；TYPE_3 vs TYPE_5 判準是「圖的份量」（圖為主→3、圖不重要→5），不是「有沒有卡」
- 報告敘述用了非客戶語言（例：對中文客戶通篇英文）→ 讀者分不清哪些是網站原文、哪些是你的判斷，也難讀
- 旅途沒標「轉換後未驗證步驟」→ 讀者誤以為連送出後流程都驗過，界線不清
- 憑印象寫旅途 → 出現不存在的步驟，客戶一看就破功
- 只做靜態爬取、把主要轉換動線標「由結構推導」就交差 → 漏掉 runtime 行為（`?plan` 沒帶、按鈕其實失效、購物車真實內容）；只造成跳轉的點擊必須實點，能走而沒走不算推導
- 同模板頁面因「版型相同」就一視同仁描述 → 漏掉 CTA 去向不同的兩種轉換模式（線上購買型 vs 聯絡客服型）；務必用 CTA 連結圖 diff 去向
- 多個 CTA 指向同一裸 URL、未帶預期參數卻沒警覺 → 斷點/context 未傳遞被當成正常
- 旅途沒回頭對照站台能力 → 漏掉整條營收路徑沒有動線（如有推薦計畫／經銷體系卻沒有對應旅途）；每條商業邏輯都要檢查有無對應旅途
- 缺口建議寫成「建議增加社會證明」→ 沒有網站類型脈絡的萬用廢話
- 編造百分比 → 整份報告可信度崩盤
- 把驗證過程寫進客戶報告（代表頁一覽、頁面抽樣表、區塊數、幾何、selector）→ 客戶看不懂、失焦；那些留機器層，報告只留現況＋判斷＋建議
- 用固定清單打勾當站台能力偵測 → 錨定在清單上，漏掉網站真正的商業邏輯（推薦計畫、預約引擎、經銷入口…）；要先爬再歸納，常見能力表只當事後完整性回顧
- SPA 只抓到骨架 → 確認 `blocks` 非空，為空要換策略而不是照樣輸出
- 網路監聽器換頁前沒解除 → 請求記到錯的頁面，證據鏈錯亂
- 把第三方請求的 query string 原樣記錄 → 可能含追蹤識別碼，一律去除
- 只用 signature 清單比對第三方請求 → 又回到「拿清單打勾」，清單外的服務消失；先全記後歸納
- 含表單測試值的 trace 外流 → 個資風險；trace 只留機器層，不作交付物
- 有目標詞彙表卻沒配 TYPE（當成選配整章跳過）→ 第 3 章只剩結構現況，下游拼頁沒有輸入；references 詞彙表可解析時，配對是預設章
- 模板盤點零截圖 → 讀起來像工作底稿不像交付物；每個模板卡至少一張代表截圖
- 把「精簡工作底稿」誤用成「精簡發現」→ 缺口砍到剩幾條、價格/方案/費率原文不抄、逐塊 TYPE 縮成一句 → 報告變單薄、資訊量輸給上一版
- **虎頭蛇尾**：前幾個模板做滿逐塊卡、其餘塞進一張摘要表或一行帶過 → 看不出各頁用什麼模板；每個模板都要成卡，不得合併摘要
- 拿「自己抽樣到的頁面集」當覆蓋基準（而非 sitemap）→ 尾段頁面/模板被漏或被摘要吃掉；覆蓋率一律對 sitemap 主要頁面檢核
- 把「沒有可用模板」當成缺失想辦法硬配 → 非模板/缺口本來就是合格結論，逐頁標明三態即可，別硬湊 TYPE

## 交付前檢查

- [ ] 每頁 `blocks` 非空，且數量落在 5–15（超出範圍已重切；prose／表格型頁面過切為已知例外，報告第 3 章已收斂回邏輯區塊）
- [ ] `repeat_unit` 在列表型區塊上有值
- [ ] 區塊標籤全部來自封閉清單
- [ ] 若 `references` 目標詞彙表可解析（或使用者給了清單）：第 3 章**每個模板卡的每個邏輯區塊**都有 `對應 TYPE` 或標【缺口】；過切頁面已先收斂再配對（這是預設章，不是選配）
- [ ] 每個模板卡至少內嵌一張代表截圖（`shots/` 相對路徑或 base64）
- [ ] **模板分析覆蓋率對 sitemap 檢核**：sitemap 每個主要頁面/區段都出現在「頁面 → 模板對照表」，狀態 ∈｛配到 TYPE／非模板／缺口｝，無遺漏
- [ ] **每個辨識出的模板都有自己的模板卡（截圖＋逐塊表），無合併摘要／一行帶過**（含非模板頁 cart/login/product/list）
- [ ] 缺口清單逐項比對 `expectations/{type}.md`（含「已有」與「不需要」），非只列重點幾條
- [ ] 關鍵商業數字（方案名／價格／費率／售價）照抄原文寫進報告，不省略
- [ ] 報告敘述為使用者語言；僅網站原文 / URL / selector 保留原文並標示
- [ ] 旅途標明實走或推導，且每條列出「轉換後未驗證步驟」
- [ ] **每條主要轉換動線都已實走到副作用邊界**（僅跳轉的點擊已實點）；無法實走者已在第 8 章「方法與限制」列出原因＋需取得帳號
- [ ] **`analysis.json.cta_graph` 已產出**；同模板頁面已 diff CTA 去向並分出不同轉換模式；多 CTA 指向同一裸 URL 已當斷點檢視
- [ ] 每條旅途標注對應的商業邏輯路徑；Phase 4 每條站台能力都檢查過有無對應旅途（缺的當缺口）
- [ ] 缺口的判斷依據與現況證據分行
- [ ] 全文無自創百分比或「業界標準」措辭
- [ ] 報告（`report.html`）無驗證過程／工作底稿內容（代表頁一覽、頁面抽樣表、區塊數、幾何、selector）——這些只在 `pages.json`／`analysis.json`
- [ ] **連缺口／發現的「證據」也用客戶語言**——不要把 `pages.json` 欄位名當證據寫進報告（`heading_length=0`、`img_missing_alt`、`repeat_unit` 這類要翻成「沒有標題文字」「圖片缺 alt」）
- [ ] 限制章節誠實列出未涵蓋部分
- [ ] HTML 單檔開啟正常、列印不破版
- [ ] 每頁 `third_party_domains` 已聚合去重，URL 皆已去除 query string
- [ ] 第 4 章技術棧每項標注「網路證據 / HTML 推測」
- [ ] 標「實走」的旅途在 `data/traces/` 都有對應 trace 檔
- [ ] 報告正文無 trace / 回放指令字眼；含表單互動的 trace 未附入交付物

## 參考檔

`references/expectations/` 下每個網站類型一份預期清單，只載入 Phase 0 確認的那一份。新增類型時照 `_template.md` 的結構寫。

這些檔案之後也是模板配對詞彙表的來源；若累積了數十份 `pages.json`，「幾乎必備」的依據可以從判斷升級為實際統計，介面不變。
