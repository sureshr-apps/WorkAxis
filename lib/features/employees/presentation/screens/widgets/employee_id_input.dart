import 'package:flutter/material.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';

/// Employee ID field. IDs are assigned by the server (sequential per
/// organization); an optional value typed on creation is used instead.
/// When editing, the stored ID is shown read-only.
class EmployeeIdInput extends StatelessWidget {
  const EmployeeIdInput({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: 'Employee ID',
      hintText: enabled ? 'Auto-assigned' : null,
      helperText: enabled ? 'Leave blank to auto-assign' : null,
      enabled: enabled,
      prefixIcon: const Icon(Icons.badge_outlined, size: 20),
    );
  }
}
