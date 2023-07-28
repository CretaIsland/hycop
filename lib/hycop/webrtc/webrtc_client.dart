

import 'package:hycop/hycop/webrtc/media_devices/media_devices_data.dart';
import 'package:hycop/hycop/webrtc/peers/peers_data.dart';
import 'package:hycop/hycop/webrtc/producers/producers_data.dart';
import 'package:hycop/hycop/webrtc/websocket.dart';
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';

WebRTCClient? webRTCClient;

class WebRTCClient {

  final String roomId;
  final String peerId;
  final String peerName;
  final String serverUrl;
  
  WebSocket? _webSocket;
  Device? _mediaDevice;
  Transport? _sendTransport;
  Transport? _recvTransport;

  bool _canProduce = false;
  final bool _canConsume = true;
  bool _closed = false;

  String audioInputDeviceId = "";
  String videoInputDeviceId = "";


  WebRTCClient({required this.roomId, required this.peerId, required this.peerName, required this.serverUrl});


  // connect socket server
  void connectSocket() {

    _webSocket = WebSocket(
      peerId: peerId, 
      roomId: roomId, 
      url: serverUrl
    );

    // socket event
    _webSocket!.onOpen = joinRoom;
    _webSocket!.onFail = () {
    };
    _webSocket!.onDisconnected = () {
      if (_sendTransport != null) {
        _sendTransport!.close();
        _sendTransport = null;
      }
      if (_recvTransport != null) {
        _recvTransport!.close();
        _recvTransport = null;
      }
    };
    _webSocket!.onClose = () {
      if (_closed) return;
      close();
    };
    _webSocket!.onRequest = (request, accept, reject) {
      switch (request['method']) {
        case 'newConsumer':
          {
            if (!_canConsume) {
              reject(403, 'I do not want to consume');
              break;
            }
            try {
              _recvTransport!.consume(
                id: request['data']['id'],
                producerId: request['data']['producerId'],
                kind: RTCRtpMediaTypeExtension.fromString(request['data']['kind']),
                rtpParameters: RtpParameters.fromMap(request['data']['rtpParameters']),
                appData: Map<String, dynamic>.from(request['data']['appData']),
                peerId: request['data']['peerId'],
                accept: accept,
              );
            } catch (error) {
              rethrow;
            }
            break;
          }
        default:
          break;
      }
    };
    _webSocket!.onNotification =(notification) {
      switch (notification['method']) {
        case 'consumerClosed':
          {
            String consumerId = notification['data']['consumerId'];
            peersDataHolder!.consumerRemove(consumerId);
            break;
          }
        case 'consumerPaused':
          {
            String consumerId = notification['data']['consumerId'];
            peersDataHolder!.peerPausedConsumer(consumerId);
            break;
          }

        case 'consumerResumed':
          {
            String consumerId = notification['data']['consumerId'];
            peersDataHolder!.peerResumedConsumer(consumerId);
            break;
          }

        case 'newPeer':
          {
            final Map<String, dynamic> newPeer = Map<String, dynamic>.from(notification['data']);
            peersDataHolder!.peerAdd(newPeer);
            break;
          }

        case 'peerClosed':
          {
            String peerId = notification['data']['peerId'];
            peersDataHolder!.peerRemove(peerId);
            break;
          }

        default:
          break;
      }
    };
  }

  // join socket room
  Future<void> joinRoom() async {

    try {
      _mediaDevice = Device();

      dynamic routerRtpCapabilities = await _webSocket!.socket.request("getRouterRtpCapabilities", {});
      final rtpCapabilities = RtpCapabilities.fromMap(routerRtpCapabilities);
      rtpCapabilities.headerExtensions.removeWhere((element) => element.uri == "urn:3gpp:video-orientation");
      await _mediaDevice!.load(routerRtpCapabilities: rtpCapabilities);

      if(_mediaDevice!.canProduce(RTCRtpMediaType.RTCRtpMediaTypeVideo) || _mediaDevice!.canProduce(RTCRtpMediaType.RTCRtpMediaTypeAudio)) _canProduce = true;
      
      if(_canProduce) {
        Map transportInfo = await _webSocket!.socket.request("createWebRtcTransport", {
          "forceTcp": false,
          "producing": true,
          "consuming": false,
          "sctpCapabilities": _mediaDevice!.sctpCapabilities.toMap(),
        });

        _sendTransport = _mediaDevice!.createSendTransportFromMap(
          transportInfo,
          producerCallback: _producerCallback
        );

        // sendTransport event
        _sendTransport!.on("connect", (Map data) {
          _webSocket!.socket.request("connectWebRtcTransport", {
            "transportId": _sendTransport!.id,
            "dtlsParameters": data["dtlsParameters"].toMap(),
          }).then(data["callback"])
          .catchError(data["errback"]);
        });

        _sendTransport!.on("produce", (Map data) async {
          try {
            Map response = await _webSocket!.socket.request("produce", {
              "transportId": _sendTransport!.id,
              "kind": data["kind"],
              "rtpParameters": data["rtpParameters"].toMap(),
              if (data['appData'] != null) "appData": Map<String, dynamic>.from(data["appData"])
            });
            data["callback"](response["id"]);
          } catch (error) {
            data["errback"](error);
          }
        });

        _sendTransport!.on("producedata", (Map data) async {
          try {
            Map response = await _webSocket!.socket.request("produceData", {
              "transportId": _sendTransport!.id,
              "sctpStreamParameters": data["sctpStreamParameters"].toMap(),
              "label": data["label"],
              "protocol": data["protocol"],
              "appData": data["appData"],
            });
            data["callback"](response["id"]);
          } catch (error) {
            data["errback"](error);
          }
        });
      }


      if(_canConsume) {
        Map transportInfo = await _webSocket!.socket.request(
          "createWebRtcTransport",
          {
            "forceTcp": false,
            "producing": false,
            "consuming": true,
            "sctpCapabilities": _mediaDevice!.sctpCapabilities.toMap(),
          },
        );

        _recvTransport = _mediaDevice!.createRecvTransportFromMap(
          transportInfo,
          consumerCallback: _consumerCallback
        );

        _recvTransport!.on("connect", (Map data) {
          _webSocket!.socket.request("connectWebRtcTransport", {
            "transportId" : _recvTransport!.id,
            "dtlsParameters" : data["dtlsParameters"].toMap()
          }).then(data["callback"])
          .catchError(data["errback"]);
        });
      }


      Map response = await _webSocket!.socket.request("join", {
        "displayName" : peerName,
        "device": {
          "name": "Flutter",
          "flag": "flutter",
          "version": "0.8.0"
        },
        "rtpCapabilities": _mediaDevice!.rtpCapabilities.toMap(),
        "sctpCapabilities": _mediaDevice!.sctpCapabilities.toMap(),
      });

      response["peers"].forEach((value) {
        peersDataHolder!.peerAdd(value);
      });

      // if(_canProduce) {
      //   enableWebCam();
      //   enableMic();
      // }


    } catch (error) {
      rethrow;
    }
  }

