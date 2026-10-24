import 'package:flutter/material.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';

/// Legacy alias for [AppKpiCard] to maintain backward compatibility.
/// All new features and screens should use [AppKpiCard] directly.
class OperationsKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? total;
  final Color? valueColor;
  final Widget? inlineBadge;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final Widget? footerIcon;
  final Color? footerDotColor;
  final String? footerText;
  final Widget? bottomWidget;

  const OperationsKpiCard({
    super.key,
    required this.title,
    required this.value,
    this.total,
    this.valueColor,
    this.inlineBadge,
    required this.icon,
    this.iconColor,
    this.iconBgColor,
    this.footerIcon,
    this.footerDotColor,
    this.footerText,
    this.bottomWidget,
  });

  @override
  Widget build(BuildContext context) {
    return AppKpiCard(
      title: title,
      value: value,
      total: total,
      valueColor: valueColor,
      inlineBadge: inlineBadge,
      icon: icon,
      iconColor: iconColor,
      iconBgColor: iconBgColor,
      footerIcon: footerIcon,
      footerDotColor: footerDotColor,
      footerText: footerText,
      bottomWidget: bottomWidget,
    );
  }
}
