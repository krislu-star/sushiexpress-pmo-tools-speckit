# Project Constitution

> 本文件是專案的最高治理文件。所有開發決策必須符合此憲法。

---

## Article I — 技術棧約束 (Tech Stack Constraints)

- **允許的技術**: 在 `plan.md` 中明確聲明。
- **禁止的技術**: 任何未在 `plan.md` 中列出的函式庫，使用前必須獲得明確批准。
- **版本鎖定**: 所有依賴必須指定明確版本，禁止使用 `latest` 或浮動版本。

## Article II — 程式碼品質標準 (Code Quality Standards)

- 所有公開函式必須有 JSDoc / docstring 文件。
- 強制型別標注（TypeScript strict mode 或 Python type hints）。
- 偏好函數式、不可變的程式設計風格。
- 單一函式不超過 50 行；超過時必須拆分。

## Article III — 測試策略 (Testing Strategy)

- **NON-NEGOTIABLE**: 所有實作必須遵循 TDD（測試驅動開發）。
- 禁止在測試通過前合併任何功能程式碼。
- 最低測試覆蓋率：80%（unit）、關鍵路徑 100%。
- 測試類型優先順序：unit → integration → e2e。
- 禁止使用 mock 替代真實資料庫連線（整合測試）。

## Article IV — 安全與合規 (Security & Compliance)

- 所有使用者輸入必須在邊界層驗證（永不信任用戶端資料）。
- 絕對禁止在程式碼中硬編碼憑證、金鑰、密碼。
- 敏感資訊統一透過環境變數或 secret manager 管理。
- API 端點預設需要驗證，除非明確標記為公開。

## Article V — 規格優先 (Specification First)

- 所有功能必須先有 `spec.md` 才能開始 `plan.md`。
- 所有 `plan.md` 必須通過憲法閘門檢查才能產生 `tasks.md`。
- 程式碼是規格的輸出，不是反過來。
- `spec.md` 只描述 **WHAT** 和 **WHY**，絕不描述 **HOW**。
- **`plan.md` 必須將前端與後端範圍分開描述**（模板 2.3 節）：兩側各自寫明「負責」與「不負責」，使任一方能單獨看懂自己的工作邊界。
  - 前後端的交界一律以 API 合約定義；無法用契約說清雙方責任者，視為切分不完整，不得進入 `/speckit-tasks`。
  - 單邊功能（只有前端或只有後端）仍須保留另一側並註明「本功能不涉及」，不得整節省略。
  - 實作階段與測試策略須標註歸屬（前端／後端／兩者）。

- **plan 是否拆檔，由 `spec.md` 的 `Owner` 決定**（格式見 Article XIII）：
  - **不拆檔（預設）**：`Owner` 為一人時，只有 `plan.md`，依完整計劃模板撰寫。
  - **拆檔（例外）**：`Owner` 為前後端各一人時：
    - `plan.md` 只放兩邊共用的內容：Phase -1 閘門、架構全貌（元件圖、執行流程）、2.3 前後端範圍切分、API 合約，以及跨兩邊的 ADR、測試策略、安全、部署考量。
    - `plan-frontend.md`／`plan-backend.md` 放各自的 HOW（前端：頁面、元件、狀態管理；後端：資料模型、Schema、業務邏輯），兩份皆須存在。
    - **API 合約只能存在於 `plan.md` 與 `contracts/`**；分邊檔僅得引用，不得另寫一份。契約變更須同步通知另一邊。
    - 分邊檔不得重複寫任何專案管理欄位（見 Article XIII）。

## Article VI — 分支策略與發布管理 (Branching Strategy & Release Management)

- 功能分支命名: `NNN-feature-name`（如 `001-user-auth`）。
- 每個功能分支對應 `specs/NNN-feature-name/` 目錄。
- 禁止直接推送到 `main`/`master` 分支。
- **實作必須在功能分支上進行**：開始實作前必須先切換至該功能對應的 `NNN-feature-name` 分支，不得在 `main`/`master` 上直接實作或提交功能程式碼。
  - `/speckit-specify` 會自動建立並切換分支；若分支已存在，實作前須自行 `git switch` 回該分支。
  - `plan.md`／`tasks.md` 的產生與實作皆以**當前分支名**推導 `specs/<分支名>/`，分支不符時產物會落在錯誤目錄。
  - 文件類變更（憲法、`docs/`、模板）同樣須開分支並經 PR 合併，不得直接提交至 `main`/`master`。
