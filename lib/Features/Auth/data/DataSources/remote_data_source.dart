
import 'package:efs_misr/Features/Auth/data/models/supadart_header.dart';

import '../../../../constants/constants.dart';
import '../models/users.dart';

abstract class AuthRemoteData{
  Future<Users> getUserData({required String userId});
}

class AuthRemoteDataImpl extends AuthRemoteData{

  @override
  Future<Users> getUserData({required String userId}) async {
      final user = await supabaseClient.users.select().eq('id', userId).withConverter(Users.converter);
      return user.first;

  }

}