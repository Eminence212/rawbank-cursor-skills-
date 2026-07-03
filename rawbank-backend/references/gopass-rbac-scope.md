# RBAC & périmètre — GO-PASS backend

> **Autonome** : règles de scope et matrice permissions incluses. Voir aussi `gopass-migrations-rbac.md` pour le seed SQL complet.

## Hiérarchie organisation

```
ECONOMA → REGION → AGENCE → GUICHET
```

- Chaque `User` : un `Role` + une `Organization`
- Guichets : `parent_id` = agence parente
- `OrganizationScopeService` : filtre toutes les données multi-sites

## Trois couches (ne jamais en sauter une)

| Couche | Mécanisme | Exemple |
|--------|-----------|---------|
| Permission IAM | `@PreAuthorize` | `hasAuthority('PERM_sale:cancel')` |
| Périmètre données | `*ScopeService` | Guichet ne voit que ses ventes actives |
| Flags UI | DTO `canXxx` | `canCancel = permission + scope + statut` |

## Rôles — permissions effectives

### GUICHET (base V2 + V27/V28)

```
stock:read:own, sale:create, alert:read, alert:ack,
stock:transfer (V27), stock:receive (V28)
```

### AGENCE (base V2 + V27)

```
stock:read:own, stock:receive, sale:cancel, threshold:manage,
inventory:session, inventory:validate,
report:read, audit:read, alert:read, alert:ack,
stock:transfer (V27)
```

### REGION

```
stock:read:own, stock:read:descendants, stock:receive, stock:transfer,
report:read, audit:read, alert:read, alert:ack
```

### ECONOMA / ADMIN

Toutes les permissions (`SELECT id FROM permissions`).

### AUDIT

```
stock:read:own, report:read, audit:read, alert:read
```

## OrganizationScopeService

```java
// Scope global — pas de filtre org
boolean hasGlobalOrganizationScope(User user);
// true pour : ADMIN, ECONOMA, AUDIT

// IDs guichets sous une agence
Set<String> guichetIdsUnderAgency(String agencyOrgId);

// L'agence de l'utilisateur gère ce guichet ?
boolean isAgencyManagingGuichet(User user, String guichetParentId);
```

## SaleScopeService — règles critiques

### Liste ventes GUICHET

```java
// operator = utilisateur courant
// status IN (CONFIRMEE, ENREGISTREE) uniquement
// JAMAIS filtrer côté frontend seul — le backend applique managementSpec()
```

### Détail vente GUICHET

Même règle `canSeeSale` : opérateur = user ET statut actif.

### canCancel

```java
boolean canCancel =
    user.hasPermission("sale:cancel")  // via @PreAuthorize aussi
    && (sale.getOperator().equals(user) || isAgencyManagingGuichet(user, sale.getGuichetParentId()))
    && (sale.getStatus() == CONFIRMEE || sale.getStatus() == ENREGISTREE);
```

### canCollect (encaissement agence)

```java
boolean canCollect =
    user.hasAgencyScopeOn(sale.getGuichetId())
    && sale.getStatus() == ENREGISTREE;
```

### Revente unité (V29)

```java
// Bloqué si existe vente non ANNULEE pour cette unité
existsByUnit_IdAndStatusNot(unitId, ANNULEE)
// Index Oracle : uk_sales_unit_active
```

## StockScopeService

```java
Set<String> visibleLocations(UserPrincipal principal);
void requireViewableLocation(UserPrincipal principal, String locationId);
// GUICHET → son guichet ; AGENCE → guichets enfants ; ECONOMA → tout
```

## SupplyOrderScopeService

| Direction | Règle |
|-----------|-------|
| Sortants | `sourceLocation` = site utilisateur |
| Entrants | `targetLocation` = site utilisateur |
| Confirm/Reject | `canActOnIncoming` + `stock:receive` + statut `EN_ATTENTE_CONFIRMATION` ou `EN_TRANSIT` |

Flags DTO typiques :

```java
boolean canConfirm = scope.canActOnIncoming(user, order) && order.getStatus() == EN_ATTENTE_CONFIRMATION;
boolean canReject = canConfirm; // même périmètre
```

## ReportScopeService

12 rapports catalogue — filtres emplacements et organisations selon rôle. ECONOMA/ADMIN : national ; REGION : descendants ; AGENCE : guichets rattachés.

## Statuts métier (référence scope)

**Vente** : `CONFIRMEE` → encaissement → `RECONCILIEE` ou `ANNULEE`. Intermédiaire guichet : `ENREGISTREE`.

**Appro** : `EN_ATTENTE_CONFIRMATION` → `EN_TRANSIT` → `CONFIRMEE` | `REJETEE` | `ANNULEE`

## Pattern controller + service

```java
@GetMapping
@PreAuthorize("hasAuthority('PERM_sale:read:own')")
public ApiResponse<PagedResult<SaleListItemDto>> list(
        @AuthenticationPrincipal UserPrincipal principal,
        @RequestParam(defaultValue = "1") int page,
        @RequestParam(defaultValue = "20") int pageSize) {
    return ApiResponse.paged(saleService.listSales(principal, page, pageSize, q));
}

// Dans SaleService :
Page<Sale> sales = saleRepository.findAll(
    saleScopeService.managementSpec(user, q),
    PaginationUtil.createdAtDesc(page, pageSize));
return sales.map(s -> toListItem(s, user)); // injecte canCancel, canCollect
```

## Pagination (alignée frontend)

```java
// PaginationUtil — MIN_PAGE_SIZE=5, MAX_PAGE_SIZE=100, défaut 20
// Frontend parsePaginationParams : DEFAULT_PAGE_SIZE=10, MIN=5, MAX=100
// Normaliser côté API si divergence pageSize
```

## Tests obligatoires

| Test | Couvre |
|------|--------|
| `SaleScopeServiceTest` | Liste GUICHET, canCancel, canCollect |
| `SupplyOrderScopeServiceTest` | Incoming/outgoing, confirm |
| `OrganizationScopeServiceTest` | Hiérarchie, global scope |

**Règle** : toute modification scope → test unitaire + vérifier flags DTO API + parité frontend `hasPermission` + `canXxx`.

## Anti-patterns

- `@PreAuthorize` seul sans `*ScopeService` sur données org
- Filtrer ventes GUICHET uniquement côté React
- Exposer entité JPA au lieu de DTO avec `canXxx`
- Dupliquer logique RBAC dans le controller
