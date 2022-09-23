// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';
import '../widgets/widget_snippets.dart';
import 'drawer_menu_widget.dart';
import 'navigation/routes.dart';

class SocketIOExamplePage extends StatefulWidget {
  final VoidCallback? openDrawer;

  const SocketIOExamplePage({Key? key, this.openDrawer}) : super(key: key);

  @override
  State<SocketIOExamplePage> createState() => _SocketIOExamplePageState();
}

class _SocketIOExamplePageState extends State<SocketIOExamplePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        actions: WidgetSnippets.hyAppBarActions(context),
        backgroundColor: Colors.orange,
        title: const Text('Socket IO Example'),
        leading: DrawerMenuWidget(onClicked: () {
          if (widget.openDrawer != null) {
            widget.openDrawer!();
          } else {
            Routemaster.of(context).push(AppRoutes.main);
          }
        }),
      ),
      body: Container(),
    );
  }
}
