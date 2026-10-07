---
name: deployment-template-review
description: Use to review GitHub Actions and Helm deployment scaffolding for frontend apps. Focuses on CI/CD, placeholders, Kubernetes, rendering mode correctness, and release safety.
version: 1.0.0-template
alwaysApply: false
---

# Deployment Template Review

Use this skill before committing changes to `.github/` or `chart/`.

## Review Scope

- GitHub Actions tag workflows (`main.yml`) and reusable deploy workflow (`deploy.yml`).
- PR CI workflow (`ci.yml`).
- Composite actions under `.github/actions/`.
- Helm templates and values files under `chart/`.

## Checks

### GitHub Actions

- Tag-only workflows must not use `github.event.pull_request.head.sha`; use `github.sha` or default checkout behavior.
- `dev-x.y.z`, `stage-x.y.z`, and `x.y.z` tags must map to the correct values files and clusters.
- `APP_NAMESPACE`, `SLACK_CHANNEL`, ECR repository, AWS account/region, chart path, and Dockerfile path must be explicit or placeholdered.
- Stage/prod differences belong in values files, not workflow templates.
- CI workflow must include lint, type-check, and test steps.

### Helm

- Helm templates must not contain stale project names or stale helper names.
- HPA must use `autoscaling/v2`.
- Cluster-scoped resources must be optional or env-specific.
- Frontend apps must NOT have cronjob chart files.

### Rendering Mode Consistency

- **static profiles** (vite-react, vite-vue, angular, next-static, nuxt-static): `containerPort: 80`, health probe `path: /`.
- **standalone profiles** (next-app-router standalone, next-pages-router standalone, nuxt standalone): `containerPort: 3000`, health probe `path: /api/health` (Next.js) or `/_health` (Nuxt).
- Check that `chart/values-*.yaml` container port and probe path match the selected rendering mode.
- nginx `try_files` must route all paths to `index.html` for SPA profiles (vite-react, vite-vue, angular).

### Security Headers (nginx static profiles)

Confirm nginx.conf includes:
- `X-Frame-Options: SAMEORIGIN`
- `X-Content-Type-Options: nosniff`
- `X-XSS-Protection: 1; mode=block`
- `Referrer-Policy: strict-origin-when-cross-origin`

## Validation Commands

- `git diff --check`
- `helm template <release> chart/app -f chart/values-dev.yaml --namespace <namespace>` (after substituting placeholders in a temporary copy)
- Repeat for stage/prod values when they changed.

## Findings To Report

- **Deployment blockers**: invalid workflow, invalid Helm render, wrong checkout ref, stale project name, cronjob files present.
- **Rendering mode mismatch**: container port or probe path does not match the profile's rendering mode.
- **Operational risks**: missing namespace/channel, missing stage/prod values, nginx missing SPA fallback.
- **Follow-up required**: placeholder values that must be replaced for production.
