import 'dart:io';

List<File> findAllDartFilesWithAnnotations(
    List<File> files, String annotation) {
  List<File> filesContentWithAnnotations = [];
  for (var file in files) {
    var content = file.readAsStringSync();
    if (content.contains(annotation)) {
      filesContentWithAnnotations.add(file);
    }
  }
  return filesContentWithAnnotations;
}
