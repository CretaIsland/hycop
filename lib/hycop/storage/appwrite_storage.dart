

import 'dart:typed_data';

import 'package:hycop/hycop/hycop_factory.dart';

import '../../common/util/config.dart';
import '../../hycop/utils/hycop_exceptions.dart';
import '../enum/model_enums.dart';
import '../../hycop/storage/abs_storage.dart';
import '../../hycop/storage/storage_utils.dart';
import '../model/file_model.dart';

// ignore: depend_on_referenced_packages
import 'package:appwrite/appwrite.dart';
// ignore: depend_on_referenced_packages
import 'package:dart_appwrite/dart_appwrite.dart' as aw_server;

class AppwriteStorage extends AbsStorage {

  Storage? _storage;
  aw_server.Storage? _serverStorage;



  @override
  Future<void> initialize() async {
    if(AbsStorage.awStorageConn == null) {
      HycopFactory.initAll();
      AbsStorage.setAppwriteApp(Client()
        ..setEndpoint(myConfig!.serverConfig!.storageConnInfo.storageURL)
        ..setProject(myConfig!.serverConfig!.storageConnInfo.projectId)
        ..setSelfSigned(status: true)
      );
    
      _serverStorage = aw_server.Storage(aw_server.Client()
        ..setEndpoint(myConfig!.serverConfig!.storageConnInfo.storageURL)
        ..setProject(myConfig!.serverConfig!.storageConnInfo.projectId)
        ..setKey(myConfig!.serverConfig!.storageConnInfo.apiKey)
      );
    }

    
    // ignore: prefer_conditional_assignment, unnecessary_null_comparison
    if(_storage == null) {
      _storage = Storage(AbsStorage.awStorageConn!);
    }
    
    // setBucketId("userId");
  }

  @override
  Future<FileModel?> uploadFile(String fileName, String fileType, Uint8List fileBytes) async {
    await initialize();

    String fileId = StorageUtils.cidToKey(StorageUtils.genCid(ContentsType.getContentTypes(fileType)));

    await _storage!.createFile(
      bucketId: myConfig!.serverConfig!.storageConnInfo.bucketId,
      fileId: fileId, 
      file: InputFile(filename: fileName, contentType: fileType, bytes: fileBytes)
    ).onError((error, stackTrace) => throw HycopException(message: stackTrace.toString()));

    return await getFileInfo(fileId);
  }

  @override
  Future<Uint8List> downloadFile(String fileId) async {
    await initialize();

    return await _storage!.getFileDownload(
      bucketId: myConfig!.serverConfig!.storageConnInfo.bucketId, 
      fileId: fileId
    ).onError((error, stackTrace) => throw HycopException(message: stackTrace.toString()));
  }

  @override
  Future<void> deleteFile(String fileId) async {
    await initialize();

    await _storage!.deleteFile(
      bucketId: myConfig!.serverConfig!.storageConnInfo.bucketId, 
      fileId: fileId
    ).onError((error, stackTrace) => throw HycopException(message: stackTrace.toString()));
  }

  @override
  Future<FileModel> getFileInfo(String fileId) async {
    await initialize();

    final res = await _storage!.getFile(
      bucketId: myConfig!.serverConfig!.storageConnInfo.bucketId, 
      fileId: fileId
    ).onError((error, stackTrace) => throw HycopException(message: stackTrace.toString()));

    return FileModel(
      fileId: res.$id,
      fileName: res.name,
      fileView:  await _storage!.getFileView(bucketId: myConfig!.serverConfig!.storageConnInfo.bucketId, fileId: res.$id),
      fileMd5: res.signature,
      fileSize: res.sizeOriginal,
      fileType: ContentsType.getContentTypes(res.mimeType)
    );
  }

  @override
  Future<List<FileModel>> getFileInfoList({String? search, int? limit, int? offset, String? cursor, String? cursorDirection = "after", String? orderType = "DESC"}) async {
    List<FileModel> fileInfoList = [];

    await initialize();

    final res = await _storage!.listFiles(
      bucketId: myConfig!.serverConfig!.storageConnInfo.bucketId,
      search: search,
      limit: limit,
      offset: offset,
      cursor: cursor,
      cursorDirection: cursorDirection,
      orderType: orderType
    );

    for(var element in res.files) {

      Uint8List fileData =
        await _storage!.getFileView(bucketId: myConfig!.serverConfig!.storageConnInfo.bucketId, fileId: element.$id);

      fileInfoList.add(FileModel(
        fileId: element.$id,
        fileName: element.name,
        fileView: fileData, 
        fileMd5: element.signature,
        fileSize: element.sizeOriginal,
        fileType: ContentsType.getContentTypes(element.mimeType))
      );
    }
    return fileInfoList;
  }

  @override
  Future<void> setBucketId(String userId) async {
    await initialize();
    
    final res = await _serverStorage!.listBuckets();

    for(var element in res.buckets) {
      if(element.name == userId) {
        myConfig!.serverConfig!.storageConnInfo.bucketId = element.$id;
        return ;
      }
    }

     _serverStorage!.createBucket(
      bucketId: userId,
      name: userId,
      permission: 'bucket',
      read: ['role:member'],
      write: ['role:member']
    );

    myConfig!.serverConfig!.storageConnInfo.bucketId = userId;
    
  }










}