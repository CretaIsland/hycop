import 'dart:convert';
import 'dart:typed_data';
import 'dart:html';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

import 'abs_storage.dart';
import 'storage_utils.dart';
import '../account/account_manager.dart';
import '../enum/model_enums.dart';
import '../model/file_model.dart';
import '../../common/util/config.dart';
import '../../common/util/logger.dart';



class FirebaseAppStorage extends AbsStorage {


  FirebaseStorage? _storage;



  @override
  Future<void> initialize() async {
    if(AbsStorage.fbStorageConn == null) {
      AbsStorage.setFirebaseApp(await Firebase.initializeApp(
        name: "storage",
        options: FirebaseOptions(
          apiKey: myConfig!.serverConfig!.storageConnInfo.apiKey, 
          appId: myConfig!.serverConfig!.storageConnInfo.appId, 
          messagingSenderId: myConfig!.serverConfig!.storageConnInfo.messagingSenderId, 
          projectId: myConfig!.serverConfig!.storageConnInfo!.projectId,
          storageBucket: myConfig!.serverConfig!.storageConnInfo.storageURL
        )
      ));
    }
    _storage ??= FirebaseStorage.instanceFor(app: AbsStorage.fbStorageConn);
  }

  @override
  Future<void> setBucket() async {
    myConfig!.serverConfig!.storageConnInfo.bucketId = StorageUtils.genBucketId(AccountManager.currentLoginUser.email, AccountManager.currentLoginUser.userId);
  }

  @override
  Future<FileModel?> uploadFile(String fileName, String fileType, Uint8List fileBytes, {bool makeThumbnail = false, String usageType = "content", String? bucketId}) async {
    try {
      await initialize();

      bucketId ??= myConfig!.serverConfig!.storageConnInfo.bucketId;
      fileName = StorageUtils.sanitizeString(StorageUtils.getMD5(fileBytes) + fileName);
      late String folderName;

      if (usageType == "content") {
        if (fileType.contains("image")) {
          folderName = "content/image";
        } else if (fileType.contains("video")) {
          makeThumbnail = true;
          folderName = "content/video";
        } else {
          if (fileType.contains("pdf")) makeThumbnail = true;
          folderName = "content/etc";
        }
      } else if (usageType == "profile") {
        folderName = "profile";
      } else if (usageType == "banner") {
        folderName = "banner";
      } else if (usageType == "bookThumbnail") {
        folderName = "book/thumbnail";
      }

      var target = _storage!.ref().child("$bucketId/$folderName/$fileName");
      await target.putData(fileBytes);
      await target.updateMetadata(SettableMetadata(contentType: fileType));
      if(makeThumbnail) await createThumbnail("$folderName/", fileName, fileType, bucketId);
      
      return await getFileData("$bucketId/$folderName/$fileName");
    } catch (error) {
      logger.severe("error during Storage.uploadFile >>> $error");
    }
    return null;
  }

  @override
  Future<FileModel?> getFileData(String fileId, {String? bucketId}) async {
    try {
      await initialize();

      var target = _storage!.ref().child(fileId);
      FullMetadata targetMetadata = await target.getMetadata();
      String targetUrl = await target.getDownloadURL();

      var targetThumbnail = _storage!.ref().child(fileId);
      String targetThumbnailUrl = await targetThumbnail.getDownloadURL().onError((error, stackTrace) async {
        return targetMetadata.contentType != null && targetMetadata.contentType!.contains("image") ? targetUrl : ""; 
      });

      return FileModel(
        id: target.fullPath, 
        name: targetMetadata.name, 
        url: targetUrl, 
        thumbnailUrl: targetThumbnailUrl, 
        thumbnailId: targetThumbnailUrl.isEmpty ? "" : targetThumbnail.fullPath, 
        size: targetMetadata.size ?? 0, 
        contentType: targetMetadata.contentType == null ? ContentsType.none : ContentsType.getContentTypes(targetMetadata.contentType!)
      );
    } catch (error) {
      logger.severe("error during Storage.getFileData >>> $error");
    }
    return null;
  }

