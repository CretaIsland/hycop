import 'dart:typed_data';

import '../model/file_model.dart';
import 'abs_storage.dart';

class SupabaseAppStorage extends AbsStorage {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> setBucket() async {}

  @override
  Future<FileModel?> getFileData(String fileId, {String? bucketId}) async {
    return null;
  }

  @override
  Future<FileModel?> getFileDataFromUrl(String fileUrl) async {
    return null;
  }

  @override
  Future<List<FileModel>> getMultiFileData(List<String> fileIds,
      {String? bucketId}) async {
    return [];
  }

  @override
  Future<FileModel?> uploadFile(
      String fileName, String fileType, Uint8List fileBytes,
      {bool makeThumbnail = false,
      String usageType = "content",
      String? bucketId}) async {
    return null;
  }

  @override
  Future<bool> createThumbnail(
      String fileId, String fileName, String fileType, String bucketId) async {
    return false;
  }

  @override
  Future<Uint8List?> getFileBytes(String fileId, {String? bucketId}) async {
    return null;
  }

  @override
  Future<bool> downloadFile(String fileId, String saveName,
      {String? bucketId}) async {
    return false;
  }

  @override
  Future<bool> downloadFileFromUrl(String fileUrl, String saveName) async {
    return false;
  }

  @override
  Future<bool> deleteFile(String fileId, {String? bucketId}) async {
    return false;
  }

  @override
  Future<bool> deleteFileFromUrl(String fileUrl) async {
    return false;
  }

  @override
  Future<FileModel?> copyFile(String sourceBucketId, String sourceFileId,
      {String? bucketId}) async {
    return null;
  }

  @override
  Future<FileModel?> copyFileFromUrl(String fileUrl, {String? bucketId}) async {
    return null;
  }

  @override
  Future<FileModel?> moveFile(String sourceBucketId, String sourceFileId,
      {String? bucketId}) async {
    return null;
  }

  @override
  Future<FileModel?> moveFileFromUrl(String fileUrl, {String? bucketId}) async {
    return null;
  }

  @override
  Future<String> getImageUrl(String path) async {
    return '';
  }
}
