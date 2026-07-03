# Composants kiosk — Digibranch (79 composants)

## Table des matières

- [Règle DRY](#règle-dry)
- [Layout et shell](#layout-et-shell)
- [Auth](#auth)
- [Dashboard et catalogue](#dashboard-et-catalogue)
- [Comptes et mouvements](#comptes-et-mouvements)
- [Wizards relevés](#wizards-relevés)
- [Formulaires kiosk](#formulaires-kiosk)
- [Confirmation et résultats](#confirmation-et-résultats)
- [Loading et erreurs](#loading-et-erreurs)
- [Pattern CSS Module](#pattern-css-module)
- [Hooks associés](#hooks-associés)
- [Anti-patterns](#anti-patterns)
- [Références liées](#références-liées)

---

## Règle DRY

> **Pages = orchestration uniquement.** Toute UI réutilisable vit dans `components/kiosk/`. **Interdit** : sous-composants privés dans `page.tsx`, doublons type `TransferAccountSelector` vs `AccountSelector`.

Workflow :

1. Parcourir le catalogue ci-dessous
2. Paramétrer via props
3. Sinon créer un composant **générique** + `*.module.css`

Sync Next ↔ Vite : recopier le dossier kiosk après chaque changement UI.

---

## Layout et shell

| Composant | Props / rôle |
|-----------|----------------|
| `KioskShell` | `title`, children, footer — layout header + contenu + bas |
| `KioskSplitHero` | Colonne gauche contenu + `HeroGlobe` droite (auth dark) |
| `AuthWizardShell` | Shell wizard 5 étapes auth |
| `KioskFooter` | `onCancel`, `onContinue`, `continueDisabled`, `showConfirm` |
| `KioskBackFooter` | Retour seul |
| `StepProgress` | `current`, `total`, `label` — barre orange proportionnelle |
| `RawbankLogo` | `variant: "light" \| "dark"`, `height` |
| `HeroGlobe` | Illustration 3D dorée |
| `KioskAssistanceLink` | Lien aide bas-gauche (dark) |
| `KioskAssistancePanel` | Panneau aide dépliable |

```tsx
<KioskShell title={t(locale, "services.accounts")} footer={<KioskFooter ... />}>
  {children}
</KioskShell>
```

---

## Auth

| Composant | Rôle |
|-----------|------|
| `ChoiceButton` | Bouton large icône + label + hint — langue, méthode |
| `OtpInput` | 6 cases, auto-focus, paste support |
| `OtpChannelPicker` | SMS / WhatsApp / email |
| `OtpChannelIcon` | Icône canal |
| `PhoneInputField` | Saisie +243 |
| `CountryCodeSelect` | Indicatif pays |
| `ClientProfileCard` | Profil masqué post-lookup |
| `AuthMethodIcons` | Icônes méthodes auth |

```tsx
<OtpInput
  value={code}
  onChange={setCode}
  length={6}
  labels={otpLabels}  // useOtpInputLabels()
/>
```

---

## Dashboard et catalogue

| Composant | Rôle |
|-----------|------|
| `ServiceGrid` | Lit `KIOSK_SERVICES` — grille 2 colonnes |
| `ServiceCard` | Tuile + badge `coming_soon` |
| `ServiceIcons` | Map id → icône Tabler |
| `CatalogSelectionGrid` | Hub sous-types (relevés) |
| `GridSelectionCard` | Carte sélection grille |
| `StatementTypeIcons` | Icônes types relevé |

```tsx
<ServiceGrid
  services={KIOSK_SERVICES}
  locale={locale}
  onSelect={(route) => navigate(route)}
/>
```

---

## Comptes et mouvements

| Composant | Rôle |
|-----------|------|
| `AccountSelector` | Radio + solde CDF/USD formaté |
| `AccountList` | Liste comptes lecture seule |
| `AccountSummaryCard` | Récap compte sélectionné |
| `MovementSelector` | Choix mouvement avis débit/crédit |
| `KioskPagination` | Pagination listes — `useFilteredPagination` |

```tsx
<AccountSelector
  accounts={accounts}
  value={selectedId}
  onChange={setSelectedId}
  formatBalance={(n, ccy) => ccy === "CDF" ? formatCdf(n) : formatUsd(n)}
/>
```

---

## Wizards relevés

| Composant | Rôle |
|-----------|------|
| `StatementWizardLayout` | Shell étapes relevé |
| `StatementWizardSharedSteps` | Étapes communes compte + confirm |
| `StatementFlowSteps` | Indicateur étapes métier |

Hook `useStatementWizardShell` : `currentStep`, `totalSteps`, `goNext`, `goBack`.

---

## Formulaires kiosk

| Composant | Rôle |
|-----------|------|
| `KioskTextInput` | Input texte tactile min 48px |
| `KioskSearchInput` | Recherche avec icône |
| `KioskDateInput` | DD/MM/YYYY |
| `KioskFieldError` | Message erreur champ |
| `RadioOptionCard` | Carte radio bordure jaune si active |

---

## Confirmation et résultats

| Composant | Rôle |
|-----------|------|
| `ConfirmationCard` | Récap avant validation |
| `TransactionSummary` | Lignes montant + frais + total |
| `OperationResult` | `variant: "success" \| "error"`, `errorCode`, actions |
| `InfoCallout` | Encart information « i » |

```tsx
<OperationResult
  variant="success"
  title={t(locale, "common.success")}
  reference={txnRef}
  onPrimary={() => navigate("/dashboard")}
/>

<OperationResult
  variant="error"
  title={resolveErrorMessage(locale, code, error)}
  errorCode={code}
  onSecondary={retry}
/>
```

---

## Loading et erreurs

| Composant | Rôle |
|-----------|------|
| `KioskSpinner` | Spinner inline |
| `KioskGlobalLoader` | Overlay plein écran |
| `KioskLoaderProvider` | Context loader global |
| `KioskLoaderRouteSync` | Sync navigation → loader |
| `KioskLoadErrorView` | Écran erreur chargement |
| `KioskHardRedirect` | Redirect forcé session |
| `IconBadge` | Badge icône circulaire |

---

## Pattern CSS Module

Chaque composant = `nom.tsx` + `nom.module.css`.

```tsx
import classes from "./choice-button.module.css";

<button className={cx(classes.root, primary && classes.primary)}>
```

Variables globales `--kiosk-*` — voir [digibranch-theme-styles.md](digibranch-theme-styles.md). Pas de hex dupliqués dans les modules.

---

## Hooks associés

| Hook | Composant(s) |
|------|----------------|
| `useStatementWizardShell` | `StatementWizardLayout` |
| `useStatementWizardAccount` | Sélection compte wizard |
| `useOtpInputLabels` | `OtpInput` |
| `useDownloadCountdown` | Succès document PDF |
| `useFilteredPagination` | `KioskPagination` |
| `useKioskPageReady` | `KioskLoaderRouteSync` |
| `useKioskNavigation` | Navigation wizard |
| `useKioskFormAction` | Forms + Server Action |
| `useKioskSessionExpired` | ERR-006 |

---

## Anti-patterns

- Markup layout dupliqué dans `page.tsx`
- `TransferSuccess` séparé de `BillSuccess` — un seul `OperationResult`
- Texte français en dur — toujours `t(locale, key)`
- Boutons < 48px hauteur
- Décoder cookie `digibranch_sid` côté client

---

## Références liées

- Tokens visuels : [digibranch-design-system.md](digibranch-design-system.md)
- CSS `--kiosk-*` : [digibranch-theme-styles.md](digibranch-theme-styles.md)
- Next.js usage : [digibranch-nextjs-patterns.md](digibranch-nextjs-patterns.md)
- i18n : [digibranch-i18n-errors.md](digibranch-i18n-errors.md)
