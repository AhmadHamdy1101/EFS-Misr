import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:efs_misr/Features/Home/domain/repo/home_repo.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

part 'assets_tickets_state.dart';

class AssetsTicketsCubit extends Cubit<AssetsTicketsState> {
  HomeRepo homeRepo;

  AssetsTicketsCubit(this.homeRepo) : super(AddAssetsTicketsInitial());

  final List<Assets> assets = [];
  final List<Tickets> tickets = [];
  final List<AssetsRepair> assetsRepair = [];

  Future<void> addAssetsAndTickets({
    required BigInt assetsId,
    required BigInt ticketId,
  }) async {
    final result = await homeRepo.addAssetsAndTickets(
      assetsId: assetsId,
      ticketId: ticketId,
    );
    result.fold(
      (l) {
        print(l.message);
      },
      (r) {
        getAssetsWithTicketId(ticketId: ticketId);
        emit(GetAssetsTicketsSuccess(assetsAndTickets: assets));
      },
    );
  }

  Future<void> getAssetsWithTicketId({required BigInt ticketId}) async {
    emit(GetAssetsTicketsLoading());
    final result = await homeRepo.getAssetsWithTicketID(ticketId: ticketId);
    result.fold(
      (l) {
        print(l.message);
        emit(GetAssetsTicketsFailure(message: l.message));
      },
      (r) {
        assets.clear();
        assets.addAll(r);
        emit(GetAssetsTicketsSuccess(assetsAndTickets: assets));
      },
    );
  }

  Future<void> getTicketsWithAssetsId({required BigInt assetId}) async {
    emit(GetAssetsTicketsLoading());
    final result = await homeRepo.getTicketsWithAssetsID(assetId: assetId);
    result.fold(
      (l) {
        print(l.message);
      },
      (r) {
        tickets.clear();
        tickets.addAll(r);
      },
    );
  }

  Future<void> addAssetsRepair({
    required BigInt assetsId,
    required BigInt ticketId,
    required String variation,
    required String comment,
    required num amount,
  }) async {
    final result = await homeRepo.addAssetsRepairs(
      assetsId: assetsId,
      ticketId: ticketId,
      variation: variation,
      comment: comment,
      amount: amount,
    );
    result.fold(
      (l) {
        print(l.message);
      },
      (r) {
        Get.snackbar(
          'Success',
          'Details Added Successfully',
          backgroundColor: AppColors.green,
        );
      },
    );
  }
}
