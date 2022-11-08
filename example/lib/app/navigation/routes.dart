// ignore_for_file: depend_on_referenced_packages, equal_keys_in_map

//import 'package:flutter/material.dart';
import 'package:example/app/webrtc_example_page.dart';
import 'package:hycop/hycop.dart';
import 'package:routemaster/routemaster.dart';
import '../database_example_page.dart';
//import '../drawer_menu_page.dart';
import '../function_example_page.dart';
import '../intro_page.dart';
//import '../login_page.dart';
import '../realtime_example_page.dart';
//import '../register_page.dart';
import '../main_page.dart';
import '../socketio_example_page.dart';
import '../storage_example_page.dart';
import '../user_example_page.dart';
//import '../../common/util/logger.dart';
//import '../user_info_page.dart';
//import '../reset_password_confirm_page.dart';

abstract class AppRoutes {
  //static const String menu = '/menu';
  static const String main = '/main';
  static const String databaseExample = '/databaseExample';
  static const String realtimeExample = '/realTimeExample';
  static const String functionExample = '/functionExample';
  static const String storageExample = '/storageExample';
  static const String socketioExample = '/socketioExample';
  static const String userExample = '/userExample';
  static const String webrtcExample = '/webrtcExample';
  static const String studio = '/studio';
  static const String login = '/login';
  static const String intro = '/intro';
  static const String register = '/register';

  //static const String userinfo  = '/userinfo';
  //static const String resetPasswordConfirm = '/resetPasswordConfirm';
}

//final menuKey = GlobalKey<DrawerMenuPageState>();
//DrawerMenuPage menuWidget = DrawerMenuPage(key: menuKey);

final routesLoggedOut = RouteMap(
  onUnknownRoute: (_) => (AccountManager.currentLoginUser.isLoginedUser)
      ? const Redirect(AppRoutes.main)
      : const Redirect(AppRoutes.intro),
  routes: {
    // AppRoutes.login: (_) => const TransitionPage(
    //       child: LoginPage(),
    //       pushTransition: PageTransition.fadeUpwards,
    //     ),
    // AppRoutes.register: (_) => const TransitionPage(
    //       child: RegisterPage(),
    //       pushTransition: PageTransition.fadeUpwards,
    //     ),
    //AppRoutes.menu: (_) => TransitionPage(child: menuWidget),
    AppRoutes.main: (_) => (AccountManager.currentLoginUser.isLoginedUser)
        ? const TransitionPage(child: MainPage())
        : const Redirect(AppRoutes.intro),
    AppRoutes.databaseExample: (_) => const TransitionPage(child: DatabaseExamplePage()),
    AppRoutes.realtimeExample: (_) => const TransitionPage(child: RealTimeExamplePage()),
    AppRoutes.functionExample: (_) => const TransitionPage(child: FunctionExamplePage()),
    AppRoutes.storageExample: (_) => const TransitionPage(child: StorageExamplePage()),
    AppRoutes.socketioExample: (_) => const TransitionPage(child: SocketIOExamplePage()),
    AppRoutes.userExample: (_) => const TransitionPage(child: UserExamplePage()),
    AppRoutes.webrtcExample: (_) => const TransitionPage(child: WebRTCExamplePage()),
    AppRoutes.intro: (_) => (AccountManager.currentLoginUser.isLoginedUser)
        ? const Redirect(AppRoutes.main)
        : const TransitionPage(child: IntroPage()),
    //AppRoutes.userinfo: (_) => const TransitionPage(child: UserInfoPage()),
    //AppRoutes.resetPasswordConfirm: (_) => const TransitionPage(child: ResetPasswordConfirmPage()),
  },
);

final routesLoggedIn = RouteMap(
  onUnknownRoute: (_) => const Redirect(AppRoutes.main),
  routes: {
    //AppRoutes.menu: (_) => TransitionPage(child: menuWidget),
    AppRoutes.main: (_) => const TransitionPage(child: MainPage()),
  },
);
