# WorkAxis

WorkAxis is an enterprise workforce, branch, and attendance management system built in Flutter targeting Android smartphones and tablets (portrait and landscape orientations).

## Design System: Market Flow M3

WorkAxis uses the **Market Flow M3** design system, an operational Material 3 implementation designed for retail, branch management, and logistics environments:
- **Primary Color**: Forest Green (`#002114` / `#003925` / `#0F5238`)
- **Secondary Color**: Clementine (`#7F5600` / `#FDC56D`)
- **Tertiary Color**: Pomegranate (`#420002` / `#6A0006`)
- **Surface**: Fresh Light Surface (`#FBF8FF`) / Dark Surface (`#161A32`)
- **Typography**: Plus Jakarta Sans (Display & Headlines) + Work Sans (Titles, Body & Labels)
- **Grid & Touch**: 8dp rhythmic spacing scale with minimum 48dp touch targets.

## Responsive Targets
- **Compact (`<600dp`)**: Single column phone layouts, bottom navigation, thumb-accessible primary actions.
- **Medium (`600–839dp`)**: Tablet layouts, navigation rail, Master-Detail pattern.
- **Expanded (`≥840dp`)**: Multi-column tablet/desktop landscape layouts, permanent navigation drawer.

---

## Authentication & OTP Configuration

WorkAxis features a pluggable OTP provider architecture:

### 1. Default Development / Testing Mode
Without MSG91 credentials configured, the app **automatically and seamlessly uses the In-Memory Mock provider**:
- Test OTP code: **`123456`**
- Default delivery channel: **SMS** (with interactive toggle for **WhatsApp**)

### 2. Connecting MSG91 in Production
When you obtain your MSG91 account details, pass them during build or runtime using `--dart-define`:
```bash
flutter run \
  --dart-define=MSG91_AUTH_KEY=your_msg91_auth_key \
  --dart-define=MSG91_SMS_TEMPLATE_ID=your_sms_template_id \
  --dart-define=MSG91_WHATSAPP_TEMPLATE_ID=your_whatsapp_template_id
```
The application will automatically detect the presence of `MSG91_AUTH_KEY` and activate the live MSG91 SendOTP v5 REST API client for both SMS and WhatsApp channels.

---

## Architecture
See [docs/architecture.md](docs/architecture.md) for detailed architectural documentation.
