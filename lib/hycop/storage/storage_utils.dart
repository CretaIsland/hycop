import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import '../../hycop.dart';



class StorageUtils {

  // 사용자의 email과 userId를 토대로 bucketId 생성
  static String genBucketId(String email, String userId) {
    String replaceEmail = email.replaceAll(RegExp(r'[!@#$%^&*(),.?":{}|<>]'), "-");
    String bucketId = '$replaceEmail.$userId';
    if (HycopFactory.serverType == ServerType.appwrite) {
      // appwrite (bucketId is max 36 char)
      if (bucketId.length > 36) {
        return bucketId.substring(0, 36);
      }
    }
    else {
      // firebase
      if(replaceEmail.length > 30) {
        return "$replaceEmail.${userId.substring(0, 63-replaceEmail.length)}";
      }
    }
    return bucketId;
  }

  // 파일의 md5 해시 생성
  static String getMD5(Uint8List fileBytes) {
    final digest = md5.convert(fileBytes);
    return digest.toString();
  }

  // firebase, appwrite에서 사용 불가한 특수문자 제거
  static String sanitizeString(String originalText, {String replaceText = "_"}) {
    var reg = RegExp('[^a-zA-Z0-9가-힣.\\sぁ-ゔァ-ヴー々〆〤一-龥\\-\\~\\!\\&\\+\\,\\;\\=\\@\\[\\]\\{\\}]');
    String result = originalText.replaceAll(reg, replaceText);
    return result;
  }


}