import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:random_string/random_string.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

import 'logger.dart';

// 암호화 방법이 업그레이드 되면 아래 버전도 바꿔준다 (로그 확인용)
String encryptVersion = '1.1.231010';

class MyEncrypt {
  static bool showDebugPrint = false;
  static void _print(Object? object) {
    if (showDebugPrint) {
      if (kDebugMode) {
        print(object);
      }
      else {
        logger.info(object);
      }
    }
  }

  static Future<String> toEncrypt(String jsonString) async {
    _print(jsonString);

    int offset = int.parse(randomNumeric(2));
    offset = (offset % 2) == 0 ? offset : offset + 1; // 항상 짝수로 만듬

    final String encryptionKey = randomAlphaNumeric(32);
    final String offsetString1 = randomAlphaNumeric(offset);
    final String offsetString2 = randomAlphaNumeric(offset);
    encrypt.Key key = encrypt.Key.fromUtf8(encryptionKey);
    encrypt.IV iv = encrypt.IV.fromLength(16);
    final encryptor = encrypt.Encrypter(encrypt.AES(key));
    final cypherText = encryptor.encrypt(jsonString, iv: iv).base64;

    int fakeOffset = (offset / 2).round() + 16;

    String ivText = iv.base64;
    int ivTextLength = ivText.length;

    _print('offset=$offset');
    _print('ivTextLength=$ivTextLength');
    _print('ivText=$ivText');
    _print('fakeoffset=$fakeOffset');
    _print('offsetString1=$offsetString1');
    _print('key=$encryptionKey');
    _print('text=$cypherText');
    _print('offsetString2=$offsetString2');

    String retval =
        '{"encryptVersion":"$encryptVersion","encrypted":"$ivTextLength$ivText$fakeOffset$offsetString1$encryptionKey$cypherText$offsetString2"}';
    _print(retval);
    return retval;
  }

  static Future<String> toDecrypt(String cipherString) async {
    _print(cipherString);

    try {
      final dynamic jsonMap = jsonDecode(cipherString);
      String? jsonStr = jsonMap['encrypted'];
      if (jsonStr == null || jsonStr.isEmpty) {
        logger.severe('It is Empty');
        return cipherString;
      }
      cipherString = jsonStr;
      String encVer = jsonMap['encryptVersion'] ?? '1.0.000000';
      if (encryptVersion.compareTo(encVer) != 0) {
        logger.warning('encryptVersion of json is different from sourceCode !!!');
        logger.warning('encryptVersion(sourceCode)=$encryptVersion');
        logger.warning('encryptVersion(json)=$encVer');
      } else {
        _print('encryptVersion=$encVer');
      }
    } catch (e) {
      logger.severe('It is not json file');
      return cipherString;
    }

    if (cipherString.length <= 2) {
      logger.severe('String is too short');
      return cipherString;
    }

    int ivTextLength = int.parse(cipherString.substring(0, 2));
    String ivText = cipherString.substring(2, ivTextLength + 2);
    cipherString = cipherString.substring(2 + ivTextLength);

    int fakeOffset = 0;
    try {
      fakeOffset = int.parse(cipherString.substring(0, 2));
    } catch (e) {
      logger.severe('Invalid String');
      return cipherString;
    }
    int offset = (fakeOffset - 16) * 2; // realOffset,
    int keyPosition = offset + 2;

    String keyString = cipherString.substring(keyPosition, keyPosition + 32);

    if (cipherString.length <= keyPosition + 32 + offset) {
      logger.severe('String is too short2');
      return cipherString;
    }

    String context = cipherString.substring(keyPosition + 32, cipherString.length - offset);

    encrypt.Key key = encrypt.Key.fromUtf8(keyString);
    encrypt.IV iv = encrypt.IV.fromBase64(ivText);
    final encryptor = encrypt.Encrypter(encrypt.AES(key));
    final normalText = encryptor.decrypt64(context, iv: iv);

    _print('offset=$offset');
    _print('key=$keyString');
    _print('text=$normalText');

    return normalText;
  }
}
