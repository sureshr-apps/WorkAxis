import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_home_summary.dart';

/// Shift code and location status chips shown under the home header.
/// Chips for values the backend did not provide are omitted.
class HomeHeaderBadges extends StatelessWidget {
  const HomeHeaderBadges({super.key, required this.summary});

  final EmployeeHomeSummary summary;

  static bool _has(String value) =>
      value.isNotEmpty && value != EmployeeHomeSummary.unavailable;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (_has(summary.shiftCode))
        StatusChip(
          label: summary.shiftCode,
          type: StatusType.neutral,
          width: null,
        ),
      if (_has(summary.locationStatus))
        StatusChip(
          label: summary.locationStatus,
          type: summary.isWithinGeofence
              ? StatusType.active
              : StatusType.urgent,
          width: null,
        ),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: chips,
    );
  }
}
