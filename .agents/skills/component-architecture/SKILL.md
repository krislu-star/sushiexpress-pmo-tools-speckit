---
name: component-architecture
description: Use when designing or reviewing frontend app structure. Framework-neutral layering for routes/pages, screens, components, stores, types, API adapters, utilities, and constants.
version: 1.0.0-template
alwaysApply: false
---

# Component Architecture

Use this skill when creating or reviewing frontend app structure across any framework profile.

## Layers

| Layer | Location | Responsibility |
|---|---|---|
| **Route layer** | `app/`、`pages/`、`router/` | Thin wrapper: read data, handle navigation, pass props. No UI JSX. |
| **Screen** | `components/{feature}/screens/` | Full-page component, 1:1 with a route. Business UI logic lives here. |
| **UI component** | `components/{feature}/ui/` | Reusable, stateless small components (badges, tags, action buttons). |
| **Layout** | `components/{feature}/layout/` or `components/layout/` | Shell, Sider, Header, content area wrappers. |
| **Store** | `stores/` | UI state only (Zustand / Pinia / NgRx). Never server data. |
| **Type** | `types/` | Shared TypeScript interfaces. Owned here, not scattered in components. |
| **API adapter** | `lib/api/` | axios calls, adapt API response → UI type. Signature never changes. |
| **Mock data** | `lib/mocks/` | Mock values for adapters. Deleted after real API is wired. |
| **Utility** | `lib/utils/` | Pure functions not tied to a feature, store, or API. |
| **Constant** | `constants/` | colors, layout dimensions, typography styles, date formats, UI labels. |

## Dependency Direction

- Route layer depends on stores and screen components.
- Screen components depend on stores (UI state) and query hooks (server data).
- Query hooks depend on API adapters.
- API adapters depend on types and the axios client.
- Utilities must not import stores, screens, or adapters.
- Constants must not import any app-specific code.

## Design Rules

- Keep the route layer thin — no JSX that belongs in a screen.
- Keep screen components focused on one route's business UI.
- Separate server data (TanStack Query / useFetch / useAsyncData) from UI state (Zustand / Pinia).
- API adapter signature is the contract — UI never knows if it talks to a mock or real API.
- Mock data must be removed or replaced when real API is wired; never leave behind as dead code.
- Utility functions extracted to `lib/utils/` must have unit tests.
- Constants centralize magic values — any number, color, or string used in 2+ places belongs here.

## Review Checklist

- Route layer has no UI JSX — only data reads and navigation.
- Screen components contain the feature's business UI and interact with stores/queries.
- No store contains server data (lists, detail records).
- No component contains inline adapter logic or direct `axios.get()` calls.
- All shared TypeScript types are in `src/types/`, not duplicated across files.
- Mock data is in `src/lib/mocks/`, not inside components or adapters.
- Utility functions in `src/lib/utils/` are covered by unit tests.
- No circular dependencies across layers.
- `src/constants/` has colors, layout, typography, and format constants rather than magic values in components.

## Profile-Specific Notes

- **next-app-router**: Server Components fetch data directly; Client Components use TanStack Query. Route layer = `page.tsx`.
- **next-pages-router**: All components are Client Components. Route layer = `pages/*.tsx`. Data fetching via `getServerSideProps` or `useQuery`.
- **vite-react**: No `page.tsx`. Route layer = React Router `<Route element={<Screen />} />`. Auth guard as `ProtectedRoute` component.
- **nuxt**: Route layer = `pages/*.vue` (auto-imported). Composables in `composables/` replace custom hooks. Pinia replaces Zustand.
- **vite-vue**: Route layer = Vue Router route definitions. Pinia stores. Composables in `composables/`.
- **angular**: Route layer = Angular Router. Services replace stores for injectable state. Components have explicit dependency injection.
