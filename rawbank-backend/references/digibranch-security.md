# Sécurité kiosk — Digibranch backend

> **Autonome** : architecture périmètre, headers, rate limits et checklist prod.

Package Java : `cd.rawbank.digibranch.security`

## Architecture périmètre

```
Navigateur → Next.js/Vite BFF → [Headers sécurité] → Spring Boot → Oracle
```

Le navigateur **ne contacte jamais** Spring directement en prod — le BFF injecte les secrets.

## Filtres (ordre d'exécution)

| Filtre | Classe | Rôle |
|--------|--------|------|
| MDC | `KioskRequestMdcFilter` | `X-Request-Id` dans logs |
| Headers HTTP | `KioskHttpSecurityHeadersFilter` | HSTS, nosniff, DENY frame, no-store |
| Périmètre | `KioskSecurityFilter` | Token + device + branch |
| Rate limit | `KioskRateLimitFilter` | Fenêtres glissantes |
| Spring Security | `KioskSpringSecurityConfig` | Stateless, health public |

## Headers requis (prod)

| Header | Source | Validation |
|--------|--------|------------|
| `X-Kiosk-Internal-Token` | BFF `.env` | `KIOSK_INTERNAL_API_TOKEN`, comparaison temps constant |
| `X-Kiosk-Device-Id` | Config kiosk | Whitelist `kiosk.security.allowed-device-ids` |
| `X-Kiosk-Branch-Id` | Config agence | Whitelist `kiosk.security.allowed-branch-ids` |
| `X-Kiosk-Locale` | Cookie locale | `fr`, `en`, `ln` |
| `X-Request-Id` | BFF génère UUID | Corrélation logs |

## Endpoints publics (sans périmètre)

- `GET /kiosk/v1/health`
- `GET /actuator/health`
- `GET /kiosk/v1/downloads/**` — protégé par HMAC token, pas par filtre kiosk

## Rate limiting (`application.yml`)

| Action | Limite | Fenêtre |
|--------|--------|---------|
| Client lookup | 10 | 5 min |
| OTP send/resend | 5 | 5 min |
| OTP verify | 10 | 5 min |
| Download | 20 | 5 min |
| Accounts list | 30 | 1 min |

Dépassement : `429` + `ERR-RATE-LIMIT`.

## Session cookie

- Nom : `digibranch_sid` (`kiosk.session-cookie-name`)
- HttpOnly, SameSite=Lax, Secure en prod
- Signé avec `KIOSK_SESSION_SECRET`
- TTL : `KIOSK_SESSION_TIMEOUT_MINUTES` (défaut 5)
- Stockage : table `KIOSK_SESSION` Oracle

**Option B** : le frontend ne décode jamais le cookie — profil via `GET /session/me`.

## OTP crypto

- `OtpCrypto` : HMAC-SHA256
- TTL : `KIOSK_OTP_TTL_MINUTES` (5)
- Max tentatives : 3 → `ERR-OTP-LOCKED`
- Cooldown resend → `ERR-RESEND-COOLDOWN`
- Demo SIT : `KIOSK_DEMO_OTP=842195`

## Download signature

- `DownloadTokenSigner` : HMAC sur URL
- `DOCUMENT_DOWNLOAD.DOWNLOAD_COUNT` : max 1 (`KIOSK_STATEMENT_MAX_DOWNLOADS_PER_TOKEN`)
- TTL lien : `KIOSK_STATEMENT_DOWNLOAD_TTL_MINUTES` (5)

## Anomaly detection

`KioskAuditAnomalyDetectionService` — cron `KIOSK_ANOMALY_DETECTION_CRON` (défaut */5 min) :

| Type | Seuil |
|------|-------|
| `OTP_CONSECUTIVE_FAILURES` | 3 en 15 min |
| `CLIENT_LOOKUP_VOLUME` | 10 échecs en 5 min |
| `DEVICE_REJECTION_VOLUME` | 5 rejets en 15 min |

Logs : `[SECURITY_ANOMALY]` pour SIEM.

## Prod hardening checklist

| Paramètre | Dev | Prod |
|-----------|-----|------|
| `kiosk.internal-endpoints-enabled` | true | **false** |
| `springdoc.swagger-ui.enabled` | true | **false** |
| `kiosk.auth-mode` | api/mock | **api** |
| `KIOSK_SESSION_SECRET` | placeholder | ≥ 32 octets aléatoires |
| `KIOSK_INTERNAL_API_TOKEN` | dev | secret fort, rotation |

## Mode test

`kiosk.security.enabled=false` pour `*GateStep*IT` et `KIOSK_AUTH_MODE=mock`.

## Audit sécurité

Rejet device : action `SECURITY_DEVICE_REJECTED` dans `AUTH_AUDIT`.
