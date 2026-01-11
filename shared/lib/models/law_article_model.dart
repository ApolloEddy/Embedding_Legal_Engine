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

/// 按指定条文号筛选
extension LawArticleFilter on List<LawArticle> {
  List<LawArticle> filterByArticleNumber(String articleNumber) {
    return where((a) => a.articleNumber == articleNumber).toList();
  }

  List<LawArticle> filterByLawName(String lawName) {
    return where((a) => a.lawName.contains(lawName)).toList();
  }
}
