// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hycop/hycop/account/account_manager.dart';

import 'navigation/routes.dart';
import '../widgets/text_field.dart';
import 'package:routemaster/routemaster.dart';

import 'package:hycop/common/util/logger.dart';
// import 'package:hycop/hycop/model/user_model.dart';
//import 'package:hycop/common/util/exceptions.dart';
import 'package:hycop/hycop/utils/hycop_exceptions.dart';
import 'package:hycop/hycop/enum/model_enums.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: _RegisterForm(),
      ),
    );
  }
}

class _RegisterForm extends ConsumerStatefulWidget {
  const _RegisterForm({Key? key}) : super(key: key);

  @override
  ConsumerState<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameTextEditingController = TextEditingController();
  final _emailTextEditingController = TextEditingController();
  final _passwordTextEditingController = TextEditingController();

  String _errMsg = '';

  @override
  void dispose() {
    _nameTextEditingController.dispose();
    _emailTextEditingController.dispose();
    _passwordTextEditingController.dispose();
    super.dispose();
  }

  Future<void> createAccount() async {
    logger.finest('createAccount pressed');
    _errMsg = '';

    String name = _nameTextEditingController.text;
    String email = _emailTextEditingController.text;
    String password = _passwordTextEditingController.text;

    AccountManager.isExistAccount(email).then((value) {
      Map<String, dynamic> userData = {};
      userData['name'] = name;
      userData['email'] = email;
      userData['password'] = password;
      logger.finest('register start');
      AccountManager.createAccount(userData).then((value) {
        logger.finest('register end');
        Routemaster.of(context).push(AppRoutes.userinfo);
        logger.finest('goto user-info-page');
      }).onError((error, stackTrace) {
        if (error is HycopException) {
          HycopException ex = error;
          _errMsg = ex.message;
        } else {
          _errMsg = 'Unknown DB Error !!!';
        }
        showSnackBar(context, _errMsg);
        setState(() {});
      });
    }).onError((error, stackTrace) {
      if (error is HycopException) {
        HycopException ex = error;
        _errMsg = ex.message;
      } else {
        _errMsg = 'Unknown DB Error !!!';
      }
      showSnackBar(context, _errMsg);
      setState(() {});
    });
  }

  Future<void> createAccountByGoogle() async {
    logger.finest('createAccountByGoogle pressed');
    _errMsg = '';

    String name = _nameTextEditingController.text;
    String email = _emailTextEditingController.text;
    //String password = _passwordTextEditingController.text;

    await AccountManager.isExistAccount(email).catchError((error, stackTrace) {
      if (error is HycopException) {
        HycopException ex = error;
        _errMsg = ex.message;
      } else {
        _errMsg = 'Unknown DB Error !!!';
      }
      showSnackBar(context, _errMsg);
      setState(() {});
    }).then((value) {
      if (value == true) {
        _errMsg = 'Already exist user !!!';
        showSnackBar(context, _errMsg);
        setState(() {});
      }
    });

    //
    Map<String, dynamic> userData = {};
    userData['name'] = name;
    userData['email'] = email;
    userData['password'] = email;
    userData['accountSignUpType'] = AccountSignUpType.google.index;
    AccountManager.createAccount(userData).then((value) {
      Routemaster.of(context).push(AppRoutes.userinfo);
    }).onError((error, stackTrace) {
      if (error is HycopException) {
        HycopException ex = error;
        _errMsg = ex.message;
      } else {
        _errMsg = 'Unknown DB Error !!!';
      }
      showSnackBar(context, _errMsg);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints.loose(const Size.fromWidth(320)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child:
                      Text('Create an account 🚀', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Unlock the power of Flutter and Appwrite.',
                  ),
                ),
              ),
              OnlyTextField(hintText: 'name', controller: _nameTextEditingController),
              EmailTextField(controller: _emailTextEditingController),
              PasswordTextField(controller: _passwordTextEditingController),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: createAccount,
                  child: const Text('Create'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: createAccountByGoogle,
                  child: const Text('Sign-up by google'),
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
              Text.rich(
                TextSpan(
                  text: 'Already have an account? ',
                  children: [
                    TextSpan(
                      text: 'Sign in',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => Routemaster.of(context).push(AppRoutes.login),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
