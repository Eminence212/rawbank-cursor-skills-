# Thème & styles — Digibranch frontend

> **Autonome** : variables CSS `--kiosk-*`, palette Mantine et patterns CSS Modules reproduits ci-dessous intégralement.

## Structure styling (3 couches)

| Couche | Contenu |
|--------|---------|
| Mantine theme | `createTheme` — palette `myColor` identique GO-PASS |
| CSS global | Variables `--kiosk-*` dans `:root` |
| CSS Modules | Un `*.module.css` par composant kiosk (79) |

Next et Vite SPA partagent les **mêmes** variables `--kiosk-*` et les **mêmes** modules composants kiosk.

## Stack styling

| Couche | Technologie |
|--------|-------------|
| Composants | Mantine 7 |
| Utilitaires layout | Tailwind CSS 4 |
| Kiosk UI | **CSS Modules** par composant (`*.module.css`) |
| Tokens globaux | Variables `--kiosk-*` dans globals/index.css |
| PostCSS | `postcss-preset-mantine` |
| Police | **Geist** / Geist Mono |
| Icônes | `@tabler/icons-react` |

## Palette Mantine `myColor` (identique GO-PASS)

| Index | Hex |
|-------|-----|
| 5 | `#ff9e1b` — primary kiosk |
| 6 | `#ff9400` — hover boutons |
| 7 | `#e38300` |

```ts
export const theme = createTheme({
  colors: { myColor: ["#fff6e1", "#ffebcb", "#ffd59a", "#ffbe64", "#ffab37", "#ff9e1b", "#ff9400", "#e38300", "#cb7400", "#b06300"] },
  primaryColor: "myColor",
  defaultRadius: "md",
  fontFamily: "var(--font-geist-sans), system-ui, sans-serif",
  components: {
    Button: {
      defaultProps: { radius: "md", size: "lg" },
      styles: { root: { minHeight: 48, cursor: "pointer" } },
    },
  },
});
```

## Variables CSS `:root`

```css
--kiosk-auth-bg: #0a0a0a;           /* écrans auth dark */
--kiosk-dashboard-bg: #ffffff;      /* opérations light */
--kiosk-surface-muted: #f8f9fa;     /* cartes, info boxes */
--kiosk-border: #e5e7eb;
--kiosk-text-dark: #1a1a1a;
--kiosk-text-muted: #6b7280;
--kiosk-primary: #ff9e1b;           /* CTA, StepProgress, ChoiceButton primary */
--kiosk-header-logo-height: 72px;
--kiosk-home-logo-height: 96px;
--kiosk-touch-min: 48px;            /* accessibilité tactile */
--kiosk-card-grid-height: 204px;
--kiosk-card-tile-height: 156px;
--kiosk-card-service-height: 156px;
--kiosk-card-radio-row-min-height: 64px;
--kiosk-card-radio-min-height: 80px;
--kiosk-card-title-size: 1.05rem;
--kiosk-card-body-size: 1rem;
--kiosk-card-caption-size: 0.9rem;
```

Vite (`index.css`) ajoute :

```css
--font-geist-sans: "Geist Variable", "Geist", system-ui, sans-serif;
--font-geist-mono: "Geist Mono Variable", "Geist Mono", ui-monospace, monospace;
```

## Couleurs complémentaires (design system)

| Token | Hex | Usage |
|-------|-----|--------|
| primary-light | `#ffd000` | Dégradé logo, accents dorés |
| success | `#22c55e` | OperationResult succès |
| error | `#ef4444` | OperationResult échec |
| radius-md | `12px` | Inputs, boutons |
| radius-lg | `16px` | Tuiles dashboard |
| choice-button radius | `20px` | `choice-button.module.css` |

## Thèmes contextuels

