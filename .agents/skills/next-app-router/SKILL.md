---
name: next-app-router
description: Use for projects created with the next-app-router profile. Covers App Router conventions, Server vs Client Components, auth guard, state management, forms, UI stack setup, and scaffold checklist.
version: 1.0.0-template
alwaysApply: false
---

# Next.js App Router

Use this skill only for projects created with `framework_profile: next-app-router`.

Read this skill alongside `.agents/skills/frontend-workflow/FRONTEND_RULE_COMMON.md`.
FRONTEND_RULE_COMMON.md covers API adapter pattern, design tokens, TypeScript rules, refactor pass, and prototype fidelity. This file covers App Router specific conventions only.

## Defaults

- Framework: Next.js 14+ with App Router
- Entry layout: `src/app/layout.tsx`
- Providers: `src/app/providers.tsx`
- Auth guard: `src/middleware.ts`
- API client: `src/lib/api/client.ts`
- Health route (standalone): `src/app/api/health/route.ts` → GET `/api/health`
- Dev port: `3000`
- standalone container port: `3000`, health probe: `/api/health`
- static container port: `80`, health probe: `/`

## Commands

| Command | Description |
|---|---|
| `make install` | Install dependencies |
| `make dev` | Start dev server (port 3000) |
| `make build` | Production build |
| `make lint` | ESLint |
| `make type-check` | `tsc --noEmit` |
| `make test` | Run test suite |
| `make docker-build` | Build Docker image locally |

## Folder Structure

```
src/
├── app/                        # App Router — page.tsx / layout.tsx / error.tsx only
├── components/
│   └── {feature}/
│       ├── screens/            # Full-page components (1:1 with routes)
│       ├── ui/                 # Reusable small components
│       └── layout/             # Shell, Sider, Header
├── stores/                     # Zustand UI state stores
├── types/                      # Shared TypeScript types
├── lib/
│   ├── api/                    # axios instance + adapter functions
│   ├── mocks/                  # Mock data (delete after real API is wired)
│   └── utils/                  # Pure utility functions + *.test.ts
└── constants/
    ├── colors.ts
    ├── layout.ts
    ├── typography.ts
    └── formats.ts
```

## A. Route Structure

Each route corresponds to a thin `page.tsx` that only reads data from store/query, handles navigation, and passes props to a screen component. Business UI logic lives in `src/components/{feature}/screens/`.

```tsx
// ✅ page.tsx — thin wrapper only
export default function UsersPage() {
  const users = useUsersStore((s) => s.users);
  const router = useRouter();
  return <UserList users={users} onView={(u) => router.push(`/users/${u.key}`)} />;
}
```

Do NOT write UI JSX or business logic inside `page.tsx`.

## A.1 Server vs Client Components

- Components default to Server Components — no `useState`, `useEffect`, or event handlers.
- Add `'use client'` only when the component needs interactivity, browser APIs, or React hooks.
- Keep data fetching in Server Components; pass data down as props.
- Zustand stores and TanStack Query are Client Component concerns.

```tsx
// ✅ Server Component
async function UserListPage() {
  const users = await fetchUsers();
  return <UserList users={users} />;
}

// ✅ Client Component
'use client';
export function UserList({ users }: UserListProps) {
  const [selected, setSelected] = useState<string | null>(null);
  ...
}
```

## A.2 Auth Guard

`src/middleware.ts` must exist and guard all protected routes via cookie check.

```ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const PROTECTED_PREFIX = '/dashboard';
const LOGIN_PATH = '/login';

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  if (!pathname.startsWith(PROTECTED_PREFIX)) return NextResponse.next();
  const token = request.cookies.get('token')?.value;
  if (!token) {
    const loginUrl = new URL(LOGIN_PATH, request.url);
    loginUrl.searchParams.set('redirect', pathname);
    return NextResponse.redirect(loginUrl);
  }
  return NextResponse.next();
}

export const config = { matcher: [`${PROTECTED_PREFIX}/:path*`] };
```

## B. State Management

- **Zustand** manages UI state only: search text, modal open/close, selected IDs, filters.
- **TanStack Query** manages server data: lists, detail records, mutations.
- Do NOT put server data in Zustand stores.

