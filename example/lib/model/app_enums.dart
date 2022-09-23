//import 'dart:ui';
//
// enum ModelType {
//   none,
//   book,
//   page,
//   frame,
//   contents,
//   end;
//
//   static int validCheck(int val) => (val > end.index || val < none.index) ? none.index : val;
//   static ModelType fromInt(int? val) => ModelType.values[validCheck(val ?? none.index)];
// }

enum BookType {
  none,
  signage,
  presentaion,
  end;

  static int validCheck(int val) => (val > end.index || val < none.index) ? none.index : val;
  static BookType fromInt(int? val) => BookType.values[validCheck(val ?? none.index)];
}