  void _producerCallback(Producer producer) {
    producer.on('trackended', () {
      disableMic().catchError((data) {});
    });
    producerDataHolder!.producerAdd(producer);
  }

  void _consumerCallback(Consumer consumer, [dynamic accept]) {
    accept({});
    peersDataHolder!.consumerAdd(consumer, consumer.peerId!);
  }

  Future<MediaStream?> createAudioStream() async {
    audioInputDeviceId = mediaDeviceDataHolder!.selectedAudioInput!.deviceId;
    try {
      Map<String, dynamic> mediaConstraints = {
        "audio" : {
          "optional" : [{
            "sourceId" : audioInputDeviceId
          }]
        }
      };
      MediaStream audioStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      return audioStream;
    } catch (error) {
      return null;
    }
  }

  Future<MediaStream?> createVideoStream() async {
    try {
      videoInputDeviceId = mediaDeviceDataHolder!.selectedVideoInput!.deviceId;
      Map<String, dynamic> mediaConstraints = <String, dynamic>{
        "audio" : false,
        "video" : {
          "optional" : [{
            "sourceId" : videoInputDeviceId
          }]
        }
      };
      MediaStream videoStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      return videoStream;
    } catch (error) {
      return null;
    }
  }

  Future<void> enableWebCam() async {
    if(_mediaDevice!.canProduce(RTCRtpMediaType.RTCRtpMediaTypeVideo) == false) return;

    MediaStream? videoStream;
    MediaStreamTrack? track;

    try {
      const videoVPVersion = 8;
      RtpCodecCapability? codec = _mediaDevice!.rtpCapabilities.codecs.firstWhere((RtpCodecCapability c) => 
        c.mimeType.toLowerCase() == 'video/vp$videoVPVersion', orElse: () => throw "desired vp$videoVPVersion codec+configuration is not supported"
      );
      videoStream = await createVideoStream();
      track = videoStream!.getVideoTracks().first;

      _sendTransport!.produce(
        track: track, 
        stream: videoStream, 
        codec: codec,
        codecOptions: ProducerCodecOptions(
          videoGoogleStartBitrate: 1000
        ),
        encodings: [ RtpEncodingParameters(scalabilityMode: "L1T3", scaleResolutionDownBy: 1.0) ],
        appData: {"source" : "webcam"},
        source: "webcam"
      );
    } catch (error) {
      if(videoStream != null) await videoStream.dispose();
    }
  }

  Future<void> enableMic() async {
    if(_mediaDevice!.canProduce(RTCRtpMediaType.RTCRtpMediaTypeAudio) == false) return;

    MediaStream? audioStream;
    MediaStreamTrack? track;

    try {
      audioStream = await createAudioStream();
      track = audioStream!.getAudioTracks().first;

      _sendTransport!.produce(
        track: track, 
        stream: audioStream, 
        codecOptions: ProducerCodecOptions(
          opusStereo: 1,
          opusDtx: 1
        ),
        appData: {"source" : "mic"},
        source: "mic"
      );
    } catch (error) {
      if(audioStream != null) await audioStream.dispose();
    }
  }

  Future<void> disableWebCam() async {
    String webcamId = producerDataHolder!.webcam!.id;
    producerDataHolder!.producerRemove("webcam");
    try {
      await _webSocket!.socket.request("closeProducer", {
        "producerId" : webcamId
      });
    } catch (error) {
      rethrow;
    }
  }

  Future<void> disableMic() async {
    String micId = producerDataHolder!.mic!.id;
    producerDataHolder!.producerRemove("mic");
    try {
      await _webSocket!.socket.request("closeProducer", {
        "producerId" : micId
      });
    } catch (error) {
      rethrow;
    }
  }

  Future<void> muteMic() async {
    producerDataHolder!.producerPause('mic');
    try {
      await _webSocket!.socket.request('pauseProducer', {
        'producerId': producerDataHolder!.mic!.id
      });
    } catch (error) {
      // error process
    }
  }

  Future<void> unmuteMic() async {
    producerDataHolder!.producerResume('mic');
    try {
      await _webSocket!.socket.request('resumeProducer', {
        'producerId': producerDataHolder!.mic!.id,
      });
    } catch (error) {
      // error process
    }
  }

  void close() {
    if (_closed) return;
    _webSocket?.close();
    _sendTransport?.close();
    _recvTransport?.close();
    _closed = true;
  }




}