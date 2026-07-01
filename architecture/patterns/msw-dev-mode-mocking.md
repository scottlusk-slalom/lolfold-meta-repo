# Pattern: MSW Dev-Mode Mocking

## Context

Frontend repos often can't reach a live backend during local development (infra down, CORS, no credentials). Developers need realistic API responses without running the full stack.

## Pattern

Use [MSW (Mock Service Worker)](https://mswjs.io/) with a single handler set that serves both:
- **Vitest (node)** — via `setupServer()` in test setup
- **Dev server (browser)** — via `setupWorker()` gated on env var

### Activation Gate

In `main.tsx`, conditionally start the browser worker:

```ts
async function boot() {
  if (import.meta.env.DEV && !import.meta.env.VITE_API_URL) {
    const { worker } = await import('./mocks/browser')
    await worker.start({ onUnhandledRequest: 'bypass' })
  }
  // render app...
}
```

When `VITE_API_URL` is set (e.g., pointed at a real backend), MSW stays out of the way. When unset, all `/api/*` requests are intercepted with mock data.

### File Structure

```
src/mocks/
├── fixtures.ts   # Typed mock data (shared by tests + dev)
├── handlers.ts   # MSW route handlers (single source of truth)
├── server.ts     # Node setup (Vitest)
└── browser.ts    # Browser setup (dev server)
```

### Test Setup

```ts
// src/test-setup.ts
import { server } from './mocks/server'
beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

## Benefits

- One set of mock data for both testing and visual development
- No Vite proxy configuration needed
- Backend-independent frontend development
- Realistic fixtures catch type mismatches early

## When to Use

Any frontend repo where the backend is not reliably available locally.

## Originated From

`specs/feature/hand-replayer-ui-enhancements` (2026-07-01)
