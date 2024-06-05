import '../enum/model_enums.dart';
import '../absModel/abs_model.dart';
import '../../common/util/config.dart';

class UserModel extends AbsModel {
  // member
  bool _isLoginedUser = false;
  bool _isGuestUser = false;
  //AccountSignUpType _accountSignUpType = AccountSignInType.none;
  //bool _isGoogleAccount = false;
  //Map<String, dynamic> _userData = {};
  //Map<String, dynamic> get allUserData => _userData;

  bool get isLoginedUser => _isLoginedUser;
  bool get isGuestUser => _isGuestUser;
  AccountSignUpType get accountSignUpType => AccountSignUpType.fromInt(int.parse(
      getValue('accountSignUpType')?.toString() ?? AccountSignUpType.none.index.toString()));
  String get userId => getValue('userId') ?? '';
  String get email => getValue('email') ?? '';
  String get password => getValue('password') ?? '';
  String get name => getValue('name') ?? '';
  String get phone => getValue('phone') ?? '';
  String get imagefile => getValue('imagefile') ?? '';
  String get userType => getValue('userType') ?? '';
  String get secret => getValue('secret') ?? '';

  bool isSuperUser() {
    return userType == 'tomato';
  }

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
    String guestUserId = myConfig?.config.guestUserId ?? '';
    if (guestUserId.isNotEmpty && guestUserId == userData['email']) {
      _isGuestUser = true;
    } else {
      _isLoginedUser = true;
    }
    fromMap(userData);
  }
}
