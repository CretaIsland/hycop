import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:typed_data';


import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
      logger.info("storage initialize");
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
    }
    if(_storage == null) {
      logger.info("_storage init");
      _storage = FirebaseStorage.instanceFor(app: AbsStorage.fbStorageConn);
    }
  }
 
 
  @override
  Future<FileModel?> uploadFile(String fileName, String fileType, Uint8List fileBytes, {bool makeThumbnail = false, String fileUsage = "content"}) async {
    await initialize();

    fileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣.]'), "_");
    String folderName = "";
    if(fileUsage == "content") {
      if(fileType.contains("image")) {
        folderName = "$fileUsage/image/";
      } else if(fileType.contains("video")) {
        folderName = "$fileUsage/video/";
      } else {
        folderName = "$fileUsage/etc/";
      }
    }

    try {
      var targetFile = _storage!.ref().child("${myConfig!.serverConfig!.storageConnInfo.bucketId}$folderName$fileName");
      var uploadFile = await getFile(targetFile.fullPath);


      if(uploadFile != null) {
        if(uploadFile.thumbnailUrl == "" && (makeThumbnail || fileType.contains("video") || fileType.contains("pdf"))) {
          await createThumbnail(folderName, fileName, fileType);
        }
        return await getFile(targetFile.fullPath);
      } else {
        await targetFile.putData(fileBytes);
        await targetFile.updateMetadata(SettableMetadata(contentType: fileType));
        if(makeThumbnail || fileType.contains("video") || fileType.contains("pdf")) {
          await createThumbnail(folderName, fileName, fileType);
        }
        return await getFile(targetFile.fullPath);
      }
    } catch (error) {
      logger.severe(error);
    }
    return null;
  }


  @override
  Future<void> deleteFile(String fileId) async {
    await initialize();
    await _storage!.ref().child(fileId).delete().onError((error, stackTrace) => logger.severe(error));
  }


  @override
  Future<Uint8List?> getFileBytes(String fileId) async {
    try {
      await initialize();
      return await _storage!.ref().child(fileId).getData();
    } catch (error) {
      logger.severe(error);
      return null;
    }
  }


  @override
  Future<FileModel?> getFile(String fileId) async {
    try {
      await initialize();

      var targetFile = _storage!.ref().child(fileId);
      var targetFileMetaData = await targetFile.getMetadata();
      var targetFileUrl = await targetFile.getDownloadURL();

      var fileThumbnailUrl = await _storage!.ref()
        .child("${myConfig!.serverConfig!.storageConnInfo.bucketId}content/thumbnail/${fileId.substring(fileId.lastIndexOf("/")+1, fileId.lastIndexOf("."))}.jpg")
        .getDownloadURL().onError((error, stackTrace) async {
          logger.info(error);
          return targetFileUrl;
        });

      return FileModel(
        id: targetFileMetaData.fullPath,
        name: targetFileMetaData.name,
        url: targetFileUrl,
        thumbnailUrl: fileThumbnailUrl,
        size: targetFileMetaData.size!,
        contentType: ContentsType.getContentTypes(targetFileMetaData.contentType!)
      );
    } catch(error) {
      logger.info(error);
      return null;
    }
  }




  @override
  Future<List<FileModel>?> getFileList({String search = "", int limit = 99, int? offset, String? cursor, String cursorDirection = "after", String orderType = "DESC"}) async {
    List<FileModel> fileList = [];

    try {
      await initialize();

      // search 파라미터에는 조회하고 싶은 폴더명 입력 (ex. content/image/)
      final targetFileList = await _storage!.ref().child("${myConfig!.serverConfig!.storageConnInfo.bucketId}$search").listAll();
      for(var targetFile in targetFileList.items) {
        var targetFileMetaData = await targetFile.getMetadata();
        var targetFileUrl = await targetFile.getDownloadURL();
        var targetFileThumbnail = await _storage!.ref()
          .child("${myConfig!.serverConfig!.storageConnInfo.bucketId}content/thumbnail/${targetFile.fullPath.substring(targetFile.fullPath.lastIndexOf("/")+1, targetFile.fullPath.lastIndexOf("."))}.jpg")
          .getDownloadURL().onError((error, stackTrace) {
            logger.info(error);
            return targetFileUrl;
          });

        fileList.add(FileModel(
          id: targetFile.fullPath,
          name: targetFileMetaData.name,
          url: targetFileUrl,
          thumbnailUrl: targetFileThumbnail,
          size: targetFileMetaData.size!,
          contentType: ContentsType.getContentTypes(targetFileMetaData.contentType!)
          )
        );
      }
      return fileList;
    } catch (error) {
      logger.info(error);
      return null;
    }
  }


  @override
  Future<bool> downloadFile(String fileId, String fileName) async {
    try {
      Uint8List? targetFileBytes = await _storage!.ref().child(fileId).getData();
      final targetFileUrl = Url.createObjectUrlFromBlob(Blob([targetFileBytes!]));
      AnchorElement(href: targetFileUrl)
        ..setAttribute("download", fileName)
        ..click();
      Url.revokeObjectUrl(targetFileUrl);
      return true;
    } catch (error) {
      logger.severe(error);
      return false;
    }
  }
 
 
  @override
  Future<void> setBucket() async {
    myConfig!.serverConfig!.storageConnInfo.bucketId = "${HycopUtils.genBucketId(AccountManager.currentLoginUser.email, AccountManager.currentLoginUser.userId)}/";
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
          "bucketId" : myConfig!.serverConfig!.storageConnInfo.bucketId.substring(0, myConfig!.serverConfig!.storageConnInfo.bucketId.length -1),
          "folderName" : sourceFileId.replaceAll("/", "%2F"),
          "fileName" : sourceFileName,
          "fileType": sourceFileType,
          "cloudType" : "firebase"
        })
      );
    } catch (error) {
      logger.info(error);
    }
  }

 
}
