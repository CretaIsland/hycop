// ignore_for_file: depend_on_referenced_packages
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hycop/common/undo/save_manager.dart';
import 'package:hycop/common/util/config.dart';
import 'package:provider/provider.dart';
import 'package:routemaster/routemaster.dart';

import 'package:hycop/common/util/logger.dart';
import '../widgets/widget_snippets.dart';
import '../data_io/frame_manager.dart';
import 'package:hycop/hycop/absModel/abs_ex_model.dart';
import 'package:hycop/hycop/hycop_factory.dart';
import '../model/frame_model.dart';
import 'acc/draggable_resizable.dart';
import 'acc/stickerview.dart';
import 'constants.dart';
import 'drawer_menu_widget.dart';
import 'navigation/routes.dart';

class RealTimeExamplePage extends StatefulWidget {
  final VoidCallback? openDrawer;

  const RealTimeExamplePage({Key? key, this.openDrawer}) : super(key: key);

  @override
  State<RealTimeExamplePage> createState() => _RealTimeExamplePageState();
}

class _RealTimeExamplePageState extends State<RealTimeExamplePage> {
  final Random random = Random();
  static int randomindex = 0;

  @override
  void initState() {
    super.initState();
    frameManagerHolder = FrameManager();
    if (HycopFactory.serverType == ServerType.appwrite) {
      if (saveManagerHolder == null) {
        saveManagerHolder = SaveManager();
        saveManagerHolder!.registerManager('frame', frameManagerHolder!);
        saveManagerHolder!.runSaveTimer();
      }
    }
    HycopFactory.realtime!.addListener("hycop_frame", frameManagerHolder!.realTimeCallback);
    HycopFactory.realtime!.start();
  }

  @override
  void dispose() {
    logger.finest('_RealTimeExamplePageState dispose');
    super.dispose();
    //HycopFactory.myRealtime!.stop();
  }

  @override
  Widget build(BuildContext context) {
    //Size screenSize = MediaQuery.of(context).size;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FrameManager>.value(
          value: frameManagerHolder!,
        ),
      ],
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: insertItem,
          child: const Icon(Icons.add),
        ),
        appBar: AppBar(
          actions: WidgetSnippets.hyAppBarActions(context),
          backgroundColor: Colors.orange,
          title: const Text('Realtime Example'),
          leading: DrawerMenuWidget(onClicked: () {
            if (widget.openDrawer != null) {
              widget.openDrawer!();
            } else {
              Routemaster.of(context).push(AppRoutes.main);
            }
          }),
        ),
        body: FutureBuilder<List<AbsExModel>>(
          future: frameManagerHolder!.getAllListFromDB(),
          builder: (context, AsyncSnapshot<List<AbsExModel>> snapshot) {
            if (snapshot.hasError) {
              //error가 발생하게 될 경우 반환하게 되는 부분
              logger.severe("data fetch error");
              return const Center(child: Text('data fetch error'));
            }
            if (snapshot.hasData == false) {
              logger.severe("No data founded");
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.connectionState == ConnectionState.done) {
              logger.finest("frame founded ${snapshot.data!.length}");
              // if (snapshot.data!.isEmpty) {
              //   return const Center(child: Text('no frame founded'));
              // }
              return Consumer<FrameManager>(builder: (context, frameManager, child) {
                return Center(child: createView(frameManager));
              });
            }
            return Container();
          },
        ),
      ),
    );
  }

  void insertItem() async {
    int randomNumber = random.nextInt(1000);
    FrameModel frame = FrameModel.withName(
        '${sampleNameList[randomNumber % sampleNameList.length]}_$randomNumber');

    frame.hashTag.set('#$randomNumber tag...');
    frame.bgUrl.set(sampleImageList[(++randomindex) % sampleImageList.length]);
    frame.bgColor.set(sampleColorList[(++randomindex) % sampleColorList.length]);

    await frameManagerHolder!.createToDB(frame);
    frameManagerHolder!.modelList.insert(0, frame);
    frameManagerHolder!.notify();
  }

  void saveItem(DragUpdate update, FrameManager frameManager, String mid) async {
    for (var item in frameManager.modelList) {
      if (item.mid != mid) continue;
      FrameModel model = item as FrameModel;
      model.angle.set(update.angle, save: false, noUndo: true);
      model.posX.set(update.position.dx, save: false, noUndo: true);
      model.posY.set(update.position.dy, save: false, noUndo: true);
      model.width.set(update.size.width, save: false, noUndo: true);
      model.height.set(update.size.height, save: false, noUndo: true);
      if (HycopFactory.serverType == ServerType.appwrite) {
        model.save();
      } else {
        await frameManager.setToDB(model);
      }
    }
  }

  void removeItem(FrameManager frameManager, String mid) async {
    for (var item in frameManager.modelList) {
      if (item.mid != mid) continue;
      frameManager.modelList.remove(item);
    }
    await frameManager.removeToDB(mid);
  }

  List<Sticker> getStickerList() {
    logger.finest('getStickerList()');
    return frameManagerHolder!.modelList.map((e) {
      FrameModel model = e as FrameModel;
      return Sticker(
        id: model.mid,
        position: Offset(model.posX.value, model.posY.value),
        angle: model.angle.value,
        size: Size(model.width.value, model.height.value),
        child: Container(
          color: model.bgColor.value,
          width: model.width.value,
          height: model.height.value,
          child: Image.asset(model.bgUrl.value.isEmpty
              ? sampleImageList[(++randomindex) % sampleImageList.length]
              : model.bgUrl.value),
        ),
      );
    }).toList();
  }

  Widget createView(FrameManager frameManager) {
    return StickerView(
      // List of Stickers
      onUpdate: (update, mid) {
        saveItem(update, frameManager, mid);
      },
      onDelete: (mid) {
        removeItem(frameManager, mid);
      },
      stickerList: [
        ...getStickerList(),
        // Sticker(
        //     id: "uniqueId_000",
        //     position: Offset.zero,
        //     angle: 0,
        //     // child: Image.network(
        //     //     "https://images.unsplash.com/photo-1640113292801-785c4c678e1e?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=736&q=80"),
        //     child: Container(
        //       color: Colors.red,
        //       width: 200,
        //       height: 200,
        //       child: Image.asset(
        //         'assets/jisoo.png',
        //         // frameBuilder:
        //         //     (BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) {
        //         //   if (wasSynchronouslyLoaded) {
        //         //     return child;
        //         //   }
        //         //   return AnimatedOpacity(
        //         //     opacity: frame == null ? 0 : 1,
        //         //     duration: const Duration(seconds: 10),
        //         //     curve: Curves.easeOut,
        //         //     child: child,
        //         //   );
        //         // },
        //       ),
        //     )),
        // Sticker(
        //   id: "uniqueId_222",
        //   angle: 0,
        //   position: const Offset(200, 200),
        //   isText: true,
        //   child: const Text("Hello"),
        // ),
      ],
    );
  }
}
