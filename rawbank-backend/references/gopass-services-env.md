# Services & environnement — GO-PASS backend

> **Autonome** : catalogue services, variables d'environnement et statuts métier. **Ne jamais** commiter de secrets réels dans le skill.

## Services métier (catalogue complet)

| Service | Responsabilité |
|---------|----------------|
| `AuthService` | Login, MFA challenge, refresh JWT, profil `/auth/me` |
| `MfaService` | OTP e-mail, TOTP enroll/verify |
| `StockService` | Lecture stocks, overview, séries |
| `StockMovementWriteService` | Mouvements manuels ENTREE/SORTIE |
| `StockScopeService` | Périmètre emplacements visibles |
| `SaleService` | POS create, encaissement, annulation |
| `SaleScopeService` | Périmètre ventes, canCancel, canCollect |
| `OrganizationScopeService` | Hiérarchie ECONOMA→GUICHET |
| `SupplyOrderService` | CRUD appro, confirm, reject |
| `SupplyOrderScopeService` | Périmètre sortants/entrants |
| `InventoryService` | Sessions inventaire guichet |
| `DashboardService` | KPI 14 jours |
| `ReportsCatalogService` | Catalogue 12 rapports |
| `RevenueReportService` | Rapport revenus |
| `ExportService` | Export CSV/PDF |
| `AuditService` | Écriture `audit_logs` |
| `AuditQueryService` | Lecture journal audit |
| `AdminUserService` | CRUD users, MFA admin |
| `AdminOrganizationService` | Sites org |
| `AdminProductService` | Produits GO-PASS |
| `AdminThresholdService` | Seuils alertes stock |
| `AlertService` | Alertes stock bas / expiration |
| `EmailOutboxService` | File e-mails transactionnels |

## Utilitaires (`service/util/`)

| Classe | Usage |
|--------|--------|
| `BusinessExceptions` | `badRequest()`, `forbidden()`, `notFound()`, `conflict()` |
| `PaginationUtil` | `createdAtDesc(page, pageSize)` — MIN=5, MAX=100 |
| `JsonPayloadUtil` | JSON audit / mouvements |
| `AuditEventMapper` | Entity audit → DTO |
| `ReferenceNumberGenerator` | Numéros GP-*, bons appro |
| `SerialRangeUtil` | Expansion plages numéros série |
| `SerialValidationUtil` | Validation format série produit |

## Variables `.env` (référence)

### Oracle

| Variable | Exemple dev | Description |
|----------|-------------|-------------|
| `DB_HOST` | `localhost` | Hôte Oracle |
| `DB_PORT` | `1522` | Port |
| `DB_SID` | `GOPASS` | SID (pas service name) |
| `DB_USER` | `GOPASS` | Schéma |
| `DB_PASSWORD` | *(secret)* | Mot de passe |

### Serveur & JWT

| Variable | Description |
|----------|-------------|
| `SERVER_PORT` | Défaut `8080` (8082 si conflit Digibranch) |
| `JWT_SECRET` | Min. 32 caractères en prod |
| `JWT_ACCESS_TTL` | Durée access token |
| `JWT_REFRESH_TTL` | Durée refresh token |

### CORS & URLs

| Variable | Description |
|----------|-------------|
| `GOPASS_CORS_ALLOWED_ORIGINS` | `http://localhost:5173` (Vite dev) |
| `GOPASS_PUBLIC_APP_URL` | URL frontend pour liens e-mail |

### Auth & sécurité login

| Variable | Défaut typique | Description |
|----------|----------------|-------------|
| `AUTH_MAX_FAILED_LOGIN_ATTEMPTS` | `3` | Blocage après échecs |
| `MFA_TOTP_ENCRYPTION_KEY` | *(secret ≥32b)* | Chiffrement secret TOTP |
| `MFA_EMAIL_OTP_TTL_MINUTES` | `10` | TTL OTP e-mail |
| `MFA_CHALLENGE_TTL_MINUTES` | `5` | TTL challenge login |
| `MFA_DEV_EXPOSE_OTP` | `false` | Jamais `true` en prod |

### Stock & jobs