  @override
  Future<FileModel?> getFileDataFromUrl(String fileUrl) async {
    try {
      await initialize();

      var target = _storage!.refFromURL(fileUrl);
      FullMetadata targetMetadata = await target.getMetadata();
      String targetUrl = await target.getDownloadURL();

      // 썸네일 경로
      var targetThumbnail = _storage!.ref().child(fileUrl);
      String targetThumbnailUrl = await targetThumbnail.getDownloadURL().onError((error, stackTrace) async {
        return targetMetadata.contentType != null && targetMetadata.contentType!.contains("image") ? targetUrl : ""; 
      });

      return FileModel(
        id: target.fullPath, 
        name: targetMetadata.name, 
        url: targetUrl, 
        thumbnailUrl: targetThumbnailUrl, 
        thumbnailId: targetThumbnail.fullPath, 
        size: targetMetadata.size ?? 0, 
        contentType: targetMetadata.contentType == null ? ContentsType.none : ContentsType.getContentTypes(targetMetadata.contentType!)
      );
    } catch (error) {
      logger.severe("error during Storage.getFileDataFromUrl >>> $error");
    }
    return null;
  }

  @override
  Future<List<FileModel>?> getMultiFileData(List<String> fileIdList, {String? bucketId}) async {
    try {
      List<FileModel> result = [];

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

      String downloadUrl = await _storage!.ref().child(fileId).getDownloadURL();
      http.Response response = await http.get(Uri.parse(downloadUrl));
      Uint8List fileBytes = response.bodyBytes;
      return fileBytes;
    } catch (error) {
      logger.severe("error during Storage.getFileBytes >>> $error");
    }
    return null;
  }

  @override
  Future<bool> deleteFile(String fileId, {String? bucketId}) async {
    try {
      await initialize();
      await _storage!.ref().child(fileId).delete();
      return true;
    } catch (error) {
      logger.severe("error during Storage.deleteFile >>> $error");
    }
    return false;
  }

  @override
  Future<bool> deleteFileFromUrl(String fileUrl) async {
    try {
      await initialize();
      await _storage!.refFromURL(fileUrl).delete();
      return true;
    } catch (error) {
      logger.severe("error during Storage.deleteFileFromUrl >>> $error");
    }
    return false;
  }

  @override
  Future<bool> downloadFile(String fileId, String saveName, {String? bucketId}) async {
    try {
      Uint8List? targetBytes = await getFileBytes(fileId, bucketId: bucketId);
      String targetUrl = Url.createObjectUrlFromBlob(Blob([targetBytes]));
      AnchorElement(href: targetUrl)
        ..setAttribute("download", saveName)
        ..click();
      Url.revokeObjectUrl(targetUrl);
      return true;
    } catch (error) {
      logger.severe("error during Storage.downloadFile >>> $error");
    }
    return false;
  }

  @override
  Future<bool> downloadFileFromUrl(String fileUrl, String saveName) async {
    try {
      var file = _storage!.refFromURL(fileUrl);
      Uint8List? targetBytes = await getFileBytes(file.fullPath, bucketId: file.bucket);
      String targetUrl = Url.createObjectUrlFromBlob(Blob([targetBytes]));
      AnchorElement(href: targetUrl)
      ..setAttribute("download", saveName)
      ..click();
      Url.revokeObjectUrl(targetUrl);
      return true;
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
      await initialize();
      var sourceFile = _storage!.refFromURL(fileUrl);
      return await copyFile(sourceFile.bucket, sourceFile.fullPath);
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
      await initialize();
      var sourceFile = _storage!.refFromURL(fileUrl);
      return await moveFile(sourceFile.bucket, sourceFile.fullPath);
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
            "folderName": fileId.replaceAll("/", "%2F"),
            "fileName": fileName,
            "fileType": fileType,
            "cloudType": "firebase"
          }));

      if (response.statusCode == 200) return true;
    } catch (error) {
      logger.info(error);
    }
    return false;
  }


}