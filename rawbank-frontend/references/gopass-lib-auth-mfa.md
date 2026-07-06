# Auth & MFA — GO-PASS frontend

> **Autonome** : code source complet des règles MFA ci-dessous (parité obligatoire backend ↔ frontend). Pas besoin d'ouvrir `lib/auth/` si cette référence est chargée.

## Parité backend ↔ frontend (obligatoire)

| Règle métier | Backend `User.java` | Frontend `mfa-requirements.ts` |
|--------------|---------------------|-------------------------------|
| Enrollment TOTP requis | `requiresTotpEnrollment()` | `requiresTotpEnrollment(user)` |
| Challenge login MFA | `isLoginMfaReady()` | `requiresLoginMfaChallenge(user)` |
| Après login JWT direct | enroll ou tokens | `getPostAuthPath(user)` |
| Après verify MFA | dashboard | `POST_MFA_VERIFY_PATH` → `/dashboard` |

**Mapping API JSON** : `TOTP` / `EMAIL` ↔ enum backend `UserMfaMethod.TOTP` / `EMAIL_OTP`

Toute modification → mettre à jour **les deux** + tests `mfa-requirements.test.ts`, `AuthServiceLoginTest`, `MfaServiceTest`.

## LDAP/LDAPS (livré V30–V31)

L'authentification annuaire remplace **uniquement** la vérification mot de passe (`POST /auth/login`). **Aucun changement** dans `mfa-requirements.ts` :

- Mêmes statuts `AUTHENTICATED` / `MFA_REQUIRED`
- Mêmes guards `TotpEnrollmentGuard`, `MfaPage`, `MfaEnrollPage`
- MFA TOTP et OTP e-mail **obligatoires** pour comptes LDAP
- Login : e-mail ou sAMAccountName (champ API `email`)

Référence : [gopass-auth-ldap-frontend.md](gopass-auth-ldap-frontend.md) · backend : [gopass-auth-ldap-plan.md](../rawbank-backend/references/gopass-auth-ldap-plan.md)

## Code frontend complet (`mfa-requirements.ts`)

```typescript
import type { UserProfile } from "@/types/auth";

export const MFA_VERIFY_PATH = "/mfa" as const;
export const MFA_ENROLL_PATH = "/mfa/enroll" as const;

/** MFA TOTP activé et authenticator non configuré — enrollment obligatoire après JWT. */
export function requiresTotpEnrollment(user: UserProfile): boolean {
  return user.mfaEnabled && user.mfaMethod === "TOTP" && !user.totpEnrolled;
}

/** Compte prêt pour /mfa : TOTP enrollé ou méthode OTP e-mail. */
export function requiresLoginMfaChallenge(user: UserProfile): boolean {
  return user.mfaEnabled && !requiresTotpEnrollment(user);
}

/** Après connexion directe (JWT sans /mfa) : enrollment TOTP ou dashboard. */
export function getPostAuthPath(user: UserProfile): typeof MFA_ENROLL_PATH | "/dashboard" {
  return requiresTotpEnrollment(user) ? MFA_ENROLL_PATH : "/dashboard";
}

export const POST_MFA_VERIFY_PATH = "/dashboard" as const;
```

## Code backend équivalent (`User.java`)

```java
/** TOTP activé mais authenticator non configuré — enrollment avant l'accès à l'app. */
public boolean requiresTotpEnrollment() {
    return mfaEnabled && mfaMethod == UserMfaMethod.TOTP && !isTotpEnrolled();
}

/** Compte prêt pour l'étape /mfa : TOTP enrollé ou OTP e-mail. */
public boolean isLoginMfaReady() {
    return mfaEnabled && !requiresTotpEnrollment();
}
```

## Flux login backend (`AuthService`)

```java
// POST /auth/login
if (user.requiresTotpEnrollment()) {
    return LoginResultDto.authenticated(issueTokens(user));  // JWT + redirect frontend /mfa/enroll
}
if (user.isLoginMfaReady()) {
    return LoginResultDto.mfaRequired(mfaService.startLoginChallenge(user));  // → /mfa
}
return LoginResultDto.authenticated(issueTokens(user));  // → /dashboard
```

