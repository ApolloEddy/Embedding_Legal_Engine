import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'analysis_result_model.g.dart';

/// 要件匹配状态
enum SlotMatchStatus {
  /// 命中：相似度高于阈值
  hit,

  /// 缺失：未提取到或相似度过低
  missing,

  /// 不确定：相似度在阈值边界
  uncertain,
}

/// 单个 Slot 的匹配结果
@JsonSerializable()
class SlotMatchResult extends Equatable {
  /// 对应的 slot_id
  @JsonKey(name: 'slot_id')
  final String slotId;

  /// 槽位名称
  @JsonKey(name: 'slot_name')
  final String slotName;

  /// 匹配状态
  final SlotMatchStatus status;

  /// 相似度分数 (0.0 - 1.0)
  @JsonKey(name: 'similarity_score')
  final double? similarityScore;

  /// 置信度说明
  @JsonKey(name: 'status_reason')
  final String? statusReason;

  const SlotMatchResult({
    required this.slotId,
    required this.slotName,
    required this.status,
    this.similarityScore,
    this.statusReason,
  });

  factory SlotMatchResult.fromJson(Map<String, dynamic> json) =>
      _$SlotMatchResultFromJson(json);

  Map<String, dynamic> toJson() => _$SlotMatchResultToJson(this);

  @override
  List<Object?> get props => [slotId, slotName, status, similarityScore, statusReason];
}

/// 单个罪名的分析结果
@JsonSerializable(explicitToJson: true)
class CrimeAnalysisResult extends Equatable {
  /// 罪名 ID
  @JsonKey(name: 'crime_id')
  final String crimeId;

  /// 罪名名称
  @JsonKey(name: 'crime_name')
  final String crimeName;

  /// 是否构成该罪名
  @JsonKey(name: 'is_constituted')
  final bool? isConstituted;

  /// 综合匹配分数 (0.0 - 1.0)
  @JsonKey(name: 'overall_score')
  final double overallScore;

  /// 命中的必需要件
  @JsonKey(name: 'hit_required_slots')
  final List<SlotMatchResult> hitRequiredSlots;

  /// 缺失的必需要件
  @JsonKey(name: 'missing_required_slots')
  final List<SlotMatchResult> missingRequiredSlots;

  /// 命中的排除要件（如有则不构成该罪）
  @JsonKey(name: 'hit_exclusion_slots')
  final List<SlotMatchResult> hitExclusionSlots;

  /// 不确定的要件
  @JsonKey(name: 'uncertain_slots')
  final List<SlotMatchResult> uncertainSlots;

  /// 解释文本（来自 yaml 的 explanation_template）
  @JsonKey(name: 'explanation_text')
  final String? explanationText;

  const CrimeAnalysisResult({
    required this.crimeId,
    required this.crimeName,
    this.isConstituted,
    required this.overallScore,
    required this.hitRequiredSlots,
    required this.missingRequiredSlots,
    required this.hitExclusionSlots,
    required this.uncertainSlots,
    this.explanationText,
  });

  factory CrimeAnalysisResult.fromJson(Map<String, dynamic> json) =>
      _$CrimeAnalysisResultFromJson(json);

  Map<String, dynamic> toJson() => _$CrimeAnalysisResultToJson(this);

  /// 必需要件完整率
  double get requiredSlotsCoverage {
    final total = hitRequiredSlots.length + missingRequiredSlots.length;
    if (total == 0) return 1.0;
    return hitRequiredSlots.length / total;
  }

  /// 是否存在排除事由
  bool get hasExclusion => hitExclusionSlots.isNotEmpty;

  @override
  List<Object?> get props => [
        crimeId,
        crimeName,
        isConstituted,
        overallScore,
        hitRequiredSlots,
        missingRequiredSlots,
        hitExclusionSlots,
        uncertainSlots,
        explanationText,
      ];
}

/// 完整的罪名分析结果（Phase 3 输出）
/// 
/// Phase 3 必须是 100% 本地、确定性、白箱过程。
/// 禁止调用 LLM、生成新的 embedding、修改 yaml。
@JsonSerializable(explicitToJson: true)
class AnalysisResult extends Equatable {
  /// 分析时间戳
  @JsonKey(name: 'analyzed_at')
  final DateTime analyzedAt;

  /// 使用的 YAML 版本
  @JsonKey(name: 'yaml_version')
  final String yamlVersion;

  /// 使用的 Embedding 包版本
  @JsonKey(name: 'embedding_version')
  final String embeddingVersion;

  /// 分析使用的层级
  @JsonKey(name: 'analysis_level')
  final int analysisLevel;

  /// 相似度阈值配置
  @JsonKey(name: 'similarity_threshold')
  final double similarityThreshold;

  /// 各罪名的分析结果
  @JsonKey(name: 'crime_results')
  final List<CrimeAnalysisResult> crimeResults;

  const AnalysisResult({
    required this.analyzedAt,
    required this.yamlVersion,
    required this.embeddingVersion,
    required this.analysisLevel,
    required this.similarityThreshold,
    required this.crimeResults,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) =>
      _$AnalysisResultFromJson(json);

  Map<String, dynamic> toJson() => _$AnalysisResultToJson(this);

  /// 获取可能构成的罪名
  List<CrimeAnalysisResult> get possibleCrimes =>
      crimeResults.where((r) => r.isConstituted == true).toList();

  /// 获取不构成的罪名
  List<CrimeAnalysisResult> get excludedCrimes =>
      crimeResults.where((r) => r.isConstituted == false).toList();

  /// 获取待定的罪名
  List<CrimeAnalysisResult> get uncertainCrimes =>
      crimeResults.where((r) => r.isConstituted == null).toList();

  @override
  List<Object?> get props => [
        analyzedAt,
        yamlVersion,
        embeddingVersion,
        analysisLevel,
        similarityThreshold,
        crimeResults,
      ];
}
