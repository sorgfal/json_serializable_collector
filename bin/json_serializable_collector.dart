import 'dart:io';
import 'package:path/path.dart';

import 'find_all_dart_files.dart';
import 'find_all_dart_files_with_annotations.dart';

const jsonSerializableAnnotation = "@JsonSerializable";
void main(List<String> arguments) {
  if (arguments.isEmpty) {
    throw "No first argument. First arg must be output folder";
  }
  var outputDirectory = Directory.fromUri(Uri.parse(arguments[0]));
  if (!outputDirectory.existsSync()) {
    throw "Output folder not exists";
  }
  var curDir = Directory.current;
  var curPackageName = curDir.path
      .replaceAll(curDir.parent.path, '')
      .replaceFirst(separator, '');

  var annotatedFilesContent = findAllDartFilesWithAnnotations(
      findAllDartFiles(curDir), jsonSerializableAnnotation);
  var imports = JsonSerializationTypeCollectionImportGenerator(
          annotatedFilesContent, curDir.path, curPackageName)
      .build();
  var classNames = findAllSerializableClassNames(annotatedFilesContent);
  var outputText =
      JsonSerializationTypeCollectionGenerator(classNames, imports).build();
  var outputFile = File(
      outputDirectory.path + separator + "json_serializable_collector.dart")
    ..createSync();
  outputFile.writeAsStringSync(outputText);
}

List<String> findAllSerializableClassNames(List<File> fileContents) {
  List<String> classNames = [];
  var re = RegExp(r'JsonSerializable\(\)\sclass\s(.*)\s\{');
  for (var file in fileContents) {
    var content = file.readAsStringSync();
    var founded = re.allMatches(content).map((e) => e[1]).toList();

    if (founded.isNotEmpty) {
      for (var className in founded) {
        if (className != null) {
          classNames.add(className);
        }
      }
    }
  }

  return classNames;
}

class JsonSerializationTypeCollectionImportGenerator {
  final String rootPath;
  final String packageName;
  final List<File> files;

  JsonSerializationTypeCollectionImportGenerator(
      this.files, this.rootPath, this.packageName);

  String build() {
    List<String> imports = [];
    for (var f in files) {
      imports.add(
          "import 'package:$packageName/${f.path.replaceAll(rootPath, "").replaceAll(separator + 'lib', '').replaceFirst(separator, "")}';\n");
    }
    return imports.join();
  }
}

class JsonSerializationTypeCollectionGenerator {
  final List<String> classNames;
  final String imports;

  JsonSerializationTypeCollectionGenerator(this.classNames, this.imports);

  String build() {
    var buffer = "";
    buffer += '''
$imports

///
///
///GENERATED DONT CHANGE
///
///%path - output absolute path
///rerun generation = flutter pub run json_serializable_collector %path

class JsonSerializableCollector {
  static final Map<Type, Function> _serializers = {
''';
    for (var className in classNames) {
      buffer += "    $className: _\$${className}Serializer, \n";
    }
    buffer += '''
  };

  static serialize<T>( Map<String,dynamic> body){
    return _serializers[T]!.call(body);
  }

''';

    for (var className in classNames) {
      buffer +=
          "  static $className _\$${className}Serializer(Map<String,dynamic> body)=> $className.fromJson(body);\n";
    }
    buffer += '''
  
}
  ''';
    return buffer;
  }
}
