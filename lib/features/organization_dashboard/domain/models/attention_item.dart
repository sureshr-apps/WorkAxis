/// What an attention item is about. Presentation maps this to an icon.
enum AttentionKind {
  pendingReturns,
  branchOffline,
  lateArrivals,
  geofenceException,
  missingCheckOut,
  shiftTransfers,
  other,
}

/// How urgently an attention item needs action. Presentation maps this to a
/// status style.
enum AttentionSeverity { urgent, pending, neutral, info }

/// Attention or exception item displayed on operational dashboards.
///
/// Pure domain model: no Flutter types. Icons and colors are chosen in
/// presentation from [kind] and [severity].
class AttentionItem {
  final String id;
  final AttentionKind kind;
  final AttentionSeverity severity;
  final String title;
  final String subtitle;
  final String details;
  final String statusLabel;
  final String timestamp;
  final String? badgeText;
  final String? actionLabel;

  const AttentionItem({
    required this.id,
    required this.kind,
    required this.severity,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.statusLabel,
    required this.timestamp,
    this.badgeText,
    this.actionLabel,
  });
}
