import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workaxis/core/constants/app_radius.dart';
import 'package:workaxis/core/constants/app_spacing.dart';
import 'package:workaxis/core/theme/app_colors.dart';

class OtpInputRow extends StatefulWidget {
  const OtpInputRow({
    required this.onCompleted,
    this.onChanged,
    this.length = 6,
    super.key,
  });

  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final int length;

  @override
  State<OtpInputRow> createState() => _OtpInputRowState();
}

class _OtpInputRowState extends State<OtpInputRow> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _currentOtp => _controllers.map((c) => c.text).join();

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < widget.length && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      final focusIndex =
          digits.length < widget.length ? digits.length : widget.length - 1;
      _focusNodes[focusIndex].requestFocus();
      widget.onChanged?.call(_currentOtp);
      if (_currentOtp.length == widget.length) {
        widget.onCompleted(_currentOtp);
      }
      return;
    }

    widget.onChanged?.call(_currentOtp);

    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    if (_currentOtp.length == widget.length) {
      widget.onCompleted(_currentOtp);
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      widget.onChanged?.call(_currentOtp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalSpacing = AppSpacing.sm * (widget.length - 1);
        final itemWidth =
            ((constraints.maxWidth - totalSpacing) / widget.length)
                .clamp(40.0, 52.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(widget.length, (index) {
            return SizedBox(
              width: itemWidth,
              height: 56,
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) => _onKeyEvent(index, event),
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.surfaceContainerLowest,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.borderDefault,
                      borderSide: BorderSide(
                        color: AppColors.outlineVariant,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.borderDefault,
                      borderSide: BorderSide(
                        color: AppColors.outlineVariant,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.borderDefault,
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2.5,
                      ),
                    ),
                  ),
                  onChanged: (val) => _onChanged(index, val),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
