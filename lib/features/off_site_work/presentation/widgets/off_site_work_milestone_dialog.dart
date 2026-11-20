import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/widgets/attachment_image.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/off_site_work/domain/models/off_site_work_assignment.dart';

Future<bool?> showOffSiteMilestoneDialog({
  required BuildContext context,
  required OffSiteWorkMilestone milestone,
  required String title,
  required String prompt,
  required bool requiresReason,
  required String? requiredEvidenceDescription,
  required Future<bool> Function(String? note, List<String> photoPaths)
  onSubmit,
  required String? Function() failureMessage,
}) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (_) => OffSiteMilestoneDialog(
    milestone: milestone,
    title: title,
    prompt: prompt,
    requiresReason: requiresReason,
    requiredEvidenceDescription: requiredEvidenceDescription,
    onSubmit: onSubmit,
    failureMessage: failureMessage,
  ),
);

class OffSiteMilestoneDialog extends StatefulWidget {
  const OffSiteMilestoneDialog({
    super.key,
    required this.milestone,
    required this.title,
    required this.prompt,
    required this.requiresReason,
    required this.requiredEvidenceDescription,
    required this.onSubmit,
    required this.failureMessage,
  });

  final OffSiteWorkMilestone milestone;
  final String title;
  final String prompt;
  final bool requiresReason;
  final String? requiredEvidenceDescription;
  final Future<bool> Function(String? note, List<String> photoPaths) onSubmit;
  final String? Function() failureMessage;

  @override
  State<OffSiteMilestoneDialog> createState() => _OffSiteMilestoneDialogState();
}

class _OffSiteMilestoneDialogState extends State<OffSiteMilestoneDialog> {
  final TextEditingController _noteController = TextEditingController();
  final List<String> _photoPaths = [];
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos({required bool camera}) async {
    try {
      final picker = ImagePicker();
      final remaining = 5 - _photoPaths.length;
      if (remaining <= 0) return;
      final List<XFile> picked;
      if (camera) {
        final image = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85,
        );
        picked = image == null ? const [] : [image];
      } else {
        picked = await picker.pickMultiImage(
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85,
          limit: remaining,
        );
      }
      if (!mounted) return;
      setState(() {
        _photoPaths.addAll(picked.take(remaining).map((file) => file.path));
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Photo could not be selected. Try again.');
      }
    }
  }

  Future<void> _save() async {
    final note = _noteController.text.trim();
    final requiresEvidence =
        widget.requiredEvidenceDescription?.trim().isNotEmpty ?? false;
    if (widget.requiresReason && note.isEmpty) {
      setState(() => _error = 'Add a reason to continue.');
      return;
    }
    if (requiresEvidence && note.isEmpty && _photoPaths.isEmpty) {
      setState(() => _error = 'Add the requested evidence as a note or photo.');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final saved = await widget.onSubmit(
      note.isEmpty ? null : note,
      List.unmodifiable(_photoPaths),
    );
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isSaving = false;
        _error =
            widget.failureMessage() ??
            'Could not save. Check your location and retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final requiredEvidence =
        widget.requiredEvidenceDescription?.trim().isNotEmpty ?? false;
    return AlertDialog(
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.prompt),
              if (requiredEvidence) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Requested: ${widget.requiredEvidenceDescription}',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _noteController,
                label: widget.requiresReason || requiredEvidence
                    ? 'Note or evidence reference'
                    : 'Note (optional)',
                hintText: widget.requiresReason
                    ? 'Explain why the work could not be completed'
                    : 'Add an OTP, receipt number, or completion note',
                minLines: 2,
                maxLines: 4,
                maxLength: 2000,
                enabled: !_isSaving,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () => _pickPhotos(camera: false),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Choose photos'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () => _pickPhotos(camera: true),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Take photo'),
                  ),
                ],
              ),
              if (_photoPaths.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (var i = 0; i < _photoPaths.length; i++)
                      SizedBox(
                        width: 92,
                        height: 92,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: AppSpacing.roundedSm,
                                child: AttachmentImage(
                                  reference: _photoPaths[i],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton.filledTonal(
                                tooltip: 'Remove photo',
                                visualDensity: VisualDensity.compact,
                                onPressed: _isSaving
                                    ? null
                                    : () => setState(
                                        () => _photoPaths.removeAt(i),
                                      ),
                                icon: const Icon(Icons.close, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('${_photoPaths.length} of 5 photos'),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'WorkAxis records one GPS fix when you save this step.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        AppButton.outlined(
          text: 'Cancel',
          isFullWidth: false,
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
        ),
        AppButton.primary(
          text: 'Save step',
          isLoading: _isSaving,
          isFullWidth: false,
          onPressed: _isSaving ? null : _save,
        ),
      ],
    );
  }
}
