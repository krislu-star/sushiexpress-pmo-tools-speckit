---
name: frontend-template-bootstrap
description: Use when turning this template repo into a new frontend app. Applies common placeholders, deployment scaffolding, Helm values, and a selected framework profile without assuming a specific framework.
version: 1.0.0-template
alwaysApply: false
---

# Frontend Template Bootstrap

Use this skill to instantiate a new frontend app from this template.
Bootstrap must be infrastructure-first: confirm repository and deployment metadata, update project infrastructure files, then ask for the framework profile and scaffold application code last.

## Input Collection Order

Ask for missing values one at a time in this order. Do not ask for `framework_profile` or `ui_stack` before infrastructure values are confirmed.

1. `REPO_NAME`
2. Optional project purpose/description for `README.md`
3. `APP_NAME`
4. `APP_NAMESPACE`
5. `SLACK_CHANNEL`
6. `AWS_ACCOUNT_ID`
7. `AWS_REGION`
8. `SECRET_NAME`
9. After README, GitHub Actions, and Helm chart metadata are updated — use the `AskUserQuestion` tool (single-select) to ask for `framework_profile`. If the user selects "I have questions", explain key differences then call `AskUserQuestion` again.

   Options:
   - **Next.js App Router** (`next-app-router`): Next.js 14+ 官方推薦架構。以 Server Components 為核心，支援 SSR / SSG / API Routes。適合需要 SEO、動態資料或 server-side logic 的 web app。部署支援 standalone（Node）或 static（nginx）。
   - **Nuxt** (`nuxt`): Vue 3 的 meta-framework，定位類似 Next.js。支援 SSR、SSG、Vue Server Components。適合 Vue 團隊的 greenfield 專案，或需要 SEO 的 Vue app。部署支援 standalone 或 static。
   - **Vite + React** (`vite-react`): 純 SPA，無 SSR。Vite HMR 極快，適合 admin dashboard 或不需要 SEO 的內部工具。固定 static 部署（nginx）。
   - **Vite + Vue** (`vite-vue`): 同 Vite + React，改用 Vue 3 Composition API。適合偏好 Vue 生態的團隊做 dashboard 或內部工具。固定 static 部署（nginx）。
   - **Angular** (`angular`): 企業級框架，強型別 + Dependency Injection。適合大型團隊或既有 Angular 生態的專案。固定 static 部署（nginx）。
   - **I have questions / help me decide**: 說明各框架差異後，重新呼叫 `AskUserQuestion`。

10. For `next-app-router`, `nuxt` — use `AskUserQuestion` (single-select) to ask for `rendering_mode`:
    - **standalone**: 需要 Node.js runtime。適合有 API Routes 或 SSR 動態資料的情境。PORT 3000，健康檢查走 app 路由（如 `/api/health` 或 `/_health`）。
    - **static**: 純靜態檔，nginx 伺服。適合完全前端、不需要 server runtime 的情境。PORT 80，健康檢查走 `/`。
11. For `vite-react`, `vite-vue`, `angular` — skip rendering_mode (always static)
12. Use `AskUserQuestion` (single-select) to ask for `ui_stack`. Options depend on `framework_profile`:

    `next-app-router` / `vite-react`:
    - **Ant Design (`antd`)**: 開箱即用的企業級元件庫，元件數量多，中後台常用，整合成本低。
    - **Tailwind CSS + shadcn/ui (`tailwind-shadcn`)**: utility-first + 元件以複製貼上形式加入，不依賴外部套件版本，客製化彈性最高。
    - **無 UI Library — CSS Modules (`none`)**: 不依賴任何第三方元件庫，直接移植 prototype 的 CSS。適合從 Claude design / 純 HTML prototype 建構，視覺還原度最高，無元件轉換成本。

    `nuxt` / `vite-vue`:
    - **Element Plus (`element-plus`)**: Vue 生態的企業級元件庫，功能類似 Ant Design，支援自動 import。
    - **Tailwind CSS + Headless UI (`tailwind-headlessui`)**: utility-first + 無預設樣式但有完整 accessibility（ARIA），最大客製化空間。
    - **無 UI Library — CSS Modules (`none`)**: 不依賴任何第三方元件庫，直接移植 prototype 的 CSS。適合從 Claude design / 純 HTML prototype 建構，視覺還原度最高，無元件轉換成本。

    `angular`:
    - **Angular Material (`angular-material`)**: Angular 官方 Material Design 元件庫，與 Angular CLI 整合最佳。
    - **Tailwind CSS (`tailwind`)**: 純 utility-first，最大客製化彈性，適合已有設計稿的專案。
    - **無 UI Library — CSS Modules (`none`)**: 不依賴任何第三方元件庫，直接移植 prototype 的 CSS。適合從 Claude design / 純 HTML prototype 建構，視覺還原度最高，無元件轉換成本。
