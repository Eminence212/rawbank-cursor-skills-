---
name: rawbank-frontend
description: >-
  Développement frontend Rawbank : GO-PASS stockgopass (React 19, Vite, Mantine 7,
  TanStack Query, JWT, RBAC, pages métier stocks/ventes/appro) et Digibranch digibranch
  (Next.js 16 + Vite SPA kiosk, Mantine 7, Tailwind 4, OTP wizard, composants kiosk DRY,
  catalogues services, i18n FR/EN/Lingala, ActionResult). Use when: pages, forms, API clients,
  guards, design system Rawbank, kiosk UI, relevés, comptes, ou styling dans gopass/frontend,
  digibranch/frontend, ou digibranch/digibranch-kiosk.
---

# Rawbank Frontend

Skills couvrant **trois applications frontend** Rawbank.

> **Usage portable** : les fichiers `references/*.md` contiennent code, tokens et patterns **inline** — ne pas dépendre d'un clone repo ni de chemins absolus machine. Voir [references/paths-convention.md](references/paths-convention.md).

| App | Stack | Port | Auth |
|-----|-------|------|------|
| **GO-PASS** | Vite + React Router | 5173 | JWT Bearer |
| **Digibranch Next** | Next.js 16 App Router | 3000 | Cookie `digibranch_sid` (BFF) |
| **Digibranch SPA** | Vite + React Router 7 | 3001 | Cookie + proxy BFF |

Vue comparative : [references/projects-overview.md](references/projects-overview.md)  
Index complet : [references/paths-convention.md](references/paths-convention.md)

---

## GO-PASS

Stack : **React 19** · **Vite** · **Mantine 7** · **TypeScript** · **TanStack Query**

### Architecture

```
pages/<domaine>/     → écrans
lib/<domaine>.ts     → types, fetch API
components/          → guards, badges, layout
routes/              → AppRoutes, ProtectedRoute, AccessRoute
```

**Règle** : logique API dans `lib/`, pas dans la page.

### Clients API (`lib/`)

| Module | Domaine |
|--------|---------|
| `api.ts` | Axios + JWT refresh |
| `api-client.ts` | `apiGet`, `apiPagedGet`, `apiPost`, … |
| `admin.ts`, `stocks.ts`, `sales.ts`, `supply.ts` | Métier |
| `inventory.ts`, `dashboard.ts`, `reports.ts`, `audit.ts`, `export.ts` | Métier |
| `rbac.ts` | `hasPermission(user, code)` |

### Meta statuts

`sales/sale-status-meta.ts`, `supply/status-meta.ts`, `stocks/movement-meta.ts`, `stocks/stock-level-meta.ts`, `stocks/expiration-meta.ts` → `SemanticStatusBadge`

### Guards

| Guard | Rôle |
|-------|------|
| `ProtectedRoute` | JWT requis |
| `GuestRoute` | Redirect si session (login) |
| `AccessRoute` | Permission RBAC |
| `TotpEnrollmentGuard` | Force `/mfa/enroll` |
| `SettingsLayout` | ADMIN + AGENCE |

MFA parité : voir [references/gopass-lib-auth-mfa.md](references/gopass-lib-auth-mfa.md)

### Pattern liste

1. `useSearchParams()` + `urlSearchParamsToRecord()` + `parsePaginationParams()`
2. `useQuery` avec clé `page`/`pageSize`/filtres
3. `PaginationBar` + toolbar `app-table-toolbar`
4. `useNotifyMutation` + invalidation cache

### Styling GO-PASS

- Mantine 7 + classes sémantiques `app-*` (`app-page`, `app-card`, `app-table`, `app-kpi`)
- Palette `myColor` RAWBANK `#ff9e1b` → `#ff9400`
- Détail complet : [references/gopass-theme-styles.md](references/gopass-theme-styles.md)

### Pages clés

| Domaine | Pages | lib |
|---------|-------|-----|
| Ventes | `PosSalePage`, `SalesCancelPage` | `sales.ts` |
| Stocks | `StockOverviewPage`, `StockMovementsPage` | `stocks.ts` |
| Appro | `SupplyOrdersPage` | `supply.ts` |
| Admin | `UsersPage`, `OrganizationsPage` | `users.ts` |

### Checklist nouvelle page GO-PASS

```
- [ ] Route AppRoutes + nav-data.ts
- [ ] lib/<domaine>.ts types + fetch
- [ ] hasPermission + flags canXxx API
- [ ] useQuery / useNotifyMutation
- [ ] PaginationBar + useSearchParams
- [ ] SemanticStatusBadge + *-meta.ts
- [ ] Gestion 403
- [ ] Classes app-*
```

```bash
npm run dev:front   # 5173, proxy /api → 8080
```

### Références GO-PASS (autonomes — code inline dans references/)

