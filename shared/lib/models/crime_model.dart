import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'crime_model.g.dart';

/// 罪名模型
/// 
/// 每个罪名定义必须包含：
/// - crime_id：唯一标识
/// - required_slots：必需要件
/// - exclusion_slots：排除要件
/// - explanation_template：解释模板（纯文本，不含 embedding）
@JsonSerializable()
class Crime extends Equatable {
  /// 罪名唯一 ID
  @JsonKey(name: 'crime_id')
  final String crimeId;

  /// 罪名名称
  @JsonKey(name: 'crime_name')
  final String crimeName;

  /// 适用案件类型
  @JsonKey(name: 'applicable_case_type')
  final String applicableCaseType;

  /// 必需构成要件 slot_id 列表
  @JsonKey(name: 'required_slots')
  final List<String> requiredSlots;

  /// 可选构成要件 slot_id 列表
  @JsonKey(name: 'optional_slots')
  final List<String> optionalSlots;

  /// 排除构成要件 slot_id 列表（如正当防卫）
  @JsonKey(name: 'exclusion_slots')
  final List<String> exclusionSlots;

  /// 解释模板（纯文本，不含 embedding）
  @JsonKey(name: 'explanation_template')
  final String explanationTemplate;

  const Crime({
    required this.crimeId,
    required this.crimeName,
    required this.applicableCaseType,
    required this.requiredSlots,
    required this.optionalSlots,
    required this.exclusionSlots,
    required this.explanationTemplate,
  });

  factory Crime.fromJson(Map<String, dynamic> json) => _$CrimeFromJson(json);

  Map<String, dynamic> toJson() => _$CrimeToJson(this);

  @override
  List<Object?> get props => [
        crimeId,
        crimeName,
        applicableCaseType,
        requiredSlots,
        optionalSlots,
        exclusionSlots,
        explanationTemplate,
      ];
}
