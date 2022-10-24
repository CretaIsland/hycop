// ignore_for_file: depend_on_referenced_packages

//import 'package:example/widgets/text_field.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';
import '../widgets/widget_snippets.dart';
import 'drawer_menu_widget.dart';
import 'navigation/routes.dart';
import 'package:hycop/common/util/logger.dart';
import 'package:hycop/hycop/utils/hycop_exceptions.dart';
import 'package:hycop/hycop/account/account_manager.dart';
import 'package:hycop/hycop/model/user_model.dart';
import '../widgets/glowing_button.dart';
//import 'package:hycop/hycop/hycop_factory.dart';

class UserExamplePage extends StatefulWidget {
  final VoidCallback? openDrawer;

  const UserExamplePage({Key? key, this.openDrawer}) : super(key: key);

  @override
  State<UserExamplePage> createState() => _UserExamplePageState();
}

class _UserExamplePageState extends State<UserExamplePage> {
  final _userIdTextEditingController =
      TextEditingController(text: AccountManager.currentLoginUser.userId);
  final _emailTextEditingController =
      TextEditingController(text: AccountManager.currentLoginUser.email);
  final _passwordTextEditingController =
      TextEditingController(text: AccountManager.currentLoginUser.password);
  final _nameTextEditingController =
      TextEditingController(text: AccountManager.currentLoginUser.name);
  final _phoneTextEditingController =
      TextEditingController(text: AccountManager.currentLoginUser.phone);
  final _imagefileTextEditingController =
      TextEditingController(text: AccountManager.currentLoginUser.imagefile);
  final _userTypeTextEditingController =
      TextEditingController(text: AccountManager.currentLoginUser.userType);
  final _accountSignUpTypeTextEditingController =
      TextEditingController(text: AccountManager.currentLoginUser.accountSignUpType.name);

  final _oldPasswordTextEditingController = TextEditingController();
  final _newPasswordTextEditingController = TextEditingController();
  final _newPasswordConfirmTextEditingController = TextEditingController();

  String _errMsg = '';

  @override
  void initState() {
    super.initState();
  }

