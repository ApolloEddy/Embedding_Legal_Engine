import 'dart:typed_data';
import 'dart:html' as html;

/// Web 端导出：触发下载
Future<String?> exportImageBytes(Uint8List bytes, String filename) async {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
  return filename;
}

/// Web 端打开文件：无操作
Future<void> openExportedFile(String path) async {
  // Web 浏览器已自动处理下载，无需打开
}
