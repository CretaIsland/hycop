// ignore_for_file: depend_on_referenced_packages

// import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';

// import 'package:routemaster/routemaster.dart';
// import '../hycop/database/db_utils.dart';
// import 'navigation/routes.dart';
// import '../common/widgets/text_field.dart';
import 'package:hycop/common/util/logger.dart';
// import 'package:hycop/common/util/exceptions.dart';

import '../widgets/glowing_button.dart';
import 'package:hycop/hycop/utils/hycop_exceptions.dart';
import 'package:hycop/hycop/model/user_model.dart';
import 'package:hycop/hycop/account/account_manager.dart';
import 'navigation/routes.dart';

class UserInfoPage extends StatelessWidget {
  const UserInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: _UserInfoForm(),
      ),
    );
  }
}

class _UserInfoForm extends ConsumerStatefulWidget {
  const _UserInfoForm({Key? key}) : super(key: key);

  @override
  ConsumerState<_UserInfoForm> createState() => _UserInfoFormState();
}

class _UserInfoFormState extends ConsumerState<_UserInfoForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailTextEditingController = TextEditingController();
  final _passwordTextEditingController = TextEditingController();

  String _errMsg = '';

  @override
  void dispose() {
    _emailTextEditingController.dispose();
    _passwordTextEditingController.dispose();
    super.dispose();
  }

  Future<void> _updateUserInfo() async {
    Map<String, dynamic> updateUserInfo = {};

    //updateUserInfo['password'] = '5678tyui';
    updateUserInfo['name'] = 'name test';
    updateUserInfo['phone'] = 'phone test';
    updateUserInfo['imagefile'] = 'imagefile test';
    updateUserInfo['userType'] = 'userType test';

    AccountManager.updateAccountInfo(updateUserInfo).then((value) {
      //logger.finest('new account=${HycopUser.currentLoginUser.allUserData}');
      setState(() {});
    }).onError((error, stackTrace) {
      if (error is HycopException) {
        HycopException ex = error;
        _errMsg = ex.message;
      } else {
        _errMsg = 'Uknown DB Error !!!';
      }
      showSnackBar(context, _errMsg);
      setState(() {});
    });
  }

  Future<void> _updateUserPassword() async {
    // Map<String, dynamic> updateUserInfo = {};

    AccountManager.updateAccountPassword('5678tyui', '1234qwer').then((value) {
      //logger.finest('new account=${HycopUser.currentLoginUser.allUserData}');
      setState(() {});
    }).onError((error, stackTrace) {
      if (error is HycopException) {
        HycopException ex = error;
        _errMsg = ex.message;
      } else {
        _errMsg = 'Uknown DB Error !!!';
      }
      showSnackBar(context, _errMsg);
      setState(() {});
    });
  }

  Future<void> _logout() async {
    logger.finest('_logout start');
    AccountManager.logout().then((value) {
      //logger.finest('new account=${HycopUser.currentLoginUser.allUserData}');
      logger.finest('_logout end');
      setState(() {
        UserModel currentUserInfo = AccountManager.currentLoginUser;

        String accountSignUpType = currentUserInfo.accountSignUpType.name;
        logger.finest(accountSignUpType);
      });
      logger.finest('_logout setState');
    }).onError((error, stackTrace) {
      if (error is HycopException) {
        HycopException ex = error;
        _errMsg = ex.message;
      } else {
        _errMsg = 'Uknown DB Error !!!';
      }
      showSnackBar(context, _errMsg);
      setState(() {});
    });
  }

  Future<void> _deleteAccount() async {
    AccountManager.deleteAccount().then((value) {
      //logger.finest('new account=${HycopUser.currentLoginUser.allUserData}');
      setState(() {});
    }).onError((error, stackTrace) {
      if (error is HycopException) {
        HycopException ex = error;
        _errMsg = ex.message;
      } else {
        _errMsg = 'Uknown DB Error !!!';
      }
      showSnackBar(context, _errMsg);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    UserModel currentUserInfo = AccountManager.currentLoginUser;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ConstrainedBox(
        constraints: BoxConstraints.loose(const Size.fromWidth(500)),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('userId : ${currentUserInfo.userId}'),
              Text('email : ${currentUserInfo.email}'),
              Text('password : ${currentUserInfo.password}'),
              Text('name : ${currentUserInfo.name}'),
              Text('phone : ${currentUserInfo.phone}'),
              Text('imagefile : ${currentUserInfo.imagefile}'),
              Text('userType : ${currentUserInfo.userType}'),
              Text('accountSignUpType : ${currentUserInfo.accountSignUpType.name}'),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: _updateUserInfo,
                  child: const Text('update user info'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: _updateUserPassword,
                  child: const Text('update user password'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: _logout,
                  child: const Text('logout'),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: _deleteAccount,
                  child: const Text('delete account'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GlowingButton(
                  onPressed: () {
                    Routemaster.of(context).push(AppRoutes.main);
                  },
                  text: 'Next',
                ),
              ),
              _errMsg.isNotEmpty
                  ? Text(
                      _errMsg,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                    )
                  : const SizedBox(
                      height: 10,
                    ),

              // const Align(
              //   alignment: Alignment.centerLeft,
              //   child: Padding(
              //     padding: EdgeInsets.symmetric(vertical: 8.0),
              //     child: Text('Welcome to Creta ! 👋🏻',
              //         style: TextStyle(fontWeight: FontWeight.bold)),
              //   ),
              // ),
              // const Align(
              //   alignment: Alignment.centerLeft,
              //   child: Padding(
              //     padding: EdgeInsets.symmetric(vertical: 8.0),
              //     child: Text(
              //       'Creta Creates ✍️',
              //     ),
              //   ),
              // ),
              // EmailTextField(controller: _emailTextEditingController),
              // PasswordTextField(controller: _passwordTextEditingController),
              // Padding(
              //   padding: const EdgeInsets.all(8.0),
              //   child: ElevatedButton(
              //     onPressed: _signIn,
              //     child: const Text('Sign in'),
              //   ),
              // ),
              // _errMsg.isNotEmpty
              //     ? Text(
              //         _errMsg,
              //         style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              //       )
              //     : const SizedBox(
              //         height: 10,
              //       ),
              // Text.rich(
              //   TextSpan(
              //     text: 'Don\'t have an account? ',
              //     children: [
              //       TextSpan(
              //         text: 'Join now',
              //         style: const TextStyle(fontWeight: FontWeight.w600),
              //         recognizer: TapGestureRecognizer()
              //           ..onTap = () => Routemaster.of(context).push(AppRoutes.register),
              //       )
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
