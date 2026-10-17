import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';

/// Amount input with a currency prefix well ("UGX | 28,000,000").
class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.controller,
    this.currency = 'UGX',
    this.validator,
    this.hint,
  });

  final TextEditingController controller;
  final String currency;
  final FormFieldValidator<String>? validator;
  final String? hint;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      _GroupingFormatter(),
    ],
    style: AppTextStyles.mono(size: 15, letterSpacing: 0),
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Container(
        width: 56,
        margin: const EdgeInsets.only(right: 10),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.sunk,
          border: Border(right: BorderSide(color: AppColors.controlBorder)),
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(AppDimensions.radiusControl),
          ),
        ),
        child: Text(
          currency,
          style: AppTextStyles.mono(
            size: 13,
            color: AppColors.ink2,
            letterSpacing: 0,
          ),
        ),
      ),
    ),
  );

  static double? parse(TextEditingController c) =>
      Formatters.parseAmount(c.text);
}

class _GroupingFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(',', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final text = Formatters.grouped(int.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Tappable date input showing a mono date ("2 Oct 2026").
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.placeholder = 'Choose date',
    this.firstDate,
    this.lastDate,
    this.clearable = false,
  });

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String placeholder;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool clearable;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: firstDate ?? DateTime(now.year - 5),
      lastDate: lastDate ?? DateTime(now.year + 10),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => _pick(context),
    borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
    child: InputDecorator(
      decoration: InputDecoration(
        suffixIcon: clearable && value != null
            ? IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => onChanged(null),
              )
            : const Icon(Icons.calendar_today_outlined, size: 18),
      ),
      child: Text(
        value == null ? placeholder : Formatters.date(value!),
        style: value == null
            ? AppTextStyles.bodyLarge.copyWith(color: AppColors.ink3)
            : AppTextStyles.mono(size: 15, letterSpacing: 0),
      ),
    ),
  );
}
