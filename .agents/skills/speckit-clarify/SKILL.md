---
name: speckit-clarify
description: 澄清 spec.md 中模糊或不完整的需求，透過反向提問精確化規格。當 spec 含有 [NEEDS CLARIFICATION] 標記、驗收標準模糊、或需求存在歧義時使用。
argument-hint: "（可選）指定要澄清的部分或問題"
user-invocable: true
disable-model-invocation: false
metadata:
  source: ".claude/commands/speckit.clarify.md (ported to skill)"
---

# /speckit-clarify

澄清 spec.md 中模糊或不完整的需求，透過反向提問來精確化規格。

## 輸入

$ARGUMENTS（可選：指定要澄清的特定部分或問題；否則掃描整個 spec.md）

## 你的任務

### Step 1: 掃描 spec.md

讀取當前功能的 `specs/NNN-feature-name/spec.md`，找出：
1. 所有 `[NEEDS CLARIFICATION]` 標記
2. 模糊的驗收標準（無法判斷通過/失敗）
3. 缺少的邊界條件
4. 可能的衝突或矛盾
5. 隱含的假設（沒有明確說明但被依賴的條件）

### Step 2: 生成澄清問題

針對每個模糊點，提出**精確的問題**：
- 問題要求是**可以用具體答案回答的**，不是開放式討論
- 優先問**影響架構決策的問題**
- 用使用者熟悉的業務語言，不用技術術語

格式：
```
[問題 1] 關於 [章節/功能]：
當使用者 [情境]，系統應該 [選項 A] 還是 [選項 B]？

[問題 2] 關於 [章節/功能]：
[明確的是非題或選擇題]
```

### Step 3: 等待使用者回答

讓使用者回答所有問題。

### Step 4: 更新 spec.md

根據使用者的回答：
1. 將 `[NEEDS CLARIFICATION]` 替換為明確的規格描述
2. 更新相關的驗收標準
3. 新增/更新必要的驗收場景
4. 若有新的邊界情況，新增到「驗收場景」章節

### Step 5: 再次檢查

確認更新後的 spec.md：
- 沒有剩餘的 `[NEEDS CLARIFICATION]`
- 所有驗收標準都是可驗證的
- 沒有新的模糊點引入

### Step 6: 輸出摘要

告知使用者：
- 已澄清的問題數量
- 主要的規格變更摘要
- 若 spec.md 已完全澄清：建議執行 `/speckit-plan`

## 重要原則

- 澄清的目標是**消除歧義**，不是增加功能
- 若使用者的回答引入新功能，建議另開一個功能規格
- 保持中立：不偏向任何技術實作方向
- 澄清後的規格仍然只描述 WHAT 和 WHY，不涉及 HOW
