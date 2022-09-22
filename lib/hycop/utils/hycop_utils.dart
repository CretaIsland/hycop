// ignore_for_file: depend_on_referenced_packages

import 'package:appwrite/appwrite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
// import '../../common/util/config.dart';
// import '../../common/util/logger.dart';
import '../enum/model_enums.dart';
//import 'abs_database.dart';
import 'hycop_exceptions.dart';

class HycopUtils {
  static String midToKey(String mid) {
    int pos = mid.indexOf('=');
    if (pos >= 0 && pos < mid.length - 1) return mid.substring(pos + 1);
    return mid;
  }

  static String collectionFromMid(String mid) {
    int pos = mid.indexOf('=');
    if (pos >= 0 && pos < mid.length - 1) return 'creta_${mid.substring(0, pos)}';
    return 'creta_unknown';
  }

  static String genMid(ExModelType type) {
    String mid = '${type.name}=';
    mid += const Uuid().v4();
    return mid;
  }

  static DateTime dateTimeFromDB(String src) {
    //if (myConfig!.serverType == ServerType.appwrite) {
    return DateTime.parse(src); // yyyy-mm-dd hh:mm:ss.sss
    //}
    //return src.toDate();
  }

  static String dateTimeToDB(DateTime src) {
    //if (myConfig!.serverType == ServerType.appwrite) {
    return src.toString(); // yyyy-mm-dd hh:mm:ss.sss
    //}
    //return src;
  }

  // <!--- new add
  static HycopException getHycopException({dynamic error, required String defaultMessage}) {
    String defMsg;
    if (error is HycopException) {
      return error;
    } else if (error is AppwriteException) {
      AppwriteException ex = error;
      defMsg = '${ex.message} (${ex.code})';
    } else if (error is FirebaseException) {
      FirebaseException ex = error;
      defMsg = '${ex.message} (${ex.code})';
    } else if (error is Exception) {
      Exception ex = error;
      defMsg = '$defaultMessage (${ex.toString()})'; //ex.toString();
    } else {
      defMsg = defaultMessage;
    }
    return HycopException(message: defMsg, exception: error);
  }

  //static HycopException throwHycopException({dynamic error, required String defaultMessage}) => throw getHycopException(defaultMessage: defaultMessage);

  static String stringToSha1(String str) => sha1.convert(utf8.encode(str)).toString();
  // -->
}
