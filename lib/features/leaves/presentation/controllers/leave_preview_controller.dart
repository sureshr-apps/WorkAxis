import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/state/request_generation.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/leaves/domain/models/leave_preview.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';
import 'package:workaxis/features/leaves/domain/repositories/leaves_repository.dart';

/// Paid/unpaid preview for one leave form or review dialog.
///
/// Lives as long as the dialog that owns it (so it needs no session reset).
/// Draft changes are debounced, and an answer that a newer request has
/// superseded is dropped. A failed preview never blocks submitting; it only
/// leaves [errorMessage] for the dialog to show.
class LeavePreviewController extends ChangeNotifier with SafeNotifier {
  LeavePreviewController({
    required this.repository,
    required this.access,
    this.activeBranchId,
    this.debounce = const Duration(milliseconds: 300),
  });

  final LeavesRepository repository;
  final UserAccessContext access;

  /// Active branch of a Branch Manager; required to preview a review.
  final String? activeBranchId;
  final Duration debounce;

  final RequestGeneration _requests = RequestGeneration();
  Timer? _debounceTimer;
  LeavePreview? _preview;
  bool _isLoading = false;
  String? _errorMessage;

  /// The latest preview, or null while loading, after a failure or when the
  /// draft cannot be previewed.
  LeavePreview? get preview => _preview;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Requests a preview of the applicant's draft after [debounce]; each call
  /// replaces the previous one. Invalid date ranges are not sent.
  void previewDraft({
    required String leaveTypeId,
    required DateTime startDate,
    required DateTime endDate,
    String? editingRequestId,
  }) {
    _debounceTimer?.cancel();
    final token = _requests.next();
    _preview = null;
    _errorMessage = null;
    _isLoading = !endDate.isBefore(startDate);
    notifyListeners();
    if (!_isLoading) return;
    _debounceTimer = Timer(
      debounce,
      () => _run(
        token,
        () => repository.previewLeaveDraft(
          access: access,
          leaveTypeId: leaveTypeId,
          startDate: startDate,
          endDate: endDate,
          editingRequestId: editingRequestId,
        ),
      ),
    );
  }

  /// Loads the preview a reviewer sees for [request], immediately.
  Future<void> previewReview(LeaveRequest request) {
    _debounceTimer?.cancel();
    final token = _requests.next();
    _preview = null;
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();
    return _run(
      token,
      () => repository.previewLeaveReview(
        access: access,
        activeBranchId: activeBranchId,
        request: request,
      ),
    );
  }

  /// Drops any pending or in-flight preview (e.g. no leave type selected).
  void clear() {
    _debounceTimer?.cancel();
    _requests.invalidate();
    _preview = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _run(int token, Future<LeavePreview> Function() load) async {
    try {
      final preview = await load();
      if (!_requests.isCurrent(token) || isDisposed) return;
      _preview = preview;
    } catch (error, stackTrace) {
      if (!_requests.isCurrent(token) || isDisposed) return;
      _errorMessage = userMessageFor(
        error,
        stackTrace,
        fallback: 'Paid days could not be calculated right now.',
      );
    }
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _requests.invalidate();
    super.dispose();
  }
}
