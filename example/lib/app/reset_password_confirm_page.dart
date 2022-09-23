// ignore_for_file: depend_on_referenced_packages

// import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hycop/hycop/account/account_manager.dart';
// import 'package:routemaster/routemaster.dart';
// import '../hycop/database/db_utils.dart';
// import 'navigation/routes.dart';
import '../widgets/text_field.dart';
import 'package:hycop/common/util/logger.dart';
import 'package:hycop/hycop/utils/hycop_exceptions.dart';

// import 'package:hycop/hycop/model/user_model.dart';

class ResetPasswordConfirmPage extends StatelessWidget {
  const ResetPasswordConfirmPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: _ResetPasswordConfirmForm(),
      ),
    );
  }
}

class _ResetPasswordConfirmForm extends ConsumerStatefulWidget {
  const _ResetPasswordConfirmForm({Key? key}) : super(key: key);

  @override
  ConsumerState<_ResetPasswordConfirmForm> createState() => _ResetPasswordConfirmFormState();
}

class _ResetPasswordConfirmFormState extends ConsumerState<_ResetPasswordConfirmForm> {
  final _formKey = GlobalKey<FormState>();
  final _userIdTextEditingController = TextEditingController();
  final _secretTextEditingController = TextEditingController();
  final _passwordTextEditingController = TextEditingController();

  String _errMsg = '';

  @override
  void dispose() {
    _userIdTextEditingController.dispose();
    _secretTextEditingController.dispose();
    _passwordTextEditingController.dispose();
    super.dispose();
  }

  Future<void> _resetPasswordConfirm() async {
    String userId = _userIdTextEditingController.text;
    String secret = _secretTextEditingController.text;
    String password = _passwordTextEditingController.text;

    AccountManager.resetPasswordConfirm(userId, secret, password).then((value) {
      _errMsg = 'password reseted sucessfully, go to login';
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
    // HycopUser currentUserInfo = HycopUser.currentLoginUser;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ConstrainedBox(
        constraints: BoxConstraints.loose(const Size.fromWidth(320)),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _userIdTextEditingController,
                decoration: const InputDecoration(hintText: 'Secret'),
              ),
              TextFormField(
                controller: _secretTextEditingController,
                decoration: const InputDecoration(hintText: 'Secret'),
              ),
              PasswordTextField(controller: _passwordTextEditingController),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: _resetPasswordConfirm,
                  child: const Text('Sign in'),
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
            ],
          ),
        ),
      ),
    );
  }
}
