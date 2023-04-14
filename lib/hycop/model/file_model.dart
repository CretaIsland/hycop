
import '../enum/model_enums.dart';

class FileModel {

  late String fileId;
  late String fileName;
  late dynamic fileView;
  late String thumbnailUrl;
  late String fileMd5;
  late int fileSize;
  late ContentsType fileType;

  FileModel({
    required this.fileId,
    required this.fileName,
    required this.fileView,
    required this.thumbnailUrl,
    required this.fileMd5,
    required this.fileSize,
    required this.fileType
  });

  Map<String, dynamic> toMap() {
    return {
      'fileId' : fileId,
      'fileName' : fileName,
      'fileView' : fileView,
      'thumbnailUrl' : thumbnailUrl,
      'fileMd5' : fileMd5,
      'fileSize' : fileSize,
      'fileType' : fileType
    };
  }

  void fromMap(Map<String, dynamic> map) {
    fileId = map['fileId'];
    fileName = map['fileName'];
    fileView = map['fileView'];
    thumbnailUrl = map['thumbnailUrl'];
    fileMd5 = map['fileMd5'];
    fileSize = map['fileSize'];
    fileType = map['fileType'];
  }

}