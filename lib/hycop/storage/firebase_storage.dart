import 'dart:typed_data';

import '../../common/util/config.dart';
import '../../hycop/utils/hycop_exceptions.dart';
import '../enum/model_enums.dart';
import '../../hycop/storage/abs_storage.dart';
import '../model/file_model.dart';

// ignore: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_storage/firebase_storage.dart';


class FirebaseAppStorage extends AbsStorage {

  late FirebaseStorage _storage;




  @override
  void initialize() async {

    AbsStorage.setFirebaseApp(await Firebase.initializeApp(
      name: 'storage',
      options: FirebaseOptions(
        apiKey: myConfig!.serverConfig!.storageConnInfo.apiKey,
        appId: myConfig!.serverConfig!.storageConnInfo.appId,
        messagingSenderId: myConfig!.serverConfig!.storageConnInfo.messagingSenderId,
        projectId: myConfig!.serverConfig!.storageConnInfo.projectId,
        storageBucket: myConfig!.serverConfig!.storageConnInfo.storageURL
      )
    ));

    _storage = FirebaseStorage.instanceFor(app: AbsStorage.fbStorageConn);
    setBucketId("userId1");
    
  }

  @override
  Future<void> uploadFile(String fileName, String fileType, Uint8List fileBytes) async {
    final uploadFile = _storage.ref().child("${myConfig!.serverConfig!.storageConnInfo.bucketId}/$fileName");

    try {
      await uploadFile.getDownloadURL();
    } catch (e) {
      await uploadFile.putData(fileBytes).onError((error, stackTrace) {
        throw HycopException(message: stackTrace.toString());
      });
      await uploadFile.updateMetadata(SettableMetadata(contentType: fileType)).onError((error, stackTrace) {
        throw HycopException(message: stackTrace.toString());
      });
    }
  }

  @override
  Future<Uint8List> downloadFile(String fileId) async {
    Uint8List? fileBytes = await _storage.ref().child(fileId).getData().onError((error, stackTrace)
     => throw HycopException(message: stackTrace.toString()));

    return fileBytes!;
  }

  @override
  Future<void> deleteFile(String fileId) async {
   await _storage.ref().child(fileId).delete().onError((error, stackTrace)
     => throw HycopException(message: stackTrace.toString()));
  }

  @override
  Future<FileModel> getFileInfo(String fileId) async {
    final res = await _storage.ref().child(fileId).getMetadata().onError((error, stackTrace) {
      throw HycopException(message: stackTrace.toString());
    });
    return FileModel(
      fileId: res.name, 
      fileName: res.name, 
      fileView: await _storage.ref().child(res.fullPath).getDownloadURL(), 
      fileMd5: res.md5Hash!, 
      fileSize: res.size!, 
      fileType: ContentsType.getContentTypes(res.contentType!)
    );
  }

  @override
  Future<List<FileModel>> getFileInfoList({String? search, int? limit, int? offset, String? cursor, String? cursorDirection = "after", String? orderType = "DESC"}) async {
    List<FileModel> fileInfoList = [];

    final res = await _storage.ref().child(myConfig!.serverConfig!.storageConnInfo.bucketId).list(
      ListOptions(
        maxResults: limit
      )
    ).onError((error, stackTrace) {
      throw HycopException(message: stackTrace.toString());
    });

    for(var element in res.items) {
      var fileData = await element.getMetadata();
      fileInfoList.add(FileModel(
        fileId: fileData.fullPath, 
        fileName: fileData.name, 
        fileView: await _storage.ref().child(fileData.fullPath).getDownloadURL(), 
        fileMd5: fileData.md5Hash!, 
        fileSize: fileData.size!, 
        fileType: ContentsType.getContentTypes(fileData.contentType!))
      );
    }
    return fileInfoList;
  }

  @override
  Future<void> setBucketId(String userId) async {
    myConfig!.serverConfig!.storageConnInfo.bucketId = userId;
  }





}