- 禁止 AI 執行 `git push`（任何形式）。
- 禁止 AI 執行 `git merge` 到 `develop` 或 `master` 分支。
- **上線發布**：合併至 `master` 時，必須建立版本 tag，且該 tag 必須明確記錄各 submodule（`frontend`、`cms`、`backend`）對應的 tag 版本，確保每次上線版本可完整重現。
- **禁止使用 git worktree**：不得執行 `git worktree add`，亦不得以 AI 代理的 worktree／隔離（isolation）模式建立額外工作目錄。
  - 理由：多重工作目錄會讓同時存在的分支快速膨脹，難以掌握目前處於哪個分支、變更歸屬何處。
  - 所有開發一律在**單一工作目錄**內以分支切換進行；需要並行時，先 commit 或 stash 目前工作再 `git switch`。
  - 同一時間進行中的功能分支數不得超過 Article VII 的並行上限（3 個）。

## Article VII — 簡單性原則 (Simplicity Principle)

- 初始專案最多 3 個並行功能；超過需要書面說明。
- 優先使用框架原生功能，避免額外的抽象層包裝。
- 三行相似程式碼優於過早的抽象化。

## Article VIII — 文件即程式碼 (Docs as Code)

- `specs/` 目錄必須與程式碼同步版本控制。
- 規格文件變更需要 PR review，與程式碼變更相同流程。
- 已廢棄的規格必須標記 `[DEPRECATED]`，不得直接刪除。

## Article IX — AI 協作準則 (AI Collaboration Guidelines)

- AI 生成的程式碼必須經過人工審查後才能合併。
- 使用 `[NEEDS CLARIFICATION]` 標記所有不確定的規格點。
- 禁止 AI 在沒有完整 `spec.md` 和 `plan.md` 的情況下直接生成實作程式碼。
- 禁止 AI 執行任何破壞性的 git 操作（詳見 Article VI）。

## Article X — 語言規範 (Language Standard)

- 所有規格文件（`spec.md`、`plan.md`、`tasks.md`、`constitution.md` 等）一律使用**繁體中文**撰寫。
- AI 助手與使用者的對話一律使用**繁體中文**回應。
- 程式碼內的識別符（變數名、函式名）使用英文，僅文件與註解使用繁體中文。

## Article XI — 基礎設施慣例 (Infrastructure Conventions)

- **AWS S3 存取路徑**：所有 S3 資源的公開 URL 必須包含 `/s3/` 路徑前綴。
  - 正確範例：`https://theme-builder.kiitzu.ninja/s3/Template/20251226_122040625-home_wb01.png`
  - 錯誤範例：`https://theme-builder.kiitzu.ninja/Template/20251226_122040625-home_wb01.png`
  - 此規則適用於所有生成、硬編碼或組合 S3 URL 的程式碼。

## Article XII — 模組保護 (Module Protection)

- **CMS 模組為唯讀**：`cms/` submodule 的程式碼禁止任何修改。
- AI 及開發人員不得對 `cms/` 目錄內的檔案進行新增、編輯或刪除。
- 若功能需求涉及 CMS，必須透過 API 或設定介面實作，不得直接改動 CMS 原始碼。
- 任何例外情況需取得明確的書面授權。

## Article XIII — 任務書寫規範 (Task Authoring Standard)

任務清單是全 org PM 視圖（看板、甘特圖、WIP、完成統計）的唯一任務資料來源：
不拆檔時為 `tasks.md`，拆檔時為 `tasks-frontend.md`／`tasks-backend.md`。
一律由勾選狀態推導、忽略 `Status` 標頭；負責人與排程則取自 `spec.md` 標頭。
書寫不一致，下游數字即為錯誤。

