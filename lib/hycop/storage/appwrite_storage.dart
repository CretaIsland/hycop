import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

import 'package:appwrite/appwrite.dart';
import 'package:dart_appwrite/dart_appwrite.dart' as dart_appwrite;
import 'package:flutter/foundation.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

import 'abs_storage.dart';
import 'storage_utils.dart';
import '../account/account_manager.dart';
import '../enum/model_enums.dart';
import '../model/file_model.dart';
import '../../common/util/config.dart';
import '../../common/util/logger.dart';



class AppwriteStorage extends AbsStorage {


  Storage? _storage;
  late dart_appwrite.Storage _awStorage;
  String url = "https://devcreta.com:663/v1/storage/buckets/BUCKET_ID/files/FILE_ID?view?project=${myConfig!.serverConfig!.storageConnInfo.projectId}";
  


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
  Future<void> setBucket() async {
    try {
      final bucket = await _awStorage.getBucket(bucketId: AccountManager.currentLoginUser.userId);
      myConfig!.serverConfig!.storageConnInfo.bucketId = bucket.$id;
    } catch (error) {
      // bucket이 없을 경우
      final newBucket = await _awStorage.createBucket(
        bucketId: AccountManager.currentLoginUser.userId, 
        name: AccountManager.currentLoginUser.email,
        permissions: [
          Permission.create(Role.any()),
          Permission.read(Role.any()),
          Permission.update(Role.any()),
          Permission.delete(Role.any())
        ]
      );
      myConfig!.serverConfig!.storageConnInfo.bucketId = newBucket.$id;
    }
  }

  @override
  Future<FileModel?> uploadFile(String fileName, String fileType, Uint8List fileBytes, {bool makeThumbnail = false, String usageType = "content", String? bucketId}) async {
    try {
      await initialize();

      bucketId ??= myConfig!.serverConfig!.storageConnInfo.bucketId;
      fileName = StorageUtils.sanitizeString(fileName);
      late String fileId;

      if(fileType.contains("image")) {
        fileId = "img-";
      } else if (fileType.contains("video")) {
        fileId = "vid-";
        makeThumbnail = true;
      } else {
        fileId = "etc-";
        if(fileType.contains("pdf")) makeThumbnail = true;
      }
      fileId += StorageUtils.getMD5(fileBytes);

      var target = await getFileData(fileId, bucketId: bucketId);
      if(target != null) {
        if(target.thumbnailId.isEmpty && makeThumbnail) {
          await createThumbnail(fileId, fileName, fileType, bucketId);
        } else {
          return target;
        }
      } else {
        await _storage!.createFile(bucketId: bucketId, fileId: fileId, file: InputFile.fromBytes(bytes: fileBytes, filename: fileName));
        if(makeThumbnail) await createThumbnail(fileId, fileName, fileType, bucketId);
      }
      return await getFileData(fileId, bucketId: bucketId);
    } catch (error) {
      logger.severe("error during Storage.uploadFile >>> $error");
    }
    return null;
  }

  @override
  Future<FileModel?> getFileData(String fileId, {String? bucketId}) async {
    try {
      await initialize();

      bucketId ??= myConfig!.serverConfig!.storageConnInfo.bucketId;
      var target = await _storage!.getFile(bucketId: bucketId, fileId: fileId);
      String targetUrl = url.replaceFirst("BUCKET_ID", bucketId).replaceFirst("FILE_ID", fileId);

      try {
        var targetThumbnail = await _storage!.getFile(bucketId: bucketId, fileId: "cov-${fileId.substring(4)}");
        return FileModel(
          id: target.$id, 
          name: target.name, 
          url: targetUrl, 
          thumbnailUrl: url.replaceFirst("BUCKET_ID", targetThumbnail.bucketId).replaceFirst("FILE_ID", targetThumbnail.$id), 
          thumbnailId: targetThumbnail.$id, 
          size: target.sizeOriginal, 
          contentType: ContentsType.getContentTypes(target.mimeType)
        );
      } catch (error) {
        // fail get thumbnail
        return FileModel(
          id: target.$id, 
          name: target.name, 
          url: targetUrl, 
          thumbnailUrl: target.mimeType.contains("image") ? url : "", 
          thumbnailId: "", 
          size: target.sizeOriginal, 
          contentType: ContentsType.getContentTypes(target.mimeType)
        );
      }
    } catch (error) {
      logger.severe("error during Storage.getFileData >>> $error");
    }
    return null;
  }

