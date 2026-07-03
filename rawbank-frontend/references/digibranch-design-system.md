# Design system — Digibranch

> **Autonome** : tokens, thèmes et composants de marque — spécification UX complète inline.

## Identité visuelle Rawbank (kiosk)

| Asset | Nom fichier | Usage |
|-------|-------------|--------|
| Logo fond clair | `LOGO-DARK.png` | Dashboard, reçus, fond blanc |
| Logo fond sombre | `LOGO-LIGTH.png` | Auth dark `#0a0a0a` |
| Favicon | `favicon.svg`, `favicon.ico` | PWA Next.js |
| Globe 3D | `illustrations/globe.svg` | Colonne droite `HeroGlobe` |

Placer dans `public/` (Next) ou `public/assets/` (Vite). **Ne pas** recréer le logo en CSS.

## Tokens couleur (source de vérité)

```ts
// Design tokens — à refléter dans theme Mantine + CSS Modules kiosk
const RAWBANK_TOKENS = {
  primary: "#ff9e1b",        // CTA, StepProgress, accents marque
  primaryLight: "#ffd000",   // Dégradé logo, highlights dorés
  primaryStrong: "#ff9400",  // Hover (aligné GO-PASS myColor-6)
  success: "#22c55e",
  error: "#ef4444",
  authBg: "#0a0a0a",         // Écrans auth / langue / OTP
  dashboardBg: "#ffffff",    // Opérations, formulaires, succès
  surfaceMuted: "#f8f9fa",
  border: "#e5e7eb",
  textDark: "#1a1a1a",
  textMuted: "#6b7280",
} as const;
```

## Dimensions kiosk (1080p tactile)

| Token | Valeur | Usage |
|-------|--------|--------|
| `radius-md` | `12px` | Cartes, inputs |
| `radius-lg` | `16px` | Modales, panels |
| `btn-min-height` | `48px` | Tous boutons tactiles |
| `grid-gap` | `16px`–`24px` | Grilles services |
| `header-logo-height` | `72px` (accueil `96px`) | `RawbankLogo` |
| Résolution cible | 1920×1080 | Layout fixe kiosk |

## Thèmes contextuels

| Contexte | Fond | Composants typiques |
|----------|------|---------------------|
| Accueil langue, OTP, téléphone | Dark `#0a0a0a` | `KioskSplitHero`, `ChoiceButton`, `OtpInput` |
| Dashboard, wizards, succès | Light `#ffffff` | `KioskShell`, `ServiceGrid`, `ConfirmationCard` |
| Méthode auth (grille) | Light | `CatalogSelectionGrid`, `GridSelectionCard` |

**Règle** : ne pas mélanger dark/light sur une même étape — le shell impose le thème.

## Typographie

**Geist** variable (100–900) :

```tsx
// Next.js 16
import { Geist } from "next/font/google";
const geist = Geist({ subsets: ["latin"], variable: "--font-geist-sans" });

// Vite SPA
import "@fontsource-variable/geist";
```

Mantine `fontFamily: "var(--font-geist-sans), system-ui, sans-serif"`  
Tailwind 4 : `font-sans` mappé sur Geist.

## CSS architecture

| Couche | Technologie |
|--------|-------------|
| Composants kiosk | CSS Modules (`*.module.css` par composant) |
| Layout global | Tailwind 4 utilitaires |
| Mantine | `postcss-preset-mantine`, thème partagé |
| Tokens globaux | `globals.css` (Next) / `index.css` (Vite) |

**Pattern** : un fichier `nom.tsx` + `nom.module.css` — zéro styles layout dupliqués dans `page.tsx`.

## Composants marque — API

### RawbankLogo

```tsx
<RawbankLogo variant="light" height={72} />  // texte clair sur fond sombre
<RawbankLogo variant="dark" height={48} />   // texte sombre sur fond clair
```

### HeroGlobe

Illustration dorée colonne droite de `KioskSplitHero` — accueil langue et auth téléphone.