  Future<void> _updateUserInfo() async {
    Map<String, dynamic> updateUserInfo = {};

    updateUserInfo['name'] = _nameTextEditingController.text;
    updateUserInfo['phone'] = _phoneTextEditingController.text;
    updateUserInfo['imagefile'] = _imagefileTextEditingController.text;
    updateUserInfo['userType'] = _userTypeTextEditingController.text;

    AccountManager.updateAccountInfo(updateUserInfo).then((value) {
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
    String oldPassword = _oldPasswordTextEditingController.text;
    String newPassword = _newPasswordTextEditingController.text;
    String newPasswordConfirm = _newPasswordConfirmTextEditingController.text;

    if (newPassword != newPasswordConfirm) {
      _errMsg = 'New Password is different !!!';
      showSnackBar(context, _errMsg);
      setState(() {});
      return;
    }

    AccountManager.updateAccountPassword(newPassword, oldPassword).then((value) {
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
      Routemaster.of(context).push(AppRoutes.intro);
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
      //setState(() {});
      Routemaster.of(context).push(AppRoutes.intro);
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

  Widget _body() {
    UserModel currentUserInfo = AccountManager.currentLoginUser;

    _userIdTextEditingController.text = currentUserInfo.userId;
    _emailTextEditingController.text = currentUserInfo.email;
    _passwordTextEditingController.text = currentUserInfo.password;
    _nameTextEditingController.text = currentUserInfo.name;
    _phoneTextEditingController.text = currentUserInfo.phone;
    _imagefileTextEditingController.text = currentUserInfo.imagefile;
    _userTypeTextEditingController.text = currentUserInfo.userType;
    _accountSignUpTypeTextEditingController.text = currentUserInfo.accountSignUpType.name;

    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Center(
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                SizedBox(
                    width: 500.0,
                    height: 40.0,
                    child: TextField(
                      readOnly: true,
                      controller: _userIdTextEditingController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'UserId',
                      ),
                      style: const TextStyle(fontSize: 12.0),
                    )),
                const SizedBox(height: 10),
                SizedBox(
                    width: 500.0,
                    height: 40.0,
                    child: TextField(
                      readOnly: true,
                      controller: _emailTextEditingController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Email',
                      ),
                      style: const TextStyle(fontSize: 12.0),
                    )),
                const SizedBox(height: 10),
                SizedBox(
                    width: 500.0,
                    height: 40.0,
                    child: TextField(
                      readOnly: true,
                      controller: _passwordTextEditingController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Password',
                      ),
                      style: const TextStyle(fontSize: 12.0),
                    )),
                const SizedBox(height: 10),
                SizedBox(
                    width: 500.0,
                    height: 40.0,
                    child: TextField(
                      controller: _nameTextEditingController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Name',
                      ),
                      style: const TextStyle(fontSize: 12.0),
                    )),
                const SizedBox(height: 10),
                SizedBox(
                    width: 500.0,
                    height: 40.0,
                    child: TextField(
                      controller: _phoneTextEditingController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Phone',
                      ),
                      style: const TextStyle(fontSize: 12.0),
                    )),
                const SizedBox(height: 10),
                SizedBox(
                    width: 500.0,
                    height: 40.0,
                    child: TextField(
                      controller: _imagefileTextEditingController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Imagefile',
                      ),
                      style: const TextStyle(fontSize: 12.0),
                    )),
                const SizedBox(height: 10),
                SizedBox(
                    width: 500.0,
                    height: 40.0,
                    child: TextField(
                      controller: _userTypeTextEditingController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'UserType',
                      ),
                      style: const TextStyle(fontSize: 12.0),
                    )),
                const SizedBox(height: 10),
                SizedBox(
                    width: 500.0,
                    height: 40.0,
                    child: TextField(
                      readOnly: true,
                      controller: _accountSignUpTypeTextEditingController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'accountSignUpType',
                      ),
                      style: const TextStyle(fontSize: 12.0),
                    )),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: _updateUserInfo,
                    child: const Text('update user info'),
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
                SizedBox(
                    width: 500.0,
                    height: 40.0,
                    child: TextField(
                      controller: _oldPasswordTextEditingController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Old Password',
                      ),
                      style: const TextStyle(fontSize: 12.0),
                    )),
                const SizedBox(height: 10),
                SizedBox(
                    width: 500.0,
                    height: 40.0,
                    child: TextField(
                      controller: _newPasswordTextEditingController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'New Password',
                      ),
                      style: const TextStyle(fontSize: 12.0),
                    )),
                const SizedBox(height: 10),
                SizedBox(
                    width: 500.0,
                    height: 40.0,
                    child: TextField(
                      controller: _newPasswordConfirmTextEditingController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'New Password Confirm',
                      ),
                      style: const TextStyle(fontSize: 12.0),
                    )),
                const SizedBox(height: 10),
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
                    text: 'Prev',
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Future _future() async {
    await Future.delayed(const Duration(seconds: 1));
    return 'done';
  }

  @override
  Widget build(BuildContext context) {
    //Size screenSize = MediaQuery.of(context).size;

    return FutureBuilder(
        future: _future(), //HycopFactory.initAll(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasError) {
            //error가 발생하게 될 경우 반환하게 되는 부분
            logger.severe("data fetch error");
            return const Center(child: Text('data fetch error'));
          }
          if (snapshot.hasData == false) {
            logger.severe("No data founded(${AccountManager.currentLoginUser.email})");
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.connectionState == ConnectionState.done) {
            logger.severe("user data(${AccountManager.currentLoginUser.email})");
            return Scaffold(
              appBar: AppBar(
                actions: WidgetSnippets.hyAppBarActions(context),
                backgroundColor: Colors.orange,
                title: const Text('User Info Example'),
                leading: DrawerMenuWidget(onClicked: () {
                  if (widget.openDrawer != null) {
                    widget.openDrawer!();
                  } else {
                    Routemaster.of(context).push(AppRoutes.main);
                  }
                }),
              ),
              body: _body(),
            );
          }
          return Container();
        });
  }
}
