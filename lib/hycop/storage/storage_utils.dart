import 'dart:typed_data';
// ignore: depend_on_referenced_packages
import '../enum/model_enums.dart';
// ignore: depend_on_referenced_packages
import 'package:crypto/crypto.dart';
// ignore: depend_on_referenced_packages
import 'package:uuid/uuid.dart';

class StorageUtils {

  static String getMD5(Uint8List fileBytes) {
    final digest = md5.convert(fileBytes);
    return digest.toString();
  }

  static String genCid(ContentsType contentType) {
    String mid = "${contentType.name}=";
    mid += const Uuid().v4();
    return mid;
  }

  static String cidToKey(String cid) {
    int pos = cid.indexOf("=");
    if(pos >= 0 && pos < cid.length - 1) return cid.substring(pos + 1);
    return cid;
  }

}