### StepProgress

```tsx
<StepProgress current={2} total={5} label={t(locale, "auth.step", { n: 2 })} />
```

Barre orange `#ff9e1b`, largeur = `current / total * 100%`.

### OperationResult

```tsx
<OperationResult
  variant="success"       // ou "error"
  title={t(locale, "common.success")}
  reference="TXN-20250703-001"
  errorCode="ERR-003"     // affiché si variant="error"
  onPrimary={() => navigate("/dashboard")}
  onSecondary={retry}
/>
```

### KioskFooter (actions bas d'écran)

```tsx
<KioskFooter
  onCancel={goBack}
  onContinue={nextStep}
  continueLabel={t(locale, "common.continue")}
  continueDisabled={!isValid}
  showConfirm={isLastStep}   // remplace Continue par Confirmer
/>
```

## Catalogue services (config)

```ts
export type ServiceStatus = "active" | "coming_soon" | "disabled";

export type KioskService = {
  id: string;
  route: string;
  status: ServiceStatus;
  labelKey: string;    // i18n ex. "services.accounts"
  descKey: string;
  icon: string;
};

export const KIOSK_SERVICES: KioskService[] = [
  { id: "accounts", route: "/services/accounts", status: "active", ... },
  { id: "statements", route: "/services/statements", status: "active", ... },
  // coming_soon → badge « Bientôt disponible », non cliquable
];
```

Hub relevés (`statement-types.ts`) : `account-statement`, `rib`, `debit-credit-notice`.

## Parcours transactionnel standard

```
Sélection compte → Saisie paramètres → Confirmation (ConfirmationCard)
  → Auth OTP (OtpChannelPicker + OtpInput) → Succès (OperationResult) + PDF/reçu
```

Wizard auth : **5 étapes** (`AUTH_WIZARD_TOTAL = 5`).

## Notifications Mantine

```tsx
notifications.show({
  color: "green",  // ou "red" pour erreur
  title: t(locale, "common.success"),
  message: "...",
});
```

Erreurs : toujours inclure code `ERR-*` si disponible via `resolveErrorMessage()`.

## Accessibilité kiosk

- Boutons minimum **48×48 px** (`btn-min-height`)
- `aria-label` sur toutes les icônes seules
- Focus trap sur modales OTP
- Contraste WCAG AA minimum sur fond dark auth (texte blanc `#fff` sur `#0a0a0a`)
- Zones tactiles espacées `grid-gap` ≥ 16px

## Alignement GO-PASS vs Digibranch

| Aspect | GO-PASS | Digibranch kiosk |
|--------|---------|------------------|
| Primary | `#ff9400` (Mantine myColor-6) | `#ff9e1b` (CTA kiosk) |
| Fond app | `#f4f6fb` clair | Dark auth + light ops |
| Styling | Classes `app-*` | CSS Modules + Tailwind |
| Police | Geist ou system-ui | Geist obligatoire |

## Écrans de référence (spec UX)

| Écran | Contenu clé |
|-------|-------------|
| Accueil | 3 langues FR/EN/Lingala, `KioskSplitHero` + globe |
| Auth 1/5 | Méthode (téléphone / code client) |
| Auth 2–4 | Code client, confirmation contact, canal OTP |
| Auth 5/5 | `OtpInput` 6 cases + countdown resend |
| Dashboard | `ServiceGrid` 2 colonnes, logo header |
| Mes comptes | `AccountSelector` radio + solde CDF/USD |
| Hub relevés | `CatalogSelectionGrid` 3 types |
| RIB wizard | 5 étapes : compte → confirm → prepare → OTP → succès |
| Résultat erreur | `OperationResult` variant error + code ERR |

## Anti-patterns design

- Dupliquer markup layout dans `page.tsx`
- Hex ad hoc hors tokens ci-dessus
- Logo texte « RAWBANK » en CSS au lieu de PNG
- Boutons < 48px hauteur
- Texte français en dur (toujours `t(locale, key)`)
