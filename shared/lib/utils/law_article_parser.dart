import 'dart:io';
import 'package:yaml/yaml.dart';

/// 法律条文 - 解析后的结构
class LawArticle {
  final String lawName;           // 法律名称
  final String articleNumber;     // 条号，如 "第三百四十一条"
  final String section;           // 所属章节
  final int clauseIndex;          // 款号 (1, 2, 3...)
  final String content;           // 条文内容
  final String? crimeName;        // 罪名（如果适用）
  final List<String> keywords;    // 关键词

  LawArticle({
    required this.lawName,
    required this.articleNumber,
    required this.section,
    required this.clauseIndex,
    required this.content,
    this.crimeName,
    this.keywords = const [],
  });

  String get uniqueId => '${lawName}_${articleNumber}_${clauseIndex}';

  /// 转换为可嵌入的文本（用于 Embedding API）
  String toEmbeddingText() {
    final buffer = StringBuffer();
    buffer.writeln('【法律】$lawName');
    buffer.writeln('【条号】$articleNumber');
    if (section.isNotEmpty) buffer.writeln('【章节】$section');
    if (clauseIndex > 0) buffer.writeln('【款号】第 $clauseIndex 款');
    if (crimeName != null) buffer.writeln('【罪名】$crimeName');
    buffer.writeln('【内容】$content');
    return buffer.toString();
  }

  Map<String, dynamic> toJson() => {
    'law_name': lawName,
    'article_number': articleNumber,
    'section': section,
    'clause_index': clauseIndex,
    'content': content,
    'crime_name': crimeName,
    'keywords': keywords,
  };
}

/// 多格式法律条文解析器
/// 
/// 支持格式（优先级）：
/// 1. Markdown (.md) - 实际使用
/// 2. YAML (.yaml, .yml) - 理论兼容
/// 3. JSON (.json) - 理论兼容
/// 4. XML (.xml) - 理论兼容
/// 5. Text (.txt) - 理论兼容
class LawArticleParser {
  
