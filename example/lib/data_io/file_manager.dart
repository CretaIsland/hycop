import 'package:flutter/material.dart';
import 'package:hycop/common/util/config.dart';
import 'package:hycop/hycop/enum/model_enums.dart';
import 'package:hycop/hycop/hycop_factory.dart';
import 'package:hycop/hycop/model/file_model.dart';
// ignore: unnecessary_import
import 'package:flutter/foundation.dart';




FileManager? fileManagerHolder;

class FileManager extends ChangeNotifier {

  
  List<FileModel> imgFileList = [];
  List<FileModel> videoFileList = [];
  List<FileModel> etcFileList = [];



  void notify() => notifyListeners();

  Future<void> getImgFileList() async {

    imgFileList = [];
    
    final res = (await HycopFactory.storage!.getFileInfoList());
    for(var element in res) {
      if(element.fileType == ContentsType.image) {
        imgFileList.add(FileModel(fileId: element.fileId, fileName: element.fileName, fileView: element.fileView, thumbnailUrl: element.thumbnailUrl, fileMd5: element.fileMd5, fileSize: element.fileSize, fileType: element.fileType));
      }
    }
    notifyListeners();
  }

  Future<void> getVideoFileList() async {
    videoFileList = [];

    final res = await HycopFactory.storage!.getFileInfoList();
    for(var element in res) {
      if(element.fileType == ContentsType.video) {
        videoFileList.add(FileModel(fileId: element.fileId, fileName: element.fileName, fileView: element.fileView, thumbnailUrl: element.thumbnailUrl, fileMd5: element.fileMd5, fileSize: element.fileSize, fileType: element.fileType));
      }
    }
    notifyListeners();
  }

  Future<void> getEtcFileList() async {
    etcFileList = [];

    final res = await HycopFactory.storage!.getFileInfoList();
    for(var element in res) {
      if(element.fileType != ContentsType.image && element.fileType != ContentsType.video) {
        etcFileList.add(FileModel(fileId: element.fileId, fileName: element.fileName, fileView: element.fileView, thumbnailUrl: element.thumbnailUrl, fileMd5: element.fileMd5, fileSize: element.fileSize, fileType: element.fileType));
      }
    }
    notifyListeners();
  }

  ImageProvider<Object> getThumbnail(String fileId) {
    
    // get thumbnail logic
    // ignore: prefer_const_declarations
    final thumbnailView = null;

    if(thumbnailView == null) {
      return Image.asset("assets/video_icon.png").image;
    } else {
      if(HycopFactory.serverType == ServerType.appwrite) {
        return Image.memory(thumbnailView.fileView).image;
      }
       return NetworkImage(thumbnailView);
    }
  }

  Future<void> deleteFile(String fileId, ContentsType contentsType) async {
    await HycopFactory.storage!.deleteFile(fileId);
    switch(contentsType) {
      case ContentsType.image:
        imgFileList.removeWhere((element) => element.fileId == fileId);
        break;
      case ContentsType.video:
        videoFileList.removeWhere((element) => element.fileId == fileId);
        break;
      default: 
        etcFileList.removeWhere((element) => element.fileId == fileId);
        break;
    }
    notifyListeners();
  }


}