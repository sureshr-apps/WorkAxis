import 'package:flutter/widgets.dart';
import 'package:workaxis/core/widgets/status_chip.dart';

/// Typed attention or exception item displayed on operational dashboards.
class AttentionItem {
  final String id;
  final String title;
  final String subtitle;
  final String details;
  final StatusType statusType;
  final String statusLabel;
  final String timestamp;
  final String? badgeText;
  final String? actionLabel;
  final IconData? actionIcon;
  final IconData? itemIcon;

  const AttentionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.statusType,
    required this.statusLabel,
    required this.timestamp,
    this.badgeText,
    this.actionLabel,
    this.actionIcon,
    this.itemIcon,
  });
}
