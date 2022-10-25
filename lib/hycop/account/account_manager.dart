import 'package:http/browser_client.dart';

import '../../../hycop/hycop_factory.dart';
import '../../common/util/config.dart';

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
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart' as google_sign_in;

class AccountManager {
  // // static
  // static AbsAccount? HycopFactory.account; // = null;
  //
  static Future<void> initialize() async {
    // if (HycopFactory.account != null) return;
    // if (HycopFactory.serverType == ServerType.appwrite) {
    //   HycopFactory.account = AppwriteAccount();
    // } else {
    //   HycopFactory.account = FirebaseAccount();
    // }
    // //HycopFactory.account!.initialize();
    await HycopFactory.initAll();
  }

  static Future<bool> getSession() async {
    if (myConfig == null ||
        myConfig!.serverConfig == null ||
        myConfig!.config.sessionServerUrl.isEmpty) return false;
    final url = Uri.parse('${myConfig!.config.sessionServerUrl}/getSession/');
    // <!-- http.Response response = await htt!p.get(url);
    http.Client client = http.Client();
    if (client is BrowserClient) {
      logger.finest('client.withCredentials');
      client.withCredentials = true;
    }
    http.Response response = await client.get(url).catchError((error, stackTrace) =>
        throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'client.get(getSession) Failed !!!'));
    // -->
    var responseBody = utf8.decode(response.bodyBytes);
    var jsonData = jsonDecode(responseBody);
    logger.finest('jsonData=$jsonData');

