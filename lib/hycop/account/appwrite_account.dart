// ignore: depend_on_referenced_packages
import 'package:appwrite/appwrite.dart';
//import '../../hycop/utils/hycop_exceptions.dart';
// ignore: depend_on_referenced_packages
//import 'package:uuid/uuid.dart';
//import '../../model/abs_ex_model.dart';
import '../../common/util/logger.dart';
import 'abs_account.dart';
import '../database/abs_database.dart';
import '../hycop_factory.dart';
import '../utils/hycop_utils.dart';
import '../utils/hycop_exceptions.dart';
import 'account_manager.dart';
import '../enum/model_enums.dart'; // AccountSignUpType 사용
import '../model/user_model.dart';

class AppwriteAccount extends AbsAccount {
  // @override
  // Future<void> initialize() async {
  //   return Future.value();
  // }


  @override
  Future<void> createAccount(Map<String, dynamic> createUserData) async {
    logger.finest('createAccount($createUserData)');
    // accountSignUpType
    var accountSignUpType = AccountSignUpType.fromInt(
      int.parse(createUserData['accountSignUpType'].toString()),
    );
    // userId
    String userId = createUserData['userId'] ?? '';
    if (userId.isEmpty) {
      // not exist userId ==> create new one
      userId = HycopUtils.genUuid(includeDash: false); //const Uuid().v4().replaceAll('-', '');
      createUserData['userId'] = userId;
      logger.info('new userId($userId)');
    }
    // email
    String email = createUserData['email'] ?? '';
    if (email.isEmpty) {
      logger.severe('email is empty !!!');
      throw HycopUtils.getHycopException(defaultMessage: 'email is empty !!!');
    }
    // password
    String password = createUserData['password'] ?? '';
    // user-foreign-key
    String userForeignKey = HycopUtils.genUuid(includeDash: false); //const Uuid().v4().replaceAll('-', '');
    logger.finest('createAccount(userId:$userId, email:$email, password:$password, name:$userForeignKey)');
    createUserData['userForeignKey'] = userForeignKey;
    // secret
    String secret = createUserData['secret'] ?? '';
    if (secret.isEmpty) {
      secret = HycopUtils.genUuid(includeDash: false); //const Uuid().v4().replaceAll('-', '');
      createUserData['secret'] = secret;
    }
    // create account
    Account account = Account(AbsDatabase.awDBConn!);
    final accountCreateResult = await account
        .create(userId: userId, email: email, password: password, name: userForeignKey)
        .catchError((error, stackTrace) =>
            throw HycopUtils.getHycopException(error: error, defaultMessage: 'Unknown DB Error !!!'));
    if (accountCreateResult.email.isEmpty) {
      logger.severe('account.create error !!!');
      throw HycopUtils.getHycopException(defaultMessage: 'account.create error !!!');
    }

    logger.fine("before login [===");

    await login(email, password, accountSignUpType: accountSignUpType).catchError((error, stackTrace) =>
        throw HycopUtils.getHycopException(error: error, defaultMessage: 'loginByEmail Error !!!'));

    logger.fine("===] after login");

    await HycopFactory.dataBase!
        //.createData('hycop_users', 'user=$userForeignKey', createUserData)
        .createData('hycop_users', userForeignKey, createUserData)
        .catchError((error, stackTrace) =>
            throw HycopUtils.getHycopException(error: error, defaultMessage: 'createData Error !!!'));

    logger.finest('createAccount(userId:$userId, email:$email, password:$password, name:$userForeignKey) success');
  }


  @override
  Future<AccountSignUpType?> isExistAccount(String email) async {
    List getUserDataList = await HycopFactory.dataBase!
        .simpleQueryData('hycop_users', name: 'email', value: email, orderBy: 'email')
        .catchError((error, stackTrace) =>
            throw HycopUtils.getHycopException(error: error, defaultMessage: 'not exist account(email:$email) !!!'));
    if (getUserDataList.isEmpty) {
      logger.finest('not exist account(email:$email) !!!');
      return AccountSignUpType.none;
    }
    logger.finest('exist account(email:$email)');
    final getUserData = getUserDataList[0]; // exist only-one
    final userModel = UserModel(userData: getUserData);
    return userModel.accountSignUpType;
  }


