---
name: pr-link-tracking-issue
description: 開 implementation PR（或補一支缺 linkage 的 PR）時使用：反查 web-finance-pm 的 tracking issue、寫入 Closes、驗證 closingIssuesReferences、把 GitHub Project 6 狀態改 In progress。
---

# pr-link-tracking-issue

本檔是 `web-finance-frontend` 已填值的可執行 procedure。canonical mechanics 屬 PM repo
`docs/workflows/README.md` 與 `docs/workflows/github-project-6.md`；只有修改本檔、上游規則有變，
或操作與 PM 契約衝突時才載入它們。發現衝突時停止並修正 owner，不自行合出第三套規則。

## Config

| Key | Value |
|---|---|
| Implementation repo | `xxtechec/web-finance-frontend` |
| Tracking repo | `xxtechec/web-finance-pm` |
| Project owner / number | `xxtechec` / `6`（`web-finance`） |
| PM local path | `references/web-finance-pm` |
| PR base | `develop`（見 `AGENTS.md` §Branch Model） |

🔴 **不得在本檔寫死 Project／field／option node ID。** PM repo
`docs/workflows/github-project-6.md` §Project Helper 明訂 ID 一律依名稱動態解析。改 Project status
一律走 PM repo 的 helper：

```bash
cd references/web-finance-pm
npm run project -- fields --owner=xxtechec --number=6
npm run project -- set <central-issue-url> "Status" "In progress" --owner=xxtechec --number=6
```

submodule 未展開時先 `git submodule update --init references/web-finance-pm`；仍取不到 helper 就
停下回報，不要改用寫死 ID 的 `gh project item-edit`。

## Rules

- `Closes` 只准指向 tracking repo (`web-finance-pm`) 的 issue。本 repo 自己的 issue 不用 closing
  keyword——`reopen-auto-closed` workflow 只部署在 tracking repo，接不住。
- **兩層 issue 的 close 語義由 PM 擁有**（`docs/workflows/README.md` §GitHub Close 語義）：
  無 child 時 PR 用 `Closes xxtechec/web-finance-pm#<parent>`；有 `implementation-child` 時
  `Closes` 指向 child、parent 只留一般 reference。`reopen-auto-closed` 只對 `tracking-parent` 的
  machine close 執行 reopen ⇒ **對 child 用 `Closes` 不會被接住**，這是刻意的，不要為了「保險」
  兩張都寫 `Closes`。
- 一條 `Closes` 一行、獨立成行，否則 GitHub 不建立 `closingIssuesReferences`。
- 只有 implementation PR（BUILD／REVIEW／FIX 有實際程式交付）才寫 linkage。純文件、chore、
  spec-only 的 task 宣告 PR 不寫 `Closes`。
- 不手動 close / reopen tracking issue；不改 tracking frontmatter 的 `status`（那只表示需求核准與
  有效性，與實作進度無關，見 PM `CONVENTIONS.md`）。
- PR merge **不**把 Project status 改 `In review`——那要 dev tag 部署成功，見
  `.agents/skills/deploy-tag-to-review`。
- 前提：tracking repo 已部署 `.github/workflows/reopen-auto-closed.yml`。⚠️ 它驗證 Organization
  Project Done 需要 repository secret `PM_REOPEN_TOKEN`（由 repo owner 另設）；未設定時 worker 會
  fail-safe reopen 並建 automation alert——那不是 linkage 壞掉。

## Lookup

先讀 task spec（`requirements/tasks/BUILD-xxx-*.md`）的 `Primary Issue`。沒有該欄位（早期 task）
才反查：

```bash
# 產品交付：先找該 Feature / Use Case 的中央 parent
gh issue list --repo xxtechec/web-finance-pm --label tracking-parent --search '<F-xxx 或 UC-xxx>'
# 跨 repo 分工：找 implementation-child
gh issue list --repo xxtechec/web-finance-pm --label implementation-child --search '<F-xxx> frontend'
```

查無唯一結果時列出候選、lookup 條件與判斷依據給使用者決定，**不要自己建票**、也不要因為 lookup
是空的就當成「不需要 linkage」。

## Steps

1. 讀 task spec 的 `Primary Issue`（或依上節反查），驗證 issue 的 repo、存在性、label 與
   Project 6 membership。
2. 需要 linked branch 時用 `gh issue develop` 建，base 為 `develop`。
3. 把 standalone `Closes <Primary Issue>` 寫入 PR body。
4. 用 PM helper 把 Project Status 改 `In progress`。
5. 驗證 PR 的 `closingIssuesReferences` 含每一張預期 issue。

遇到以下情況一律先問：找不到明確 issue、一 PR 對多 issue 無法確定、issue 已是 In review / Done /
closed、issue 不在 Project 6、Project 6 的 `Implementation repository` 欄位尚未包含
`xxtechec/web-finance-frontend`。

## Commands

```bash
gh issue develop <issue> --repo xxtechec/web-finance-pm --branch-repo xxtechec/web-finance-frontend --name <branch-name> --base develop
git fetch origin && git checkout <branch-name>
gh pr create --base develop --title <title> --body-file <body-file>
gh pr edit <pr> --body-file <body-file>
```

驗證 linkage：

```bash
gh api graphql \
  -f query='query($owner: String!, $repo: String!, $number: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $number) {
        closingIssuesReferences(first: 10) {
          nodes { number repository { nameWithOwner } }
        }
      }
    }
  }' \
  -f owner=xxtechec -f repo=web-finance-frontend -F number=<pr-number> \
  --jq '.data.repository.pullRequest.closingIssuesReferences.nodes'
```
