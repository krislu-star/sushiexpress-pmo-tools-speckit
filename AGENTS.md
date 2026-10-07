# Speckit — 規格驅動開發框架

本專案使用 **Spec-Driven Development (SDD)** 方法論。在開始任何開發工作之前，請遵循以下原則和工作流程。

## 核心原則

> 規格是主要的工件。程式碼是規格的輸出，不是反過來。

- `spec.md` 只描述 **WHAT** 和 **WHY**，絕不描述 **HOW**
- `plan.md` 描述 **HOW**（技術架構），必須符合 `constitution.md` 的約束
- `tasks.md` 是可執行的任務清單，遵循 TDD 順序
- 所有開發必須先有規格，再有計劃，再有任務，最後才是程式碼

## 目錄結構

```
speckit-template/
├── frontend/                   # Git submodule（爭鮮 PMO 儀表板，唯一的 submodule）
├── .gitmodules                 # Submodule URL 設定
├── .specify/
│   ├── memory/
│   │   └── constitution.md     # 專案憲法（最高治理文件）
│   ├── templates/
│   │   ├── spec-template.md            # 功能規格模板
│   │   ├── plan-template.md            # 技術計劃模板（不拆檔，預設）
│   │   ├── tasks-template.md           # 任務清單模板（不拆檔，預設）
│   │   ├── plan-shared-template.md     # 拆檔：共用計劃（範圍切分、API 合約）
│   │   ├── plan-frontend-template.md   # 拆檔：前端計劃
│   │   ├── plan-backend-template.md    # 拆檔：後端計劃
│   │   ├── tasks-overview-template.md  # 拆檔：任務總覽（不含任務）
│   │   ├── tasks-frontend-template.md  # 拆檔：前端任務清單
│   │   └── tasks-backend-template.md   # 拆檔：後端任務清單
│   └── scripts/
│       └── bash/               # 自動化腳本
│           ├── common.sh
│           ├── create-new-feature.sh  # 第二參數可選 frontend|backend（cms 唯讀，禁用）
│           ├── setup-plan.sh
│           └── check-prerequisites.sh
├── .agents/
│   └── skills/                 # Agent Skills 實體位置（跨工具共用）
│       ├── speckit-constitution/SKILL.md
│       ├── speckit-specify/SKILL.md
│       ├── speckit-clarify/SKILL.md
│       ├── speckit-plan/SKILL.md
│       ├── speckit-analyze/SKILL.md
│       ├── speckit-tasks/SKILL.md
│       ├── speckit-implement/SKILL.md
│       ├── speckit-checklist/SKILL.md
│       ├── speckit-converge/SKILL.md      # 收斂剩餘工作到 tasks.md
│       └── speckit-taskstoissues/SKILL.md # 任務轉 GitHub Issues
├── .claude/
│   └── skills -> ../.agents/skills  # symlink，讓 Claude Code 讀得到上面的 skills
├── specs/                      # 所有功能規格（版本控制）
│   │                           # 編號跨模組統一遞增，一律放在 specs/ 根目錄下
│   └── NNN-feature-name/       # 不分 backend / frontend / cms / shared 子資料夾
│       ├── spec.md             # Owner 一人 → 不拆檔；前後端各一人 → 拆檔（憲法 Article XIII）
│       ├── plan.md             # 不拆：完整計劃｜拆檔：共用內容與 API 合約
│       ├── tasks.md            # 不拆：任務（TASK-NNN）｜拆檔：總覽，不含任務
│       ├── plan-frontend.md    # 僅拆檔時
│       ├── plan-backend.md     # 僅拆檔時
│       ├── tasks-frontend.md   # 僅拆檔時（TASK-FE-NNN）
│       ├── tasks-backend.md    # 僅拆檔時（TASK-BE-NNN）
│       └── contracts/
│           └── openapi.yaml    # （後端 API 規格用）
├── AGENTS.md                   # 本文件（AI 代理說明，Claude Code／Codex／Cursor 共用）
└── CLAUDE.md                   # 僅導向本文件（Claude Code 的讀取入口），不另外維護內容
```

