# Index des références — rawbank-frontend

> Ce skill est **autoportant** : tout le savoir technique est dans `references/*.md`. Ne pas chercher de fichiers projet (`theme.ts`, `ARCHITECTURE.md`, etc.) — le contenu est déjà copié ici.

## Table des matières

- [Installation](#installation)
- [Index par sujet](#index-par-sujet)
- [Index par application](#index-par-application)
- [Skills complémentaires](#skills-complémentaires)
- [Règles pour l'agent](#règles-pour-lagent)

---

## Installation

```bash
chmod +x .agents/skills/install-rawbank-skills.sh
./.agents/skills/install-rawbank-skills.sh
```

Cible : `$HOME/.cursor/skills/rawbank-frontend/` (et `$HOME/.agents/skills/` si activé).

---

## Index par sujet

| Sujet | Référence |
|-------|-----------|
| Vue d'ensemble 3 apps | [projects-overview.md](projects-overview.md) |
| Thème GO-PASS (Mantine + CSS `app-*`) | [gopass-theme-styles.md](gopass-theme-styles.md) |
| Pattern pages liste / formulaires | [gopass-pages-pattern.md](gopass-pages-pattern.md) |
| Composants UI GO-PASS | [gopass-ui-components.md](gopass-ui-components.md) |
| Auth JWT + MFA (code complet) | [gopass-lib-auth-mfa.md](gopass-lib-auth-mfa.md) |
| Design system kiosk (tokens) | [digibranch-design-system.md](digibranch-design-system.md) |
| Thème kiosk (`--kiosk-*`, CSS Modules) | [digibranch-theme-styles.md](digibranch-theme-styles.md) |
| 79 composants kiosk (catalogue) | [digibranch-kiosk-components.md](digibranch-kiosk-components.md) |
| Next.js App Router + Server Actions | [digibranch-nextjs-patterns.md](digibranch-nextjs-patterns.md) |
| Vite SPA + proxy BFF | [digibranch-vite-spa.md](digibranch-vite-spa.md) |
| i18n fr/en/ln + codes ERR-* | [digibranch-i18n-errors.md](digibranch-i18n-errors.md) |

---

## Index par application

### GO-PASS (Vite, port 5173, JWT)

Stack : React 19 · Mantine 7 · TanStack Query · `/api/v1`

| Besoin | Référence |
|--------|-----------|
| Couleurs, classes CSS | [gopass-theme-styles.md](gopass-theme-styles.md) |
| Page liste CRUD | [gopass-pages-pattern.md](gopass-pages-pattern.md) |
| Guards, badges, layout | [gopass-ui-components.md](gopass-ui-components.md) |
| Login / MFA / RBAC UI | [gopass-lib-auth-mfa.md](gopass-lib-auth-mfa.md) |

### Digibranch Next (port 3000, cookie BFF)

| Besoin | Référence |
|--------|-----------|
| kioskFetch, proxy.ts, actions | [digibranch-nextjs-patterns.md](digibranch-nextjs-patterns.md) |
| Composants réutilisables | [digibranch-kiosk-components.md](digibranch-kiosk-components.md) |
| Tokens visuels | [digibranch-design-system.md](digibranch-design-system.md) + [digibranch-theme-styles.md](digibranch-theme-styles.md) |

### Digibranch Vite SPA (port 3001)

| Besoin | Référence |
|--------|-----------|
| React Router, ProtectedRoute | [digibranch-vite-spa.md](digibranch-vite-spa.md) |
| Même UI kiosk | [digibranch-kiosk-components.md](digibranch-kiosk-components.md) |

---

## Skills complémentaires

| Skill | Usage |
|-------|-------|
| `rawbank-backend` | API, RBAC, sécurité kiosk |
| `mantine-dev` | API Mantine 7 |
| `mantine-combobox` | Select custom GO-PASS |
| `mantine-custom-components` | Factory Mantine |

---

## Règles pour l'agent

1. **Lire la référence** correspondante avant d'implémenter — ne pas supposer l'existence de fichiers projet.
2. **Liens autorisés** : uniquement `references/*.md` de ce skill ou `rawbank-backend/references/*.md`.
3. **Interdit** : chemins absolus machine, `gopass/...`, `digibranch/...`, `docs/...`, `.cursor/skills/...` comme source de doc.
4. **Si le workspace contient le code** : utiliser les références comme spec, puis aligner l'implémentation existante.
