# Migrations & RBAC — GO-PASS

> **Autonome** : matrice IAM complète, historique Flyway et templates SQL ci-dessous.

## Règles Flyway

| Règle | Détail |
|-------|--------|
| Nommage | `V{n}__snake_case_description.sql` |
| Idempotence RBAC | `INSERT ... WHERE NOT EXISTS` |
| Oracle | SID `GOPASS`, schéma `GOPASS` |
| ddl-auto | `validate` — jamais `update` en prod |
| Migration appliquée | **Ne jamais modifier** — créer `V{n+1}` |

## Catalogue permissions (V2 seed)

| id | code | label |
|----|------|-------|
| perm-01 | `stock:read:own` | Consulter stock périmètre propre |
| perm-02 | `stock:read:descendants` | Consulter stock niveaux inférieurs |
| perm-03 | `stock:read:national` | Consulter stock national |
| perm-04 | `stock:receive` | Réceptionner stock entrant |
| perm-05 | `stock:transfer` | Transférer vers niveau inférieur |
| perm-06 | `sale:create` | Vendre au guichet |
| perm-07 | `sale:cancel` | Annuler vente |
| perm-08 | `inventory:session` | Inventaire guichet |
| perm-09 | `inventory:validate` | Valider inventaire |
| perm-10 | `report:read` | Reporting / exports |
| perm-11 | `audit:read` | Journal d'audit |
| perm-12 | `alert:read` | Consulter alertes |
| perm-13 | `alert:ack` | Accuser / traiter alertes |
| perm-14 | `admin:users` | Gestion utilisateurs |
| perm-15 | `admin:settings` | Paramètres référentiel |
| perm-16 | `threshold:manage` | Gérer seuils de stock |

**Spring Security** : autorité = `PERM_<code>` (ex. `PERM_sale:cancel`).

**Frontend** : codes **sans** préfixe `PERM_` via `hasPermission(user, 'sale:cancel')`.

## Rôles IAM

| id | code | label |
|----|------|-------|
| role-admin | `ADMIN` | Administrateur |
| role-economa | `ECONOMA` | Economat central |
| role-region | `REGION` | Région |
| role-agence | `AGENCE` | Agence |
| role-guichet | `GUICHET` | Guichet aéroport |
| role-audit | `AUDIT` | Contrôle interne / Audit |

## Matrice role → permissions (V2 + V27/V28)

| Permission | ADMIN | ECONOMA | REGION | AGENCE | GUICHET | AUDIT |
|------------|:-----:|:-------:|:------:|:------:|:-------:|:-----:|
| stock:read:own | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| stock:read:descendants | ✓ | ✓ | ✓ | — | — | — |
| stock:read:national | ✓ | ✓ | — | — | — | — |
| stock:receive | ✓ | ✓ | ✓ | ✓ | ✓* | — |
| stock:transfer | ✓ | ✓ | ✓ | ✓* | ✓* | — |
| sale:create | ✓ | ✓ | — | — | ✓ | — |
| sale:cancel | ✓ | ✓ | — | ✓ | — | — |
| inventory:session | ✓ | ✓ | — | ✓ | — | — |
| inventory:validate | ✓ | ✓ | — | ✓ | — | — |
| report:read | ✓ | ✓ | ✓ | ✓ | — | ✓ |
| audit:read | ✓ | ✓ | ✓ | ✓ | — | ✓ |
| alert:read | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| alert:ack | ✓ | ✓ | ✓ | ✓ | ✓ | — |
| admin:users | ✓ | ✓ | — | — | — | — |
| admin:settings | ✓ | ✓ | — | — | — | — |
| threshold:manage | ✓ | ✓ | — | ✓ | — | — |

\* `stock:receive` GUICHET ajouté en **V28** ; `stock:transfer` AGENCE+GUICHET en **V27**.

ADMIN et ECONOMA reçoivent **toutes** les permissions (SELECT id FROM permissions).

## Hiérarchie organisations

```
ECONOMA → REGION → AGENCE → GUICHET
```

Table `organizations` : colonnes `org_type`, `code`, `parent_id`, `region_id`, `site_signature`.

Site seed V2 : `org-economa` (ECONOMA, code `ECONOMA`).

User admin seed : `admin@rawbank.local` / rôle ADMIN / org `org-economa`.

## Historique migrations (résumé)

| V | Sujet |
|---|--------|
| V1 | Schéma IAM + métier (users, roles, permissions, organizations, stocks, ventes…) |
| V2 | Seed permissions, rôles, matrice RBAC, produits GO-PASS, stock initial |
| V3 | MFA colonnes utilisateur |
| V4–V19 | Domaine métier (mouvements, appro, inventaire, audit, alertes…) |
| V20 | MFA challenges (bases héritées Flyway ≥ 4) |
| V21–V26 | MFA par user, blocage login, email outbox |
| V27 | `stock:transfer` → rôles AGENCE + GUICHET |
| V28 | `stock:receive` → rôle GUICHET |
| V29 | Index partiel `uk_sales_unit_active` — revente après annulation |

## Ajouter une permission à un rôle (template V{n+1})

```sql
-- 1. Créer la permission si nouvelle
INSERT INTO permissions (id, code, label)
SELECT 'perm-xx', 'ma:permission', 'Libellé'
FROM dual
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE code = 'ma:permission');

-- 2. Attribuer au rôle
INSERT INTO role_permissions (role_id, permission_id)
SELECT 'role-guichet', p.id
FROM permissions p
WHERE p.code = 'ma:permission'
  AND NOT EXISTS (
    SELECT 1 FROM role_permissions rp
    WHERE rp.role_id = 'role-guichet' AND rp.permission_id = p.id
  );
```

Puis côté Java :

```java
@PreAuthorize("hasAuthority('PERM_ma:permission')")
```

## Index partiel Oracle (V29)

```sql
CREATE UNIQUE INDEX uk_sales_unit_active ON sales (unit_id)
WHERE status != 'ANNULEE';
```

Remplace contrainte globale `uk_sales_unit` qui bloquait la revente d'une unité après annulation.

Message handler : `GlobalExceptionHandler` → « Cette unité est déjà vendue. » si violation `UK_SALES_UNIT_ACTIVE`.

## Tables IAM principales

- `users` — `email`, `password_hash`, `organization_id`, `role_id`, `mfa_enabled`, `mfa_method`, `totp_enrolled`
- `roles`, `permissions`, `role_permissions`, `user_permissions`
- `organizations` — types `ECONOMA`, `REGION`, `AGENCE`, `GUICHET`
- `mfa_secrets`, `mfa_challenges`, `email_outbox`

## Tables métier principales

- `gopass_products`, `stock_locations`, `stock_units`, `stock_movements`
- `sales` — statuts `CONFIRMEE`, `ENREGISTREE`, `RECONCILIEE`, `ANNULEE`
- `supply_orders`, `supply_order_lines` — statuts appro
- `inventory_sessions`, `inventory_counts`
- `audit_logs`, `alerts`, `thresholds`

## Produits GO-PASS seed (V2)

| id | kind | face_value | serial_pattern |
|----|------|------------|----------------|
| seed-product-nat | NATIONAL | 10 CDF | `^\d+/1951/25/N$` |
| seed-product-int | INTERNATIONAL | 50 CDF | `^\d+/1951/25/I$` |

`validity_days=365`, `expiration_warning_days=60`, `expiration_critical_days=30`.
