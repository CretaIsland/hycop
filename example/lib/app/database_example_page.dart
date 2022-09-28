// ignore_for_file: depend_on_referenced_packages

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:routemaster/routemaster.dart';

import '../widgets/widget_snippets.dart';
import '../data_io/book_manager.dart';
import 'package:hycop/hycop/absModel/abs_ex_model.dart';
import 'package:hycop/hycop/hycop_factory.dart';
//import 'package:hycop/hycop/model/user_model.dart';
import '../model/book_model.dart';
import 'package:hycop/common/util/logger.dart';
import 'book_list_widget.dart';
import 'constants.dart';
import 'navigation/routes.dart';
import 'drawer_menu_widget.dart';
import 'package:hycop/hycop/account/account_manager.dart';

class DatabaseExamplePage extends StatefulWidget {
  final VoidCallback? openDrawer;

  const DatabaseExamplePage({Key? key, this.openDrawer}) : super(key: key);

  @override
  State<DatabaseExamplePage> createState() => _DatabaseExamplePageState();
}

class _DatabaseExamplePageState extends State<DatabaseExamplePage> {
  final listKey = GlobalKey<AnimatedListState>();
  String _bookModelStr = '';
  int counter = 0;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    bookManagerHolder = BookManager();
    logger.info('initState');
    HycopFactory.initAll();
    HycopFactory.realtime!.addListener("hycop_book", bookManagerHolder!.realTimeCallback);
  }

  @override
  void dispose() {
    logger.finest('_DatabaseExamplePageState dispose');
    super.dispose();
    //HycopFactory.myRealtime!.stop();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    HycopFactory.realtime!.start();

    Size screenSize = MediaQuery.of(context).size;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BookManager>.value(
          value: bookManagerHolder!,
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
          title: const Text('Database Example'),
          leading: DrawerMenuWidget(onClicked: () {
            if (widget.openDrawer != null) {
              widget.openDrawer!();
            } else {
              //Routemaster.of(context).push(AppRoutes.menu);
              Routemaster.of(context).push(AppRoutes.main);
            }
          }),
        ),
        body: FutureBuilder<List<AbsExModel>>(
            future: bookManagerHolder!.getListFromDB(AccountManager.currentLoginUser.email),
            builder: (context, AsyncSnapshot<List<AbsExModel>> snapshot) {
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
                logger.finest("book founded ${snapshot.data!.length}");
                // if (snapshot.data!.isEmpty) {
                //   return const Center(child: Text('no book founded'));
                // }
                return Consumer<BookManager>(builder: (context, bookManager, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        //color: Colors.amber,
                        height: 50,
                        //width: 100,
                        child: Text(
                          '${bookManager.modelList.length} data founded(${AccountManager.currentLoginUser.email})',
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      SizedBox(
                        height: screenSize.height * 0.8,
                        child: AnimatedList(
                          key: listKey,
                          initialItemCount: bookManager.modelList.length,
                          itemBuilder: (context, index, animation) {
                            if (index >= bookManager.modelList.length) {
                              return Container();
                            }
                            return BookListWidget(
                              item: bookManager.modelList[index] as BookModel,
                              animation: animation,
                              onDeleteClicked: () => removeItem(bookManager, index),
                              onSaveClicked: () => saveItem(bookManager, index),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                });
              }
              return Container();
            }),
      ),
    );
  }

  void removeItem(BookManager bookManager, int index) async {
    BookModel removedItem = bookManager.modelList[index] as BookModel;
    await bookManager.removeToDB(removedItem.mid);
    listKey.currentState?.removeItem(
      index,
      (context, animation) => BookListWidget(
        item: removedItem,
        animation: animation,
        onDeleteClicked: () {},
        onSaveClicked: () {},
      ),
      duration: const Duration(milliseconds: 600),
    );
    bookManager.modelList.remove(removedItem);
    bookManager.notify();
  }

  void saveItem(BookManager bookManager, int index) async {
    BookModel savedItem = bookManager.modelList[index] as BookModel;
    await bookManager.setToDB(savedItem);
  }

  void insertItem() async {
    int randomNumber = random.nextInt(1000);
    BookModel book = BookModel.withName(
        '${sampleNameList[randomNumber % sampleNameList.length]}_$randomNumber',
        AccountManager.currentLoginUser.email);

    book.hashTag.set('#$randomNumber tag...');

    await bookManagerHolder!.createToDB(book);
    bookManagerHolder!.modelList.insert(0, book);
    listKey.currentState?.insertItem(
      0,
      duration: const Duration(microseconds: 600),
    );
    bookManagerHolder!.notify();
  }

  Widget oldExample(BookManager bookManager) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('database and realTime example'),
        const SizedBox(
          height: 20,
        ),
        ElevatedButton(
            onPressed: () async {
              //Navigator.of(context).pop();
              Routemaster.of(context).push(AppRoutes.login);
            },
            child: const Text('logout')),
        Center(child: Text(bookManager.debugText())),
        ElevatedButton(
            onPressed: () async {
              BookModel book =
                  await bookManager.getFromDB(bookManager.modelList.first.mid) as BookModel;
              setState(() {
                _bookModelStr = book.debugText();
              });
            },
            child: const Text('get first data')),
        Text(_bookModelStr),
        ElevatedButton(
            onPressed: () async {
              if (bookManager.modelList.isEmpty) {
                BookModel book =
                    BookModel.withName('sample($counter)', AccountManager.currentLoginUser.email);
                await bookManager.createToDB(book);
              } else {
                BookModel book = BookModel();
                book.copyFrom(bookManager.modelList.first, newMid: book.mid);
                book.name.set('(${counter++}) new created book', save: false);
                await bookManager.createToDB(book);
              }
              setState(() {});
            },
            child: const Text('create data')),
        const SizedBox(
          height: 10,
        ),
        ElevatedButton(
            onPressed: () async {
              BookModel book = bookManager.modelList.first as BookModel;
              book.name.set('change #${++counter}th book', save: false);
              book.hashTag.set("#${counter}th Tag", save: false);
              await bookManager.setToDB(book);
              setState(() {
                _bookModelStr = '';
              });
            },
            child: const Text('set data')),
        const SizedBox(
          height: 10,
        ),
        ElevatedButton(
            onPressed: () async {
              if (bookManager.modelList.isEmpty) {
                await bookManager.removeToDB('wrong mid test');
              } else {
                await bookManager.removeToDB(bookManager.modelList.first.mid);
              }
              setState(() {});
            },
            child: const Text('remove data')),
        // const SizedBox(
        //   height: 10,
        // ),
        // ElevatedButton(
        //     onPressed: () async {
        //       BookModel book = bookManager.modelList.first as BookModel;
        //       HycopFactory.myRealtime!.createExample(book.mid);
        //     },
        //     child: const Text('create delta sample')),
      ],
    );
  }
}
