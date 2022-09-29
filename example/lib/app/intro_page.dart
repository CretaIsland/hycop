// ignore_for_file: depend_on_referenced_packages

import '../widgets/glass_box.dart';
import '../widgets/widget_snippets.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';
import 'package:flutter/gestures.dart';

import 'package:hycop/common/util/config.dart';
import 'package:hycop/common/util/logger.dart';
import 'package:hycop/common/util/util.dart';
import '../widgets/card_flip.dart';
import '../widgets/glowing_button.dart';
import '../widgets/glowing_image_button.dart';
import '../widgets/text_field.dart';
import 'package:hycop/hycop/hycop_factory.dart';
import 'navigation/routes.dart';
import 'package:hycop/hycop/account/account_manager.dart';
import 'package:hycop/hycop/utils/hycop_exceptions.dart';
import 'package:hycop/hycop/enum/model_enums.dart';


enum IntroPageType {
  none,
  dbSelect,
  login,
  signup,
  resetPassword,
  resetPasswordConfirm,
  end;

  static int validCheck(int val) {
    if (val >= end.index) return (end.index - 1);
    if (val <= none.index) return (none.index + 1);
    return val;
  }
  static IntroPageType fromInt(int val) => IntroPageType.values[validCheck(val)];
}


class IntroPage extends StatefulWidget {
  const IntroPage({Key? key}) : super(key: key);

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  //ServerType _serverType = ServerType.firebase;
  //String _enterpriseId = '';
  final TextEditingController _enterpriseCtrl = TextEditingController();
  final TextEditingController _apiKeyCtrl = TextEditingController();
  final TextEditingController _authDomainCtrl = TextEditingController();
  final TextEditingController _databaseURLCtrl = TextEditingController();
  final TextEditingController _projectIdCtrl = TextEditingController();
  final TextEditingController _storageBucketCtrl = TextEditingController();
  final TextEditingController _messagingSenderIdCtrl = TextEditingController();
  final TextEditingController _appIdCtrl = TextEditingController();

  final Map<String, TextEditingController> _ctrlMap = {};
  final List<String> propNameList = [
    'apiKey',
    'authDomain',
    'databaseURL',
    'projectId',
    'storageBucket',
    'messagingSenderId',
    'appId',
  ];
  final Map<String, String> propValueMap = {};

  bool _isFlip = false;

  IntroPageType _pageIndex = IntroPageType.dbSelect;
  String _errMsg = '';

  final _loginEmailTextEditingController = TextEditingController();
  final _loginPasswordTextEditingController = TextEditingController();

  final _signinNameTextEditingController = TextEditingController();
  final _signinEmailTextEditingController = TextEditingController();
  final _signinPasswordTextEditingController = TextEditingController();

  final _resetPasswordEmailTextEditingController = TextEditingController();

  final _resetPasswordConfirmEmailTextEditingController = TextEditingController();
  final _resetPasswordConfirmSecretTextEditingController = TextEditingController();
  final _resetPasswordConfirmNewPasswordTextEditingController = TextEditingController();

