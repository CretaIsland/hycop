// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';

import '../widgets/glowing_button.dart';
import '../widgets/widget_snippets.dart';
import 'drawer_menu_widget.dart';
import 'navigation/routes.dart';

class MainPage extends StatefulWidget {
  final VoidCallback? openDrawer;
  const MainPage({Key? key, this.openDrawer}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  void initState() {
    //await myConfig?.config.loadAsset(/*context*/);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        actions: WidgetSnippets.hyAppBarActions(context),
        backgroundColor: Colors.orange,
        title: const Text('Main page'),
        leading: DrawerMenuWidget(onClicked: () {
          if (widget.openDrawer != null) {
            widget.openDrawer!();
          } else {
            Routemaster.of(context).push(AppRoutes.main);
          }
        }),
      ),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _glowingButton(
                  text: 'database',
                  onPressed: () {
                    Routemaster.of(context).push(AppRoutes.databaseExample);
                  },
                  icon1: Icons.info,
                  icon2: Icons.info_outlined,
                ),
                const SizedBox(width: 50),
                _glowingButton(
                  text: 'realtime',
                  onPressed: () {
                    Routemaster.of(context).push(AppRoutes.realtimeExample);
                  },
                  icon1: Icons.bolt,
                  icon2: Icons.bolt_outlined,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _glowingButton(
                  text: 'storage',
                  onPressed: () {
                    Routemaster.of(context).push(AppRoutes.storageExample);
                  },
                  icon1: Icons.perm_media,
                  icon2: Icons.perm_media_outlined,
                ),
                const SizedBox(width: 50),
                _glowingButton(
                  text: 'serverless',
                  onPressed: () {
                    Routemaster.of(context).push(AppRoutes.functionExample);
                  },
                  icon1: Icons.functions,
                  icon2: Icons.functions_outlined,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _glowingButton(
                  text: 'socket io',
                  onPressed: () {
                    Routemaster.of(context).push(AppRoutes.socketioExample);
                  },
                  icon1: Icons.hub,
                  icon2: Icons.hub_outlined,
                ),
                const SizedBox(width: 50),
                _glowingButton(
                  text: 'user account',
                  onPressed: () {
                    Routemaster.of(context).push(AppRoutes.userExample);
                  },
                  icon1: Icons.people,
                  icon2: Icons.people_outlined,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _glowingButton(
                  text: 'WebRTC',
                  onPressed: () {
                    Routemaster.of(context).push(AppRoutes.webrtcExample);
                  },
                  icon1: Icons.hub,
                  icon2: Icons.hub_outlined,
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  GlowingButton _glowingButton({
    required String text,
    required void Function() onPressed,
    required IconData icon1,
    required IconData icon2,
  }) {
    return GlowingButton(
      text: text,
      onPressed: onPressed,
      width: 320,
      height: 80,
      fontSize: 32,
      icon1: icon1,
      icon2: icon2,
    );
  }
}