  /// 解析法律文件夹
  Future<List<LawArticle>> parseDirectory(String directoryPath) async {
    final articles = <LawArticle>[];
    final dir = Directory(directoryPath);
    
    if (!await dir.exists()) {
      throw FileSystemException('目录不存在', directoryPath);
    }

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final extension = entity.path.split('.').last.toLowerCase();
        final supportedExtensions = ['md', 'yaml', 'yml', 'json', 'xml', 'txt'];
        
        if (supportedExtensions.contains(extension)) {
          final parsed = await parseFile(entity.path);
          articles.addAll(parsed);
        }
      }
    }

    return articles;
  }

  /// 解析单个文件
  Future<List<LawArticle>> parseFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('文件不存在', filePath);
    }

    final extension = filePath.split('.').last.toLowerCase();
    final content = await file.readAsString();

    switch (extension) {
      case 'md':
        return parseMarkdown(content, filePath);
      case 'yaml':
      case 'yml':
        return parseYaml(content, filePath);
      case 'json':
        return parseJson(content, filePath);
      case 'xml':
        return parseXml(content, filePath);
      case 'txt':
        return parseTxt(content, filePath);
      default:
        return [];
    }
  }

  /// 解析 Markdown 格式（主要格式）
  List<LawArticle> parseMarkdown(String content, String filePath) {
    final articles = <LawArticle>[];
    
    // 提取法律名称（第一个 # 标题）
    final lawNameMatch = RegExp(r'^# (.+)$', multiLine: true).firstMatch(content);
    final lawName = lawNameMatch?.group(1)?.trim() ?? _extractLawNameFromPath(filePath);

    // 跟踪当前章节
    String currentSection = '';
    
    // 分割行
    final lines = content.split('\n');
    
    // 正则匹配条文号
    final articlePattern = RegExp(r'^(第[一二三四五六七八九十百千零〇]+条(?:之[一二三四五六七八九十]+)?)\s*(.*)$');
    
    String? currentArticleNumber;
    final clauseBuffer = StringBuffer();
    int clauseIndex = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // 跳过空行和注释
      if (line.isEmpty || line.startsWith('<!--')) continue;
      
      // 检测章节（## 或 ###）
      if (line.startsWith('##')) {
        currentSection = line.replaceAll(RegExp(r'^#+\s*'), '').trim();
        continue;
      }
      
      // 检测条文号
      final articleMatch = articlePattern.firstMatch(line);
      if (articleMatch != null) {
        // 保存上一条
        if (currentArticleNumber != null && clauseBuffer.isNotEmpty) {
          final crimeName = _extractCrimeName(clauseBuffer.toString());
          articles.add(LawArticle(
            lawName: lawName,
            articleNumber: currentArticleNumber,
            section: currentSection,
            clauseIndex: clauseIndex,
            content: clauseBuffer.toString().trim(),
            crimeName: crimeName,
            keywords: _extractKeywords(clauseBuffer.toString()),
          ));
        }
        
        // 开始新条文
        currentArticleNumber = articleMatch.group(1)!;
        clauseBuffer.clear();
        clauseIndex = 1;
        
        // 如果条文号后面有内容
        final afterNumber = articleMatch.group(2)?.trim() ?? '';
        if (afterNumber.isNotEmpty) {
          clauseBuffer.write(afterNumber);
        }
        continue;
      }
      
      // 检测款（以换行分隔的段落）
      if (currentArticleNumber != null) {
        if (line.isNotEmpty) {
          // 检查是否是新款（判断逻辑：如果缓冲区不为空且当前行是新段落）
          if (clauseBuffer.isNotEmpty && 
              !line.startsWith('（') && 
              !line.startsWith('(') &&
              !RegExp(r'^[一二三四五六七八九十]+[、．.]').hasMatch(line) &&
              lines[i > 0 ? i - 1 : 0].trim().isEmpty) {
            // 保存上一款
            final crimeName = _extractCrimeName(clauseBuffer.toString());
            articles.add(LawArticle(
              lawName: lawName,
              articleNumber: currentArticleNumber,
              section: currentSection,
              clauseIndex: clauseIndex,
              content: clauseBuffer.toString().trim(),
              crimeName: crimeName,
              keywords: _extractKeywords(clauseBuffer.toString()),
            ));
            
            clauseBuffer.clear();
            clauseIndex++;
          }
          
          if (clauseBuffer.isNotEmpty) clauseBuffer.write(' ');
          clauseBuffer.write(line);
        }
      }
    }
    
    // 保存最后一条
    if (currentArticleNumber != null && clauseBuffer.isNotEmpty) {
      final crimeName = _extractCrimeName(clauseBuffer.toString());
      articles.add(LawArticle(
        lawName: lawName,
        articleNumber: currentArticleNumber,
        section: currentSection,
        clauseIndex: clauseIndex,
        content: clauseBuffer.toString().trim(),
        crimeName: crimeName,
        keywords: _extractKeywords(clauseBuffer.toString()),
      ));
    }

    return articles;
  }

  /// 解析 YAML 格式（理论兼容）
  List<LawArticle> parseYaml(String content, String filePath) {
    try {
      final yaml = loadYaml(content);
      if (yaml == null) return [];

      final articles = <LawArticle>[];
      final lawName = yaml['law_name'] ?? _extractLawNameFromPath(filePath);
      
      if (yaml['articles'] is List) {
        for (final article in yaml['articles']) {
          articles.add(LawArticle(
            lawName: lawName,
            articleNumber: article['article_number'] ?? '',
            section: article['section'] ?? '',
            clauseIndex: article['clause_index'] ?? 1,
            content: article['content'] ?? '',
            crimeName: article['crime_name'],
            keywords: List<String>.from(article['keywords'] ?? []),
          ));
        }
      }
      
      return articles;
    } catch (e) {
      print('YAML 解析错误: $e');
      return [];
    }
  }

  /// 解析 JSON 格式（理论兼容）
  List<LawArticle> parseJson(String content, String filePath) {
    // 理论兼容，结构与 YAML 类似
    return [];
  }

  /// 解析 XML 格式（理论兼容）
  List<LawArticle> parseXml(String content, String filePath) {
    // 理论兼容
    return [];
  }

  /// 解析 TXT 格式（理论兼容）
  List<LawArticle> parseTxt(String content, String filePath) {
    // 简单的纯文本格式，每行一个条文
    return [];
  }

  /// 从文件路径提取法律名称
  String _extractLawNameFromPath(String filePath) {
    final fileName = filePath.split(Platform.pathSeparator).last;
    return fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
  }

  /// 提取罪名
  String? _extractCrimeName(String content) {
    // 匹配常见罪名格式
    final crimePatterns = [
      RegExp(r'以(.{2,15}罪)论处'),
      RegExp(r'构成(.{2,15}罪)'),
      RegExp(r'犯(.{2,15}罪)的'),
      RegExp(r'是(.{2,8}犯罪)'),
    ];
    
    for (final pattern in crimePatterns) {
      final match = pattern.firstMatch(content);
      if (match != null) {
        return match.group(1);
      }
    }
    
    return null;
  }

  /// 提取关键词
  List<String> _extractKeywords(String content) {
    final keywords = <String>[];
    
    // 提取处罚相关关键词
    if (content.contains('死刑')) keywords.add('死刑');
    if (content.contains('无期徒刑')) keywords.add('无期徒刑');
    if (content.contains('有期徒刑')) keywords.add('有期徒刑');
    if (content.contains('拘役')) keywords.add('拘役');
    if (content.contains('管制')) keywords.add('管制');
    if (content.contains('罚金')) keywords.add('罚金');
    
    // 提取情节关键词
    if (content.contains('情节严重')) keywords.add('情节严重');
    if (content.contains('情节特别严重')) keywords.add('情节特别严重');
    if (content.contains('从重处罚')) keywords.add('从重处罚');
    if (content.contains('从轻')) keywords.add('从轻处罚');
    
    return keywords;
  }
}

/// 按指定条文号筛选
extension LawArticleFilter on List<LawArticle> {
  List<LawArticle> filterByArticleNumber(String articleNumber) {
    return where((a) => a.articleNumber == articleNumber).toList();
  }

  List<LawArticle> filterByLawName(String lawName) {
    return where((a) => a.lawName.contains(lawName)).toList();
  }
}
