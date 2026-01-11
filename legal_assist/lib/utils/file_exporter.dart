import 'dart:typed_data';
import 'file_exporter_io.dart' if (dart.library.html) 'file_exporter_web.dart';

/// 跨平台文件导出器接口
abstract class FileExporter {
  /// 导出图片数据 (PNG)
  /// 
  /// Web: 触发浏览器下载
  /// Desktop/Mobile: 保存到文档目录
  /// 
  /// 返回: 保存的文件路径 (Web 返回 null 或文件名)
  static Future<String?> exportImage(Uint8List bytes, String filename) async {
    return exportImageBytes(bytes, filename);
  }

  /// 打开文件/文件夹
  static Future<void> openFile(String path) async {
    return openExportedFile(path);
  }
}
