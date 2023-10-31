import 'dart:async';

//import 'package:appwrite/appwrite.dart';
//import 'package:google_docs_clone/app/utils.dart';
import '../../common/util/logger.dart';

class HycopException implements Exception {
  const HycopException({
    required this.message,
    this.code,
    this.exception,
    this.stackTrace,
  });

  final String message;
  final Exception? exception;
  final StackTrace? stackTrace;
  final int? code;

  @override
  String toString() {
    return "HycopException: (${code ?? 'unknown'})($message)";
  }
}

mixin HycopExceptionMixin {
  Future<T> exceptionHandler<T>(
    FutureOr computation, {
    String unknownMessage = 'Hycop Exception',
  }) async {
    try {
      return await computation;
      // } on AppwriteException catch (e) {
      //   trace.warning(e.message, e);
      //   throw RepositoryException(message: e.message ?? 'An undefined error occured');
    } on Exception catch (e, st) {
      logger.severe(unknownMessage, e, st);
      throw HycopException(message: unknownMessage, exception: e, stackTrace: st);
    }
  }
}
