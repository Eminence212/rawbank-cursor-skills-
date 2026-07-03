# Vue d'ensemble — projets frontend Rawbank

## Table des matières

- [Comparaison](#comparaison)
- [Détection rapide](#détection-rapide)
- [GO-PASS — résumé](#go-pass--résumé)
- [Digibranch — résumé](#digibranch--résumé)
- [Démarrage dev](#démarrage-dev)
- [Index des références](#index-des-references)

---

## Comparaison

| | GO-PASS | Digibranch Next | Digibranch Vite SPA |
|---|---------|-----------------|---------------------|
| **Identifiant** | App stocks/ventes IAM | Kiosk Next.js BFF | Kiosk Vite migration |
| **Framework** | Vite + React Router | Next.js 16 App Router | Vite 8 + React Router 7 |
| **Port dev** | 5173 | 3000 | 3001 |
| **UI** | Mantine 7 | Mantine 7 + Tailwind 4 | idem (copie composants) |
| **Data** | TanStack Query | Server Actions + hooks | fetch + hooks |
| **Auth** | JWT localStorage | Cookie httpOnly BFF | Cookie + proxy |
| **API** | `/api/v1` Axios | `/kiosk/v1` kioskFetch | `/kiosk/v1` kioskFetch |
| **Réponse** | `{ data, meta }` | `ActionResult` | `ActionResult` |
| **i18n** | FR UI métier | fr / en / ln | fr / en / ln |
| **Styling** | classes `app-*` | CSS Modules kiosk | idem |
| **PWA** | — | Serwist | — |
| **E2E** | Playwright | Playwright | Playwright |

---

## Détection rapide

| Indices dans le code | Projet |
|---------------------|--------|
| `hasPermission`, `useQuery`, `/api/v1`, `app-page` | GO-PASS |
| `kioskFetch`, `"use server"`, `components/kiosk/` | Digibranch Next |
| `react-router-dom`, `ProtectedRoute`, proxy Vite `/kiosk/v1` | Digibranch Vite |

---

## GO-PASS — résumé

- **Auth** : JWT Bearer, MFA TOTP/email, RBAC `hasPermission(user, code)`
- **Organisation** : ECONOMA → REGION → AGENCE → GUICHET
- **Pages types** : listes URL-sync, POS vente, appro, inventaire, admin

| Sujet | Référence |
|-------|-----------|
| Thème + CSS | [gopass-theme-styles.md](gopass-theme-styles.md) |
| Pages CRUD | [gopass-pages-pattern.md](gopass-pages-pattern.md) |
| Composants | [gopass-ui-components.md](gopass-ui-components.md) |
| MFA | [gopass-lib-auth-mfa.md](gopass-lib-auth-mfa.md) |

---

## Digibranch — résumé

- **Auth** : wizard OTP 5 étapes, cookie `digibranch_sid` opaque
- **UI** : 79 composants kiosk DRY, dark auth + light ops
- **Services** : comptes, relevés RIB/période/avis, PDF + lien signé

| Sujet | Référence |
|-------|-----------|
| Composants kiosk | [digibranch-kiosk-components.md](digibranch-kiosk-components.md) |
| Design tokens | [digibranch-design-system.md](digibranch-design-system.md) |
| CSS Modules | [digibranch-theme-styles.md](digibranch-theme-styles.md) |
| Next.js | [digibranch-nextjs-patterns.md](digibranch-nextjs-patterns.md) |
| Vite SPA | [digibranch-vite-spa.md](digibranch-vite-spa.md) |
| i18n ERR-* | [digibranch-i18n-errors.md](digibranch-i18n-errors.md) |

---

## Démarrage dev

```bash
# GO-PASS frontend — port 5173, proxy /api → :8080
npm run dev:front

# Digibranch Next — port 3000
npm run dev

# Digibranch Vite — port 3001
npm run dev

# Backend requis pour les deux : Spring Boot :8080
```

---

## Index des références

Navigation complète : [paths-convention.md](paths-convention.md) (index du skill).

Backend associé : skill `rawbank-backend` — [projects-overview.md](../rawbank-backend/references/projects-overview.md)
