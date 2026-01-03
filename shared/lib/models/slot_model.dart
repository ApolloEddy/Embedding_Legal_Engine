import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'slot_model.g.dart';

/// Slot 角色类型
/// - 定性：用于确定罪名成立
/// - 排除：用于排除罪名（如正当防卫）
/// - 解释：用于解释说明
/// - 统计：用于量刑参考
enum SlotRole {
  @JsonValue('定性')
  qualification,
  @JsonValue('排除')
  exclusion,
  @JsonValue('解释')
  explanation,
  @JsonValue('统计')
  statistics,
}

/// 构成要素 Slot 模型
/// 
/// Slot 是 embedding 的最小对齐单位，
/// 不是罪名，不是文本段落。
@JsonSerializable()
class Slot extends Equatable {
  /// 全局唯一 ID，不可变
  @JsonKey(name: 'slot_id')
  final String slotId;

  /// Slot 名称
  @JsonKey(name: 'slot_name')
  final String slotName;

  /// 分析层级（一级/二级/三级）
  @JsonKey(name: 'analysis_level')
  final int analysisLevel;

  /// 是否必需
  final bool required;

  /// 角色：定性 / 排除 / 解释 / 统计
  final SlotRole role;

  /// 语义边界描述（一句话，限定 embedding 的语义边界）
  @JsonKey(name: 'semantic_scope')
  final String semanticScope;

  const Slot({
    required this.slotId,
    required this.slotName,
    required this.analysisLevel,
    required this.required,
    required this.role,
    required this.semanticScope,
  });

  factory Slot.fromJson(Map<String, dynamic> json) => _$SlotFromJson(json);

  Map<String, dynamic> toJson() => _$SlotToJson(this);

  @override
  List<Object?> get props => [
        slotId,
        slotName,
        analysisLevel,
        required,
        role,
        semanticScope,
      ];
}