  @override
  Future<void> getAccountInfo(String userId, Map<String, dynamic> userData) async {
    logger.finest('getAccountInfo($userId)');
    final resultUserData = await HycopFactory.dataBase!
        //.getData('hycop_users', 'user=$userId')
        .simpleQueryData('hycop_users', name: 'userId', value: userId, orderBy: 'userId')
        .catchError((error, stackTrace) =>
            throw HycopUtils.getHycopException(error: error, defaultMessage: 'getData failed !!!'));
    if (resultUserData.isEmpty) {
      logger.severe('getData error !!!');
      throw HycopUtils.getHycopException(defaultMessage: 'getData failed !!!');
    }
    for (var result in resultUserData) {
      if (result['isRemoved'] == true) {
        logger.severe('removed user !!!');
        throw HycopUtils.getHycopException(defaultMessage: 'removed user !!!');
      }
      userData.addAll(result);
      break;
    }
    logger.finest('getAccountInfo success ($userData)');
  }


  @override
  Future<void> updateAccountInfo(Map<String, dynamic> updateUserData) async {
    logger.finest('updateAccount($updateUserData)');
    String userForeignKey = updateUserData['userForeignKey'] ?? '';
    if (userForeignKey.isEmpty) {
      throw HycopUtils.getHycopException(defaultMessage: 'userForeignKey is null !!!');
    }
    await HycopFactory.dataBase!.setData('hycop_users', 'user=$userForeignKey', updateUserData).catchError(
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
    Map<String, dynamic> newUserData = {};
    newUserData.addAll(AccountManager.currentLoginUser.getValueMap);
    newUserData['password'] = HycopUtils.stringToSha1(newPassword);
    String userForeignKey = newUserData['userForeignKey'] ?? '';
    if (userForeignKey.isEmpty) {
      throw HycopUtils.getHycopException(defaultMessage: 'userForeignKey is null !!!');
    }
    // set to appwrite-account
    Account account = Account(AbsDatabase.awDBConn!);
    await account.updatePassword(password: newPassword, oldPassword: oldPassword).catchError((error, stackTrace) =>
        throw HycopUtils.getHycopException(error: error, defaultMessage: 'Unknown DB Error !!!'));
    // set to hycop_users collection
    await HycopFactory.dataBase!.setData('hycop_users', 'user=$userForeignKey', newUserData).catchError(
        (error, stackTrace) => throw HycopUtils.getHycopException(error: error, defaultMessage: 'setData Error !!!'));
  }


  @override
  Future<void> deleteAccount() async {
    logger.finest('deleteAccount(${AccountManager.currentLoginUser.email})');
    //
    Map<String, dynamic> newUserData = {};
    newUserData.addAll(AccountManager.currentLoginUser.getValueMap);
    String userForeignKey = newUserData['userForeignKey'] ?? '';
    if (userForeignKey.isEmpty) {
      throw HycopUtils.getHycopException(defaultMessage: 'userForeignKey is null !!!');
    }
    newUserData['isRemoved'] = true;
    await HycopFactory.dataBase!.setData('hycop_users', 'user=$userForeignKey', newUserData).catchError(
        (error, stackTrace) => throw HycopUtils.getHycopException(error: error, defaultMessage: 'setData Error !!!'));
  }

  @override
  Future<void> deleteAccountByUser(Map<String, dynamic> newUserData) async {
    logger.finest('deleteAccountByUser()');
    //
     String userForeignKey = newUserData['userForeignKey'] ?? '';
    if (userForeignKey.isEmpty) {
      throw HycopUtils.getHycopException(defaultMessage: 'userForeignKey is null !!!');
    }
    newUserData['isRemoved'] = true;
    await HycopFactory.dataBase!
        .setData('hycop_users', 'user=$userForeignKey', newUserData)
        .catchError((error, stackTrace) =>
            throw HycopUtils.getHycopException(error: error, defaultMessage: 'setData Error !!!'));
  }



  @override
  Future<void> login(String email, String password,
      {Map<String, dynamic>? returnUserData, AccountSignUpType accountSignUpType = AccountSignUpType.hycop}) async {
    logger.finest('loginByEmail($email, $password)');
    //
    Account account = Account(AbsDatabase.awDBConn!);
    final result = await account.createEmailSession(email: email, password: password).catchError((error, stackTrace) =>
        throw HycopUtils.getHycopException(error: error, defaultMessage: 'createEmailSession failed !!!'));
    if (result.userId.isEmpty) {
      logger.severe('createEmailSession failed !!!');
      throw HycopUtils.getHycopException(defaultMessage: 'createEmailSession failed !!!');
    } else {
      if (returnUserData == null) {
        logger.finest('login(email:$email, password:$password) without getData is success');
        return;
      }
      final userObject = await account.get().catchError((error, stackTrace) =>
          throw HycopUtils.getHycopException(error: error, defaultMessage: 'User.get failed !!!'));
      final resultUserData = await HycopFactory.dataBase!.getData('hycop_users', 'user=${userObject.name}').catchError(
          (error, stackTrace) =>
              throw HycopUtils.getHycopException(error: error, defaultMessage: 'getData failed !!!'));
      if (resultUserData.isEmpty) {
        logger.severe('getData error !!!');
        throw HycopUtils.getHycopException(defaultMessage: 'getData failed !!!');
      }
      final type = AccountSignUpType.fromInt(int.parse(resultUserData['accountSignUpType'].toString()));
      if (type != accountSignUpType) {
        logger.severe('not [${accountSignUpType.name}] sign-up user !!!');
        throw HycopUtils.getHycopException(defaultMessage: 'not [${accountSignUpType.name}] sign-up user !!!');
      }

      if (resultUserData['isRemoved'] == true) {
        logger.severe('removed user !!!');
        throw HycopUtils.getHycopException(defaultMessage: 'removed user !!!');
      }
      returnUserData.addAll(resultUserData);
      logger.finest('loginByEmail success ($resultUserData)');
    }
  }


  @override
  Future<void> logout() async {
    logger.finest('logout');
    Account account = Account(AbsDatabase.awDBConn!);
    //Future result =
    await account.deleteSession(sessionId: 'current').catchError((error, stackTrace) =>
        throw HycopUtils.getHycopException(error: error, defaultMessage: 'deleteSession failed !!!'));
  }


  @override
  Future<(String, String)> resetPassword(String email) async {
    logger.finest('resetPassword($email)');
    final getUserDataList = await HycopFactory.dataBase!
        .simpleQueryData('hycop_users', name: 'email', value: email, orderBy: 'name')
        .catchError((error, stackTrace) =>
            throw HycopUtils.getHycopException(error: error, defaultMessage: 'not exist account(email:$email) !!!'));
    if (getUserDataList.isEmpty) {
      logger.severe('getData error !!!');
      throw const HycopException(message: 'getData failed !!!');
    }
    final getUserData = getUserDataList[0]; // exist only-one
    final userModel = UserModel(userData: getUserData);
    if (userModel.accountSignUpType != AccountSignUpType.hycop) {
      // not hycop-user-account ==> return empty-string
      return ('', '');
    }
    Account account = Account(AbsDatabase.awDBConn!);
    await account.createRecovery(email: email, url: 'http://localhost/#/resetPasswordConfirm').catchError(
        (error, stackTrace) =>
            throw HycopUtils.getHycopException(error: error, defaultMessage: 'createRecovery failed !!!'));
    return (email, '');
  }


  @override
  Future<void> resetPasswordConfirm(String userId, String secret, String newPassword) async {
    logger.finest('resetPassword(userId:$userId, secret:$secret, newPassword:$newPassword)');
    Account account = Account(AbsDatabase.awDBConn!);
    await account
        .updateRecovery(userId: userId, secret: secret, password: newPassword, passwordAgain: newPassword)
        .catchError((error, stackTrace) =>
            throw HycopUtils.getHycopException(error: error, defaultMessage: 'createRecovery failed !!!'));
  }
}
