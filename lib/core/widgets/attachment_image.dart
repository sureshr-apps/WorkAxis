import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/core/storage/attachment_storage.dart';

/// Shows an image from any value an attachment field can hold: a freshly
/// picked local file, a remote URL, or a stored reference that is resolved
/// through [AttachmentStorage].
class AttachmentImage extends StatefulWidget {
  const AttachmentImage({
    super.key,
    required this.reference,
    this.fit = BoxFit.cover,
    this.iconSize = 36,
  });

  final String reference;
  final BoxFit fit;
  final double iconSize;

  @override
  State<AttachmentImage> createState() => _AttachmentImageState();
}

class _AttachmentImageState extends State<AttachmentImage> {
  Future<String>? _url;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _url ??= _resolve();
  }

  @override
  void didUpdateWidget(covariant AttachmentImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reference != widget.reference) _url = _resolve();
  }

  Future<String>? _resolve() {
    final reference = widget.reference;
    if (AttachmentReference.needsUpload(reference)) return null;
    if (AttachmentReference.isRemoteUrl(reference)) {
      return Future.value(reference);
    }
    final AttachmentStorage storage;
    try {
      storage = context.read<AttachmentStorage>();
    } on ProviderNotFoundException {
      return Future.error('No attachment storage available.');
    }
    return storage.resolveUrl(reference);
  }

  Widget _broken() => Center(
    child: Icon(
      Icons.broken_image_outlined,
      size: widget.iconSize,
      color: AppColors.onSurfaceVariant,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final reference = widget.reference;
    if (AttachmentReference.needsUpload(reference)) {
      // A local pick that has not been saved yet.
      if (kIsWeb) {
        return Image.network(
          reference,
          fit: widget.fit,
          errorBuilder: (_, _, _) => _broken(),
        );
      }
      final file = File(reference);
      return file.existsSync() ? Image.file(file, fit: widget.fit) : _broken();
    }
    return FutureBuilder<String>(
      future: _url,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _broken();
        final url = snapshot.data;
        if (url == null) {
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return Image.network(
          url,
          fit: widget.fit,
          errorBuilder: (_, _, _) => _broken(),
        );
      },
    );
  }
}