- [references/gopass-pages-pattern.md](references/gopass-pages-pattern.md)
- [references/gopass-ui-components.md](references/gopass-ui-components.md)
- [references/gopass-lib-auth-mfa.md](references/gopass-lib-auth-mfa.md)
- [references/gopass-theme-styles.md](references/gopass-theme-styles.md)
- [references/paths-convention.md](references/paths-convention.md)

---

## Digibranch — design system Rawbank

### Tokens couleur

```
primary: #ff9e1b          CTA, progression
primary-light: #ffd000     accents dorés
success: #22c55e | error: #ef4444
auth-bg: #0a0a0a          écrans auth dark
dashboard-bg: #ffffff     opérations light
surface-muted: #f8f9fa
radius-md: 12px | radius-lg: 16px
btn-min-height: 48px      tactile kiosk
résolution cible: 1080p
```

Police : **Geist**. Détail tokens : [references/digibranch-theme-styles.md](references/digibranch-theme-styles.md).

### Thèmes contextuels

| Contexte | Thème |
|----------|-------|
| Accueil langue, OTP, téléphone | **Dark** `#0a0a0a` |
| Dashboard, formulaires, succès | **Light** |

### Règle DRY absolue (kiosk)

> Pages = orchestration uniquement. **79 composants** dans `components/kiosk/`. Zéro duplication UI.

Workflow : parcourir `components/kiosk/` → paramétrer via props → sinon créer composant **générique**.

| Composant | Rôle |
|-----------|------|
| `KioskShell` | Layout header + footer |
| `KioskSplitHero` | Dark 2 colonnes + illustration |
| `AuthWizardShell` | Wizard authentification |
| `StepProgress` + `KioskFooter` | Étapes + actions bas |
| `OtpInput` | 6 cases, countdown resend |
| `OtpChannelPicker` | SMS / WhatsApp / email |
| `AccountSelector` | Liste comptes radio |
| `MovementSelector` | Mouvement avis débit/crédit |
| `StatementWizardLayout` | Shell wizards relevés |
| `ConfirmationCard` | Récap avant validation |
| `OperationResult` | Succès / échec + code ERR |
| `ServiceGrid` + `ServiceCard` | Dashboard catalogue |
| `CatalogSelectionGrid` | Hub sous-types |
| `KioskPagination` | Pagination listes |
| `RawbankLogo`, `HeroGlobe` | Marque |

Liste complète : [references/digibranch-kiosk-components.md](references/digibranch-kiosk-components.md)

---

## Digibranch Next.js

Stack : **Next.js 16** · **React 19** · **Mantine 7** · **Tailwind 4** · **Zod** · **Serwist PWA**

### Structure

```
src/app/(kiosk)/          # Routes kiosk
  page.tsx                # Sélection langue
  auth/                   # Wizard OTP (5 étapes)
  dashboard/
  services/accounts/
  services/statements/    # Hub + 3 wizards
src/components/kiosk/     # 79 composants
src/lib/
  api/kiosk-api-client.ts # kioskFetch Server Actions
  services/               # Logique métier
  domain/, format/, i18n/, auth/
src/config/
  services.ts             # KIOSK_SERVICES catalogue
  statement-types.ts      # Sous-catalogue relevés
  auth-flow.ts            # AUTH_ROUTES, AUTH_WIZARD_TOTAL=5
src/proxy.ts              # Garde routes (pas middleware.ts)
```

### Routes App Router

| Route | Écran |
|-------|-------|
| `/` | Langue FR/EN/Lingala |
| `/auth/method` | Méthode auth (étape 1/5) |
| `/auth/client-code` | Code client |
| `/auth/profile-confirm` | Contact téléphone/email |
| `/auth/otp-delivery` | Canal OTP |
| `/auth/otp` | Saisie OTP |
| `/auth/session-expired` | Session expirée |
| `/dashboard` | Grille services |
| `/services/accounts` | Mes comptes |
| `/services/statements` | Hub relevés |
| `/services/statements/account-statement` | Relevé période |
| `/services/statements/rib` | RIB |
| `/services/statements/debit-credit-notice` | Avis débit/crédit |

### Catalogue services (déploiement progressif)

```ts
// config/services.ts
export type ServiceStatus = "active" | "coming_soon" | "disabled";
export const KIOSK_SERVICES: KioskService[] = [
  { id: "accounts", route: "/services/accounts", status: "active", ... },
  { id: "statements", route: "/services/statements", status: "active", ... },
];
```

Hub relevés (`statement-types.ts`) : `account-statement`, `rib`, `debit-credit-notice`.

`ServiceGrid` lit le catalogue — seuls `active` sont cliquables ; `coming_soon` = badge « Bientôt disponible ».

### API client (Server Actions)

`kioskFetch()` dans `lib/api/kiosk-api-client.ts` :
- Relaie cookies `digibranch_sid`, `digibranch_doc_draft`
- Injecte `X-Kiosk-Internal-Token`, device, branch, locale, `X-Request-Id`
- Parse `ActionResult<T>` via `parse-kiosk-response.ts`
- **Ne jamais** décoder le cookie session côté client

