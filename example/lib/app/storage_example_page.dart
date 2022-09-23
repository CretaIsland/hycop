// ignore: duplicate_ignore
// ignore_for_file: depend_on_referenced_packages

import 'dart:typed_data';

import 'package:hycop/common/util/config.dart';
import 'package:hycop/hycop/utils/hycop_exceptions.dart';
import 'package:hycop/common/util/logger.dart';
import '../data_io/file_manager.dart';
import 'package:hycop/hycop/enum/model_enums.dart';
import 'package:hycop/hycop/hycop_factory.dart';
import 'package:hycop/hycop/model/file_model.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';
import '../widgets/widget_snippets.dart';
import 'drawer_menu_widget.dart';
import 'navigation/routes.dart';
import 'package:provider/provider.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter_dropzone/flutter_dropzone.dart';

class StorageExamplePage extends StatefulWidget {
  final VoidCallback? openDrawer;

  const StorageExamplePage({Key? key, this.openDrawer}) : super(key: key);

  @override
  State<StorageExamplePage> createState() => _StorageExamplePageState();
}

class _StorageExamplePageState extends State<StorageExamplePage> with TickerProviderStateMixin {
  late TabController _tabController;
  // late DropzoneViewController _dropZonecontroller;
  late html.File dropFile;
  html.FileReader fileReader = html.FileReader();

  @override
  void initState() {
    super.initState();
    fileManagerHolder = FileManager();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    //Size screenSize = MediaQuery.of(context).size;
    return MultiProvider(
      providers: [ChangeNotifierProvider<FileManager>.value(value: fileManagerHolder!)],
      child: Scaffold(
        appBar: AppBar(
          actions: WidgetSnippets.hyAppBarActions(context),
          backgroundColor: Colors.orange,
          title: const Text('Storage Example'),
          leading: DrawerMenuWidget(onClicked: () {
            if (widget.openDrawer != null) {
              widget.openDrawer!();
            } else {
              Routemaster.of(context).push(AppRoutes.main);
            }
          }),
        ),
        body: Row(
          children: [
            Expanded(
                flex: 6,
                child: Container(
                  color: Colors.yellow[600],
                  child: dropZoneWidget(context),
                )),
            Expanded(
                flex: 4,
                child: Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * .1,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.grey,
                        indicatorColor: Colors.grey,
                        tabs: const [Tab(text: "image"), Tab(text: "video"), Tab(text: "etc")],
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * .8,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          imgFileListView(ContentsType.image),
                          videoFileListView(ContentsType.video),
                          etcFileListView(ContentsType.octetstream)
                        ],
                      ),
                    )
                  ],
                )),
          ],
        ),
      ),
    );
  }

  Widget dropZoneWidget(BuildContext context) {
    return Builder(
      builder: (context) => DropzoneView(
        operation: DragOperation.copy,
        cursor: CursorType.grab,
        // onCreated: (ctrl) => _dropZonecontroller = ctrl,
        onLoaded: () => logger.finest("dropZone load"),
        onHover: () => logger.finest("dropZone hover"),
        onLeave: () => logger.finest("dropZone leave"),
        onError: (err) => throw HycopException(message: err.toString()),
        onDrop: (ev) async {
          logger.finest("drop");

          dropFile = ev as html.File;

          fileReader.onLoadEnd.listen((event) {
            HycopFactory.storage!
                .uploadFile(dropFile.name, dropFile.type, fileReader.result as Uint8List)
                .then((value) async {
              switch (ContentsType.getContentTypes(dropFile.type)) {
                case ContentsType.image:
                  await fileManagerHolder!.getImgFileList();
                  break;
                case ContentsType.video:
                  await fileManagerHolder!.getVideoFileList();
                  break;
                case ContentsType.octetstream:
                  await fileManagerHolder!.getEtcFileList();
                  break;
                default:
                  break;
              }
            });
          });

          fileReader.onError.listen((err) {
            throw HycopException(message: err.toString());
          });

          fileReader.readAsArrayBuffer(dropFile);
        },
      ),
    );
  }

  Widget imgFileListView(ContentsType contentsType) {
    return FutureBuilder(
        future: fileManagerHolder!.getImgFileList(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasError) {
            logger.severe("data fetch error");
            return const Center(child: Text('data fetch error'));
          }
          if (snapshot.hasData) {
            logger.severe("No data founded");
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.connectionState == ConnectionState.done) {
            logger.finest("done!");
            return Consumer<FileManager>(builder: (context, fileManager, child) {
              return fileListTileView(fileManager.imgFileList, contentsType);
            });
          }
          return Container();
        });
  }

  Widget videoFileListView(ContentsType contentsType) {
    return FutureBuilder(
        future: fileManagerHolder!.getVideoFileList(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasError) {
            logger.severe("data fetch error");
            return const Center(child: Text('data fetch error'));
          }
          if (snapshot.hasData) {
            logger.severe("No data founded");
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.connectionState == ConnectionState.done) {
            return Consumer<FileManager>(builder: (context, fileManager, child) {
              return fileListTileView(fileManager.videoFileList, contentsType);
            });
          }
          return Container();
        });
  }

  Widget etcFileListView(ContentsType contentsType) {
    return FutureBuilder(
        future: fileManagerHolder!.getEtcFileList(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasError) {
            logger.severe("data fetch error");
            return const Center(child: Text('data fetch error'));
          }
          if (snapshot.hasData) {
            logger.severe("No data founded");
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.connectionState == ConnectionState.done) {
            return Consumer<FileManager>(builder: (context, fileManager, child) {
              return fileListTileView(fileManager.etcFileList, contentsType);
            });
          }
          return Container();
        });
  }

  Widget fileListTileView(List<FileModel> fileList, ContentsType contentsType) {
    return GridView.builder(
      controller: ScrollController(),
      itemCount: fileList.length,
      itemBuilder: (BuildContext context, int index) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: MediaQuery.of(context).size.width * .18,
              height: MediaQuery.of(context).size.width * .1,
              decoration: contentsType == ContentsType.image
                  ? BoxDecoration(
                      image: DecorationImage(
                          image: HycopFactory.serverType == ServerType.appwrite
                              ? Image.memory(fileList[index].fileView).image
                              : NetworkImage(fileList[index].fileView),
                          fit: BoxFit.cover),
                      borderRadius: BorderRadius.circular(10))
                  : BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                      icon:
                          Icon(Icons.delete_rounded, size: MediaQuery.of(context).size.width * .02),
                      onPressed: () {
                        fileManagerHolder!.deleteFile(fileList[index].fileId, contentsType);
                      })
                ],
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * .2,
              height: MediaQuery.of(context).size.width * .02,
              child: Text(fileList[index].fileName, textAlign: TextAlign.center),
            )
          ],
        );
      },
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: MediaQuery.of(context).size.width * .2,
          crossAxisSpacing: 3,
          mainAxisSpacing: 3,
          childAspectRatio: 2 / 1.3),
    );
  }
}
