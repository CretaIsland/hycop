// ignore_for_file: depend_on_referenced_packages

import '../widgets/glass_box.dart';
import '../widgets/widget_snippets.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';

import 'package:hycop/common/util/config.dart';
import 'package:hycop/common/util/logger.dart';
import 'package:hycop/common/util/util.dart';
import '../widgets/card_flip.dart';
import '../widgets/glowing_button.dart';
import '../widgets/glowing_image_button.dart';
import '../widgets/text_field.dart';
import 'package:hycop/hycop/hycop_factory.dart';
import 'navigation/routes.dart';

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
            firstPage: firstPage(),
            secondPage: secondPage(),
            flip: _isFlip,
          ),
        ),
      ),
    );
  }

  Widget firstPage() {
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
                  flip();
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
                  flip();
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

  void flip() {
    _initConnection();
    setState(() {
      _isFlip = !_isFlip;
    });
  }

  Widget secondPage() {
    return GlassBox(
      width: 600,
      height: 600,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HycopFactory.serverType == ServerType.appwrite
              ? WidgetSnippets.appwriteLogo()
              : WidgetSnippets.firebaseLogo(),
          Text(
            HycopFactory.enterprise,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 30,
            ),
          ),
          const Text(
            'Connection Infomation',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._props(),
            ],
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
                  setState(() {
                    _isFlip = !_isFlip;
                  });
                },
                text: 'Prev',
              ),
              const SizedBox(width: 20),
              GlowingButton(
                onPressed: () {
                  Routemaster.of(context).push(AppRoutes.login);
                },
                text: 'Next',
              ),
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

  List _props() {
    return propNameList.map((name) {
      return Padding(
        padding: const EdgeInsets.only(left: 40, right: 40),
        child: NameTextField(
          readOnly: true,
          hintText: propValueMap[name] ?? 'NULL',
          controller: _ctrlMap[name]!,
          fontSize: 20,
          name: name,
          inputSize: 300,
        ),
      );
    }).toList();
  }
}
