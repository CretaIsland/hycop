import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:typed_data';

import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;
import 'package:appwrite/appwrite.dart';
import 'package:dart_appwrite/dart_appwrite.dart' as dart_aw;

import '../../common/util/config.dart';
import '../../common/util/logger.dart';
import '../../hycop/account/account_manager.dart';
import '../../hycop/enum/model_enums.dart';
import '../../hycop/model/file_model.dart';
import '../../hycop/storage/abs_storage.dart';
import '../../hycop/storage/storage_utils.dart';

class AppwriteStorage extends AbsStorage {
  Storage? _storage;
  late dart_aw.Storage _awStorage;
  String fileUrl =
      "${myConfig!.serverConfig!.storageConnInfo.storageURL}/storage/buckets/{BUCKET_ID}/files/{FILE_ID}/view?project=${myConfig!.serverConfig!.storageConnInfo.projectId}";

  @override
  Future<void> initialize() async {
    if (AbsStorage.awStorageConn == null) {
      AbsStorage.setAppwriteApp(Client()
        ..setEndpoint(myConfig!.serverConfig!.storageConnInfo.storageURL)
        ..setProject(myConfig!.serverConfig!.storageConnInfo.projectId)
        ..setSelfSigned(status: true));
      _awStorage = dart_aw.Storage(dart_aw.Client()
        ..setEndpoint(myConfig!.serverConfig!.storageConnInfo.storageURL)
        ..setProject(myConfig!.serverConfig!.storageConnInfo.projectId)
        ..setKey(myConfig!.serverConfig!.storageConnInfo.apiKey));
    }
    _storage ??= Storage(AbsStorage.awStorageConn!);
  }

  @override
  Future<void> setBucket() async {
    try {
      myConfig!.serverConfig!.storageConnInfo.bucketId =
          (await _awStorage.getBucket(bucketId: AccountManager.currentLoginUser.userId)).$id;
    } catch (error) {
      // if not exist user bucket
      myConfig!.serverConfig!.storageConnInfo.bucketId = (await _awStorage.createBucket(
              bucketId: AccountManager.currentLoginUser.userId,
              name: AccountManager.currentLoginUser.email,
              permissions: [
            Permission.create(Role.any()),
            Permission.read(Role.any()),
            Permission.update(Role.any()),
            Permission.delete(Role.any())
          ]))
          .$id;
    }
  }

  @override
  Future<FileModel?> uploadFile(String fileName, String fileType, Uint8List fileBytes,
      {bool makeThumbnail = false, String usageType = "content", String bucketId = ""}) async {
    try {
      await initialize();

      bucketId = bucketId.isEmpty ? myConfig!.serverConfig!.storageConnInfo.bucketId : bucketId;
      fileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣.]'), "_");
      String fileId = "";
      switch (usageType) {
        case "content":
          if (fileType.contains("image")) {
            fileId = "img-";
          } else if (fileType.contains("video")) {
            fileId = "vid-";
            makeThumbnail = true;
          } else {
            fileId = "etc-";
            if (fileType.contains("pdf")) makeThumbnail = true;
          }
          break;
        case "profile":
          fileId = "pic-";
          break;
        case "banner":
          fileId = "ad-";
          break;
        case "bookThumbnail":
          // if thumbnail already exist.
          try {
            fileId =
                fileName.substring(fileName.indexOf("book_") + 5, fileName.indexOf("_thumbnail"));
            var thumbnail = await _storage!.getFile(bucketId: bucketId, fileId: fileId);
            await deleteFile(thumbnail.$id);
          } catch (error) {
            logger.info("not exist book thumbnail");
          }
          break;
        default:
          break;
      }
      if (usageType != "bookThumbnail") fileId += StorageUtils.getMD5(fileBytes);

      var target = await getFileData(fileId);
      if (target != null) {
        if (target.thumbnailUrl.isEmpty && makeThumbnail) {
          await createThumbnail(fileId, fileName, fileType, bucketId);
          return await getFileData(fileId);
        }
        return target;
      } else {
        await _storage!.createFile(
            bucketId: bucketId,
            fileId: fileId,
            file: InputFile.fromBytes(bytes: fileBytes, filename: fileName));
        if (makeThumbnail) await createThumbnail(fileId, fileName, fileType, bucketId);
        return await getFileData(fileId);
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
      var target = await _storage!.getFile(bucketId: bucketId, fileId: fileId);
      try {
        // check thumbnail exist
        var targetThumbnail = await _storage!
            .getFile(bucketId: target.bucketId, fileId: "cov-${target.$id.substring(4)}");
        return FileModel(
            id: target.$id,
            name: target.name,
            url: fileUrl
                .replaceAll("{BUCKET_ID}", target.bucketId)
                .replaceAll("{FILE_ID}", target.$id),
            thumbnailUrl: fileUrl
                .replaceAll("{BUCKET_ID}", targetThumbnail.bucketId)
                .replaceAll("{FILE_ID}", targetThumbnail.$id),
            size: target.sizeOriginal,
            contentType: ContentsType.getContentTypes(target.mimeType));
      } catch (error) {
        return FileModel(
            id: target.$id,
            name: target.name,
            url: fileUrl
                .replaceAll("{BUCKET_ID}", target.bucketId)
                .replaceAll("{FILE_ID}", target.$id),
            thumbnailUrl: target.mimeType.contains("image")
                ? fileUrl
                    .replaceAll("{BUCKET_ID}", target.bucketId)
                    .replaceAll("{FILE_ID}", target.$id)
                : "",
            size: target.sizeOriginal,
            contentType: ContentsType.getContentTypes(target.mimeType));
      }
    } catch (error) {
      // file not exist or something error
      logger.info("error during Storage.getFileData >> $error");
    }
    return null;
  }

