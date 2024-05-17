import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import '../../hycop.dart';



class StorageUtils {

  // 유저의 이메일과 userId을 이용해 생성
  static String createBucketId(String email, String userId) {
    if(HycopFactory.serverType == ServerType.appwrite) {
      return userId;
    } else {  //firebase
      String replaceEmail = email.replaceAll(RegExp(r'[!@#$%^&*(),.?":{}|<>]'), "-");
      return "$replaceEmail.$userId";
    }
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