  @override
  Future<FileModel?> getFileDataFromUrl(String fileUrl) async {
    try {
      String bucketId = fileUrl.substring(fileUrl.indexOf("buckets/") + 8, fileUrl.indexOf("/files"));
      String fileId = fileUrl.substring(fileUrl.indexOf("files/") + 6, fileUrl.indexOf("/view"));
      return await getFileData(fileId, bucketId: bucketId);
    } catch (error) {
      logger.severe("error during Storage.getFileDataFromUrl >>> $error");
    }
    return null;
  }

  @override
  Future<List<FileModel>?> getMultiFileData(List<String> fileIdList, {String? bucketId}) async {
    try {
      List<FileModel> result = [];
      bucketId ??= myConfig!.serverConfig!.storageConnInfo.bucketId;

      for(var fileId in fileIdList) {
        var fileData = await getFileData(fileId);
        if(fileData != null) result.add(fileData);
      }

      return result;
    } catch (error) {
      logger.severe("error during Storage.getMultiFileData >>> $error");
    }
    return null;
  }

  @override
  Future<Uint8List?> getFileBytes(String fileId, {String? bucketId}) async {
    try {
      await initialize();

      bucketId ??= myConfig!.serverConfig!.storageConnInfo.bucketId;
      return await _storage!.getFileDownload(bucketId: bucketId, fileId: fileId);
    } catch (error) {
      logger.severe("error during Storage.getFileBytes >>> $error");
    }
    return null;
  }

  @override
  Future<bool> deleteFile(String fileId, {String? bucketId}) async {
    try {
      await initialize();

      bucketId ??= myConfig!.serverConfig!.storageConnInfo.bucketId;
      var target = await getFileData(fileId, bucketId: bucketId);
      if(target != null) {
        if(target.thumbnailId.isNotEmpty) await _storage!.deleteFile(bucketId: bucketId, fileId: target.thumbnailId);
        await _storage!.deleteFile(bucketId: bucketId, fileId: target.id);
      }
      return true;
    } catch (error) {
      logger.severe("error during Storage.deleteFile >>> $error");
    }
    return false;
  }

  @override
  Future<bool> deleteFileFromUrl(String fileUrl) async {
    try {
      String bucketId = fileUrl.substring(fileUrl.indexOf("buckets/") + 8, fileUrl.indexOf("/files"));
      String fileId = fileUrl.substring(fileUrl.indexOf("files/") + 6, fileUrl.indexOf("/view"));
      return await deleteFile(fileId, bucketId: bucketId);
    } catch (error) {
      logger.severe("error during Storage.deleteFileFromUrl >>> $error");
    }
    return false;
  }

  @override
  Future<bool> downloadFile(String fileId, String saveName, {String? bucketId}) async { // only web
    try {
      if(kIsWeb) {
        bucketId ??= myConfig!.serverConfig!.storageConnInfo.bucketId;
        Uint8List? targetBytes = await getFileBytes(fileId, bucketId: bucketId);
        String targetUrl = Url.createObjectUrlFromBlob(Blob([targetBytes]));
        AnchorElement(href: targetUrl)
          ..setAttribute("download", saveName)
          ..click();
        Url.revokeObjectUrl(targetUrl);
        return true;
      }
    } catch (error) {
      logger.severe("error during Storage.downloadFile >>> $error");
    }
    return false;
  }

  @override
  Future<bool> downloadFileFromUrl(String fileUrl, String saveName) async { // only web
    try {
      if(kIsWeb) {
        String bucketId = fileUrl.substring(fileUrl.indexOf("buckets/") + 8, fileUrl.indexOf("/files"));
        String fileId = fileUrl.substring(fileUrl.indexOf("files/") + 6, fileUrl.indexOf("/view"));
        return await downloadFile(fileId, saveName, bucketId: bucketId);
      }
    } catch (error) {
      logger.severe("error during Storage.downloadFile >>> $error");
    }
    return false;
  }

