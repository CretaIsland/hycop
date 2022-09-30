// ignore_for_file: avoid_print

import 'package:random_string/random_string.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class MyEncrypt {
  static Future<String> toEncrypt(String jsonString) async {
    print(jsonString);

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
    print('offset=$offset');
    print('fakeoffset=$fakeOffset');
    print('key=$encryptionKey');
    print('text=$cypherText');

    String retval = '$fakeOffset$offsetString1$encryptionKey$cypherText$offsetString2';
    print(retval);
    return retval;
  }

  static Future<String> toDecrypt(String cipherString) async {
    print(cipherString);

    if (cipherString.length <= 2) {
      print('String is too short');
      return cipherString;
    }

    int fakeOffset = 0;
    try {
      fakeOffset = int.parse(cipherString.substring(0, 2));
    } catch (e) {
      print('Invalid String');
      return cipherString;
    }
    int offset = (fakeOffset - 16) * 2; // realOffset,
    int keyPosition = offset + 2;

    String keyString = cipherString.substring(keyPosition, keyPosition + 32);

    if (cipherString.length <= keyPosition + 32 + offset) {
      print('String is too short2');
      return cipherString;
    }

    String context = cipherString.substring(keyPosition + 32, cipherString.length - offset);

    encrypt.Key key = encrypt.Key.fromUtf8(keyString);
    encrypt.IV iv = encrypt.IV.fromLength(16);
    final encryptor = encrypt.Encrypter(encrypt.AES(key));
    final normalText = encryptor.decrypt64(context, iv: iv);

    print('offset=$offset');
    print('key=$keyString');
    print('text=$normalText');

    return normalText;
  }
}
