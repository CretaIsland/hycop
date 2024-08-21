abstract class AbsFunction {
  Future<void> initialize();
  Future<String> execute({required String functionId, String? params, bool isAsync = true});
  Future<String> execute2(
      {required String functionId, Map<String, dynamic>? params, bool isAsync = true});
}
