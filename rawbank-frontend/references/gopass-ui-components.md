# UI components — GO-PASS frontend

## Table des matières

- [Layout et navigation](#layout-et-navigation)
- [Statuts et KPI](#statuts-et-kpi)
- [Auth et MFA](#auth-et-mfa)
- [Admin settings](#admin-settings)
- [SemanticStatusBadge](#semanticstatusbadge)
- [Meta statuts par domaine](#meta-statuts-par-domaine)
- [useNotifyMutation](#usenotifymutation)
- [Notifications](#notifications)
- [Classes CSS sémantiques](#classes-css-sémantiques)
- [Thème Mantine](#thème-mantine)
- [Client HTTP](#client-http)
- [Références liées](#références-liées)

---

## Layout et navigation

| Composant | Rôle |
|-----------|------|
| `AppShell` | Shell principal + sidebar |
| `nav-data.ts` | Entrées menu filtrées par `hasPermission` |
| `ProtectedRoute` | JWT requis — redirect `/login` |
| `AccessRoute` | Permission RBAC sur la route |
| `GuestRoute` | Pages login — redirect si déjà connecté |
| `TotpEnrollmentGuard` | Force `/mfa/enroll` si TOTP requis |
| `SettingsLayout` | Section admin — rôles ADMIN + AGENCE |

### AppRoutes pattern

```tsx
<Route element={<ProtectedRoute />}>
  <Route element={<TotpEnrollmentGuard />}>
    <Route element={<AccessRoute permission="stock:read:own" />}>
      <Route path="/stocks" element={<StockOverviewPage />} />
    </Route>
  </Route>
</Route>
```

`nav-data.ts` : masquer ou griser les entrées sans permission ; badge 403 si accès direct URL.

---

## Statuts et KPI

| Composant | Rôle |
|-----------|------|
| `SemanticStatusBadge` | Pill CSS coloré depuis meta métier |
| `KpiCard`, `KpiGrid` | Tuiles dashboard |
| `StockLevelCell` | Niveau stock (available/low/out) |
| `ExpirationStatusCell` | Statut expiration série |
| `PaginationBar` | Pagination URL-sync |
| `RowActionsMenu` | Menu ⋯ actions ligne |
| `ConfirmModal` | Confirmation destructive |

---

## Auth et MFA

| Composant | Rôle |
|-----------|------|
| `AuthPageShell` | Layout centré login/MFA + logo |
| `MfaCodeInput` | 6 cases, auto-focus |
| `MfaStatusBadge` | Méthode MFA sur fiche user |
| `RouteLoadingScreen` | Loader plein écran pendant auth check |

Détail flux MFA : [gopass-lib-auth-mfa.md](gopass-lib-auth-mfa.md)

---

## Admin settings

| Composant | Rôle |
|-----------|------|
| `CreateUserModal` | Création user — reset form à la fermeture |
| `AdminFormSection` | Section titre modale |
| `AdminUserFormFields` | Champs nom, email, rôle, org |
| `AdminMfaMethodSelect` | TOTP ou EMAIL_OTP |
| `CredentialTransmitNotice` | Bandeau orange MDP initial |
| `UsersTableEmpty` | État vide liste users |

`SettingsLayout` : accessible ADMIN et AGENCE uniquement.

---

## SemanticStatusBadge

```tsx
export type StatusDisplay = {
  label: string;
  className: string;  // ex. "app-status ok", "app-exp-status--warning"
};

type SemanticStatusBadgeProps = StatusDisplay & {
  extraClassName?: string;
};

export function SemanticStatusBadge({ label, className, extraClassName }: SemanticStatusBadgeProps) {
  const merged = extraClassName ? `${className} ${extraClassName}` : className;
  return <span className={merged}>{label}</span>;
}
```

Usage :

```tsx
import { getSupplyOrderStatusDisplay } from "@/lib/supply/status-meta";

const display = getSupplyOrderStatusDisplay(order.status);
<SemanticStatusBadge {...display} />
```

---

## Meta statuts par domaine

### Ventes — `getSaleStatusDisplay(status, roleCode?)`

| status | GUICHET | Autres rôles |
|--------|---------|--------------|
| ANNULEE | Annulée (red) | Annulée (red) |
| RECONCILIEE | Validée (green) | Encaissée (green) |
| ENREGISTREE | Validée (warn) | Enregistrée (gray) |
| CONFIRMEE | Validée (warn) | Validée (warn) |

### Appro — `getSupplyOrderStatusDisplay(status)`

| status | label | className |
|--------|-------|-----------|
| CONFIRMEE | Confirmé | app-status ok |
| REJETEE | Rejeté | app-status critical |
| ANNULEE | Annulé | app-status warn |
| EN_TRANSIT | En transit | app-status info |
| EN_ATTENTE_CONFIRMATION | En attente | app-status warn |

Filtre URL : `SUPPLY_STATUS_FILTER_OPTIONS` — ALL, EN_ATTENTE_CONFIRMATION, EN_TRANSIT, CONFIRMEE, REJETEE, ANNULEE.

### Stocks

Meta dans `movement-meta.ts`, `stock-level-meta.ts`, `expiration-meta.ts` — tons `success | warning | danger | info | neutral`.

---

## useNotifyMutation

```typescript
export function useNotifyMutation<TData, TVariables>({
  mutationFn,
  successMessage,
  successTitle,
  errorFallback,
  invalidateKeys = [],
  onSuccessData,
  onSuccessCleanup,
  onError,
}: {
  mutationFn: (vars: TVariables) => Promise<TData>;
  successMessage: string | ((data: TData) => string);
  successTitle?: string;
  errorFallback: string;
  invalidateKeys?: QueryKey[];
  onSuccessData?: (data: TData) => void;
  onSuccessCleanup?: () => void;
  onError?: (error: Error) => boolean;  // return true pour skip toast
}) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn,
    onSuccess: async (data) => {
      const message = typeof successMessage === "function" ? successMessage(data) : successMessage;
      successTitle ? notifySuccess(successTitle, message) : notifyOk(message);
      onSuccessData?.(data);
      onSuccessCleanup?.();
      await Promise.all(invalidateKeys.map((k) => queryClient.invalidateQueries({ queryKey: k })));
    },
    onError: (error) => {
      if (onError?.(error) === true) return;
      notifyFromError(error, errorFallback);
    },
  });
}
```

Exemple :

```tsx
const confirm = useNotifyMutation({
  mutationFn: (id: string) => confirmSupplyOrder(id),
  successMessage: "Réception confirmée",
  errorFallback: "Impossible de confirmer",
  invalidateKeys: [["supply-orders"]],
  onSuccessCleanup: closeModal,
});
```

---

## Notifications

```typescript
export function notifyOk(message: string) { /* titre OK, vert */ }
export function notifySuccess(title: string, message: string) { /* vert */ }
export function notifyError(message: string, title = "Erreur") { /* rouge */ }
export function notifyFromError(error: unknown, fallback: string) {
  notifyError(extractApiErrorMessage(error) ?? fallback);
}
```

---

## Classes CSS sémantiques

| Classe | Usage |
|--------|--------|
| `app-page` | Conteneur page vertical |
| `app-card` | Paper / carte |
| `app-table-card` | Conteneur tableau |
| `app-table` | Table striped + hover |
| `app-table-toolbar` | Filtres GET (form method="get") |
| `app-kpi` | Tuiles dashboard |
| `app-muted` | Texte secondaire |
| `app-status ok/warn/critical` | Badges orange legacy |
| `app-exp-status--*` / `app-stock-status--*` | Badges sémantiques |

Liste complète : [gopass-theme-styles.md](gopass-theme-styles.md)

---

## Thème Mantine

`primaryColor: "myColor"` — palette RAWBANK `#ff9e1b` → `#ff9400`.

Code `theme.ts` complet et variables `:root` : [gopass-theme-styles.md](gopass-theme-styles.md)

### Conventions Mantine

- Tables denses : `size="sm"`, `striped`, `highlightOnHover`
- Modales : `size="md"` ou `lg`
- Icônes : `@tabler/icons-react`
- **Pas** de Tailwind utility-first sur pages métier

---

## Client HTTP

```typescript
// api.ts — Axios instance
// baseURL: "/api/v1"
// intercepteur : refresh JWT sur 401, redirect /login

// api-client.ts
apiGet<T>(url, params?)      // → data
apiPagedGet<T>(url, params?) // → { items, page, pageSize, total }
apiPost<T, B>(url, body)
apiPatch<T, B>(url, body)
apiDelete<T>(url)
apiGetBlob(url, params?)     // CSV/PDF
```

---

## Références liées

- Pages liste CRUD : [gopass-pages-pattern.md](gopass-pages-pattern.md)
- Auth MFA : [gopass-lib-auth-mfa.md](gopass-lib-auth-mfa.md)
- RBAC backend : [gopass-rbac-scope.md](../rawbank-backend/references/gopass-rbac-scope.md)
- Factory Mantine custom : skill `mantine-custom-components`
