import 'dart:io';

List<File> findAllDartFiles(Directory r) {
  return r
      .listSync(recursive: true)
      .whereType<File>()
      .where((element) => element.path.endsWith('.dart'))
      .toList();
}
