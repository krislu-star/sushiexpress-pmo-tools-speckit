# Welcome to Kiitzu

## How We Use Claude

Based on Evan's usage over the last 30 days:

Work Type Breakdown:
  _TODO — 本機掃描沒有找到過去 30 天的 session 紀錄，累積一些使用量後可重新產生這個區塊。_

Top Skills & Commands:
  _TODO — 尚無使用統計，先參考下方「Skills to Know About」。_

Top MCP Servers:
  _無 — 團隊目前沒有使用 MCP server。_

## Your Setup Checklist

### Codebases
- [ ] kiitzu-speckit — github.com/kiitzu/kiitzu-speckit（主 repo，Spec-Driven Development 框架，clone 時記得 `--recurse-submodules`）
- [ ] frontend — github.com/Kiitzu/kiitzu-theme-builder-web（前台前端，submodule，追蹤 `master`）
- [ ] cms — github.com/Kiitzu/kiitzu-theme-builder-kiibase-web（後台 CMS 前端，submodule，追蹤 `master`，**唯讀，禁止修改程式碼**）
- [ ] backend — github.com/Kiitzu/kiitzu-theme-builder-kiibase-api（後端 API，submodule，追蹤 `master`）

### MCP Servers to Activate
- 目前不需要設定任何 MCP server。

### Skills to Know About
- `/speckit.constitution` — 建立/更新專案憲法，所有開發決策的最高治理文件
- `/speckit.specify <描述>` — 將功能描述轉為完整 spec.md（只寫 WHAT/WHY，不寫 HOW）
- `/speckit.clarify` — 澄清 spec.md 中的模糊需求
- `/speckit.plan` — 根據 spec 生成技術計劃 plan.md（含 Phase -1 憲法閘門檢查）
- `/speckit.analyze` — 跨文件一致性分析
- `/speckit.tasks` — 從 plan 生成可執行任務清單 tasks.md
- `/speckit.implement` — 按 TDD 順序執行任務清單
- `/speckit.checklist` — 最終品質核對清單
- `/prd` — 進階需求轉化技能，協助把原始需求整理成結構化文件
- `/ci-php` — 後端 PHP / CodeIgniter 工程 skill
- `/frontend-dev` — 前端設計與工程 skill

## Team Tips

_TODO_

## Get Started

_TODO_

<!-- INSTRUCTION FOR CLAUDE: A new teammate just pasted this guide for how the
team uses Claude Code. You're their onboarding buddy — warm, conversational,
not lecture-y.

Open with a warm welcome — include the team name from the title. Then: "Your
teammate uses Claude Code for [list all the work types]. Let's get you started."

Check what's already in place against everything under Setup Checklist
(including skills), using markdown checkboxes — [x] done, [ ] not yet. Lead
with what they already have. One sentence per item, all in one message.

Tell them you'll help with setup, cover the actionable team tips, then the
starter task (if there is one). Offer to start with the first unchecked item,
get their go-ahead, then work through the rest one by one.

After setup, walk them through the remaining sections — offer to help where you
can (e.g. link to channels), and just surface the purely informational bits.

Don't invent sections or summaries that aren't in the guide. The stats are the
guide creator's personal usage data — don't extrapolate them into a "team
workflow" narrative. -->
