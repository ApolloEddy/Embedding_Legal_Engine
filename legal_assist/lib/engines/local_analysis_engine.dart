import 'package:legal_engine_shared/legal_engine_shared.dart';

/// 本地分析引擎（Phase 3）- 自适应分层版本
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

  /// 执行自适应分层罪名分析
  /// 
  /// 自动执行 L1→L2→L3 全量分层分析：
  /// - Level 1: 核心构成要件比对
  /// - Level 2: 排除阻却事由扫描
  /// - Level 3: 量刑情节分析
  TieredAnalysisResult analyze({
    required YamlBase yamlBase,
    required EmbeddingPackage legalEmbeddings,
    required CaseExtraction caseExtraction,
    double threshold = defaultThreshold,
    double margin = defaultMargin,
  }) {
    final crimeAnalyses = <TieredCrimeAnalysis>[];

    // 对每个罪名执行分层分析
    for (final crime in yamlBase.crimes) {
      final result = _analyzeCrimeTiered(
        crime: crime,
        yamlBase: yamlBase,
        legalEmbeddings: legalEmbeddings,
        caseExtraction: caseExtraction,
        threshold: threshold,
        margin: margin,
      );
      crimeAnalyses.add(result);
    }

    // 按分数排序
    crimeAnalyses.sort((a, b) => b.overallScore.compareTo(a.overallScore));

    return TieredAnalysisResult(
      analyzedAt: DateTime.now(),
      yamlVersion: yamlBase.yamlVersion,
      embeddingVersion: legalEmbeddings.embeddingVersion,
      similarityThreshold: threshold,
      crimeAnalyses: crimeAnalyses,
    );
  }

  /// 分层分析单个罪名
  TieredCrimeAnalysis _analyzeCrimeTiered({
    required Crime crime,
    required YamlBase yamlBase,
    required EmbeddingPackage legalEmbeddings,
    required CaseExtraction caseExtraction,
    required double threshold,
    required double margin,
  }) {
    // ========== Level 1: 核心构成要件分析 ==========
    final coreElements = _analyzeLevel1(
      crime: crime,
      yamlBase: yamlBase,
      legalEmbeddings: legalEmbeddings,
      caseExtraction: caseExtraction,
      threshold: threshold,
      margin: margin,
    );

    ExclusionResult? exclusionAnalysis;
    SentencingResult? sentencingAnalysis;
    CrimeConclusion finalConclusion;

    // 判断 L1 结果
    if (!coreElements.isPreliminaryConstituted) {
      // L1 不通过 -> 直接判定不构成
      if (coreElements.uncertainSlots.isNotEmpty) {
        finalConclusion = CrimeConclusion.uncertain;
      } else {
        finalConclusion = CrimeConclusion.notConstitutedMissingElements;
      }
    } else {
      // L1 通过 -> 进入 L2
      // ========== Level 2: 排除阻却事由分析 ==========
      exclusionAnalysis = _analyzeLevel2(
        crime: crime,
        yamlBase: yamlBase,
        legalEmbeddings: legalEmbeddings,
        caseExtraction: caseExtraction,
        threshold: threshold,
        margin: margin,
      );

      if (exclusionAnalysis.isExcluded) {
        // L2 存在排除事由 -> 不构成
        finalConclusion = CrimeConclusion.notConstitutedExcluded;
      } else {
        // L2 通过 -> 进入 L3
        // ========== Level 3: 量刑情节分析 ==========
        sentencingAnalysis = _analyzeLevel3(
          crime: crime,
          yamlBase: yamlBase,
          legalEmbeddings: legalEmbeddings,
          caseExtraction: caseExtraction,
          threshold: threshold,
          margin: margin,
        );

        // 根据量刑等级确定最终结论
        finalConclusion = _mapSentencingToConclusion(sentencingAnalysis.sentencingLevel);
      }
    }

    // 生成解释文本
    final explanationText = _generateTieredExplanation(
      crime: crime,
      coreElements: coreElements,
      exclusionAnalysis: exclusionAnalysis,
      sentencingAnalysis: sentencingAnalysis,
      finalConclusion: finalConclusion,
    );

    return TieredCrimeAnalysis(
      crimeId: crime.crimeId,
      crimeName: crime.crimeName,
      coreElements: coreElements,
      exclusionAnalysis: exclusionAnalysis,
      sentencingAnalysis: sentencingAnalysis,
      finalConclusion: finalConclusion,
      overallScore: coreElements.coverageScore,
      explanationText: explanationText,
    );
  }

  /// Level 1: 核心构成要件分析
  CoreElementsResult _analyzeLevel1({
    required Crime crime,
    required YamlBase yamlBase,
    required EmbeddingPackage legalEmbeddings,
    required CaseExtraction caseExtraction,
    required double threshold,
    required double margin,
  }) {
    final hitSlots = <SlotMatchResult>[];
    final missingSlots = <SlotMatchResult>[];
    final uncertainSlots = <SlotMatchResult>[];

    // 仅分析 Level 1 的必需要件
    final level1RequiredIds = crime.requiredSlots.where((id) {
      final slot = yamlBase.findSlotById(id);
      return slot != null && slot.analysisLevel == 1;
    }).toList();

    for (final slotId in level1RequiredIds) {
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
          hitSlots.add(matchResult);
          break;
        case SlotMatchStatus.missing:
          missingSlots.add(matchResult);
          break;
        case SlotMatchStatus.uncertain:
          uncertainSlots.add(matchResult);
          break;
      }
    }

    // 计算覆盖率
    final total = level1RequiredIds.length;
    final coverageScore = total > 0 ? hitSlots.length / total : 0.0;

    // 初步判定：所有必需要件都命中且没有不确定要件
    final isPreliminaryConstituted = missingSlots.isEmpty && uncertainSlots.isEmpty;

    return CoreElementsResult(
      hitSlots: hitSlots,
      missingSlots: missingSlots,
      uncertainSlots: uncertainSlots,
      coverageScore: coverageScore,
      isPreliminaryConstituted: isPreliminaryConstituted,
    );
  }

  /// Level 2: 排除阻却事由分析
  ExclusionResult _analyzeLevel2({
    required Crime crime,
    required YamlBase yamlBase,
    required EmbeddingPackage legalEmbeddings,
    required CaseExtraction caseExtraction,
    required double threshold,
    required double margin,
  }) {
    final hitExclusions = <SlotMatchResult>[];

    // 分析 Level 2 的排除要件
    final level2ExclusionIds = crime.exclusionSlots.where((id) {
      final slot = yamlBase.findSlotById(id);
      return slot != null && slot.analysisLevel == 2;
    }).toList();

    for (final slotId in level2ExclusionIds) {
      final matchResult = _matchSlot(
        slotId: slotId,
        yamlBase: yamlBase,
        legalEmbeddings: legalEmbeddings,
        caseExtraction: caseExtraction,
        threshold: threshold,
        margin: margin,
      );

      if (matchResult.status == SlotMatchStatus.hit) {
        hitExclusions.add(matchResult);
      }
    }

    return ExclusionResult(
      hitExclusions: hitExclusions,
      isExcluded: hitExclusions.isNotEmpty,
    );
  }

  /// Level 3: 量刑情节分析
  SentencingResult _analyzeLevel3({
    required Crime crime,
    required YamlBase yamlBase,
    required EmbeddingPackage legalEmbeddings,
    required CaseExtraction caseExtraction,
    required double threshold,
    required double margin,
  }) {
    final aggravatingFactors = <SlotMatchResult>[];
    final mitigatingFactors = <SlotMatchResult>[];

    // 分析 Level 3 的可选要件（量刑情节）
    final level3OptionalIds = crime.optionalSlots.where((id) {
      final slot = yamlBase.findSlotById(id);
      return slot != null && slot.analysisLevel == 3;
    }).toList();

    for (final slotId in level3OptionalIds) {
      final slot = yamlBase.findSlotById(slotId);
      if (slot == null) continue;

      final matchResult = _matchSlot(
        slotId: slotId,
        yamlBase: yamlBase,
        legalEmbeddings: legalEmbeddings,
        caseExtraction: caseExtraction,
        threshold: threshold,
        margin: margin,
      );

      if (matchResult.status == SlotMatchStatus.hit) {
        // 根据 sentencing_type 分类
        if (slot.sentencingType == SentencingType.aggravating) {
          aggravatingFactors.add(matchResult);
        } else if (slot.sentencingType == SentencingType.mitigating) {
          mitigatingFactors.add(matchResult);
        }
      }
    }

    // 确定量刑等级
    final sentencingLevel = _determineSentencingLevel(
      aggravatingFactors: aggravatingFactors,
      mitigatingFactors: mitigatingFactors,
      yamlBase: yamlBase,
    );

    return SentencingResult(
      aggravatingFactors: aggravatingFactors,
      mitigatingFactors: mitigatingFactors,
      sentencingLevel: sentencingLevel,
    );
  }

  /// 确定量刑等级
  SentencingLevel _determineSentencingLevel({
    required List<SlotMatchResult> aggravatingFactors,
    required List<SlotMatchResult> mitigatingFactors,
    required YamlBase yamlBase,
  }) {
    // 检查是否有"情节特别严重"
    final hasVerySevere = aggravatingFactors.any((f) => f.slotId == 'S202');
    if (hasVerySevere) {
      return SentencingLevel.verySevere;
    }

    // 检查是否有"情节严重"
    final hasSerious = aggravatingFactors.any((f) => f.slotId == 'S201');
    if (hasSerious) {
      // 如果同时有减轻情节，降一级
      if (mitigatingFactors.isNotEmpty) {
        return SentencingLevel.normal;
      }
      return SentencingLevel.serious;
    }

    // 没有加重情节
    if (mitigatingFactors.isNotEmpty) {
      return SentencingLevel.minor;
    }

    return SentencingLevel.normal;
  }

  /// 将量刑等级映射为最终结论
  CrimeConclusion _mapSentencingToConclusion(SentencingLevel level) {
    switch (level) {
      case SentencingLevel.minor:
        return CrimeConclusion.constitutedMinor;
      case SentencingLevel.normal:
        return CrimeConclusion.constitutedNormal;
      case SentencingLevel.serious:
        return CrimeConclusion.constitutedSerious;
      case SentencingLevel.verySevere:
        return CrimeConclusion.constitutedVerySevere;
    }
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

  /// 生成分层解释文本
  String _generateTieredExplanation({
    required Crime crime,
    required CoreElementsResult coreElements,
    ExclusionResult? exclusionAnalysis,
    SentencingResult? sentencingAnalysis,
    required CrimeConclusion finalConclusion,
  }) {
    String template = crime.explanationTemplate;
    final slotAnalysis = StringBuffer();

    // L1: 核心要件
    if (coreElements.hitSlots.isNotEmpty) {
      slotAnalysis.write('已认定核心要件: ');
      slotAnalysis.write(coreElements.hitSlots.map((s) => s.slotName).join('、'));
    }

    if (coreElements.missingSlots.isNotEmpty) {
      if (slotAnalysis.isNotEmpty) slotAnalysis.write('；');
      slotAnalysis.write('缺失核心要件: ');
      slotAnalysis.write(coreElements.missingSlots.map((s) => s.slotName).join('、'));
    }

    // L2: 排除事由
    if (exclusionAnalysis != null && exclusionAnalysis.hitExclusions.isNotEmpty) {
      if (slotAnalysis.isNotEmpty) slotAnalysis.write('；');
      slotAnalysis.write('存在排除事由: ');
      slotAnalysis.write(exclusionAnalysis.hitExclusions.map((s) => s.slotName).join('、'));
    }

    // L3: 量刑情节
    if (sentencingAnalysis != null) {
      if (sentencingAnalysis.aggravatingFactors.isNotEmpty) {
        if (slotAnalysis.isNotEmpty) slotAnalysis.write('；');
        slotAnalysis.write('加重情节: ');
        slotAnalysis.write(sentencingAnalysis.aggravatingFactors.map((s) => s.slotName).join('、'));
      }
      if (sentencingAnalysis.mitigatingFactors.isNotEmpty) {
        if (slotAnalysis.isNotEmpty) slotAnalysis.write('；');
        slotAnalysis.write('减轻情节: ');
        slotAnalysis.write(sentencingAnalysis.mitigatingFactors.map((s) => s.slotName).join('、'));
      }
    }

    template = template.replaceAll('{slot_analysis}', slotAnalysis.toString());
    return template;
  }
}
