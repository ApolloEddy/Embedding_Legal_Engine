
import 'dart:io';
import 'dart:convert';
import 'package:legal_engine_shared/legal_engine_shared.dart';
import 'package:program_a/services/llm_service.dart';
import 'package:program_a/services/yaml_service.dart';
import 'package:program_a/services/embedding_service.dart';
import 'package:path/path.dart' as p;

void main() async {
  print('=== 开始集成测试 Part 1: Embedding 计算与导出 ===');

  // ... (省略中间代码，使用原始内容直至导出部分)


  // 1. 加载密钥
  print('[1/5] 加载密钥...');
  final aliyunConfig = await SecretsLoader.getAliyunConfig();
  final llmConfig = LlmConfig.aliyunDashScope(
    apiKey: aliyunConfig.apiKey,
    model: aliyunConfig.embeddingModel,
    dimension: aliyunConfig.embeddingDimension, 
  );
  print('    API Key 加载成功');
  print('    Model: ${llmConfig.embeddingModel}');
  print('    Dim: ${llmConfig.embeddingDimension}');

  // 2. 加载 YAML 基座
  print('[2/5] 加载 YAML 基座...');
  final yamlService = YamlService();
  final yamlPath = p.join(Directory.current.parent.path, 'assets', 'legal_base.yaml');
  
  // 使用 loadFromFile(String)
  final yamlBase = await yamlService.loadFromFile(yamlPath);
  print('    加载成功: ${yamlBase.slots.length} 个 Slot, ${yamlBase.crimes.length} 个 Crime');

  // 3. 准备服务
  final llmService = LlmService(config: llmConfig);
  // 不需要 EmbeddingService 实例来进行此手动测试，我们直接从 yamlBase 获取数据并调用 llmService
  print('[3/5] 解析法律条文 (Article 341)...');
  final parser = LawArticleParser();
  final lawDir = p.join(Directory.current.parent.path, 'Law', '刑法');
  final allArticles = await parser.parseDirectory(lawDir);
  final targetArticles = allArticles.filterByArticleNumber('第三百四十一条');
  print('    解析到 ${targetArticles.length} 款相关条文');
  
  print('[4/5] 计算 Embedding (调用 LLM)...');
  try {
    final slotEmbeddings = <SlotEmbedding>[];
    
    for (final slot in yamlBase.slots) {
      print('    Processing Slot: ${slot.slotId} (${slot.slotName})');
      // 构造 Embedding 输入文本
      final inputText = '${slot.slotName}: ${slot.semanticScope}';
      
      final embeddingVector = await llmService.computeEmbedding(inputText);
      
      slotEmbeddings.add(SlotEmbedding(
        slotId: slot.slotId,
        embeddingVector: embeddingVector,
      ));
      
      await Future.delayed(Duration(milliseconds: 200));
    }
    
    final package = EmbeddingPackage(
      embeddingModelId: llmConfig.embeddingModel,
      embeddingVersion: DateTime.now().toIso8601String(),
      dimension: llmConfig.embeddingDimension,
      createdAt: DateTime.now(),
      embeddings: slotEmbeddings,
    );
    
    print('    计算完成，生成 ${package.embeddings.length} 个 Slot Embedding');

    // 5. 导出 .pak
    print('[5/5] 导出 embeddings_test.pak ...');
    final outputPath = p.join(Directory.current.parent.path, 'assets', 'embeddings_test.pak');
    
    // 使用 jsonEncode 序列化为标准 JSON
    await File(outputPath).writeAsString(jsonEncode(package.toJson()));
    
    print('✅ 导出成功: $outputPath');

  } catch (e) {
    print('❌ 计算失败: $e');
    exit(1);
  } finally {
    llmService.dispose();
  }
}
