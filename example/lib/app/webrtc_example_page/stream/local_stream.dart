
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hycop/hycop/webrtc/producers/producers_data.dart';
import 'package:provider/provider.dart';

class LocalStream extends StatefulWidget {
  const LocalStream({Key? key}) : super(key: key);
  @override
  _LocalStreamState createState() => _LocalStreamState();
}

class _LocalStreamState extends State<LocalStream> {
  late RTCVideoRenderer renderer;
  final double streamContainerSize = 180;

  @override
  void initState() {
    super.initState();
    initRenderers();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ ChangeNotifierProvider<ProducerData>.value(value: producerDataHolder! )],
      child: Consumer<ProducerData>(
        builder: (context, producerDataManager, child) {
          if(producerDataManager.webcam != null) {
            if(renderer.srcObject != producerDataManager.webcam!.stream) {
              renderer.srcObject = producerDataManager.webcam!.stream;
            }
          }

          if(renderer.srcObject != null && renderer.renderVideo && producerDataManager.webcam != null) {
            return Container(
              width: MediaQuery.of(context).size.width * .7,
              height: MediaQuery.of(context).size.height * .7,
              child: RTCVideoView(renderer),
            );
          } else {
            return Container(
              width: MediaQuery.of(context).size.width * .7,
              height: MediaQuery.of(context).size.height * .7,
              child: Icon(
                Icons.person,
                size: MediaQuery.of(context).size.height * .7,
                color: Colors.grey,
              )
            );
          }
        }, 
      ),
    );


    // return BlocConsumer<ProducersBloc, ProducersState>(
    //   listener: (context, state) {
    //     if (renderer.srcObject != state.webcam?.stream) {
    //       renderer.srcObject = state.webcam?.stream;
    //     }
    //   },
    //   builder: (context, state) {
    //     final MediaDeviceInfo? selectedVideoInput = context.select((MediaDevicesBloc mediaDevicesBloc) => mediaDevicesBloc.state.selectedVideoInput);
    //     if (renderer.srcObject != null && renderer.renderVideo) {
    //       return Container(
    //         width: MediaQuery.of(context).size.width * .7,
    //         height: MediaQuery.of(context).size.height * .7,
    //         child: RTCVideoView(renderer),
    //       );
    //     } else {
    //       return Container(
    //         width: MediaQuery.of(context).size.width * .7,
    //         height: MediaQuery.of(context).size.height * .7,
    //         child: Icon(
    //           Icons.person,
    //           size: MediaQuery.of(context).size.height * .7,
    //           color: Colors.grey,
    //         )
    //       );
    //     }
    //   },
    // );
  }

  void initRenderers() async {
    renderer = RTCVideoRenderer();
    await renderer.initialize();
  }

  @override
  void dispose() {
    renderer.dispose();
    super.dispose();
  }
}
