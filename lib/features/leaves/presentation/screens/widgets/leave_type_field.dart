import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/features/leaves/domain/models/leave_type_option.dart';

/// Leave type picker over the organization's active types, with loading and
/// load-failure states.
class LeaveTypeField extends StatelessWidget {
  const LeaveTypeField({
    super.key,
    required this.types,
    required this.failed,
    required this.selectedId,
    required this.onChanged,
    required this.onRetry,
    this.errorText,
  });

  /// Null while loading.
  final List<LeaveTypeOption>? types;
  final bool failed;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final VoidCallback onRetry;
  final String? errorText;

  static const _decoration = InputDecoration(
    labelText: 'Leave type',
    border: OutlineInputBorder(),
  );

  @override
  Widget build(BuildContext context) {
    final options = types;
    if (failed) {
      return InputDecorator(
        decoration: _decoration.copyWith(
          errorText: 'Leave types could not be loaded.',
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ),
      );
    }
    if (options == null) {
      return const InputDecorator(
        decoration: _decoration,
        child: Row(
          children: [
            SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                'Loading leave types…',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );
    }
    final hasSelection = options.any((type) => type.id == selectedId);
    return DropdownButtonFormField<String>(
      initialValue: hasSelection ? selectedId : null,
      isExpanded: true,
      decoration: _decoration.copyWith(
        errorText: errorText,
        errorMaxLines: 2,
        hintText: options.isEmpty ? 'No leave types available' : null,
      ),
      items: [
        for (final type in options)
          DropdownMenuItem(
            value: type.id,
            child: Text(type.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
