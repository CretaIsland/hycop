//import 'package:appwrite/appwrite.dart';
import 'dart:math';

import 'package:http/browser_client.dart';
import '../../hycop.dart';

// import '../../../hycop/hycop_factory.dart';
// import '../../common/util/config.dart';

// import '../../../common/util/config.dart';
// import 'absModel/abs_ex_model.dart';
// import 'abs_account.dart';
// import 'appwrite_account.dart';
// import 'firebase_account.dart';
// import '../../hycop/utils/hycop_exceptions.dart';
// import '../../common/util/logger.dart';
//import 'database/db_utils.dart';
// import '../absModel/abs_model.dart';
// import '../utils/hycop_utils.dart';
// import '../enum/model_enums.dart'; // AccountSignUpType 사용
// import '../model/user_model.dart';
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
    //await HycopFactory.initAll();
  }

  static Future<bool> getSession() async {
    if (myConfig == null ||
        myConfig!.serverConfig.apiServerUrl.isEmpty) {
      return false;
    }
    final url = Uri.parse('${myConfig!.serverConfig.apiServerUrl}/getSession/');
    // <!-- http.Response response = await htt!p.get(url);
    http.Client client = http.Client();
    if (client is BrowserClient) {
      logger.finest('client.withCredentials');
      client.withCredentials = true;
    }
    http.Response response = await client.get(url).catchError(
          (error, stackTrace) => throw HycopUtils.getHycopException(
            error: error,
            defaultMessage: 'client.get(getSession) Failed !!!',
          ),
        );
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
      if (ServerType.fromString(serverType) != HycopFactory.serverType) {
        _currentLoginUser = UserModel(logout: true);
      } else if (logined) {
        _currentLoginUser = UserModel(userData: {'userId': userId});
        return true;
      }
    }
    return false;
  }

  static Future<void> createSession() async {
    if (_currentLoginUser.isLoginedUser || _currentLoginUser.isGuestUser) {
      final url = Uri.parse('${myConfig!.serverConfig.apiServerUrl}/createSession/');
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
      ).catchError(
        (error, stackTrace) => throw HycopUtils.getHycopException(
          error: error,
          defaultMessage: 'client.post(createSession) Failed !!!',
        ),
      );
      // -->
      var responseBody = utf8.decode(response.bodyBytes);
      var jsonData = jsonDecode(responseBody);
      logger.finest('jsonData=$jsonData');
    }
  }

  static Future<void> deleteSession() async {
    final url = Uri.parse('${myConfig!.serverConfig.apiServerUrl}/deleteSession/');

    // <!-- http.Response response = await http.get(url);
    http.Client client = http.Client();
    if (client is BrowserClient) {
      logger.finest('client.withCredentials');
      client.withCredentials = true;
    }
    http.Response response = await client.get(url).catchError(
          (error, stackTrace) => throw HycopUtils.getHycopException(
            error: error,
            defaultMessage: 'client.get(deleteSession) Failed !!!',
          ),
        );
    // -->

    var responseBody = utf8.decode(response.bodyBytes);
    var jsonData = jsonDecode(responseBody);
    logger.finest('jsonData=$jsonData');
  }

  static Future<void> createAccount(Map<String, dynamic> userData, {bool autoLogin = true}) async {
    await initialize();
    logger.finest('createAccount start');
    // accountSignUpType
    var accountSignUpType = AccountSignUpType.hycop;
    if (userData['accountSignUpType'] == null) {
      userData['accountSignUpType'] = accountSignUpType.index;
    } else {
      accountSignUpType =
          AccountSignUpType.fromInt(int.parse(userData['accountSignUpType'].toString()));
      if (accountSignUpType == AccountSignUpType.none) {
        logger.severe('invalid sign-up type !!!');
        throw HycopUtils.getHycopException(defaultMessage: 'invalid sign-up type !!!');
      }
    }
    logger.info('accountSignUpType($accountSignUpType)');
    // password
    String password = userData['password'] ?? '';
    if (password.isEmpty && accountSignUpType == AccountSignUpType.hycop) {
      // hycop-service need password !!!
      logger.severe('password is empty !!!');
      throw HycopUtils.getHycopException(defaultMessage: 'password is empty !!!');
    }
    String passwordSha1 = '';
    if (accountSignUpType == AccountSignUpType.hycop) {
      // hycop-service's password = sha1-hash of password
      passwordSha1 = HycopUtils.stringToSha1(password);
    } else {
      // not hycop-service's password = sha1-hash of email
      String email = userData['email'] ?? '';
      if (email.isEmpty) {
        logger.severe('email is empty !!!');
        throw HycopUtils.getHycopException(defaultMessage: 'email is empty !!!');
      }
      passwordSha1 = HycopUtils.stringToSha1(email);
      password = passwordSha1;
    }
    userData['password'] = passwordSha1;
    logger.finest('password resetting to [$password] (${accountSignUpType.name}');
    // createAccount
    await HycopFactory.account!.createAccount(userData).catchError((error, stackTrace) =>
        throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'AccountManager.createAccount Failed !!!'));
    logger.finest('createAccount end');

    if (autoLogin) {
      _currentLoginUser = UserModel(userData: userData);
      await createSession();
    }
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
      final value = await AccountManager.isExistAccount(_googleAccount!.email)
          .catchError((error, stackTrace) {
        throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'isExistAccount error !!!');
      }); /*.then((value) {
        if (value == true) {
          alreadyExistAccount = true;
          //throw HycopUtils.getHycopException(defaultMessage: 'already exist account !!!');
        }
      });*/
      if (value == AccountSignUpType.none) {
        Map<String, dynamic> userData = {};
        userData['name'] = _googleAccount!.displayName ?? '';
        userData['email'] = _googleAccount!.email;
        userData['password'] = _googleAccount!.email;
        userData['accountSignUpType'] = AccountSignUpType.google.index;
        userData['imagefile'] = _googleAccount!.photoUrl;
        await createAccount(userData).then((value) {}).onError((error, stackTrace) {
          throw HycopUtils.getHycopException(
              error: error, defaultMessage: 'createAccount error !!!');
        });
      }

      if (_currentLoginUser.isLoginedUser == false) {
        await loginByService(_googleAccount!.email, AccountSignUpType.google)
            .then((value) {})
            .onError((error, stackTrace) {
          throw HycopUtils.getHycopException(
              error: error, defaultMessage: 'loginByService error !!!');
        });
      }
    } catch (error) {
      throw HycopUtils.getHycopException(
          error: error, defaultMessage: 'unknown google-account error !!!');
    }
  }

  static Future<UserModel> createDefaultAccount(String enterprise) async {
    Map<String, dynamic> userData = {};
    userData['name'] = '${enterprise}Admin';
    userData['email'] = '${enterprise}Admin@nomail.com';
    userData['password'] = '${enterprise}Admin!!';
    userData['accountSignUpType'] = AccountSignUpType.hycop.index;
    //userData['imagefile'] = _googleAccount!.photoUrl;
    await createAccount(userData, autoLogin: false).then((value) {}).onError((error, stackTrace) {
      throw HycopUtils.getHycopException(error: error, defaultMessage: 'createAccount error !!!');
    });
    return UserModel(userData: userData);
  }

  static Future<UserModel> createAccountByAdmin(String name, String email) async {
    Map<String, dynamic> userData = {};
    userData['name'] = name;
    userData['email'] = email;
    String pwd = generateTemporaryPassword(8);
    logger.severe(pwd);
    userData['password'] = pwd;
    userData['userType'] = "gen_password";
    userData['accountSignUpType'] = AccountSignUpType.hycop.index;
    //userData['imagefile'] = _googleAccount!.photoUrl;
    await createAccount(userData, autoLogin: false).then((value) {}).onError((error, stackTrace) {
      throw HycopUtils.getHycopException(error: error, defaultMessage: 'createAccount error !!!');
    });
    return UserModel(userData: userData);
  }

  static String generateTemporaryPassword(int length) {
    const String lowercaseLetters = 'abcdefghijklmnopqrstuvwxyz';
    const String uppercaseLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String numbers = '0123456789';
    const String specialChars = '@#\$%^&*()-_=+';

    // Ensure the password length is at least 8 characters
    final int minLength = length < 8 ? 8 : length;

    // Create a list to hold the password characters
    final List<String> passwordChars = [];

    // Randomly select at least one character from each character set
    final Random random = Random();
    passwordChars.add(lowercaseLetters[random.nextInt(lowercaseLetters.length)]);
    passwordChars.add(uppercaseLetters[random.nextInt(uppercaseLetters.length)]);
    passwordChars.add(numbers[random.nextInt(numbers.length)]);
    passwordChars.add(specialChars[random.nextInt(specialChars.length)]);

    // Fill the rest of the password length with random characters from all sets
    const String allChars = lowercaseLetters + uppercaseLetters + numbers + specialChars;
    while (passwordChars.length < minLength) {
      passwordChars.add(allChars[random.nextInt(allChars.length)]);
    }

    // Shuffle the characters to ensure randomness
    passwordChars.shuffle();

    // Join the characters to form the password string and return
    return passwordChars.join();
  }

  static Future<AccountSignUpType?> isExistAccount(String email) async {
    await initialize();
    logger.finest('isExistAccount');
    final value = await HycopFactory.account!.isExistAccount(email).catchError((error, stackTrace) {
      logger.severe('isExistAccount failed (${error.toString()})');
      throw HycopUtils.getHycopException(
          error: error, defaultMessage: 'AccountManager.isExistAccount Failed !!!');
    });
    return value;
  }

  static Future<void> getCurrentUserInfo() async {
    if (_currentLoginUser.isLoginedUser == false && _currentLoginUser.isGuestUser == false) {
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
    if (_currentLoginUser.isLoginedUser || _currentLoginUser.isGuestUser) {
      // already login !!!
      throw HycopUtils.getHycopException(defaultMessage: 'already logined !!!');
    }
    String passwordSha1 = HycopUtils.stringToSha1(password);
    await initialize();
    Map<String, dynamic> userData = {};
    await HycopFactory.account!.login(email, passwordSha1, returnUserData: userData).catchError(
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
    String password = HycopUtils.stringToSha1(email); // set password from email
    Map<String, dynamic> userData = {};
    await HycopFactory.account!
        .login(email, password, returnUserData: userData, accountSignUpType: accountSignUpType)
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
      }).onError((error, stackTrace) async {
        await _googleSignIn?.signOut();
        await _googleSignIn?.disconnect();
        _googleSignIn = null;
        _googleAccount = null;
        throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'loginByService error !!!');
      });
    } catch (error) {
      throw HycopUtils.getHycopException(
          error: error, defaultMessage: 'unknown google-account error !!!');
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
    await logout();
  }

  static Future<void> deleteAccountByUser(String userId) async {
    await initialize();
    Map<String, dynamic> userData = {};
    await HycopFactory.account!.getAccountInfo(userId, userData);

    await HycopFactory.account!.deleteAccountByUser(userData).catchError((error, stackTrace) =>
        throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'AccountManager.deleteAccountByUser Failed !!!'));
  }

  static Future<void> logout() async {
    if (_currentLoginUser.isLoginedUser == false && _currentLoginUser.isGuestUser == false) {
      // already logout !!!
      return;
    }
    await initialize();
    await HycopFactory.account!.logout().catchError((error, stackTrace) =>
        throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'AccountManager.logout Failed !!!'));
    if (_currentLoginUser.accountSignUpType == AccountSignUpType.google) {
      logger.finest('_googleSignIn?.signOut()');
      await _googleSignIn?.signOut();
      logger.finest('_googleSignIn?.disconnect()');
      await _googleSignIn?.disconnect();
      logger.finest('_googleSignIn = null');
      _googleSignIn = null;
      _googleAccount = null;
    }
    _currentLoginUser = UserModel(logout: true);
    await deleteSession();
  }

  static Future<(String, String)> resetPassword(String email) async {
    await initialize();
    var ret = await HycopFactory.account!.resetPassword(email).catchError((error, stackTrace) =>
        throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'AccountManager.resetPassword Failed !!!'));
    return ret;
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
