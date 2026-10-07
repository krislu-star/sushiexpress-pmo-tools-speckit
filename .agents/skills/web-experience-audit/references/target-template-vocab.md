# 目標模板詞彙表（指標檔，不是副本）

這個檔案本身**不含** TYPE 定義。它只記錄「做模板配對時，去哪讀最新的詞彙定義」。
之所以用指標而非複製：詞彙表是活的文件，複製一份進來會默默過期，配對就會錯。

## 目前的目標詞彙：kiitzu theme-builder

- **單一真實來源（canonical）**：`./page-template-guide.md`（本指標檔同目錄下的副本；原始出處為 `/Users/dianasu/projects/kiitzu-theme-builder-speckit/docs/page-template-guide.md`，若需最新版請回原始出處同步）
- **內容**：TYPE_1~TYPE_13 的用途、欄位、子資料、硬性規則（H1 決議、牌卡 >3 輪播、TYPE_8 首圖單張、**TYPE_6／TYPE_8 多圖輪播規劃中**、TYPE_7 標題為 h2、TYPE_13 有 bg_pic＋form_fields…）、§8 視覺驗證流程、**§9 導覽列/頁尾（Nav/Footer）資料結構**（非模板，屬 003），與 **§10 電商與會員系統（產品/會員/購物車）**（非模板，屬 007/008/009）。
- **對應 spec**：001-page-template-system（TYPE_1~10、13）、002-blog-system（TYPE_11、12）、003-nav-footer（導覽/頁尾，非模板，資料結構見 guide §9）、007-product-catalog／008-membership／009-shopping-cart（產品/會員/購物車，非模板，範圍與缺口見 guide §10）。

## 配對時的紀律（務必遵守）

1. **配對前先讀最新版** canonical guide——不要憑記憶或這份指標檔配 TYPE。
2. 逐「邏輯區塊」配一個 TYPE，契合度分 `貼近／勉強／缺口／非模板`；配不上標【缺口】，別硬湊。
3. **對照硬性規則再判契合度**，例如：
   - 重複單元 >3 → TYPE_3/4/5 會自動輪播（設計要接受）。
   - 首圖疊表單 → 是 **TYPE_13**（`bg_pic`＋`big_title`＋`form_fields`，`position` FORM_RIGHT/…），**非缺口**；滿版 hero 高度需 §8 視覺驗證。
   - 導覽/頁尾 → 非本模板系統（003，見 guide §9）；產品列表/詳情、登入/會員中心/地址簿/訂單、購物車/結帳/下單完成 → 非本模板系統（007/008/009，見 guide §10）。功能主體走非模板閘，功能頁外框的一般行銷區塊仍照常配 TYPE。金流／變體 SKU／訪客結帳等落在現行 spec 排除範圍者標缺口。
   - 部落格列表/內頁 → TYPE_11/12（002），不在通用拼頁流程。
4. 在報告方法章節與 `analysis.json.mapping_note` 記下**來源路徑＋讀取日期**，讓讀者知道對齊的是哪一版。

## 換一個目標系統時

若之後要配到別的 theme／版型系統，改這一節的 canonical 路徑即可，配對流程不變。
