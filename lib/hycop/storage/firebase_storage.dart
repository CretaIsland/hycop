import 'dart:convert';
import 'dart:typed_data';
import 'dart:html';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

import '../../common/util/config.dart';
import '../../common/util/logger.dart';
import '../account/account_manager.dart';
import '../enum/model_enums.dart';
import '../model/file_model.dart';
import 'abs_storage.dart';
import 'storage_utils.dart';



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
          projectId: myConfig!.serverConfig!.storageConnInfo.projectId,
          storageBucket: myConfig!.serverConfig!.storageConnInfo.storageURL
        )
      ));
    }
    _storage ??= FirebaseStorage.instanceFor(app: AbsStorage.fbStorageConn);
  }

  @override
  Future<void> setBucket() async {
    myConfig!.serverConfig!.storageConnInfo.bucketId = 
      StorageUtils.createBucketId(AccountManager.currentLoginUser.email, AccountManager.currentLoginUser.userId);
  }


  @override
  Future<FileModel?> getFileData(String fileId, {String? bucketId}) async {
    try {
      await initialize();

      var file = _storage!.ref().child(fileId);
      FullMetadata fileMetadata = await file.getMetadata();
      String fileUrl = await file.getDownloadURL();

      String thumbnailId = "${file.fullPath.substring(0, file.fullPath.indexOf("/"))}/content/thumbnail/${file.name.substring(0, file.name.lastIndexOf("."))}.jpg";
      var thumbnail = _storage!.ref().child(thumbnailId);
      var thumbnailUrl = await thumbnail.getDownloadURL().onError((error, stackTrace) =>
        fileMetadata.contentType != null && fileMetadata.contentType!.contains("image") ? fileUrl : ""
      );

      return FileModel(
        id: file.fullPath, 
        name: file.name.length > 36 ? file.name.substring(32) : file.name, 
        url: fileUrl, 
        thumbnailUrl: thumbnailUrl, 
        size: fileMetadata.size ?? 0, 
        contentType: ContentsType.getContentTypes(fileMetadata.contentType ?? "")
      );
    } catch (error) {
      logger.severe("error at Storage.getFileData >>> $error");
    }
    return null;
  }

  @override
  Future<FileModel?> getFileDataFromUrl(String fileUrl) async {
    try {
      var file = _storage!.refFromURL(fileUrl);
      return await getFileData(file.fullPath, bucketId: file.bucket);
    } catch (error) {
      logger.severe("error at Storage.getFileDataFromUrl >>> $error");
    }
    return null;
  }

  @override
  Future<List<FileModel>> getMultiFileData(List<String> fileIds, {String? bucketId}) async {
    try {
      List<FileModel> fileDatas = [];
      for(String fileId in fileIds) {
        FileModel? fileData = await getFileData(fileId);
        if(fileData != null) fileDatas.add(fileData);
      }
      return fileDatas;
    } catch (error) {
      logger.severe("error at Storage.getMultiFileData >>> $error");
    }
    return List.empty();
  }

  @override
  Future<FileModel?> uploadFile(String fileName, String fileType, Uint8List fileBytes, {bool makeThumbnail = false, String usageType = "content", String? bucketId}) async {
    try {
      await initialize();

      bucketId ??= myConfig!.serverConfig!.storageConnInfo.bucketId;
      fileName = StorageUtils.sanitizeString(StorageUtils.getMD5(fileBytes) + fileName);
      late String folderPath;

      if(usageType == "content") {
        if(fileType.contains("image")) {
          folderPath = "content/image/";
        } else if(fileType.contains("video")) {
          folderPath = "content/video/";
          makeThumbnail = true;
        } else {
          folderPath = "content/etc/";
          if(fileType.contains("pdf")) makeThumbnail = true;
        }
      } else if(usageType == "bookThumbnail") {
        folderPath = "book/thumbnail/";
      } else if(usageType == "profile") {
        folderPath = "profile/";
      } else if(usageType == "banner"){
        folderPath = "banner/";
      } else {
        folderPath = "etc/";
      }

      var file = _storage!.ref().child("$bucketId/$folderPath$fileName");
      await file.putData(fileBytes);
      await file.updateMetadata(SettableMetadata(contentType: fileType));
      if(makeThumbnail) await createThumbnail(folderPath, fileName, fileType, bucketId);
      return await getFileData(file.fullPath);
    } catch (error) {
      logger.severe("error at Storage.uploadFile >>> $error");
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
          }
        )
      );
      if (response.statusCode == 200) return true;
    } catch (error) {
      logger.severe("error at Storage.createThumbnail >>> $error");
    }
    return false;
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
      logger.severe("error at Storage.getFileBytes >>> $error");
    }
    return null;
  }
  
  @override
  Future<bool> downloadFile(String fileId, String saveName, {String? bucketId}) async {
    try {
      await initialize();

      if(kIsWeb) {
        Uint8List? targetBytes = await getFileBytes(fileId, bucketId: bucketId);
        String targetUrl = Url.createObjectUrlFromBlob(Blob([targetBytes]));
        AnchorElement(href: targetUrl)
          ..setAttribute("download", saveName)
          ..click();
        Url.revokeObjectUrl(targetUrl);
        return true;
      }
    } catch (error) {
      logger.severe("error at Storage.downloadFile >>> $error");
    }
    return false;
  }
  
  @override
  Future<bool> downloadFileFromUrl(String fileUrl, String saveName) async {
    try {
      await initialize();
      
      var file = _storage!.refFromURL(fileUrl);
      return await downloadFile(file.fullPath, saveName);
    } catch (error) {
      logger.severe("error at Storage.downloadFileFromUrl >>> $error");
    }
    return true;
  }

  @override
  Future<bool> deleteFile(String fileId, {String? bucketId}) async {
    try {
      await initialize();
      await _storage!.ref().child(fileId).delete();
      return true;
    } catch (error) {
      logger.severe("error at Storage.deleteFile >>> $error");
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
      logger.severe("error at Storage.deleteFileFromUrl >>> $error");
    }
    return false;
  }
  
  @override
  Future<FileModel?> copyFile(String sourceBucketId, String sourceFileId, {String? bucketId}) async {
    try {
      await initialize();

      bucketId ??= myConfig!.serverConfig!.storageConnInfo.bucketId;
      var sourceFile = _storage!.ref().child(sourceFileId);
      var sourceFileData = await getFileData(sourceFileId);
      var sourceFileMetaData = await sourceFile.getMetadata();
      Uint8List? sourceFileBytes = await getFileBytes(sourceFileId);
      if(sourceFileData!.thumbnailUrl.isNotEmpty && sourceFileData.thumbnailUrl != sourceFileData.url) {
        return await uploadFile(sourceFile.name, sourceFileMetaData.contentType ?? "", sourceFileBytes!, makeThumbnail: true, bucketId: bucketId);
      }
      return await uploadFile(sourceFile.name, sourceFileMetaData.contentType ?? "", sourceFileBytes!, bucketId: bucketId);
    } catch (error) {
      logger.severe("error at Storage.copyFile >>> $error");
    }
    return null;
  }
  
  @override
  Future<FileModel?> copyFileFromUrl(String fileUrl, {String? bucketId}) async {
    try {
      await initialize();

      var file = _storage!.refFromURL(fileUrl);
      return await copyFile(file.fullPath.substring(0, file.fullPath.indexOf("/")), file.fullPath, bucketId: bucketId);
    } catch (error) {
      logger.severe("error at Storage.copyFileFromUrl >>> $error");
    }
    return null;
  }
  
  @override
  Future<FileModel?> moveFile(String sourceBucketId, String sourceFileId, {String? bucketId}) async {
    try {
      var moveFile = await copyFile(sourceBucketId, sourceFileId, bucketId: bucketId);
      await deleteFile(sourceFileId);
      return moveFile;
    } catch (error) {
      logger.severe("error at Storage.moveFile >>> $error");
    }
    return null;
  }
  
  @override
  Future<FileModel?> moveFileFromUrl(String fileUrl, {String? bucketId}) async {
    try {
      await initialize();

      var file = _storage!.refFromURL(fileUrl);
      return await moveFile(file.fullPath.substring(0, file.fullPath.indexOf("/")), file.fullPath, bucketId: bucketId);
    } catch (error) {
      logger.severe("error at Storage.moveFileFromUrl >>> $error");
    }
    return null;
  }
  
  
}