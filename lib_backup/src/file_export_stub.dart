// Conditional export wrapper. The real implementation is selected by
// conditional imports in the consumer file.

Future<String> writeStringToFile(String filename, String content) async {
  throw UnsupportedError('No platform implementation');
}