- **專案管理欄位只寫在 `spec.md` 標頭**：`Owner`、`DependsOn`、`Start`、`Estimate`、`Due`
  整個 feature 各一份，不分前後端；plan／tasks 的任何檔案皆不得重複填寫。
  - `Owner` 為**實際負責執行的工程師**（非 PM），於 `/speckit-specify` 時由 PM 填寫。
  - **一人負責（預設，不拆檔）**：寫一人、不加標註，如 `@bob`。
    不論只做前端、只做後端或兩邊都做，皆同。
  - **前後端由不同人負責（例外，拆檔）**：恰好兩人，括號標註所屬邊：
    `@alice (frontend), @bob (backend)`。括號值對應分邊檔的檔名後綴，PM 視圖據此將任務對應到人。
  - 多人卻未標註、標註不完整、或出現 `frontend`／`backend` 以外的標註者，視為格式錯誤。

- **不拆檔時**：任務寫在 `tasks.md`，負責人即唯一的 `Owner`。

- **拆檔時，每條任務恰好屬於一邊**：
  - 任務只能寫在 `tasks-frontend.md` 或 `tasks-backend.md`，兩份皆須存在。
  - 需要兩邊合作的工作（聯調、契約確認等）必須拆成兩條分邊任務，各自歸屬；
    跨檔依賴寫在任務文字中（如「依賴 TASK-BE-010」）。
  - 任務的負責人 = 該分邊檔對應的 `Owner`，不在任務文字中另寫人名。
  - `tasks.md` 仍須存在，但改為**總覽、不含任務**：不得有任何勾選項目，
    內容為指向分邊檔的連結、跨邊依賴順序、里程碑（以任務編號定義）。

- **拆檔與否須在任務產出前定案**：
  - `/speckit-tasks` 產出任務清單前，可修改 `Owner` 並重新執行 `/speckit-plan`。
  - 任務清單產出後**不得轉換**（不得把 `tasks.md` 的任務搬到分邊檔，或反之）：
    搬移與重新編號會使由 git 推導的完成時間斷裂。
  - 之後才需要由另一人負責另一邊時，**另開新 spec**，並以 `DependsOn` 指向原 spec。

- **一致性**：plan／tasks 的檔案配置必須與 `Owner` 相符；不一致者不得進入 `/speckit-implement`。

- **五個狀態**：`[ ]` to-do / `[~]` in progress / `[r]` in review /
  `[c]` waiting for client / `[x]` done。
  - 任務必須寫成 `-` 或 `*` 清單項目。寫成標題（`###`）者不會被解析，
    不計入任何統計。code block（```）內的內容亦不視為任務。
  - `[~]` 僅代表「現在有人在動這一條」。
  - `[r]` 涵蓋所有等待關卡放行的情況（code review、驗證、內部環境阻塞）。
  - `[c]` 專指等待客戶回覆或決策。
  - `[r]` 與 `[c]` 必須在任務文字中寫出阻塞對象（PR／MR 編號、環境名稱、
    等待中的對口），使他人能據以追蹤。
  - 可選或決定跳過者維持 `[ ]`，並將原因寫在任務文字中，不得以勾選狀態表達。
  - 既有的 `[P]`／`[S]`（可平行／須循序）與狀態無關，位置在狀態標記之後。

- **先建立後打勾**：任務必須先以 `[ ]` 建立並提交，完成時才改為 `[x]`。
  - 禁止在新增任務時直接寫成 `[x]`，於同一個 commit 內建立並完成亦不允許。
  - 完成時間由「改為 `[x]` 的那次 commit」推導；無此轉換者不計入完成統計。
  - 工作已完成才補文件時：先以 `[ ]` 提交，下一個 commit 再打勾。

- **任務編號**：於同一 spec 內唯一、不重用。
  - 不拆檔：`**TASK-NNN**`。
  - 拆檔：前端 `**TASK-FE-NNN**`、後端 `**TASK-BE-NNN**`，兩邊各自遞增。
  - 子任務可用字母後綴（`TASK-006a`、`TASK-BE-006a`），視為獨立編號。
  - 此編號為任務的穩定識別碼，供跨工具比對；缺編號者無法追蹤完成時間。

- **完成時間**：由 git history 推導，禁止在文件中手寫完成日期。

---

*最後更新: 2026-09-14*
*版本: 2.0.0*
