import '../../../hycop/hycop_factory.dart';

// import '../../../common/util/config.dart';
// import 'absModel/abs_ex_model.dart';
// import 'abs_account.dart';
// import 'appwrite_account.dart';
// import 'firebase_account.dart';
// import '../../hycop/utils/hycop_exceptions.dart';
import '../../common/util/logger.dart';
//import 'database/db_utils.dart';
// import '../absModel/abs_model.dart';
import '../utils/hycop_utils.dart';
import '../enum/model_enums.dart'; // AccountSignUpType 사용
import '../model/user_model.dart';

class AccountManager {
  // // static
  // static AbsAccount? HycopFactory.account; // = null;
  //
  static void initialize() {
    // if (HycopFactory.account != null) return;
    // if (HycopFactory.serverType == ServerType.appwrite) {
    //   HycopFactory.account = AppwriteAccount();
    // } else {
    //   HycopFactory.account = FirebaseAccount();
    // }
    // //HycopFactory.account!.initialize();
    HycopFactory.initAll();
  }

  static Future<void> createAccount(Map<String, dynamic> userData) async {
    initialize();
    logger.finest('createAccount start');
    await HycopFactory.account!.createAccount(userData).onError((error, stackTrace) =>
        throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'AccountManager.createAccount Failed !!!'));
    logger.finest('createAccount end');
    _currentLoginUser = UserModel(userData: userData);
    logger.finest('createAccount set');
  }

  static Future<bool> isExistAccount(String email) {
    initialize();
    return HycopFactory.account!.isExistAccount(email).catchError((error, stackTrace) =>
        throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'AccountManager.isExistAccount Failed !!!'));
  }

  static Future<void> updateAccountInfo(Map<String, dynamic> updateUserData) async {
    if (_currentLoginUser.isLoginedUser == false) {
      // not login !!!
      throw HycopUtils.getHycopException(defaultMessage: 'not login !!!');
    }
    initialize();
    Map<String, dynamic> newUserData = {};
    newUserData.addAll(_currentLoginUser.getValueMap);
    newUserData.addAll(updateUserData);
    await HycopFactory.account!.updateAccountInfo(newUserData).onError((error, stackTrace) =>
        throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'AccountManager.updateAccount Failed !!!'));
    _currentLoginUser = UserModel(userData: newUserData);
  }

  static Future<void> updateAccountPassword(String newPassword, String oldPassword) async {
    if (_currentLoginUser.isLoginedUser == false) {
      // not login !!!
      throw HycopUtils.getHycopException(defaultMessage: 'not login !!!');
    }
    //initialize();
    Map<String, dynamic> newUserData = {};
    newUserData.addAll(_currentLoginUser.getValueMap);
    newUserData['password'] = HycopUtils.stringToSha1(newPassword);
    await HycopFactory.account!.updateAccountPassword(newPassword, oldPassword).onError((error, stackTrace) =>
        throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'AccountManager.updateAccount Failed !!!'));
    _currentLoginUser = UserModel(userData: newUserData);
  }

  static Future<void> login(String email, String password) async {
    if (_currentLoginUser.isLoginedUser) {
      // already login !!!
      throw HycopUtils.getHycopException(defaultMessage: 'already logined !!!');
    }
    initialize();
    Map<String, dynamic> userData = {};
    await HycopFactory.account!.login(email, password, returnUserData: userData).onError((error, stackTrace) =>
        throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'AccountManager.loginByEmail Failed !!!'));
    _currentLoginUser = UserModel(userData: userData);
  }

  static Future<void> loginByService(String email, AccountSignUpType accountSignUpType) async {
    if (_currentLoginUser.isLoginedUser) {
      // already login !!!
      throw HycopUtils.getHycopException(defaultMessage: 'already logined !!!');
    }
    initialize();
    Map<String, dynamic> userData = {};
    await HycopFactory.account!
        .login(email, email, returnUserData: userData, accountSignUpType: accountSignUpType)
        .onError((error, stackTrace) => throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'AccountManager.loginByEmail Failed !!!'));
    _currentLoginUser = UserModel(userData: userData);
  }

  static Future<void> deleteAccount() async {
    if (_currentLoginUser.isLoginedUser == false) {
      // already logout !!!
      throw HycopUtils.getHycopException(defaultMessage: 'not login !!!');
    }
    initialize();
    await HycopFactory.account!.deleteAccount().onError((error, stackTrace) =>
        throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'AccountManager.deleteAccount Failed !!!'));
    _currentLoginUser = UserModel(logout: true);
  }

  static Future<void> logout() async {
    if (_currentLoginUser.isLoginedUser == false) {
      // already logout !!!
      return;
    }
    initialize();
    logger.finest('logout start');
    await HycopFactory.account!.logout().onError((error, stackTrace) => throw HycopUtils.getHycopException(
        error: error, defaultMessage: 'AccountManager.logout Failed !!!'));
    logger.finest('logout end');
    _currentLoginUser = UserModel(logout: true);
    logger.finest('logout set');
  }

  static Future<void> resetPassword(String email) async {
    initialize();
    await HycopFactory.account!.resetPassword(email).onError((error, stackTrace) =>
        throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'AccountManager.resetPassword Failed !!!'));
  }

  static Future<void> resetPasswordConfirm(String userId, String secret, String newPassword) async {
    initialize();
    await HycopFactory.account!.resetPasswordConfirm(HycopUtils.midToKey(userId), secret, newPassword).onError(
        (error, stackTrace) => throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'AccountManager.resetPassword Failed !!!'));
  }

  static UserModel _currentLoginUser = UserModel(logout: true);
  static UserModel get currentLoginUser => _currentLoginUser;

}

//
// setValue 예제 필요
//
