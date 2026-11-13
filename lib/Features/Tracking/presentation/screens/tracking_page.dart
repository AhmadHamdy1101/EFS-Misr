import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/entities/user_entity.dart';
import '../controller/tracking_cubit.dart';
import 'tracking_page_body.dart';

class TrackingPage extends StatelessWidget {
  const TrackingPage({super.key, this.user});

  final UserEntity? user;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TrackingCubit(),
      child: TrackingPageBody(user: user),
    );
  }
}
