
import 'package:efs_misr/Features/Home/data/models/supadart_header.dart';

import '../../../../constants/constants.dart';
import '../../../Home/data/models/user.dart';

abstract class AuthRemoteData{
  Future<User> getUserData({required String userId});
}

class AuthRemoteDataImpl extends AuthRemoteData{

  @override
  Future<User> getUserData({required String userId}) async {
      final user = await supabaseClient.users.select().eq('id', userId).withConverter(User.converter);
      return user.first;

  }

}