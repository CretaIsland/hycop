import 'dart:convert';
import 'dart:typed_data';


import 'package:appwrite/models.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;
import 'package:appwrite/appwrite.dart';
import 'package:dart_appwrite/dart_appwrite.dart' as dart_appwrite;
import 'package:hycop/common/util/config.dart';
import 'package:hycop/common/util/logger.dart';
import 'package:hycop/hycop/account/account_manager.dart';
import 'package:hycop/hycop/enum/model_enums.dart';
import 'package:hycop/hycop/model/file_model.dart';
import 'package:hycop/hycop/storage/abs_storage.dart';
import 'package:hycop/hycop/storage/storage_utils.dart';


class AppwriteStorage extends AbsStorage {

  Storage? _storage;
  late dart_appwrite.Storage _awStorage;
  String fileUrl = "${myConfig!.serverConfig!.storageConnInfo.storageURL}/storage/buckets/{BUCKET_ID}/files/{FILE_ID}/view?project=${myConfig!.serverConfig!.storageConnInfo.projectId}";


  @override
  Future<void> initialize() async {
    if(AbsStorage.awStorageConn == null) {
      AbsStorage.setAppwriteApp(Client()
        ..setEndpoint(myConfig!.serverConfig!.storageConnInfo.storageURL)
        ..setProject(myConfig!.serverConfig!.storageConnInfo.projectId)
        ..setSelfSigned(status: true)
      );
      _awStorage = dart_appwrite.Storage(dart_appwrite.Client()
        ..setEndpoint(myConfig!.serverConfig!.storageConnInfo.storageURL)
        ..setProject(myConfig!.serverConfig!.storageConnInfo.projectId)
        ..setKey(myConfig!.serverConfig!.storageConnInfo.apiKey)
      );
    }
    _storage ??= Storage(AbsStorage.awStorageConn!);
  }


  @override
  Future<FileModel?> uploadFile(String fileName, String fileType, Uint8List fileBytes, {bool makeThumbnail = false, String fileUsage = "content"}) async {
    fileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣.]'), "_");
    if(fileUsage == "content") {
      if(fileType.contains("image")) {
        fileUsage = "img-";
      } else if(fileType.contains("video")) {
        fileUsage = "vid-";
      } else {
        fileUsage = "etc-";
      }
    } else if (fileUsage == "profile") {
      fileUsage = "pic-";
    } else if (fileUsage == "banner") {
      fileUsage = "ad-";
    } else if (fileUsage == "bookThumbnail") {
      var thumbnailFiles = await _storage!.listFiles(bucketId: myConfig!.serverConfig!.storageConnInfo.bucketId, search: fileName).onError((error, stackTrace) {
        return FileList(total: 0, files: List.empty());
      });

      for(var thumbnail in thumbnailFiles.files) {
        await deleteFile(thumbnail.$id);
      }

      fileUsage = "img-";
    } else { //banner
      fileUsage = "";
    }
    String fileId = fileUsage + StorageUtils.getMD5(fileBytes);


