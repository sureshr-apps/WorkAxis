# WorkAxis Development Mock Credentials

These accounts are used for local UI development and automated testing in the mock layer.

> [!NOTE]
> All mock accounts use the password: `Password123!` (or `password123` for convenience).

| Role | Username | Email Alias | Phone Alias | Scope / Details |
|---|---|---|---|---|
| **Platform Owner** | `owner` | `owner@workaxis.io` | `+15550001` | Platform management |
| **Platform Administrator** | `platformadmin` | `admin@platform.workaxis.io` | `+15550002` | Platform operations |
| **Organization Admin** | `orgadmin` | `admin@acme.com` | `+15550003` | Org: Acme Retail Ltd |
| **Branch Manager (Multiple)** | `manager_multi` | `manager.multi@acme.com` | `+15550004` | 3 assigned branches (triggers Branch Selection) |
| **Branch Manager (Single)** | `manager_single` | `manager.single@acme.com` | `+15550005` | 1 assigned branch (auto-selected) |
| **Employee** | `employee` | `sarah.chen@acme.com` | `+15550006` | Org: Acme Retail Ltd |
| **Disabled Account** | `disabled_user` | `disabled@acme.com` | `+15550007` | Inactive status (tests login denial) |

All login aliases for an account resolve to that account with the same password.
