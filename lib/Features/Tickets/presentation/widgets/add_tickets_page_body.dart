import 'package:efs_misr/Features/Tickets/domain/entities/ticket_lookup_option.dart';
import 'package:efs_misr/Features/Tickets/presentation/controller/tickets_cubit.dart';
import 'package:efs_misr/Features/Tickets/presentation/widgets/ticket_dropdown_field.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:efs_misr/core/utils/app_text_styles.dart';
import 'package:efs_misr/core/utils/widgets/custom_button_widget.dart';
import 'package:efs_misr/core/utils/widgets/custom_inbut_wedget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    hide DatePickerTheme;
import 'package:get/get.dart';

class AddTicketsPageBody extends StatefulWidget {
  const AddTicketsPageBody({super.key});

  @override
  State<AddTicketsPageBody> createState() => _AddTicketsPageBodyState();
}

class _AddTicketsPageBodyState extends State<AddTicketsPageBody> {
  final _formKey = GlobalKey<FormState>();
  final _oracleIdController = TextEditingController();
  final _requestDateController = TextEditingController();
  final _commentController = TextEditingController();

  TicketFormOptions? _options;
  int? _branchId;
  int? _engineerId;
  String? _priority;
  DateTime _requestDate = DateTime.now();
  bool _isLoadingOptions = true;
  bool _isSaving = false;
  String? _optionsError;

  static const _priorities = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    _requestDateController.text = _formatDate(_requestDate);
    _loadOptions();
  }

  @override
  void dispose() {
    _oracleIdController.dispose();
    _requestDateController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    if (mounted && _optionsError != null) {
      setState(() {
        _isLoadingOptions = true;
        _optionsError = null;
      });
    }
    final result = await context.read<TicketsCubit>().getTicketFormOptions();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _optionsError = failure.message;
        _isLoadingOptions = false;
      }),
      (options) => setState(() {
        _options = options;
        _isLoadingOptions = false;
      }),
    );
  }

  Future<void> _selectRequestDate() async {
    await DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: DateTime(2000),
      maxTime: DateTime.now().add(const Duration(days: 3650)),
      currentTime: _requestDate,
      locale: LocaleType.en,
      onConfirm: (date) {
        setState(() {
          _requestDate = date;
          _requestDateController.text = _formatDate(date);
        });
      },
    );
  }

  Future<void> _submit() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    final oracleId = BigInt.tryParse(_oracleIdController.text.trim());
    if (oracleId == null || oracleId <= BigInt.zero) {
      _formKey.currentState!.validate();
      return;
    }

    setState(() => _isSaving = true);
    final result = await context.read<TicketsCubit>().addTicket(
      oracleId: oracleId,
      branchId: BigInt.from(_branchId!),
      engineerId: BigInt.from(_engineerId!),
      priority: _priority!,
      requestDate: _requestDate,
      comment: _commentController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
      (_) {
        _formKey.currentState!.reset();
        _oracleIdController.clear();
        _requestDateController.text = _formatDate(_requestDate);
        _commentController.clear();
        setState(() {
          _branchId = null;
          _engineerId = null;
          _priority = null;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ticket added successfully'.tr)));
      },
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Add Ticket'.tr,
          style: AppTextStyle.latoBold26(
            context,
          ).copyWith(color: AppColors.green),
        ),
      ),
      body: _isLoadingOptions
          ? const Center(child: CircularProgressIndicator())
          : _optionsError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_optionsError!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _loadOptions,
                      child: Text('Retry'.tr),
                    ),
                  ],
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  CustomInputWidget(
                    inbutIcon: 'assets/images/id.svg',
                    inbutHintText: 'Oracle Id'.tr,
                    changeToPass: false,
                    textEditingController: _oracleIdController,
                    textInputType: TextInputType.number,
                    validator: (value) {
                      final parsed = BigInt.tryParse(value?.trim() ?? '');
                      if (parsed == null || parsed <= BigInt.zero) {
                        return 'Enter a valid Oracle ID'.tr;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TicketDropdownField(
                    label: 'Branch',
                    options: _options!.branches,
                    value: _branchId,
                    onChanged: (value) => setState(() => _branchId = value),
                    validator: (value) =>
                        value == null ? 'Select a branch'.tr : null,
                  ),
                  const SizedBox(height: 16),
                  _buildPriorityField(),
                  const SizedBox(height: 16),
                  CustomInputWidget(
                    inbutIcon: 'assets/images/date.svg',
                    inbutHintText: 'Request Date'.tr,
                    changeToPass: false,
                    readOnly: true,
                    textEditingController: _requestDateController,
                    onTap: _selectRequestDate,
                  ),
                  const SizedBox(height: 16),
                  CustomInputWidget(
                    inbutIcon: 'assets/images/comment.svg',
                    inbutHintText: 'Comment'.tr,
                    changeToPass: false,
                    textEditingController: _commentController,
                    textInputType: TextInputType.multiline,
                    validator: (value) => (value?.trim().isEmpty ?? true)
                        ? 'Comment is required'.tr
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TicketDropdownField(
                    label: 'Engineer',
                    options: _options!.engineers,
                    value: _engineerId,
                    onChanged: (value) => setState(() => _engineerId = value),
                    validator: (value) =>
                        value == null ? 'Select an engineer'.tr : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: screenWidth,
                    child: CustomButtonWidget(
                      screenWidth: screenWidth,
                      color: AppColors.green,
                      text: _isSaving ? 'Saving...'.tr : 'Add Ticket'.tr,
                      onpressed: _isSaving ? null : _submit,
                      foregroundcolor: AppColors.white,
                      textstyle: AppTextStyle.latoBold26(context),
                      toppadding: 15,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPriorityField() {
    return DropdownButtonFormField<String>(
      initialValue: _priority,
      isExpanded: true,
      style: const TextStyle(color: AppColors.black),
      dropdownColor: AppColors.white,
      decoration: InputDecoration(
        labelText: 'Priority'.tr,
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
      items: _priorities
          .map(
            (value) => DropdownMenuItem(
              value: value,
              child: Text(
                value,
                style: const TextStyle(color: AppColors.black),
              ),
            ),
          )
          .toList(growable: false),
      onChanged: (value) => setState(() => _priority = value),
      validator: (value) => value == null ? 'Select a priority'.tr : null,
    );
  }
}
