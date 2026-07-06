# Plan LDAP/LDAPS — GO-PASS backend

> **Autonome** — plan d'implémentation v1.1 (juillet 2026). **Incréments 1–2 livrés** (labo AD validé) ; Phase 3 SIT LDAPS à venir.  
> **Principe** : LDAP remplace **uniquement** la vérification mot de passe ; MFA TOTP + OTP e-mail, RBAC Oracle et JWT **inchangés**.

## Table des matières

- [Contexte](#contexte)
- [Principes directeurs](#principes-directeurs)
- [Architecture](#architecture)
- [Flux login](#flux-login)
- [Flyway V30](#flyway-v30)
- [Composants Spring Boot](#composants-spring-boot)
- [Variables d'environnement](#variables-denvironnement)
- [LDAPS](#ldaps)
- [Provisioning](#provisioning)
- [Sécurité](#sécurité)
- [Phases d'implémentation](#phases-dimplémentation)
- [Tests](#tests)
- [Décisions ouvertes](#décisions-ouvertes)
- [Références liées](#références-liées)

---

## Contexte

### État actuel (livré)

| Composant | Comportement |
|-----------|--------------|
| Credentials | E-mail + mot de passe, **BCrypt** (`users.password_hash`) |
| MFA | Post-mot de passe : TOTP ou OTP e-mail ; enrollment TOTP si requis |
| JWT | Émis **après** MFA validé (ou sans MFA si désactivé) |
| RBAC | Rôle, org, permissions — **100 % Oracle** |
| Blocage | `login_locked` après N échecs ; `active` pour désactivation admin |

Classes existantes : `AuthService.login()`, `MfaService`, `FailedLoginAttemptService`.

### Besoin

- Authentification **Active Directory / LDAP** pour collaborateurs Rawbank.
- **Conserver** MFA applicatif GO-PASS (US-A05).
- Compte **break-glass** LOCAL (ADMIN) si annuaire indisponible.
- L'**ADMIN** configure **par utilisateur** `auth_provider` (`LOCAL` \| `LDAP`) ; **les deux coexistent** sur la même instance.

---

## Principes directeurs

| # | Principe |
|---|----------|
| P1 | LDAP = vérification mot de passe **seulement** |
| P2 | User **doit exister** dans Oracle (rôle + org) — pas de JIT V1 |
| P3 | Même API `POST /api/v1/auth/login` — client opaque au provider |
| P3bis | **Choix ADMIN par utilisateur** : `LOCAL` et `LDAP` **coexistent** ; routage login selon `user.auth_provider` uniquement |
| P4 | MFA inchangé : `/mfa/verify`, `/mfa/totp/enroll`, variables `MFA_*` |
| P5 | **LDAPS** obligatoire en prod |
| P6 | Ne **jamais** stocker le mot de passe AD en Oracle |
| P7 | Audit : `AUTH.LOGIN_LDAP_SUCCESS` / `AUTH.LOGIN_LDAP_FAILED` |

---

## Architecture

```
LoginPage → POST /auth/login → AuthService
  → find User by email
  → CredentialAuthenticatorFactory
       LOCAL → LocalPasswordAuthenticator (BCrypt)
       LDAP  → LdapPasswordAuthenticator (bind LDAPS)
  → si OK → resolvePostPasswordLogin()  // MFA branches existantes
  → MfaService → POST /mfa/verify → JWT
```

| Couche | LDAP | MFA | RBAC |
|--------|------|-----|------|
| Annuaire | Bind utilisateur | — | — |
| Oracle `users` | `auth_provider` | `mfa_*`, TOTP chiffré | `role_id`, `organization_id` |
| JWT | — | Après MFA | Permissions via `/auth/me` |

**Ne pas** activer `ldapAuthentication()` dans `SecurityFilterChain` — auth programmatique dans `AuthService` (JWT custom actuel).

### Coexistence LOCAL + LDAP

| Niveau | Rôle |
|--------|------|
| `users.auth_provider` | Choix **ADMIN** à création/édition — `LOCAL` ou `LDAP` par compte |
| `GOPASS_AUTH_MODE` | Garde-fou infra (`hybrid` = les deux providers actifs selon chaque user) |

Règles transition (édition ADMIN) : `LOCAL` → `LDAP` supprime mot de passe GO-PASS ; `LDAP` → `LOCAL` exige définition mot de passe.

---

## Flux login

### Nominal (LDAP + MFA TOTP)

```
1. POST /auth/login { email, password }  // email = loginId (e-mail ou sAMAccountName)
2. User par ldap_username ou email ; LDAP exige ldap_username renseigné
3. auth_provider = LDAP → search (sAMAccountName={ldap_username}) + bind
   auth_provider = LOCAL → BCrypt
```

### Messages API (anti-énumération)

- Utilisateur inconnu : « Adresse e-mail incorrecte. »
- Mot de passe / bind échoué : « Mot de passe incorrect. »
- AD indisponible : HTTP 503 message neutre (pas de détail LDAP)

### Endpoints inchangés

| Méthode | Path | Rôle |
|---------|------|------|
| POST | `/api/v1/auth/login` | Credentials + branche MFA |
| POST | `/api/v1/auth/mfa/verify` | Finalise connexion |
| POST | `/api/v1/auth/mfa/totp/enroll` | Enrollment TOTP |
| GET | `/api/v1/auth/me` | Profil + permissions |

---

## Flyway V30

### `V30__user_auth_provider_ldap.sql`

```sql
ALTER TABLE users ADD (
    auth_provider VARCHAR2(16) DEFAULT 'LOCAL' NOT NULL
);

ALTER TABLE users ADD CONSTRAINT chk_users_auth_provider
    CHECK (auth_provider IN ('LOCAL', 'LDAP'));

-- Option A recommandée : pas de hash local pour comptes LDAP
ALTER TABLE users MODIFY (password_hash NULL);

ALTER TABLE users ADD (ldap_username VARCHAR2(255) NULL);

CREATE UNIQUE INDEX uk_users_ldap_username ON users (
    (CASE WHEN ldap_username IS NOT NULL THEN LOWER(ldap_username) END)
);

UPDATE users SET auth_provider = 'LOCAL';
```

Login AD : `(sAMAccountName={0})` avec `{0}` = `users.ldap_username`. **Plusieurs** comptes LDAP possibles.

### V31 — `ldap_settings` (config serveur en base + UI)

Table singleton `ldap_settings` (`id='default'`) : `url`, `base_dn`, `user_search_base`, `user_search_filter`, `bind_dn`, `bind_password_enc` (AES), `auth_mode`, `enabled`, timeouts, truststore.

- API : `GET/PUT /api/v1/admin/ldap-settings`, `POST .../test` — permission `admin:settings`
- UI : **`/settings/ldap`** (`LdapSettingsPage`)
- Env seule : `LDAP_SETTINGS_ENCRYPTION_KEY` (+ bootstrap dev optionnel)

Seed labo : `ldap://192.168.64.10:389`, `DC=develop,DC=local`, `OU=Utilisateurs,DC=develop,DC=local`, `(sAMAccountName={0})`.

### Enum Java

```java
public enum UserAuthProvider {
    LOCAL,  // BCrypt
    LDAP    // bind annuaire ; password_hash ignoré
}
```

### DTO et API admin

**Exigence** : ADMIN choisit `authProvider` par compte ; LOCAL et LDAP coexistent.

```java
// CreateAdminUserRequest / UpdateAdminUserRequest / AdminUserDetailDto
@NotNull UserAuthProvider authProvider;  // défaut LOCAL

// LOCAL : password requis ; BCrypt en base
// LDAP  : ldap_username obligatoire (sAMAccountName) ; password_hash NULL ; email = mail AD
```

| Endpoint | Champ |
|----------|-------|
| `POST /api/v1/admin/users` | `authProvider`, `ldapUsername` |
| `PUT /api/v1/admin/users/{id}` | `authProvider`, `ldapUsername` |
| `GET` admin users | `authProvider` (liste / badge) |

---

## Composants Spring Boot

### Dépendance Maven

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-ldap</artifactId>
</dependency>
```

### Nouvelles classes

| Classe | Rôle |
|--------|------|
| `LdapProperties` | URL, base DN, bind DN, filtres, timeouts, TLS |
| `LdapConfig` | `LdapContextSource`, `LdapTemplate`, truststore |
| `CredentialAuthenticator` | `boolean authenticate(User, rawPassword)` |
| `LocalPasswordAuthenticator` | BCrypt (extrait de `AuthService`) |
| `LdapPasswordAuthenticator` | search DN + bind |
| `CredentialAuthenticatorFactory` | Route selon `UserAuthProvider` |

### Algorithme bind

```
1. Bind compte service (LDAP_BIND_DN)
2. Search sous LDAP_USER_SEARCH_BASE : (sAMAccountName={0}), {0} = user.ldapUsername
3. Bind utilisateur DN + password
4. Ne pas persister password en Oracle
```

### Refactor AuthService.login()

```java
User user = loadUserOrThrow(email);
ensureAccountUsable(user);

if (!credentialAuthenticatorFactory.forProvider(user.getAuthProvider())
        .authenticate(user, request.password())) {
    return handleFailedPassword(user);
}
clearFailedLoginAttempts(user);
return resolvePostPasswordLogin(user);  // MFA inchangé
```

### MFA — pas de modification

`MfaService.startLoginChallenge()` / `verifyLoginChallenge()` restent identiques.

### Audit

| Action | Quand |
|--------|-------|
| `AUTH.LOGIN_LDAP_SUCCESS` | Bind OK, avant MFA |
| `AUTH.LOGIN_LDAP_FAILED` | Bind échoué |
| `AUTH.LOGIN_LOCAL_SUCCESS` | BCrypt OK |

---

## Configuration annuaire — base Oracle + UI

**Source de vérité** : table `ldap_settings` (pas les variables `LDAP_*` en prod).

| Variable env | Description |
|--------------|-------------|
| `LDAP_SETTINGS_ENCRYPTION_KEY` | Clé AES pour `bind_password_enc` en base — **obligatoire** si LDAP actif |
| `LDAP_SETTINGS_BOOTSTRAP` | Dev : import initial si table vide |

Champs en base (saisis via **`/settings/ldap`**) : `url`, `base_dn`, `user_search_base`, `user_search_filter`, `bind_dn`, `bind_password_enc`, `auth_mode`, `enabled`, timeouts, truststore.

Labo seed : `ldap://192.168.64.10:389`, `OU=Utilisateurs,DC=develop,DC=local`.

Variables MFA **inchangées** — voir [gopass-services-env.md](gopass-services-env.md).

---

## LDAPS

| Env | Protocole |
|-----|-----------|
| Dev labo | `ldap://192.168.64.10:389` (TCP OK — juillet 2026) |
| Dev (fallback) | `ldap://` OpenLDAP / Samba AD test |
| SIT / Prod | `ldaps://` + truststore CA |

`GopassSecurityStartupValidator` (prod) :

- Si `ldap_settings.enabled = 1` et prod → `url` doit être `ldaps://`
- Truststore obligatoire — pas de `TrustAll`

---

## Provisioning

### V1 — ADMIN choisit LOCAL ou LDAP (coexistence)

**Collaborateur LDAP** : `auth_provider=LDAP`, e-mail = mail AD, pas de mot de passe GO-PASS.

**Compte LOCAL** (break-glass, prestataire…) : `auth_provider=LOCAL`, mot de passe GO-PASS + MFA.

Même agence peut mélanger les deux types. Exemple : `guichet1@` LDAP, `guichet2@` LOCAL, `admin@rawbank.local` LOCAL.

### V2+ (hors scope V1)

- JIT création inactive
- Sync `displayName` depuis AD
- Groupes AD → rôles GO-PASS

---

## Sécurité

| Sujet | Mesure |
|-------|--------|
| Mot de passe AD | Bind uniquement, jamais loggé ni stocké |
| Break-glass | ≥ 1 compte LOCAL ADMIN actif |
| Lockout | `login_locked` Oracle (indépendant AD) |
| MFA bypass | **Interdit** — LDAP ≠ MFA suffisant |
| LDAP injection | Échapper `email` dans filtre de recherche |
| Disponibilité AD | 503 neutre ; break-glass LOCAL |

---

## Phases d'implémentation

| Phase | Livrable | Durée |
|-------|----------|-------|
| 0 | Cadrage IT (URL, filtre, truststore) | 1–2 j |
| 1 | V30, LDAP auth, refactor AuthService, tests Testcontainers | 3–5 j |
| 2 | Admin API + UI `authProvider` | 2–3 j |
| 3 | SIT LDAPS + recette T1-LDAP-* | 3–5 j |
| 4 | Prod Dokploy `hybrid` | 1 j |

**Total** : 10–15 j ouvrés.

### Checklist Phase 1 backend

```
- [ ] V30__user_auth_provider_ldap.sql
- [ ] UserAuthProvider enum + User entity
- [ ] LdapProperties, LdapConfig
- [ ] LocalPasswordAuthenticator + LdapPasswordAuthenticator
- [ ] Refactor AuthService.login()
- [ ] AuthServiceLoginTest régression LOCAL
- [ ] AuthServiceLoginLdapMfaTest nouveau
- [ ] LdapPasswordAuthenticatorTest + Testcontainers OpenLDAP
```

---

## Tests

### Automatisés

| Test | Scénario |
|------|----------|
| `LdapPasswordAuthenticatorTest` | Bind OK / KO / user AD absent |
| `AuthServiceLoginTest` | LOCAL régression |
| `AuthServiceLoginLdapMfaTest` | LDAP → MFA_REQUIRED → verify → JWT |
| `AuthServiceLoginLdapTotpEnrollTest` | LDAP → enrollment TOTP |

### Recette manuelle (US-A06)

| ID | Scénario | Attendu |
|----|----------|---------|
| T1-LDAP-01 | LDAP + MFA TOTP | Login → MFA → dashboard |
| T1-LDAP-02 | Mauvais mot de passe LDAP | Message générique ; lockout après N |
| T1-LDAP-03 | LOCAL admin en `hybrid` | Login BCrypt OK |
| T1-LDAP-04 | LDAP user `active=false` | Refus avant bind |
| T1-LDAP-05 | E-mail inconnu Oracle | Refus avant LDAP |
| T1-LDAP-06 | LDAP + MFA e-mail | OTP après bind |
| T1-LDAP-07 | AD down | 503 ; break-glass LOCAL OK |

---

## Décisions ouvertes

| # | Question | Recommandation |
|---|----------|----------------|
| D1 | `mail` vs `userPrincipalName` ? | **`mail`** si = e-mail Oracle |
| D2 | `password_hash` nullable LDAP ? | **Oui** |
| D3 | JIT auto-création ? | **Non V1** |
| D4 | Désactiver MFA LDAP ? | **Non** |
| D5 | Sync groupes AD → rôles ? | Hors scope |
| D6 | Failover multi-DC ? | Clarifier avec IT |

---

## Séquence LDAP + MFA TOTP

```
Utilisateur → Frontend: email + password AD
Frontend → AuthService: POST /auth/login
AuthService → Oracle: findByEmail
AuthService → LdapAuthenticator: authenticate
LdapAuthenticator → LDAPS: search DN + bind
AuthService → MfaService: startLoginChallenge
Frontend ← MFA_REQUIRED + pendingToken
Utilisateur → code TOTP
Frontend → AuthService: POST /auth/mfa/verify
Frontend ← JWT → /dashboard
```

---

## Références liées

- MFA actuel (inchangé) : parité [gopass-lib-auth-mfa.md](../rawbank-frontend/references/gopass-lib-auth-mfa.md)
- Frontend admin UI : [gopass-auth-ldap-frontend.md](../rawbank-frontend/references/gopass-auth-ldap-frontend.md)
- Variables env actuelles : [gopass-services-env.md](gopass-services-env.md)
- Migrations IAM : [gopass-migrations-rbac.md](gopass-migrations-rbac.md)
- API auth : [gopass-api-patterns.md](gopass-api-patterns.md)

*Planification — implémentation non démarrée.*
