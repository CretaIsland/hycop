// ignore_for_file: depend_on_referenced_packages, prefer_const_constructors

import 'package:flutter/foundation.dart';
//import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';
import 'package:collection/collection.dart';
import 'enitity/peer.dart';

PeersData? peersDataHolder;

class PeersData extends ChangeNotifier {
  Map<String, Peer> peers = {};

  void peerAdd(Map<String, dynamic> peer) {
    final Peer newPeer = Peer.fromMap(peer);
    peers[newPeer.id] = newPeer;
    notifyListeners();
  }

  void peerRemove(String peerId) {
    peers.remove(peerId);
    notifyListeners();
  }

  Future<void> consumerAdd(Consumer consumer, String peerId) async {
    if (kIsWeb) {
      if (peers[peerId]!.renderer == null) {
        peers[peerId] = peers[peerId]!.copyWith(renderer: RTCVideoRenderer());
        await peers[peerId]!.renderer!.initialize();
      }

      if (consumer.kind == 'video') {
        peers[peerId] = peers[peerId]!.copyWith(video: consumer);
        peers[peerId]!.renderer!.srcObject = peers[peerId]!.video!.stream;
      }

      if (consumer.kind == 'audio') {
        peers[peerId] = peers[peerId]!.copyWith(audio: consumer);
        if (peers[peerId]!.video == null) {
          peers[peerId]!.renderer!.srcObject = peers[peerId]!.audio!.stream;
        }
      }
    } else {
      if (consumer.kind == 'video') {
        peers[peerId] = peers[peerId]!.copyWith(
          renderer: RTCVideoRenderer(),
          video: consumer,
        );
        await peers[peerId]!.renderer!.initialize();
        peers[peerId]!.renderer!.srcObject = peers[peerId]!.video!.stream;
      } else {
        peers[peerId] = peers[peerId]!.copyWith(audio: consumer);
      }
    }
    notifyListeners();
  }

  Future<void> consumerRemove(String consumerId) async {
    final Peer? peer = peers.values.firstWhereOrNull((p) => p.consumers.contains(consumerId));

    if (peer != null) {
      if (kIsWeb) {
        if (peer.audio?.id == consumerId) {
          final consumer = peer.audio;
          if (peer.video == null) {
            final renderer = peers[peer.id]?.renderer!;
            peers[peer.id] = peers[peer.id]!.removeAudioAndRenderer();
            await Future.delayed(Duration(microseconds: 300));
            await renderer?.dispose();
          } else {
            peers[peer.id] = peers[peer.id]!.removeAudio();
          }
          await consumer?.close();
        } else if (peer.video?.id == consumerId) {
          final consumer = peer.video;
          if (peer.audio != null) {
            peers[peer.id]!.renderer!.srcObject = peers[peer.id]!.audio!.stream;
            peers[peer.id] = peers[peer.id]!.removeVideo();
          } else {
            final renderer = peers[peer.id]!.renderer!;
            peers[peer.id] = peers[peer.id]!.removeVideoAndRenderer();
            await renderer.dispose();
          }
          await consumer?.close();
        }
      } else {
        if (peer.audio?.id == consumerId) {
          final consumer = peer.audio;
          peers[peer.id] = peers[peer.id]!.removeAudio();
          await consumer?.close();
        } else if (peer.video?.id == consumerId) {
          final consumer = peer.video;
          final renderer = peer.renderer;
          peers[peer.id] = peers[peer.id]!.removeVideoAndRenderer();
          consumer
              ?.close()
              .then((_) => Future.delayed(Duration(microseconds: 300)))
              .then((_) async => await renderer?.dispose());
        }
      }
    }
    notifyListeners();
  }

  void peerPausedConsumer(String consumerId) {
    final Peer? peer = peers.values.firstWhereOrNull((p) => p.consumers.contains(consumerId));
    if (peer != null) {
      peers[peer.id] = peers[peer.id]!.copyWith(audio: peer.audio!.pauseCopy());
    }
    notifyListeners();
  }

  void peerResumedConsumer(String consumerId) {
    final Peer? peer = peers.values.firstWhereOrNull((p) => p.consumers.contains(consumerId));
    if (peer != null) {
      peers[peer.id] = peers[peer.id]!.copyWith(audio: peer.audio!.resumeCopy());
    }
    notifyListeners();
  }

  Future<void> close() async {
    for (var peer in peers.values) {
      peer.renderer?.dispose();
    }
  }
}
