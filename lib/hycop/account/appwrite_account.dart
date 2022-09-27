// ignore: depend_on_referenced_packages
import 'package:appwrite/appwrite.dart';
//import '../../hycop/utils/hycop_exceptions.dart';
// ignore: depend_on_referenced_packages
import 'package:uuid/uuid.dart';
//import '../../model/abs_ex_model.dart';
import '../../common/util/logger.dart';
import 'abs_account.dart';
import '../database/abs_database.dart';
import '../hycop_factory.dart';
import '../utils/hycop_utils.dart';
import 'account_manager.dart';
import '../enum/model_enums.dart'; // AccountSignUpType 사용

class AppwriteAccount extends AbsAccount {
  // @override
  // Future<void> initialize() async {
  //   return Future.value();
  // }

  @override
  Future<void> createAccount(Map<String, dynamic> createUserData) async {
    logger.finest('createAccount($createUserData)');
    // accountSignUpType
    var accountSignUpType = AccountSignUpType.creta;
    if (createUserData['accountSignUpType'] == null) {
      createUserData['accountSignUpType'] = accountSignUpType.index;
    } else {
      accountSignUpType =
          AccountSignUpType.fromInt(int.parse(createUserData['accountSignUpType'].toString()));
      if (accountSignUpType == AccountSignUpType.none) {
        logger.severe('invalid sign-up type !!!');
        throw HycopUtils.getHycopException(defaultMessage: 'invalid sign-up type !!!');
      }
    }
    // userId
    String userId = createUserData['userId'] ?? '';
    if (userId.isEmpty) {
      // not exist userId ==> create new one
      userId = const Uuid().v4().replaceAll('-', '');
      createUserData['userId'] = userId;
    }
    // email
    String email = createUserData['email'] ?? '';
    if (email.isEmpty) {
      logger.severe('email is empty !!!');
      throw HycopUtils.getHycopException(defaultMessage: 'email is empty !!!');
    }
    // password
    String password = createUserData['password'] ?? '';
    if (password.isEmpty && accountSignUpType == AccountSignUpType.creta) {
      // creta need password !!!
      logger.severe('password is empty !!!');
      throw HycopUtils.getHycopException(defaultMessage: 'password is empty !!!');
    }
    String passwordSha1 = '';
    if (accountSignUpType == AccountSignUpType.creta) {
      // creta service password = sha1-hash of password
      passwordSha1 = HycopUtils.stringToSha1(password);
      logger
          .finest('password resetting to [$password] (creta service - [${accountSignUpType.name}]');
    } else {
      // accountSignUpType != AccountSignUpType.creta ==>
      // external service password = sha1-hash of email
      passwordSha1 = HycopUtils.stringToSha1(email); //sha1.convert(bytes).toString();
      password = passwordSha1;
      logger.finest(
          'password resetting to [$password] (external service - [${accountSignUpType.name}]');
    }
    createUserData['password'] = passwordSha1;

    String userForeignKey = const Uuid().v4().replaceAll('-', '');
    logger.finest(
        'createAccount(userId:$userId, email:$email, password:$password, name:$userForeignKey)');
    createUserData['userForeignKey'] = userForeignKey;

    Account account = Account(AbsDatabase.awDBConn!);
    final accountCreateResult = await account
        .create(userId: userId, email: email, password: password, name: userForeignKey)
        .catchError((error, stackTrace) => throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'Unknown DB Error !!!'));
    if (accountCreateResult.email.isEmpty) {
      logger.severe('account.create error !!!');
      throw HycopUtils.getHycopException(defaultMessage: 'account.create error !!!');
    }

    await login(email, password, accountSignUpType: accountSignUpType).catchError((error,
            stackTrace) =>
        throw HycopUtils.getHycopException(error: error, defaultMessage: 'loginByEmail Error !!!'));

    logger.fine("[===========================");

