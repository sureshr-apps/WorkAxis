import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/core/state/request_generation.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/settings/domain/models/organization_settings.dart';
import 'package:workaxis/features/settings/domain/models/platform_settings.dart';
import 'package:workaxis/features/settings/domain/repositories/settings_repository.dart';
import 'package:workaxis/features/settings/domain/validators/settings_validators.dart';

enum SettingsLoadStatus { initial, loading, loaded, error }

/// Presentation state for the organization and platform settings screens.
///
/// Load state ([organizationStatus]/[platformStatus] and [loadErrorMessage])
/// is kept apart from save state ([isSaving], [saveErrorMessage],
/// [validationErrors], [lastSaveSucceeded]) so a failed save never discards
/// the loaded values.
class SettingsController extends ChangeNotifier
    with SafeNotifier
    implements SessionScoped {
  SettingsController({required this.repository});

  final SettingsRepository repository;

  final RequestGeneration _loads = RequestGeneration();
  final RequestGeneration _saves = RequestGeneration();

  SettingsLoadStatus _organizationStatus = SettingsLoadStatus.initial;
  SettingsLoadStatus _platformStatus = SettingsLoadStatus.initial;
  OrganizationSettings? _organization;
  PlatformSettings? _platform;
  String? _loadErrorMessage;
  String? _saveErrorMessage;
  Map<SettingsField, String> _validationErrors = const {};
  bool _isSaving = false;
  bool _lastSaveSucceeded = false;

  SettingsLoadStatus get organizationStatus => _organizationStatus;
  SettingsLoadStatus get platformStatus => _platformStatus;
  OrganizationSettings? get organizationSettings => _organization;
  PlatformSettings? get platformSettings => _platform;
  String? get loadErrorMessage => _loadErrorMessage;
  String? get saveErrorMessage => _saveErrorMessage;
  Map<SettingsField, String> get validationErrors => _validationErrors;
  bool get isSaving => _isSaving;

  /// True after a successful save until the next edit/save attempt.
  bool get lastSaveSucceeded => _lastSaveSucceeded;

  Future<void> loadOrganization({required UserAccessContext access}) async {
    final token = _loads.next();
    _organizationStatus = SettingsLoadStatus.loading;
    _loadErrorMessage = null;
    notifyListeners();
    try {
      final result = await repository.getOrganizationSettings(access: access);
      if (!_loads.isCurrent(token)) return;
      _organization = result;
      _organizationStatus = SettingsLoadStatus.loaded;
    } catch (e, st) {
      if (!_loads.isCurrent(token)) return;
      _loadErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'Could not load organization settings. Please try again.',
      );
      _organizationStatus = SettingsLoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadPlatform({required UserAccessContext access}) async {
    final token = _loads.next();
    _platformStatus = SettingsLoadStatus.loading;
    _loadErrorMessage = null;
    notifyListeners();
    try {
      final result = await repository.getPlatformSettings(access: access);
      if (!_loads.isCurrent(token)) return;
      _platform = result;
      _platformStatus = SettingsLoadStatus.loaded;
    } catch (e, st) {
      if (!_loads.isCurrent(token)) return;
      _loadErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'Could not load platform settings. Please try again.',
      );
      _platformStatus = SettingsLoadStatus.error;
    }
    notifyListeners();
  }

  /// Validates and saves; returns whether the settings were saved.
  Future<bool> saveOrganization({
    required UserAccessContext access,
    required OrganizationSettings settings,
  }) {
    return _save(
      validate: () => SettingsValidators.organization(settings),
      persist: (isCurrent) async {
        final saved = await repository.saveOrganizationSettings(
          access: access,
          settings: settings,
        );
        if (isCurrent()) _organization = saved;
      },
      fallback: 'Could not save organization settings. Please try again.',
    );
  }

  /// Validates and saves; returns whether the settings were saved.
  Future<bool> savePlatform({
    required UserAccessContext access,
    required PlatformSettings settings,
  }) {
    return _save(
      validate: () => SettingsValidators.platform(settings),
      persist: (isCurrent) async {
        final saved = await repository.savePlatformSettings(
          access: access,
          settings: settings,
        );
        if (isCurrent()) _platform = saved;
      },
      fallback: 'Could not save platform settings. Please try again.',
    );
  }

  /// Clears save feedback (call when the user edits a field).
  void clearSaveState() {
    if (_saveErrorMessage == null &&
        _validationErrors.isEmpty &&
        !_lastSaveSucceeded) {
      return;
    }
    _saveErrorMessage = null;
    _validationErrors = const {};
    _lastSaveSucceeded = false;
    notifyListeners();
  }

  Future<bool> _save({
    required Map<SettingsField, String> Function() validate,
    required Future<void> Function(bool Function() isCurrent) persist,
    required String fallback,
  }) async {
    final token = _saves.next();
    _saveErrorMessage = null;
    _lastSaveSucceeded = false;
    _validationErrors = validate();
    if (_validationErrors.isNotEmpty) {
      notifyListeners();
      return false;
    }
    _isSaving = true;
    notifyListeners();
    try {
      await persist(() => _saves.isCurrent(token) && !isDisposed);
      if (!_saves.isCurrent(token) || isDisposed) return false;
      _lastSaveSucceeded = true;
      return true;
    } catch (e, st) {
      if (!_saves.isCurrent(token) || isDisposed) return false;
      _saveErrorMessage = userMessageFor(e, st, fallback: fallback);
      return false;
    } finally {
      if (_saves.isCurrent(token) && !isDisposed) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  @override
  void reset() {
    _loads.invalidate();
    _saves.invalidate();
    _organizationStatus = SettingsLoadStatus.initial;
    _platformStatus = SettingsLoadStatus.initial;
    _organization = null;
    _platform = null;
    _loadErrorMessage = null;
    _saveErrorMessage = null;
    _validationErrors = const {};
    _isSaving = false;
    _lastSaveSucceeded = false;
    notifyListeners();
  }
}