## Flux login UI (routing)

```
/login → POST /auth/login
  → JWT + profil user (/auth/me)
  → requiresLoginMfaChallenge ? /mfa
  → requiresTotpEnrollment ? /mfa/enroll
  → sinon /dashboard

/mfa → POST /auth/mfa/verify → POST_MFA_VERIFY_PATH (/dashboard)

/mfa/enroll → POST totp/enroll + confirm → /dashboard
```

## Type `UserProfile` (champs MFA pertinents)

```typescript
type UserProfile = {
  id: string;
  email: string;
  name: string;
  roleCode: RoleCode;           // ADMIN | ECONOMA | REGION | AGENCE | GUICHET | AUDIT
  organizationId: string;
  permissions: string[];        // codes sans PERM_
  mfaEnabled: boolean;
  mfaMethod?: "TOTP" | "EMAIL";
  totpEnrolled?: boolean;
};
```

## Guards React

```tsx
// TotpEnrollmentGuard — bloque l'app si TOTP requis non enrollé
if (requiresTotpEnrollment(user)) return <Navigate to="/mfa/enroll" />;

// GuestRoute — /login inaccessible si déjà connecté
// ProtectedRoute — redirect /login si pas de token JWT
// AccessRoute — permission RBAC sur la route
```

## RBAC UI

```typescript
// lib/rbac.ts — délègue à lib/auth/rbac
export function hasPermission(user: UserProfile | null | undefined, code: string): boolean {
  return sessionHasPermission(user ? { user } : null, code);
}

hasPermission(user, 'sale:cancel');
hasAnyPermission(user, ['stock:read:own', 'stock:read:descendants']);
```

Permissions chargées depuis `GET /auth/me` — liste de codes **sans** préfixe `PERM_`.

## Session JWT

| Élément | Détail |
|---------|--------|
| Stockage | Access + refresh token (localStorage via `lib/api.ts`) |
| Refresh | Intercepteur Axios automatique sur 401 |
| Logout | `POST /auth/logout` + clear storage |
| Base URL | `/api/v1` (proxy Vite dev → `:8080`) |

## Modules auth (rôles)

| Module | Rôle |
|--------|------|
| `mfa-requirements.ts` | Guards routing MFA |
| `mfa-labels.ts` | Libellés méthode, hints UI |
| `mfa-challenge-storage.ts` | Challenge pending en `sessionStorage` |
| `validate-mfa-code.ts` | Validation code 6 chiffres |
| `AuthContext.tsx` | Provider session user + tokens |

## Composants UI auth

| Composant | Rôle |
|-----------|------|
| `AuthPageShell` | Layout login/MFA centré + logo |
| `MfaCodeInput` | 6 cases, auto-focus, `validateMfaCode()` |
| `MfaStatusBadge` | Badge méthode MFA sur fiche user |
| `RouteLoadingScreen` | Loader global pendant auth check |

## Admin MFA

- `AdminMfaMethodSelect` — choix TOTP ou EMAIL_OTP à la création
- `PATCH /admin/users/{id}/mfa` — activation admin
- `CredentialTransmitNotice` — bandeau transmission mot de passe initial

## Variables env MFA (backend)

| Variable | Usage |
|----------|--------|
| `MFA_TOTP_ENCRYPTION_KEY` | Chiffrement secret TOTP (≥ 32 octets prod) |
| `MFA_EMAIL_OTP_TTL_MINUTES` | TTL code e-mail (défaut 10) |
| `MFA_CHALLENGE_TTL_MINUTES` | TTL challenge login (défaut 5) |
| `MFA_DEV_EXPOSE_OTP` | `false` en prod — ne jamais exposer OTP en API |

## Tests à maintenir

- `mfa-requirements.test.ts` — toutes branches `getPostAuthPath`, enrollment, challenge
- `AuthServiceLoginTest` — parité login MFA backend
- `MfaServiceTest` — OTP e-mail, TOTP verify
