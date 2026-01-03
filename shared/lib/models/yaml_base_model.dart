import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'slot_model.dart';
import 'crime_model.dart';

part 'yaml_base_model.g.dart';

/// 分析层级定义
@JsonSerializable()
class AnalysisLevel extends Equatable {
  final int level;
  final String name;

  const AnalysisLevel({
    required this.level,
    required this.name,
  });

  factory AnalysisLevel.fromJson(Map<String, dynamic> json) =>
      _$AnalysisLevelFromJson(json);

  Map<String, dynamic> toJson() => _$AnalysisLevelToJson(this);

  @override
  List<Object?> get props => [level, name];
}

/// 法律体系类型枚举
enum LegalSystemType {
  @JsonValue('criminal')
  criminal, // 刑事
  @JsonValue('administrative')
  administrative, // 行政
  @JsonValue('civil')
  civil, // 民事
}

/// YAML 基座模型 - 系统唯一权威结构定义
/// 
/// 任何运行时逻辑，必须以 yaml 为准，
/// 不得绕过、覆盖或隐式修改 yaml 语义。
@JsonSerializable(explicitToJson: true)
class YamlBase extends Equatable {
  /// YAML 版本号
  @JsonKey(name: 'yaml_version')
  final String yamlVersion;

  /// 法律体系类型
  @JsonKey(name: 'legal_system_type')
  final LegalSystemType legalSystemType;

  /// 分析层级定义
  @JsonKey(name: 'analysis_levels')
  final List<AnalysisLevel> analysisLevels;

  /// 构成要素 slot 定义（核心）
  final List<Slot> slots;

  /// 罪名定义
  final List<Crime> crimes;

  const YamlBase({
    required this.yamlVersion,
    required this.legalSystemType,
    required this.analysisLevels,
    required this.slots,
    required this.crimes,
  });

  factory YamlBase.fromJson(Map<String, dynamic> json) =>
      _$YamlBaseFromJson(json);

  Map<String, dynamic> toJson() => _$YamlBaseToJson(this);

  /// 根据 slot_id 查找 slot
  Slot? findSlotById(String slotId) {
    try {
      return slots.firstWhere((s) => s.slotId == slotId);
    } catch (_) {
      return null;
    }
  }

  /// 根据 crime_id 查找 crime
  Crime? findCrimeById(String crimeId) {
    try {
      return crimes.firstWhere((c) => c.crimeId == crimeId);
    } catch (_) {
      return null;
    }
  }

  /// 根据分析层级筛选 slots
  List<Slot> getSlotsByLevel(int level) {
    return slots.where((s) => s.analysisLevel == level).toList();
  }

  @override
  List<Object?> get props => [
        yamlVersion,
        legalSystemType,
        analysisLevels,
        slots,
        crimes,
      ];
}