| Variable | Description |
|----------|-------------|
| `STOCK_EXPIRATION_WARNING_DAYS` | Défaut nouveaux produits (60) |
| `STOCK_EXPIRATION_CRITICAL_DAYS` | Défaut nouveaux produits (30) |
| `CRON_SECRET` | Token jobs internes |
| `GOPASS_JOBS_SCHEDULED_ENABLED` | Activer crons |
| `GOPASS_JOBS_SCHEDULE_EMAIL_OUTBOX` | Cron file e-mail |
| `GOPASS_JOBS_SCHEDULE_ESCALATE_ALERTS` | Cron escalade alertes |
| `GOPASS_JOBS_SCHEDULE_RECALC_EXPIRATION` | Cron recalcul expiration |
| `GOPASS_JOBS_EMAIL_OUTBOX_BATCH_SIZE` | Taille batch e-mail |

### E-mail (Infobip SMTP typique)

| Variable | Description |
|----------|-------------|
| `EMAIL_MODE` | `smtp` |
| `EMAIL_FROM` | Expéditeur notification |
| `MAIL_HOST` | `smtp-api.infobip.com` |
| `MAIL_PORT` | `587` |
| `MAIL_USERNAME` | *(secret)* |
| `MAIL_PASSWORD` | *(secret)* |
| `MAIL_SMTP_AUTH` | `true` |
| `MAIL_SMTP_STARTTLS_ENABLE` | `true` |

## Contrôleurs REST (16)

| Controller | Base path |
|------------|-----------|
| `AuthController` | `/api/v1/auth` |
| `HealthController` | `/api/v1/health` |
| `DashboardController` | `/api/v1/dashboard` |
| `StockController` | `/api/v1/stocks` |
| `SaleController` | `/api/v1/sales` |
| `SupplyOrderController` | `/api/v1/supply-orders` |
| `InventoryController` | `/api/v1/inventory` |
| `InventoryLookupController` | `/api/v1/inventory/lookup` |
| `ReportsController` | `/api/v1/reports` |
| `ExportController` | `/api/v1/exports` |
| `AuditController` | `/api/v1/audit` |
| `AdminUserController` | `/api/v1/admin/users` |
| `AdminOrganizationController` | `/api/v1/admin/organizations` |
| `AdminProductController` | `/api/v1/admin/products` |
| `AdminThresholdController` | `/api/v1/admin/thresholds` |
| `InternalJobController` | `/api/v1/internal/jobs` |

## Enveloppe API

```java
public record ApiResponse<T>(T data, Meta meta) {
    public static <T> ApiResponse<T> ok(T data) { ... }
    public static <T> ApiResponse<T> paged(Page<T> page) { ... }
}

public record Meta(int page, int pageSize, long total) {}
```

Frontend : `apiGet`, `apiPagedGet` déballent `{ data, meta }`.

## Statuts métier

### Vente

| Statut | Signification |
|--------|---------------|
| `CONFIRMEE` | Vente POS validée guichet |
| `ENREGISTREE` | En attente encaissement agence |
| `RECONCILIEE` | Encaissée |
| `ANNULEE` | Annulée (unité libérée pour revente V29) |

### Approvisionnement

| Statut | Signification |
|--------|---------------|
| `EN_ATTENTE_CONFIRMATION` | Créé, attente réception |
| `EN_TRANSIT` | Expédié |
| `CONFIRMEE` | Reçu |
| `REJETEE` | Refusé |
| `ANNULEE` | Annulé |

### Mouvement stock

`ENTREE`, `SORTIE` — catégories : appro, vente, ajustement, transfert, …

### Inventaire

`OUVERTE`, `VALIDEE`, `ANNULEE`

## Audit — actions courantes

`SALE.CREATE`, `SALE.CANCEL`, `SALE.COLLECT`, `STOCK.MOVEMENT`, `SUPPLY.CREATE`, `SUPPLY.CONFIRM`, `USER.CREATE`, `USER.MFA_UPDATE`

## Commandes dev

```bash
source .env && ./mvnw spring-boot:run          # :8080
./mvnw test
./mvnw test -Dtest=SaleScopeServiceTest,SaleServiceCreateSaleTest
```

Swagger (dev) : `/swagger-ui.html`

## Domain entités clés

`User`, `Organization`, `Role`, `Permission`, `Product`, `StockLocation`, `StockUnit`, `StockMovement`, `Sale`, `SupplyOrder`, `InventorySession`, `AuditLog`, `Alert`, `Threshold`

Enums : `UserMfaMethod` (TOTP, EMAIL_OTP), `OrganizationType`, statuts vente/appro/mouvement.