### Server Actions pattern

```ts
"use server";
type ActionResult<T> = { ok: true; message; data? } | { ok: false; error; code? };
// Zod validate → service → ActionResult
```

### Garde session (`proxy.ts`)

- Vérifie cookie sur `/dashboard`, `/services`
- **Bypass** Server Actions (évite ERR-NETWORK sur session expirée)
- Redirect `/auth/session-expired`

### i18n

Locales : `fr`, `en`, `ln`. Custom `t(locale, key)` — clés `auth.*`, `services.*`, `statements.*`, `errors.ERR-*`.  
Erreurs : `resolve-error-message.ts` mappe codes `ERR-*` → message localisé.

### Hooks (10+)

`useKioskNavigation`, `useKioskFormAction`, `useKioskServerAction`, `useKioskSessionExpired`, `useStatementWizardShell`, `useStatementWizardAccount`, `useDownloadCountdown`, `useFilteredPagination`, `useOtpInputLabels`, `useKioskPageReady`

### Parcours transactionnel standard

```
Sélection compte → Saisie → Confirmation → Auth OTP → Succès + reçu/PDF
```

### Checklist feature Digibranch Next

```
- [ ] Maquette mockups/ si UI nouvelle
- [ ] Composant kiosk existant réutilisé
- [ ] Zod + service lib/services/
- [ ] Server Action ActionResult
- [ ] Entrée catalogue services.ts (status)
- [ ] Traductions fr/en/ln
- [ ] Audit + codes ERR-*
- [ ] Playwright e2e si parcours critique
```

---

## Digibranch SPA (Vite)

Migration Next → Vite (phases M0–M8). **Même contrat API**, fidélité visuelle.

### Différences vs Next

| Aspect | Next.js | Vite SPA |
|--------|---------|----------|
| Routing | App Router | React Router 7 `src/routes/` |
| API | Server Actions `kioskFetch` | Browser `kioskFetch` + proxy dev |
| Garde | `proxy.ts` | `ProtectedRoute` → `GET /session/me` |
| Images | `next/image` | `<img>` |
| Navigation | `next/navigation` | `react-router-dom` |
| Env secrets | serveur only | `KIOSK_API_PROXY_TARGET` — **pas** `VITE_*` pour token |

### Dev proxy BFF

Vite injecte headers sécurité comme Next.js. Avertit si `KIOSK_INTERNAL_API_TOKEN` manquant.

### Sync composants

Modifier `frontend/src/components/kiosk/` puis synchroniser vers `digibranch-kiosk/src/components/kiosk/`.

### E2E Playwright

`digibranch-kiosk/e2e/` : `smoke`, `auth-otp`, `auth-guard`, `session-expired`.  
`E2E_WITH_BACKEND=1` pour OTP réel contre Spring Boot.

```bash
npm run dev:front   # GO-PASS :5173
npm run dev         # Digibranch Next :3000 ou Vite :3001 selon package
```

### Déploiement prod

`digibranch-kiosk/deploy/nginx-kiosk.conf` — SPA `dist/` + proxy `/kiosk/v1/` avec headers injectés.

### Références Digibranch (autonomes — tokens + ERR-* inline)

- [references/digibranch-kiosk-components.md](references/digibranch-kiosk-components.md)
- [references/digibranch-design-system.md](references/digibranch-design-system.md)
- [references/digibranch-theme-styles.md](references/digibranch-theme-styles.md) — variables `--kiosk-*` inline
- [references/digibranch-nextjs-patterns.md](references/digibranch-nextjs-patterns.md)
- [references/digibranch-vite-spa.md](references/digibranch-vite-spa.md)
- [references/digibranch-i18n-errors.md](references/digibranch-i18n-errors.md)
- [references/paths-convention.md](references/paths-convention.md)

---

## Conventions Rawbank partagées

| Convention | GO-PASS | Digibranch |
|------------|---------|------------|
| UI library | Mantine 7 | Mantine 7 |
| Icons | Tabler | Tabler |
| TypeScript | strict | strict |
| Validation | côté API + forms | Zod + Server Actions |
| Format CDF | `fr-FR` entiers | idem |
| Format USD | 2 décimales | idem |
| Téléphone RDC | +243 | +243 |
| Tests unit | Vitest | Vitest |
| E2E | Playwright | Playwright |

## Anti-patterns

**GO-PASS** : fetch dans useEffect ; ignorer `canXxx` ; Tailwind ; filtrer ventes GUICHET côté client.

**Digibranch** : markup dupliqué dans pages ; `TransferAccountSelector` au lieu de `AccountSelector` ; hardcoder dashboard ; secrets en `VITE_*` ; décoder cookie session ; Server Actions sans Zod ; texte en dur sans i18n.

**Commun** : logique métier dans composants React ; ignorer parité backend↔frontend sur règles auth.
