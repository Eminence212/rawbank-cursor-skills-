# Vue d'ensemble — projets backend Rawbank

## Table des matières

- [Comparaison](#comparaison)
- [Détection rapide](#détection-rapide)
- [GO-PASS — résumé](#go-pass--résumé)
- [Digibranch — résumé](#digibranch--résumé)
- [Démarrage dev](#démarrage-dev)
- [Index des références](#index-des-references)

---

## Comparaison

| | GO-PASS | Digibranch |
|---|---------|------------|
| **Package** | `com.rawbank.gopass` | `cd.rawbank.digibranch` |
| **Spring Boot** | 3.4 | 3.3.6 |
| **API prefix** | `/api/v1` | `/kiosk/v1` |
| **Auth** | JWT Bearer | Cookie `digibranch_sid` |
| **Autorisation** | RBAC `@PreAuthorize` + scope | Périmètre device/branch + session |
| **Utilisateur** | Employés IAM | Clients bancaires |
| **Oracle SID** | `GOPASS` | `DIGIBRACH` |
| **Flyway** | V1–V29 | V1–V7 |
| **Enveloppe** | `ApiResponse<T>` | `ActionResult<T>` |
| **Erreurs** | HTTP + message | Codes `ERR-*` |
| **Externe** | — | Corbanking SIT |
| **Audit** | `audit_logs` | `AUTH_AUDIT` |
| **Tests** | Mockito unitaires | Gate IT |

---

## Détection rapide

| Indices | Projet |
|---------|--------|
| `@PreAuthorize`, `UserPrincipal`, `*ScopeService` | GO-PASS |
| `KioskSecurityFilter`, `ActionResult`, `AuthException` | Digibranch |

---

## GO-PASS — résumé

- Artifact : `com.rawbank:gopass-api`
- 16 controllers REST, hiérarchie org, ventes/stocks/appro
- MFA login, Flyway IAM V1–V29

| Sujet | Référence |
|-------|-----------|
| Patterns API | [gopass-api-patterns.md](gopass-api-patterns.md) |
| RBAC scope | [gopass-rbac-scope.md](gopass-rbac-scope.md) |
| Migrations IAM | [gopass-migrations-rbac.md](gopass-migrations-rbac.md) |
| Services + env | [gopass-services-env.md](gopass-services-env.md) |

---

## Digibranch — résumé

- Artifact : `cd.rawbank:digibranch-api`
- Kiosk OTP, documents PDF, Corbanking SIT
- Pas de RBAC employé — sécurité périmètre kiosk

| Sujet | Référence |
|-------|-----------|
| Endpoints | [digibranch-api-endpoints.md](digibranch-api-endpoints.md) |
| Sécurité | [digibranch-security.md](digibranch-security.md) |
| Flux métier | [digibranch-domain-flows.md](digibranch-domain-flows.md) |
| ERR-* | [digibranch-errors-audit.md](digibranch-errors-audit.md) |
| Corbanking | [digibranch-corbanking-env.md](digibranch-corbanking-env.md) |

---

## Démarrage dev

```bash
# GO-PASS — port 8080
source .env && ./mvnw spring-boot:run

# Digibranch — port 8080 (changer si conflit)
./run.sh
```

---

## Index des références

Navigation complète : [paths-convention.md](paths-convention.md) (index du skill).

Frontend associé : skill `rawbank-frontend` — [projects-overview.md](../rawbank-frontend/references/projects-overview.md)
