// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:hycop/hycop/account/account_manager.dart';
import 'package:hycop/hycop/socket/mouse_tracer.dart';
import 'package:hycop/hycop/socket/socket_client.dart';
import 'package:provider/provider.dart';
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

  SocketClient client = SocketClient();
  List<Color> userColorList = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple];

  late double screenWidthPercentage;
  late double screenHeightPrecentage;
  late double screenWidth;

  @override
  void initState() {
    super.initState();
    mouseTracerHolder = MouseTracer();
    mouseTracerHolder!.joinUser([{"userID" : AccountManager.currentLoginUser.email, "userName" : AccountManager.currentLoginUser.name}]);

    client.initialize();
    client.connectServer("contentBookID");
  }

  @override
  Widget build(BuildContext context) {

    screenWidthPercentage = MediaQuery.of(context).size.width * 0.01;
    screenHeightPrecentage = MediaQuery.of(context).size.height * 0.01;
    screenWidth = MediaQuery.of(context).size.width;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MouseTracer>.value(value: mouseTracerHolder!)
      ],
      child: Scaffold(
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
        body: Consumer<MouseTracer>(builder: (context, mouseTracerManager, child) {
          return MouseRegion(
            onHover: (pointerEvent) {
              mouseTracerManager.changePosition(0, pointerEvent.position.dx / screenWidthPercentage, (pointerEvent.position.dy-50) / screenHeightPrecentage);
              client.moveCursor(pointerEvent.position.dx / screenWidthPercentage, (pointerEvent.position.dy-50) / screenHeightPrecentage);
            },
            child: Stack(
              children: [
                componentWidget("basicFrame", MediaQuery.of(context).size.width, MediaQuery.of(context).size.height - 80, 0, Colors.white, mouseTracerManager),
                Center(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      componentWidget("frame_1", screenWidth * 0.1, screenWidth * 0.1, screenWidth * 0.1, const Color.fromARGB(255, 255, 171, 164), mouseTracerManager),
                      SizedBox(width: screenWidth * 0.05),
                      componentWidget("frame_2", screenWidth * 0.1, screenWidth * 0.1, 0, const Color.fromARGB(255, 134, 190, 135), mouseTracerManager),
                      SizedBox(width: screenWidth * 0.05),
                      componentWidget("frame_3", screenWidth * 0.1, screenWidth * 0.1, screenWidth * 0.03, const Color.fromARGB(255, 144, 183, 215), mouseTracerManager),
                    ],
                  ),
                ),
                cursorWidget(0, mouseTracerManager),
                for(int i=1; i<mouseTracerManager.mouseModelList.length; i++)
                  cursorWidget(i, mouseTracerManager)
              ]
            ),
          );
        })
      )
    );
  }

  // 컴포넌트 위젯의 테두리 제공
  Border getBorder(String frameID, MouseTracer mouseTracerManager) {
    Border border = Border.all();
    for(var element in mouseTracerManager.focusFrameList) {
      if(element["frameID"] == frameID) {
        border = Border.all(color: userColorList[mouseTracerHolder!.getIndex(element["userID"]!) % 5], width: 3);
      }
    }
    return border;
  }

  // 컴포넌트 위젯
  Widget componentWidget(String frameID, double width, double height, double radius, Color color, MouseTracer mouseTracerManager) {
    return GestureDetector(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: frameID != "basicFrame" ? getBorder(frameID, mouseTracerManager) : null,
          borderRadius: BorderRadius.circular(radius),
          color: color
        ),
      ),
      onTap: () {
        client.unFocusFrame();
        if(frameID != "basicFrame") {
          client.focusFrame(frameID);
        }
      },
    );
  }

  // 유저 마우스 객체 위젯
  Widget cursorWidget(int index, MouseTracer mouseTracerManager) {
    return Positioned(
      left: mouseTracerManager.mouseModelList[index].cursorX * screenWidthPercentage,
      top: mouseTracerManager.mouseModelList[index].cursorY * screenHeightPrecentage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children : [
          Icon(
            Icons.pan_tool_alt,
            size: 30,
            color: userColorList[index < 5 ? index : (index % 5) + 1],
          ),
          index == 0 ? Container() :
          Container(
            width: mouseTracerManager.mouseModelList[index].userName.length * 10,
            height: 20,
            decoration: BoxDecoration(
              color: userColorList[index < 5 ? index : (index % 5) + 1],
              borderRadius: BorderRadius.circular(20)
            ),
            child: Text(mouseTracerManager.mouseModelList[index].userName, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
          )
        ]
      )
    );
  }

  


}