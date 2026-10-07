---
name: deploy-tag-to-review
description: >-
  tag / release / deploy 成功後，從本次版本包含的 merged PR 用 `closingIssuesReferences` 反查 tracking
  issue，在 issue 留下 tag / deploy / 可驗範圍，再把 Project status 改 `In review`。
---

# deploy-tag-to-review

本檔是 `web-finance-frontend` 已填值的可執行 procedure。PM repo `docs/workflows/README.md` 與
`docs/workflows/github-project-6.md` 擁有上游 mechanics；只有修改本 procedure、上游規則有變，
或操作衝突時才載入它們。worktree 未展開 submodule 不阻擋依本檔執行既有流程。

## Config

本 repo (`web-finance-frontend`) 實際值：

| Key | Value |
|---|---|
| Service | `web-finance-frontend` |
| Implementation repo | `xxtechec/web-finance-frontend` |
| Dev site | TBD — `chart/values-dev.yaml` 的 host 尚未填 |
| Tracking repo | `xxtechec/web-finance-pm` |
| Project owner / number | `xxtechec` / `6` |
| Dev tag pattern | `dev-<MAJOR>.<MINOR>.<PATCH>`（例：`dev-1.2.3`，regex `^dev-\d+\.\d+\.\d+$`） |
| Stage tag pattern | `stage-<MAJOR>.<MINOR>.<PATCH>` |
| Prod tag pattern | `<MAJOR>.<MINOR>.<PATCH>` |

Deploy workflow：`.github/workflows/main.yml` 在 push `dev-*` tag 時觸發 `deploy-dev` job
（呼叫 `deploy.yml`）。`stage-*` → staging、`X.Y.Z` → prod。**可驗環境＝dev**，只有 `deploy-dev`
成功才考慮轉 `In review`（PM `AGENTS.md` §Deployment Tags：只有 dev 有 acceptance gate）。

前端另有可直接看的驗收證據：dev 站台 URL。留 comment 時一併給，PM 才不必自己去猜路徑。

🔴 **不得在本檔寫死 Project／field／option node ID**（PM `docs/workflows/github-project-6.md`
§Project Helper）。改狀態一律：

```bash
cd references/web-finance-pm
npm run project -- set <central-issue-url> "Status" "In review" --owner=xxtechec --number=6
```

## Rules

- 只有部署到 dev（`deploy-dev`）成功、evidence 明確，才考慮改 `In review`；PR merge 本身不算。
- 🔴 **本 repo 綠燈不足以讓 product parent 進 `In review`。** PM `docs/workflows/README.md` 第 7 條：
  **每個必要 implementation repository 都要各自產生 dev tag**，product parent 才可進 `In review`。
  某張 parent 的 `impl_areas` 同時含 backend 時，只有前端部署完成 ⇒ **在 issue 留 evidence
  comment，但不改 Status**，並明寫還缺哪個 repo。只影響本 repo 的工程 issue 不受此限。
- Tag 建立後不可移動或重用；重新部署必須建立新版本 tag（PM `AGENTS.md` §Deployment Tags）。
- 只從 `implementation-completion` PR 的 `closingIssuesReferences` 反查 tracking issue。
  Declaration/readiness/reopen/withdrawal 沒有 closing linkage；implementation-start 可能已有同一
  Primary Issue linkage，但不是 delivered-code evidence，部署反查必須忽略。
- 改 review 前必須先準備 issue comment，內容至少包含 tag、deploy evidence（workflow run URL）、
  environment、可驗範圍與排除項。
- PR merge 或 auto-close / reopen timeline 不得單獨觸發 review。若 issue 目前被 PR 關著沒被 reopen，
  代表 tracking repo 的 `reopen-auto-closed` workflow 失效（常見原因是 `PM_REOPEN_TOKEN` 未設），
  回報使用者補救，不在 closed issue 上改狀態。
- 不 close tracking issue，不改 tracking frontmatter 的 `status`——那只表示需求核准與有效性，
  與實作進度無關（PM `CONVENTIONS.md`）。
- 不設 Acceptance `passed`、不改 Project `Done`：那要 E2E 通過後由 PM 確認（PM
  `docs/workflows/README.md` 第 8 條）。

## Steps

1. 確認 dev tag 與 `deploy-dev` run 成功，取得 evidence（workflow run URL）。
2. 找出本次版本包含的 merged PR（見 Find Included PRs）。
3. 對每支 PR 用 `closingIssuesReferences` 反查 tracking issue，讀 issue、labels
   （`tracking-parent` / `implementation-child`）與 Project Status。
4. 對每張 product parent，查它的 `impl_areas` 需要哪些 implementation repositories
   （tracking frontmatter，或 PM `AGENTS.md` §Implementation Repositories 對照），確認每個必要 repo
   都已有 dev tag。缺任何一個就只留 comment、不改 Status。
5. 為每張 issue 準備 evidence comment，明列 tag、deploy evidence、environment、可驗範圍與排除項。
6. 改狀態前先列出動作給使用者確認；執行時先在 issue 留 evidence comment，再用 PM helper 把
   Project Status 改 `In review`。

遇到以下情況一律先問：deploy evidence 不明確、無法判斷版本包含哪些 PR、issue 已是 In review /
Done / closed、issue 需要多 repo / 多 PR evidence 才可驗、issue 不在 Project 6。

## Find Included PRs

優先序，取到明確答案就停：

```bash
# 1. 兩個 tag 之間的 commit（最可靠）
git fetch --tags
git log --oneline <previous-dev-tag>..<current-dev-tag>

# 2. 從 commit 反查 PR
gh pr list --repo xxtechec/web-finance-frontend --state merged --search '<commit-sha>' --json number,title,mergedAt

# 3. merged 時間區間（最後手段，需人工確認）
gh pr list --repo xxtechec/web-finance-frontend --state merged --limit 30 --json number,title,mergedAt,mergeCommit
```

無法可靠判斷就問，不要猜。

## Issue Comment

```markdown
已包含於可驗版本：<dev-tag>
Deploy evidence: <workflow run URL>
Environment: dev
可驗範圍：<這次交付的行為，對應 BUILD / REVIEW task 與 R#>
Dev site: <URL>
不含：<明確排除項，或還缺哪個 implementation repository 的 dev tag>
狀態：可進入驗收。／等待 <repo> 部署後才可進入驗收。
```
