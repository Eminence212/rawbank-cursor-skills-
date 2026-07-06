# LDAP/LDAPS — impact frontend GO-PASS

> **Livré** (juillet 2026) : `/settings/ldap`, users LOCAL/LDAP, login « E-mail ou identifiant AD ».

> **Autonome** — complément frontend du plan [gopass-auth-ldap-plan.md](../rawbank-backend/references/gopass-auth-ldap-plan.md). MFA et login **API inchangés** côté contrat.

## Table des matières

- [Résumé](#résumé)
- [Pages sans changement V1](#pages-sans-changement-v1)
- [Parité MFA (obligatoire)](#parité-mfa-obligatoire)
- [Admin — création utilisateur](#admin--création-utilisateur)
- [Types TypeScript](#types-typescript)
- [UX phase 2](#ux-phase-2)
- [Tests](#tests)
- [Références liées](#références-liées)

---

## Résumé

LDAP remplace la vérification mot de passe **côté backend uniquement**. Le frontend continue d'envoyer :

```typescript
POST /api/v1/auth/login
{ email: string; password: string }
```

Le client **ne connaît pas** `auth_provider` au login.

**Administration** : l'ADMIN configure **chaque utilisateur** en `LOCAL` ou `LDAP` ; **plusieurs comptes LDAP** coexistent. Chaque compte LDAP a un **`ldapUsername`** (= `sAMAccountName`).

Login : e-mail (LOCAL) ou **sAMAccountName** (LDAP) dans le même champ ; libellé « E-mail ou identifiant AD ».

---

## Pages sans changement V1

| Page / module | Changement |
|---------------|------------|
| `LoginPage` | **Aucun** — e-mail + mot de passe |
| `AuthContext` / `lib/api.ts` | **Aucun** |
| `MfaPage` | **Aucun** |
| `MfaEnrollPage` | **Aucun** |
| `TotpEnrollmentGuard` | **Aucun** |
| `ProtectedRoute`, `AccessRoute` | **Aucun** |

Statuts `LoginResultDto` attendus (inchangés) :

```typescript
type LoginStatus = "AUTHENTICATED" | "MFA_REQUIRED";
```

---

## Parité MFA (obligatoire)

Aucune modification de `mfa-requirements.ts` si le backend conserve :

| Règle | Fonction frontend | Backend |
|-------|-------------------|---------|
| Enrollment TOTP | `requiresTotpEnrollment(user)` | `User.requiresTotpEnrollment()` |
| Challenge login | `requiresLoginMfaChallenge(user)` | `User.isLoginMfaReady()` |
| Post-login | `getPostAuthPath(user)` | — |
| Post MFA verify | `POST_MFA_VERIFY_PATH` → `/dashboard` | — |

Flux identique après bind LDAP réussi :

```
/login → (LDAP bind OK backend) → /mfa ou /mfa/enroll ou /dashboard
```

Tests à maintenir : `mfa-requirements.test.ts`.

Détail MFA : [gopass-lib-auth-mfa.md](gopass-lib-auth-mfa.md)

---

## Admin — configuration serveur LDAP (obligatoire)

Page **`/settings/ldap`** · permission **`admin:settings`** · données en **base Oracle** (`ldap_settings`).

| Composant | Rôle |
|-----------|------|
| `LdapSettingsPage` | Formulaire URL, DN, OU, filtre, bind DN, mot de passe bind, mode, activer |
| `lib/ldap-settings.ts` | `getLdapSettings`, `updateLdapSettings`, `testLdapConnection` |
| `SettingsLayout` | Nav « Annuaire LDAP » |

```typescript
// GET /api/v1/admin/ldap-settings — bindPassword jamais renvoyé
type LdapSettingsDto = {
  enabled: boolean;
  authMode: "local" | "ldap" | "hybrid";
  url: string;
  baseDn: string;
  userSearchBase: string;
  userSearchFilter: string;
  bindDn: string;
  bindPassword?: string;       // PUT only — vide = conserver
  connectTimeoutMs: number;
  readTimeoutMs: number;
  poolEnabled: boolean;
  tlsTruststorePath?: string;
  tlsTruststorePassword?: string;
};
```

Actions UI : **Enregistrer** (PUT) · **Tester la connexion** (POST `/test`).

---

## Admin — création et édition utilisateur (obligatoire)

**Exigence** : l'ADMIN choisit `LOCAL` ou `LDAP` **par compte** ; les deux types **coexistent** dans l'app.

### Phase 2 UI

| Composant | Modification |
|-----------|--------------|
| `CreateUserModal` | `LOCAL` : mot de passe ; `LDAP` : champ **`ldapUsername`** + masquer mot de passe |
| `AdminUserFormFields` (édition) | `authProvider` + `ldapUsername` si LDAP |
| `LoginPage` | Libellé « E-mail ou identifiant AD » |
| `UsersTable` / fiche | Badge ou colonne `LOCAL` / `LDAP` |

Transitions édition : `LDAP` → `LOCAL` = mot de passe GO-PASS requis ; `LOCAL` → `LDAP` = supprimer mot de passe local.

### Comportement formulaire

```tsx
<SegmentedControl
  value={authProvider}
  onChange={(v) => setAuthProvider(v as "LOCAL" | "LDAP")}
  data={[
    { label: "Mot de passe GO-PASS", value: "LOCAL" },
    { label: "Annuaire LDAP / AD", value: "LDAP" },
  ]}
/>

{authProvider === "LOCAL" && (
  <PasswordInput /* mot de passe initial */ />
)}

{authProvider === "LDAP" && (
  <Text size="sm" c="dimmed">
    Connexion via mot de passe Active Directory. MFA GO-PASS obligatoire.
  </Text>
)}
```

### API admin (backend Phase 2)

```typescript
// POST /api/v1/admin/users  +  PUT /api/v1/admin/users/{id}
type CreateAdminUserRequest = {
  // ...existants
  authProvider?: "LOCAL" | "LDAP";
  ldapUsername?: string;  // obligatoire si LDAP — sAMAccountName AD
  // password omis si LDAP ; requis si LOCAL
};

type AdminUserDetail = {
  // ...existants
  authProvider: "LOCAL" | "LDAP";
};
```

---

## Types TypeScript

```typescript
// types/auth.ts — extension profil (optionnel affichage admin)
export type UserAuthProvider = "LOCAL" | "LDAP";

export type UserProfile = {
  // ...existants
  authProvider?: UserAuthProvider;  // exposé via GET /auth/me ou admin seulement
};
```

`GET /auth/me` : exposer `authProvider` **optionnel** (lecture seule) pour badge admin — pas requis pour login flow.

---

## UX phase 2

- Login : texte d'aide « E-mail professionnel Rawbank »
- Liste users : colonne ou badge `LOCAL` / `LDAP`
- Doc utilisateur : MFA reste requis même avec AD

---

## Tests

| Test | Scénario |
|------|----------|
| `mfa-requirements.test.ts` | Régression — aucun changement attendu |
| E2E `auth-otp.spec.ts` | Régression login LOCAL |
| E2E (nouveau) | `/settings/ldap` — save + test connexion |
| E2E (nouveau) | ADMIN change LOCAL ↔ LDAP en édition |

---

## Références liées

- Plan backend complet : [gopass-auth-ldap-plan.md](../rawbank-backend/references/gopass-auth-ldap-plan.md)
- MFA actuel : [gopass-lib-auth-mfa.md](gopass-lib-auth-mfa.md)
- Composants admin : [gopass-ui-components.md](gopass-ui-components.md)

*Planification — implémentation non démarrée.*
