import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:hycop/common/util/logger.dart';
import 'package:hycop/hycop/account/account_manager.dart';
// import 'package:logging/logging.dart';

import '../../common/util/config.dart';
import '../../hycop/utils/hycop_exceptions.dart';
import '../enum/model_enums.dart';
import '../../hycop/storage/abs_storage.dart';
//import '../hycop_factory.dart';
import '../model/file_model.dart';

// ignore: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_storage/firebase_storage.dart';

import '../utils/hycop_utils.dart';

class FirebaseAppStorage extends AbsStorage {
  FirebaseStorage? _storage;

  @override
  Future<void> initialize() async {
    if (AbsStorage.fbStorageConn == null) {
      //await HycopFactory.initAll();
      logger.info("storage initialize");

      AbsStorage.setFirebaseApp(await Firebase.initializeApp(
          name: 'storage',
          options: FirebaseOptions(
              apiKey: myConfig!.serverConfig!.storageConnInfo.apiKey,
              appId: myConfig!.serverConfig!.storageConnInfo.appId,
              messagingSenderId: myConfig!.serverConfig!.storageConnInfo.messagingSenderId,
              projectId: myConfig!.serverConfig!.storageConnInfo.projectId,
              storageBucket: myConfig!.serverConfig!.storageConnInfo.storageURL)));
    }

    // ignore: prefer_conditional_assignment, unnecessary_null_comparison
    if (_storage == null) {
      logger.info("_storage init");
      _storage = FirebaseStorage.instanceFor(app: AbsStorage.fbStorageConn);
    }
  }

  @override
  Future<FileModel?> uploadFile(String fileName, String fileType, Uint8List fileBytes) async {
    await initialize();

    final uploadFile =
        _storage!.ref().child("${myConfig!.serverConfig!.storageConnInfo.bucketId}$fileName");

    try {
      // 해당 파일이 이미 있으면 파일 리턴
      return await getFileInfo(uploadFile.fullPath);
    } catch (e) {
      // 해당 파일이 없으면 업로드 후 리턴
      await uploadFile.putData(fileBytes).onError((error, stackTrace) {
        throw HycopException(message: stackTrace.toString());
      });
      await uploadFile
          .updateMetadata(SettableMetadata(contentType: fileType))
          .onError((error, stackTrace) {
        throw HycopException(message: stackTrace.toString());
      });

      // 영상이라면 썸네일 추출
      if(fileType.contains("video")) {
        await createThumbnail(fileName);
      }

      return await getFileInfo("${myConfig!.serverConfig!.storageConnInfo.bucketId}$fileName");
    }
  }

  @override
  Future<Uint8List> downloadFile(String fileId) async {
    await initialize();

    Uint8List? fileBytes = await _storage!
        .ref()
        .child(fileId)
        .getData()
        .onError((error, stackTrace) => throw HycopException(message: stackTrace.toString()));

    return fileBytes!;
  }

  @override
  Future<void> deleteFile(String fileId) async {
    await initialize();

    await _storage!
        .ref()
        .child(fileId)
        .delete()
        .onError((error, stackTrace) => throw HycopException(message: stackTrace.toString()));
  }

