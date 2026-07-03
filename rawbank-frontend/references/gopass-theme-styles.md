# Thème & styles — GO-PASS frontend

> **Autonome** : `theme.ts`, variables CSS `:root` et classes `app-*` reproduits ci-dessous intégralement.

## Stack styling

| Couche | Technologie |
|--------|-------------|
| Composants | Mantine 7 (`@mantine/core`, `form`, `dates`, `notifications`) |
| Utilitaires | Tailwind CSS 4 (`@import "tailwindcss"` dans globals) |
| Layout métier | Classes sémantiques `app-*` (**prioritaire** sur Tailwind inline) |
| Modules CSS | Uniquement sidebar nav (`NavbarNested.module.css`) |
| Icônes | `@tabler/icons-react` |

## Code source `theme.ts` (complet)

```typescript
import { ActionIcon, Button, createTheme, type MantineColorsTuple } from "@mantine/core";

const myColor: MantineColorsTuple = [
  "#fff6e1",  // 0
  "#ffebcb",  // 1 — --app-primary-soft
  "#ffd59a",  // 2 — --app-primary-soft-strong
  "#ffbe64",  // 3
  "#ffab37",  // 4
  "#ff9e1b",  // 5 — marque Rawbank
  "#ff9400",  // 6 — --app-primary, CTA défaut
  "#e38300",  // 7 — --app-primary-strong, hover
  "#cb7400",  // 8
  "#b06300",  // 9 — texte badge orange
];

export const theme = createTheme({
  colors: { myColor },
  primaryColor: "myColor",
  fontFamily: "var(--font-geist-sans), system-ui, sans-serif",
  components: {
    Button: Button.extend({
      styles: {
        root: {
          cursor: "pointer",
          "&:disabled:not([data-loading]), &[data-disabled]:not([data-loading])": {
            cursor: "not-allowed",
          },
        },
      },
    }),
    ActionIcon: ActionIcon.extend({
      styles: {
        root: {
          cursor: "pointer",
          "&:disabled:not([data-loading]), &[data-disabled]:not([data-loading])": {
            cursor: "not-allowed",
          },
        },
      },
    }),
  },
});
```

Intégration :

```tsx
<MantineProvider theme={theme} defaultColorScheme="light">
```

## Variables CSS `:root` (globals.css)

```css
:root {
  --background: #ffffff;
  --foreground: #171717;
  --app-bg: #f4f6fb;              /* fond page */
  --app-surface: #ffffff;         /* cartes */
  --app-border: #e2e8f0;
  --app-muted: #64748b;           /* texte secondaire */
  --app-text: #0f172a;
  --app-primary: var(--mantine-color-myColor-6, #ff9400);
  --app-primary-strong: var(--mantine-color-myColor-7, #e38300);
  --app-primary-soft: var(--mantine-color-myColor-1, #ffebcb);
  --app-primary-soft-strong: var(--mantine-color-myColor-2, #ffd59a);
}

body {
  background: var(--app-bg);
  color: var(--app-text);
  font-family: system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif;
}
```

## Palette — index Mantine `myColor`

| Index | Hex | Usage |
|-------|-----|--------|
| 0 | `#fff6e1` | Fond badge ok |
| 1 | `#ffebcb` | Soft, warn badge |
| 2 | `#ffd59a` | Soft strong, critical badge |
| 5 | `#ff9e1b` | Marque Rawbank |
| 6 | `#ff9400` | CTA primaire |
| 7 | `#e38300` | Hover, strong |
| 9 | `#b06300` | Texte badge orange |

## Typographie

- Titres page : `.app-page-title` — `clamp(1.5rem, 1.9vw, 2rem)`, weight 700
- Sous-titre : `.app-page-subtitle` — couleur `--app-muted`

## Classes layout page

| Classe | Usage |
|--------|--------|
| `.app-page` | Conteneur vertical, gap ~1.25rem |
| `.app-page-header` | Titre + actions |
| `.app-page-title` | H1 page |
| `.app-page-subtitle` | Sous-titre muted |
| `.app-page-actions` | Groupe boutons header |
| `.app-page-crumb` | Lien retour |

## Classes actions

| Classe | Usage |
|--------|--------|
| `.app-action-primary` | Bouton orange plein + ombre |
| `.app-action-secondary` | Outline gris |
| `.app-action-small` | Variante compacte |

## KPI dashboard