  @override
  Future<List<FileModel>?> getMultiFileData(
      {String search = "",
      int limit = 99,
      int? offset,
      String? cursor,
      String cursorDirection = "after",
      String orderType = "DESC",
      String bucketId = ""}) async {
    List<FileModel> multiFileData = [];

    try {
      await initialize();

      bucketId = bucketId.isEmpty ? myConfig!.serverConfig!.storageConnInfo.bucketId : bucketId;
      List<String> queries = [];
      queries.add(Query.limit(limit));
      if (offset != null) queries.add(Query.offset(offset));
      if (cursor != null) {
        queries.add(
            cursorDirection == "after" ? Query.cursorAfter(cursor) : Query.cursorBefore(cursor));
      }
      queries
          .add(orderType == "DESC" ? Query.orderDesc("\$updateAt") : Query.orderAsc("\$updateAt"));

      var multiTarget =
          await _storage!.listFiles(bucketId: bucketId, queries: queries, search: search);
      for (var target in multiTarget.files) {
        try {
          // check thumbnail exist
          var targetThumbnail = await _storage!
              .getFile(bucketId: target.bucketId, fileId: "cov-${target.$id.substring(4)}");
          multiFileData.add(FileModel(
              id: target.$id,
              name: target.name,
              url: fileUrl
                  .replaceAll("{BUCKET_ID}", target.bucketId)
                  .replaceAll("{FILE_ID}", target.$id),
              thumbnailUrl: fileUrl
                  .replaceAll("{BUCKET_ID}", targetThumbnail.bucketId)
                  .replaceAll("{FILE_ID}", targetThumbnail.$id),
              size: target.sizeOriginal,
              contentType: ContentsType.getContentTypes(target.mimeType)));
        } catch (error) {
          multiFileData.add(FileModel(
              id: target.$id,
              name: target.name,
              url: fileUrl
                  .replaceAll("{BUCKET_ID}", target.bucketId)
                  .replaceAll("{FILE_ID}", target.$id),
              thumbnailUrl: target.mimeType.contains("image")
                  ? fileUrl
                      .replaceAll("{BUCKET_ID}", target.bucketId)
                      .replaceAll("{FILE_ID}", target.$id)
                  : "",
              size: target.sizeOriginal,
              contentType: ContentsType.getContentTypes(target.mimeType)));
        }
      }
      return multiFileData;
    } catch (error) {
      logger.info("error during Storage.getMultiFileData >> $error");
    }
    return null;
  }

  @override
  Future<Uint8List?> getFileBytes(String fileId, {String bucketId = ""}) async {
    try {
      await initialize();
      bucketId = bucketId.isEmpty ? myConfig!.serverConfig!.storageConnInfo.bucketId : bucketId;
      return await _storage!.getFileDownload(bucketId: bucketId, fileId: fileId);
    } catch (error) {
      logger.info("error during Storage.getFileBytes >> $error");
    }
    return null;
  }

