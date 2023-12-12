import 'package:appwrite/appwrite.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hycop/hycop/model/file_model.dart';


abstract class AbsStorage {


  static Client? _awStorageConn;
  static FirebaseApp? _fbStorageConn;


  static Client? get awStorageConn => _awStorageConn;
  static FirebaseApp? get fbStorageConn => _fbStorageConn;


  @protected
  static void setAppwriteApp(Client client) => _awStorageConn = client;
  static void setFirebaseApp(FirebaseApp firebaseApp) => _fbStorageConn = firebaseApp;




  Future<void> initialize();
  Future<FileModel?> uploadFile(String fileName, String fileType, Uint8List fileBytes, {bool makeThumbnail = false, String fileUsage = "content"});
  Future<void> deleteFile(String fileId);
  Future<Uint8List?> getFileBytes(String fileId);
  Future<FileModel?> getFile(String fileId);
  Future<List<FileModel>?> getFileList({String search = "", int limit = 99, int? offset, String? cursor, String cursorDirection = "after", String orderType = "DESC"});
  Future<bool> downloadFile(String fileId, String fileName);
  Future<void> setBucket();
  Future<void> createThumbnail(String sourceFileId, String sourceFileName, String sourceFileType);
  Future<FileModel?> copyFile(String targetFileurl, {String targetThumbnailUrl = ""});


}
