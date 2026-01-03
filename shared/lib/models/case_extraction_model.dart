import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'case_extraction_model.g.dart';

/// 涉案人员信息
@JsonSerializable()
class InvolvedPerson extends Equatable {
  /// 人员标识
  final String id;

  /// 姓名
  final String name;

  /// 角色描述
  final String? role;

  /// 行为摘要
  @JsonKey(name: 'action_summary')
  final String? actionSummary;

  const InvolvedPerson({
    required this.id,
    required this.name,
    this.role,
    this.actionSummary,
  });

  factory InvolvedPerson.fromJson(Map<String, dynamic> json) =>
      _$InvolvedPersonFromJson(json);

  Map<String, dynamic> toJson() => _$InvolvedPersonToJson(this);

  @override
  List<Object?> get props => [id, name, role, actionSummary];
}

/// Slot 提取结果
@JsonSerializable()
class SlotExtraction extends Equatable {
  /// 对应的 slot_id
  @JsonKey(name: 'slot_id')
  final String slotId;

  /// 从案情中提取的文本
  @JsonKey(name: 'slot_text')
  final String? slotText;

  /// 由 slot_text 派生的 embedding
  @JsonKey(name: 'slot_embedding')
  final List<double>? slotEmbedding;

  /// 置信度 (0.0 - 1.0)
  final double? confidence;

  const SlotExtraction({
    required this.slotId,
    this.slotText,
    this.slotEmbedding,
    this.confidence,
  });

  factory SlotExtraction.fromJson(Map<String, dynamic> json) =>
      _$SlotExtractionFromJson(json);

  Map<String, dynamic> toJson() => _$SlotExtractionToJson(this);

  /// 是否已提取到有效内容
  bool get hasContent => slotText != null && slotText!.isNotEmpty;

  /// 是否有有效的 embedding
  bool get hasEmbedding => slotEmbedding != null && slotEmbedding!.isNotEmpty;

  @override
  List<Object?> get props => [slotId, slotText, slotEmbedding, confidence];
}

/// 案件事实提取结果（Phase 2 输出）
/// 
/// 禁止对同一案件进行多次事实提取调用。
/// slot_embedding 必须由 slot_text 派生。
@JsonSerializable(explicitToJson: true)
class CaseExtraction extends Equatable {
  /// 原始案情文本
  @JsonKey(name: 'original_case_text')
  final String originalCaseText;

  /// 提取时间戳
  @JsonKey(name: 'extracted_at')
  final DateTime extractedAt;

  /// 使用的 embedding 模型 ID
  @JsonKey(name: 'embedding_model_id')
  final String embeddingModelId;

  /// 各 slot 的提取结果
  @JsonKey(name: 'slot_extractions')
  final List<SlotExtraction> slotExtractions;

  /// 涉案人员信息（可选）
  @JsonKey(name: 'involved_persons')
  final List<InvolvedPerson>? involvedPersons;

  const CaseExtraction({
    required this.originalCaseText,
    required this.extractedAt,
    required this.embeddingModelId,
    required this.slotExtractions,
    this.involvedPersons,
  });

  factory CaseExtraction.fromJson(Map<String, dynamic> json) =>
      _$CaseExtractionFromJson(json);

  Map<String, dynamic> toJson() => _$CaseExtractionToJson(this);

  /// 根据 slot_id 获取提取结果
  SlotExtraction? getExtractionBySlotId(String slotId) {
    try {
      return slotExtractions.firstWhere((e) => e.slotId == slotId);
    } catch (_) {
      return null;
    }
  }

  /// 获取所有已提取内容的 slot_id 列表
  List<String> get extractedSlotIds =>
      slotExtractions.where((e) => e.hasContent).map((e) => e.slotId).toList();

  @override
  List<Object?> get props => [
        originalCaseText,
        extractedAt,
        embeddingModelId,
        slotExtractions,
        involvedPersons,
      ];
}