  @override
  void dispose() {
    _enterpriseCtrl.dispose();
    _apiKeyCtrl.dispose();
    _authDomainCtrl.dispose();
    _databaseURLCtrl.dispose();
    _projectIdCtrl.dispose();
    _storageBucketCtrl.dispose();
    _messagingSenderIdCtrl.dispose();
    _appIdCtrl.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _ctrlMap[propNameList[0]] = _apiKeyCtrl;
    _ctrlMap[propNameList[1]] = _authDomainCtrl;
    _ctrlMap[propNameList[2]] = _databaseURLCtrl;
    _ctrlMap[propNameList[3]] = _projectIdCtrl;
    _ctrlMap[propNameList[4]] = _storageBucketCtrl;
    _ctrlMap[propNameList[5]] = _messagingSenderIdCtrl;
    _ctrlMap[propNameList[6]] = _appIdCtrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            image: DecorationImage(
          image: AssetImage('hycop_intro.jpg'),
          fit: BoxFit.cover,
        )),
        child: Center(
          child: TwinCardFlip(
            firstPage: cardPage(),
            secondPage: cardPage(),
            flip: _isFlip,
          ),
        ),
      ),
    );
  }

  Widget cardPage() {
    switch (_pageIndex) {
      case IntroPageType.login:
        return loginPage();

    case IntroPageType.signup:
      return signupPage();

      case IntroPageType.resetPassword:
        return resetPasswordPage();////////////////////////

    case IntroPageType.resetPasswordConfirm:
      return resetPasswordConfirmPage();///////////////////////////

      case IntroPageType.dbSelect:
      default:
        return dbSelectPage();
    }
  }

  Widget dbSelectPage() {
    return GlassBox(
      width: 600,
      height: 600,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          WidgetSnippets.shimmerText(
            duration: 6000,
            bgColor: Colors.white,
            fgColor: Colors.deepPurple,
            child: const Text(
              'Choose your PAS Server',
              style: TextStyle(
                //color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 30,
              ),
            ),
          ),
          const SizedBox(
            height: 50,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GlowingImageButton(
                width: 200,
                height: 200,
                assetPath: 'assets/firebase_logo.png',
                onPressed: () {
                  //setState(() {
                  HycopFactory.serverType = ServerType.firebase;
                  flip(IntroPageType.login);
                  //});
                },
              ),
              GlowingImageButton(
                width: 200,
                height: 200,
                assetPath: 'assets/appwrite_logo.png',
                onPressed: () {
                  //setState(() {
                  HycopFactory.serverType = ServerType.appwrite;
                  flip(IntroPageType.login);
                  //});
                },
              ),
              // RadioListTile(
              //     title: Text(
              //       "On Cloud Server(Firebase)",
              //       style: TextStyle(
              //         fontWeight: HycopFactory.serverType == ServerType.firebase
              //             ? FontWeight.bold
              //             : FontWeight.w600,
              //         fontSize: HycopFactory.serverType == ServerType.firebase ? 28 : 20,
              //       ),
              //     ),
              //     value: ServerType.firebase,
              //     groupValue: HycopFactory.serverType,
              //     onChanged: (value) {
              //       setState(() {
              //         HycopFactory.serverType = value as ServerType;
              //       });
              //     }),
              // RadioListTile(
              //     title: Text(
              //       "On Premiss Server(Appwrite)",
              //       style: TextStyle(
              //         fontWeight: HycopFactory.serverType == ServerType.appwrite
              //             ? FontWeight.bold
              //             : FontWeight.w600,
              //         fontSize: HycopFactory.serverType == ServerType.appwrite ? 28 : 20,
              //       ),
              //     ),
              //     value: ServerType.appwrite,
              //     groupValue: HycopFactory.serverType,
              //     onChanged: (value) {
              //       setState(() {
              //         HycopFactory.serverType = value as ServerType;
              //       });
              //     }),
            ],
          ),
          // const SizedBox(
          //   height: 40,
          // ),
          // const Text(
          //   'Enterprise ID',
          //   style: TextStyle(
          //     color: Colors.white,
          //     fontWeight: FontWeight.bold,
          //     fontSize: 30,
          //   ),
          // ),
          // const SizedBox(
          //   height: 20,
          // ),
          // SizedBox(
          //   width: 400,
          //   child: OnlyTextField(
          //     controller: _enterpriseCtrl,
          //     hintText: "Demo",
          //     readOnly: true,
          //   ),
          // ),
          // const SizedBox(
          //   height: 50,
          // ),
          // GlowingButton(
          //   onPressed: () {
          //     _initConnection();
          //     setState(() {
          //       _isFlip = !_isFlip;
          //     });
          //   },
          //   text: 'Next',
          // ),
        ],
      ),
    );
  }

  void flip(IntroPageType moveToPage) {
    _initConnection();
    setState(() {
      _errMsg = '';
      _pageIndex = IntroPageType.fromInt(moveToPage.index);
      _isFlip = !_isFlip;
    });
  }

  Future<void> _login() async {
    logger.finest('_login pressed');
    _errMsg = '';

    String email = _loginEmailTextEditingController.text;
    String password = _loginPasswordTextEditingController.text;

    AccountManager.login(email, password).then((value) {
      HycopFactory.setBucketId();
      Routemaster.of(context).push(AppRoutes.userinfo);
    }).onError((error, stackTrace) {
      if (error is HycopException) {
        HycopException ex = error;
        _errMsg = ex.message;
      } else {
        _errMsg = 'Uknown DB Error !!!';
      }
      logger.severe(_errMsg);
      showSnackBar(context, _errMsg);
      setState(() {});
    });
  }

  Future<void> _loginByGoogle() async {
    logger.finest('_loginByGoogle pressed');
    _errMsg = '';

    String email = _signinEmailTextEditingController.text;
    // String password = _passwordTextEditingController.text;

    AccountManager.loginByService(email, AccountSignUpType.google).then((value) {
      Routemaster.of(context).push(AppRoutes.userinfo);
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

  Future<void> _signup() async {
    logger.finest('_signup pressed');
    _errMsg = '';

    String name = _signinNameTextEditingController.text;
    String email = _signinEmailTextEditingController.text;
    String password = _signinPasswordTextEditingController.text;

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

  Future<void> _signupByGoogle() async {
    logger.finest('createAccountByGoogle pressed');
    _errMsg = '';

    String name = _signinNameTextEditingController.text;
    String email = _signinEmailTextEditingController.text;
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

  Future<void> _resetPassword() async {
    logger.finest('_resetPassword pressed');
    _errMsg = '';

    String email = _resetPasswordEmailTextEditingController.text;
    if (email.isEmpty) {
      _errMsg = 'email is empty !!!';
      showSnackBar(context, _errMsg);
      setState(() {});
      return;
    }

    AccountManager.resetPassword(email).then((value) {
      _errMsg = 'send a password recovery email to your account, check it';
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

  Future<void> _resetPasswordConfirm() async {
    String email = _resetPasswordConfirmEmailTextEditingController.text;
    String secret = _resetPasswordConfirmSecretTextEditingController.text;
    String newPassword = _resetPasswordConfirmNewPasswordTextEditingController.text;

    AccountManager.resetPasswordConfirm(email, secret, newPassword).then((value) {
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

  Widget loginPage() {
    return GlassBox(
      width: 600,
      height: 600,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('Welcome to HyCop ! 👋🏻', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(150.0, 0.0, 150.0, 0.0),
            child: EmailTextField(controller: _loginEmailTextEditingController),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(150.0, 0.0, 150.0, 0.0),
            child: PasswordTextField(controller: _loginPasswordTextEditingController),
          ),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: _login,
                child: const Text('Log in'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: _loginByGoogle,
                child: const Text('Log in by Google'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () => flip(IntroPageType.resetPassword),
                child: const Text('Reset Password'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () => flip(IntroPageType.resetPasswordConfirm),
                child: const Text('Reset Password Confirm'),
              ),
            ),
          ),
          _errMsg.isNotEmpty
              ? SizedBox(
                  height: 40,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _errMsg,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w800),
                      )
                    ],
                  ))
              : const SizedBox(
                  height: 40,
                ),
          Text.rich(
            TextSpan(
              text: 'Don\'t have an account? ',
              children: [
                TextSpan(
                  text: 'Sign up now !',
                  mouseCursor: SystemMouseCursors.click,
                  style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w800),
                  recognizer: TapGestureRecognizer()..onTap = () => Routemaster.of(context).push(AppRoutes.register),
                )
              ],
            ),
          ),
          const SizedBox(
            height: 40,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlowingButton(
                icon1: Icons.back_hand,
                icon2: Icons.back_hand_outlined,
                color1: Colors.amberAccent,
                color2: Colors.orangeAccent,
                onPressed: () {
                  //setState(() {
                  //   _isFlip = !_isFlip;
                      flip(IntroPageType.dbSelect);
                  // });
                },
                text: 'Prev',
              ),
              // const SizedBox(width: 20),
              // GlowingButton(
              //   onPressed: () {
              //     Routemaster.of(context).push(AppRoutes.login);
              //   },
              //   text: 'Next',
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget signupPage() {
    return GlassBox(
      width: 600,
      height: 600,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('Create an account 🚀', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(150.0, 0.0, 150.0, 0.0),
            child: SimpleNameTextField(controller: _signinNameTextEditingController),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(150.0, 0.0, 150.0, 0.0),
            child: EmailTextField(controller: _signinEmailTextEditingController),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(150.0, 0.0, 150.0, 0.0),
            child: PasswordTextField(controller: _signinPasswordTextEditingController),
          ),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: _signup,
                child: const Text('Sign up'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: _signupByGoogle,
                child: const Text('Sign up by google'),
              ),
            ),
          ),
          _errMsg.isNotEmpty
              ? SizedBox(
              height: 40,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _errMsg,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w800),
                  )
                ],
              ))
              : const SizedBox(
            height: 40,
          ),
          Text.rich(
            TextSpan(
              text: 'Already have an account? ',
              children: [
                TextSpan(
                  text: 'Login in now !',
                  mouseCursor: SystemMouseCursors.click,
                  style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w800),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => Routemaster.of(context).push(AppRoutes.login),
                )
              ],
            ),
          ),
          const SizedBox(
            height: 40,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlowingButton(
                icon1: Icons.back_hand,
                icon2: Icons.back_hand_outlined,
                color1: Colors.amberAccent,
                color2: Colors.orangeAccent,
                onPressed: () {
                  //setState(() {
                  //   _isFlip = !_isFlip;
                  flip(IntroPageType.login);
                  // });
                },
                text: 'Prev',
              ),
              // const SizedBox(width: 20),
              // GlowingButton(
              //   onPressed: () {
              //     Routemaster.of(context).push(AppRoutes.login);
              //   },
              //   text: 'Next',
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget resetPasswordPage() {
    return GlassBox(
      width: 600,
      height: 600,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(150.0, 0.0, 150.0, 0.0),
            child: EmailTextField(controller: _resetPasswordEmailTextEditingController),
          ),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: _resetPassword,
                child: const Text('Reset Password'),
              ),
            ),
          ),
          _errMsg.isNotEmpty
              ? SizedBox(
              height: 40,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _errMsg,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w800),
                  )
                ],
              ))
              : const SizedBox(
            height: 40,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlowingButton(
                icon1: Icons.back_hand,
                icon2: Icons.back_hand_outlined,
                color1: Colors.amberAccent,
                color2: Colors.orangeAccent,
                onPressed: () {
                  //setState(() {
                  //   _isFlip = !_isFlip;
                  flip(IntroPageType.login);
                  // });
                },
                text: 'Prev',
              ),
              // const SizedBox(width: 20),
              // GlowingButton(
              //   onPressed: () {
              //     Routemaster.of(context).push(AppRoutes.login);
              //   },
              //   text: 'Next',
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget resetPasswordConfirmPage() {
    return GlassBox(
      width: 600,
      height: 600,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('Reset password Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(150.0, 0.0, 150.0, 0.0),
            child: EmailTextField(controller: _resetPasswordConfirmEmailTextEditingController),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(150.0, 0.0, 150.0, 0.0),
            child: TextFormField(controller: _resetPasswordConfirmSecretTextEditingController),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(150.0, 0.0, 150.0, 0.0),
            child: PasswordTextField(controller: _resetPasswordConfirmNewPasswordTextEditingController),
          ),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: _resetPasswordConfirm,
                child: const Text('Reset Password Confirm'),
              ),
            ),
          ),
          _errMsg.isNotEmpty
              ? SizedBox(
              height: 40,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _errMsg,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w800),
                  )
                ],
              ))
              : const SizedBox(
            height: 40,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlowingButton(
                icon1: Icons.back_hand,
                icon2: Icons.back_hand_outlined,
                color1: Colors.amberAccent,
                color2: Colors.orangeAccent,
                onPressed: () {
                  //setState(() {
                  //   _isFlip = !_isFlip;
                  flip(IntroPageType.dbSelect);
                  // });
                },
                text: 'Prev',
              ),
              // const SizedBox(width: 20),
              // GlowingButton(
              //   onPressed: () {
              //     Routemaster.of(context).push(AppRoutes.login);
              //   },
              //   text: 'Next',
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _initConnection() async {
    logger.finest('_initConnection');

    HycopFactory.enterprise = _enterpriseCtrl.text;
    if (HycopFactory.enterprise.isEmpty) {
      HycopFactory.enterprise = 'Demo';
    }

    HycopFactory.initAll(force: true);
    //myConfig = HycopConfig(enterprise: HycopFactory.enterprise, serverType: _serverType);
    // myConfig = HycopConfig();
    // HycopFactory.selectDatabase();
    // HycopFactory.selectRealTime();
    // HycopFactory.selectFunction();

    //_serverType = myConfig!.serverType;
    //_enterpriseId = myConfig!.enterprise;
    late DBConnInfo conn;
    //if (_serverType == ServerType.appwrite) {
    conn = myConfig!.serverConfig!.dbConnInfo;
    //} else {
    //  conn = myConfig!.serverConfig!.rtConnInfo;
    //}

    propValueMap[propNameList[0]] = CommonUtils.hideString(conn.apiKey, max: 24);
    propValueMap[propNameList[1]] = CommonUtils.hideString(conn.authDomain, max: 24);
    propValueMap[propNameList[2]] = CommonUtils.hideString(conn.databaseURL, max: 24);
    propValueMap[propNameList[3]] = CommonUtils.hideString(conn.projectId, max: 24);
    propValueMap[propNameList[4]] = CommonUtils.hideString(conn.storageBucket, max: 24);
    propValueMap[propNameList[5]] = CommonUtils.hideString(conn.messagingSenderId, max: 24);
    propValueMap[propNameList[6]] = CommonUtils.hideString(conn.appId, max: 24);
  }

  // List _props() {
  //   return propNameList.map((name) {
  //     return Padding(
  //       padding: const EdgeInsets.only(left: 40, right: 40),
  //       child: NameTextField(
  //         readOnly: true,
  //         hintText: propValueMap[name] ?? 'NULL',
  //         controller: _ctrlMap[name]!,
  //         fontSize: 20,
  //         name: name,
  //         inputSize: 300,
  //       ),
  //     );
  //   }).toList();
  // }
}