| Classe | Usage |
|--------|--------|
| `.kpi-grid` | Grille 4 → 2 → 1 colonnes (responsive) |
| `.kpi-card` | Carte indicateur |
| `.kpi-card--attention` | Alerte rouge |
| `.kpi-card--muted` | Valeur atténuée |
| `.kpi-label`, `.kpi-value`, `.kpi-icon`, `.kpi-foot` | Structure interne |

Composants React : `KpiGrid`, `KpiCard` dans `components/ui/kpi-card.tsx`.

## Tables & listes

| Classe | Usage |
|--------|--------|
| `.app-table-card` | Conteneur carte tableau |
| `.app-table-head` | En-tête avec tabs |
| `.app-table-toolbar` | Grille filtres (4 col responsive) |
| `.app-table-toolbar-compact` | Recherche + bouton |
| `.app-table-toolbar-stocks` | Variante stocks |
| `.app-table-wrap` | Scroll horizontal |
| `.app-table` | Table striped + hover orange |
| `.app-search-input`, `.app-filter-select` | Champs filtre |
| `.app-pagination` | Barre pagination |

Pattern page liste :

```tsx
<Stack className="app-page">
  <form className="app-table-toolbar" method="get">...</form>
  <Paper className="app-card app-table-card">
    <Table className="app-table" striped highlightOnHover>...</Table>
  </Paper>
</Stack>
```

## Badges statut

### Orange marque (ventes legacy)

`.app-status.ok` | `.app-status.warn` | `.app-status.critical` — teintes `myColor`

### Sémantiques (stock, expiration, supply)

| Classe | Signification |
|--------|---------------|
| `.app-exp-status--valid` / `.app-stock-status--available` | Vert |
| `.app-exp-status--warning` / `.app-stock-status--low` | Jaune |
| `.app-exp-status--critical` | Orange |
| `.app-exp-status--expired` / `.app-stock-status--out` | Rouge |

**Préférer** `SemanticStatusBadge` + fichiers `*-meta.ts`.

## Loader global

`.global-loader`, `.global-loader-full`, `.global-loader-card` — spinner orange, backdrop blur, animation `appLoaderFloat` / `appLoaderPulse`. Utilisé par `RouteLoadingScreen`.

## Admin & formulaires

| Classe | Usage |
|--------|--------|
| `.admin-form-section` | Section modale admin |
| `.credential-transmit-notice` | Bandeau orange MDP |
| `.users-empty-state` | État vide users |
| `.booklet-selector*` | Sélecteur carnets POS |

## Meta statuts TypeScript

### Ventes (`getSaleStatusDisplay`)

Règle **GUICHET** : masque les statuts intermédiaires — tout sauf `ANNULEE`/`RECONCILIEE` affiché « Validée » (warn).

| status | GUICHET label | Autres rôles label |
|--------|---------------|-------------------|
| ANNULEE | Annulée (red) | Annulée (red) |
| RECONCILIEE | Validée (green) | Encaissée (green) |
| ENREGISTREE | Validée (warn) | Enregistrée (gray) |
| CONFIRMEE | Validée (warn) | Validée (warn) |

### Appro (`getSupplyOrderStatusDisplay`)

| status | label | color |
|--------|-------|-------|
| CONFIRMEE | Confirmé | green |
| REJETEE | Rejeté | red |
| ANNULEE | Annulé | gray |
| EN_TRANSIT | En transit | myColor |
| EN_ATTENTE_CONFIRMATION | En attente | myColor |

Filtre URL : `SUPPLY_STATUS_FILTER_OPTIONS` — ALL, EN_ATTENTE_CONFIRMATION, EN_TRANSIT, CONFIRMEE, REJETEE, ANNULEE.

## Règles styling (checklist)

1. Nouvelle page liste → `app-page` + `app-table-card` + `app-table`
2. Nouveau statut → meta TS + `SemanticStatusBadge`, pas nouvelle classe CSS
3. Couleur primaire → `myColor` Mantine ou `var(--app-primary)`, pas hex ad hoc
4. **Éviter** Tailwind utility-first sur pages métier
5. Responsive : breakpoints globals `74rem`, `58rem`, `40rem`
6. Tables denses : Mantine `size="sm"`, `striped`, `highlightOnHover`
7. Modales : `size="md"` ou `lg`
8. Notifications : `lib/ui/notify.ts` (`notifyOk`, `notifyError`, `notifyFromError`)

## Contraste Digibranch

GO-PASS : fond clair `#f4f6fb`, primary `#ff9400`, **pas** de dark auth.  
Digibranch kiosk : dark auth `#0a0a0a`, même primary `#ff9e1b` — voir `digibranch-design-system.md`.
