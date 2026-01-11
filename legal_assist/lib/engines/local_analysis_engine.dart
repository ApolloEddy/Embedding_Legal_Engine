import 'package:legal_engine_shared/legal_engine_shared.dart';

/// 本地分析引擎（Phase 3）
/// 
/// Phase 3 必须是 100% 本地、确定性、白箱过程。
/// 
/// 禁止：
/// - 调用 LLM
/// - 生成新的 embedding
/// - 修改 yaml
/// 
/// 解释文本只能来自 yaml 的 explanation_template。
class LocalAnalysisEngine {
  /// 默认相似度阈值
  static const double defaultThreshold = 0.45;

  /// 不确定区间边界
  static const double defaultMargin = 0.05;

  /// 执行罪名分析
  /// 
  /// 纯本地、确定性、白箱罪名分析流程：
  /// 1. 根据 analysis_level 选择参与分析的 slot
  /// 2. 对每个候选罪名执行要件匹配
  /// 3. 输出命中要件、缺失要件、不确定要件
  AnalysisResult analyze({
    required YamlBase yamlBase,
    required EmbeddingPackage legalEmbeddings,
    required CaseExtraction caseExtraction,
    int analysisLevel = 1,
    double threshold = defaultThreshold,
    double margin = defaultMargin,
  }) {
    final crimeResults = <CrimeAnalysisResult>[];

    // 1. 获取指定层级的 slots
    final analysisSlots = yamlBase.slots
        .where((s) => s.analysisLevel <= analysisLevel)
        .toList();

    // 2. 对每个罪名进行分析
    for (final crime in yamlBase.crimes) {
      final result = _analyzeCrime(
        crime: crime,
        yamlBase: yamlBase,
        legalEmbeddings: legalEmbeddings,
        caseExtraction: caseExtraction,
        analysisSlots: analysisSlots,
        threshold: threshold,
        margin: margin,
      );
      crimeResults.add(result);
    }

    // 按分数排序
    crimeResults.sort((a, b) => b.overallScore.compareTo(a.overallScore));

    return AnalysisResult(
      analyzedAt: DateTime.now(),
      yamlVersion: yamlBase.yamlVersion,
      embeddingVersion: legalEmbeddings.embeddingVersion,
      analysisLevel: analysisLevel,
      similarityThreshold: threshold,
      crimeResults: crimeResults,
    );
  }

