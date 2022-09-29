// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
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

  static String getClassName(String mid) {
    int pos = mid.indexOf('=');
    if (pos > 0 && pos < mid.length - 1) return mid.substring(0, pos);
    return mid;
  }

  static String collectionFromMid(String mid, String prefix) {
    int pos = mid.indexOf('=');
    if (pos >= 0 && pos < mid.length - 1) return '${prefix}_${mid.substring(0, pos)}';
    return '${prefix}_unknown';
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

  static String hideString(String org, {int max = 0}) {
    int len = org.length;
    if (len < 6) {
      return "*****";
    }
    if (max > 0 && len > max) {
      len = max;
    }
    int half = (len / 2).round();
    String postFix = '';
    for (int i = 0; i < half; i++) {
      postFix += '*';
    }
    return org.substring(0, half) + postFix;
  }

  static Color stringToColor(String? colorStr) {
    if (colorStr != null && colorStr.length > 16) {
      int pos = colorStr.indexOf('0x');
      String key = colorStr.substring(pos + 2, pos + 2 + 8);
      return Color(int.parse(key, radix: 16));
    }
    return Colors.transparent;
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


  // 사용자의 email과 userId를 토대로 bucketId 생성
  static String genBucketId(String email, String userId) {
    String replaceEmail = email.replaceAll(RegExp(r'[!@#$%^&*(),.?":{}|<>]'), "-");
    return "$replaceEmail.${userId.substring(0, 35-replaceEmail.length)}";
  }

}
