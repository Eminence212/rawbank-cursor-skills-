# Pages pattern — GO-PASS frontend

## Table des matières

- [Page liste standard](#page-liste-standard)
- [Pagination URL](#pagination-url)
- [Formulaire modal admin](#formulaire-modal-admin)
- [Actions conditionnelles](#actions-conditionnelles)
- [Filtre verrouillé URL](#filtre-verrouillé-url)
- [POS vente](#pos-vente)
- [Settings admin](#settings-admin)
- [Dashboard KPI](#dashboard-kpi)
- [Gestion erreurs](#gestion-erreurs)
- [Routing et navigation](#routing-et-navigation)
- [Catalogue pages par domaine](#catalogue-pages-par-domaine)
- [Références liées](#références-liées)

---

## Page liste standard

```tsx
import { useSearchParams } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { Stack, Group, Title, Button, Paper, Table, TextInput } from "@mantine/core";
import { parsePaginationParams } from "@/lib/table/pagination";
import { hasPermission } from "@/lib/rbac";
import { PaginationBar } from "@/components/ui/pagination-bar";

export function MaListePage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const { page, pageSize } = parsePaginationParams(
    Object.fromEntries(searchParams.entries()),
  );
  const q = searchParams.get("q") ?? "";

  const { data, isLoading } = useQuery({
    queryKey: ["items", page, pageSize, q],
    queryFn: () => fetchItems({ page, pageSize, q }),
  });

  return (
    <Stack className="app-page">
      <Group justify="space-between" className="app-page-header">
        <Title order={2} className="app-page-title">Titre</Title>
        {hasPermission(user, "item:create") && (
          <Button className="app-action-primary" onClick={open}>Nouveau</Button>
        )}
      </Group>

      <form className="app-table-toolbar" method="get">
        <TextInput name="q" defaultValue={q} placeholder="Rechercher..." className="app-search-input" />
        <input type="hidden" name="page" value="1" />
      </form>

      <Paper className="app-card app-table-card">
        <Table className="app-table" striped highlightOnHover size="sm">
          {/* rows */}
        </Table>
        <PaginationBar
          page={page}
          totalPages={data?.totalPages ?? 1}
          onPageChange={(p) => {
            const next = new URLSearchParams(searchParams);
            next.set("page", String(p));
            setSearchParams(next);
          }}
        />
      </Paper>
    </Stack>
  );
}
```

**Règle** : logique API dans `lib/<domaine>.ts`, pas dans la page.

---

## Pagination URL

```typescript
const DEFAULT_PAGE_SIZE = 10;
const MAX_PAGE_SIZE = 100;
const MIN_PAGE_SIZE = 5;

export function parsePaginationParams(
  raw: Record<string, string | string[] | undefined>,
): { page: number; pageSize: number } {
  const get = (k: string) => {
    const v = raw[k];
    return Array.isArray(v) ? v[0] : v;
  };
  const page = Math.max(1, parseInt(String(get("page") ?? "1"), 10) || 1);
  const pageSizeRaw = parseInt(String(get("pageSize") ?? String(DEFAULT_PAGE_SIZE)), 10);
  const pageSize = Math.min(
    MAX_PAGE_SIZE,
    Math.max(MIN_PAGE_SIZE, Number.isFinite(pageSizeRaw) ? pageSizeRaw : DEFAULT_PAGE_SIZE),
  );
  return { page, pageSize };
}

export function getQueryString(
  base: Record<string, string | undefined>,
  updates: Record<string, string | undefined | null>,
): string { /* fusion + URLSearchParams */ }
```

Backend aligné : `PaginationUtil` MIN=5, MAX=100.

---

## Formulaire modal admin

```tsx
const form = useForm({
  initialValues: { name: "" },
  validate: { name: (v) => (!v ? "Requis" : null) },
});

const save = useNotifyMutation({
  mutationFn: (values) => createItem(values),
  successMessage: "Enregistré",
  errorFallback: "Échec enregistrement",
  invalidateKeys: [["items"]],
  onSuccessCleanup: () => { close(); form.reset(); },
});
```

---

## Actions conditionnelles

Toujours **deux** conditions : flag API `canXxx` **et** permission RBAC.

```tsx
{detail.canConfirm && hasPermission(user, "stock:receive") && (
  <Button onClick={() => confirm.mutate(detail.id)}>Confirmer réception</Button>
)}

{sale.canCancel && hasPermission(user, "sale:cancel") && (
  <Button color="red" variant="light" onClick={handleCancel}>Annuler</Button>
)}

{sale.canCollect && hasPermission(user, "sale:cancel") && (
  <Button onClick={() => collect.mutate(sale.id)}>Encaisser</Button>
)}
```

---

## Filtre verrouillé URL

Pattern `StockMovementsPage` — deep link depuis fiche site :

```tsx
const lockedLocationId = searchParams.get("locationId");

<Select
  disabled={!!lockedLocationId}
  value={lockedLocationId ?? selectedLocationId}
  data={locations}
/>

// Lien depuis overview :
<Link to={`/stocks/movements?locationId=${site.id}`}>Voir mouvements</Link>
```

---

## POS vente

`PosSalePage` — flux :

1. Sélection produit GO-PASS (national / international)
2. Saisie plage numéros série ou carnet
3. Montant face value × quantité
4. `createSale` mutation → invalidation `["sales"]`

Helpers série : expansion plages `SerialRangeUtil` côté backend ; côté front validation format avant submit.

---

## Settings admin

- `CreateUserModal` — reset à la fermeture (`form.reset()`)
- `AdminMfaMethodSelect` — TOTP / EMAIL_OTP
- `SettingsLayout` — wrap routes `/settings/*`, rôles ADMIN + AGENCE

---

## Dashboard KPI

```tsx
<KpiGrid>
  <KpiCard label="Ventes 14j" value={data.salesCount} icon={<IconReceipt />} />
  <KpiCard label="Stock bas" value={data.lowStock} className="kpi-card--attention" />
</KpiGrid>
```

**Attention** : KPI guichet peut compter différemment de la liste ventes — aligner avec `DashboardService` backend, ne pas recalculer côté client.

---

## Gestion erreurs

```typescript
// 403 → message "Accès refusé" ou redirect
// 401 → intercepteur Axios refresh puis login
notifyFromError(error, "Opération impossible");
```

Extraire message Spring : `extractApiErrorMessage(error)` depuis body `{ message }`.

---

## Routing et navigation

```tsx
// ProtectedRoute → JWT
// AccessRoute permission="stock:read:own"
// TotpEnrollmentGuard → /mfa/enroll

// nav-data.ts — structure entrée :
{ label: "Stocks", to: "/stocks", permission: "stock:read:own", icon: IconPackage }
```

---

## Catalogue pages par domaine

| Domaine | Pages |
|---------|-------|
| Ventes | `PosSalePage`, `SalesCancelPage`, `SalesListPage` |
| Stocks | `StockOverviewPage`, `StockMovementsPage` |
| Appro | `SupplyOrdersPage`, `SupplyCreatePage` |
| Inventaire | `InventorySessionsPage` |
| Rapports | `ReportsPage`, `RevenueReportPage` |
| Admin | `UsersPage`, `OrganizationsPage`, `ProductsPage`, `ThresholdsPage` |
| Auth | `LoginPage`, `MfaPage`, `MfaEnrollPage` |
| Audit | `AuditLogPage` |

---

## Checklist nouvelle page

```
- [ ] Route AppRoutes + entrée nav-data.ts
- [ ] lib/<domaine>.ts — types + fetch
- [ ] hasPermission + flags canXxx API
- [ ] useQuery liste / useNotifyMutation actions
- [ ] PaginationBar + useSearchParams
- [ ] SemanticStatusBadge + *-meta.ts
- [ ] Gestion 403
- [ ] Classes app-*
```

---

## Références liées

- Composants : [gopass-ui-components.md](gopass-ui-components.md)
- Styles : [gopass-theme-styles.md](gopass-theme-styles.md)
- MFA : [gopass-lib-auth-mfa.md](gopass-lib-auth-mfa.md)
- Scope backend : [gopass-rbac-scope.md](../rawbank-backend/references/gopass-rbac-scope.md)