  @override
  Future<FileModel?> copyFile(String sourceBucketId, String sourceFileId, {String? bucketId}) async {
    try {
      var sourceFile = await getFileData(sourceFileId, bucketId: sourceBucketId);
      if(sourceFile != null) {
        var sourceFileBytes = await getFileBytes(sourceFileId, bucketId: sourceBucketId);
        if(sourceFileBytes != null) {
          if(sourceFile.thumbnailId.isNotEmpty) {
            return await uploadFile(sourceFile.name, sourceFile.contentType.name, sourceFileBytes, makeThumbnail: true, bucketId: bucketId);
          } 
          return await uploadFile(sourceFile.name, sourceFile.contentType.name, sourceFileBytes, bucketId: bucketId);
        }
      }
    } catch (error) {
      logger.severe("error during Storage.copyFile >>> $error");
    }
    return null;
  }

  @override
  Future<FileModel?> copyFileFromUrl(String fileUrl, {String? bucketId}) async {
    try {
      String sourceBucketId = fileUrl.substring(fileUrl.indexOf("buckets/") + 8, fileUrl.indexOf("/files"));
      String sourceFileId = fileUrl.substring(fileUrl.indexOf("files/") + 6, fileUrl.indexOf("/view"));
      return await copyFile(sourceBucketId, sourceFileId, bucketId: bucketId);  
    } catch (error) {
      logger.severe("error during Storage.copyFile >>> $error");
    }
    return null;
  }

  @override
  Future<FileModel?> moveFile(String sourceBucketId, String sourceFileId, {String? bucketId}) async {
    try {
      late FileModel? moveFile;
      var sourceFile = await getFileData(sourceFileId, bucketId: sourceBucketId);
      if(sourceFile != null) {
        var sourceFileBytes = await getFileBytes(sourceFileId, bucketId: sourceBucketId);
        if(sourceFileBytes != null) {
          if(sourceFile.thumbnailId.isNotEmpty) {
            moveFile = await uploadFile(sourceFile.name, sourceFile.contentType.name, sourceFileBytes, makeThumbnail: true, bucketId: bucketId);
          } else {
            moveFile = await uploadFile(sourceFile.name, sourceFile.contentType.name, sourceFileBytes, bucketId: bucketId);
          }
          await deleteFile(sourceFileId, bucketId: sourceBucketId);
          return moveFile;
        }
      }
    } catch (error) {
      logger.severe("error during Storage.moveFile >>> $error");
    }
    return null;
  }

  @override
  Future<FileModel?> moveFileFromUrl(String fileUrl, {String? bucketId}) async {
    try {
      String sourceBucketId = fileUrl.substring(fileUrl.indexOf("buckets/") + 8, fileUrl.indexOf("/files"));
      String sourceFileId = fileUrl.substring(fileUrl.indexOf("files/") + 6, fileUrl.indexOf("/view"));
      return await moveFile(sourceBucketId, sourceFileId, bucketId: bucketId);  
    } catch (error) {
      logger.severe("error during Storage.moveFile >>> $error");
    }
    return null;
  }

  @override
  Future<bool> createThumbnail(String fileId, String fileName, String fileType, String bucketId) async {
    try {
      http.Client client = http.Client();
      if (client is BrowserClient) {
        client.withCredentials = true;
      }

      var response = await client.post(Uri.parse("${myConfig!.config.apiServerUrl}/createThumbnail"),
          headers: {"Content-type": "application/json"},
          body: jsonEncode({
            "bucketId": bucketId,
            "folderName": fileId,
            "fileName": fileName,
            "fileType": fileType,
            "cloudType": "appwrite"
          }));

      if (response.statusCode == 200) return true;
    } catch (error) {
      logger.severe("error during Storage.createThumbnail >> $error");
    }
    return false;
  }


}