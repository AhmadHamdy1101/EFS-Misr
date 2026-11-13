import 'package:efs_misr/Features/Auth/presentation/viewmodel/auth_cubit.dart';
import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_permissions.dart';

extension PermissionsContext on BuildContext {
  /// Permissions of the signed-in user; rebuilds the caller when the user
  /// changes (sign-in, sign-out, profile update). Use in `build`.
  AppPermissions get permissions => AppPermissions(
    select<AuthCubit, UserEntity?>((cubit) => cubit.currentUser),
  );

  /// Same, without listening. Use in callbacks.
  AppPermissions get readPermissions =>
      AppPermissions(read<AuthCubit>().currentUser);
}
