# Vite SPA — Digibranch kiosk

## Table des matières

- [Contexte migration](#contexte-migration)
- [Structure application](#structure-application)
- [React Router](#react-router)
- [ProtectedRoute](#protectedroute)
- [kioskFetch navigateur](#kioskfetch-navigateur)
- [Proxy Vite BFF](#proxy-vite-bff)
- [Variables d'environnement](#variables-denvironnement)
- [Différences Next.js vs Vite](#différences-nextjs-vs-vite)
- [Pending auth storage](#pending-auth-storage)
- [Déploiement nginx](#déploiement-nginx)
- [E2E Playwright](#e2e-playwright)
- [Phases migration M0–M8](#phases-migration-m0m8)
- [Références liées](#références-liées)

---

## Contexte migration

Migration Next.js → Vite (phases M0–M8). **Même contrat API** `/kiosk/v1`, **même** catalogue composants kiosk, fidélité visuelle.

| App | Port | Routing | API |
|-----|------|---------|-----|
| Next.js | 3000 | App Router | Server Actions `kioskFetch` |
| Vite SPA | 3001 | React Router 7 | Browser `kioskFetch` + proxy dev |

---

## Structure application

```
src/
├── main.tsx                   # MantineProvider + Router
├── App.tsx
├── index.css                  # --kiosk-* + Geist
├── routes/
│   ├── index.tsx              # AppRoutes
│   ├── guards/protected-route.tsx
│   ├── language-select-page.tsx
│   ├── dashboard-page.tsx
│   ├── auth/                  # 5 pages wizard
│   └── services/
│       ├── accounts-page.tsx
│       └── statements/        # hub + 3 wizards
├── components/kiosk/          # même catalogue que Next
├── config/, hooks/, lib/, types/
└── vite.config.ts
```

---

## React Router

```tsx
import { Routes, Route } from "react-router-dom";
import { ProtectedRoute } from "./guards/protected-route";
import { LanguageSelectPage } from "./language-select-page";
import { DashboardPage } from "./dashboard-page";
import { AuthRoutes } from "./auth";
import { StatementRoutes } from "./services/statements";

export function AppRoutes() {
  return (
    <Routes>
      <Route path="/" element={<LanguageSelectPage />} />
      <Route path="/auth/*" element={<AuthRoutes />} />
      <Route element={<ProtectedRoute />}>
        <Route path="/dashboard" element={<DashboardPage />} />
        <Route path="/services/accounts" element={<AccountsPage />} />
        <Route path="/services/statements/*" element={<StatementRoutes />} />
      </Route>
      <Route path="/auth/session-expired" element={<SessionExpiredPage />} />
    </Routes>
  );
}
```

Carte URL identique à Next.js — voir [digibranch-nextjs-patterns.md](digibranch-nextjs-patterns.md#routes-url).

---

## ProtectedRoute

```tsx
import { useEffect, useState } from "react";
import { Outlet, useNavigate } from "react-router-dom";
import { kioskFetch } from "@/lib/api/kiosk-api-client";

export function ProtectedRoute() {
  const navigate = useNavigate();
  const [ready, setReady] = useState(false);

  useEffect(() => {
    kioskFetch("/kiosk/v1/session/me").then((result) => {
      if (!result.ok && result.code === "ERR-006") {
        navigate("/auth/session-expired", { replace: true });
        return;
      }
      if (!result.ok) {
        navigate("/", { replace: true });
        return;
      }
      setReady(true);
    });
  }, [navigate]);

  if (!ready) return <KioskGlobalLoader />;
  return <Outlet />;
}
```

**Ne jamais** lire `document.cookie` pour `digibranch_sid` — uniquement `session/me`.

Alternative : hook `useAuthRouteGuard` pour pages individuelles.

---

## kioskFetch navigateur

```typescript
export async function kioskFetch<T>(
  path: string,
  init?: RequestInit,
): Promise<ActionResult<T>> {
  const locale = readKioskLocaleFromCookie();

  const res = await fetch(`/kiosk/v1${path.replace(/^\/kiosk\/v1/, "")}`, {
    ...init,
    credentials: "include",
    headers: {
      "Content-Type": "application/json",
      "X-Kiosk-Locale": locale,
      "X-Request-Id": crypto.randomUUID(),
      ...init?.headers,
    },
  });

  return parseKioskResponse<T>(res);
}
```

En dev, le **proxy Vite** injecte `X-Kiosk-Internal-Token`, `X-Kiosk-Device-Id`, `X-Kiosk-Branch-Id`.

---

## Proxy Vite BFF

```typescript
// vite.config.ts
import { defineConfig, loadEnv } from "vite";

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), "");
  const token = env.KIOSK_INTERNAL_API_TOKEN;

  if (!token) {
    console.warn("[kiosk] KIOSK_INTERNAL_API_TOKEN manquant — requêtes API échoueront");
  }

  return {
    server: {
      port: 3001,
      proxy: {
        "/kiosk/v1": {
          target: env.KIOSK_API_PROXY_TARGET || "http://localhost:8080",
          changeOrigin: true,
          configure: (proxy) => {
            proxy.on("proxyReq", (proxyReq) => {
              if (token) proxyReq.setHeader("X-Kiosk-Internal-Token", token);
              proxyReq.setHeader("X-Kiosk-Device-Id", env.KIOSK_DEVICE_ID || "KIOSK-DEV-001");
              proxyReq.setHeader("X-Kiosk-Branch-Id", env.KIOSK_BRANCH_ID || "BR-DEV");
            });
          },
        },
      },
    },
  };
});
```

---

## Variables d'environnement

```bash
# Public (préfixe VITE_ autorisé)
VITE_KIOSK_APP_NAME=Rawbank Digibranch
VITE_KIOSK_PUBLIC_BASE_URL=http://localhost:3001

# Secrets — SANS préfixe VITE_ (lus par vite.config.ts uniquement)
KIOSK_API_PROXY_TARGET=http://localhost:8080
KIOSK_INTERNAL_API_TOKEN=...
KIOSK_DEVICE_ID=KIOSK-DEV-001
KIOSK_BRANCH_ID=BR-DEV
```

**Règle** : `KIOSK_INTERNAL_API_TOKEN` ne doit **jamais** être exposé au bundle client.

---

## Différences Next.js vs Vite

| Aspect | Next.js | Vite SPA |
|--------|---------|----------|
| Navigation | `next/navigation` | `react-router-dom` |
| Liens | `next/link` | `Link` |
| Images | `next/image` | `<img>` |
| API calls | Server Actions | `kioskFetch` direct |
| Garde routes | `proxy.ts` | `ProtectedRoute` |
| Cookies serveur | `cookies()` | `credentials: "include"` |
| Locale | cookie → header serveur | `readKioskLocaleFromCookie()` |
| PWA | Serwist | — |

---

## Pending auth storage

```typescript
// État wizard auth intermédiaire (avant session)
const PENDING_AUTH_KEY = "kiosk_pending_auth";

export function savePendingAuth(state: PendingAuthState): void {
  sessionStorage.setItem(PENDING_AUTH_KEY, JSON.stringify(state));
}

export function loadPendingAuth(): PendingAuthState | null {
  const raw = sessionStorage.getItem(PENDING_AUTH_KEY);
  return raw ? JSON.parse(raw) : null;
}

export function clearPendingAuth(): void {
  sessionStorage.removeItem(PENDING_AUTH_KEY);
}
```

---

## Déploiement nginx

```nginx
server {
  listen 80;
  root /usr/share/nginx/html;   # dist/ Vite

  location / {
    try_files $uri $uri/ /index.html;
  }

  location /kiosk/v1/ {
    proxy_pass http://digibranch-api:8080/kiosk/v1/;
    proxy_set_header X-Kiosk-Internal-Token $kiosk_internal_token;
    proxy_set_header X-Kiosk-Device-Id $kiosk_device_id;
    proxy_set_header X-Kiosk-Branch-Id $kiosk_branch_id;
    proxy_set_header X-Request-Id $request_id;
  }
}
```

---

## E2E Playwright

| Spec | Couverture |
|------|------------|
| `smoke.spec.ts` | Chargement app |
| `auth-otp.spec.ts` | Parcours OTP complet |
| `auth-guard.spec.ts` | Routes protégées |
| `session-expired.spec.ts` | ERR-006 |

```bash
E2E_WITH_BACKEND=1 npm run test:e2e   # OTP réel contre Spring Boot :8080
```

---

## Phases migration M0–M8

| Phase | Livrable |
|-------|----------|
| M0 | Scaffold Vite + React Router |
| M1 | i18n + thème `--kiosk-*` |
| M2 | Copie composants kiosk (79) |
| M3 | Wizard auth 5 étapes |
| M4 | Dashboard + catalogue services |
| M5 | Page comptes |
| M6 | Wizard relevé période |
| M7 | Wizards RIB + avis débit/crédit |
| M8 | E2E + nginx prod |

Sync UI : après modification d'un composant kiosk Next, recopier le dossier `components/kiosk/` vers la SPA Vite.

---

## Références liées

- Patterns Next équivalents : [digibranch-nextjs-patterns.md](digibranch-nextjs-patterns.md)
- Composants : [digibranch-kiosk-components.md](digibranch-kiosk-components.md)
- Styles : [digibranch-theme-styles.md](digibranch-theme-styles.md)
- Sécurité backend : [digibranch-security.md](../rawbank-backend/references/digibranch-security.md)
