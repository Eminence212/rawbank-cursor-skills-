# Rawbank Cursor Skills

Skills Cursor pour le développement **GO-PASS** et **Digibranch** (backend Spring Boot + frontend React/Mantine).

| Skill | Périmètre |
|-------|-----------|
| [`rawbank-backend`](rawbank-backend/SKILL.md) | Spring Boot — JWT/RBAC GO-PASS, kiosk `/kiosk/v1`, Corbanking, Flyway |
| [`rawbank-frontend`](rawbank-frontend/SKILL.md) | Vite GO-PASS, Next.js + Vite SPA Digibranch, design system kiosk |

## Autoportant — pas besoin du code source

Chaque skill embarque tout le détail technique dans `references/*.md` :

- Code inline (TypeScript, Java, SQL, CSS)
- Matrice RBAC complète, endpoints API, codes `ERR-*`
- Thèmes Mantine, variables `--app-*` / `--kiosk-*`
- Patterns pages, composants kiosk, MFA

**Aucun clone** des repos `stockgopass` ou `digibranch` n'est requis pour que l'agent s'appuie sur ces skills.

Index : [`rawbank-frontend/references/paths-convention.md`](rawbank-frontend/references/paths-convention.md) · [`rawbank-backend/references/paths-convention.md`](rawbank-backend/references/paths-convention.md)

---

## Installation depuis GitHub

### Option A — clone + script (recommandé)

```bash
git clone https://github.com/<org>/rawbank-cursor-skills.git
cd rawbank-cursor-skills
chmod +x install-rawbank-skills.sh
./install-rawbank-skills.sh
```

### Option B — one-liner

```bash
git clone https://github.com/<org>/rawbank-cursor-skills.git /tmp/rawbank-skills \
  && chmod +x /tmp/rawbank-skills/install-rawbank-skills.sh \
  && /tmp/rawbank-skills/install-rawbank-skills.sh
```

### Option C — mise à jour

```bash
cd rawbank-cursor-skills && git pull
./install-rawbank-skills.sh
```

Le script **écrase** les installations précédentes dans `~/.cursor/skills/` (idempotent).

---

## Où sont installés les skills ?

| Cible | Chemin |
|-------|--------|
| Cursor (défaut) | `$HOME/.cursor/skills/rawbank-backend` |
| Cursor (défaut) | `$HOME/.cursor/skills/rawbank-frontend` |
| Agents (optionnel) | `$HOME/.agents/skills/rawbank-{backend,frontend}` |

Après installation : **redémarrer Cursor** ou ouvrir un **nouveau chat** pour la découverte des skills.

### Variables d'environnement

| Variable | Défaut | Effet |
|----------|--------|-------|
| `INSTALL_AGENTS_SKILLS` | `1` | Copie aussi vers `~/.agents/skills/` |
| `INSTALL_AGENTS_SKILLS=0` | — | Uniquement `~/.cursor/skills/` |

---

## Structure du dépôt GitHub

Publier **uniquement** ce contenu à la racine du repo :

```
rawbank-cursor-skills/
├── README.md
├── install-rawbank-skills.sh
├── rawbank-backend/
│   ├── SKILL.md
│   └── references/          # 11 fichiers
└── rawbank-frontend/
    ├── SKILL.md
    └── references/          # 12 fichiers
```

Ne pas inclure dans le repo GitHub skills : les anciens `gopass-backend/`, `gopass-frontend/`, ni les skills tiers (`mantine-custom-components`, etc.) — ils restent optionnels dans le monorepo stockgopass.

---

## Utilisation avec le code métier

Quand le workspace **contient** le code GO-PASS ou Digibranch :

1. L'agent charge le skill (`rawbank-backend` ou `rawbank-frontend`)
2. Il lit les `references/*.md` comme **spécification**
3. Il applique les changements dans le workspace ouvert

Les skills complémentaires utiles (installés séparément) :

| Skill | Source |
|-------|--------|
| `mantine-dev` | Cursor / marketplace |
| `mantine-combobox` | Projet ou marketplace |
| `mantine-custom-components` | Monorepo stockgopass `.agents/skills/` |

---

## Contenu des références

### Backend (`rawbank-backend/references/`)

| Fichier | Sujet |
|---------|--------|
| `gopass-api-patterns.md` | Controllers, DTO, `ApiResponse` |
| `gopass-rbac-scope.md` | Périmètre ventes/stocks/appro |
| `gopass-migrations-rbac.md` | Flyway V1–V29, matrice IAM |
| `gopass-services-env.md` | Services, variables env |
| `digibranch-security.md` | Filtres kiosk, rate limit |
| `digibranch-api-endpoints.md` | REST `/kiosk/v1` + DTOs |
| `digibranch-domain-flows.md` | Auth OTP, PDF, Flyway V1–V7 |
| `digibranch-errors-audit.md` | Codes `ERR-*`, audit |
| `digibranch-corbanking-env.md` | SIT, Docker, gates IT |
| `projects-overview.md` | Comparaison projets |
| `paths-convention.md` | Index du skill |

### Frontend (`rawbank-frontend/references/`)

| Fichier | Sujet |
|---------|--------|
| `gopass-theme-styles.md` | Mantine `myColor`, CSS `app-*` |
| `gopass-pages-pattern.md` | Listes, pagination URL |
| `gopass-ui-components.md` | Composants, badges, mutations |
| `gopass-lib-auth-mfa.md` | MFA parité backend |
| `digibranch-design-system.md` | Tokens marque kiosk |
| `digibranch-theme-styles.md` | Variables `--kiosk-*` |
| `digibranch-kiosk-components.md` | Catalogue 79 composants |
| `digibranch-nextjs-patterns.md` | Server Actions, `kioskFetch` |
| `digibranch-vite-spa.md` | React Router, proxy BFF |
| `digibranch-i18n-errors.md` | fr/en/ln + ERR-* |
| `projects-overview.md` | Comparaison 3 apps |
| `paths-convention.md` | Index du skill |

---

## Dépannage

| Problème | Action |
|----------|--------|
| Skill non détecté | Redémarrer Cursor ; vérifier `~/.cursor/skills/rawbank-frontend/SKILL.md` |
| Anciens skills `gopass-*` | Le script les supprime ; relancer `install-rawbank-skills.sh` |
| Agent cite des chemins absolus | Rappeler : tout est dans `references/` — pas de `/Users/...` |

---

## Licence

Usage interne Rawbank. Adapter la licence selon la politique de l'organisation avant publication GitHub.
