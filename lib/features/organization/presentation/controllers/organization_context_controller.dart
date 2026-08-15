import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:workaxis/features/access_control/domain/entities/app_user.dart';
import 'package:workaxis/features/access_control/domain/entities/invitation.dart';
import 'package:workaxis/features/access_control/domain/entities/organization.dart';
import 'package:workaxis/features/access_control/domain/entities/organization_membership.dart';
import 'package:workaxis/features/access_control/domain/repositories/access_repository.dart';
import 'package:workaxis/features/authentication/domain/entities/auth_user.dart';

sealed class AccessState extends Equatable {
  const AccessState();

  @override
  List<Object?> get props => [];
}

final class AccessInitial extends AccessState {
  const AccessInitial();
}

final class AccessResolving extends AccessState {
  const AccessResolving(
      {this.message = 'Verifying your credentials and memberships...'});
  final String message;

  @override
  List<Object?> get props => [message];
}

final class AccessDeniedState extends AccessState {
  const AccessDeniedState({required this.reason});
  final String reason;

  @override
  List<Object?> get props => [reason];
}

final class AccountDisabledState extends AccessState {
  const AccountDisabledState({required this.user});
  final AppUser user;

  @override
  List<Object?> get props => [user];
}

final class PendingInvitationState extends AccessState {
  const PendingInvitationState({required this.invitation});
  final Invitation invitation;

  @override
  List<Object?> get props => [invitation];
}

final class InvitationExpiredState extends AccessState {
  const InvitationExpiredState({required this.invitation});
  final Invitation invitation;

  @override
  List<Object?> get props => [invitation];
}

final class InvitationMismatchState extends AccessState {
  const InvitationMismatchState({
    required this.invitation,
    required this.authenticatedPhone,
  });
  final Invitation invitation;
  final String authenticatedPhone;

  @override
  List<Object?> get props => [invitation, authenticatedPhone];
}

final class OrganizationSelectionRequiredState extends AccessState {
  const OrganizationSelectionRequiredState({
    required this.memberships,
    required this.user,
  });
  final List<OrganizationMembership> memberships;
  final AppUser user;

  @override
  List<Object?> get props => [memberships, user];
}

final class OrganizationUnavailableState extends AccessState {
  const OrganizationUnavailableState({
    required this.organization,
    required this.otherMemberships,
  });
  final Organization organization;
  final List<OrganizationMembership> otherMemberships;

  @override
  List<Object?> get props => [organization, otherMemberships];
}

final class BranchAssignmentRequiredState extends AccessState {
  const BranchAssignmentRequiredState({
    required this.membership,
    required this.user,
    required this.allMemberships,
  });
  final OrganizationMembership membership;
  final AppUser user;
  final List<OrganizationMembership> allMemberships;

  @override
  List<Object?> get props => [membership, user, allMemberships];
}

final class AccessGrantedState extends AccessState {
  const AccessGrantedState({
    required this.activeMembership,
    required this.user,
    required this.allMemberships,
  });

  final OrganizationMembership activeMembership;
  final AppUser user;
  final List<OrganizationMembership> allMemberships;

  @override
  List<Object?> get props => [activeMembership, user, allMemberships];
}

class OrganizationContextController extends ChangeNotifier {
  OrganizationContextController({required AccessRepository accessRepository})
      : _accessRepository = accessRepository;

  final AccessRepository _accessRepository;

  AccessState _state = const AccessInitial();
  AccessState get state => _state;

  AuthUser? _lastAuthUser;
  AuthUser? get lastAuthUser => _lastAuthUser;

  OrganizationMembership? get activeMembership {
    if (_state is AccessGrantedState) {
      return (_state as AccessGrantedState).activeMembership;
    }
    return null;
  }

  Future<void> resolveAccess(AuthUser authUser) async {
    _lastAuthUser = authUser;
    _state = const AccessResolving();
    notifyListeners();

    try {
      final phone = authUser.phoneNumber ?? '';
      if (phone.isEmpty) {
        _state = const AccessDeniedState(
            reason: 'No mobile number attached to account.');
        notifyListeners();
        return;
      }

      final appUser = await _accessRepository.resolveUserByPhone(phone);
      if (appUser == null) {
        // Check if there is an invitation for this phone
        final invite =
            await _accessRepository.getPendingInvitationByPhone(phone);
        if (invite != null) {
          _handleInvitation(invite, phone);
          return;
        }
        _state = const AccessDeniedState(
          reason:
              'Your account is not registered. Please contact your organization administrator.',
        );
        notifyListeners();
        return;
      }

      if (appUser.isDisabled) {
        _state = AccountDisabledState(user: appUser);
        notifyListeners();
        return;
      }

      final memberships = await _accessRepository.getMemberships(appUser.id);
      if (memberships.isEmpty) {
        final invite =
            await _accessRepository.getPendingInvitationByPhone(phone);
        if (invite != null) {
          _handleInvitation(invite, phone);
          return;
        }
        _state = const AccessDeniedState(
          reason: 'You do not have any active organization memberships.',
        );
        notifyListeners();
        return;
      }

      final activeMemberships = memberships.where((m) => m.isActive).toList();

      if (activeMemberships.isEmpty) {
        final suspendedMembership = memberships.firstWhere(
          (m) => m.organization.status == OrgStatus.suspended,
          orElse: () => memberships.first,
        );
        _state = OrganizationUnavailableState(
          organization: suspendedMembership.organization,
          otherMemberships: const [],
        );
        notifyListeners();
        return;
      }

      if (activeMemberships.length == 1) {
        _selectMembership(
          membership: activeMemberships.first,
          user: appUser,
          allMemberships: memberships,
        );
        return;
      }

      // Multiple organizations -> Route to Organization Selection
      _state = OrganizationSelectionRequiredState(
        memberships: activeMemberships,
        user: appUser,
      );
      notifyListeners();
    } catch (e) {
      _state = AccessDeniedState(reason: 'Failed to resolve access: $e');
      notifyListeners();
    }
  }

