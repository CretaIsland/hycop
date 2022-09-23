// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';
// import 'package:uuid/uuid.dart';

import 'package:hycop/common/util/logger.dart';
import '../widgets/glowing_button.dart';
import '../widgets/widget_snippets.dart';
import '../widgets/gauge_view.dart';
import 'package:hycop/hycop/hycop_factory.dart';
import 'drawer_menu_widget.dart';
import 'navigation/routes.dart';

class FunctionExamplePage extends StatefulWidget {
  final VoidCallback? openDrawer;

  const FunctionExamplePage({Key? key, this.openDrawer}) : super(key: key);

  @override
  State<FunctionExamplePage> createState() => _FunctionExamplePageState();
}

class _FunctionExamplePageState extends State<FunctionExamplePage> {
  String _setDBTestResult = '';
  String _getDBTestResult = '';
  String _removeDeltaResult = '';

  double _guageValue = 98;

  final guageKey = GlobalKey<GaugeViewState>();

  @override
  void initState() {
    super.initState();
    //HycopFactory.myFunction!.initialize();
    logger.finest('_FunctionExamplePageState initState()');
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //String id = const Uuid().v4();

    return Scaffold(
        appBar: AppBar(
          actions: WidgetSnippets.hyAppBarActions(context),
          backgroundColor: Colors.orange,
          title: const Text('Function Example'),
          leading: DrawerMenuWidget(onClicked: () {
            if (widget.openDrawer != null) {
              widget.openDrawer!();
            } else {
              Routemaster.of(context).push(AppRoutes.main);
            }
          }),
        ),
        body: FutureBuilder<double>(
          future: getDiskUsage(),
          //future: nullFunction(),
          builder: (context, AsyncSnapshot<double> snapshot) {
            if (snapshot.hasError) {
              //error가 발생하게 될 경우 반환하게 되는 부분
              logger.severe("data fetch error");
              return const Center(child: Text('data fetch error'));
            }
            if (snapshot.hasData == false) {
              logger.severe("No data founded()");
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.connectionState == ConnectionState.done) {
              logger.info("data founded ${snapshot.data!}");
              _guageValue = snapshot.data!;
            }
            return guageExample();
            //return oldExample(id);
          },
        ));
  }

  Future<double> getDiskUsage() async {
    String result = '0';
    try {
      result = await HycopFactory.function!.execute(functionId: "getDiskUsage");
    } catch (e) {
      logger.severe('getDiskUsage test failed $e');
    }
    return parseResult(result);
  }

  Future<double> nullFunction() async {
    return 0.0;
  }

  double parseResult(String result) {
    double usage = 0;
    int pos1 = result.indexOf(':');
    if (pos1 > 0) {
      // 리턴이 json 으로 온 경우 {"usage":22}
      logger.info('params=($result)');
      Map<String, dynamic>? jsonParams = jsonDecode(result);
      usage = jsonParams?['usage'] as double;
      logger.info('getDiskUsage <$usage>');
    } else {
      // 리턴이 그냥 숫자로 온경우
      logger.info('getDiskUsage end <$result>');
      usage = double.parse(result);
    }
    return usage;
  }

  Widget guageExample() {
    logger.info('disk usage = $_guageValue');
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Container(
          width: 500,
          height: 500,
          padding: const EdgeInsets.all(10),
          child: GaugeView(
            key: guageKey,
            unitOfMeasurement: 'Disk Usage %',
            minSpeed: 0,
            maxSpeed: 100,
            speed: _guageValue,
            animate: true,
            alertSpeedArray: const [40, 80, 90],
            alertColorArray: const [Colors.orange, Colors.indigo, Colors.red],
            duration: const Duration(seconds: 2),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GlowingButton(
              text: 'clean disk',
              width: 240,
              height: 60,
              fontSize: 24,
              icon1: Icons.delete,
              icon2: Icons.delete_outlined,
              onPressed: () async {
                logger.info('clean disk');
                String result = '0';
                try {
                  result = await HycopFactory.function!
                      .execute(functionId: "setDiskUsage", params: '{"usage":20}');
                } catch (e) {
                  logger.severe('setDiskUsage test failed $e');
                }
                logger.info('clean disk end');
                double usage = parseResult(result);
                setState(() {
                  _guageValue = usage;
                });
                guageKey.currentState?.reset();
              },
            ),
            GlowingButton(
              text: 'refresh usage',
              width: 240,
              height: 60,
              fontSize: 24,
              icon1: Icons.refresh,
              icon2: Icons.refresh_outlined,
              onPressed: () async {
                logger.info('refresh usage');
                double usage = await getDiskUsage();
                setState(() {
                  _guageValue = usage;
                });
                guageKey.currentState?.reset();
              },
            ),
          ],
        ),
      ]),
    );
  }

  Widget oldExample(String id) {
    return Center(
      child: Column(
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
          const SizedBox(
            height: 20,
          ),
          ElevatedButton(
              onPressed: () async {
                _setDBTestResult = '';
                try {
                  _setDBTestResult = await HycopFactory.function!
                      .execute(functionId: "setDBTest", params: '{"text":"helloworld","id":"$id"}');
                } catch (e) {
                  _setDBTestResult = 'setDBTest test failed $e';
                  logger.severe(_setDBTestResult);
                }
                setState(() {});
              },
              child: const Text('setDBTest')),
          Text(_setDBTestResult),
          const SizedBox(
            height: 20,
          ),
          ElevatedButton(
              onPressed: () async {
                _getDBTestResult = '';
                try {
                  _getDBTestResult = await HycopFactory.function!
                      .execute(functionId: "getDBTest", params: '{"text":"helloworld"}');
                } catch (e) {
                  _getDBTestResult = 'getDBTest test failed $e';
                  logger.severe(_getDBTestResult);
                }
                setState(() {});
              },
              child: const Text('getDBTest')),
          Text(_getDBTestResult),
          const SizedBox(
            height: 20,
          ),
          ElevatedButton(
              onPressed: () async {
                _removeDeltaResult = '';
                try {
                  _removeDeltaResult =
                      await HycopFactory.function!.execute(functionId: "removeDelta");
                } catch (e) {
                  _removeDeltaResult = 'removeDelta test failed $e';
                  logger.severe(_removeDeltaResult);
                }
                setState(() {});
              },
              child: const Text('removeDelta Test')),
          Text(_removeDeltaResult),
        ],
      ),
    );
  }
}
