import 'dart:io';
import 'package:legal_engine_shared/legal_engine_shared.dart';
import 'package:program_a/services/llm_service.dart';
import 'package:program_a/services/embedding_service.dart';
import 'package:program_a/services/yaml_service.dart';
import 'package:yaml/yaml.dart';

void main() async {
  print('=== 开始自动化 Clean Run (Headless Generation) ===');

  // 1. 读取 Secrets
  final secretsFile = File('../secrets.yaml');
  if (!await secretsFile.exists()) {
    print('错误: 找不到 secrets.yaml (CWD: ${Directory.current.path})');
    exit(1);
  }
  final secretsContent = await secretsFile.readAsString();
  final secrets = loadYaml(secretsContent) as YamlMap;
  final aliyun = secrets['aliyun'] as YamlMap;
  final apiKey = aliyun['api_key'] as String;
  
  print('✅ 密钥已加载');

  // 2. 初始化 Services
  final config = LlmConfig.aliyunDashScope(
    apiKey: apiKey, 
    model: 'text-embedding-v4', // 强制指定 v4
    dimension: 1024
  );
  
  final llmService = LlmService(config: config);
  final embeddingService = EmbeddingService(llmService: llmService);
  final yamlService = YamlService();

  // 3. 加载 YAML 基座
  final yamlPath = '../assets/legal_base.yaml';
  YamlBase yamlBase;
  try {
    yamlBase = await yamlService.loadFromFile(yamlPath);
    print('✅ YAML 基座加载成功: ${yamlBase.slots.length} inputs');
  } catch (e) {
    print('❌ YAML 加载失败: $e');
    exit(1);
  }

  // 4. 加载法律条文
  final articlesPath = '../assets/law_articles';
  List<LawArticle> articles = [];
  if (await Directory(articlesPath).exists()) {
    articles = await embeddingService.loadArticlesFromDirectory(articlesPath);
    print('✅ 法律条文加载成功: ${articles.length} 条');
  } else {
    print('⚠️ 警告: 找不到 assets/law_articles 目录? 跳过条文加载 (将影响 Context)');
  }

  // 5. 执行计算
  print('🚀 开始计算 Embedding (Model: ${config.embeddingModel}, Dim: ${config.embeddingDimension})...');
  try {
    final package = await embeddingService.computeEmbeddings(
      yamlBase: yamlBase,
      articles: articles,
      onProgress: (current, total, message) {
        // print('[$current/$total] $message'); // 减少日志刷屏
        stdout.write('\r[$current/$total] $message'.padRight(80));
      },
    );
    print('\n✅ Embedding 计算完成!');

    // 6. 导出包
    final outputPath = '../assets/legal_embeddings_v4.pak';
    await embeddingService.exportPackage(package, outputPath);
    print('✅ 导出成功: $outputPath');
    
    // 验证一下
    final file = File(outputPath);
    print('📦 文件大小: ${(await file.length()) / 1024} KB');

  } catch (e) {
    print('\n❌ 计算/导出失败: $e');
    exit(1);
  }
  
  print('=== Clean Run 成功结束 ===');
  exit(0);
}
