import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'analysis_result_model.dart';

part 'tiered_analysis_model.g.dart';

/// 量刑等级
enum SentencingLevel {
  @JsonValue('minor')
  minor, // 情节轻微
  @JsonValue('normal')
  normal, // 一般情节
  @JsonValue('serious')
  serious, // 情节严重
  @JsonValue('very_severe')
  verySevere, // 情节特别严重
}

/// 最终结论
enum CrimeConclusion {
  @JsonValue('not_constituted_missing_elements')
  notConstitutedMissingElements, // 不构成：核心要件缺失
  @JsonValue('not_constituted_excluded')
  notConstitutedExcluded, // 不构成：存在阻却事由
  @JsonValue('constituted_minor')
  constitutedMinor, // 构成：情节轻微
  @JsonValue('constituted_normal')
  constitutedNormal, // 构成：一般情节
  @JsonValue('constituted_serious')
  constitutedSerious, // 构成：情节严重
  @JsonValue('constituted_very_severe')
  constitutedVerySevere, // 构成：情节特别严重
  @JsonValue('uncertain')
  uncertain, // 待定：信息不足
}

/// 第一层结果：核心构成要件
@JsonSerializable(explicitToJson: true)
class CoreElementsResult extends Equatable {
  @JsonKey(name: 'hit_slots')
  final List<SlotMatchResult> hitSlots;

  @JsonKey(name: 'missing_slots')
  final List<SlotMatchResult> missingSlots;

  @JsonKey(name: 'uncertain_slots')
  final List<SlotMatchResult> uncertainSlots;

  @JsonKey(name: 'coverage_score')
  final double coverageScore;

  @JsonKey(name: 'is_preliminary_constituted')
  final bool isPreliminaryConstituted;

  const CoreElementsResult({
    required this.hitSlots,
    required this.missingSlots,
    required this.uncertainSlots,
    required this.coverageScore,
    required this.isPreliminaryConstituted,
  });

  factory CoreElementsResult.fromJson(Map<String, dynamic> json) =>
      _$CoreElementsResultFromJson(json);
  Map<String, dynamic> toJson() => _$CoreElementsResultToJson(this);

  @override
  List<Object?> get props =>
      [hitSlots, missingSlots, uncertainSlots, coverageScore, isPreliminaryConstituted];
}

/// 第二层结果：排除阻却事由
@JsonSerializable(explicitToJson: true)
class ExclusionResult extends Equatable {
  @JsonKey(name: 'hit_exclusions')
  final List<SlotMatchResult> hitExclusions;

  @JsonKey(name: 'is_excluded')
  final bool isExcluded;

  const ExclusionResult({
    required this.hitExclusions,
    required this.isExcluded,
  });

  factory ExclusionResult.fromJson(Map<String, dynamic> json) =>
      _$ExclusionResultFromJson(json);
  Map<String, dynamic> toJson() => _$ExclusionResultToJson(this);

  @override
  List<Object?> get props => [hitExclusions, isExcluded];
}

/// 第三层结果：量刑情节
@JsonSerializable(explicitToJson: true)
class SentencingResult extends Equatable {
  @JsonKey(name: 'aggravating_factors')
  final List<SlotMatchResult> aggravatingFactors;

  @JsonKey(name: 'mitigating_factors')
  final List<SlotMatchResult> mitigatingFactors;

  @JsonKey(name: 'sentencing_level')
  final SentencingLevel sentencingLevel;

  const SentencingResult({
    required this.aggravatingFactors,
    required this.mitigatingFactors,
    required this.sentencingLevel,
  });

  factory SentencingResult.fromJson(Map<String, dynamic> json) =>
      _$SentencingResultFromJson(json);
  Map<String, dynamic> toJson() => _$SentencingResultToJson(this);

  @override
  List<Object?> get props => [aggravatingFactors, mitigatingFactors, sentencingLevel];
}

/// 分层罪名分析结果
@JsonSerializable(explicitToJson: true)
class TieredCrimeAnalysis extends Equatable {
  @JsonKey(name: 'crime_id')
  final String crimeId;

  @JsonKey(name: 'crime_name')
  final String crimeName;

  /// Level 1 分析结果
  @JsonKey(name: 'core_elements')
  final CoreElementsResult coreElements;

  /// Level 2 分析结果（仅当 L1 通过时有效）
  @JsonKey(name: 'exclusion_analysis')
  final ExclusionResult? exclusionAnalysis;

  /// Level 3 分析结果（仅当最终构成时有效）
  @JsonKey(name: 'sentencing_analysis')
  final SentencingResult? sentencingAnalysis;

  /// 最终结论
  @JsonKey(name: 'final_conclusion')
  final CrimeConclusion finalConclusion;

  /// 综合分数
  @JsonKey(name: 'overall_score')
  final double overallScore;

  /// 解释文本
  @JsonKey(name: 'explanation_text')
  final String explanationText;

  const TieredCrimeAnalysis({
    required this.crimeId,
    required this.crimeName,
    required this.coreElements,
    this.exclusionAnalysis,
    this.sentencingAnalysis,
    required this.finalConclusion,
    required this.overallScore,
    required this.explanationText,
  });

  factory TieredCrimeAnalysis.fromJson(Map<String, dynamic> json) =>
      _$TieredCrimeAnalysisFromJson(json);
  Map<String, dynamic> toJson() => _$TieredCrimeAnalysisToJson(this);

  @override
  List<Object?> get props => [
        crimeId,
        crimeName,
        coreElements,
        exclusionAnalysis,
        sentencingAnalysis,
        finalConclusion,
        overallScore,
        explanationText
      ];
}

/// 完整分层分析结果
@JsonSerializable(explicitToJson: true)
class TieredAnalysisResult extends Equatable {
  @JsonKey(name: 'analyzed_at')
  final DateTime analyzedAt;

  @JsonKey(name: 'yaml_version')
  final String yamlVersion;

  @JsonKey(name: 'embedding_version')
  final String embeddingVersion;

  @JsonKey(name: 'similarity_threshold')
  final double similarityThreshold;

  @JsonKey(name: 'crime_analyses')
  final List<TieredCrimeAnalysis> crimeAnalyses;

  const TieredAnalysisResult({
    required this.analyzedAt,
    required this.yamlVersion,
    required this.embeddingVersion,
    required this.similarityThreshold,
    required this.crimeAnalyses,
  });

  factory TieredAnalysisResult.fromJson(Map<String, dynamic> json) =>
      _$TieredAnalysisResultFromJson(json);
  Map<String, dynamic> toJson() => _$TieredAnalysisResultToJson(this);

  /// 获取可能构成的罪名
  List<TieredCrimeAnalysis> get constitutedCrimes => crimeAnalyses
      .where((c) => c.finalConclusion.name.startsWith('constituted'))
      .toList();

  /// 获取不构成的罪名
  List<TieredCrimeAnalysis> get notConstitutedCrimes => crimeAnalyses
      .where((c) => c.finalConclusion.name.startsWith('notConstituted'))
      .toList();

  /// 获取待定的罪名
  List<TieredCrimeAnalysis> get uncertainCrimes =>
      crimeAnalyses.where((c) => c.finalConclusion == CrimeConclusion.uncertain).toList();

  @override
  List<Object?> get props =>
      [analyzedAt, yamlVersion, embeddingVersion, similarityThreshold, crimeAnalyses];
}
