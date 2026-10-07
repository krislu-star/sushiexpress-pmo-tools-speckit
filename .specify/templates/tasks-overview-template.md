# Task Overview: [FEATURE_TITLE]

> **Branch**: `NNN-feature-name`
> **Spec**: `specs/NNN-feature-name/spec.md`
> **Plan**: `specs/NNN-feature-name/plan.md`

> 本模板用於**拆檔**的功能（`spec.md` 的 `Owner` 為前後端各一人），產出為 `tasks.md`。
> **本檔是總覽，不放任何任務**（憲法 Article XIII）。
> 本檔不得出現任何勾選清單項目，否則會被 PM 視圖誤計。任務只寫在分邊任務清單，
> 負責人取自 `spec.md` 的 `Owner` 標註。

---

## 任務清單 (Task Lists)

| 邊 | 檔案 | 編號格式 |
|---|---|---|
| 前端 | `tasks-frontend.md` | `TASK-FE-NNN` |
| 後端 | `tasks-backend.md` | `TASK-BE-NNN` |

## 跨邊依賴順序 (Cross-side Dependencies)

> 只列跨檔的依賴；同一邊內的順序寫在該分邊檔。需要兩邊合作的工作已拆成兩條分邊任務。

1. `TASK-BE-NNN` API 契約草案 → `TASK-FE-NNN` 確認契約並依契約建 mock
2. `TASK-BE-NNN` 部署 stage → `TASK-FE-NNN` 串接真 API、聯調
3. `TASK-FE-NNN` 聯調完成 → `TASK-BE-NNN` 聯調問題修正

## 里程碑 (Milestones)

> 以任務編號定義；里程碑的達成時間由對應任務的完成時間推導，不在此手寫日期。

| 里程碑 | 達成條件 |
|---|---|
| 契約定案 | `TASK-BE-NNN`、`TASK-FE-NNN` 皆完成 |
| 可聯調 | `TASK-BE-NNN` 完成 |
| 可驗收 | 兩份分邊任務清單全部完成 |
