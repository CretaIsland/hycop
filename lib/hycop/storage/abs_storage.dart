import 'package:appwrite/appwrite.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hycop/hycop/model/file_model.dart';


abstract class AbsStorage {

  // appwrite
  static Client? _awStorageConn;
  static FirebaseApp? _fbStorageConn;
  // firebase
  static Client? get awStorageConn => _awStorageConn;
  static FirebaseApp? get fbStorageConn => _fbStorageConn;

  @protected
  static void setAppwriteApp(Client client) => _awStorageConn = client;
  static void setFirebaseApp(FirebaseApp firebaseApp) => _fbStorageConn = firebaseApp;
  
  Future<void> initialize();  // Storage init
  Future<void> setBucket();   // set personal bucket

  Future<FileModel?> uploadFile(String fileName, String fileType, Uint8List fileBytes, {bool makeThumbnail = false, String usageType = "content", String bucketId = ""}); // create file
  Future<FileModel?> getFileData(String fileId, {String bucketId = ""});  // get file info
  Future<List<FileModel>?> getMultiFileData({String search="", int limit = 99, int? offset, String? cursor, String cursorDirection = "after", String orderType = "DESC", String bucketId = ""}); // get multiple file info
  Future<Uint8List?> getFileBytes(String fileId, {String bucketId = ""}); // get file bytes
  Future<bool> deleteFile(String fileId, {String bucketId = ""}); // delete file
  Future<bool> downloadFile(String fileId, String fileName, {String bucketId = ""}); // local download file
  Future<FileModel?> copyFile(String sourceBucketId, String sourceFileId, {String bucketId = ""});  // copy file
  Future<FileModel?> moveFile(String sourceBucketId, String sourceFileId, {String bucketId = ""});  // change file bucket

  Future<bool> createThumbnail(String sourceFileId, String sourceFileName, String sourceFileType, String sourceBucketId);  // create file thumbnail
  Map<String, String> parseFileUrl(String fileUrl); // parse file url. return fileId and buckektId



}
