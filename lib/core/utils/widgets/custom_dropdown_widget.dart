import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../app_text_styles.dart';

class CustomDropdownWidget extends StatefulWidget {
  const CustomDropdownWidget({
    super.key,
    required this.inbutIcon,
    required this.inbutHintText,
    this.textEditingController,
    this.textInputType,
    this.validator,
    this.onChanged,
    required this.selectedValue,
    required this.data,
    this.iconColor,
  });
  final Color? iconColor;
  final String inbutIcon;
  final String inbutHintText;
  final String? selectedValue;
  final List<Map<String, dynamic>> data;
  final TextEditingController? textEditingController;
  final TextInputType? textInputType;
  final String? Function(String?)? validator;
  final void Function(String?)? onChanged;

  @override
  State<CustomDropdownWidget> createState() => _CustomDropdownWidgetState();
}

class _CustomDropdownWidgetState extends State<CustomDropdownWidget> {
  String? _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.selectedValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(40), // pill shape
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        dropdownColor: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(10),
        isExpanded: true,
        initialValue: _currentValue,
        validator: widget.validator,
        hint: Text(
          widget.inbutHintText,
          textAlign: TextAlign.center,
          style: AppTextStyle.latoBold20(
            context,
          ).copyWith(color: Theme.of(context).colorScheme.primary),
        ),
        items: widget.data.map((status) {
          return DropdownMenuItem<String>(
            value: status['value'],
            child: Text(
              status['name'],
              style: AppTextStyle.latoBold20(
                context,
              ).copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _currentValue = value;
          });
          if (widget.onChanged != null) {
            widget.onChanged!(value);
          }
        },
        decoration: InputDecoration(
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 30,
            minHeight: 30,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(9.0),
            child: SvgPicture.asset(
              widget.inbutIcon,
              colorFilter: widget.iconColor == null
                  ? null
                  : ColorFilter.mode(widget.iconColor!, BlendMode.srcIn),
            ),
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
