# API patterns — GO-PASS backend

> **Autonome** : patterns controller/service/DTO et helpers HTTP frontend alignés ci-dessous.

Package Java : `com.rawbank.gopass`

## Controller type

```java
@RestController
@RequestMapping("/api/v1/stocks")
@Tag(name = "Stocks", description = "...")
public class StockController {

    @GetMapping("/overview")
    @PreAuthorize("hasAuthority('PERM_stock:read:own')")
    @Operation(summary = "...")
    public ApiResponse<StockOverviewResponseDto> overview(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(required = false) String q) {
        return ApiResponse.ok(stockService.getOverview(principal, q, ...));
    }

    @GetMapping
    @PreAuthorize("hasAuthority('PERM_sale:read:own')")
    public ApiResponse<PagedResult<SaleListItemDto>> list(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize,
            @RequestParam(required = false) String q) {
        return ApiResponse.paged(saleService.listSales(principal, page, pageSize, q));
    }
}
```

## Contrôleurs complets

| Controller | Base path | Domaine |
|------------|-----------|---------|
| `AuthController` | `/api/v1/auth` | login, MFA, refresh, profil |
| `HealthController` | `/api/v1/health` | santé |
| `DashboardController` | `/api/v1/dashboard` | KPI |
| `StockController` | `/api/v1/stocks` | overview, séries, mouvements |
| `SaleController` | `/api/v1/sales` | POS, encaissement, annulation |
| `SupplyOrderController` | `/api/v1/supply-orders` | appro sortants/entrants |
| `InventoryController` | `/api/v1/inventory` | sessions inventaire |
| `InventoryLookupController` | `/api/v1/inventory/lookup` | recherche guichets |
| `ReportsController` | `/api/v1/reports` | catalogue rapports |
| `ExportController` | `/api/v1/exports` | CSV/PDF |
| `AuditController` | `/api/v1/audit` | journal |
| `AdminUserController` | `/api/v1/admin/users` | CRUD users |
| `AdminOrganizationController` | `/api/v1/admin/organizations` | sites |
| `AdminProductController` | `/api/v1/admin/products` | produits GO-PASS |
| `AdminThresholdController` | `/api/v1/admin/thresholds` | seuils alertes |
| `InternalJobController` | `/api/v1/internal/jobs` | jobs alertes/email |

## DTO (records)

```java
public record CreateSaleRequest(
        @NotBlank String productId,
        @NotBlank String unitId,
        @NotNull @DecimalMin("0.01") BigDecimal amount) {}

public record ApiResponse<T>(T data, Meta meta) {
    public static <T> ApiResponse<T> ok(T data) { ... }
    public static <T> ApiResponse<T> paged(Page<T> page) { ... }
}
```

## Service transaction

```java
@Service
public class SaleService {
    @Transactional
    public SaleCreatedDto createSale(UserPrincipal principal, CreateSaleRequest request) { ... }

    @Transactional(readOnly = true)
    public Page<SaleListItemDto> listSales(...) { ... }
}
```

## Liste filtrée (Specification)

```java
Page<Sale> sales = saleRepository.findAll(
        saleScopeService.managementSpec(user, q),
        PaginationUtil.createdAtDesc(page, pageSize));
return sales.map(sale -> toListItem(sale, user));
```

## Flags d'action dans list DTO

```java
boolean canCancel =
        (sale.getStatus() == CONFIRMEE || sale.getStatus() == ENREGISTREE)
        && saleScopeService.canCancelSale(sessionUser, sale);

boolean canCollect = saleScopeService.canCollectSale(sessionUser, sale)
        && sale.getStatus() == ENREGISTREE;
```

## Audit

```java
auditService.write(
        "SALE.CREATE", "Sale", sale.getId(), user.getId(),
        Map.of("status", previous.name()),
        Map.of("status", newStatus.name(), "guichetCode", guichet.getCode()));
```

Actions courantes : `SALE.CREATE`, `SALE.CANCEL`, `SALE.COLLECT`, `STOCK.MOVEMENT`, `SUPPLY.CREATE`, `SUPPLY.CONFIRM`.

## GlobalExceptionHandler

Mapper contraintes Oracle :

```java
if (upper.contains("UK_SALES_UNIT_ACTIVE")) {
    return "Cette unité est déjà vendue.";
}
```

## Helpers HTTP frontend (parité enveloppe)

```typescript
// lib/api-client.ts — déballage { data, meta }
export async function apiGet<T>(url: string, params?: Record<string, unknown>): Promise<T> {
  const res = await api.get<ApiResponse<T>>(url, { params });
  return res.data.data;
}

export async function apiPagedGet<T>(url: string, params?: Record<string, unknown>): Promise<PagedResult<T>> {
  const res = await api.get<ApiResponse<T[]>>(url, { params });
  return toPagedResult(res.data);  // { items, page, pageSize, total }
}

export async function apiPost<T, B>(url: string, body: B): Promise<T> { ... }
export async function apiPatch<T, B>(url: string, body: B): Promise<T> { ... }
export async function apiDelete<T>(url: string): Promise<T> { ... }
export async function apiGetBlob(url: string, params?): Promise<Blob> { ... }
```

Base Axios `lib/api.ts` : intercepteur JWT refresh, redirect `/login` sur 401, base `/api/v1`.

## JwtAuthFilter

- Lit `Authorization: Bearer <token>`
- Construit `UserPrincipal` avec permissions (`PERM_*`)
- Refresh via `POST /api/v1/auth/refresh`

## Auth endpoints

| Méthode | Path | Rôle |
|---------|------|------|
| POST | `/api/v1/auth/login` | Login → JWT ou MFA |
| POST | `/api/v1/auth/mfa/verify` | Verify → tokens |
| POST | `/api/v1/auth/refresh` | Refresh access |
| GET | `/api/v1/auth/me` | Profil + permissions |
| POST | `/api/v1/auth/logout` | Invalidation |
| POST | `/api/v1/auth/totp/enroll` | Enrollment TOTP |

## InternalJobController

Endpoints cron alertes — protégés par `CRON_SECRET`.
