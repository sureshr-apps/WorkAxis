import 'package:flutter/material.dart';
import 'package:workaxis/features/employees/presentation/screens/widgets/workforce_weekday_names.dart';

/// Multi-select field for an employee's recurring weekly days off.
/// Leaving every day unchecked means the employee has no weekly day off.
class WeeklyDaysOffField extends StatelessWidget {
  const WeeklyDaysOffField({
    super.key,
    required this.selectedDays,
    required this.onChanged,
    this.label = 'Weekly days off',
  });

  final List<int> selectedDays;
  final ValueChanged<List<int>> onChanged;
  final String label;

  String get _selectionLabel {
    final days =
        selectedDays
            .where((day) => day >= 0 && day < workforceWeekdayNames.length)
            .toSet()
            .toList()
          ..sort();
    if (days.isEmpty) return 'No day off';
    return days.map((day) => workforceWeekdayNames[day]).join(', ');
  }

  @override
  Widget build(BuildContext context) => MenuAnchor(
    menuChildren: [
      SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var day = 0; day < workforceWeekdayNames.length; day++)
              CheckboxListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(workforceWeekdayNames[day]),
                value: selectedDays.contains(day),
                onChanged: (selected) {
                  final next = selectedDays.toSet();
                  if (selected == true) {
                    next.add(day);
                  } else {
                    next.remove(day);
                  }
                  onChanged(next.toList()..sort());
                },
              ),
          ],
        ),
      ),
    ],
    builder: (context, controller, child) => Semantics(
      button: true,
      label: '$label: $_selectionLabel',
      child: InkWell(
        onTap: controller.isOpen ? controller.close : controller.open,
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          isFocused: controller.isOpen,
          decoration: InputDecoration(
            labelText: label,
            helperText: 'Leave all days unchecked for no day off.',
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: Text(
            _selectionLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ),
  );
}
