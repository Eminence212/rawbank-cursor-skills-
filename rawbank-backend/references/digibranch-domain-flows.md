# Flux métier — Digibranch backend

## Table des matières

- [Schéma Oracle Flyway V1–V7](#schéma-oracle-flyway-v1v7)
- [Auth OTP wizard](#auth-otp-wizard)
- [Document flow PDF](#document-flow-pdf)
- [Comptes et activité](#comptes-et-activité)
- [Contraintes relevé](#contraintes-relevé)
- [Rétention données](#rétention-données)
- [PII masking](#pii-masking)
- [Mock mode](#mock-mode)
- [Services métier](#services-métier)
- [Références liées](#références-liées)

---

## Schéma Oracle Flyway V1–V7

| V | Objet |
|---|--------|
| V1 | Table `AUTH_AUDIT` — journal actions kiosk |
| V2 | Table `DOCUMENT_DOWNLOAD` — BLOB PDF, activated, TTL |
| V3 | `AUTH_CHALLENGE` + `KIOSK_SESSION` |
| V4 | Index rétention audit |
| V5 | `AUTH_CHALLENGE.CLIENT_PROFILE_JSON` |
| V6 | `KIOSK_SESSION.EMAIL`, `MASKED_EMAIL` |
| V7 | `DOCUMENT_DOWNLOAD.DOWNLOAD_COUNT` |

Oracle SID : `DIGIBRACH`. `hibernate.ddl-auto: validate`.

### Entités JPA

| Entity | Table | Colonnes clés |
|--------|-------|---------------|
| `AuthAuditEntity` | `AUTH_AUDIT` | action, actor, deviceId, branchId, metadata JSON, createdAt |
| `AuthChallengeEntity` | `AUTH_CHALLENGE` | state, otpHash, attempts, clientCode, profileJson, expiresAt |
| `KioskSessionEntity` | `KIOSK_SESSION` | tokenHash, clientCode, phone, email, expiresAt |
| `DocumentDownloadEntity` | `DOCUMENT_DOWNLOAD` | blob, activated, downloadCount, signedToken, expiresAt |

### États AUTH_CHALLENGE

```
PENDING_CONTACT → PENDING_OTP → (session créée, challenge supprimé)
```

Expiration → `ERR-AUTH-CHALLENGE-EXPIRED` (410).

---

## Auth OTP wizard

```
1. POST /auth/clients/lookup { code }
   → Corbanking digiGetCustomerDetail
   → INSERT AUTH_CHALLENGE state=PENDING_CONTACT
   → ClientPublicProfileDto (PII masqué)
   → audit CLIENT_LOOKUP

2. POST /auth/clients/contact/confirm { contactValue }
   → match téléphone/email vs profil Corbanking
   → audit CLIENT_CONTACT_CONFIRMED ou CLIENT_CONTACT_CONFIRM_FAILED

3. POST /auth/otp/send { channel }
   → NotificationChannelResolver
   → Corbanking digiSendMessage
   → state=PENDING_OTP, OTP HMAC-SHA256 stocké, TTL 5 min
   → audit OTP_SENT

4. POST /auth/otp/resend
   → cooldown → ERR-RESEND-COOLDOWN si trop tôt
   → audit OTP_RESENT

5. POST /auth/otp/verify { code }
   → max 3 tentatives → ERR-OTP-LOCKED
   → INSERT KIOSK_SESSION
   → Set-Cookie digibranch_sid
   → audit KIOSK_LOGIN

6. GET /session/me
   → SessionProfileDto
```

Reset : `DELETE /auth/pending` ou timeout challenge.

### OtpCrypto

```java
// HMAC-SHA256, secret KIOSK_SESSION_SECRET
// TTL: KIOSK_OTP_TTL_MINUTES (5)
// Demo SIT: KIOSK_DEMO_OTP=842195
```

---

## Document flow PDF

Types `DocumentKind` : `account-statement`, `rib`, `debit-credit-notice`.

### Prepare

```
POST /documents/{type}
→ require session (SessionCookieService)
→ Corbanking fetch PDF
→ INSERT DOCUMENT_DOWNLOAD (activated=0, BLOB)
→ Set-Cookie digibranch_doc_draft
→ audit RIB_PREPARED | STATEMENT_PREPARED | DEBIT_CREDIT_NOTICE_PREPARED
```

### Finalize

```
POST /documents/{type}/finalize { channel }
→ OTP lien par SMS/WhatsApp/email
→ DOCUMENT_DOWNLOAD activated=1
→ URL signée (DownloadTokenSigner HMAC)
→ audit RIB_LINK_SENT | STATEMENT_LINK_SENT | DEBIT_CREDIT_NOTICE_LINK_SENT
```

### Download (public)

```
GET /downloads/{signedToken}
→ vérifie HMAC + TTL + DOWNLOAD_COUNT < 1
→ stream application/pdf
→ increment DOWNLOAD_COUNT
→ audit DOCUMENT_DOWNLOADED
```

Erreurs : `ERR-DOWNLOAD-EXPIRED`, `ERR-DOWNLOAD-ALREADY-USED`, `ERR-DOWNLOAD-FORBIDDEN`.

---

## Comptes et activité

```
GET /customers/{code}/accounts
→ Corbanking fetchAccountList
→ filtre productCodes: 001,100,101,102,954
→ audit ACCOUNTS_LISTED

GET /accounts/{id}/activity?date=DD/MM/YYYY
→ Corbanking fetchAccountActivity
→ limite KIOSK_ACCOUNT_ACTIVITY_LIMIT (50)
→ audit ACTIVITY_LISTED
```

---

## Contraintes relevé

`StatementPeriodValidator` :

- Dates valides format DD/MM/YYYY
- Période max `KIOSK_STATEMENT_MAX_PERIOD_MONTHS` = **6 mois**
- Erreur : `ERR-STATEMENT-PERIOD`

---

## Rétention données

`KioskDataRetentionService` — cron `KIOSK_CLEANUP_CRON` (03:00) :

| Cible | Règle |
|-------|--------|
| Sessions expirées | purge |
| Challenges expirés | purge |
| PDF expirés | purge BLOB |
| AUTH_AUDIT | > `KIOSK_AUDIT_RETENTION_DAYS` (90) |

---

## PII masking

`PiiMasking` dans DTOs publics :

```
téléphone : ****1234
email     : j***@mail.com
```

Jamais exposer PII complet dans `ClientPublicProfileDto` / `SessionProfileDto`.

---

## Mock mode

`KIOSK_AUTH_MODE=mock` → `MockClientLookupService`

| Constante | Valeur |
|-----------|--------|
| Code client démo | `00842693` |
| OTP démo | `842195` |

**Uniquement tests gates** — jamais production.

---

## Services métier

| Classe | Rôle |
|--------|------|
| `AuthFlowService` | Orchestration wizard auth |
| `SessionCookieService` | Read/write cookie signé |
| `CustomerCodeValidator` | Format code client |
| `ContactConfirmationService` | Match profil Corbanking |
| `NotificationChannelResolver` | Canal OTP disponible |
| `OtpCrypto` | Hash/verify OTP |
| `CorbankingClientLookupService` | Lookup API SIT |
| `MockClientLookupService` | Lookup tests |
| `AccountService` | Liste comptes + activité |
| `DocumentPrepareService` | Prepare PDF |
| `DocumentFinalizeService` | Finalize + lien |
| `DownloadTokenSigner` | HMAC URL publique |
| `AuditService` | Écriture AUTH_AUDIT |
| `KioskDataRetentionService` | Purge cron |

---

## Références liées

- Endpoints REST : [digibranch-api-endpoints.md](digibranch-api-endpoints.md)
- Sécurité : [digibranch-security.md](digibranch-security.md)
- ERR-* : [digibranch-errors-audit.md](digibranch-errors-audit.md)
- Corbanking : [digibranch-corbanking-env.md](digibranch-corbanking-env.md)
