import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// IO 端导出：保存到文档目录
Future<String?> exportImageBytes(Uint8List bytes, String filename) async {
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}${Platform.pathSeparator}$filename';
  final file = File(filePath);
  await file.writeAsBytes(bytes);
  return filePath;
}

/// IO 端打开文件：尝试打开文件夹
Future<void> openExportedFile(String path) async {
  if (Platform.isWindows) {
    // 打开所在文件夹
    final dir = File(path).parent.path;
    await Process.run('explorer', [dir]);
  } else if (Platform.isMacOS) {
    await Process.run('open', ['-R', path]);
  } else if (Platform.isLinux) {
    await Process.run('xdg-open', [File(path).parent.path]);
  }
}
