---
name: speckit-constitution
description: 建立或更新專案憲法（.specify/memory/constitution.md）。當使用者要定義或修改專案的技術棧約束、程式碼品質、測試策略、安全合規等治理條款時使用。
user-invocable: true
disable-model-invocation: false
metadata:
  source: ".claude/commands/speckit.constitution.md (ported to skill)"
---

# /speckit-constitution

建立或更新專案憲法（`.specify/memory/constitution.md`）。

## 你的任務

1. **讀取** `.specify/memory/constitution.md`（若存在）
2. **詢問**使用者以下問題（一次列出，讓使用者一起回答）：
   - 這個專案使用什麼技術棧？（前端/後端/資料庫）
   - 有哪些被禁止的技術或必須避免的套件？
   - 測試策略偏好？（TDD? 覆蓋率要求?）
   - 程式碼風格規範？（格式化工具、lint 規則）
   - 安全與合規需求？（認證機制、資料保護）
   - 有哪些組織或團隊的特殊要求？

3. **根據**使用者的回答，更新 `.specify/memory/constitution.md`，保留原有條款並加入/修改相關內容。

4. **確認**所有九個 Article 都存在且完整：
   - Article I: 技術棧約束
   - Article II: 程式碼品質標準
   - Article III: 測試策略
   - Article IV: 安全與合規
   - Article V: 規格優先
   - Article VI: 分支策略
   - Article VII: 簡單性原則
   - Article VIII: 文件即程式碼
   - Article IX: AI 協作準則

5. **輸出**憲法摘要給使用者確認。

## 重要原則

- 憲法是**不可變的治理文件**，修改需要明確的理由
- 憲法中的條款會成為每個 `plan.md` 的「Phase -1 閘門檢查」
- 技術棧決策在憲法中定義後，所有 plan 必須遵守
