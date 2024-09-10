import 'dart:convert';
import 'package:collection/collection.dart';
import 'dart:html';
import 'package:flutter/foundation.dart';
import 'package:http/browser_client.dart';
import 'package:hycop/common/util/config.dart';
import 'package:hycop/common/util/logger.dart';
import 'package:hycop/hycop/account/account_manager.dart';
//import 'package:hycop/hycop/hycop_factory.dart';
import 'package:hycop/hycop/storage/storage_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

import '../enum/model_enums.dart';
import '../model/file_model.dart';
import '../model/user_model.dart';
import 'abs_storage.dart';

class SupabaseAppStorage extends AbsStorage {
  static String mainBucketId = 'hycop';
  @override
  Future<void> initialize() async {
    if (AbsStorage.sbStorageConn == null) {
      logger.finest('SupabaseStorage initialize');

      AbsStorage.setSupabaseApp(Supabase.instance.client);
    }
  }

  //버킷은 hycop로 정해져 있다(firebase는 기본 하나의 버킷이 있다) 파이어 베이스도 폴더(유저)를 지정하는 것이다
  @override
  Future<void> setBucket() async {
    myConfig!.serverConfig.storageConnInfo.bucketId =
        StorageUtils.createBucketId(AccountManager.currentLoginUser.email,
            AccountManager.currentLoginUser.userId);
    //userFolder를 지정 하는 것임
    // ignore: unused_local_variable
    String? bucketId = myConfig!.serverConfig.storageConnInfo.bucketId;
    //print('supabase mainBucketId:$mainBucketId');
    // ignore: unused_local_variable
    final bucket =
        await Supabase.instance.client.storage.getBucket(mainBucketId);
    //print('supabase bucket.name: ${bucket.name}');
    //print('supabase bucket.id: ${bucket.id}');
    //print('supabase bucket.public: ${bucket.public}');
    // ignore: unused_local_variable
    final bucketUrl = Supabase.instance.client.storage.from(mainBucketId).url;
    //print('supabase bucket.url: $bucketUrl');

    //print('supabase bucketId(userFolder):$bucketId');
  }

  @override
  Future<FileModel?> uploadFile(
    String fileName,
    String fileType,
    Uint8List fileBytes, {
    bool makeThumbnail = false,
    String usageType = "content",
    String? bucketId,
  }) async {
    try {
      bucketId ??= myConfig!.serverConfig.storageConnInfo.bucketId;
      fileName = StorageUtils.sanitizeString(
          StorageUtils.getMD5(fileBytes) + fileName);
      late String folderPath;

      if (usageType == "content") {
        if (fileType.contains("image")) {
          folderPath = "/content/image/";
        } else if (fileType.contains("video")) {
          folderPath = "/content/video/";
          makeThumbnail = true;
        } else {
          folderPath = "/content/etc/";
          if (fileType.contains("pdf")) makeThumbnail = true;
        }
      } else if (usageType == "bookThumbnail") {
        folderPath = "/book/thumbnail/";
      } else if (usageType == "profile") {
        folderPath = "p/rofile/";
      } else if (usageType == "banner") {
        folderPath = "/banner/";
      } else {
        folderPath = "/etc/";
      }

      String? fileId = '$bucketId$folderPath$fileName';
      //print('fileId:$fileId');

      final fileExit = await getFileData(fileId);
      //파일이 이미 존재 하면
      if (fileExit != null) {
        //print('파일이 이미 존재 해요 fileId:$fileExit');
        return fileExit;
      } else {
        //print('파일이 존재 하지 않아요. 업로드를 진행 합니다.');
      }
      // 썸네일 작동후 확인
      if (makeThumbnail) {
        // ignore: unused_local_variable
        final createThumbnailResult =
            await createThumbnail(folderPath, fileName, fileType, bucketId);
        //print('썸네일 생성 결과:$createThumbnailResult');
        // 썸네일 생성 안되고 있음 왜 인지?(펑션스 문제?)
      }

      // ignore: unused_local_variable
      final result = await Supabase.instance.client.storage
          .from(mainBucketId)
          .uploadBinary(fileId, fileBytes);
      //print('uploadFile success!! result:$result');
      //result에 오는 값 : hycop/ks-park-sqisoft-com.3ca5a91e9da54c6e8e10781758e3e4d5/content/image/05ede4a4a175bd4f538ca018ab3e1a72test1.jpg

      return await getFileData(fileId);
    } catch (e) {
      return null;
    }
  }

