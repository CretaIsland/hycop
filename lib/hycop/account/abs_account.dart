// ignore_for_file: depend_on_referenced_packages

//import 'package:appwrite/appwrite.dart';
//import 'package:firebase_core/firebase_core.dart';
//import 'package:flutter/material.dart';
// import 'account_manager.dart'; // AccountSignUpType 사용
import '../enum/model_enums.dart'; // AccountSignUpType 사용


abstract class AbsAccount {

  //Future<void> initialize();

  Future<void> createAccount(Map<String, dynamic> createUserData);
  Future<bool> isExistAccount(String email);
  Future<void> updateAccountInfo(Map<String, dynamic> updateUserData);
  Future<void> updateAccountPassword(String newPassword, String oldPassword);
  Future<void> deleteAccount();

  Future<void> login(String email, String password, {Map<String, dynamic>? returnUserData, AccountSignUpType accountSignUpType=AccountSignUpType.creta});
  //Future<void> loginByExternalService(String email, Map<String, dynamic>? returnUserData);
  Future<void> logout();
  Future<void> resetPassword(String email);
  Future<void> resetPasswordConfirm(String userId, String secret, String newPassword);
}
