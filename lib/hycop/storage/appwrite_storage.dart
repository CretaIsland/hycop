import 'dart:typed_data';

import 'package:dart_appwrite/models.dart';
import 'package:hycop/hycop/account/account_manager.dart';
//import 'package:hycop/hycop/hycop_factory.dart';
import 'package:hycop/hycop/utils/hycop_utils.dart';

import '../../common/util/config.dart';
import '../../common/util/logger.dart';
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
  late aw_server.Storage _serverStorage;

  @override
  Future<void> initialize() async {
    if (AbsStorage.awStorageConn == null) {
      //await HycopFactory.initAll();
      AbsStorage.setAppwriteApp(Client()
        ..setEndpoint(myConfig!.serverConfig!.storageConnInfo.storageURL)
        ..setProject(myConfig!.serverConfig!.storageConnInfo.projectId)
        ..setSelfSigned(status: true));
      logger.info('aw_server storage initialize start--------------------');
      _serverStorage = aw_server.Storage(aw_server.Client()
        ..setEndpoint(myConfig!.serverConfig!.storageConnInfo.storageURL)
        ..setProject(myConfig!.serverConfig!.storageConnInfo.projectId)
        ..setKey(myConfig!.serverConfig!.storageConnInfo.apiKey));
      logger.info('aw_server storage initialize end--------------------');
    }

    // ignore: prefer_conditional_assignment, unnecessary_null_comparison
    if (_storage == null) {
      _storage = Storage(AbsStorage.awStorageConn!);
    }

    // setBucketId("userId");
  }

  @override
  Future<FileModel?> uploadFile(String fileName, String fileType, Uint8List fileBytes,
      {bool makeThumbnail = false, String folderName = "content/"}) async {
    await initialize();

    String fileId =
        StorageUtils.cidToKey(StorageUtils.genCid(ContentsType.getContentTypes(fileType)));

    await _storage!
        .createFile(
            bucketId: myConfig!.serverConfig!.storageConnInfo.bucketId,
            fileId: fileId,
            //skpark 20231031 InputFile --> InputFile.fromBytes
            file: InputFile.fromBytes(filename: fileName, contentType: fileType, bytes: fileBytes))
        .onError((error, stackTrace) => throw HycopException(message: stackTrace.toString()));

    return await getFileInfo(fileId);
  }

  @override
  Future<Uint8List> downloadFile(String fileId) async {
    await initialize();

    return await _storage!
        .getFileDownload(bucketId: myConfig!.serverConfig!.storageConnInfo.bucketId, fileId: fileId)
        .onError((error, stackTrace) => throw HycopException(message: stackTrace.toString()));
  }

  @override
  Future<void> deleteFile(String fileId) async {
    await initialize();

    await _storage!
        .deleteFile(bucketId: myConfig!.serverConfig!.storageConnInfo.bucketId, fileId: fileId)
        .onError((error, stackTrace) => throw HycopException(message: stackTrace.toString()));
  }

  @override
  Future<FileModel> getFileInfo(String fileId) async {
    await initialize();

    final res = await _storage!
        .getFile(bucketId: myConfig!.serverConfig!.storageConnInfo.bucketId, fileId: fileId)
        .onError((error, stackTrace) => throw HycopException(message: stackTrace.toString()));

    return FileModel(
        fileId: res.$id,
        fileName: res.name,
        fileView: await _storage!.getFileView(
            bucketId: myConfig!.serverConfig!.storageConnInfo.bucketId, fileId: res.$id),
        thumbnailUrl: "",
        fileMd5: res.signature,
        fileSize: res.sizeOriginal,
        fileType: ContentsType.getContentTypes(res.mimeType));
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

    List<String> queries = [];
    if (limit != null) {
      queries.add(Query.limit(limit));
    }
    if (offset != null) {
      queries.add(Query.offset(offset));
    }
    if (cursor != null) {
      queries
          .add(cursorDirection == 'after' ? Query.cursorAfter(cursor) : Query.cursorBefore(cursor));
    }
    if (orderType != null) {
      queries.add(
          orderType == 'DESC' ? Query.orderDesc('\$updatedAt') : Query.orderAsc('\$updatedAt'));
    }

    final res = await _storage!.listFiles(
      bucketId: myConfig!.serverConfig!.storageConnInfo.bucketId,
      search: search,
      queries: queries,
      //limit: limit,
      //offset: offset,
      //cursor: cursor,
      //cursorDirection: cursorDirection,
      //orderType: orderType
    );

    for (var element in res.files) {
      Uint8List fileData = await _storage!.getFileView(
          bucketId: myConfig!.serverConfig!.storageConnInfo.bucketId, fileId: element.$id);

      fileInfoList.add(FileModel(
          fileId: element.$id,
          fileName: element.name,
          fileView: fileData,
          thumbnailUrl: "",
          fileMd5: element.signature,
          fileSize: element.sizeOriginal,
          fileType: ContentsType.getContentTypes(element.mimeType)));
    }
    return fileInfoList;
  }

  @override
  Future<void> setBucketId() async {
    // await initialize();
    logger.info('-----setBucketId()');
    String bucketId = HycopUtils.genBucketId(
        AccountManager.currentLoginUser.email, AccountManager.currentLoginUser.userId);
    // final res = await _serverStorage.listBuckets();
    //
    // for (var element in res.buckets) {
    //   if (element.name == bucketId) {
    //     myConfig!.serverConfig!.storageConnInfo.bucketId = element.$id;
    //     return;
    //   }
    // }
    try {
      final res = await _serverStorage.getBucket(bucketId: bucketId);
      if (res.name.isNotEmpty) {
        myConfig!.serverConfig!.storageConnInfo.bucketId = bucketId;
        return;
      }
    } catch (e) {
      // not exist bucketId ==> createBucket
    }
    logger.info('-----try to create bucket=$bucketId');
    Bucket bucket = await _serverStorage.createBucket(
      bucketId: bucketId,
      name: AccountManager.currentLoginUser.email,
      // permission: 'bucket',
      // read: ['role:member'],
      // write: ['role:member'],
      //skpark 20231031 new version 에서 permitisions format  이 바뀜.
      permissions: [
        Permission.read(Role.users()), //  이 부분을 user 로 바꿔야 할 가능성이 많다.
        Permission.write(Role.users()), // 이 부분을  user 로 바꿔야 할 가능서이 많다.
      ],
    );

    logger.info('-----bucket newly created=${bucket.$id}');

    myConfig!.serverConfig!.storageConnInfo.bucketId = bucketId;
  }
}
