import 'package:flutter/material.dart';
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';


ProducerData? producerDataHolder;
class ProducerData extends ChangeNotifier {

  Producer? mic;
  Producer? webcam;
  
  ProducerData({this.mic, this.webcam});


  void producerAdd(Producer producer) {
    switch (producer.source) {
      case 'mic' :
        mic = producer;
        break;
      case 'webcam': 
        webcam = producer;
        break;
      default:
        break;
    }
    notifyListeners();
  }

  void producerRemove(String source) {
    switch (source) {
      case 'mic' :
        mic?.close();
        mic = null;
        break;
      case 'webcam': 
        webcam?.close();
        webcam = null;
        break;
      default:
        break;
    }
    notifyListeners();
  }

  void producerResume(String source) {
    switch(source) {
      case 'mic':
        mic = mic!.resumeCopy();
        break;
      case 'webcam':
        webcam = webcam!.resumeCopy();
        break;
      default :
        break;
    }
    notifyListeners();
  }

  void producerPause(String source) {
    switch(source) {
      case 'mic':
        mic = mic!.pauseCopy();
        break;
      case 'webcam':
        webcam = webcam!.pauseCopy();
        break;
      default :
        break;
    }
    notifyListeners();
  }




}