  //테스트 안됨 // 썸네일 작동후 확인
  @override
  Future<bool> createThumbnail(
      String fileId, String fileName, String fileType, String bucketId) async {
    try {
      http.Client client = http.Client();
      if (client is BrowserClient) {
        client.withCredentials = true;
      }

      var response = await client.post(
          Uri.parse("${myConfig!.serverConfig.apiServerUrl}/createThumbnail"),
          headers: {"Content-type": "application/json"},
          body: jsonEncode({
            "bucketId": bucketId,
            "folderName": fileId.replaceAll("/", "%2F"),
            "fileName": fileName,
            "fileType": fileType,
            "cloudType": "supabase"
          }));
      if (response.statusCode == 200) return true;
    } catch (error) {
      logger.severe("error at Storage.createThumbnail >>> $error");
    }
    return false;
  }

  @override
  Future<bool> deleteFile(String fileId, {String? bucketId}) async {
    try {
      await Supabase.instance.client.storage
          .from(mainBucketId)
          .remove([fileId]);
      //print('deleteFile fileId:$fileId success!!');
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> deleteFileFromUrl(String fileUrl) async {
    try {
      // ignore: unused_local_variable
      final bucketUrl = Supabase.instance.client.storage.from(mainBucketId).url;
      //print('bucketUrl:$bucketUrl');

      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;

      // 파일 경로 추출
      //아래와 같은 형식 이라는 정의가 있어야 한다. (일단은 지금 구조는 정해져 있다.)
      //bucketUrl/object/public/hycop/
      final fileId = pathSegments.skip(2).join('/');
      //print('fileId:$fileId');
      await deleteFile(fileId);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> downloadFile(String fileId, String saveName,
      {String? bucketId}) async {
    try {
      if (kIsWeb) {
        final Uint8List? targetBytes = await getFileBytes(fileId);

        String targetUrl = Url.createObjectUrlFromBlob(Blob([targetBytes]));
        AnchorElement(href: targetUrl)
          ..setAttribute("download", saveName)
          ..click();
        Url.revokeObjectUrl(targetUrl);

        return true;
      }
      return true;
    } catch (e) {
      //print('downloadFile error:$e');
      return false;
    }
  }

  @override
  Future<bool> downloadFileFromUrl(String fileUrl, String saveName) async {
    try {
      // ignore: unused_local_variable
      final bucketUrl = Supabase.instance.client.storage.from(mainBucketId).url;
      //print('bucketUrl:$bucketUrl');

      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;

      // 파일 경로 추출
      //아래와 같은 형식 이라는 정의가 있어야 한다. (일단은 지금 구조는 정해져 있다.)
      //bucketUrl/object/public/hycop/
      final fileId = pathSegments.skip(2).join('/');
      //print('fileId:$fileId');
      await downloadFile(fileId, saveName);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Uint8List?> getFileBytes(String fileId, {String? bucketId}) async {
    try {
      final Uint8List fileBytes = await Supabase.instance.client.storage
          .from(mainBucketId)
          .download(fileId);
      return fileBytes;
    } catch (e) {
      //print('getFileBytes error:$e');
      return null;
    }
  }

  @override
  Future<String> getImageUrl(String path) async {
    try {
      return await getPublicFileUrl(path) ?? '';
    } catch (e) {
      return '';
    }
  }

  @override
  Future<List<FileModel>> getMultiFileData(List<String> fileIds,
      {String? bucketId}) async {
    try {
      List<FileModel> fileDatas = [];
      for (String fileId in fileIds) {
        FileModel? fileData = await getFileData(fileId);
        if (fileData != null) fileDatas.add(fileData);
      }
      return fileDatas;
    } catch (error) {
      logger.info("error at Storage.getMultiFileData >>> $error");
    }
    return List.empty();
  }

  //원본 유지 이동
  @override
  Future<FileModel?> copyFile(String sourceBucketId, String sourceFileId,
      {String? bucketId}) async {
    //print(
    //    'sourceFileId:$sourceFileId'); //ks-park-sqisoft-com.3ca5a91e9da54c6e8e10781758e3e4d5/content/image/05ede4a4a175bd4f538ca018ab3e1a72test1.jpg
    //print(
    //    'bucketId(target):$bucketId'); //ks-park-sqisoft-com.43c6ea3c83284a838dbabcd947e9e6f9

    //파일 존재 여부
    final file = await getFileData(sourceFileId);
    if (file != null) {
      //print('파일 존재 fileModel:${file.toDetailString()}');
    }
    final removeUserFolderPath =
        sourceFileId.substring(sourceFileId.indexOf('/'));

    ///content/image/05ede4a4a175bd4f538ca018ab3e1a72test1.jpg
    //print('removeUserFolderPath:$removeUserFolderPath');

    final targetFileId = '$bucketId$removeUserFolderPath';
    //print(
    //    'targetFileId:$targetFileId'); //ks-park-sqisoft-com.43c6ea3c83284a838dbabcd947e9e6f9/content/image/05ede4a4a175bd4f538ca018ab3e1a72test1.jpg
    try {
      // ignore: unused_local_variable
      final copyResult =
          await Supabase.instance.client.storage.from(mainBucketId).copy(
                sourceFileId,
                targetFileId,
              );
      //print('copyFile success result:$copyResult');
      return await getFileData(targetFileId);
    } catch (e) {
      //print('copyFile error:$e');
      return null;
    }
  }

  @override
  Future<FileModel?> copyFileFromUrl(String fileUrl, {String? bucketId}) async {
    try {
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;

      // 파일 경로 추출
      //아래와 같은 형식 이라는 정의가 있어야 한다. (일단은 지금 구조는 정해져 있다.)
      //bucketUrl/object/public/hycop/
      final fileId = pathSegments.skip(2).join('/');

      return copyFile('', fileId, bucketId: bucketId);
    } catch (e) {
      //print('copyFileFromUrl error:$e');
      return null;
    }
  }

  //원본 삭제 이동
  @override
  Future<FileModel?> moveFile(String sourceBucketId, String sourceFileId,
      {String? bucketId}) async {
    //print(
    //    'sourceFileId:$sourceFileId'); //ks-park-sqisoft-com.3ca5a91e9da54c6e8e10781758e3e4d5/content/image/05ede4a4a175bd4f538ca018ab3e1a72test1.jpg
    //print(
    //    'bucketId(target):$bucketId'); //ks-park-sqisoft-com.43c6ea3c83284a838dbabcd947e9e6f9

    //파일 존재 여부
    final file = await getFileData(sourceFileId);
    if (file != null) {
      //print('파일 존재 fileModel:${file.toDetailString()}');
    }

    final removeUserFolderPath =
        sourceFileId.substring(sourceFileId.indexOf('/'));

    ///content/image/05ede4a4a175bd4f538ca018ab3e1a72test1.jpg
    //print('removeUserFolderPath:$removeUserFolderPath');

    final targetFileId = '$bucketId$removeUserFolderPath';
   // print(
    //    'targetFileId:$targetFileId'); //ks-park-sqisoft-com.43c6ea3c83284a838dbabcd947e9e6f9/content/image/05ede4a4a175bd4f538ca018ab3e1a72test1.jpg

    try {
      // ignore: unused_local_variable
      final moveResult =
          await Supabase.instance.client.storage.from(mainBucketId).move(
                sourceFileId,
                targetFileId,
              );
      //print('moveFile success result:$moveResult');
      return await getFileData(targetFileId);
    } catch (e) {
      logger.severe('moveFile error:$e');
      return null;
    }
  }

  @override
  Future<FileModel?> moveFileFromUrl(String fileUrl, {String? bucketId}) async {
    try {
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;

      // 파일 경로 추출
      //아래와 같은 형식 이라는 정의가 있어야 한다. (일단은 지금 구조는 정해져 있다.)
      //bucketUrl/object/public/hycop/
      final fileId = pathSegments.skip(2).join('/');

      return moveFile('', fileId, bucketId: bucketId);
    } catch (e) {
      logger.severe('moveFileFromUrl error:$e');
      return null;
    }
  }

  //supabase는 fileId를 파일 전체 경로
  //ks-park-sqisoft-com.3ca5a91e9da54c6e8e10781758e3e4d5/content/image/05ede4a4a175bd4f538ca018ab3e1a72test.jpg
  @override
  Future<FileModel?> getFileData(String fileId, {String? bucketId}) async {
    try {
      // 폴더 경로와 파일 이름을 한 줄로 분리
      String fullPath = fileId;
      String folderPath = fullPath.substring(0, fullPath.lastIndexOf('/'));
      String fileName = fullPath.split('/').last;
      final fileObjects = await Supabase.instance.client.storage
          .from(mainBucketId)
          .list(path: folderPath);

      if (fileObjects.isNotEmpty) {
        FileObject? fileObject = fileObjects.firstWhereOrNull(
          (file) => file.name == fileName,
        );
        //print('fileObject:${fileObject?.toDetailString()}');
        //TO DO 썸네일 작동후 확인
        String thumbnailId =
            "${fullPath.substring(0, fullPath.indexOf("/"))}/content/thumbnail/${fileName.substring(0, fileName.lastIndexOf("."))}.jpg";
        //print('thumbnailId:$thumbnailId');

        String? thumbnailUrl = await getPublicFileUrl(thumbnailId);
        //print('getFileData fileId:$fileId, success!!');
        return FileModel(
            id: fullPath,
            name: fileName,
            url: '${await getPublicFileUrl(fullPath)}',
            thumbnailUrl: '$thumbnailUrl',
            size: fileObject?.metadata!['size'],
            contentType: ContentsType.getContentTypes(
                fileObject?.metadata!['mimetype']));
      } else {
        return null;
      }
    } catch (e) {
      //print('getFileObject error:$e');
      return null;
    }
  }

//public url을 통해 FileModel 가져오기
  @override
  Future<FileModel?> getFileDataFromUrl(String fileUrl) async {
    //print('getFileDataFromUrl fileUrl:$fileUrl');
    // ignore: unused_local_variable
    final bucketUrl = Supabase.instance.client.storage.from(mainBucketId).url;
    //print('bucketUrl:$bucketUrl');

    final uri = Uri.parse(fileUrl);
    final pathSegments = uri.pathSegments;

    // 파일 경로 추출
    //아래와 같은 형식 이라는 정의가 있어야 한다. (일단은 지금 구조는 정해져 있다.)
    //bucketUrl/object/public/hycop/
    final fileId = pathSegments.skip(2).join('/');
    //print('fileId:$fileId');
    return getFileData(fileId);
  }

  Future<String?> getPublicFileUrl(String fileId) async {
    try {
      String fullPath = fileId;
      String folderPath = fullPath.substring(0, fullPath.lastIndexOf('/'));
      String fileName = fullPath.split('/').last;

      //파일 존재 여부
      final fileObjects = await Supabase.instance.client.storage
          .from(mainBucketId)
          .list(path: folderPath);

      if (fileObjects.isNotEmpty) {
        
        // ignore: unused_local_variable
        FileObject? fileObject = fileObjects.firstWhereOrNull(
          (file) => file.name == fileName,
        );
      } else {
        //print('file $fullPath does not exists !!');
        return null;
      }

      final publicUrl = Supabase.instance.client.storage
          .from(mainBucketId)
          .getPublicUrl(fullPath);

      //print(
      //    'publicUrl:$publicUrl'); //https://jaeumzhrdayuyqhemhyk.supabase.co/storage/v1/object/public/test_bucket/test_folder/test.jpg
      return publicUrl;
    } catch (e) {
      logger.severe('getPublicFileUrl error:$e');
      return null;
    }
  }
}

extension FileObjectExtension on FileObject {
  String toDetailString() {
    return 'FileObject(name: $name, bucketId: $bucketId, owner: $owner, id: $id, '
        'updatedAt: $updatedAt, createdAt: $createdAt, lastAccessedAt: $lastAccessedAt, '
        'metadata: $metadata, buckets: $buckets)';
  }
}

extension UserModelExtension on UserModel {
  String toDetailString() {
    return 'UserModel(userId:$userId, email:$email, password:$password, name:$name, phone:$phone, imagefile:$imagefile, userType:$userType, secret:$secret)';
  }
}

extension FileModelExtension on FileModel {
  String toDetailString() {
    return 'FileModel(id:$id, name:$name, url:$url, thumbnailUrl:$thumbnailUrl, size:$size, contentType:$contentType)';
  }
}
