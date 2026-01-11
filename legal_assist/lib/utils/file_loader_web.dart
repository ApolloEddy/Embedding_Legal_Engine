import 'dart:convert';
import 'package:file_picker/file_picker.dart';

/// Web 端实现：从内存 bytes 读取
Future<String> loadFileAsString(PlatformFile file) async {
  if (file.bytes == null) {
    throw Exception('Web 端文件读取失败: bytes 为空');
  }
  return utf8.decode(file.bytes!);
}
