---
name: rawbank-backend
description: >-
  Développement backend Rawbank : GO-PASS stockgopass (Spring Boot 3.4, JWT, RBAC IAM,
  Oracle Flyway V1-V29, périmètre ECONOMA→GUICHET) et Digibranch digibranch (Spring Boot 3.3,
  kiosk /kiosk/v1, session cookie, Corbanking, périmètre device/branch, OTP, documents PDF).
  Use when: API, services, repositories, migrations, sécurité, tests, audit, ventes, stocks,
  approvisionnements, auth OTP kiosk, relevés RIB, ou erreurs backend dans stockgopass/gopass/backend
  ou digibranch/backend.
---

# Rawbank Backend

Skills couvrant **deux projets Spring Boot** Rawbank. Identifier le dépôt avant d'agir.

> **Usage portable** : les fichiers `references/*.md` contiennent matrice RBAC, endpoints, codes ERR et patterns **inline** — ne pas dépendre d'un clone repo. Voir [references/paths-convention.md](references/paths-convention.md).

| Projet | Package | API | Sécurité |
|--------|---------|-----|----------|
| **GO-PASS** | `com.rawbank.gopass` | `/api/v1/*` | JWT + RBAC `@PreAuthorize` |
| **Digibranch** | `cd.rawbank.digibranch` | `/kiosk/v1/*` | Périmètre kiosk + cookie session |

Vue comparative : [references/projects-overview.md](references/projects-overview.md)  
Chemins portables : [references/paths-convention.md](references/paths-convention.md)

---

## GO-PASS

Stack : **Spring Boot 3.4** · **Java 17** · **Oracle** · **Flyway** · **JPA** · **JWT**  
Artifact : `com.rawbank:gopass-api`

### Flux

```
Controller (api/) → Service (service/) → Repository → Oracle
                      ↑
              *ScopeService (RBAC périmètre)
```

1. DTO records dans `api/dto/` — jamais exposer les entités JPA.
2. Réponses : `ApiResponse.ok()` / `ApiResponse.paged()`.
3. Erreurs : `BusinessExceptions.badRequest|forbidden|notFound|conflict`.
4. Pagination : `PaginationUtil.createdAtDesc(page, pageSize)` (MIN=5, MAX=100).

### Contrôleurs (16)

`AuthController`, `HealthController`, `DashboardController`, `StockController`, `SaleController`, `SupplyOrderController`, `InventoryController`, `InventoryLookupController`, `ReportsController`, `ExportController`, `AuditController`, `AdminUserController`, `AdminOrganizationController`, `AdminProductController`, `AdminThresholdController`, `InternalJobController`

### Services scope — ne pas dupliquer RBAC

| Service | Rôle |
|---------|------|
| `OrganizationScopeService` | ECONOMA → REGION → AGENCE → GUICHET |
| `StockScopeService` | Emplacements stock visibles |
| `SaleScopeService` | GUICHET = ventes actives ; `canCancel` exige `sale:cancel` |
| `SupplyOrderScopeService` | Appro sortants/entrants par site |
| `ReportScopeService` | Filtres rapports |

### Sécurité IAM

```java
@PreAuthorize("hasAuthority('PERM_stock:read:own')")
@PreAuthorize("hasAnyAuthority('PERM_sale:create', 'PERM_sale:cancel')")
```

- Permission DB `sale:create` → autorité Spring `PERM_sale:create`.
- **Toujours** valider le périmètre en service, pas seulement `@PreAuthorize`.
- `UserPrincipal` : `User` + codes permission.

### MFA login

1. `POST /auth/login` → selon MFA : JWT direct, `/mfa` challenge, ou `/mfa/enroll` TOTP
2. `POST /auth/mfa/verify` → tokens JWT
3. Parité frontend : `User.requiresTotpEnrollment()` ↔ `mfa-requirements.ts`

**LDAP/LDAPS (livré V30–V31)** : bind annuaire remplace BCrypt au login — MFA inchangé. Voir [references/gopass-auth-ldap-plan.md](references/gopass-auth-ldap-plan.md).

### Migrations Flyway (V1–V29)

| Scripts | Contenu |
|---------|---------|
| V1–V2 | IAM schéma + seed rôles/permissions |
| V3/V20 | MFA TOTP, challenges |
| V21–V26 | MFA utilisateur, blocage login, email outbox |
| V27–V28 | `stock:transfer`, `stock:receive` AGENCE/GUICHET |
| V29 | `uk_sales_unit_active` — revente série annulée |

**Règle** : jamais modifier une migration appliquée — créer V{n+1}.

### Patterns métier critiques

**Ventes** : `CONFIRMEE` → encaissement → `RECONCILIEE`/`ANNULEE`. GUICHET liste/détail = `CONFIRMEE`+`ENREGISTREE` seulement. Revente : `existsByUnit_IdAndStatusNot(unitId, ANNULEE)`.