    await HycopFactory.dataBase!
        .createData('hycop_users', 'user=$userForeignKey', createUserData)
        .catchError((error, stackTrace) => throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'createData Error !!!'));

    logger.fine("===========================]");

    // final getUserData = await HycopFactory.dataBase!.getData('hycop_users', 'user=$userForeignKey').catchError(
    //     (error, stackTrace) => throw HycopUtils.getHycopException(error: error, defaultMessage: 'No User Data !!!'));
    // if (getUserData.isEmpty) {
    //   logger.severe('No User Data !!!');
    //   throw HycopUtils.getHycopException(defaultMessage: 'No User Data !!!');
    // }
    logger.finest(
        'createAccount(userId:$userId, email:$email, password:$password, name:$userForeignKey) success');
  }

  @override
  Future<bool> isExistAccount(String email) async {
    //final getUserData =
    await HycopFactory.dataBase!
        .simpleQueryData('hycop_users', name: 'email', value: email, orderBy: 'email')
        .catchError((error, stackTrace) => throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'not exist account(email:$email) !!!'))
        .then((value) {
      if (value.isEmpty) {
        logger.finest('not exist account(email:$email) !!!');
        //throw HycopUtils.getHycopException(defaultMessage: 'not exist account(email:$email) !!!');
        return Future.value(false); //false;
      } else {
        logger.finest('exist account(email:$email)');
        return Future.value(true); //true;
      }
    });
    logger.finest('unknown error !!!');
    return Future.value(false); //false;
  }

  @override
  Future<void> updateAccountInfo(Map<String, dynamic> updateUserData) async {
    logger.finest('updateAccount($updateUserData)');
    // Account account = Account(AbsDatabase.awDBConn!);
    // String password = updateUserData['password'] ?? '';
    // if (password.isNotEmpty) {
    //   await account.updatePassword(password: password, oldPassword: '1234qwer').catchError((error, stackTrace) =>
    //       throw HycopUtils.getHycopException(error: error, defaultMessage: 'Unknown DB Error !!!'));
    // }

    // final userObject = await account.get().catchError(
    //     (error, stackTrace) => throw HycopUtils.getHycopException(error: error, defaultMessage: 'User.get failed !!!'));
    String userForeignKey = updateUserData['userForeignKey'] ?? '';
    if (userForeignKey.isEmpty) {
      throw HycopUtils.getHycopException(defaultMessage: 'userForeignKey is null !!!');
    }
    await HycopFactory.dataBase!
        .setData('hycop_users', 'user=$userForeignKey', updateUserData)
        .catchError((error, stackTrace) =>
            throw HycopUtils.getHycopException(error: error, defaultMessage: 'setData Error !!!'));
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
    await account.updatePassword(password: newPassword, oldPassword: oldPassword).catchError((error,
            stackTrace) =>
        throw HycopUtils.getHycopException(error: error, defaultMessage: 'Unknown DB Error !!!'));
    // set to hycop_users collection
    await HycopFactory.dataBase!
        .setData('hycop_users', 'user=$userForeignKey', newUserData)
        .catchError((error, stackTrace) =>
            throw HycopUtils.getHycopException(error: error, defaultMessage: 'setData Error !!!'));
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
    await HycopFactory.dataBase!
        .setData('hycop_users', 'user=$userForeignKey', newUserData)
        .catchError((error, stackTrace) =>
            throw HycopUtils.getHycopException(error: error, defaultMessage: 'setData Error !!!'));
  }

  @override
  Future<void> login(String email, String password,
      {Map<String, dynamic>? returnUserData,
      AccountSignUpType accountSignUpType = AccountSignUpType.creta}) async {
    logger.finest('loginByEmail($email, $password)');
    //
    Account account = Account(AbsDatabase.awDBConn!);
    final result = await account.createEmailSession(email: email, password: password).catchError(
        (error, stackTrace) => throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'createEmailSession failed !!!'));
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
      final resultUserData = await HycopFactory.dataBase!
          .getData('hycop_users', 'user=${userObject.name}')
          .catchError((error, stackTrace) => throw HycopUtils.getHycopException(
              error: error, defaultMessage: 'getData failed !!!'));
      if (resultUserData.isEmpty) {
        logger.severe('getData error !!!');
        throw HycopUtils.getHycopException(defaultMessage: 'getData failed !!!');
      }
      final type =
          AccountSignUpType.fromInt(int.parse(resultUserData['accountSignUpType'].toString()));
      if (type != accountSignUpType) {
        logger.severe('not [${accountSignUpType.name}] sign-up user !!!');
        throw HycopUtils.getHycopException(
            defaultMessage: 'not [${accountSignUpType.name}] sign-up user !!!');
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
    account.deleteSession(sessionId: 'current').catchError((error, stackTrace) =>
        throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'deleteSession failed !!!'));
  }

  @override
  Future<void> resetPassword(String email) async {
    logger.finest('resetPassword($email)');
    Account account = Account(AbsDatabase.awDBConn!);
    //Future result =
    account.createRecovery(email: email, url: 'http://localhost/#/resetPasswordConfirm').catchError(
        (error, stackTrace) => throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'createRecovery failed !!!'));
  }

  @override
  Future<void> resetPasswordConfirm(String userId, String secret, String newPassword) async {
    logger.finest('resetPassword(userId:$userId, secret:$secret, newPassword:$newPassword)');
    Account account = Account(AbsDatabase.awDBConn!);
    await account
        .updateRecovery(
            userId: userId, secret: secret, password: newPassword, passwordAgain: newPassword)
        .catchError((error, stackTrace) => throw HycopUtils.getHycopException(
            error: error, defaultMessage: 'createRecovery failed !!!'));
  }
}
