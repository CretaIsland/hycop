import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

import 'package:hycop/common/util/config.dart';
import 'package:hycop/common/util/logger.dart';
import 'package:hycop/hycop/account/account_manager.dart';
import 'package:hycop/hycop/enum/model_enums.dart';
import 'package:hycop/hycop/model/file_model.dart';
import 'package:hycop/hycop/storage/abs_storage.dart';
import 'package:hycop/hycop/utils/hycop_utils.dart';

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
    myConfig!.serverConfig!.storageConnInfo.bucketId = HycopUtils.genBucketId(AccountManager.currentLoginUser.email, AccountManager.currentLoginUser.userId);
  }


  @override
  Future<FileModel?> uploadFile(String fileName, String fileType, Uint8List fileBytes, {bool makeThumbnail = false, String usageType = "content", String bucketId = ""}) async {
    try {
      await initialize();

      bucketId = bucketId.isEmpty ? myConfig!.serverConfig!.storageConnInfo.bucketId : bucketId;
      fileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣.]'), "_");
      String folderName = "";
      if(usageType == "content") {
        if(fileType.contains("image")) {
          folderName = "$usageType/image/";
        } else if(fileType.contains("video")) {
          makeThumbnail = true;
          folderName = "$usageType/video/";
        } else {
          if(fileType.contains("pdf")) makeThumbnail = true;
          folderName = "$usageType/etc/";
        } 
      } else if (usageType == "profile") {
        folderName = "profile";
      } else {
        folderName = "banner";
      }

      var target = _storage!.ref().child("$bucketId/$folderName$fileName");
      var uploadFile = await getFileData(target.fullPath);

      if(uploadFile != null) {
        if(uploadFile.thumbnailUrl == "" && makeThumbnail) {
          await createThumbnail(folderName, fileName, fileType, bucketId);
          return await getFileData(uploadFile.id);
        }
        return uploadFile;
      } else {
        await target.putData(fileBytes);
        await target.updateMetadata(SettableMetadata(contentType: fileType));
        if(makeThumbnail) {
          await createThumbnail(folderName, fileName, fileType, bucketId);
        }
        return await getFileData(target.fullPath);
      }
    } catch (error) {
      logger.severe("error during Storage.uplaodFile >> $error");
    }
    return null;
  }


  @override
  Future<FileModel?> getFileData(String fileId, {String bucketId = ""}) async {
    try {
      await initialize();

      bucketId = bucketId.isEmpty ? myConfig!.serverConfig!.storageConnInfo.bucketId : bucketId;
      var target = _storage!.ref().child(fileId);
      var targetMetaData = await target.getMetadata();
      var targetUrl = await target.getDownloadURL();

      var targetThumbnailUrl = await _storage!.ref()
        .child("$bucketId/content/thumbnail/${fileId.substring(fileId.lastIndexOf("/") + 1, fileId.lastIndexOf("."))}.jpg")
        .getDownloadURL().onError((error, stackTrace) async {
          return targetUrl;
        });
      
      return FileModel(
        id: targetMetaData.fullPath, 
        name: targetMetaData.name, 
        url: targetUrl, 
        thumbnailUrl: targetThumbnailUrl, 
        size: targetMetaData.size ?? 0, 
        contentType: targetMetaData.contentType == null ? ContentsType.none : ContentsType.getContentTypes(targetMetaData.contentType!)
      );
    } catch (error) {
      logger.severe("error during Storage.getFileData >> $error");
    }
    return null;
  }

  @override
  Future<List<FileModel>?> getMultiFileData({String search = "", int limit = 99, int? offset, String? cursor, String cursorDirection = "after", String orderType = "DESC", String bucketId = ""}) async {
    List<FileModel> multiFileData = [];
  
    try {
      await initialize();

      bucketId = bucketId.isEmpty ? myConfig!.serverConfig!.storageConnInfo.bucketId : bucketId;
      final multiTarget = await _storage!.ref().child("$bucketId/$search").listAll();
      for(var target in multiTarget.items) {
        var targetMetaData = await target.getMetadata();
        var targetUrl = await target.getDownloadURL();
        var targetThumbnail = await _storage!.ref()
          .child("$bucketId/content/thumbnail/${target.fullPath.substring(target.fullPath.lastIndexOf("/") + 1, targetMetaData.fullPath.lastIndexOf("."))}.jpg")
          .getDownloadURL().onError((error, stackTrace) {
            return targetUrl;
          });
        multiFileData.add(FileModel(
          id: targetMetaData.fullPath,
          name: targetMetaData.name, 
          url: targetUrl, 
          thumbnailUrl: targetThumbnail, 
          size: targetMetaData.size ?? 0,
          contentType: ContentsType.getContentTypes(targetMetaData.contentType!)
        ));
      }
      return multiFileData;
    } catch (error) {
      logger.severe("error during Storage.getMultiFileData >> $error");
    }
    return null;
  }

  @override
  Future<Uint8List?> getFileBytes(String fileId, {String bucketId = ""}) async {
    try {
      await initialize();
      return await _storage!.ref().child(fileId).getData();
    } catch (error) {
      logger.severe("error during Storage.getFileBytes >> $error");
    }
    return null;
  }

  @override
  Future<bool> deleteFile(String fileId, {String bucketId = ""}) async {
    try {
      await initialize();
      await _storage!.ref().child(fileId).delete();
      return true;
    } catch (error) {
      logger.severe("error during Storage.deleteFile >> $error");
    }
    return false;
  }

  @override
  Future<void> downloadFile(String fileId, String fileName, {String bucketId = ""}) async {
    try {
      await initialize();
      Uint8List? targetBytes = await getFileBytes(fileId, bucketId: bucketId);
      String targetUrl = Url.createObjectUrlFromBlob(Blob([targetBytes]));
      AnchorElement(href: targetUrl)
        ..setAttribute("download", fileName)
        ..click();
      Url.revokeObjectUrl(targetUrl);
    } catch (error) {
      logger.severe("error during Storage.downloadFile >> $error");
    }
  }

  @override
  Future<FileModel?> copyFile(String sourceBucketId, String sourceFileId, {String bucketId = ""}) async {
    try {
      await initialize();

      var target = await getFileData("$sourceBucketId/$sourceFileId");
      if(target != null) {
        var targetBytes = await getFileBytes("$sourceBucketId/$sourceFileId");
        if(targetBytes == null) throw Exception("file not exist");
        return await uploadFile(target.name, target.contentType.name, targetBytes);
      }
    } catch (error) {
      logger.severe("error during Storage.copyFile >> $error");
    }
    return null;
  }

  @override
  Future<FileModel?> moveFile(String sourceBucketId, String sourceFileId, {String bucketId = ""}) async {
    try {
      await initialize();

      var target = await getFileData("$sourceBucketId/$sourceFileId");
      if(target != null) {
        var targetBytes = await getFileBytes("$sourceBucketId/$sourceFileId");
        if(targetBytes == null) throw Exception("file not exist");
        var moveFile = await uploadFile(target.name, target.contentType.name, targetBytes);
        await deleteFile("$sourceBucketId/$sourceFileId");
        return moveFile;
      }
    } catch (error) {
      logger.severe("error during Storage.copyFile >> $error");
    }
    return null;
  }

  @override
  Future<bool> createThumbnail(String sourceFileId, String sourceFileName, String sourceFileType, String sourceBucketId) async {
    try {
      http.Client client = http.Client();
      if (client is BrowserClient) {
        client.withCredentials = true;
      }

      var response = await client.post(
        Uri.parse("https://devcreta.com:553/createThumbnail"),
        headers: {
          "Content-type": "application/json"
        },
        body: jsonEncode({
          "bucketId" : sourceBucketId,
          "folderName" : sourceFileId.replaceAll("/", "%2F"),
          "fileName" : sourceFileName,
          "fileType": sourceFileType,
          "cloudType" : "firebase"
        })
      );

      if(response.statusCode == 200) return true;
    } catch (error) {
      logger.info(error);
    }
    return false;
  }

  @override
  Map<String, String> parseFileUrl(String fileUrl) {
    Map<String, String> parseResult = {};

    parseResult.addEntries(<String, String>{"bucketId" : fileUrl.substring(fileUrl.indexOf("o/") + 2, fileUrl.indexOf("%2F"))}.entries);
    parseResult.addEntries(<String, String>{"fileId" : Uri.decodeComponent(fileUrl.substring(fileUrl.indexOf("%2F") + 3, fileUrl.indexOf("?alt")).replaceAll(RegExp(r"%2F", caseSensitive: false), "/"))}.entries);

    return parseResult;
  }

}