13. Derive `APP_PORT`: standalone → `3000`, static → `80`

## Required Reads

Before editing infrastructure files:

- `AGENTS.md`
- `profiles/README.md`
- `.github/workflows/main.yml`, `.github/workflows/deploy.yml`
- `chart/app/values.yaml`, `chart/values-dev.yaml`, `chart/values-stage.yaml`, `chart/values-prod.yaml`

After `framework_profile` is confirmed:

- `profiles/<framework_profile>/README.md`
- `profiles/<framework_profile>/skills/<profile-name>/SKILL.md`

## Bootstrap Steps

1. Ask for `REPO_NAME` first, then one-by-one for remaining infrastructure settings.
2. Register `TASK-000-bootstrap.md` in `requirements/tasks/_index.md`.
3. Create `requirements/tasks/TASK-000-bootstrap.md` before editing generated files.
4. Record all confirmed settings in `TASK-000-bootstrap.md`.
5. Update `README.md` with `REPO_NAME`, description, settings, and tag deploy conventions.
6. Replace all `{replace_repo_name}` placeholders in Helm chart names/helpers/templates.
7. Replace environment placeholders: `{replace_aws_account_id}`, `{replace_aws_region}`.
8. Set `.github/workflows/main.yml` env values: namespace, Slack channel, ECR repository, Dockerfile path, chart path.
9. Keep dev/stage/prod differences in `chart/values-*.yaml`.
10. Ask for `framework_profile` only after infrastructure files are updated.
11. Read `profiles/<framework_profile>/README.md` and copy templates: Dockerfile(s), Makefile, nginx.conf (if static).
12. Update Helm health probe path and container port from profile + rendering mode.
13. Ask for `ui_stack` and record in `TASK-000-bootstrap.md`.
13.5. If no prototype exists, add the following unchecked item to `TASK-000-bootstrap.md`: `[ ] Run /anti-ai-design to lock visual identity before building UI pages`. Do NOT run it during bootstrap — it belongs before the first real BUILD task.
14. Copy scaffold source files from `profiles/<framework_profile>/scaffold/src/` into the project's `src/` (or `app/` for Next.js App Router). For ui_stack variants (`-antd` / `-tailwind` suffix), copy the matching variant and rename to the canonical filename (e.g. `layout-antd.tsx.tmpl` → `app/layout.tsx`). Substitute all `{{VARIABLE}}` placeholders with confirmed values: `REPO_NAME`, `APP_NAME`, `PROTECTED_PREFIX`, `LOGIN_PATH`, `API_URL_ENV`.
15. For profiles without a scaffold directory (nuxt, vite-vue, angular), hand-write the entry point, layout shell, auth guard, and API client per `profiles/<framework_profile>/README.md`.
16. Copy `profiles/<framework_profile>/skills/<profile-name>/` into `.agents/skills/<profile-name>/` in the generated project. This is the day-to-day development skill for the selected profile.
16. Mark each checklist item `[ ]` → `[x]` immediately after completing.
17. If work is interrupted, resume by reading `TASK-000-bootstrap.md` and continuing from first unchecked item.
18. Rewrite `README.md` and `AGENTS.md` from template guidance to project-specific docs.
19. Run post-bootstrap cleanup checklist.
20. Remove `.agents/skills/frontend-template-bootstrap/` from the generated repo after bootstrap is complete.
21. Verify initialization is complete: profile scaffold exists, README and AGENTS.md describe the generated project, deploy follow-ups recorded, skills reduced.
22. Tell the user initialization is complete, then ask whether to remove `profiles/`.

