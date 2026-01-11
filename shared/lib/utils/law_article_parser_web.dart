import '../models/law_article_model.dart';
export '../models/law_article_model.dart';
/// 多格式法律条文解析器 (Web Stub)
class LawArticleParser {
  
  /// 解析法律文件夹
  Future<List<LawArticle>> parseDirectory(String directoryPath) async {
    throw UnimplementedError('Web 端不支持文件系统遍历');
  }

  /// 解析单个文件
  Future<List<LawArticle>> parseFile(String filePath) async {
    throw UnimplementedError('Web 端不支持文件系统读取');
  }
}
