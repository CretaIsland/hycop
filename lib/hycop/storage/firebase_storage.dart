import 'dart:typed_data';

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
      await getFileInfo(uploadFile.fullPath);
    } catch (e) {
      await uploadFile.putData(fileBytes).onError((error, stackTrace) {
        throw HycopException(message: stackTrace.toString());
      });
      await uploadFile
          .updateMetadata(SettableMetadata(contentType: fileType))
          .onError((error, stackTrace) {
        throw HycopException(message: stackTrace.toString());
      });
      return await getFileInfo("${myConfig!.serverConfig!.storageConnInfo.bucketId}$fileName");
    }
    return null;
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
    return FileModel(
        fileId: res.fullPath,
        fileName: res.name,
        fileView: await _storage!.ref().child(res.fullPath).getDownloadURL(),
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
      fileInfoList.add(FileModel(
          fileId: fileData.fullPath,
          fileName: fileData.name,
          fileView: await _storage!.ref().child(fileData.fullPath).getDownloadURL(),
          fileMd5: fileData.md5Hash!,
          fileSize: fileData.size!,
          fileType: ContentsType.getContentTypes(fileData.contentType!)));
    }
    return fileInfoList;
  }

  @override
  Future<void> setBucketId() async {
    // await initialize();
    myConfig!.serverConfig!.storageConnInfo.bucketId =
        "${HycopUtils.genBucketId(AccountManager.currentLoginUser.email, AccountManager.currentLoginUser.userId)}/";
  }
}