## Bootstrap Progress Checklist

Every generated app must include a persistent bootstrap checklist in `requirements/tasks/TASK-000-bootstrap.md`.

Minimum shared checklist items:

- [ ] Confirm `REPO_NAME`
- [ ] Confirm optional project purpose/description
- [ ] Confirm `APP_NAME`, `APP_NAMESPACE`, `SLACK_CHANNEL`, `AWS_ACCOUNT_ID`, `AWS_REGION`, `SECRET_NAME`
- [ ] Update `README.md` with project name, description, and deploy tag conventions
- [ ] Replace `{replace_repo_name}`, AWS, and namespace placeholders
- [ ] Configure GitHub Actions: ECR repository, Dockerfile path, chart path, namespace, Slack channel
- [ ] Configure Helm chart names, environment values
- [ ] Confirm `framework_profile`
- [ ] Confirm `rendering_mode` (for Next.js / Nuxt profiles)
- [ ] Confirm `ui_stack`
- [ ] Copy Dockerfile template from `profiles/<framework_profile>/templates/` to project root
- [ ] Copy Makefile template to project root
- [ ] Copy nginx.conf template to project root (static profiles only)
- [ ] Update Helm `containerPort` and health probe path from profile + rendering mode
- [ ] Add follow-up item: run `/anti-ai-design` before first BUILD task (if no prototype exists)
- [ ] Copy scaffold files from `profiles/<framework_profile>/scaffold/src/` and substitute `{{VARIABLE}}` placeholders
- [ ] Select correct ui_stack variant for entry/layout/providers files; rename to canonical filenames
- [ ] Copy `profiles/<framework_profile>/skills/<profile-name>/` into `.agents/skills/<profile-name>/`
- [ ] Run `make type-check` (tsc/vue-tsc/ng) — pass or document blockers
- [ ] Run `make lint` — pass or document blockers
- [ ] Rewrite `README.md` as project-specific docs (not template guidance)
- [ ] Rewrite `AGENTS.md` as project-specific guidance
- [ ] Remove `.agents/skills/frontend-template-bootstrap/` from generated repo
- [ ] Record deploy follow-ups: ACM ARN, ingress host, real AWS values
- [ ] Verify initialization complete and ask whether to remove `profiles/`

## Post-Bootstrap Cleanup

- Convert `README.md` to project docs: local commands, env setup, deploy conventions.
- Convert `AGENTS.md` to project guidance: framework, architecture, profile-specific rules.
- Remove `.agents/skills/frontend-template-bootstrap/` after bootstrap is complete.
- Add unchecked follow-up items to `TASK-000-bootstrap.md` for placeholder values not yet production-ready.

## Final Bootstrap Action

`profiles/` must remain until all initialization work is complete.

After everything is complete:
- Tell the user initialization is complete.
- Note that `profiles/` is template-only scaffolding no longer needed for generated repos.
- Ask whether to remove `profiles/`.
- Remove only after explicit approval.

## Validation

- Run `git diff --check`.
- Run `helm template <release> chart/app -f chart/values-dev.yaml --namespace <namespace>` after substituting placeholders.
- Repeat for stage/prod values.
- Confirm health probe path matches: standalone → `/api/health` or `/_health`; static → `/`.

## Do Not

- Do not ask for `framework_profile` before infrastructure settings and README/GitHub/Helm placeholders are handled.
- Do not create source directories before `framework_profile` is confirmed.
- Do not mix React/Vue/Angular-specific scaffold unless the selected profile matches.
- Do not add cronjob chart files — frontend apps never have scheduled jobs.
- Do not remove `profiles/` from a generated repo before initialization is complete or without explicit user approval.