**Appro** : `EN_ATTENTE_CONFIRMATION` → `EN_TRANSIT` → `CONFIRMEE`/`REJETEE`. Flags `canConfirm`/`canReject` = permission + scope + statut.

**Stocks** : `StockMovementWriteService`, `SerialRangeUtil`, `SerialValidationUtil`.

### Checklist nouvel endpoint GO-PASS

```
- [ ] DTO records + @Valid
- [ ] @Tag / @Operation Swagger
- [ ] @PreAuthorize ou migration V{n}
- [ ] Service @Transactional
- [ ] *ScopeService si données org
- [ ] auditService.write() si sensible
- [ ] Test Mockito (SaleScopeServiceTest, AuthServiceLoginTest)
- [ ] GlobalExceptionHandler si contrainte Oracle
```

### Tests GO-PASS

```bash
./mvnw test
./mvnw test -Dtest=SaleScopeServiceTest
```

### Références GO-PASS (autonomes — matrice RBAC inline)

- [references/gopass-api-patterns.md](references/gopass-api-patterns.md)
- [references/gopass-rbac-scope.md](references/gopass-rbac-scope.md)
- [references/gopass-migrations-rbac.md](references/gopass-migrations-rbac.md)
- [references/gopass-services-env.md](references/gopass-services-env.md)
- [references/gopass-auth-ldap-plan.md](references/gopass-auth-ldap-plan.md) — LDAP/LDAPS + MFA (plan V30)
- [references/paths-convention.md](references/paths-convention.md)

---

## Digibranch

Stack : **Spring Boot 3.3.6** · **Java 17** · **Oracle 19c** · **Flyway V1–V7** · **Corbanking SIT**  
Artifact : `cd.rawbank:digibranch-api:0.1.0-SNAPSHOT`

### Flux

```
Controller (api/) → Service (service/) → Repository / CorbankingClient → Oracle + SIT
                      ↑
         KioskSecurityFilter + SessionCookieService + AuthFlowService
```

**Pas de RBAC** — sécurité = périmètre kiosk + session Oracle + OTP + audit.

### Packages

| Package | Rôle |
|---------|------|
| `api/` | Controllers, DTOs, `ApiExceptionHandler` |
| `api/auth/`, `accounts/`, `documents/`, `downloads/`, `internal/` | Domaines REST |
| `config/` | `KioskProperties`, `CorbankingProperties`, `CorsConfig` |
| `corbanking/` | `CorbankingClient`, `CorbankingHttpClient`, DTOs SIT |
| `domain/` | `AuthException`, `AuthChallengeState`, `DocumentKind` |
| `persistence/` | 4 entités + repositories |
| `security/` | Filtres périmètre, rate limit, Spring Security |
| `service/auth/`, `accounts/`, `documents/`, `audit/`, `retention/` | Métier |
| `web/` | `KioskRequestContext`, MDC `X-Request-Id` |

### API `/kiosk/v1`

| Controller | Endpoints clés |
|------------|----------------|
| `HealthController` | `GET /health` |
| `AuthController` | lookup, contact, OTP send/resend/verify, `DELETE /pending` |
| `SessionController` | `GET /me`, `DELETE` logout |
| `AccountController` | `GET /customers/{code}/accounts`, `GET /accounts/{id}/activity` |
| `DocumentController` | prepare/finalize RIB, relevés, avis débit/crédit ; `DELETE /draft` |
| `DownloadController` | `GET /downloads/{signedToken}` — **public**, HMAC |
| `InternalAuditController` | `POST /internal/audit/ping` (dev) |

### Enveloppe réponse

```java
ActionResult<T> { ok, message, error, code, data }
```

Erreurs stables `ERR-*` via `AuthException` + `ApiExceptionHandler`. Voir [references/digibranch-errors-audit.md](references/digibranch-errors-audit.md).

### Sécurité kiosk

| Mécanisme | Classe / config |
|-----------|-----------------|
| Token BFF | `X-Kiosk-Internal-Token` → `KIOSK_INTERNAL_API_TOKEN` |
| Device / agence | `X-Kiosk-Device-Id`, `X-Kiosk-Branch-Id` — whitelist |
| Locale | `X-Kiosk-Locale` |
| Corrélation | `X-Request-Id` → MDC |
| Session | Cookie `digibranch_sid` → table `KIOSK_SESSION` |
| Rate limit | `KioskRateLimitFilter` par endpoint |
| Download | `DownloadTokenSigner` HMAC, `DOWNLOAD_COUNT` = 1 |
| Anomalies | `KioskAuditAnomalyDetectionService` cron → `[SECURITY_ANOMALY]` |

**Public** (sans périmètre) : `/health`, `/actuator/health`, `GET /downloads/**`

