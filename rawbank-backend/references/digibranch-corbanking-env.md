# Corbanking & environnement — Digibranch backend

## Variables `.env` backend

| Variable | Obligatoire | Description |
|----------|-------------|-------------|
| `DB_HOST`, `DB_PORT`, `DB_SID` | oui | Oracle SID `DIGIBRACH` |
| `DB_USER`, `DB_PASSWORD` | oui | Schéma DIGIBRACH |
| `KIOSK_SESSION_SECRET` | prod | Signature cookie + download HMAC |
| `KIOSK_INTERNAL_API_TOKEN` | prod | Token BFF `X-Kiosk-Internal-Token` |
| `KIOSK_DEVICE_ID` | oui | `KIOSK-DEV-001` en dev |
| `KIOSK_BRANCH_ID` | oui | `BR-DEV` en dev |
| `KIOSK_AUTH_MODE` | — | `api` (prod) ou `mock` (tests) |
| `CORBANKING_API_COOKIE` | prod SIT | Cookie gateway Rawbank — **backend only** |
| `CORBANKING_USER_CODE` | — | Défaut `AUTO` |
| `CORBANKING_ACCOUNT_PRODUCT_CODES` | — | `001,100,101,102,954` |
| `KIOSK_PUBLIC_BASE_URL` | — | URL frontend pour liens |
| `KIOSK_CORS_ALLOWED_ORIGINS` | — | `http://localhost:3000,http://localhost:3001` |
| `LOG_FILE`, `LOG_LEVEL_*` | — | Logging fichier |
| `SPRINGDOC_SWAGGER_UI_ENABLED` | — | false en prod |
| `KIOSK_INTERNAL_ENDPOINTS_ENABLED` | — | false en prod |
| `KIOSK_SECURITY_ENABLED` | tests | false pour gates IT |
| `KIOSK_RATE_LIMIT_ENABLED` | — | true en prod |
| `KIOSK_CLEANUP_ENABLED` | — | Purge cron |
| `KIOSK_ANOMALY_DETECTION_ENABLED` | — | Détection SOC |

## Corbanking endpoints SIT (`application.yml`)

| Clé config | URL SIT typique |
|------------|-----------------|
| `corbanking.customer-detail.url` | `digiGetCustomerDetail` |
| `corbanking.account-list.url` | Liste comptes |
| `corbanking.account-activity.url` | Mouvements |
| `corbanking.rib-statement.url` | PDF RIB |
| `corbanking.historic-statement.url` | Relevé période |
| `corbanking.debit-credit-notice.url` | Avis mouvement |
| Notifications | `digiSendMessage` (SMS/WhatsApp/email) |

Timeout : `CORBANKING_REQUEST_TIMEOUT_MS` (10s), customer detail 25s.

## CorbankingClient

```java
// Façade principale — délègue à CorbankingHttpClient
fetchCustomerDetail(code)
fetchAccountList(customerCode)
fetchAccountActivity(accountId, date)
fetchRibStatement(accountId)
fetchHistoricStatement(accountId, start, end)
fetchDebitCreditNotice(accountId, movement)
```

`CorbankingResponses.requireSuccess(opstatus, message, code)` — mappe échecs SIT vers `ERR-005` ou codes métier.

## Retry

`CorbankingRetry` — retry configurable sur timeouts réseau.

## Mappers

`CustomerDetailMapper`, `ActivityMapper` — Corbanking DTO → API DTO.

## Docker

```bash
docker build -t digibranch-api .
docker run --rm -p 8080:8080 --env-file .env digibranch-api
```

Image : `eclipse-temurin:17-jre-alpine`, user non-root `digibranch`.

## Scripts dev

```bash
./run.sh                    # source .env + mvnw spring-boot:run
./mvnw test                 # tous tests
./scripts/verify-step*.sh   # vérification manuelle gates
```

## Tests gates

Support : `MockKioskAuthSupport`, `KioskTestSecuritySupport`

| IT | Phase |
|----|-------|
| `SchemaGateStep1IT` | 0 — schéma |
| `AuditGateStep2IT` | 1 — audit |
| `AuthGateStep3IT` | 2 — auth mock |
| `AccountsGateStep4IT` | 3 — comptes |
| `DocumentsGateStep5IT` | 4 — documents |
| `SecurityGateIT` | périmètre |
| `RateLimitGateIT` | rate limit |
| `DownloadSignatureGateIT` | HMAC download |
| `AuditAnomalyGateIT` | anomalies |

## Demo SIT

- Code client : `00842693`
- OTP : `842195`

## Règle secrets

**Jamais** dans frontend `.env` ou `VITE_*` :
- `CORBANKING_API_COOKIE`
- `KIOSK_INTERNAL_API_TOKEN`
- `KIOSK_SESSION_SECRET`

Frontend reçoit uniquement via BFF/proxy qui injecte headers.
