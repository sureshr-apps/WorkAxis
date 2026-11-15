import 'package:flutter/material.dart';
import 'package:workaxis/core/widgets/attachment_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';

/// Interactive photo and document picker supporting Camera & Gallery.
///
/// Supports two visual variants:
/// - [EmployeePhotoPicker.avatar]: Circular employee profile photo.
/// - [EmployeePhotoPicker.document]: Document attachment box (e.g., Aadhaar card).
class EmployeePhotoPicker extends StatelessWidget {
  const EmployeePhotoPicker.avatar({
    super.key,
    required this.imagePath,
    required this.onImageChanged,
    this.label = 'Profile Photo',
    this.errorText,
  }) : isAvatar = true;

  const EmployeePhotoPicker.document({
    super.key,
    required this.imagePath,
    required this.onImageChanged,
    this.label = 'Aadhaar Card Photo',
    this.errorText,
  }) : isAvatar = false;

  final String? imagePath;
  final ValueChanged<String?> onImageChanged;
  final String label;
  final bool isAvatar;

  /// Inline validation message shown under the picker.
  final String? errorText;

  Widget _withError(Widget picker) {
    final error = errorText;
    if (error == null) return picker;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        picker,
        const SizedBox(height: AppSpacing.xs),
        Text(
          error,
          style: AppTypography.bodySmall.copyWith(color: AppColors.error),
        ),
      ],
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    Navigator.of(context).pop();
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        onImageChanged(picked.path);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  void _showSourceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Text(
                      label,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Take Photo with Camera'),
                onTap: () => _pickImage(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () => _pickImage(sheetContext, ImageSource.gallery),
              ),
              if (imagePath != null && imagePath!.isNotEmpty)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onImageChanged(null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(String path) => AttachmentImage(reference: path);

  @override
  Widget build(BuildContext context) => _withError(_buildPicker(context));

  Widget _buildPicker(BuildContext context) {
    if (isAvatar) {
      return Center(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryContainer.withValues(alpha: 0.5),
                    border: Border.all(
                      color: AppColors.outlineSubtle,
                      width: 2,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imagePath != null && imagePath!.isNotEmpty
                      ? _buildImageWidget(imagePath!)
                      : const Center(
                          child: Icon(
                            Icons.person_rounded,
                            size: 52,
                            color: AppColors.primary,
                          ),
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: InkWell(
                      onTap: () => _showSourceSheet(context),
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(AppSpacing.xs),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            TextButton(
              onPressed: () => _showSourceSheet(context),
              child: Text(
                imagePath == null || imagePath!.isEmpty
                    ? 'Upload Photo'
                    : 'Change Photo',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Document Card layout (e.g. Aadhaar Photo)
    return Material(
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedMd,
        side: BorderSide(
          color: imagePath != null
              ? AppColors.primary
              : AppColors.outlineVariant,
          width: imagePath != null ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () => _showSourceSheet(context),
        borderRadius: AppSpacing.roundedMd,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  color: AppColors.surfaceContainerLow,
                  border: Border.all(color: AppColors.outlineSubtle),
                ),
                clipBehavior: Clip.antiAlias,
                child: imagePath != null && imagePath!.isNotEmpty
                    ? _buildImageWidget(imagePath!)
                    : const Icon(
                        Icons.badge_outlined,
                        size: 30,
                        color: AppColors.primary,
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      imagePath != null && imagePath!.isNotEmpty
                          ? 'Photo attached • Tap to change or remove'
                          : 'Tap to take photo or choose from gallery',
                      style: AppTypography.bodySmall.copyWith(
                        color: imagePath != null
                            ? AppColors.statusActiveText
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                imagePath != null
                    ? Icons.check_circle_rounded
                    : Icons.upload_file_outlined,
                color: imagePath != null
                    ? AppColors.statusActiveText
                    : AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
