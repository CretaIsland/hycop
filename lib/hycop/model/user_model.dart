
import '../enum/model_enums.dart';
import '../absModel/abs_model.dart';

class UserModel extends AbsModel {
  // member
  bool _isLoginedUser = false;
  //AccountSignUpType _accountSignUpType = AccountSignInType.none;
  //bool _isGoogleAccount = false;
  //Map<String, dynamic> _userData = {};
  //Map<String, dynamic> get allUserData => _userData;

  bool get isLoginedUser => _isLoginedUser;
  AccountSignUpType get accountSignUpType => AccountSignUpType.fromInt(int.parse(
      getValue('accountSignUpType')?.toString() ?? AccountSignUpType.none.index.toString()));
  String get userId => getValue('userId') ?? '';
  String get email => getValue('email') ?? '';
  String get password => getValue('password') ?? '';
  String get name => getValue('name') ?? '';
  String get phone => getValue('phone') ?? '';
  String get imagefile => getValue('imagefile') ?? '';
  String get userType => getValue('userType') ?? '';

  UserModel(
      {ObjectType type = ObjectType.user, Map<String, dynamic>? userData, bool logout = false})
      : super(type: type) {
    if (logout || userData == null) {
      return;
    }
    if (userData.isEmpty) {
      return;
    }
    String userId = userData['userId'] ?? '';
    if (userId.isEmpty) {
      return;
    }
    _isLoginedUser = true;
    fromMap(userData);
  }
}