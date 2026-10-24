import 'package:flutter/material.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';

/// Legacy alias for [AppKpiCard] on the Platform dashboard.
/// All implementations should use [AppKpiCard] directly.
class PlatformKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;
  final Widget? inlineBadge;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final Widget? footerIcon;
  final Color? footerDotColor;
  final String? footerText;
  final String? subtitle;
  final Widget? trailingBadge;
  final AppKpiIconPosition iconPosition;

  const PlatformKpiCard({
    super.key,
    required this.title,
    required this.value,
    this.valueColor,
    this.inlineBadge,
    required this.icon,
    this.iconColor,
    this.iconBgColor,
    this.footerIcon,
    this.footerDotColor,
    this.footerText,
    this.subtitle,
    this.trailingBadge,
    this.iconPosition = AppKpiIconPosition.topRight,
  });

  @override
  Widget build(BuildContext context) {
    return AppKpiCard(
      title: title,
      value: value,
      valueColor: valueColor,
      inlineBadge: inlineBadge,
      icon: icon,
      iconColor: iconColor,
      iconBgColor: iconBgColor,
      footerIcon: footerIcon,
      footerDotColor: footerDotColor,
      footerText: footerText ?? subtitle,
      iconPosition: iconPosition,
    );
  }
}
