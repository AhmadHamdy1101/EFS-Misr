import 'package:bloc/bloc.dart';
import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:efs_misr/Features/Home/domain/repo/home_repo.dart';
import 'package:meta/meta.dart';

part 'accounts_state.dart';

class AccountsCubit extends Cubit<AccountsState> {
  HomeRepo homeRepo;
  AccountsCubit(this.homeRepo) : super(AccountsInitial());

  // Future<void> getAccounts() async{
  //   emit(GetAccountsLoading());
  //   final result = await homeRepo.getUsers();
  //   result.fold((failure) {
  //     emit(GetAccountsFailed(failure.message));
  //   }, (accounts) {
  //     emit(GetAccountsSuccess(accounts));
  //   });
  // }
}
