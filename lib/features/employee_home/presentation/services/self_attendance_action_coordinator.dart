import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';
import 'package:workaxis/features/employee_home/presentation/controllers/employee_home_controller.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Coordinates the shared self-service attendance action flow, including the
/// policy check and any required selfie capture.
class SelfAttendanceActionCoordinator {
  const SelfAttendanceActionCoordinator._();

  static Future<void> perform({
    required BuildContext context,
    required EmployeeHomeController controller,
    required ValueChanged<bool> onPreparingChanged,
    bool checkOut = false,
  }) async {
    if (controller.isActionProcessing) return;
    final action = checkOut
        ? AttendanceAction.checkOut
        : controller.summary?.currentStatus.nextAction;
    if (action == null) return;

    onPreparingChanged(true);
    try {
      final policy = await controller.checkAttendancePolicy();
      if (!context.mounted) return;
      if (policy == null) {
        _showActionMessage(
          context,
          controller.actionErrorMessage ??
              'Attendance settings could not be checked. Try again.',
        );
        return;
      }
      final role = context.read<AccessController>().accessContext?.user.role;
      if (role == UserRole.branchManager &&
          !policy.requireBranchManagerAttendance) {
        _showActionMessage(
          context,
          'Branch Manager attendance is disabled by your organization.',
        );
        return;
      }
      if (action == AttendanceAction.startBreak && !policy.allowBreaks) {
        _showActionMessage(
          context,
          'Mid-shift break recording is disabled by your organization.',
        );
        return;
      }

      String? selfieLocalPath;
      if (policy.requireAttendanceSelfie) {
        try {
          final image = await ImagePicker().pickImage(
            source: ImageSource.camera,
            preferredCameraDevice: CameraDevice.front,
            imageQuality: 85,
            maxWidth: 1280,
          );
          if (!context.mounted) return;
          if (image == null) {
            _showActionMessage(context, 'Take a selfie to record this action.');
            return;
          }
          selfieLocalPath = image.path;
        } on PlatformException {
          if (!context.mounted) return;
          _showActionMessage(
            context,
            'Camera access is required to record this attendance action.',
          );
          return;
        }
      }

      final recorded = await controller.recordAttendanceAction(
        action,
        policy: policy,
        selfieLocalPath: selfieLocalPath,
      );
      if (!context.mounted) return;
      _showActionMessage(
        context,
        recorded
            ? 'Attendance updated: ${controller.summary?.currentStatus.displayName}'
            : (controller.actionErrorMessage ??
                  'Attendance could not be recorded.'),
      );
    } finally {
      if (context.mounted) onPreparingChanged(false);
    }
  }

  static void _showActionMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