  @override
  Future<bool> deleteFile(String fileId, {String bucketId = ""}) async {
    try {
      await initialize();
      bucketId = bucketId.isEmpty ? myConfig!.serverConfig!.storageConnInfo.bucketId : bucketId;
      await _storage!.deleteFile(bucketId: bucketId, fileId: fileId);
      return true;
    } catch (error) {
      logger.severe("error during Storage.deleteFile >> $error");
    }
    return false;
  }

  @override
  Future<bool> downloadFile(String fileId, String fileName, {String bucketId = ""}) async {
    try {
      await initialize();
      Uint8List? targetBytes = await getFileBytes(fileId, bucketId: bucketId);
      String targetUrl = Url.createObjectUrlFromBlob(Blob([targetBytes]));
      AnchorElement(href: targetUrl)
        ..setAttribute("download", fileName)
        ..click();
      Url.revokeObjectUrl(targetUrl);
      return true;
    } catch (error) {
      logger.severe("error during Storage.downloadFile >> $error");
    }
    return false;
  }

  @override
  Future<FileModel?> copyFile(String sourceBucketId, String sourceFileId,
      {String bucketId = ""}) async {
    try {
      await initialize();
      var target = await getFileData(sourceFileId, bucketId: sourceBucketId);
      if (target != null) {
        var targetBytes = await getFileBytes(sourceFileId, bucketId: sourceBucketId);
        if (targetBytes == null) throw Exception("file bytes is null");
        return await uploadFile(target.name, target.contentType.name, targetBytes,
            bucketId: bucketId, usageType: getUsageType(target.id));
      }
    } catch (error) {
      logger.severe("error during Storage.copyFile >> $error");
    }
    return null;
  }

  @override
  Future<FileModel?> moveFile(String sourceBucketId, String sourceFileId,
      {String bucketId = ""}) async {
    try {
      await initialize();
      var target = await getFileData(sourceFileId, bucketId: sourceBucketId);
      if (target != null) {
        var targetBytes = await getFileBytes(sourceFileId, bucketId: sourceBucketId);
        if (targetBytes == null) throw Exception("file bytes is null");
        var moveFile = await uploadFile(target.name, target.contentType.name, targetBytes,
            bucketId: bucketId, usageType: getUsageType(target.id));

        if (target.thumbnailUrl.isNotEmpty && target.thumbnailUrl != target.url) {
          var targetThumbnailData = parseFileUrl(target.thumbnailUrl);
          await deleteFile(targetThumbnailData["fileId"]!,
              bucketId: targetThumbnailData["bucketId"]!);
        }
        await deleteFile(sourceFileId, bucketId: sourceBucketId);
        return moveFile;
      }
    } catch (error) {
      logger.severe("error during Storage.copyFile >> $error");
    }
    return null;
  }

  @override
  Future<bool> createThumbnail(String sourceFileId, String sourceFileName, String sourceFileType,
      String sourceBucketId) async {
    try {
      http.Client client = http.Client();
      if (client is BrowserClient) {
        client.withCredentials = true;
      }

      var response = await client.post(Uri.parse("https://devcreta.com:553/createThumbnail"),
          headers: {"Content-type": "application/json"},
          body: jsonEncode({
            "bucketId": sourceBucketId,
            "folderName": sourceFileId,
            "fileName": sourceFileName,
            "fileType": sourceFileType,
            "cloudType": "appwrite"
          }));

      if (response.statusCode == 200) return true;
    } catch (error) {
      logger.severe("error during Storage.createThumbnail >> $error");
    }
    return false;
  }

  @override
  Map<String, String> parseFileUrl(String fileUrl) {
    Map<String, String> parseResult = {};

    parseResult.addEntries(<String, String>{
      "bucketId": fileUrl.substring(fileUrl.indexOf("buckets/") + 8, fileUrl.indexOf("/files"))
    }.entries);
    parseResult.addEntries(<String, String>{
      "fileId": fileUrl.substring(fileUrl.indexOf("files/") + 6, fileUrl.indexOf("/view"))
    }.entries);

    return parseResult;
  }

  String getUsageType(String fileId) {
    if (fileId.contains("img-") || fileId.contains("vid-") || fileId.contains("etc-")) {
      return "content";
    } else if (fileId.contains("pic-")) {
      return "profile";
    } else if (fileId.contains("ad-")) {
      return "banner";
    } else {
      return "bookThumbnail";
    }
  }
}
