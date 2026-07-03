# i18n & erreurs — Digibranch frontend

> **Autonome** : système i18n complet, parsing `ActionResult`, et **tous** les codes `ERR-*` avec messages FR. Aligné sur `digibranch-errors-audit.md` (backend).

## Locales

| Code | Langue | Défaut |
|------|--------|--------|
| `fr` | Français | oui |
| `en` | English | |
| `ln` | Lingala | |

Cookie : `LOCALE_COOKIE` → header API `X-Kiosk-Locale`.

## Système i18n (custom, pas next-intl)

```
lib/i18n/
├── index.ts                 # export t(locale, key, params?)
├── messages/fr.ts           # messages FR complets
├── messages/en.ts
├── messages/ln.ts
└── resolve-error-message.ts
```

### Fonction `t`

```typescript
export type Locale = "fr" | "en" | "ln";

export function t(
  locale: Locale,
  key: string,
  params?: Record<string, string | number>,
): string {
  const messages = MESSAGES[locale] ?? MESSAGES.fr;
  let text = getNested(messages, key) ?? key;
  if (params) {
    for (const [k, v] of Object.entries(params)) {
      text = text.replace(`{${k}}`, String(v));
    }
  }
  return text;
}
```

### Structure clés (dot notation)

```
auth.otp.title
auth.otp.resendIn              // param {seconds}
auth.step                        // param {n}
auth.sessionExpired.title
services.accounts
services.accountsDesc
services.statements
statements.rib.title
statements.rib.step1.title
statements.account-statement.title
statements.debit-credit-notice.title
errors.generic
errors.ERR-003
errors.ERR-006
common.continue
common.cancel
common.confirm
common.error
common.success
```

### Usage composant

```tsx
const locale = useKioskLocale(); // hook ou readKioskLocaleFromCookie()
const title = t(locale, "auth.otp.title");
const resend = t(locale, "auth.otp.resendIn", { seconds: 42 });
```

## resolve-error-message.ts (complet)

```typescript
export function resolveErrorMessage(
  locale: Locale,
  code?: string,
  fallback?: string,
): string {
  if (code) {
    const key = `errors.${code}`;
    const translated = t(locale, key);
    if (translated !== key) return translated;
  }
  return fallback ?? t(locale, "errors.generic");
}
```

## Catalogue ERR-* — messages FR (obligatoires dans fr.ts)

| Code | HTTP | Message FR suggéré |
|------|------|-------------------|
| `ERR-003` | 401 | Code incorrect. Vérifiez le code reçu. |
| `ERR-005` | 503 | Service temporairement indisponible. Réessayez plus tard. |
| `ERR-006` | 401 | Votre session a expiré. Veuillez vous reconnecter. |
| `ERR-CLIENT` | 400 | Format de code client invalide. |
| `ERR-CLIENT-NOT-FOUND` | 404 | Code client inconnu. |
| `ERR-CONTACT` | 400 | Veuillez saisir un contact valide. |
| `ERR-CONTACT-EMAIL` | 400 | L'adresse e-mail ne correspond pas à votre profil. |
| `ERR-CONTACT-PHONE` | 400 | Le numéro de téléphone ne correspond pas à votre profil. |
| `ERR-OTP-CHANNEL` | 400 | Ce canal de réception n'est pas disponible. |
| `ERR-OTP-EXPIRED` | 401 | Le code a expiré. Demandez un nouveau code. |
| `ERR-OTP-LOCKED` | 403 | Trop de tentatives. Réessayez plus tard. |
| `ERR-RESEND-COOLDOWN` | 429 | Veuillez patienter avant de renvoyer le code. |
| `ERR-AUTH-CHALLENGE-EXPIRED` | 410 | Votre authentification a expiré. Recommencez. |
| `ERR-FORBIDDEN` | 403 | Accès non autorisé sur ce terminal. |
| `ERR-RATE-LIMIT` | 429 | Trop de requêtes. Patientez quelques instants. |
| `ERR-NOT-FOUND` | 404 | Ressource introuvable. |
| `ERR-VALIDATION` | 400 | Données invalides. Vérifiez votre saisie. |
| `ERR-STATEMENT-PERIOD` | 400 | Période invalide (maximum 6 mois). |
| `ERR-DOWNLOAD-EXPIRED` | 410 | Ce lien a expiré. |
| `ERR-DOWNLOAD-ALREADY-USED` | 410 | Ce lien a déjà été utilisé. |
| `ERR-DOWNLOAD-FORBIDDEN` | 403 | Ce document n'est pas encore disponible. |
| `ERR-DEBIT-CREDIT-NOTICE` | 502 | Impossible de générer l'avis. Réessayez. |

