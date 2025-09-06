
import 'package:efs_misr/Features/Home/data/models/supadart_header.dart';

import '../../../../constants/constants.dart';
import '../../../Home/data/models/user.dart';

abstract class AuthRemoteData{
  Future<Users> getUserData({required String userId});
}

class AuthRemoteDataImpl extends AuthRemoteData{

  @override
  Future<Users> getUserData({required String userId}) async {
      final user = await supabaseClient.users.select().eq('userid', userId).withConverter(Users.converter);
      return user.first;
  }

}