`KIOSK_AUTH_MODE=mock` → `MockClientLookupService` (tests gates uniquement).

### Auth OTP (5 étapes frontend)

1. Langue → 2. Méthode → 3. Code client lookup → 4. Contact confirm → 5. OTP verify → session

États Oracle `AUTH_CHALLENGE` : `PENDING_CONTACT` → `PENDING_OTP`. OTP : HMAC-SHA256, TTL 5 min, max 3 tentatives, cooldown resend.

### Documents PDF (3 types)

`account-statement`, `rib`, `debit-credit-notice` :

1. **Prepare** — Corbanking → BLOB `DOCUMENT_DOWNLOAD` (inactive)
2. **Finalize** — OTP lien par canal (SMS/WhatsApp/email)
3. **Download** — URL signée publique, usage unique

Période relevé max : `KIOSK_STATEMENT_MAX_PERIOD_MONTHS` (6). Date activité : `DD/MM/YYYY`.

### Migrations Flyway V1–V7

| V | Table / colonne |
|---|-----------------|
| V1 | `AUTH_AUDIT` |
| V2 | `DOCUMENT_DOWNLOAD` |
| V3 | `AUTH_CHALLENGE`, `KIOSK_SESSION` |
| V4 | Index rétention audit |
| V5 | `AUTH_CHALLENGE.CLIENT_PROFILE_JSON` |
| V6 | `KIOSK_SESSION.EMAIL`, `MASKED_EMAIL` |
| V7 | `DOCUMENT_DOWNLOAD.DOWNLOAD_COUNT` |

Oracle SID : `DIGIBRACH` (pas service name). `hibernate.ddl-auto: validate`.

### Corbanking (SIT)

`CorbankingClient` : `fetchCustomerDetail`, `fetchAccountList`, `fetchAccountActivity`, `fetchRibStatement`, `fetchHistoricStatement`, `fetchDebitCreditNotice`.  
Secrets **backend only** : `CORBANKING_API_COOKIE`. Produits comptes : `001,100,101,102,954`.

### Tests gates Digibranch

| IT | Gate |
|----|------|
| `SchemaGateStep1IT` | Flyway V1+V2 |
| `AuditGateStep2IT` | Audit ping |
| `AuthGateStep3IT` | OTP mock |
| `AccountsGateStep4IT` | Session requise |
| `DocumentsGateStep5IT` | Prepare/finalize |
| `SecurityGateIT`, `RateLimitGateIT`, `DownloadSignatureGateIT` | Sécurité |

```bash
./run.sh   # ou ./mvnw test
```

### Checklist nouvel endpoint Digibranch

```
- [ ] DTO record + @Valid
- [ ] ActionResult via KioskResponses
- [ ] Session via SessionCookieService (sauf public download)
- [ ] Audit AUTH_AUDIT si action sensible
- [ ] AuthException + code ERR-* stable
- [ ] Rate limit si endpoint sensible
- [ ] Gate IT ou test unitaire
- [ ] Pas de secret Corbanking exposé
```

### Références Digibranch (autonomes — ERR-* et sécurité inline)

- [references/digibranch-security.md](references/digibranch-security.md)
- [references/digibranch-api-endpoints.md](references/digibranch-api-endpoints.md)
- [references/digibranch-domain-flows.md](references/digibranch-domain-flows.md)
- [references/digibranch-errors-audit.md](references/digibranch-errors-audit.md)
- [references/digibranch-corbanking-env.md](references/digibranch-corbanking-env.md)
- [references/paths-convention.md](references/paths-convention.md)

---

## Conventions Rawbank partagées

| Convention | GO-PASS | Digibranch |
|------------|---------|------------|
| Java | 17 | 17 |
| Oracle | SID GOPASS | SID DIGIBRACH |
| Flyway | `db/migration/V{n}__*.sql` | idem |
| DTO | Java records | Java records |
| OpenAPI | Springdoc | Springdoc `/swagger-ui.html` |
| Audit | `AuditService` / `AUTH_AUDIT` | `AuditService` / `AUTH_AUDIT` |
| Docker | — | `backend/Dockerfile` multi-stage JRE 17 |
| Logs | — | `LOG_FILE`, rotation 10MB×14 |

## Anti-patterns communs

- Logique métier dans le controller.
- Modifier une migration Flyway déjà déployée.
- Secrets Corbanking ou `KIOSK_INTERNAL_API_TOKEN` côté frontend.
- Appliquer le pattern JWT/RBAC GO-PASS sur Digibranch (modèle différent).
- Appliquer le pattern kiosk session sur GO-PASS (JWT requis).
- Filtrer ventes GUICHET uniquement côté frontend (GO-PASS).
- Décoder `digibranch_sid` côté client (Digibranch).
