# API endpoints — Digibranch backend

## Table des matières

- [Conventions](#conventions)
- [Santé](#santé)
- [Session](#session)
- [Auth OTP](#auth-otp)
- [Comptes](#comptes)
- [Documents PDF](#documents-pdf)
- [Download public](#download-public)
- [Internal dev](#internal-dev)
- [Enveloppe ActionResult](#enveloppe-actionresult)
- [DTOs complets](#dtos-complets)
- [Références liées](#références-liées)

---

## Conventions

- Base : `/kiosk/v1`
- Enveloppe : `ActionResult<T>` (pas `ApiResponse`)
- Erreurs stables : codes `ERR-*` via `AuthException`
- Support controllers : `KioskControllerSupport`, `KioskResponses`
- Session : cookie `digibranch_sid` (HttpOnly)
- Brouillon document : cookie `digibranch_doc_draft` (TTL 30 min)

Headers requis (injectés par BFF) : voir [digibranch-security.md](digibranch-security.md)

---

## Santé

```
GET /actuator/health
GET /kiosk/v1/health
```

Public — sans périmètre kiosk.

---

## Session

```
GET    /kiosk/v1/session/me     → SessionProfileDto
DELETE /kiosk/v1/session        → logout, purge cookie
```

---

## Auth OTP

Sans session — état challenge Oracle `AUTH_CHALLENGE`.

```
POST   /kiosk/v1/auth/clients/lookup
       Body: { "code": "00842693" }
       → ClientPublicProfileDto

POST   /kiosk/v1/auth/clients/contact/confirm
       Body: { "contactValue": "+243..." }

POST   /kiosk/v1/auth/clients/contact/reset

POST   /kiosk/v1/auth/otp/send
       Body: { "channel": "SMS" | "WHATSAPP" | "EMAIL" }

POST   /kiosk/v1/auth/otp/resend

POST   /kiosk/v1/auth/otp/verify
       Body: { "code": "842195" }
       → Set-Cookie digibranch_sid

DELETE /kiosk/v1/auth/pending    → reset wizard
```

---

## Comptes

Session requise.

```
GET /kiosk/v1/customers/{code}/accounts
    → AccountDto[] (produits 001,100,101,102,954)

GET /kiosk/v1/accounts/{id}/activity?date=03/07/2026
    → AccountMovementViewDto[] (max 50)
```

Date activité : format **DD/MM/YYYY** obligatoire.

---

## Documents PDF

Session requise. Types : `rib`, `account-statement`, `debit-credit-notice`.

```
POST /kiosk/v1/documents/rib
     Body: { "accountId": "..." }

POST /kiosk/v1/documents/account-statements
     Body: { "accountId": "...", "startDate": "01/01/2026", "endDate": "30/06/2026" }

POST /kiosk/v1/documents/debit-credit-notices
     Body: { "accountId": "...", "movement": { ... } }

POST /kiosk/v1/documents/rib/finalize
POST /kiosk/v1/documents/account-statements/finalize
POST /kiosk/v1/documents/debit-credit-notices/finalize
     Body: { "channel": "SMS" | "WHATSAPP" | "EMAIL" }

DELETE /kiosk/v1/documents/draft
```

Flux détaillé : [digibranch-domain-flows.md](digibranch-domain-flows.md)

---

## Download public

```
GET /kiosk/v1/downloads/{signedToken}
    → application/pdf
```

Sans périmètre kiosk — protégé par HMAC + `DOWNLOAD_COUNT` max 1.

---

## Internal dev

```
POST /kiosk/v1/internal/audit/ping
     Condition: kiosk.internal-endpoints-enabled=true
```

**Désactiver en prod.**

---

## Enveloppe ActionResult

```java
public record ActionResult<T>(
    boolean ok,
    String message,
    String error,
    String code,
    T data
) {}
```

Succès :

```json
{ "ok": true, "message": "OK", "data": { ... } }
```

Erreur :

```json
{ "ok": false, "error": "Session expirée.", "code": "ERR-006" }
```

---

## DTOs complets

### Java records (backend)

```java
public record ClientLookupRequest(@NotBlank String code) {}

public record ContactConfirmRequest(@NotBlank String contactValue) {}

public record OtpSendRequest(@NotNull NotificationChannel channel) {}

public record OtpVerifyRequest(@NotBlank @Size(min = 6, max = 6) String code) {}

public record ClientPublicProfileDto(
    String clientCode,
    String maskedPhone,
    String maskedEmail,
    boolean phoneAvailable,
    boolean emailAvailable
) {}

public record SessionProfileDto(
    String clientCode,
    String displayName,
    String maskedPhone,
    String maskedEmail
) {}

public record AccountDto(
    String id,
    String label,
    String iban,
    String currency,
    BigDecimal balance,
    String productCode
) {}

public record DocumentAccountRequest(@NotBlank String accountId) {}

public record DocumentAccountStatementRequest(
    @NotBlank String accountId,
    @NotBlank String startDate,  // DD/MM/YYYY
    @NotBlank String endDate
) {}

public record DocumentDebitCreditNoticeRequest(
    @NotBlank String accountId,
    @NotNull AccountMovementRef movement
) {}

public record DocumentFinalizeRequest(@NotNull NotificationChannel channel) {}
```

### TypeScript (frontend)

```typescript
export type ActionResult<T> =
  | { ok: true; message?: string; data?: T }
  | { ok: false; error: string; code?: string };

export type NotificationChannel = "SMS" | "WHATSAPP" | "EMAIL";

export type ClientPublicProfile = {
  clientCode: string;
  maskedPhone?: string;
  maskedEmail?: string;
  phoneAvailable: boolean;
  emailAvailable: boolean;
};

export type SessionProfile = {
  clientCode: string;
  displayName: string;
  maskedPhone?: string;
  maskedEmail?: string;
};

export type Account = {
  id: string;
  label: string;
  iban: string;
  currency: "CDF" | "USD";
  balance: number;
  productCode: string;
};
```

### Corbanking DTOs (internes)

`CorbankingAccount`, `CorbankingCustomerDetailResponse`, `CorbankingHistoricStatementResponse`, `CorbankingRibResponse` — mappés vers DTOs publics via `CustomerDetailMapper`, `ActivityMapper`.

---

## Références liées

- Flux métier : [digibranch-domain-flows.md](digibranch-domain-flows.md)
- Sécurité : [digibranch-security.md](digibranch-security.md)
- ERR-* : [digibranch-errors-audit.md](digibranch-errors-audit.md)
- Frontend parsing : [digibranch-i18n-errors.md](../rawbank-frontend/references/digibranch-i18n-errors.md)
