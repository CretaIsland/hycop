// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../../hycop/absModel/abs_ex_model.dart';
import '../absModel/abs_model.dart';
// import 'package:firebase_core/firebase_core.dart';
//import '../../hycop/utils/hycop_exceptions.dart';
// import 'package:uuid/uuid.dart';
//import '../../model/abs_ex_model.dart';
import '../../common/util/logger.dart';
import 'abs_account.dart';
// import '../database/abs_database.dart';
import '../hycop_factory.dart';
import '../utils/hycop_exceptions.dart';
import '../utils/hycop_utils.dart';
import 'account_manager.dart';
import '../enum/model_enums.dart'; // AccountSignUpType 사용

class FirebaseAccount extends AbsAccount {
  // @override
  // Future<void> initialize() async {
  //   return Future.value();
  // }
  //

  @override
  Future<void> createAccount(Map<String, dynamic> createUserData) async {
    logger.finest('createAccount($createUserData)');
    // accountSignUpType
    // var accountSignUpType = AccountSignUpType.hycop;
    // if (createUserData['accountSignUpType'] == null) {
    //   createUserData['accountSignUpType'] = accountSignUpType.index;
    // } else {
    //   accountSignUpType = AccountSignUpType.fromInt(int.parse(createUserData['accountSignUpType'].toString()));
    //   if (accountSignUpType == AccountSignUpType.none) {
    //     logger.severe('invalid sign-up type !!!');
    //     throw HycopUtils.getHycopException(defaultMessage: 'invalid sign-up type !!!');
    //   }
    // }
    // userId
    String userId = createUserData['userId'] ?? '';
    if (userId.isEmpty) {
      // not exist userId ==> create new one
      userId = HycopUtils.midToKey(genMid2(ObjectType.user).replaceAll('-', ''));
      createUserData['userId'] = userId;
    }
    // email
    String email = createUserData['email'] ?? '';
    if (email.isEmpty) {
      logger.severe('email is empty !!!');
      throw HycopUtils.getHycopException(defaultMessage: 'email is empty !!!');
    }
    // password
    // String password = createUserData['password'] ?? '';
    // if (password.isEmpty && accountSignUpType == AccountSignUpType.hycop) {
    //   // hycop-service need password !!!
    //   logger.severe('password is empty !!!');
    //   throw HycopUtils.getHycopException(defaultMessage: 'password is empty !!!');
    // }
    // String passwordSha1 = '';
    // if (accountSignUpType == AccountSignUpType.hycop) {
    //   // hycop-service's password = sha1-hash of password
    //   passwordSha1 = HycopUtils.stringToSha1(password);
    // } else {
    //   // hycop-service's password = sha1-hash of email
    //   passwordSha1 = HycopUtils.stringToSha1(email); //sha1.convert(bytes).toString();
    //   password = passwordSha1;
    // }
    // createUserData['password'] = passwordSha1;
    // logger.finest('password resetting to [$password] (${accountSignUpType.name}');
    logger.finest('createAccount($createUserData)');
    await HycopFactory.dataBase!.createData('hycop_users', 'user=$userId', createUserData).catchError((error, stackTrace) =>
        throw HycopUtils.getHycopException(error: error, defaultMessage: 'loginByEmail Error !!!'));
    logger.finest('createAccount($createUserData) success');
  }

  @override
  Future<bool> isExistAccount(String email) async {
    final getUserData =
    await HycopFactory.dataBase!
        .simpleQueryData('hycop_users', name: 'email', value: email, orderBy: 'name')
        .catchError((error, stackTrace) =>
    throw HycopUtils.getHycopException(error: error, defaultMessage: 'not exist account(email:$email) !!!'));
    //     .then((value) {
    //   if (value.isEmpty) {
    //     logger.finest('not exist account(email:$email) !!!');
    //     //throw HycopException(message: 'not exist account(email:$email) !!!');
    //     return Future.value(false); //false;
    //   } else {
    //     logger.finest('exist account(email:$email)');
    //     return Future.value(true); //true;
    //   }
    // });
    // logger.finest('not exist account(email:$email)');
    // return Future.value(false); //false;
    if (getUserData.isEmpty) {
      return false;
    }
    return true;
  }

  @override
  Future<void> getAccountInfo(String userId, Map<String, dynamic> userData) async {
    logger.finest('getAccountInfo($userId)');
    var getUserData = await HycopFactory.dataBase!
        //.queryData('hycop_users', where: {'email': email, 'password': passwordSha1}, orderBy: 'name')
        .getData('hycop_users', 'user=$userId')
        .catchError((error, stackTrace) =>
    throw HycopUtils.getHycopException(error: error, defaultMessage: 'not exist account(userId:$userId) !!!'));
    if (getUserData.isEmpty) {
      logger.severe('getData error !!!');
      throw const HycopException(message: 'getData failed !!!');
    }
    if (getUserData['isRemoved'] == true) {
      logger.severe('removed user !!!');
      throw HycopUtils.getHycopException(defaultMessage: 'removed user !!!');
    }
    userData.addAll(getUserData);
    logger.finest('getAccountInfo success ($userData)');
  }

  @override
  Future<void> updateAccountInfo(Map<String, dynamic> updateUserData) async {
    logger.finest('updateAccount($updateUserData)');
    String userId = updateUserData["userId"] ?? "";
    if (userId.isEmpty) {
      throw const HycopException(message: 'no userId !!!');
    }
    await HycopFactory.dataBase!.setData('hycop_users', 'user=$userId', updateUserData).catchError(
        (error, stackTrace) => throw HycopUtils.getHycopException(error: error, defaultMessage: 'setData Error !!!'));
  }

