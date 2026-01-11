import 'dart:io';
import 'package:file_picker/file_picker.dart';

/// IO 端实现：从文件路径读取
Future<String> loadFileAsString(PlatformFile file) async {
  if (file.path == null) {
    throw Exception('文件路径为空');
  }
  final ioFile = File(file.path!);
  if (!await ioFile.exists()) {
    throw Exception('文件不存在: ${file.path}');
  }
  return ioFile.readAsString();
}