  /// 分析单个罪名
  CrimeAnalysisResult _analyzeCrime({
    required Crime crime,
    required YamlBase yamlBase,
    required EmbeddingPackage legalEmbeddings,
    required CaseExtraction caseExtraction,
    required List<Slot> analysisSlots,
    required double threshold,
    required double margin,
  }) {
    // 过滤要件：仅分析在 analysisSlots 中的 slot
    final effectiveRequiredIds = crime.requiredSlots
        .where((id) => analysisSlots.any((s) => s.slotId == id))
        .toList();
        
    final effectiveExclusionIds = crime.exclusionSlots
        .where((id) => analysisSlots.any((s) => s.slotId == id))
        .toList();

    final effectiveOptionalIds = crime.optionalSlots
        .where((id) => analysisSlots.any((s) => s.slotId == id))
        .toList();

    final hitRequired = <SlotMatchResult>[];
    final missingRequired = <SlotMatchResult>[];
    final hitExclusion = <SlotMatchResult>[];
    final hitOptional = <SlotMatchResult>[];
    final uncertainSlots = <SlotMatchResult>[];

    // 分析必需要件
    for (final slotId in effectiveRequiredIds) {
      final matchResult = _matchSlot(
        slotId: slotId,
        yamlBase: yamlBase,
        legalEmbeddings: legalEmbeddings,
        caseExtraction: caseExtraction,
        threshold: threshold,
        margin: margin,
      );

      switch (matchResult.status) {
        case SlotMatchStatus.hit:
          hitRequired.add(matchResult);
          break;
        case SlotMatchStatus.missing:
          missingRequired.add(matchResult);
          break;
        case SlotMatchStatus.uncertain:
          uncertainSlots.add(matchResult);
          break;
      }
    }

    // 分析排除要件
    for (final slotId in effectiveExclusionIds) {
      final matchResult = _matchSlot(
        slotId: slotId,
        yamlBase: yamlBase,
        legalEmbeddings: legalEmbeddings,
        caseExtraction: caseExtraction,
        threshold: threshold,
        margin: margin,
      );

      if (matchResult.status == SlotMatchStatus.hit) {
        hitExclusion.add(matchResult);
      }
    }
    
    // 分析可选要件 (量刑情节)
    for (final slotId in effectiveOptionalIds) {
      final matchResult = _matchSlot(
        slotId: slotId,
        yamlBase: yamlBase,
        legalEmbeddings: legalEmbeddings,
        caseExtraction: caseExtraction,
        threshold: threshold,
        margin: margin,
      );

      if (matchResult.status == SlotMatchStatus.hit) {
        hitOptional.add(matchResult);
      } else if (matchResult.status == SlotMatchStatus.uncertain) {
        // 可选要件的不确定也记录下来? 目前模型只支持单一 uncertainSlots 列表
        // 我们可以选择记录或者忽略。为了信息完整，记录到 uncertainSlots
        uncertainSlots.add(matchResult);
      }
    }

    // 计算综合分数 (仅基于必需要件)
    final totalRequired = crime.requiredSlots.length; // 注意：分母仍应是总必要要件数，还是当前层级的？
    // 通常分数反映的是"该罪名构成的完整度"。如果 analysisLevel=1，我们只判断核心要件。
    // 建议：分母使用 effectiveRequiredIds.length，如果为0则为0.0
    final effectiveTotal = effectiveRequiredIds.length;
    final overallScore = effectiveTotal > 0
        ? hitRequired.length / effectiveTotal
        : 0.0;

    // 判断是否构成该罪
    bool? isConstituted;
    if (hitExclusion.isNotEmpty) {
      // 存在排除事由 -> 不构成
      isConstituted = false;
    } else if (missingRequired.isEmpty && uncertainSlots.where((s) => crime.requiredSlots.contains(s.slotId)).isEmpty) {
      // 所有"有效"必需要件都命中，且没有必需要件处于不确定状态
      // 注意：uncertainSlots 可能包含 optional slots，这些不应影响 isConstituted
      // 只有 required slots 的 uncertain 才会导致 isConstituted = null
      isConstituted = true;
    } else if (missingRequired.isNotEmpty) {
      // 存在缺失的必需要件 -> 不构成
      isConstituted = false;
    } else {
      // 存在不确定的必需要件 -> 待定
      isConstituted = null;
    }

    // 生成解释文本
    final explanationText = _generateExplanation(
      crime: crime,
      hitRequired: hitRequired,
      missingRequired: missingRequired,
      hitExclusion: hitExclusion,
      hitOptional: hitOptional,
    );

    return CrimeAnalysisResult(
      crimeId: crime.crimeId,
      crimeName: crime.crimeName,
      isConstituted: isConstituted,
      overallScore: overallScore,
      hitRequiredSlots: hitRequired,
      missingRequiredSlots: missingRequired,
      hitExclusionSlots: hitExclusion,
      uncertainSlots: uncertainSlots,
      explanationText: explanationText,
    );
  }

