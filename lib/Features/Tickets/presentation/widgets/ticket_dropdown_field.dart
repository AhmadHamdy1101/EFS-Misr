import 'package:efs_misr/Features/Tickets/domain/entities/ticket_lookup_option.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TicketDropdownField extends StatelessWidget {
  const TicketDropdownField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final List<TicketLookupOption> options;
  final int? value;
  final ValueChanged<int?> onChanged;
  final String? Function(int?)? validator;

  @override
  Widget build(BuildContext context) {
    final uniqueOptions = <int, TicketLookupOption>{
      for (final option in options) option.id: option,
    }.values.toList(growable: false);
    final selectedValue = uniqueOptions.any((item) => item.id == value)
        ? value
        : null;

    return DropdownButtonFormField<int>(
      initialValue: selectedValue,
      isExpanded: true,
      style: const TextStyle(color: AppColors.black),
      dropdownColor: AppColors.white,
      decoration: InputDecoration(
        labelText: label.tr,
        labelStyle: const TextStyle(color: AppColors.gray),
        floatingLabelStyle: const TextStyle(color: AppColors.green),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.gray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.green),
        ),
      ),
      items: uniqueOptions
          .map(
            (option) => DropdownMenuItem<int>(
              value: option.id,
              child: Text(
                option.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.black),
              ),
            ),
          )
          .toList(growable: false),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