| Contexte | Background | Composants |
|----------|------------|------------|
| Auth dark | `--kiosk-auth-bg` `#0a0a0a` | `KioskSplitHero`, `ChoiceButton.secondary` |
| Dashboard / wizards | `--kiosk-dashboard-bg` | `KioskShell.standardPage` |
| Bouton CTA | `--kiosk-primary` | `ChoiceButton.primary`, Mantine Button |

## Typographie

- Next : `next/font` → `--font-geist-sans`, `--font-geist-mono` dans layout
- Vite : `@fontsource-variable/geist` + variables dans `index.css`
- `body` : `font-family: var(--font-geist-sans)`
- Titres dashboard : `1.125rem`, weight 700 (`kiosk-shell.module.css`)

## Pattern CSS Modules

Chaque composant kiosk :

```
components/kiosk/choice-button.tsx
components/kiosk/choice-button.module.css
```

Import : `import classes from './choice-button.module.css'`

Les modules utilisent les **variables globales** `--kiosk-*`, pas de hex dupliqués sauf hover (`#ff9400` sur primary).

### Exemples modules clés

| Module | Classes | Rôle |
|--------|---------|------|
| `kiosk-shell.module.css` | `.standardPage`, `.dashboardHeader`, `.dashboardGreeting` | Layout pages |
| `kiosk-split-hero.module.css` | colonnes dark + illustration | Accueil auth |
| `choice-button.module.css` | `.primary`, `.secondary`, min-height radio | Choix langue/méthode |
| `step-progress.module.css` | barre progression orange | Wizard étapes |
| `operation-result.module.css` | succès vert / erreur rouge | Résultat opération |
| `service-card.module.css` | tuile + badge coming_soon | Dashboard |
| `otp-input.module.css` | 6 cases | Saisie OTP |
| `radio-option-card.module.css` | bordure jaune active | Sélection compte |

## Assets marque

| Asset | Usage |
|-------|--------|
| `LOGO-DARK.png` | Fonds clairs (dashboard, reçus) |
| `LOGO-LIGTH.png` | Fonds sombres auth `#0a0a0a` |
| `favicon.svg`, `apple-touch-icon.png` | PWA Next |
| `illustrations/globe.svg` | `HeroGlobe` colonne droite |

Placer dans `public/` — composant `RawbankLogo` prop `variant: 'light' | 'dark'`, hauteur `--kiosk-header-logo-height`.

## MantineProvider

```tsx
// Next layout.tsx / Vite main.tsx
<MantineProvider theme={theme} defaultColorScheme="light">
```

Notifications : `@mantine/notifications` — succès vert, erreur rouge.

## Tailwind 4

`@import "tailwindcss"` dans globals — utilitaires pour **layout** uniquement ; styles kiosk dans CSS Modules.

`@theme inline` mappe `--font-sans` → Geist.

## Règles styling kiosk

1. **Pages** = orchestration — styles dans `components/kiosk/*.module.css`
2. **Nouveau composant** → module CSS dédié, variables `--kiosk-*`
3. **Boutons tactiles** → `min-height: var(--kiosk-touch-min)` (48px)
4. **Auth dark** → fond `#0a0a0a`, texte blanc sur `ChoiceButton.secondary`
5. **Ne pas** recréer logo/couleurs — utiliser assets et tokens existants
6. **Sync** Next ↔ Vite après changement CSS module

## Différences Next vs Vite

| Aspect | Next `globals.css` | Vite `index.css` |
|--------|-------------------|------------------|
| Fonts | `layout.tsx` next/font | `@fontsource-variable/geist` |
| Variables kiosk | identiques | identiques + `--font-geist-*` explicites |
| Modules kiosk | mêmes fichiers copiés | mêmes fichiers |

## Références complémentaires (dans ce skill)

- [digibranch-design-system.md](digibranch-design-system.md) — tokens marque, parcours UX
- [digibranch-kiosk-components.md](digibranch-kiosk-components.md) — catalogue 79 composants
- [paths-convention.md](paths-convention.md) — chemins portables
