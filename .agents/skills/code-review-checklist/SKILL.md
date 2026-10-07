---
name: code-review-checklist
description: Use before finishing or merging frontend work. Reviews implementation against FRONTEND_RULE_COMMON and profile-specific RULE for behavior, security, design token usage, architecture, and prototype fidelity.
version: 1.0.0-template
alwaysApply: false
---

# Frontend Code Review Checklist

Use this skill for self-review or when preparing work for human review.

## Review Inputs

- User request or approved spec.
- Changed files and diff.
- Selected `framework_profile` and `ui_stack`.
- Commands run and their results.
- Known risks, assumptions, and deferred items.

## Findings First

Report issues before summaries, ordered by severity:

- **Critical**: security issue (exposed secrets, no auth guard, sensitive data in URL), broken deploy, invalid Helm/workflow.
- **Important**: prototype fidelity violation, missing loading/error states, wrong layer boundary, missing required config, unreplaced placeholder.
- **Minor**: naming, constant extraction, missing test for utility function, stale mock data.

## Checklist

### Architecture (FRONTEND_RULE_COMMON §2)

- [ ] Route layer has no UI JSX — thin wrapper only
- [ ] Business UI logic is in `screens/`, not `pages/` or `app/`
- [ ] No server data in Zustand / Pinia stores
- [ ] Auth guard exists and protects the correct routes
- [ ] TypeScript types in `src/types/`, not scattered in components

### API & Data (FRONTEND_RULE_COMMON §3)

- [ ] API calls use the axios adapter pattern (`src/lib/api/`)
- [ ] Mock data is in `src/lib/mocks/`, adapter signature unchanged
- [ ] Every API call has loading and error state handling
- [ ] No `as any` TypeScript cast

### Design Tokens (FRONTEND_RULE_COMMON §5)

- [ ] `src/constants/colors.ts`, `layout.ts`, `typography.ts`, `formats.ts` exist and have values
- [ ] No hardcode hex/rgba in components
- [ ] No magic numbers in inline styles
- [ ] No `<style>` tags injected in JSX/template
- [ ] Dates use dayjs + `src/constants/formats.ts`

### Prototype Fidelity

- [ ] Visual structure matches prototype (layout, navigation, brand colors)
- [ ] UI text is verbatim copy from prototype
- [ ] Component types not swapped from prototype (Table → Collapse requires DEVIATION_REPORT)
- [ ] `comparison/DEVIATION_REPORT.md` exists and records all deviations

### Security

- [ ] No quick login / test backdoor outside `DEV` guard
- [ ] No sensitive info in URL query strings
- [ ] `.env.example` updated for every new env variable
- [ ] No secrets, credentials, or env values committed

### Refactor Pass (FRONTEND_RULE_COMMON §6)

- [ ] No style object repeated 3+ times without extraction
- [ ] No JSX structure repeated 3+ times without extraction
- [ ] No logic function repeated 2+ times without extraction to `src/lib/utils/`
- [ ] Every `src/lib/utils/` function has a `*.test.ts` with happy path + edge cases

### Framework-Specific

- [ ] Profile-specific rules followed (read `.agents/skills/<framework_profile>/SKILL.md`)
- [ ] Forms use the profile's recommended library (React Hook Form + Zod / VeeValidate + Zod / Angular Reactive Forms)
- [ ] No prototype remnants (`setTimeout` delays, hardcode account names)

### Deployment

- [ ] `npx tsc --noEmit` (or `vue-tsc` / `nuxi typecheck`) passes
- [ ] `npm run lint` passes
- [ ] Dockerfile matches selected rendering mode
- [ ] Helm values container port and probe path match rendering mode

## Review Output

- Findings with file/line references when possible.
- Open questions or assumptions.
- Verification performed.
- Short change summary only after findings.
