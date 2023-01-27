// ignore_for_file: prefer_final_fields, avoid_print

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hycop/hycop/webrtc/media_devices/media_devices_data.dart';
import 'package:hycop/hycop/webrtc/peers/peers_data.dart';
import 'package:hycop/hycop/webrtc/producers/producers_data.dart';
import 'package:hycop/hycop/webrtc/websocket.dart';
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';

WebRTCClient? webRTCClient;

class WebRTCClient {
  final String roomId;
  final String peerId;
  final String url;
  final String displayName;

  bool _closed = false;

  WebSocket? _webSocket;
  Device? _mediasoupDevice;
  Transport? _sendTransport;
  Transport? _recvTransport;
  bool _produce = false;
  bool _consume = true;
  String? audioInputDeviceId;
  String? audioOutputDeviceId;
  String? videoInputDeviceId;

  WebRTCClient(
      {required this.roomId, required this.peerId, required this.url, required this.displayName}) {
    join();
  }

  void close() {
    if (_closed) return;
    _webSocket?.close();
    _sendTransport?.close();
    _recvTransport?.close();
  }

  Future<void> disableMic() async {
    String micId = producerDataHolder!.mic!.id;
    producerDataHolder!.producerRemove('mic');
    try {
      await _webSocket!.socket.request('closeProducer', {
        'producerId': micId,
      });
    } catch (error) {
      // catch something
    }
  }

  Future<void> disableWebcam() async {
    String webcamId = producerDataHolder!.webcam!.id;
    producerDataHolder!.producerRemove('webcam');
    try {
      await _webSocket!.socket.request('closeProducer', {
        'producerId': webcamId,
      });
    } catch (error) {
      // error process
    }
  }