Store file naming: feature name plural, e.g., `src/stores/users.ts`.

## C. Forms

All forms use React Hook Form + Zod. Never use `useState` per field.

```tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const schema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
});
type FormValues = z.infer<typeof schema>;

export default function UserForm() {
  const { control, handleSubmit, formState: { errors } } = useForm<FormValues>({
    resolver: zodResolver(schema),
  });
}
```

## D. UI Stack

### D.1 Ant Design (`antd`)

- Install: `npm install antd @ant-design/icons @ant-design/nextjs-registry`
- `src/app/providers.tsx` wraps `<AntdRegistry>` + `<ConfigProvider theme={...}>`
- Color priority: `theme.useToken()` → `src/constants/colors.ts` → never hardcode hex

### D.2 Tailwind CSS + shadcn/ui (`tailwind-shadcn`)

- Install: `npm install tailwindcss @radix-ui/react-* class-variance-authority clsx tailwind-merge`
- Config: `tailwind.config.ts` + `src/app/globals.css` with CSS variables from design tokens
- Color priority: semantic classes (`text-primary`, `bg-background`) → config tokens → never arbitrary color values

## E. Component Writing Rules

Props interface naming: `{ComponentName}Props`. Screen component file order: imports → constants → sub-components → Props interface → default export. Wrap table column definitions with `useMemo`.

## F. Health Route (standalone only)

```ts
// src/app/api/health/route.ts
import { NextResponse } from 'next/server';
export function GET() {
  return NextResponse.json({ status: 'ok' });
}
```

## Scaffold Checklist

- [ ] Copy `profiles/next-app-router/scaffold/src/middleware.ts.tmpl` → `src/middleware.ts`
- [ ] Copy `profiles/next-app-router/scaffold/src/lib/api/client.ts.tmpl` → `src/lib/api/client.ts`
- [ ] Copy `profiles/next-app-router/scaffold/src/lib/queryClient.ts.tmpl` → `src/lib/queryClient.ts`
- [ ] Copy `profiles/next-app-router/scaffold/src/constants/colors.ts.tmpl` → `src/constants/colors.ts`
- [ ] Copy `profiles/next-app-router/scaffold/src/constants/layout.ts.tmpl` → `src/constants/layout.ts`
- [ ] Copy `profiles/next-app-router/scaffold/src/constants/typography.ts.tmpl` → `src/constants/typography.ts`
- [ ] Copy `profiles/next-app-router/scaffold/src/constants/formats.ts.tmpl` → `src/constants/formats.ts`
- [ ] For `ui_stack: antd` — copy `layout-antd.tsx.tmpl` → `src/app/layout.tsx`; copy `providers-antd.tsx.tmpl` → `src/app/providers.tsx`
- [ ] For `ui_stack: tailwind-shadcn` — copy `layout-tailwind.tsx.tmpl` → `src/app/layout.tsx`; copy `providers-tailwind.tsx.tmpl` → `src/app/providers.tsx`
- [ ] For `rendering_mode: standalone` — copy `app/api/health/route.ts.tmpl` → `src/app/api/health/route.ts`
- [ ] Substitute all `{{VARIABLE}}` placeholders: `REPO_NAME`, `APP_NAME`, `PROTECTED_PREFIX`, `LOGIN_PATH`, `API_URL_ENV`
- [ ] Copy this skill into `.agents/skills/next-app-router/` in the generated project

## Template File Mapping

| Template | Destination |
|---|---|
| `profiles/next-app-router/templates/Dockerfile-standalone.tmpl` | `Dockerfile` (standalone mode) |
| `profiles/next-app-router/templates/Dockerfile-static.tmpl` | `Dockerfile` (static mode) |
| `profiles/next-app-router/templates/nginx.conf.tmpl` | `nginx.conf` (static mode) |
| `profiles/next-app-router/templates/Makefile.tmpl` | `Makefile` |

## Do Not

- Do not write UI JSX or business logic inside `page.tsx` or `layout.tsx`.
- Do not add `'use client'` to Server Components unnecessarily.
- Do not put server response data in Zustand stores.
- Do not use `useState` per form field — use React Hook Form.
- Do not hardcode hex colors in components.
- Do not implement API routes or `getServerSideProps` equivalents in static export mode.
