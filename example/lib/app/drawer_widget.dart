// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DrawerItem {
  final String title;
  final IconData icon;

  const DrawerItem({required this.title, required this.icon});
}

class DrawerItems {
  static const intro = DrawerItem(title: 'infro', icon: FontAwesomeIcons.wandMagic);
  static const home = DrawerItem(title: 'home', icon: FontAwesomeIcons.house);
  static const database = DrawerItem(title: 'database', icon: FontAwesomeIcons.database);
  static const realtime = DrawerItem(title: 'realtime', icon: FontAwesomeIcons.cloudBolt);
  static const storage = DrawerItem(title: 'storage', icon: FontAwesomeIcons.file);
  static const function =
      DrawerItem(title: 'serverless function', icon: FontAwesomeIcons.puzzlePiece);
  static const socket = DrawerItem(title: 'socket io', icon: FontAwesomeIcons.computerMouse);
  static const user = DrawerItem(title: 'user account', icon: FontAwesomeIcons.users);
  static const logout = DrawerItem(title: 'logout', icon: FontAwesomeIcons.rightFromBracket);
  static List<DrawerItem> all = [
    intro,
    home,
    database,
    realtime,
    storage,
    function,
    socket,
    user,
    logout
  ];
}

class DrawerWidget extends StatelessWidget {
  final ValueChanged<DrawerItem> onSelectedItem;

  const DrawerWidget({
    Key? key,
    required this.onSelectedItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: SingleChildScrollView(
          child: Column(
        children: [
          buildDrawerItems(context),
        ],
      )),
    );
  }

  Widget buildDrawerItems(BuildContext context) {
    return Column(
      children: DrawerItems.all
          .map((e) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                leading: Icon(e.icon, color: Colors.white),
                title: Text(
                  e.title,
                  style: const TextStyle(color: Colors.white, fontSize: 36),
                ),
                onTap: () {
                  onSelectedItem(e);
                },
              ))
          .toList(),
    );
  }
}
