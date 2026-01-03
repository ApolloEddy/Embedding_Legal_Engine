import 'dart:convert';
import 'dart:io';
import 'package:legal_engine_shared/legal_engine_shared.dart';
import 'llm_service.dart';

/// Embedding 计算进度回调
typedef EmbeddingProgressCallback = void Function(int current, int total, String message);

/// Embedding 服务
/// 
/// 程序 A 的核心服务，负责：
/// 1. 遍历法律条文数据库
/// 2. 根据 yaml 中 slot 定义组装 prompt
/// 3. 调用 LLM API 计算 embedding
/// 4. 执行 JSON schema 校验
/// 5. 导出 embedding 包
/// 
/// 禁止：解析案件事实、进行罪名分析、调用任何裁决或推理逻辑
class EmbeddingService {
  final LlmService llmService;

  EmbeddingService({required this.llmService});

  /// 计算法律 Embedding
  /// 
  /// 严格按照以下流程执行：
  /// 1. 读取 yaml（已传入）
  /// 2. 遍历法律条文（一次一个文件）
  /// 3. 根据 slot 定义组装 prompt
  /// 4. 调用 LLM API
  /// 5. 解析输出：slot_id → embedding
  /// 6. 执行 JSON schema 校验
  /// 7. 返回 embedding 包
  Future<EmbeddingPackage> computeEmbeddings({
    required YamlBase yamlBase,
    required List<LawArticle> articles,
    EmbeddingProgressCallback? onProgress,
  }) async {
    final slotEmbeddings = <SlotEmbedding>[];
    final processedSlots = <String>{};

    int current = 0;
    final total = yamlBase.slots.length;

    // 为每个 slot 计算 embedding
    for (final slot in yamlBase.slots) {
      current++;
      onProgress?.call(current, total, '正在处理: ${slot.slotName}');

      // 如果已处理过该 slot，跳过
      if (processedSlots.contains(slot.slotId)) continue;

      // 组装 prompt：使用 slot 的 semantic_scope 作为核心语义
      final promptText = _buildPromptForSlot(slot, articles);

      try {
        // 调用 LLM API 计算 embedding
        final embedding = await llmService.computeEmbedding(promptText);

        slotEmbeddings.add(SlotEmbedding(
          slotId: slot.slotId,
          embeddingVector: embedding,
          sourceArticleId: null, // 综合多条文
        ));

        processedSlots.add(slot.slotId);
      } catch (e) {
        // 记录错误但继续处理其他 slot
        onProgress?.call(current, total, '错误: ${slot.slotName} - $e');
      }
    }

    // 构建 embedding 包
    final package = EmbeddingPackage(
      embeddingModelId: llmService.config.embeddingModel,
      embeddingVersion: '1.0.0',
      createdAt: DateTime.now(),
      dimension: llmService.config.embeddingDimension,
      embeddings: slotEmbeddings,
    );

    // 校验 embedding 包格式
    final validation = JsonSchemaValidator.validateEmbeddingPackage(package.toJson());
    if (!validation.isValid) {
      throw Exception('Embedding package validation failed: ${validation.errorMessage}');
    }

    return package;
  }

  /// 为 slot 构建用于 embedding 的 prompt
  String _buildPromptForSlot(Slot slot, List<LawArticle> articles) {
    final buffer = StringBuffer();

    // 使用 semantic_scope 作为核心语义描述
    buffer.writeln(slot.semanticScope);
    buffer.writeln();

    // 添加相关法律条文上下文（限制长度避免 token 溢出）
    int addedArticles = 0;
    const maxArticles = 3; // 限制每个 slot 最多关联 3 条法律条文

    for (final article in articles) {
      if (addedArticles >= maxArticles) break;

      // 简单的关键词匹配来筛选相关条文
      if (_isArticleRelevantToSlot(article, slot)) {
        buffer.writeln('相关法条: ${article.lawName} ${article.articleNumber}');
        buffer.writeln(article.content);
        buffer.writeln();
        addedArticles++;
      }
    }

    return buffer.toString().trim();
  }

  /// 判断法律条文是否与 slot 相关
  bool _isArticleRelevantToSlot(LawArticle article, Slot slot) {
    final keywords = slot.semanticScope.split(RegExp(r'[，、。；\s]+'));
    // 组合标题和内容进行搜索
    final articleText = '${article.lawName} ${article.articleNumber} ${article.content}';

    for (final keyword in keywords) {
      if (keyword.length >= 2 && articleText.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  /// 从目录加载法律条文
  /// 使用 shared 包中的 LawArticleParser
  Future<List<LawArticle>> loadArticlesFromDirectory(String directoryPath) async {
    final parser = LawArticleParser();
    try {
      return await parser.parseDirectory(directoryPath);
    } catch (e) {
      // 简单处理错误，返回空列表或重新抛出取决于需求
      // 这里为了 UI 层的简单性，我们捕获错误但打印日志
      print('加载法律文件失败: $e');
      return [];
    }
  }

  /// 导出 Embedding 包到文件
  Future<void> exportPackage(EmbeddingPackage package, String filePath) async {
    final jsonContent = jsonEncode(package.toJson());
    final file = File(filePath);
    await file.writeAsString(jsonContent);
  }

  /// 从文件加载 Embedding 包
  Future<EmbeddingPackage> loadPackage(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('Embedding 包文件不存在', filePath);
    }

    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;

    // 校验格式
    final validation = JsonSchemaValidator.validateEmbeddingPackage(json);
    if (!validation.isValid) {
      throw Exception('Embedding package validation failed: ${validation.errorMessage}');
    }

    return EmbeddingPackage.fromJson(json);
  }
}