## Git Submodule 設定

本專案只有一個 submodule：

| 名稱 | 路徑 | Branch |
|------|------|--------|
| 爭鮮 PMO 儀表板（`Kiitzu/sushiexpress-pmo-tools-web`） | `frontend/` | `master` |

> 2026-10-07 起移除 `cms`、`backend`、`themebuilder` 三個 submodule。frontend 的 UI 元件是當初自 `cms@0a0a5e2c` 複製而來，不再需要 cms 原始碼。

### 第一次加入 Submodule

> **重要**：只編輯 `.gitmodules` 不夠，必須用 `git submodule add` 才會寫入 git index。

```bash
git submodule add git@github.com:Kiitzu/sushiexpress-pmo-tools-web.git frontend
git add .gitmodules frontend
git commit -m "chore: add frontend submodule"
```

### Clone 後初始化

```bash
# clone 時一併初始化
git clone --recurse-submodules <this-repo-url>

# 或 clone 後再初始化
git submodule update --init --recursive
```

### 更新 Submodule 到最新

```bash
# 依 .gitmodules 的 branch 設定拉取遠端最新（本專案為 master）
git submodule update --remote

# 或對每個 submodule 執行 pull
git submodule foreach git pull
```

> **注意**：`frontend` 追蹤 `master`，以 `.gitmodules` 的 `branch` 設定為準；
> `git submodule update --remote` 會依該設定拉取，不需手動指定分支。
>
> ```bash
> # 切回追蹤分支並更新
> git -C frontend switch master && git -C frontend pull
> git add frontend
> git commit -m "chore: sync frontend submodule"
> ```

### 更換 Submodule

> **重要**：三個步驟缺一不可，少一個會在 `git submodule add` 時報錯。

```bash
# 1. 移除舊的（以 frontend 為例）
git submodule deinit -f frontend   # 清除 .git/config 登記 + 清空目錄
git rm -f frontend                 # 從 git index 移除
rm -rf .git/modules/frontend       # 刪除 git 快取的 submodule 資料

# 2. 加入新的
git submodule add <new-repo-url> frontend

# 3. Commit
git add .gitmodules frontend
git commit -m "chore: replace frontend submodule"
```

如果只是**換 URL**（路徑不變），可直接編輯 `.gitmodules` 再同步：

```bash
# 編輯 .gitmodules 改 URL 後
git submodule sync
git submodule update --init
git add .gitmodules
git commit -m "chore: update frontend submodule url"
```

## 工作流程

```
/speckit-constitution  →  建立/更新專案憲法
         ↓
/speckit-specify       →  描述功能需求（生成 spec.md）
         ↓
/speckit-clarify       →  （可選）澄清模糊需求
         ↓
/speckit-plan          →  建立技術計劃（生成 plan.md）
         ↓
/speckit-analyze       →  （可選）一致性檢查
         ↓
/speckit-tasks         →  生成任務清單（生成 tasks.md）
         ↓
/speckit-implement     →  執行實作（TDD）
         ↓
/speckit-converge      →  （可選）收斂剩餘工作到 tasks.md
         ↓
/speckit-checklist     →  最終品質驗證
```

> 指令現以 **Agent Skills** 提供，實體位置在 `.agents/skills/`，`.claude/skills` 是指向它的 symlink。輸入 `/speckit-` 開頭即可觸發，或由 Claude 依情境自動選用。

## 可用指令

| 指令 | 用途 |
|------|------|
| `/speckit-constitution` | 建立/更新專案憲法和開發原則 |
| `/speckit-specify <描述>` | 將功能描述轉為完整 spec.md |
| `/speckit-clarify` | 澄清 spec.md 中的模糊點 |
| `/speckit-plan` | 根據 spec 生成技術計劃 |
| `/speckit-analyze` | 跨文件一致性分析 |
| `/speckit-tasks` | 從 plan 生成可執行任務清單 |
| `/speckit-implement` | 按 TDD 執行任務清單 |
| `/speckit-converge` | 評估程式碼落差，附加剩餘任務到 tasks.md |
| `/speckit-taskstoissues` | 把 tasks.md 任務轉成 GitHub Issues |
| `/speckit-checklist` | 最終品質核對清單 |

