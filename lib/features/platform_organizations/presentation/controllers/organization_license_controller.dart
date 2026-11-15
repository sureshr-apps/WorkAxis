import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/state/request_generation.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/features/platform_organizations/domain/models/license_history_event.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_requests.dart';
import 'package:workaxis/features/platform_organizations/domain/repositories/organization_license_repository.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';

/// State of one organization's license tab: the license, its history, the
/// active plans and the four license actions.
///
/// [PlatformOrganizationsController] owns this controller and forwards its
/// notifications, so the details page (header tier and license tab) rebuilds
/// when the license changes.
///
/// Actions return null on success or a user-safe message for the dialog to
/// show next to the entered values. The license is re-read after each change.
class OrganizationLicenseController extends ChangeNotifier with SafeNotifier {
  OrganizationLicenseController({required this.repository});

  final OrganizationLicenseRepository repository;
  final RequestGeneration _requests = RequestGeneration();

  String? _organizationId;
  OrganizationLicense? _license;
  List<LicenseHistoryEvent> _history = const [];
  List<LicensePlan> _activePlans = const [];
  bool _isLoading = false;
  String? _errorMessage;

  /// Organization whose license is loaded or loading.
  String? get organizationId => _organizationId;

  List<LicensePlan> get activePlans => _activePlans;

  /// The license when it belongs to [organizationId]; never another
  /// organization's license while a switch is in progress.
  OrganizationLicense? licenseFor(String organizationId) =>
      organizationId == _organizationId ? _license : null;

  List<LicenseHistoryEvent> historyFor(String organizationId) =>
      organizationId == _organizationId ? _history : const [];

  bool isLoadingFor(String organizationId) =>
      _isLoading && organizationId == _organizationId;

  String? errorFor(String organizationId) =>
      organizationId == _organizationId ? _errorMessage : null;

  /// Loads the license, its history and the active plans for
  /// [organizationId]. A [silent] reload keeps the current view in place.
  Future<void> load(String organizationId, {bool silent = false}) async {
    final token = _requests.next();
    if (!silent) {
      _organizationId = organizationId;
      _license = null;
      _history = const [];
      _activePlans = const [];
      _errorMessage = null;
      _isLoading = true;
      notifyListeners();
    }
    try {
      final (license, history, plans) = await (
        repository.getLicense(organizationId),
        repository.getHistory(organizationId),
        repository.getActiveLicensePlans(),
      ).wait;
      if (!_requests.isCurrent(token)) return;
      _license = license;
      _history = history;
      _activePlans = plans;
      _errorMessage = null;
    } catch (e, st) {
      if (!_requests.isCurrent(token)) return;
      _errorMessage = userMessageFor(
        e,
        st,
        fallback: silent
            ? 'The change was saved, but the license could not be refreshed. '
                  'Reload the page to see the latest state.'
            : 'Could not load license details. Please try again.',
      );
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Assigns the first license of the selected organization.
  Future<String?> assignLicense(AssignLicenseRequest request) => _mutate(
    fallback: 'The license could not be assigned. Please try again.',
    action: (id) => repository.assignLicense(id, request),
  );

  Future<String?> changePlan(ChangeLicensePlanRequest request) => _mutate(
    fallback: 'The plan could not be changed. Please try again.',
    action: (id) => repository.changePlan(id, request),
  );

  Future<String?> modifyCommercialTerms(ModifyCommercialTermsRequest request) =>
      _mutate(
        fallback: 'The commercial terms could not be saved. Please try again.',
        action: (id) => repository.modifyCommercialTerms(id, request),
      );

  Future<String?> renewLicense(RenewLicenseRequest request) => _mutate(
    fallback: 'The license could not be renewed. Please try again.',
    action: (id) => repository.renewLicense(id, request),
  );

  Future<String?> _mutate({
    required String fallback,
    required Future<void> Function(String organizationId) action,
  }) async {
    final id = _organizationId;
    if (id == null) return fallback;
    try {
      await action(id);
    } catch (e, st) {
      return userMessageFor(e, st, fallback: fallback);
    }
    await load(id, silent: true);
    return null;
  }

  /// Drops all license state (session reset or organization removed).
  void clear() {
    _requests.invalidate();
    _organizationId = null;
    _license = null;
    _history = const [];
    _activePlans = const [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