  /// 匹配单个 Slot
  SlotMatchResult _matchSlot({
    required String slotId,
    required YamlBase yamlBase,
    required EmbeddingPackage legalEmbeddings,
    required CaseExtraction caseExtraction,
    required double threshold,
    required double margin,
  }) {
    final slot = yamlBase.findSlotById(slotId);
    if (slot == null) {
      return SlotMatchResult(
        slotId: slotId,
        slotName: '未知 Slot',
        status: SlotMatchStatus.missing,
        statusReason: 'Slot 在 YAML 中不存在',
      );
    }

    // 获取法律 embedding
    final legalEmbedding = legalEmbeddings.getEmbeddingBySlotId(slotId);
    if (legalEmbedding == null) {
      return SlotMatchResult(
        slotId: slotId,
        slotName: slot.slotName,
        status: SlotMatchStatus.missing,
        statusReason: '缺少法律 Embedding',
      );
    }

    // 获取案件提取的 embedding
    final caseSlot = caseExtraction.getExtractionBySlotId(slotId);
    if (caseSlot == null || !caseSlot.hasEmbedding) {
      return SlotMatchResult(
        slotId: slotId,
        slotName: slot.slotName,
        status: SlotMatchStatus.missing,
        statusReason: caseSlot?.slotText != null ? '无法计算 Embedding' : '案情中未提取到相关信息',
      );
    }

    // 计算相似度（纯本地确定性算法）
    final similarity = SimilarityCalculator.cosineSimilarity(
      legalEmbedding.embeddingVector,
      caseSlot.slotEmbedding!,
    );
    
    // [DEBUG LOG]
    print('[DEBUG_XRAY] Slot: ${slot.slotName} ($slotId)');
    print('  -> Legal Vector Mag: ${SimilarityCalculator.magnitude(legalEmbedding.embeddingVector)}');
    print('  -> Case Vector Mag:  ${SimilarityCalculator.magnitude(caseSlot.slotEmbedding!)}');
    print('  -> Cosine Similarity: $similarity');
    print('  -> Threshold: $threshold / Margin: $margin');

    // 分类相似度结果
    final classification = SimilarityCalculator.classifySimilarity(
      similarity,
      threshold: threshold,
      margin: margin,
    );

    SlotMatchStatus status;
    String reason;

    switch (classification) {
      case 1:
        status = SlotMatchStatus.hit;
        reason = '相似度 ${(similarity * 100).toStringAsFixed(1)}% ≥ 阈值';
        print('  -> Result: HIT');
        break;
      case 0:
        status = SlotMatchStatus.uncertain;
        reason = '相似度 ${(similarity * 100).toStringAsFixed(1)}% 处于不确定区间';
        print('  -> Result: UNCERTAIN');
        break;
      default:
        status = SlotMatchStatus.missing;
        reason = '相似度 ${(similarity * 100).toStringAsFixed(1)}% < 阈值';
         print('  -> Result: MISS');
    }

    return SlotMatchResult(
      slotId: slotId,
      slotName: slot.slotName,
      status: status,
      similarityScore: similarity,
      statusReason: reason,
    );
  }

  /// 生成解释文本
  /// 
  /// 解释文本只能来自 yaml 的 explanation_template
  String _generateExplanation({
    required Crime crime,
    required List<SlotMatchResult> hitRequired,
    required List<SlotMatchResult> missingRequired,
    required List<SlotMatchResult> hitExclusion,
    required List<SlotMatchResult> hitOptional,
  }) {
    final buffer = StringBuffer();

    // 使用 yaml 中的解释模板
    String template = crime.explanationTemplate;

    // 替换模板中的占位符
    final slotAnalysis = StringBuffer();

    if (hitRequired.isNotEmpty) {
      slotAnalysis.write('已认定核心要件: ');
      slotAnalysis.write(hitRequired.map((s) => s.slotName).join('、'));
    }

    if (missingRequired.isNotEmpty) {
      if (slotAnalysis.isNotEmpty) slotAnalysis.write('；');
      slotAnalysis.write('缺失核心要件: ');
      slotAnalysis.write(missingRequired.map((s) => s.slotName).join('、'));
    }

    if (hitExclusion.isNotEmpty) {
      if (slotAnalysis.isNotEmpty) slotAnalysis.write('；');
      slotAnalysis.write('存在排除事由: ');
      slotAnalysis.write(hitExclusion.map((s) => s.slotName).join('、'));
    }
    
    if (hitOptional.isNotEmpty) {
      if (slotAnalysis.isNotEmpty) slotAnalysis.write('；');
      slotAnalysis.write('具备量刑/加重情节: ');
      slotAnalysis.write(hitOptional.map((s) => s.slotName).join('、'));
    }

    template = template.replaceAll('{slot_analysis}', slotAnalysis.toString());
    buffer.write(template);

    return buffer.toString();
  }
}
