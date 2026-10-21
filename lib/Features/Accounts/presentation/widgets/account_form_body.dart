import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:efs_misr/core/lookups/lookup_repo.dart';
import 'package:efs_misr/core/utils/singelton.dart';
import 'package:efs_misr/core/utils/widgets/custom_dropdown_widget.dart';
import 'package:efs_misr/core/utils/widgets/custom_inbut_wedget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../domain/accounts_repo.dart';

const _companies = [
  {'name': 'EFS', 'value': 'EFS'},
  {'name': 'Bank Misr', 'value': 'Bank Misr'},
];
const _roles = [
  {'name': 'Admin', 'value': 'Admin'},
  {'name': 'User', 'value': 'User'},
  {'name': 'Worker', 'value': 'Worker'},
];
const _statuses = [
  {'name': 'Active', 'value': '1'},
  {'name': 'Internship', 'value': '2'},
  {'name': 'Terminated', 'value': '3'},
  {'name': 'Suspended', 'value': '4'},
];

/// Shared form for creating and editing an account. When [user] is null the
/// form is in "add" mode and asks for a password.
class AccountFormBody extends StatefulWidget {
  const AccountFormBody({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.onSubmit,
    this.user,
  });

  final String title;
  final String submitLabel;
  final UserEntity? user;

  /// Returns once the save has finished (successfully or not).
  final Future<void> Function(AccountForm form, String password) onSubmit;

  @override
  State<AccountFormBody> createState() => _AccountFormBodyState();
}

class _AccountFormBodyState extends State<AccountFormBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _companyEmail;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  final TextEditingController _password = TextEditingController();

  String? _company;
  String? _role;
  String? _status;
  String? _position;
  List<Map<String, dynamic>>? _positions;
  bool _saving = false;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _name = TextEditingController(text: user?.name);
    _email = TextEditingController(text: user?.email);
    _companyEmail = TextEditingController(text: user?.companyEmail);
    _address = TextEditingController(text: user?.address);
    _phone = TextEditingController(text: user?.phone);
    _company = _valueIn(_companies, user?.company);
    _role = _valueIn(_roles, user?.role);
    _status = _valueIn(_statuses, user?.status.toString());
    _loadPositions();
  }

  Future<void> _loadPositions() async {
    final result = await getIt.get<LookupRepo>().getPositions();
    if (!mounted) return;
    setState(() {
      _positions = result.fold((_) => const [], (p) => p.toDropdownData());
      _position = _valueIn(_positions!, widget.user?.position?.id.toString());
    });
  }

  /// Dropdowns assert their initial value is one of the items.
  static String? _valueIn(List<Map<String, dynamic>> items, String? value) {
    if (value == null) return null;
    return items.any((item) => item['value'] == value) ? value : null;
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _companyEmail,
      _address,
      _phone,
      _password,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value, String message) =>
      (value == null || value.trim().isEmpty) ? message.tr : null;

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await widget.onSubmit(
      AccountForm(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        companyEmail: _companyEmail.text.trim(),
        company: _company!,
        positionId: _position == null ? null : BigInt.parse(_position!),
        role: _role!,
        status: int.parse(_status!),
      ),
      _password.text,
    );
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final positions = _positions;
    return Scaffold(
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              centerTitle: true,
              leading: BackButton(color: Theme.of(context).colorScheme.primary),
              title: Text(
                widget.title.tr,
                style: AppTextStyle.latoBold26(
                  context,
                ).copyWith(color: AppColors.green),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList.list(
                children: [
                  for (final field in <Widget>[
                    CustomInputWidget(
                      inbutIcon: 'assets/images/profile.svg',
                      inbutHintText: 'Username'.tr,
                      changeToPass: false,
                      textEditingController: _name,
                      validator: (v) => _required(v, 'Please enter username'),
                    ),
                    if (!_isEdit)
                      CustomInputWidget(
                        inbutIcon: 'assets/images/Password.svg',
                        inbutHintText: 'Password'.tr,
                        changeToPass: true,
                        textEditingController: _password,
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Password must be at least 6 characters'.tr
                            : null,
                      ),
                    CustomInputWidget(
                      inbutIcon: 'assets/images/Email.svg',
                      inbutHintText: 'Email'.tr,
                      changeToPass: false,
                      textEditingController: _email,
                      textInputType: TextInputType.emailAddress,
                      validator: (v) => _required(v, 'Please enter email'),
                    ),
                    CustomInputWidget(
                      inbutIcon: 'assets/images/Email.svg',
                      inbutHintText: 'Company Email'.tr,
                      changeToPass: false,
                      textEditingController: _companyEmail,
                    ),
                    CustomInputWidget(
                      inbutIcon: 'assets/images/address.svg',
                      inbutHintText: 'Address'.tr,
                      changeToPass: false,
                      textEditingController: _address,
                    ),
                    CustomInputWidget(
                      inbutIcon: 'assets/images/Phone.svg',
                      inbutHintText: 'Phone'.tr,
                      changeToPass: false,
                      textEditingController: _phone,
                      textInputType: TextInputType.phone,
                      validator: (v) => _required(v, 'Please enter phone'),
                    ),
                    CustomDropdownWidget(
                      inbutIcon: 'assets/images/status.svg',
                      inbutHintText: 'Status'.tr,
                      selectedValue: _status,
                      data: _statuses,
                      onChanged: (value) => _status = value,
                      validator: (v) => _required(v, 'Please enter status'),
                    ),
                    if (positions == null)
                      const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.green,
                        ),
                      )
                    else
                      CustomDropdownWidget(
                        inbutIcon: 'assets/images/position.svg',
                        inbutHintText: 'Position'.tr,
                        selectedValue: _position,
                        data: positions,
                        onChanged: (value) => _position = value,
                        validator: (v) => _required(v, 'Please enter position'),
                      ),
                    CustomDropdownWidget(
                      inbutIcon: 'assets/images/company.svg',
                      inbutHintText: 'Company'.tr,
                      selectedValue: _company,
                      data: _companies,
                      onChanged: (value) => _company = value,
                      validator: (v) => _required(v, 'Please enter company'),
                    ),
                    CustomDropdownWidget(
                      inbutIcon: 'assets/images/role.svg',
                      inbutHintText: 'Role'.tr,
                      selectedValue: _role,
                      data: _roles,
                      iconColor: AppColors.gray,
                      onChanged: (value) => _role = value,
                      validator: (v) => _required(v, 'Please enter role'),
                    ),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: field,
                    ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: const ButtonStyle(
                      padding: WidgetStatePropertyAll(
                        EdgeInsets.symmetric(vertical: 10),
                      ),
                      backgroundColor: WidgetStatePropertyAll(AppColors.green),
                      foregroundColor: WidgetStatePropertyAll(AppColors.white),
                    ),
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            widget.submitLabel.tr,
                            style: AppTextStyle.latoBold26(context),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
