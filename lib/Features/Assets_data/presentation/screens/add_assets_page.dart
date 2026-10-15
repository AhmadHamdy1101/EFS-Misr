import 'package:efs_misr/Features/Assets_data/presentation/controller/assets_cubit.dart';
import 'package:efs_misr/core/lookups/lookup_repo.dart';
import 'package:efs_misr/core/utils/singelton.dart';
import 'package:efs_misr/core/utils/widgets/app_snack_bar.dart';
import 'package:efs_misr/core/utils/widgets/custom_dropdown_widget.dart';
import 'package:efs_misr/core/utils/widgets/custom_inbut_wedget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';

const _assetTypes = [
  {'name': 'Furniture', 'value': 'Furniture'},
  {'name': 'Electricity', 'value': 'Electricity'},
  {'name': 'air conditioning', 'value': 'air conditioning'},
  {'name': 'Digital Call', 'value': 'Digital Call'},
];

class AddAssetsPage extends StatefulWidget {
  const AddAssetsPage({super.key});

  @override
  State<AddAssetsPage> createState() => _AddAssetsPageState();
}

class _AddAssetsPageState extends State<AddAssetsPage> {
  final _formKey = GlobalKey<FormState>();
  final _barcode = TextEditingController();
  final _name = TextEditingController();
  final _floor = TextEditingController();
  final _place = TextEditingController();
  List<Map<String, dynamic>>? _branches;
  String? _branch;
  String? _type;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    final result = await getIt.get<LookupRepo>().getBranches();
    if (!mounted) return;
    setState(() {
      _branches = result.fold((_) => const [], (b) => b.toDropdownData());
    });
  }

  @override
  void dispose() {
    _barcode.dispose();
    _name.dispose();
    _floor.dispose();
    _place.dispose();
    super.dispose();
  }

  String? _required(String? value, String message) =>
      (value == null || value.trim().isEmpty) ? message.tr : null;

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final result = await context.read<AssetsCubit>().addAssetsData(
      barcode: _barcode.text.trim(),
      name: _name.text.trim(),
      floor: _floor.text.trim(),
      place: _place.text.trim(),
      type: _type,
      branch: BigInt.parse(_branch!),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (failure) => showAppSnackBar(messenger, failure.message, isError: true),
      (_) {
        Get.back();
        showAppSnackBar(messenger, 'Assets Added Successfully'.tr);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final branches = _branches;
    return Scaffold(
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              centerTitle: true,
              leading: BackButton(color: Theme.of(context).colorScheme.primary),
              title: Text(
                'Add Assets'.tr,
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
                      inbutHintText: 'Barcode'.tr,
                      changeToPass: false,
                      textEditingController: _barcode,
                      validator: (v) => _required(v, 'Please enter barcode'),
                    ),
                    CustomInputWidget(
                      inbutIcon: 'assets/images/Password.svg',
                      inbutHintText: 'Name'.tr,
                      changeToPass: false,
                      textEditingController: _name,
                    ),
                    CustomInputWidget(
                      inbutIcon: 'assets/images/Email.svg',
                      inbutHintText: 'Floor'.tr,
                      changeToPass: false,
                      textEditingController: _floor,
                    ),
                    CustomInputWidget(
                      inbutIcon: 'assets/images/Email.svg',
                      inbutHintText: 'Place'.tr,
                      changeToPass: false,
                      textEditingController: _place,
                    ),
                    if (branches == null)
                      const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.green,
                        ),
                      )
                    else
                      CustomDropdownWidget(
                        inbutIcon: 'assets/images/address.svg',
                        inbutHintText: 'Branch'.tr,
                        selectedValue: _branch,
                        data: branches,
                        onChanged: (value) => _branch = value,
                        validator: (v) =>
                            _required(v, 'Please choose a branch'),
                      ),
                    CustomDropdownWidget(
                      inbutIcon: 'assets/images/company.svg',
                      inbutHintText: 'Type'.tr,
                      selectedValue: _type,
                      data: _assetTypes,
                      onChanged: (value) => _type = value,
                      validator: (v) => _required(v, 'Please choose a type'),
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
                            'Add'.tr,
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
