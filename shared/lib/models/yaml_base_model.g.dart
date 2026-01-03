// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yaml_base_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnalysisLevel _$AnalysisLevelFromJson(Map<String, dynamic> json) =>
    AnalysisLevel(
      level: (json['level'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$AnalysisLevelToJson(AnalysisLevel instance) =>
    <String, dynamic>{
      'level': instance.level,
      'name': instance.name,
    };

YamlBase _$YamlBaseFromJson(Map<String, dynamic> json) => YamlBase(
      yamlVersion: json['yaml_version'] as String,
      legalSystemType:
          $enumDecode(_$LegalSystemTypeEnumMap, json['legal_system_type']),
      analysisLevels: (json['analysis_levels'] as List<dynamic>)
          .map((e) => AnalysisLevel.fromJson(e as Map<String, dynamic>))
          .toList(),
      slots: (json['slots'] as List<dynamic>)
          .map((e) => Slot.fromJson(e as Map<String, dynamic>))
          .toList(),
      crimes: (json['crimes'] as List<dynamic>)
          .map((e) => Crime.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$YamlBaseToJson(YamlBase instance) => <String, dynamic>{
      'yaml_version': instance.yamlVersion,
      'legal_system_type': _$LegalSystemTypeEnumMap[instance.legalSystemType]!,
      'analysis_levels':
          instance.analysisLevels.map((e) => e.toJson()).toList(),
      'slots': instance.slots.map((e) => e.toJson()).toList(),
      'crimes': instance.crimes.map((e) => e.toJson()).toList(),
    };

const _$LegalSystemTypeEnumMap = {
  LegalSystemType.criminal: 'criminal',
  LegalSystemType.administrative: 'administrative',
  LegalSystemType.civil: 'civil',
};
