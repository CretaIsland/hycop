import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';


MediaDeviceData? mediaDeviceDataHolder;
class MediaDeviceData extends ChangeNotifier {

  List<MediaDeviceInfo>? audioInputs; 
  List<MediaDeviceInfo>? audioOutputs; 
  List<MediaDeviceInfo>? videoInputs; 
  MediaDeviceInfo? selectedAudioInput;
  MediaDeviceInfo? selectedAudioOutput;
  MediaDeviceInfo? selectedVideoInput;

  MediaDeviceData({
    this.audioInputs = const [],
    this.audioOutputs = const [],
    this.videoInputs = const [],
    this.selectedAudioInput,
    this.selectedAudioOutput,
    this.selectedVideoInput
  });

  void selectAudioInput(MediaDeviceInfo? device) {
    selectedAudioInput = device;
    notifyListeners();
  }

  void selectAudioOutput(MediaDeviceInfo? device) {
    selectedAudioOutput = device;
    notifyListeners();
  }

  void selectVedioInput(MediaDeviceInfo? device) {
    selectedVideoInput = device;
    notifyListeners();
  }

  Future<void> loadMediaDevice() async {
    try {
      final List<MediaDeviceInfo> devices = await navigator.mediaDevices.enumerateDevices();
      final List<MediaDeviceInfo> audioInputDevices = [];
      final List<MediaDeviceInfo> audioOutputDevices = [];
      final List<MediaDeviceInfo> videoInputDevices = [];

      devices.forEach((device) {
        switch(device.kind) {
          case 'audioinput':
            audioInputDevices.add(device);
            break;
          case 'audiooutput':
            audioOutputDevices.add(device);
            break;
          case 'videoinput':
            videoInputDevices.add(device);
            break;
          default:
            break;
        }
      });

      if (audioInputDevices.isNotEmpty) {
        selectedAudioInput = audioInputDevices.first;
        audioInputs = audioInputDevices;
      }
      if (audioOutputDevices.isNotEmpty) {
        selectedAudioOutput = audioOutputDevices.first;
        audioOutputs = audioOutputDevices;
      }
      if (videoInputDevices.isNotEmpty) {
        selectedVideoInput = videoInputDevices.first;
        videoInputs = videoInputDevices;
      }
      notifyListeners();
    } catch (error) {
      print(error);
    }
  }








}