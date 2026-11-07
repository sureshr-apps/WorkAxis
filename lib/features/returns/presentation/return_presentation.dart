import 'package:flutter/material.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';

/// Maps the pure domain [ReturnStatus] to Flutter visuals.
extension ReturnStatusPresentation on ReturnStatus {
  StatusType get chipType => switch (this) {
    ReturnStatus.pending => StatusType.pending,
    ReturnStatus.approved => StatusType.active,
    ReturnStatus.rejected => StatusType.urgent,
  };
}

/// Maps the pure domain [ReturnReason] to Flutter visuals.
extension ReturnReasonPresentation on ReturnReason {
  IconData get icon => switch (this) {
    ReturnReason.damaged => Icons.broken_image_outlined,
    ReturnReason.expired => Icons.event_busy_outlined,
    ReturnReason.wrongItem => Icons.swap_horiz_outlined,
    ReturnReason.customerReturned => Icons.assignment_return_outlined,
    ReturnReason.other => Icons.help_outline,
  };
}

/// Display helpers for [ReturnItem].
extension ReturnItemPresentation on ReturnItem {
  /// Quantity without a trailing `.0`, followed by the unit.
  String get quantityLabel =>
      '${quantity % 1 == 0 ? quantity.toInt() : quantity} $unit';
}