  @override
  Future<FileModel> getFileInfo(String fileId) async {
    await initialize();

    final res = await _storage!.ref().child(fileId).getMetadata().onError((error, stackTrace) {
      throw HycopException(message: stackTrace.toString());
    });

    String fileView = await _storage!.ref().child(res.fullPath).getDownloadURL();

    // 영상이라면 썸네일 url 가져오기
    if(ContentsType.getContentTypes(res.contentType!) == ContentsType.video) {

      String fileName = fileId.substring(fileId.indexOf("/")+1, fileId.lastIndexOf("."));

      final thumbnailRes = await _storage!.ref().child("${fileId.substring(0, fileId.indexOf("/"))}/thumbnail_$fileName.jpg").getMetadata().onError((error, stackTrace) {
        createThumbnail(fileId.substring(fileId.indexOf("/")));
        throw HycopException(message: stackTrace.toString());
      });

      return FileModel(
        fileId: res.fullPath,
        fileName: res.name,
        fileView: fileView,
        thumbnailUrl: await _storage!.ref().child(thumbnailRes.fullPath).getDownloadURL(),
        fileMd5: res.md5Hash!,
        fileSize: res.size!,
        fileType: ContentsType.getContentTypes(res.contentType!));
    } 

    return FileModel(
        fileId: res.fullPath,
        fileName: res.name,
        fileView: fileView,
        thumbnailUrl: fileView,
        fileMd5: res.md5Hash!,
        fileSize: res.size!,
        fileType: ContentsType.getContentTypes(res.contentType!));
  }

  @override
  Future<List<FileModel>> getFileInfoList(
      {String? search,
      int? limit,
      int? offset,
      String? cursor,
      String? cursorDirection = "after",
      String? orderType = "DESC"}) async {
    List<FileModel> fileInfoList = [];

    await initialize();

    final res = await _storage!
        .ref()
        .child(myConfig!.serverConfig!.storageConnInfo.bucketId)
        .list(ListOptions(maxResults: limit))
        .onError((error, stackTrace) {
      throw HycopException(
          message:
              '${myConfig!.serverConfig!.storageConnInfo.bucketId}:${error.toString()},\n${stackTrace.toString()}');
    });

    for (var element in res.items) {
      var fileData = await element.getMetadata();
      String fileView = await _storage!.ref().child(fileData.fullPath).getDownloadURL();

      if(ContentsType.getContentTypes(fileData.contentType!) == ContentsType.video) {
        
        String folderName = fileData.fullPath.substring(0, fileData.fullPath.indexOf("/"));
        String fileName = fileData.fullPath.substring(fileData.fullPath.indexOf("/")+1, fileData.fullPath.lastIndexOf("."));

        final thumbnailRes = await _storage!.ref().child("$folderName/thumbnail_$fileName.jpg").getMetadata().onError((error, stackTrace) async {
          logger.info(error);
          await createThumbnail(fileData.fullPath.substring(fileData.fullPath.indexOf("/")+1));
          return FullMetadata({"fullPath" : "$folderName/thumbnail_$fileName.jpg"});
          //throw HycopException(message: stackTrace.toString());
        });

        fileInfoList.add(FileModel(
          fileId: fileData.fullPath,
          fileName: fileData.name,
          fileView: fileView,
          thumbnailUrl: await _storage!.ref().child(thumbnailRes.fullPath).getDownloadURL(),
          fileMd5: fileData.md5Hash!,
          fileSize: fileData.size!,
          fileType: ContentsType.getContentTypes(fileData.contentType!)));

      } else {
        fileInfoList.add(FileModel(
          fileId: fileData.fullPath,
          fileName: fileData.name,
          fileView: fileView,
          thumbnailUrl: fileView,
          fileMd5: fileData.md5Hash!,
          fileSize: fileData.size!,
          fileType: ContentsType.getContentTypes(fileData.contentType!)));
      }
    }
    return fileInfoList;
  }

  @override
  Future<void> setBucketId() async {
    // await initialize();
    myConfig!.serverConfig!.storageConnInfo.bucketId =
        "${HycopUtils.genBucketId(AccountManager.currentLoginUser.email, AccountManager.currentLoginUser.userId)}/";
  }

  Future<void> createThumbnail(String fileName) async {
    try {
      await http.post(
        Uri.parse("https://devcreta.tk:447/createThumbnail"),
        headers: {"Content-type": "application/json"},
        body: jsonEncode({
          "userId" : myConfig!.serverConfig!.storageConnInfo.bucketId,
          "fileName" : fileName
        })
      );
    } catch (error) {
      logger.info(error);
    }
  }


}
