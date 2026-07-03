# Next.js patterns — Digibranch frontend

## Table des matières

- [Stack et conventions](#stack-et-conventions)
- [Arborescence App Router](#arborescence-app-router)
- [Configuration catalogue](#configuration-catalogue)
- [kioskFetch (Server Actions)](#kioskfetch-server-actions)
- [Server Action pattern](#server-action-pattern)
- [proxy.ts — garde de routes](#proxyts--garde-de-routes)
- [Session et auth côté serveur](#session-et-auth-côté-serveur)
- [Hooks custom](#hooks-custom)
- [Format et domaine pur](#format-et-domaine-pur)
- [PWA Serwist](#pwa-serwist)
- [Variables d'environnement](#variables-denvironnement)
- [Parcours document RIB](#parcours-document-rib)
- [Références liées](#références-liées)

---

## Stack et conventions

| Couche | Technologie |
|--------|-------------|
| Framework | Next.js 16 App Router, React 19 |
| UI | Mantine 7 + Tailwind 4 + CSS Modules kiosk |
| Validation | Zod dans Server Actions |
| API | `kioskFetch` → Spring Boot `/kiosk/v1` |
| Auth | Cookie httpOnly `digibranch_sid` (BFF) |
| Réponse API | `ActionResult<T>` |

**Règle absolue** : ne jamais décoder `digibranch_sid` côté client — profil via `GET /session/me` uniquement.

---

## Arborescence App Router

```
app/
├── layout.tsx                 # MantineProvider, Serwist, Geist
├── globals.css                # variables --kiosk-*
├── manifest.ts, sw.ts         # PWA Serwist
├── (kiosk)/
│   ├── page.tsx               # Sélection langue (Server Component)
│   ├── language-select-client.tsx
│   ├── auth/
│   │   ├── method/page.tsx           # étape 1/5
│   │   ├── client-code/page.tsx      # étape 2/5
│   │   ├── profile-confirm/page.tsx    # étape 3/5
│   │   ├── otp-delivery/page.tsx     # étape 4/5
│   │   ├── otp/page.tsx              # étape 5/5
│   │   └── session-expired/page.tsx
│   ├── dashboard/page.tsx + dashboard-client.tsx
│   ├── services/accounts/page.tsx
│   ├── services/statements/
│   │   ├── page.tsx                  # Hub relevés
│   │   ├── account-statement/page.tsx
│   │   ├── rib/page.tsx
│   │   ├── debit-credit-notice/page.tsx
│   │   └── actions.ts                # Server Actions documents
│   └── actions.ts                      # Server Actions auth
├── api/health/route.ts
└── api/auth/session-expired/route.ts
```

### Routes URL

| Route | Écran |
|-------|-------|
| `/` | Langue FR / EN / Lingala |
| `/auth/method` | Méthode auth (1/5) |
| `/auth/client-code` | Code client (2/5) |
| `/auth/profile-confirm` | Contact (3/5) |
| `/auth/otp-delivery` | Canal OTP (4/5) |
| `/auth/otp` | Saisie OTP (5/5) |
| `/auth/session-expired` | Session expirée |
| `/dashboard` | Grille services |
| `/services/accounts` | Mes comptes |
| `/services/statements` | Hub relevés |
| `/services/statements/account-statement` | Relevé période |
| `/services/statements/rib` | RIB |
| `/services/statements/debit-credit-notice` | Avis débit/crédit |

---

## Configuration catalogue

### auth-flow.ts

```typescript
export const AUTH_WIZARD_TOTAL = 5;

export const AUTH_ROUTES = {
  method: "/auth/method",
  clientCode: "/auth/client-code",
  profileConfirm: "/auth/profile-confirm",
  otpDelivery: "/auth/otp-delivery",
  otp: "/auth/otp",
} as const;
```

### services.ts

```typescript
export type ServiceStatus = "active" | "coming_soon" | "disabled";

export type KioskService = {
  id: string;
  route: string;
  status: ServiceStatus;
  labelKey: string;
  descKey: string;
  icon: string;
};

export const KIOSK_SERVICES: KioskService[] = [
  {
    id: "accounts",
    route: "/services/accounts",
    status: "active",
    labelKey: "services.accounts",
    descKey: "services.accountsDesc",
    icon: "accounts",
  },
  {
    id: "statements",
    route: "/services/statements",
    status: "active",
    labelKey: "services.statements",
    descKey: "services.statementsDesc",
    icon: "statements",
  },
];
```

`ServiceGrid` : seuls `status: "active"` sont cliquables ; `coming_soon` → badge « Bientôt disponible ».

### statement-types.ts

```typescript
export const STATEMENT_TYPES = [
  { id: "account-statement", route: "/services/statements/account-statement", labelKey: "statements.account-statement", ... },
  { id: "rib", route: "/services/statements/rib", labelKey: "statements.rib", ... },
  { id: "debit-credit-notice", route: "/services/statements/debit-credit-notice", labelKey: "statements.debit-credit-notice", ... },
];
```

### kiosk-api.ts

```typescript
export const KIOSK_API_BASE_URL = process.env.KIOSK_API_BASE_URL ?? "http://localhost:8080";
export const KIOSK_SESSION_COOKIE = "digibranch_sid";
export const KIOSK_DOC_DRAFT_COOKIE = "digibranch_doc_draft";
export const KIOSK_PROXY_COOKIE_NAMES = ["digibranch_sid", "digibranch_doc_draft"] as const;
```

---

## kioskFetch (Server Actions)

```typescript
"use server";

import { cookies, headers } from "next/headers";
import { parseKioskResponse } from "@/lib/api/parse-kiosk-response";
import type { ActionResult } from "@/types/kiosk";

export async function kioskFetch<T>(
  path: string,
  init?: RequestInit,
): Promise<ActionResult<T>> {
  const cookieStore = await cookies();
  const hdrs = await headers();

  const cookieHeader = KIOSK_PROXY_COOKIE_NAMES.map((name) => {
    const value = cookieStore.get(name)?.value;
    return value ? `${name}=${value}` : null;
  })
    .filter(Boolean)
    .join("; ");

  const res = await fetch(`${KIOSK_API_BASE_URL}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      Cookie: cookieHeader,
      "X-Kiosk-Internal-Token": process.env.KIOSK_INTERNAL_API_TOKEN!,
      "X-Kiosk-Device-Id": process.env.KIOSK_DEVICE_ID!,
      "X-Kiosk-Branch-Id": process.env.KIOSK_BRANCH_ID!,
      "X-Kiosk-Locale": cookieStore.get(LOCALE_COOKIE)?.value ?? "fr",
      "X-Request-Id": crypto.randomUUID(),
      ...init?.headers,
    },
    cache: "no-store",
  });

  // Relayer Set-Cookie de la réponse vers le navigateur
  const setCookie = res.headers.getSetCookie?.() ?? [];
  for (const raw of setCookie) {
    // parser et appliquer via cookieStore.set(...)
  }

  return parseKioskResponse<T>(res);
}
```

---

## Server Action pattern

```typescript
"use server";

import { z } from "zod";
import { kioskFetch } from "@/lib/api/kiosk-api-client";
import { requireKioskSession } from "@/lib/auth/require-session";
import type { ActionResult } from "@/types/kiosk";

const prepareRibSchema = z.object({
  accountId: z.string().min(1, "Compte requis"),
});

export async function prepareRibAction(
  input: unknown,
): Promise<ActionResult<{ draftId: string }>> {
  await requireKioskSession();

  const parsed = prepareRibSchema.safeParse(input);
  if (!parsed.success) {
    return { ok: false, error: "Données invalides.", code: "ERR-VALIDATION" };
  }

  return kioskFetch("/kiosk/v1/documents/rib", {
    method: "POST",
    body: JSON.stringify(parsed.data),
  });
}
```

### Wrappers actions (`lib/actions/`)

```typescript
export function actionFailure(error: string, code?: string): ActionResult<never> {
  return { ok: false, error, code };
}

export async function withActionError<T>(
  fn: () => Promise<ActionResult<T>>,
): Promise<ActionResult<T>> {
  try {
    return await fn();
  } catch {
    return { ok: false, error: "Erreur réseau.", code: "ERR-005" };
  }
}
```

---

## proxy.ts — garde de routes

> Utiliser `proxy.ts`, **pas** `middleware.ts` (convention projet).

```typescript
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

const PROTECTED_PREFIXES = ["/dashboard", "/services"];
const SESSION_COOKIE = "digibranch_sid";

export function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Server Actions POST : ne pas bloquer (évite ERR-NETWORK si session expirée mid-action)
  if (request.method === "POST" && request.headers.get("next-action")) {
    return NextResponse.next();
  }

  const isProtected = PROTECTED_PREFIXES.some((p) => pathname.startsWith(p));
  if (!isProtected) return NextResponse.next();

  const hasSession = request.cookies.has(SESSION_COOKIE);
  if (!hasSession) {
    return NextResponse.redirect(new URL("/auth/session-expired", request.url));
  }

  return NextResponse.next();
}
```

---

## Session et auth côté serveur

### requireKioskSession

```typescript
"use server";

export async function requireKioskSession(): Promise<SessionProfile> {
  const result = await kioskFetch<SessionProfile>("/kiosk/v1/session/me");
  if (!result.ok) {
    throw new Error(result.code ?? "ERR-006");
  }
  return result.data!;
}
```

### locale.ts

```typescript
export const LOCALE_COOKIE = "kiosk_locale";

export type KioskLocale = "fr" | "en" | "ln";

export function parseKioskLocale(value?: string): KioskLocale {
  if (value === "en" || value === "ln") return value;
  return "fr";
}
```

---

## Hooks custom

| Hook | Rôle |
|------|------|
| `useKioskNavigation` | `router.push` + reset wizard |
| `useKioskFormAction` | Formulaire + Server Action + erreurs |
| `useKioskServerAction` | Wrapper async action + loading |
| `useKioskSessionExpired` | Détecte ERR-006 → redirect |
| `useStatementWizardShell` | État étapes wizard relevé |
| `useStatementWizardAccount` | Compte sélectionné wizard |
| `useDownloadCountdown` | Compte à rebours lien PDF |
| `useFilteredPagination` | Pagination listes kiosk |
| `useOtpInputLabels` | Labels i18n pour `OtpInput` |
| `useKioskPageReady` | Sync loader global navigation |

---

## Format et domaine pur

```typescript
// format/currency.ts
export function formatCdf(value: number): string {
  return `${value.toLocaleString("fr-FR")} CDF`;
}
export function formatUsd(value: number): string {
  return `$ ${value.toLocaleString("fr-FR", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

// format/phone.ts — indicatif +243 par défaut
// format/date.ts — DD/MM/YYYY HH:mm

// domain/ — validation IBAN, montants, règles OTP (testable sans React)
```

---

## PWA Serwist

- Service worker : `app/sw.ts`
- Provider : `components/providers/serwist-provider.tsx`
- Offline **limité** — le kiosk nécessite le réseau pour l'API

---

## Variables d'environnement

```bash
# .env.local — serveur Next uniquement pour secrets
KIOSK_API_BASE_URL=http://localhost:8080
KIOSK_INTERNAL_API_TOKEN=...        # JAMAIS NEXT_PUBLIC_
KIOSK_DEVICE_ID=KIOSK-DEV-001
KIOSK_BRANCH_ID=BR-DEV
```

**Interdit** : `NEXT_PUBLIC_KIOSK_INTERNAL_API_TOKEN` ou tout secret en `NEXT_PUBLIC_*`.

---

## Parcours document RIB

```
1. AccountSelector          — choix compte
2. ConfirmationCard         — récap
3. prepareRibAction         — POST /documents/rib → cookie digibranch_doc_draft
4. OtpChannelPicker         — SMS / WhatsApp / email
5. finalizeRibAction        — POST /documents/rib/finalize → lien envoyé
6. OperationResult success  — référence + useDownloadCountdown
```

Étapes auth wizard : **5** (`AUTH_WIZARD_TOTAL`).  
Étapes wizard RIB métier : **5** (compte → confirm → prepare → OTP canal → succès).

---

## Références liées

- Composants UI : [digibranch-kiosk-components.md](digibranch-kiosk-components.md)
- Tokens CSS : [digibranch-theme-styles.md](digibranch-theme-styles.md)
- i18n + ERR-* : [digibranch-i18n-errors.md](digibranch-i18n-errors.md)
- Endpoints API : [digibranch-api-endpoints.md](../rawbank-backend/references/digibranch-api-endpoints.md)
- SPA Vite équivalent : [digibranch-vite-spa.md](digibranch-vite-spa.md)