    try {
      var targetFile = await getFile(fileId);
      if(targetFile != null) {
        if(targetFile.thumbnailUrl == "" && (makeThumbnail || fileType.contains("video") || fileType.contains("pdf"))) {
         await createThumbnail(fileId, fileName, fileType);
        }
        return await getFile(fileId);
      } else {
        await _storage!.createFile(bucketId: myConfig!.serverConfig!.storageConnInfo.bucketId, fileId: fileId, file: InputFile.fromBytes(bytes: fileBytes, filename: fileName));
        if(makeThumbnail || fileType.contains("video") || fileType.contains("pdf")) {
          await createThumbnail(fileId, fileName, fileType);
        }
        return await getFile(fileId);
      }
    } catch (error) {
      logger.severe(error);
    }
    return null;
  }


  @override
  Future<void> deleteFile(String fileId) async {
    await _storage!.deleteFile(bucketId: myConfig!.serverConfig!.storageConnInfo.bucketId, fileId: fileId).onError((error, stackTrace) => logger.severe(error));
  }


  @override
  Future<Uint8List?> getFileBytes(String fileId) async {
    try {
      return await _storage!.getFileDownload(bucketId: myConfig!.serverConfig!.storageConnInfo.bucketId, fileId: fileId);
    } catch (error) {
      logger.severe(error);
    }
    return null;
  }


  @override
  Future<FileModel?> getFile(String fileId) async {
    try {
      await initialize();

      var targetFile = await _storage!.getFile(bucketId: myConfig!.serverConfig!.storageConnInfo.bucketId, fileId: fileId);
      try {
        var thumbnailFile = await _storage!.getFile(bucketId: myConfig!.serverConfig!.storageConnInfo.bucketId, fileId: "cov-${fileId.substring(4)}");
        return FileModel(
          id: targetFile.$id,
          name: targetFile.name,
          url: fileUrl.replaceAll("{BUCKET_ID}", myConfig!.serverConfig!.storageConnInfo.bucketId).replaceAll("{FILE_ID}", targetFile.$id),
          thumbnailUrl: fileUrl.replaceAll("{BUCKET_ID}", myConfig!.serverConfig!.storageConnInfo.bucketId).replaceAll("{FILE_ID}", thumbnailFile.$id),
          size: targetFile.sizeOriginal,
          contentType: ContentsType.getContentTypes(targetFile.mimeType)
        );
      } catch (thumbnailError) {
        return FileModel(
          id: targetFile.$id,
          name: targetFile.name,
          url: fileUrl.replaceAll("{BUCKET_ID}", myConfig!.serverConfig!.storageConnInfo.bucketId).replaceAll("{FILE_ID}", targetFile.$id),
          thumbnailUrl: fileUrl.replaceAll("{BUCKET_ID}", myConfig!.serverConfig!.storageConnInfo.bucketId).replaceAll("{FILE_ID}", targetFile.$id),
          size: targetFile.sizeOriginal,
          contentType: ContentsType.getContentTypes(targetFile.mimeType)
        );
      }
    } catch (error) {
      logger.info(error);
    }
    return null;
  }


  @override
  Future<List<FileModel>?> getFileList({String search = "", int limit = 99, int? offset, String? cursor, String cursorDirection = "after", String orderType = "DESC"}) async {
    List<FileModel> fileList = [];

    try {
      await initialize();
      List<String> queries = [];
      queries.add(Query.limit(limit));
      if(offset != null) queries.add(Query.offset(offset));
      if(cursor != null) queries.add(cursorDirection == "after" ? Query.cursorAfter(cursor) : Query.cursorBefore(cursor));
      queries.add(orderType == "DESC" ? Query.orderDesc("\$updateAt") : Query.orderAsc("\$updateAt"));

      final targetFileList = await _storage!.listFiles(bucketId: myConfig!.serverConfig!.storageConnInfo.bucketId, queries: queries, search: search);
      for(var targetFile in targetFileList.files) {
        try {
          var thumbnailFile = await _storage!.getFile(bucketId: myConfig!.serverConfig!.storageConnInfo.bucketId, fileId: "cov${targetFile.$id.substring(4)}");
          fileList.add(FileModel(
            id: targetFile.$id, 
            name: targetFile.name, 
            url: fileUrl.replaceAll("{BUCKET_ID}", myConfig!.serverConfig!.storageConnInfo.bucketId).replaceAll("{FILE_ID}", targetFile.$id), 
            thumbnailUrl: fileUrl.replaceAll("{BUCKET_ID}", myConfig!.serverConfig!.storageConnInfo.bucketId).replaceAll("{FILE_ID}", thumbnailFile.$id),
            size: targetFile.sizeOriginal, 
            contentType: ContentsType.getContentTypes(targetFile.mimeType)
          ));
        } catch (thumbnailError) {
          fileList.add(FileModel(
            id: targetFile.$id, 
            name: targetFile.name, 
            url: fileUrl.replaceAll("{BUCKET_ID}", myConfig!.serverConfig!.storageConnInfo.bucketId).replaceAll("{FILE_ID}", targetFile.$id), 
            thumbnailUrl: fileUrl.replaceAll("{BUCKET_ID}", myConfig!.serverConfig!.storageConnInfo.bucketId).replaceAll("{FILE_ID}", targetFile.$id), 
            size: targetFile.sizeOriginal, 
            contentType: ContentsType.getContentTypes(targetFile.mimeType)
          ));
        }
      }
    } catch (error) {
      logger.info(error);
    }
    return null;
  }


  @override
  Future<void> setBucket() async {
    try {
      myConfig!.serverConfig!.storageConnInfo.bucketId = (await _awStorage.getBucket(bucketId: AccountManager.currentLoginUser.userId)).$id;
    } catch (error) {
      myConfig!.serverConfig!.storageConnInfo.bucketId = (await _awStorage.createBucket(
        bucketId: AccountManager.currentLoginUser.userId,
        name: AccountManager.currentLoginUser.email,
        permissions: [
          Permission.create(Role.any()),
          Permission.read(Role.any()),
          Permission.update(Role.any()),
          Permission.delete(Role.any())
        ]
      )).$id;
    }
  }


  @override
  Future<void> createThumbnail(String sourceFileId, String sourceFileName, String sourceFileType) async {
    try {
      http.Client client = http.Client();
      if (client is BrowserClient) {
        client.withCredentials = true;
      }

      await client.post(
        Uri.parse("https://devcreta.com:553/createThumbnail"),
        headers: {
          "Content-type": "application/json"
        },
        body: jsonEncode({
          "bucketId" : myConfig!.serverConfig!.storageConnInfo.bucketId,
          "folderName" : sourceFileId,
          "fileName" : sourceFileName,
          "fileType": sourceFileType,
          "cloudType" : "appwrite"
        })
      );
    } catch (error) {
      logger.severe(error);
    }
  }

}
