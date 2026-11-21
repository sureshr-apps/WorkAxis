import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/widgets/app_button.dart';

Future<bool?> showOffSiteWorkDeleteDialog({
  required BuildContext context,
  required Future<bool> Function() onDelete,
  required String? Function() failureMessage,
}) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (_) => OffSiteWorkDeleteDialog(
    onDelete: onDelete,
    failureMessage: failureMessage,
  ),
);

class OffSiteWorkDeleteDialog extends StatefulWidget {
  const OffSiteWorkDeleteDialog({
    super.key,
    required this.onDelete,
    required this.failureMessage,
  });

  final Future<bool> Function() onDelete;
  final String? Function() failureMessage;

  @override
  State<OffSiteWorkDeleteDialog> createState() =>
      _OffSiteWorkDeleteDialogState();
}

class _OffSiteWorkDeleteDialogState extends State<OffSiteWorkDeleteDialog> {
  bool _isDeleting = false;
  String? _errorMessage;

  Future<void> _delete() async {
    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });
    final deleted = await widget.onDelete();
    if (!mounted) return;
    if (deleted) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isDeleting = false;
      _errorMessage =
          widget.failureMessage() ?? 'The assignment could not be deleted.';
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Delete off-site work?'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This assignment will be removed. You can delete it only before the assignee starts work.',
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
        ],
      ],
    ),
    actions: [
      AppButton.outlined(
        text: 'Cancel',
        isFullWidth: false,
        onPressed: _isDeleting ? null : () => Navigator.of(context).pop(false),
      ),
      AppButton.destructive(
        text: 'Delete assignment',
        iconData: Icons.delete_outline,
        isFullWidth: false,
        isLoading: _isDeleting,
        onPressed: _isDeleting ? null : _delete,
      ),
    ],
  );
}
