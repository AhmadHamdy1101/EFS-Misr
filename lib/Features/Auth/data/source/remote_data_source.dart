

import '../../../../constants/constants.dart';
import '../../../../core/models/supadart_header.dart';
import '../../../../core/models/user.dart';


abstract class AuthRemoteData{
  Future<Users> getUserData({required String userId});
}

class AuthRemoteDataImpl extends AuthRemoteData{

  @override
  Future<Users> getUserData({required String userId}) async {
      final user = await supabaseClient.users.select('*,positions(*)').eq('userid', userId).single();
      return Users.fromJson(user);
  }

}