## 分支命名規範

```
NNN-feature-name
```

NNN 跨所有模組（backend / frontend / cms / shared）**統一遞增**，不加模組 prefix。

例如：
- `001-user-authentication`
- `002-product-search`
- `003-shopping-cart`

## 憲法

請先閱讀 `.specify/memory/constitution.md`。所有開發決策必須符合憲法中的條款。

在 `plan.md` 中，**Phase -1** 是憲法閘門檢查，必須在繼續之前通過所有檢查。

## 給 AI 助手的說明

1. **永遠先讀 constitution.md**，了解專案約束
2. **使用對應的斜線指令**，不要跳過工作流程步驟
3. **在 spec.md 中**，只描述業務需求，不提技術實作
4. **TDD 是不可協商的**：測試必須在實作之前存在
5. **標記 `[NEEDS CLARIFICATION]`**，不要假設或猜測

## 參考來源

- [AI 時代，一定要學會使用 GitHub spec kit — SDD 規格驅動開發 | Milk Midi](https://milkmidi.medium.com/ai-%E6%99%82%E4%BB%A3-%E4%B8%80%E5%AE%9A%E8%A6%81%E5%AD%B8%E6%9C%83%E4%BD%BF%E7%94%A8-github-spec-kit-sdd-%E8%A6%8F%E6%A0%BC%E9%A9%85%E5%8B%95%E9%96%8B%E7%99%BC-f2df57cfdf3c)
- [GitHub - github/spec-kit: Toolkit to help you get started with Spec-Driven Development](https://github.com/github/spec-kit)
- [Spec-Driven Development | github/spec-kit | DeepWiki](https://deepwiki.com/github/spec-kit/3-spec-driven-development)
- [Initializing a Project | github/spec-kit | DeepWiki](https://deepwiki.com/github/spec-kit/2.2-quick-start-tutorial)
- [Diving Into Spec-Driven Development With GitHub Spec Kit | Microsoft for Developers](https://developer.microsoft.com/blog/spec-driven-development-spec-kit)
- [GitHub - doggy8088/spec-kit: 幫助您開始規格驅動開發的工具包](https://github.com/doggy8088/spec-kit)
- [Understanding Spec-Driven-Development: Kiro, spec-kit, and Tessl | Martin Fowler](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html)

## Skills 維護規則

`.agents/skills/` 內含 web-experience-audit 與 web-cms-spec-to-quote-items 兩支 skill。這兩支同時也存在於 kiitzu-forecast（若該 repo 尚未搬移，仍在 `.claude/skills/`；兩處 fork 線分別供開發案與評估案使用），兩邊結構一致。

- 目前**兩邊各自獨立維護、無自動同步**；修改 skill 時，兩處的**結構與內容必須保持一致**（改一邊記得同步改另一邊）。
- skill 實體放在 `.agents/skills/`（工具中立的位置），`.claude/skills` 為指向它的 symlink，Claude Code 照常載入；其他 agent 工具可在各自的路徑另建 symlink。
- **未來計畫**：將兩支 skill 抽成獨立 repo（`kiitzu-skills`），由本 repo 與 kiitzu-forecast 以 git submodule 於 `.agents/skills` 引用，收斂為單一維護點、消除手動保持一致的負擔。

## 沙箱與權限

團隊共用的 `.claude/settings.json` 保留 `permissions` 規則，已移除整個 `sandbox` 區塊，讓 PR review 不再依賴專案強制啟用的沙箱。此變更也適用於本機；實際沙箱狀態仍取決於個人或組織管理設定。

需要本機沙箱時，可在已 gitignore 的 `.claude/settings.local.json` 自行設定。調整沙箱前請閱讀 [`docs/ai-agent-sandbox.md`](docs/ai-agent-sandbox.md) 的歷史設計與平台限制；其中的舊驗收結果不代表目前共用設定仍提供那些保護。
