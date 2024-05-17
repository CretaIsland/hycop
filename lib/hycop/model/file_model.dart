import '../../hycop/enum/model_enums.dart';

class FileModel {
  late String id;
  late String name;
  late String url;
  late String thumbnailUrl;
  late String thumbnailId;
  late int size;
  late ContentsType contentType;

  FileModel(
      {required this.id,
      required this.name,
      required this.url,
      required this.thumbnailUrl,
      required this.thumbnailId,
      required this.size,
      required this.contentType});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'thumbnailId': thumbnailId,
      'size': size,
      'contentType': contentType
    };
  }

  void fromMap(Map<String, dynamic> map) {
    id = map['id'];
    name = map['name'];
    url = map['url'];
    thumbnailUrl = map['thumbnailUrl'];
    thumbnailId = map['thumbnailId'];
    size = map['size'];
    contentType = map['contentType'];
  }
}