**EN et LN** : traduire chaque clé `errors.ERR-*` dans `en.ts` et `ln.ts`.

## ActionResult — contrat API

```typescript
export type ActionResult<T> =
  | { ok: true; message?: string; data?: T }
  | { ok: false; error: string; code?: string; message?: null; data?: null };
```

### parse-kiosk-response.ts

```typescript
export async function parseKioskResponse<T>(res: Response): Promise<ActionResult<T>> {
  const body = await res.json();
  if (!body.ok) {
    return { ok: false, error: body.error ?? "Erreur", code: body.code };
  }
  return { ok: true, message: body.message, data: body.data };
}
```

### unwrap-kiosk-fetch.ts

```typescript
export function unwrapKioskFetch<T>(result: ActionResult<T>): T {
  if (!result.ok) {
    const err = new Error(result.error);
    (err as Error & { code?: string }).code = result.code;
    throw err;
  }
  return result.data as T;
}
```

## Affichage erreur UI

```tsx
// OperationResult — erreur métier
<OperationResult
  variant="error"
  title={resolveErrorMessage(locale, result.code, result.error)}
  errorCode={result.code}
  onPrimary={() => navigate("/dashboard")}
/>

// Session expirée (ERR-006)
// useKioskSessionExpired hook → redirect /auth/session-expired

// Notification Mantine
notifications.show({
  color: "red",
  title: t(locale, "common.error"),
  message: resolveErrorMessage(locale, code, error),
});
```

## Format montants & dates

```typescript
// lib/format/currency.ts
formatCdf(n: number): string   // "1 234 567 CDF" — fr-FR, entiers
formatUsd(n: number): string   // "$ 1 234,56" — fr-FR, 2 décimales

// lib/format/date.ts
formatDate(d: Date): string     // "03/07/2026 14:30"
formatDateOnly(d: Date): string // "03/07/2026"
```

Saisie kiosk : `KioskDateInput` format `DD/MM/YYYY`.  
API activité : query `?date=03/07/2026`.

## Téléphone RDC

- Indicatif par défaut `+243`
- `PhoneInputField` + `CountryCodeSelect`
- Validation Zod : regex RDC 9 chiffres après indicatif

## Clés catalogue (services.ts)

```typescript
{ labelKey: "services.accounts", descKey: "services.accountsDesc" }
{ labelKey: "services.statements", descKey: "services.statementsDesc" }
// statement-types.ts
{ labelKey: "statements.rib", descKey: "statements.ribDesc" }
{ labelKey: "statements.account-statement", descKey: "statements.accountStatementDesc" }
{ labelKey: "statements.debit-credit-notice", descKey: "statements.debitCreditNoticeDesc" }
```

## Exemple extrait messages/fr.ts

```typescript
export const fr = {
  common: {
    continue: "Continuer",
    cancel: "Annuler",
    confirm: "Confirmer",
    error: "Erreur",
    success: "Succès",
  },
  auth: {
    otp: {
      title: "Saisissez le code reçu",
      resendIn: "Renvoyer dans {seconds} s",
    },
    sessionExpired: {
      title: "Session expirée",
      message: "Veuillez vous reconnecter pour continuer.",
    },
  },
  errors: {
    generic: "Une erreur est survenue.",
    "ERR-003": "Code incorrect. Vérifiez le code reçu.",
    "ERR-006": "Votre session a expiré. Veuillez vous reconnecter.",
    "ERR-CLIENT-NOT-FOUND": "Code client inconnu.",
    // ... tous les codes du tableau ci-dessus
  },
} as const;
```

## Checklist nouvelle feature

```
- [ ] Clés fr.ts + en.ts + ln.ts
- [ ] errors.ERR-XXX si nouveau code backend
- [ ] resolve-error-message.test.ts pour nouveau code
- [ ] OperationResult affiche code ERR en variant error
- [ ] Zéro texte en dur dans JSX
```

## Utilitaires API

| Module | Rôle |
|--------|------|
| `lib/api/retry.ts` | Retry réseau transitoire |
| `lib/api/kiosk-api-health.ts` | `ensureKioskApiAvailable()` avant action critique |
| `lib/api/kiosk-api-client.ts` | `kioskFetch` — cookies + headers sécurité |

## Demo SIT (tests manuels)

- Code client : `00842693`
- OTP : `842195`
- Uniquement environnement SIT / mock — jamais documenter comme prod
