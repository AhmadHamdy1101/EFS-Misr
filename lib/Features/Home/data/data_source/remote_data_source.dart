
import '../../../../constants/constants.dart';
import '../../../../core/models/supadart_header.dart';
import '../../../../core/models/user.dart';

abstract class HomeRemoteDataSource {
  Future <List<Users>> getUsers();
}
class HomeRemoteDataSourceImpl extends HomeRemoteDataSource{
  @override
  Future<List<Users>> getUsers() async {
    final users = await supabaseClient.users
        .select('*,positions(*)')
        .withConverter(Users.converter);
    return users;
  }

}