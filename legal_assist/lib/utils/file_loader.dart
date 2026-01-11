import 'file_loader_io.dart' if (dart.library.html) 'file_loader_web.dart';
import 'package:file_picker/file_picker.dart';

/// 跨平台文件加载器接口
abstract class FileLoader {
  /// 读取文件内容为字符串
  static Future<String> readAsString(PlatformFile file) async {
    return loadFileAsString(file);
  }
}
