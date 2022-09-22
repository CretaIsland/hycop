abstract class AbsFunction {
  Future<void> initialize();
  Future<String> execute({required String functionId, String? params, bool isAsync = true});
}
