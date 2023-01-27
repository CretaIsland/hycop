// ignore_for_file: prefer_const_constructors_in_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:hycop/hycop/webrtc/peers/peers_data.dart';
import 'package:provider/provider.dart';

import 'remote_stream.dart';

class ListRemoteStreams extends StatelessWidget {
  final double screenHeight;
  final double screenWidth;
  ListRemoteStreams({Key? key, required this.screenHeight, required this.screenWidth})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider<PeersData>.value(value: peersDataHolder!)],
      child: Consumer<PeersData>(
        builder: (context, peersDataManager, child) {
          return SizedBox(
              width: screenWidth,
              height: screenHeight,
              child: peersDataManager.peers.isNotEmpty
                  ? ListView.builder(
                      itemCount: peersDataManager.peers.length,
                      itemBuilder: (context, index) {
                        String peerId = peersDataManager.peers.keys.elementAt(index);
                        return RemoteStream(
                            key: ValueKey(peerId),
                            peer: peersDataManager.peers[peerId]!,
                            screenHeight: screenHeight * .3,
                            screenWidth: screenWidth);
                      })
                  : SizedBox());
        },
      ),
    );
  }
}
