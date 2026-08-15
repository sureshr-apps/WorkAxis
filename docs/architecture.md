# WorkAxis Architecture Documentation

This document describes the architectural foundation and engineering patterns for WorkAxis, adhering to the constraints defined in `AGENTS.md`.

## 1. Project Organization

WorkAxis follows a **Feature-First Clean Architecture**:

```text
lib/
├── app/
│   ├── app.dart                   # Root WorkAxisApp widget
│   └── routing/                   # Centralized routing with GoRouter & guards
│
├── core/
│   ├── constants/                 # Breakpoints, spacing, radii design tokens
│   ├── errors/                    # Typed application exceptions & failures
│   ├── theme/                     # Market Flow M3 colors, typography, and ThemeData
│   ├── utils/                     # Focused validators and formatters
│   └── widgets/                   # Genuinely reusable adaptive widgets (AppButton, AppTextField, etc.)
│
├── features/
│   ├── access_control/            # Application user profile, account status, invitations & guard screens
│   ├── authentication/            # Phone + OTP auth, Google sign-in, session state & controllers
│   └── organization/              # Multi-tenant organization memberships, switching & context scoping
│
└── main.dart                      # Application bootstrap & dependency registration
```

## 2. State Management Strategy

WorkAxis uses a **pragmatic, testable, single-approach state management strategy**:
- Pure `ChangeNotifier` and `ValueNotifier` controllers/notifiers scoped via `Provider`.
- Clear differentiation between UI state, feature application state, and cross-cutting organization context.
- **Organization Context Isolation**: The `OrganizationContextController` strictly resets downstream organization-scoped state, clears caches, and re-resolves role and branch assignments on organization switch, guaranteeing **zero cross-organization data leakage**.

## 3. Routing & Security Guards

Centralized routing is implemented with **GoRouter**:
- **Authentication Guard**: Unauthenticated users are redirected to `/welcome` or `/signin/phone`.
- **Access Resolution Guard**: Post-authentication routes through `/verifying-access` where application user profile, account status, and organization memberships are resolved.
- **Organization Selection**: Users with $>1$ active organization are guided to `/organizations`. Single-organization users automatically bypass selection.
- **Role & Branch Guard**:
  - `Organization Admin` $\rightarrow$ Admin shell.
  - `Branch Manager` / `Employee` without branch assignment $\rightarrow$ `/branch-required`.
  - `Branch Manager` / `Employee` with active branch assignment $\rightarrow$ Corresponding role shells.
- **Edge-Case Guards**:
  - Unknown identity $\rightarrow$ `/access-denied`.
  - Disabled account $\rightarrow$ `/account-disabled`.
  - Suspended organization $\rightarrow$ `/organization-unavailable`.
  - Identity mismatch on invite $\rightarrow$ `/invite/mismatch`.
  - Expired invite $\rightarrow$ `/invite/expired`.

## 4. Multi-Tenant Scoping & Security Policies

- Data queries, caches, and repository calls are strictly scoped by the active `organizationId`.
- Switching organization invalidates all previous organization-bound state.
- No sensitive keys, raw Firebase exceptions, or unformatted phone numbers are ever leaked to presentation widgets.

## 5. Responsive & Adaptive Strategy

WorkAxis natively targets Android phones and tablets:
- **Compact (`<600dp`)**: Single-column vertical layouts, bottom navigation, bottom-right thumb-friendly primary CTAs.
- **Medium (`600–839dp`)**: Centered card layouts, tablet margins (24dp), Navigation Rail.
- **Expanded (`≥840dp`)**: Multi-column master-detail layouts, desktop margins (32dp), Permanent Navigation Drawer.
