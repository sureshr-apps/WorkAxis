import 'package:flutter/foundation.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';

class OrganizationMembersController extends ChangeNotifier {
  OrganizationMembersController({required this.repository});

  final OrganizationMembersRepository repository;
  List<OrganizationMember> _members = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _actionErrorMessage;
  String _query = '';

  List<OrganizationMember> get members => _members;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get actionErrorMessage => _actionErrorMessage;
  String get query => _query;

  Future<void> loadMembers({
    required UserAccessContext access,
    String? activeBranchId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _members = await repository.getMembers(
        access: access,
        activeBranchId: activeBranchId,
        query: _query,
      );
    } catch (_) {
      _errorMessage = 'Could not load organization accounts. Try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setQuery({
    required UserAccessContext access,
    required String query,
    String? activeBranchId,
  }) async {
    _query = query;
    await loadMembers(access: access, activeBranchId: activeBranchId);
  }

  Future<OrganizationMember?> getMember({
    required UserAccessContext access,
    required String memberId,
    String? activeBranchId,
  }) async {
    try {
      return await repository.getMember(
        access: access,
        memberId: memberId,
        activeBranchId: activeBranchId,
      );
    } catch (_) {
      _actionErrorMessage = 'This account is outside your access scope.';
      notifyListeners();
      return null;
    }
  }

  Future<OrganizationMember?> saveMember({
    required UserAccessContext access,
    required OrganizationMember member,
    required String initialPassword,
    String? activeBranchId,
  }) async {
    _isSaving = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final result = await repository.saveMember(
        access: access,
        member: member,
        initialPassword: initialPassword,
        activeBranchId: activeBranchId,
      );
      await loadMembers(access: access, activeBranchId: activeBranchId);
      return result;
    } catch (error) {
      _actionErrorMessage = error is StateError
          ? error.message
          : 'The account could not be saved. Try again.';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