  Future<void> muteMic() async {
    producerDataHolder!.producerPause('mic');
    try {
      await _webSocket!.socket
          .request('pauseProducer', {'producerId': producerDataHolder!.mic!.id});
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

  Future<MediaStream> createAudioStream() async {
    audioInputDeviceId = mediaDeviceDataHolder!.selectedAudioInput!.deviceId;
    Map<String, dynamic> mediaConstraints = {
      'audio': {
        'optional': [
          {
            'sourceId': audioInputDeviceId,
          },
        ],
      },
    };
    MediaStream stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    return stream;
  }

  Future<MediaStream?> createVideoStream() async {
    try {
      videoInputDeviceId = mediaDeviceDataHolder!.selectedVideoInput!.deviceId;
      Map<String, dynamic> mediaConstraints = <String, dynamic>{
        'audio': false,
        'video': {
          'optional': [
            {
              'sourceId': videoInputDeviceId,
            },
          ],
        },
      };
      MediaStream stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      return stream;
    } catch (error) {
      //print(error);
      // error process
    }
    return null;
  }

  Future<void> enableWebcam() async {
    if (_mediasoupDevice!.canProduce(RTCRtpMediaType.RTCRtpMediaTypeVideo) == false) return;
    MediaStream? videoStream;
    MediaStreamTrack? track;
    try {
      const videoVPVersion = kIsWeb ? 9 : 8;
      RtpCodecCapability? codec = _mediasoupDevice!.rtpCapabilities.codecs.firstWhere(
          (RtpCodecCapability c) => c.mimeType.toLowerCase() == 'video/vp$videoVPVersion',
          orElse: () => throw 'desired vp$videoVPVersion codec+configuration is not supported');
      videoStream = await createVideoStream();
      track = videoStream!.getVideoTracks().first;
      _sendTransport!.produce(
        track: track,
        codecOptions: ProducerCodecOptions(
          videoGoogleStartBitrate: 1000,
        ),
        encodings: kIsWeb
            ? [
                RtpEncodingParameters(scalabilityMode: 'S3T3_KEY', scaleResolutionDownBy: 1.0),
              ]
            : [],
        stream: videoStream,
        appData: {
          'source': 'webcam',
        },
        source: 'webcam',
        codec: codec,
      );
    } catch (error) {
      print(error);
      if (videoStream != null) {
        await videoStream.dispose();
      }
    }
  }

  Future<void> enableMic() async {
    if (_mediasoupDevice!.canProduce(RTCRtpMediaType.RTCRtpMediaTypeAudio) == false) return;

    MediaStream? audioStream;
    MediaStreamTrack? track;
    try {
      audioStream = await createAudioStream();
      track = audioStream.getAudioTracks().first;
      _sendTransport!.produce(
        track: track,
        codecOptions: ProducerCodecOptions(opusStereo: 1, opusDtx: 1),
        stream: audioStream,
        appData: {
          'source': 'mic',
        },
        source: 'mic',
      );
    } catch (error) {
      if (audioStream != null) {
        await audioStream.dispose();
      }
    }
  }

  Future<void> _joinRoom() async {
    try {
      _mediasoupDevice = Device();

      dynamic routerRtpCapabilities =
          await _webSocket!.socket.request('getRouterRtpCapabilities', {});
      final rtpCapabilities = RtpCapabilities.fromMap(routerRtpCapabilities);
      rtpCapabilities.headerExtensions.removeWhere((he) => he.uri == 'urn:3gpp:video-orientation');
      await _mediasoupDevice!.load(routerRtpCapabilities: rtpCapabilities);

      if (_mediasoupDevice!.canProduce(RTCRtpMediaType.RTCRtpMediaTypeAudio) == true ||
          _mediasoupDevice!.canProduce(RTCRtpMediaType.RTCRtpMediaTypeVideo) == true) {
        _produce = true;
      }

      if (_produce) {
        Map transportInfo = await _webSocket!.socket.request('createWebRtcTransport', {
          'forceTcp': false,
          'producing': true,
          'consuming': false,
          'sctpCapabilities': _mediasoupDevice!.sctpCapabilities.toMap(),
        });

        _sendTransport = _mediasoupDevice!.createSendTransportFromMap(
          transportInfo,
          producerCallback: _producerCallback,
        );

        _sendTransport!.on('connect', (Map data) {
          _webSocket!.socket
              .request('connectWebRtcTransport', {
                'transportId': _sendTransport!.id,
                'dtlsParameters': data['dtlsParameters'].toMap(),
              })
              .then(data['callback'])
              .catchError(data['errback']);
        });

        _sendTransport!.on('produce', (Map data) async {
          try {
            Map response = await _webSocket!.socket.request(
              'produce',
              {
                'transportId': _sendTransport!.id,
                'kind': data['kind'],
                'rtpParameters': data['rtpParameters'].toMap(),
                if (data['appData'] != null) 'appData': Map<String, dynamic>.from(data['appData'])
              },
            );

            data['callback'](response['id']);
          } catch (error) {
            data['errback'](error);
          }
        });

        _sendTransport!.on('producedata', (data) async {
          try {
            Map response = await _webSocket!.socket.request('produceData', {
              'transportId': _sendTransport!.id,
              'sctpStreamParameters': data['sctpStreamParameters'].toMap(),
              'label': data['label'],
              'protocol': data['protocol'],
              'appData': data['appData'],
            });

            data['callback'](response['id']);
          } catch (error) {
            data['errback'](error);
          }
        });
      }

      if (_consume) {
        Map transportInfo = await _webSocket!.socket.request(
          'createWebRtcTransport',
          {
            'forceTcp': false,
            'producing': false,
            'consuming': true,
            'sctpCapabilities': _mediasoupDevice!.sctpCapabilities.toMap(),
          },
        );

        _recvTransport = _mediasoupDevice!.createRecvTransportFromMap(
          transportInfo,
          consumerCallback: _consumerCallback,
        );

        _recvTransport!.on(
          'connect',
          (data) {
            _webSocket!.socket
                .request(
                  'connectWebRtcTransport',
                  {
                    'transportId': _recvTransport!.id,
                    'dtlsParameters': data['dtlsParameters'].toMap(),
                  },
                )
                .then(data['callback'])
                .catchError(data['errback']);
          },
        );
      }

      Map response = await _webSocket!.socket.request('join', {
        'displayName': displayName,
        'device': {
          'name': "Flutter",
          'flag': 'flutter',
          'version': '0.8.0',
        },
        'rtpCapabilities': _mediasoupDevice!.rtpCapabilities.toMap(),
        'sctpCapabilities': _mediasoupDevice!.sctpCapabilities.toMap(),
      });

      response['peers'].forEach((value) {
        peersDataHolder!.peerAdd(value);
      });

      if (_produce) {
        enableMic();
        enableWebcam();
      }
    } catch (error) {
      print(error);
      close();
    }
  }

  void join() {
    _webSocket = WebSocket(
      peerId: peerId,
      roomId: roomId,
      url: url,
    );

    _webSocket!.onOpen = _joinRoom;
    _webSocket!.onFail = () {
      print('WebSocket connection failed');
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

    _webSocket!.onRequest = (request, accept, reject) async {
      switch (request['method']) {
        case 'newConsumer':
          {
            if (!_consume) {
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
              print('newConsumer request failed: $error');
              rethrow;
            }
            break;
          }
        default:
          break;
      }
    };

    _webSocket!.onNotification = (notification) async {
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
}
