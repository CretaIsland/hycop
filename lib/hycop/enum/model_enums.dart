//import 'dart:ui';

// ignore_for_file: constant_identifier_names

/////////////////
// <!-- 삭제될 예정
enum ExModelType {
  none,
  book,
  page,
  frame,
  contents,
  user,
  team,
  enterprise,
  channel,
  watchHistory,
  playlist,
  favorites,
  subscription,
  link,
  filter,
  connected_user,
  comment,
  end;

  static int validCheck(int val) => (val > end.index || val < none.index) ? none.index : val;
  static ExModelType fromInt(int? val) => ExModelType.values[validCheck(val ?? none.index)];
}
///////////////////-->

enum AccountSignUpType {
  none,
  hycop,
  google,
  //facebook,
  //instagram,
  //twitter,
  end;

  static int validCheck(int val) => (val > end.index || val < none.index) ? none.index : val;
  static AccountSignUpType fromInt(int? val) =>
      AccountSignUpType.values[validCheck(val ?? none.index)];
}

enum ContentsType {
  none,
  video,
  image,
  text,
  youtube,
  effect,
  sticker,
  music,
  wheather,
  news,
  document,
  datasheet,
  pdf,
  threeD,
  web,
  octetstream,
  end;

  static int validCheck(int val) => (val > end.index || val < none.index) ? none.index : val;
  static ContentsType fromInt(int? val) => ContentsType.values[validCheck(val ?? none.index)];
  static getContentTypes(String contentType) {
    if (contentType.contains("image")) {
      return ContentsType.image;
    } else if (contentType.contains("video")) {
      return ContentsType.video;
    } else if (contentType.contains("audio")) {
      return ContentsType.music;
    } else if (contentType.contains("text")) {
      return ContentsType.text;
    } else if (contentType.contains("pdf")) {
      return ContentsType.pdf;
    } else {
      return ContentsType.octetstream;
    }
  }
}