    if (jsonData.isEmpty) {
      _currentLoginUser = UserModel(logout: true);
    } else {
      bool logined = jsonData['logined'] ?? false;
      String userId = jsonData['user_id'] ?? '';
      String serverType = jsonData['server_type'] ?? '';
      logger.finest('getSession($logined, $userId, $serverType)');
      if (logined) {
        _currentLoginUser = UserModel(userData: {'userId': userId});
        HycopFactory.serverType = ServerType.fromString(serverType);
        HycopFactory.setBucketId();
        return true;
      }
    }
    return false;
  }

  static Future<void> createSession() async {
    if (_currentLoginUser.isLoginedUser) {
      final url = Uri.parse('${myConfig!.config.sessionServerUrl}/createSession/');
      http.Client client = http.Client();
      if (client is BrowserClient) {
        logger.finest('client.withCredentials');
        client.withCredentials = true;
      }
      // <!-- http.Response response = await http.post(
      http.Response response = await client.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: <String, String>{
          'user_id': _currentLoginUser.userId,
          'server_type': HycopFactory.serverType.name,
        },
      ).catchError((error, stackTrace) => throw HycopUtils.getHycopException(
          error: error, defaultMessage: 'client.post(createSession) Failed !!!'));
      // -->
      var responseBody = utf8.decode(response.bodyBytes);
      var jsonData = jsonDecode(responseBody);
      logger.finest('jsonData=$jsonData');
    }
  }

  static Future<void> deleteSession() async {
    final url = Uri.parse('${myConfig!.config.sessionServerUrl}/deleteSession/');

    // <!-- http.Response response = await http.get(url);
    http.Client client = http.Client();
    if (client is BrowserClient) {
      logger.finest('client.withCredentials');
      client.withCredentials = true;
    }
    http.Response response = await client.get(url).catchError((error, stackTrace) =>
        throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'client.get(deleteSession) Failed !!!'));
    // -->

    var responseBody = utf8.decode(response.bodyBytes);
    var jsonData = jsonDecode(responseBody);
    logger.finest('jsonData=$jsonData');
  }

  static Future<void> createAccount(Map<String, dynamic> userData) async {
    await initialize();
    logger.finest('createAccount start');
    await HycopFactory.account!.createAccount(userData).catchError((error, stackTrace) =>
        throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'AccountManager.createAccount Failed !!!'));
    logger.finest('createAccount end');
    _currentLoginUser = UserModel(userData: userData);
    logger.finest('createAccount set');
  }

  static google_sign_in.GoogleSignIn? _googleSignIn;
  static google_sign_in.GoogleSignInAccount? _googleAccount;

  static Future<void> createAccountByGoogle(String googleApiKey) async {
    await initialize();
    logger.finest('createAccountByGoogle start');

    if (googleApiKey.isEmpty) {
      throw HycopUtils.getHycopException(defaultMessage: 'No googleApiKey !!!');
    }

    _googleSignIn ??= google_sign_in.GoogleSignIn(clientId: googleApiKey, scopes: []);

    try {
      final checkSignInResultO = await _googleSignIn!.isSignedIn();
      logger.finest('login result=$checkSignInResultO');
      if (checkSignInResultO) {
        _googleAccount = await _googleSignIn!.signInSilently();
        if (_googleAccount == null) {
          logger.finest('login disconnect');
          await _googleSignIn!.disconnect();
          throw HycopUtils.getHycopException(defaultMessage: 'login disconnect!!!');
        }
      } else {
        _googleAccount = await _googleSignIn!.signIn();
        if (_googleAccount == null) {
          logger.finest('login cancel');
          await _googleSignIn!.disconnect();
          throw HycopUtils.getHycopException(defaultMessage: 'login cancel!!!');
        }
      }
      bool alreadyExistAccount = false;
      await AccountManager.isExistAccount(_googleAccount!.email).catchError((error, stackTrace) {
        throw HycopUtils.getHycopException(error: error, defaultMessage: 'isExistAccount error !!!');
      }).then((value) {
        if (value == true) {
          alreadyExistAccount = true;
          //throw HycopUtils.getHycopException(defaultMessage: 'already exist account !!!');
        }
      });

      if(alreadyExistAccount == true) {
        await loginByService(_googleAccount!.email, AccountSignUpType.google).then((value) {
          return;
        }).onError((error, stackTrace) {
          throw HycopUtils.getHycopException(error: error, defaultMessage: 'loginByService error !!!');
        });
        return;
      }

      //
      Map<String, dynamic> userData = {};
      userData['name'] = _googleAccount!.displayName ?? '';
      userData['email'] = _googleAccount!.email;
      userData['password'] = _googleAccount!.email;
      userData['accountSignUpType'] = AccountSignUpType.google.index;
      await createAccount(userData).then((value) {
        return;
      }).onError((error, stackTrace) {
        throw HycopUtils.getHycopException(error: error, defaultMessage: 'createAccount error !!!');
      });
    } catch (error) {
      throw HycopUtils.getHycopException(error: error, defaultMessage: 'unknown google-account error !!!');
    }
  }

  static Future<bool> isExistAccount(String email) async {
    await initialize();
    logger.finest('isExistAccount');
    return HycopFactory.account!.isExistAccount(email).catchError((error, stackTrace) {
      logger.severe('isExistAccount failed (${error.toString()})');
      throw HycopUtils.getHycopException(
          error: error, defaultMessage: 'AccountManager.isExistAccount Failed !!!');
    });
  }

  static Future<void> getCurrentUserInfo() async {
    if (_currentLoginUser.isLoginedUser == false) {
      // not login !!!
      //throw HycopUtils.getHycopException(defaultMessage: 'not login !!!');
      return;
    }
    await initialize();
    Map<String, dynamic> userData = {};
    await HycopFactory.account!.getAccountInfo(_currentLoginUser.userId, userData).catchError(
        (error, stackTrace) => throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'AccountManager.updateAccount Failed !!!'));
    _currentLoginUser = UserModel(userData: userData);
  }

  static Future<void> updateAccountInfo(Map<String, dynamic> updateUserData) async {
    if (_currentLoginUser.isLoginedUser == false) {
      // not login !!!
      throw HycopUtils.getHycopException(defaultMessage: 'not login !!!');
    }
    await initialize();
    Map<String, dynamic> newUserData = {};
    newUserData.addAll(_currentLoginUser.getValueMap);
    newUserData.addAll(updateUserData);
    await HycopFactory.account!.updateAccountInfo(newUserData).catchError((error, stackTrace) =>
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
    await HycopFactory.account!.updateAccountPassword(newPassword, oldPassword).catchError(
        (error, stackTrace) => throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'AccountManager.updateAccount Failed !!!'));
    _currentLoginUser = UserModel(userData: newUserData);
  }

  static Future<void> login(String email, String password) async {
    if (_currentLoginUser.isLoginedUser) {
      // already login !!!
      throw HycopUtils.getHycopException(defaultMessage: 'already logined !!!');
    }
    await initialize();
    Map<String, dynamic> userData = {};
    await HycopFactory.account!.login(email, password, returnUserData: userData).catchError(
        (error, stackTrace) => throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'AccountManager.loginByEmail Failed !!!'));
    _currentLoginUser = UserModel(userData: userData);
    await createSession();
  }

  static Future<void> loginByService(String email, AccountSignUpType accountSignUpType) async {
    if (_currentLoginUser.isLoginedUser) {
      // already login !!!
      throw HycopUtils.getHycopException(defaultMessage: 'already logined !!!');
    }
    await initialize();
    Map<String, dynamic> userData = {};
    await HycopFactory.account!
        .login(email, email, returnUserData: userData, accountSignUpType: accountSignUpType)
        .catchError((error, stackTrace) => throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'AccountManager.loginByEmail Failed !!!'));
    _currentLoginUser = UserModel(userData: userData);
    await createSession();
  }

  static Future<void> loginByGoogle(String googleApiKey) async {
    logger.finest('loginByGoogle');

    if (googleApiKey.isEmpty) {
      throw HycopUtils.getHycopException(defaultMessage: 'No googleApiKey !!!');
    }

    _googleSignIn ??= google_sign_in.GoogleSignIn(clientId: googleApiKey, scopes: []);

    try {
      final checkSignInResult = await _googleSignIn!.isSignedIn();
      logger.finest('login result=$checkSignInResult');
      if (checkSignInResult) {
        _googleAccount = await _googleSignIn!.signInSilently();
        if (_googleAccount == null) {
          logger.finest('login disconnect');
          await _googleSignIn!.disconnect();
          throw HycopUtils.getHycopException(defaultMessage: 'login disconnect!!!');
        }
      } else {
        _googleAccount = await _googleSignIn!.signIn();
        if (_googleAccount == null) {
          logger.finest('login cancel');
          await _googleSignIn!.disconnect();
          throw HycopUtils.getHycopException(defaultMessage: 'login cancel!!!');
        }
      }
      await loginByService(_googleAccount!.email, AccountSignUpType.google).then((value) {
        return;
      }).onError((error, stackTrace) {
        throw HycopUtils.getHycopException(error: error, defaultMessage: 'loginByService error !!!');
      });
    } catch (error) {
      throw HycopUtils.getHycopException(error: error, defaultMessage: 'unknown google-account error !!!');
    }
  }

  static Future<void> deleteAccount() async {
    if (_currentLoginUser.isLoginedUser == false) {
      // already logout !!!
      throw HycopUtils.getHycopException(defaultMessage: 'not login !!!');
    }
    await initialize();
    await HycopFactory.account!.deleteAccount().catchError((error, stackTrace) =>
        throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'AccountManager.deleteAccount Failed !!!'));
    _currentLoginUser = UserModel(logout: true);
    await deleteSession();
  }

  static Future<void> logout() async {
    if (_currentLoginUser.isLoginedUser == false) {
      // already logout !!!
      return;
    }
    await initialize();
    await HycopFactory.account!.logout().catchError((error, stackTrace) =>
        throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'AccountManager.logout Failed !!!'));
    _currentLoginUser = UserModel(logout: true);
    await deleteSession();
  }

  static Future<void> resetPassword(String email) async {
    await initialize();
    await HycopFactory.account!.resetPassword(email).catchError((error, stackTrace) =>
        throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'AccountManager.resetPassword Failed !!!'));
  }

  static Future<void> resetPasswordConfirm(String userId, String secret, String newPassword) async {
    await initialize();
    await HycopFactory.account!
        .resetPasswordConfirm(HycopUtils.midToKey(userId), secret, newPassword)
        .catchError((error, stackTrace) => throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'AccountManager.resetPassword Failed !!!'));
  }

  static UserModel _currentLoginUser = UserModel(logout: true);
  static UserModel get currentLoginUser => _currentLoginUser;
}