  void _handleInvitation(Invitation invite, String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final cleanInvitePhone = invite.invitedPhone.replaceAll(RegExp(r'\D'), '');

    if (cleanPhone != cleanInvitePhone) {
      _state = InvitationMismatchState(
        invitation: invite,
        authenticatedPhone: phone,
      );
    } else if (invite.isExpired) {
      _state = InvitationExpiredState(invitation: invite);
    } else {
      _state = PendingInvitationState(invitation: invite);
    }
    notifyListeners();
  }

  void _selectMembership({
    required OrganizationMembership membership,
    required AppUser user,
    required List<OrganizationMembership> allMemberships,
  }) {
    _accessRepository.recordLastAccessedOrganization(
      userId: user.id,
      organizationId: membership.organizationId,
    );

    if (membership.requiresBranch && !membership.hasValidBranch) {
      _state = BranchAssignmentRequiredState(
        membership: membership,
        user: user,
        allMemberships: allMemberships,
      );
    } else {
      _state = AccessGrantedState(
        activeMembership: membership,
        user: user,
        allMemberships: allMemberships,
      );
    }
    notifyListeners();
  }

  void selectOrganization(OrganizationMembership membership) {
    if (_state is OrganizationSelectionRequiredState) {
      final s = _state as OrganizationSelectionRequiredState;
      _selectMembership(
        membership: membership,
        user: s.user,
        allMemberships: s.memberships,
      );
    } else if (_state is AccessGrantedState) {
      final s = _state as AccessGrantedState;
      _selectMembership(
        membership: membership,
        user: s.user,
        allMemberships: s.allMemberships,
      );
    } else if (_state is BranchAssignmentRequiredState) {
      final s = _state as BranchAssignmentRequiredState;
      _selectMembership(
        membership: membership,
        user: s.user,
        allMemberships: s.allMemberships,
      );
    }
  }

  /// Switches active organization with complete context wiping (Zero Data Leakage).
  Future<void> switchOrganization(
      OrganizationMembership targetMembership) async {
    AppUser? user;
    List<OrganizationMembership> allMemberships = [];

    if (_state is AccessGrantedState) {
      final s = _state as AccessGrantedState;
      user = s.user;
      allMemberships = s.allMemberships;
    } else if (_state is BranchAssignmentRequiredState) {
      final s = _state as BranchAssignmentRequiredState;
      user = s.user;
      allMemberships = s.allMemberships;
    } else if (_state is OrganizationSelectionRequiredState) {
      final s = _state as OrganizationSelectionRequiredState;
      user = s.user;
      allMemberships = s.memberships;
    }

    if (user == null) return;

    // Transition state to clear any stale cache
    _state =
        const AccessResolving(message: 'Switching organization context...');
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 150));

    _selectMembership(
      membership: targetMembership,
      user: user,
      allMemberships: allMemberships,
    );
  }

  Future<void> acceptInvitation(String invitationId) async {
    final authUser = _lastAuthUser;
    if (authUser == null) return;

    _state = const AccessResolving(message: 'Joining organization...');
    notifyListeners();

    try {
      final phone = authUser.phoneNumber ?? '';
      var user = await _accessRepository.resolveUserByPhone(phone);
      user ??= AppUser(
        id: 'usr_${phone.replaceAll(RegExp(r'\D'), '')}',
        phoneNumber: phone,
        name: authUser.displayName ?? 'New User',
      );

      final newMembership = await _accessRepository.acceptInvitation(
        invitationId: invitationId,
        userId: user.id,
      );

      final allMemberships = await _accessRepository.getMemberships(user.id);
      _selectMembership(
        membership: newMembership,
        user: user,
        allMemberships: allMemberships,
      );
    } catch (e) {
      _state = AccessDeniedState(reason: 'Failed to accept invitation: $e');
      notifyListeners();
    }
  }

  Future<void> declineInvitation(String invitationId) async {
    _state = const AccessResolving(message: 'Declining invitation...');
    notifyListeners();

    try {
      await _accessRepository.declineInvitation(invitationId);
      if (_lastAuthUser != null) {
        await resolveAccess(_lastAuthUser!);
      } else {
        _state = const AccessDeniedState(reason: 'Invitation declined.');
        notifyListeners();
      }
    } catch (e) {
      _state = AccessDeniedState(reason: 'Failed to decline invitation: $e');
      notifyListeners();
    }
  }

  Future<void> retryResolution() async {
    if (_lastAuthUser != null) {
      await resolveAccess(_lastAuthUser!);
    }
  }

  void clear() {
    _state = const AccessInitial();
    _lastAuthUser = null;
    notifyListeners();
  }
}