  @override
  Future<void> updateAccountPassword(String newPassword, String oldPassword) async {
    logger.finest('updateAccountPassword($newPassword)');
    //
    if (newPassword.isEmpty || newPassword.isEmpty || newPassword == oldPassword) {
      // invalid password !!!
      logger.severe('invalid password !!!');
      throw HycopUtils.getHycopException(defaultMessage: 'invalid password !!!');
    }
    //
    String email = AccountManager.currentLoginUser.email;
    final getUserData = await HycopFactory.dataBase!
        .simpleQueryData('hycop_users', name: 'email', value: email, orderBy: 'name')
        .catchError((error, stackTrace) =>
            throw HycopUtils.getHycopException(error: error, defaultMessage: 'not exist account(email:$email) !!!'));
    if (getUserData.isEmpty) {
      logger.finest('not exist account(email:$email) !!!');
      throw HycopException(message: 'not exist account(email:$email) !!!');
    }
    String oldPasswordSha1 = HycopUtils.stringToSha1(oldPassword);
    String newPasswordSha1 = HycopUtils.stringToSha1(newPassword);
    for (var result in getUserData) {
      String pwd = result['password'] ?? '';
      if (pwd != oldPasswordSha1) {
        logger.finest('different oldpassword (email:$oldPassword) !!!');
        throw HycopException(message: 'not exist account(email:$email) !!!');
      }
      break;
    }
    //
    Map<String, dynamic> newUserData = {};
    newUserData.addAll(AccountManager.currentLoginUser.getValueMap);
    newUserData['password'] = newPasswordSha1;
    String userId = AccountManager.currentLoginUser.userId;
    await HycopFactory.dataBase!.setData('hycop_users', 'user=$userId', newUserData).catchError(
        (error, stackTrace) => throw HycopUtils.getHycopException(error: error, defaultMessage: 'setData Error !!!'));
  }

  @override
  Future<void> deleteAccount() async {
    logger.finest('deleteAccount(${AccountManager.currentLoginUser.email})');
    //
    Map<String, dynamic> newUserData = {};
    newUserData.addAll(AccountManager.currentLoginUser.getValueMap);
    newUserData['isRemoved'] = true;
    String userId = AccountManager.currentLoginUser.userId;
    await HycopFactory.dataBase!.setData('hycop_users', 'user=$userId', newUserData).catchError(
        (error, stackTrace) => throw HycopUtils.getHycopException(error: error, defaultMessage: 'setData Error !!!'));
  }

  @override
  Future<void> login(String email, String password,
      {Map<String, dynamic>? returnUserData, AccountSignUpType accountSignUpType = AccountSignUpType.hycop}) async {
    logger.finest('loginByEmail($email, $password)');
    var getUserData = await HycopFactory.dataBase!
        .queryData('hycop_users', where: {'email': email, 'password': password}, orderBy: 'name')
        .catchError((error, stackTrace) =>
            throw HycopUtils.getHycopException(error: error, defaultMessage: 'not exist account(email:$email) !!!'));
    if (getUserData.isEmpty) {
      logger.severe('getData error !!!');
      throw const HycopException(message: 'getData failed !!!');
    }
    for (var result in getUserData) {
      final type = AccountSignUpType.fromInt(
          int.parse(result['accountSignUpType'].toString()));
      if (type != accountSignUpType) {
        logger.severe('not [${accountSignUpType.name}] sign-up user !!!');
        throw HycopUtils.getHycopException(defaultMessage: 'not [${accountSignUpType.name}] sign-up user !!!');
      }
      if (result['isRemoved'] == true) {
        logger.severe('removed user !!!');
        throw HycopUtils.getHycopException(defaultMessage: 'removed user !!!');
      }
      returnUserData?.addAll(result);
      break;
    }
    logger.finest('loginByEmail success ($returnUserData)');
  }

  @override
  Future<void> logout() async {
    logger.finest('logout');
    // do nothing
  }

  @override
  Future<void> resetPassword(String email) async {
    logger.finest('resetPassword');
    //
    // 서버의 api-url로 email정보 전송
    // => users 테이블에서 email 계정을 찾아서 (임의의)secret키 set, userId를 get
    // => smtp로 email 계정으로 secret키 및 userId를 전송 (ex: https://www.examples.com/resetPasswordConfirm?userId=xxx&secret=yyy )
    //
  }

  @override
  Future<void> resetPasswordConfirm(String userId, String secret, String newPassword) async {
    logger.finest('resetPassword(userId:$userId, secret:$secret, newPassword:$newPassword)');
    var getUserData = await HycopFactory.dataBase!.getData('hycop_users', 'user=$userId').catchError(
        (error, stackTrace) =>
            throw HycopUtils.getHycopException(error: error, defaultMessage: 'not exist account(userId:$userId) !!!'));
    if (getUserData.isEmpty) {
      logger.severe('getData error !!!');
      throw const HycopException(message: 'getData failed !!!');
    }
    String dbSecret = getUserData['secret'] ?? "";
    if (dbSecret != secret) {
      logger.severe('not match secret-key !!!');
      throw const HycopException(message: 'not match secret-key !!!');
    }
    getUserData['password'] = HycopUtils.stringToSha1(newPassword);
    await HycopFactory.dataBase!.setData('hycop_users', 'user=$userId', getUserData).catchError(
        (error, stackTrace) => throw HycopUtils.getHycopException(error: error, defaultMessage: 'setData Error !!!'));
  }
}
