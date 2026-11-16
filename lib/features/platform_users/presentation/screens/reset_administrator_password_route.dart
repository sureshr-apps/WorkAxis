import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/core/widgets/record_not_found_page.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/features/platform_users/presentation/controllers/platform_users_controller.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/reset_administrator_password_page.dart';

/// Routed entry for resetting a platform administrator's password. Loads the
/// administrator, saves through [PlatformUsersController], then returns to the
/// previous page, or the platform users list when opened directly.
class ResetAdministratorPasswordRoute extends StatefulWidget {
  const ResetAdministratorPasswordRoute({
    super.key,
    required this.administratorId,
  });

  final String administratorId;

  @override
  State<ResetAdministratorPasswordRoute> createState() =>
      _ResetAdministratorPasswordRouteState();
}

class _ResetAdministratorPasswordRouteState
    extends State<ResetAdministratorPasswordRoute> {
  PlatformAdministrator? _administrator;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final controller = context.read<PlatformUsersController>();
    final selected = controller.selectedAdministrator;
    final administrator = selected?.id == widget.administratorId
        ? selected
        : await controller.loadAdministrator(widget.administratorId);
    if (!mounted) return;
    setState(() {
      _administrator = administrator;
      _loading = false;
    });
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.platformUsers);
    }
  }

  Future<String?> _submit(String newPassword) async {
    final controller = context.read<PlatformUsersController>();
    final ok = await controller.resetPassword(
      id: widget.administratorId,
      newPassword: newPassword,
    );
    return ok
        ? null
        : controller.actionErrorMessage ??
              'The password could not be reset. Try again.';
  }

  void _saved() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Password reset for ${_administrator?.fullName}.'),
      ),
    );
    _leave();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final administrator = _administrator;
    if (administrator == null) {
      final loadError = context.watch<PlatformUsersController>().errorMessage;
      return RecordNotFoundPage(
        backLabel: 'Platform Users',
        currentLabel: 'Administrator',
        onBack: _leave,
        message: loadError ?? 'This platform administrator could not be found.',
        onRetry: _load,
      );
    }
    return ResetAdministratorPasswordPage(
      administrator: administrator,
      onSubmit: _submit,
      onClose: _leave,
      onSaved: _saved,
    );
  }
}
