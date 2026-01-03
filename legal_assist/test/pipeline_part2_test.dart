
import 'dart:io';
import 'dart:convert';
import 'package:legal_engine_shared/legal_engine_shared.dart';
import 'package:program_b/services/asset_loader_service.dart';
import 'package:program_b/services/llm_extraction_service.dart';
import 'package:program_b/engines/local_analysis_engine.dart';
import 'package:path/path.dart' as p;

// 引入 services 需要的 http client (如果是 dart:io 环境，http 包能自动处理)

void main() async {
  print('=== 开始集成测试 Part 2: 罪名分析引擎 (Phase 3) ===');

  // 1. 加载密钥
  print('[1/5] 加载密钥...');
  final aliyunConfig = await SecretsLoader.getAliyunConfig();
  final llmConfig = LlmConfig.aliyunDashScope(apiKey: aliyunConfig.apiKey);

  // 2. 加载资产
  print('[2/5] 加载资产 (YamlBase + Embeddings)...');
  final projectRoot = Directory.current.parent.path;
  final assetLoader = AssetLoaderService();
  
  final yamlPath = p.join(projectRoot, 'assets', 'legal_base.yaml');
  final pakPath = p.join(projectRoot, 'assets', 'embeddings_test.pak');
  
  final yamlBase = await assetLoader.loadYamlBase(yamlPath);
  final embeddingPackage = await assetLoader.loadEmbeddingPackage(pakPath);
  
  final validation = assetLoader.validateAssetConsistency();
  if (!validation.isValid) {
    print('❌ 资产一致性校验失败: ${validation.errorMessage}');
    exit(1);
  }
  print('    资产加载并校验成功');

  // 3. 构造案件事实 (模拟提取结果)
  print('[3/5] 构造测试案情 (CaseExtraction)...');
  // 我们手动构造 CaseExtraction，但使用真实的 Embedding API 来计算向量
  // 这样可以测试 LocalAnalysisEngine 的相似度计算逻辑是否正常工作
  
  // 实例化一个临时的 LlmExtractionService 仅用于计算 embedding（通过私有方法通过反射？或者把 extraction service 的 compute 暴露出来？）
  // 不，LlmExtractionService 没有公开 computeEmbedding。
  // 但是 shared 包的 export 并没有 LlmService (它在 program_a)。
  // 实际上 program_b 也有 LlmExtractionService，它内部有 _computeEmbedding。
  // 我们无法直接访问私有方法。
  
  // 变通方案：我们使用 LlmExtractionService 的 extracting 接口，但提供非常简单的、必然能命中关键词的伪造案情？
  // 或者，我们直接复制 compute logic 在这里？
  // 为了测试的严谨性，我们应该尽量复用代码。
  // 但由于 program_b 没有公开 LlmService，我们只能实例化 LlmExtractionService。
  // 它的 extractFacts 方法依赖 _simpleExtract (关键词匹配)。
  // 我们构造一个包含所有关键词的句子。
  
  // 目标 Slot 及其关键词 (来自 legal_base.yaml):
  // S001: 行为主体 刑事责任能力
  // S002: 犯罪故意
  // S003: 珍贵 濒危 野生动物
  // S005: 禁猎区
  
  // 使用用户提供的真实案例测试
  final caseText = '''
  嫌疑人刘某通过网络渠道联系上游卖家，非法收购穿山甲鳞片并准备倒卖牟利，
  数量较大，查获时相关物品仍存放在其住所内，
  经鉴定为国家一级保护动物制品，主观上具有明显牟利目的。
  ''';
  
  final extractService = LlmExtractionService(config: llmConfig);
  print('    调用 LLM Service 提取并计算 Embedding...');
  
  // 运行提取
  CaseExtraction extraction;
  try {
    extraction = await extractService.extractFacts(
      caseText: caseText,
      slots: yamlBase.slots,
    );
  } catch (e) {
    print('❌ 提取失败: $e');
    exit(1);
  }
  
  print('    提取完成，共提取 ${extraction.slotExtractions.length} 个 Slot');
  for (final slot in extraction.slotExtractions) {
    if (slot.slotText != null) {
      print('      - ${slot.slotId}: ${slot.slotText} (Has Embedding: ${slot.slotEmbedding != null})');
    }
  }

  // 4. 执行本地分析
  print('[4/5] 执行本地分析 (LocalAnalysisEngine)...');
  final engine = LocalAnalysisEngine();
  final result = engine.analyze(
    yamlBase: yamlBase,
    legalEmbeddings: embeddingPackage,
    caseExtraction: extraction,
  );

  // 5. 验证结果
  print('[5/5] 验证分析结果...');
  bool passed = true;
  
  // 检查是否输出了结果
  if (result.crimeResults.isEmpty) {
    print('❌ 错误: 没有产生任何罪名分析结果');
    exit(1);
  }
  
  // 查找 C341_1 (危害珍贵、濒危野生动物罪)
  final c341_1 = result.crimeResults.firstWhere(
    (r) => r.crimeId == 'C341_1', 
    orElse: () => CrimeAnalysisResult(
      crimeId: 'NotFound', 
      crimeName: '', 
      overallScore: 0, 
      hitRequiredSlots: [], 
      missingRequiredSlots: [], 
      hitExclusionSlots: [], 
      uncertainSlots: [],
      explanationText: '',
    )
  );

  if (c341_1.crimeId == 'NotFound') {
    print('❌ 错误: 未找到 C341_1 分析结果');
    passed = false;
  } else {
    print('\n=== C341_1 详细分析报告 ===');
    print('匹配度: ${(c341_1.overallScore * 100).toStringAsFixed(1)}%');
    
    void printSlots(String label, List<SlotMatchResult> slots) {
      if (slots.isEmpty) return;
      print('$label:');
      for (final s in slots) {
        final score = s.similarityScore != null ? (s.similarityScore! * 100).toStringAsFixed(1) : 'N/A';
        print('  - ${s.slotId} (${s.slotName}): $score% - ${s.statusReason}');
      }
    }

    printSlots('✅ 命中要件', c341_1.hitRequiredSlots);
    printSlots('❌ 缺失要件', c341_1.missingRequiredSlots);
    printSlots('⚠️ 不确定要件', c341_1.uncertainSlots);
    
    // 检查 S003
    if (c341_1.missingRequiredSlots.any((s) => s.slotId == 'S003')) {
       // 再深入看看 S003 为什么缺失
       print('\n[DEBUG] S003 缺失原因排查:');
       final s003Extraction = extraction.getExtractionBySlotId('S003');
       if (s003Extraction == null) {
         print('  -> 根本没有为 S003 创建 Extraction 条目');
       } else if (s003Extraction.slotText == null) {
         print('  -> S003 未提取到文本 (slotText is null)');
       } else if (!s003Extraction.hasEmbedding) {
         print('  -> S003 有文本但无 Embedding');
       } else {
         print('  -> S003 有文本和 Embedding，但相似度过低');
         print('  -> 提取文本: ${s003Extraction.slotText}');
       }
    }
  }

  if (passed) {
    print('\n✅✅✅ 集成测试 Part 2 通过！程序 B 核心链路正常。');
  } else {
    print('\n❌❌❌ 测试未完全通过。');
    exit(1);
  }
  
  extractService.dispose();
}
