import 'package:appwrite/appwrite.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../hycop/model/file_model.dart';



abstract class AbsStorage {

  static Client? _awStorageConn;
  static FirebaseApp? _fbStorageConn;

  static Client? get awStorageConn => _awStorageConn;
  static FirebaseApp? get fbStorageConn => _fbStorageConn;

  static void setAppwriteApp(Client client) => _awStorageConn = client;
  static void setFirebaseApp(FirebaseApp firebaseApp) => _fbStorageConn = firebaseApp;


  Future<void> initialize();
  Future<void> setBucket();
  
  Future<FileModel?> getFileData(String fileId, {String? bucketId});
  Future<FileModel?> getFileDataFromUrl(String fileUrl);
  Future<List<FileModel>> getMultiFileData(List<String> fileIds, {String? bucketId});

  Future<FileModel?> uploadFile(String fileName, String fileType, Uint8List fileBytes, {bool makeThumbnail = false, String usageType = "content", String? bucketId});
  Future<bool> createThumbnail(String fileId, String fileName, String fileType, String bucketId);

  Future<Uint8List?> getFileBytes(String fileId, {String? bucketId});
  Future<bool> downloadFile(String fileId, String saveName, {String? bucketId});
  Future<bool> downloadFileFromUrl(String fileUrl, String saveName);

  Future<bool> deleteFile(String fileId, {String? bucketId});
  Future<bool> deleteFileFromUrl(String fileUrl);

  Future<FileModel?> copyFile(String sourceBucketId, String sourceFileId, {String? bucketId});
  Future<FileModel?> copyFileFromUrl(String fileUrl, {String? bucketId});

  Future<FileModel?> moveFile(String sourceBucketId, String sourceFileId, {String? bucketId});
  Future<FileModel?> moveFileFromUrl(String fileUrl, {String? bucketId});


}