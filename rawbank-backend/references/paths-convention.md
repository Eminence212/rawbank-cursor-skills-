# Index des références — rawbank-backend

> Ce skill est **autoportant** : tout le savoir technique est dans `references/*.md`. Ne pas chercher de fichiers projet (`application.yml`, migrations SQL, etc.) — le contenu est déjà copié ici.

## Table des matières

- [Installation](#installation)
- [Index par sujet](#index-par-sujet)
- [Index par projet](#index-par-projet)
- [Skills complémentaires](#skills-complémentaires)
- [Règles pour l'agent](#règles-pour-lagent)

---

## Installation

```bash
chmod +x .agents/skills/install-rawbank-skills.sh
./.agents/skills/install-rawbank-skills.sh
```

Cible : `$HOME/.cursor/skills/rawbank-backend/`

---

## Index par sujet

| Sujet | Référence |
|-------|-----------|
| Vue d'ensemble GO-PASS vs Digibranch | [projects-overview.md](projects-overview.md) |
| Controllers, DTO, ApiResponse | [gopass-api-patterns.md](gopass-api-patterns.md) |
| RBAC + scope ventes/stocks/appro | [gopass-rbac-scope.md](gopass-rbac-scope.md) |
| Flyway V1–V29, matrice IAM | [gopass-migrations-rbac.md](gopass-migrations-rbac.md) |
| Services métier + variables env | [gopass-services-env.md](gopass-services-env.md) |
| Sécurité kiosk (filtres, headers) | [digibranch-security.md](digibranch-security.md) |
| Endpoints `/kiosk/v1` + DTOs | [digibranch-api-endpoints.md](digibranch-api-endpoints.md) |
| Flux auth OTP, documents PDF | [digibranch-domain-flows.md](digibranch-domain-flows.md) |
| Codes ERR-* + audit AUTH_AUDIT | [digibranch-errors-audit.md](digibranch-errors-audit.md) |
| Corbanking SIT + env + Docker | [digibranch-corbanking-env.md](digibranch-corbanking-env.md) |

---

## Index par projet

### GO-PASS (`com.rawbank.gopass`, `/api/v1`, JWT)

| Besoin | Référence |
|--------|-----------|
| Nouvel endpoint REST | [gopass-api-patterns.md](gopass-api-patterns.md) |
| Permission + périmètre org | [gopass-rbac-scope.md](gopass-rbac-scope.md) + [gopass-migrations-rbac.md](gopass-migrations-rbac.md) |
| Nouvelle migration Flyway | [gopass-migrations-rbac.md](gopass-migrations-rbac.md) |
| Config Oracle, JWT, jobs | [gopass-services-env.md](gopass-services-env.md) |

### Digibranch (`cd.rawbank.digibranch`, `/kiosk/v1`, cookie)

| Besoin | Référence |
|--------|-----------|
| Nouvel endpoint kiosk | [digibranch-api-endpoints.md](digibranch-api-endpoints.md) + [digibranch-security.md](digibranch-security.md) |
| Auth OTP, session, PDF | [digibranch-domain-flows.md](digibranch-domain-flows.md) |
| Code erreur stable | [digibranch-errors-audit.md](digibranch-errors-audit.md) |
| Intégration Corbanking | [digibranch-corbanking-env.md](digibranch-corbanking-env.md) |

---

## Skills complémentaires

| Skill | Usage |
|-------|-------|
| `rawbank-frontend` | Parité MFA, ActionResult, composants kiosk |
| `mantine-dev` | — (frontend uniquement) |

---

## Règles pour l'agent

1. **Lire la référence** avant d'implémenter — ne pas supposer l'existence de fichiers projet.
2. **Liens autorisés** : uniquement `references/*.md` de ce skill ou `rawbank-frontend/references/*.md`.
3. **Interdit** : chemins absolus, `gopass/backend/...`, `digibranch/backend/...`, `docs/...` comme source de doc.
4. **Parité frontend** : codes `ERR-*` ↔ [digibranch-i18n-errors.md](../rawbank-frontend/references/digibranch-i18n-errors.md) ; MFA ↔ [gopass-lib-auth-mfa.md](../rawbank-frontend/references/gopass-lib-auth-mfa.md).
