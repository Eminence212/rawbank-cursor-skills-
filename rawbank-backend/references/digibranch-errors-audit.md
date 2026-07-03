# Erreurs & audit — Digibranch backend

> **Autonome** : catalogue complet des codes `ERR-*`, actions audit et handler — source de vérité partagée avec `digibranch-i18n-errors.md` (frontend).

## Codes ERR-* complets

| Code | HTTP | Signification |
|------|------|---------------|
| `ERR-003` | 401 | OTP incorrect |
| `ERR-005` | 503 | Corbanking / service indisponible |
| `ERR-006` | 401 | Session expirée / absente |
| `ERR-CLIENT` | 400 | Format code client invalide |
| `ERR-CLIENT-NOT-FOUND` | 404 | Client inconnu |
| `ERR-CONTACT` | 400 | Contact vide / invalide |
| `ERR-CONTACT-EMAIL` | 400 | Email ne correspond pas au profil |
| `ERR-CONTACT-PHONE` | 400 | Téléphone ne correspond pas |
| `ERR-OTP-CHANNEL` | 400 | Canal OTP indisponible |
| `ERR-OTP-EXPIRED` | 401 | OTP expiré |
| `ERR-OTP-LOCKED` | 403 | 3 tentatives max atteintes |
| `ERR-RESEND-COOLDOWN` | 429 | Renvoi OTP trop tôt |
| `ERR-AUTH-CHALLENGE-EXPIRED` | 410 | Challenge expiré |
| `ERR-FORBIDDEN` | 403 | Périmètre kiosk rejeté |
| `ERR-RATE-LIMIT` | 429 | Rate limit dépassé |
| `ERR-NOT-FOUND` | 404 | Ressource introuvable |
| `ERR-VALIDATION` | 400 | Bean validation / JSON invalide |
| `ERR-STATEMENT-PERIOD` | 400 | Période relevé invalide |
| `ERR-DOWNLOAD-EXPIRED` | 410 | Lien download expiré |
| `ERR-DOWNLOAD-ALREADY-USED` | 410 | Lien déjà utilisé |
| `ERR-DOWNLOAD-FORBIDDEN` | 403 | Lien non activé |
| `ERR-DEBIT-CREDIT-NOTICE` | 502 | Échec génération avis Corbanking |

Mapping HTTP : `AuthExceptionHttpStatus` + `ApiExceptionHandler`.

## AuthException pattern

```java
throw new AuthException("OTP expiré ou incorrect.", "ERR-003");
```

## ActionResult erreur

```json
{
  "ok": false,
  "error": "Message utilisateur",
  "code": "ERR-006",
  "message": null,
  "data": null
}
```

## Actions audit AUTH_AUDIT

### Auth

| Action | Contexte |
|--------|----------|
| `CLIENT_LOOKUP` | Lookup réussi |
| `CLIENT_LOOKUP_FAILED` | Code inconnu |
| `CLIENT_CONTACT_CONFIRMED` | Contact validé |
| `CLIENT_CONTACT_CONFIRM_FAILED` | Mismatch profil |
| `CLIENT_CONTACT_RESET` | Reset contact |
| `OTP_SENT` | Envoi OTP |
| `OTP_RESENT` | Renvoi OTP |
| `OTP_VERIFY_FAILED` | Mauvais code |
| `KIOSK_LOGIN` | Session créée |
| `KIOSK_LOGOUT` | Déconnexion |
| `AUTH_SESSION_PURGED` | Rétention |

### Comptes

| Action | Contexte |
|--------|----------|
| `ACCOUNTS_LISTED` | Liste comptes |
| `ACTIVITY_LISTED` | Mouvements |

### Documents

| Action | Contexte |
|--------|----------|
| `RIB_PREPARED` | PDF RIB stocké |
| `STATEMENT_PREPARED` | Relevé stocké |
| `DEBIT_CREDIT_NOTICE_PREPARED` | Avis stocké |
| `RIB_LINK_SENT` | Lien RIB envoyé |
| `STATEMENT_LINK_SENT` | Lien relevé envoyé |
| `DEBIT_CREDIT_NOTICE_LINK_SENT` | Lien avis envoyé |
| `DOCUMENT_DOWNLOADED` | Téléchargement public |

### Sécurité

| Action | Contexte |
|--------|----------|
| `SECURITY_DEVICE_REJECTED` | Device/branch invalide |

## Anomaly types

`OTP_CONSECUTIVE_FAILURES`, `CLIENT_LOOKUP_VOLUME`, `DEVICE_REJECTION_VOLUME`

## Exception handler

`ApiExceptionHandler` (`@RestControllerAdvice`) :
- `AuthException` → status mappé + ActionResult
- `MethodArgumentNotValidException` → 400 `ERR-VALIDATION`
- `NoResourceFoundException` → 404 `ERR-NOT-FOUND`
- `Exception` → 500 `ERR-005`

## Frontend mapping

Les codes `ERR-*` sont traduits côté UI via `resolve-error-message.ts` (fr/en/ln).
