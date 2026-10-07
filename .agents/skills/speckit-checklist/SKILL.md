---
name: speckit-checklist
description: 執行最終品質驗證，確認功能實作符合所有規格與憲法要求。當所有任務完成、準備開 PR、要做合併前的品質核對清單時使用。
argument-hint: "（可選）指定分支名稱；否則使用當前 git 分支"
user-invocable: true
disable-model-invocation: false
metadata:
  source: ".claude/commands/speckit.checklist.md (ported to skill)"
---

# /speckit-checklist

執行最終品質驗證，確認功能實作符合所有規格和憲法要求。

## 輸入

$ARGUMENTS（可選：指定分支名稱；否則使用當前 git 分支）

## 你的任務

### Step 1: 載入所有文件和程式碼

1. 執行 `bash .specify/scripts/bash/check-prerequisites.sh`，從 `Layout from Owner:` 取得 Layout（`single`／`split`）；腳本報出的錯誤直接列為未通過項目
2. 讀取 `.specify/memory/constitution.md`
3. 讀取 `specs/NNN-feature-name/spec.md`
4. 讀取 `plan.md`；split 時另讀 `plan-frontend.md`、`plan-backend.md`
5. 讀取任務清單：single 為 `tasks.md`；split 為 `tasks-frontend.md`、`tasks-backend.md`（`tasks.md` 為總覽，讀取里程碑）
6. 掃描相關的程式碼檔案

### Step 2: 執行品質核對清單

#### A. 規格完成度

- [ ] spec.md 品質核對清單全部通過
- [ ] 計劃品質核對清單全部通過（split 時三份計劃都要通過）
- [ ] 所有任務標記為 `[x]`（完成）
  - single：`tasks.md` 全部完成
  - split：`tasks-frontend.md` 與 `tasks-backend.md` **兩份**都全部完成；`tasks.md` 總覽的里程碑皆已達成
  - 忽略 code block 內的範例行
- [ ] 沒有未解決的 `[NEEDS CLARIFICATION]`

#### B. 憲法合規

- [ ] **Article I**: 程式碼只使用計劃中列出的技術
- [ ] **Article II**: 所有公開函式有文件（docstring/JSDoc）
- [ ] **Article III**: 測試覆蓋率 >= 80%（或專案規定的標準）
- [ ] **Article III**: 所有測試在實作程式碼之前被建立
- [ ] **Article IV**: 沒有硬編碼的憑證或密鑰
- [ ] **Article IV**: 所有使用者輸入都有邊界驗證
- [ ] **Article V**: split 時 API 合約只存在於 `plan.md` 與 `contracts/`，實作與契約一致
- [ ] **Article XII**: 未修改 `cms/`
- [ ] **Article XIII**: 檔案配置與 `Owner` 相符；任務編號格式正確且不重複；專案管理欄位只在 `spec.md`

#### C. 驗收場景驗證

對每個 spec.md 中的驗收場景（SC-NNN），確認：
- [ ] SC-001: 有對應的自動化測試且通過
- [ ] SC-002: 有對應的自動化測試且通過
- [ ] SC-003: 有對應的自動化測試且通過
（根據實際場景數量調整；split 時註明每個場景由哪一邊的測試涵蓋）

#### D. 程式碼品質

- [ ] 沒有函式超過 50 行
- [ ] 沒有 TODO/FIXME/HACK 注釋（或已記錄為已知問題）
- [ ] 沒有 console.log 或調試代碼遺留
- [ ] 所有錯誤都有適當的處理
- [ ] split 時前端已移除 mock，改接真 API

#### E. 文件

- [ ] API 文件已更新（若有 API 變更）
- [ ] CHANGELOG 或 PR 描述已撰寫
- [ ] specs/ 目錄已提交版控

#### F. 最終測試

建議執行以下命令並確認通過：
```bash
# 執行完整測試套件
[測試指令]

# 執行覆蓋率報告
[覆蓋率指令]

# 執行程式碼品質檢查
[lint 指令]
```

### Step 3: 生成核對清單報告

```markdown
# 品質核對清單報告

## 功能: [功能名稱]
## 日期: [今天日期]
## Layout: single | split

### A. 規格完成度: ✅/❌（split 時：前端 N/N、後端 N/N 任務完成）
### B. 憲法合規: ✅/❌
### C. 驗收場景: ✅/❌ (N/N 通過)
### D. 程式碼品質: ✅/❌
### E. 文件: ✅/❌

### 總體狀態: ✅ 可以合併 | ❌ 需要修正

### 未通過項目:
- [項目]: [需要的行動]（split 時註明屬於哪一邊）
```

### Step 4: 建議下一步

- **若全部通過**: 建議建立 Pull Request，並提供 PR 描述模板
- **若有未通過**: 列出優先修正的項目；split 時依邊分組，方便各自的 Owner 處理
