// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slot_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Slot _$SlotFromJson(Map<String, dynamic> json) => Slot(
      slotId: json['slot_id'] as String,
      slotName: json['slot_name'] as String,
      analysisLevel: (json['analysis_level'] as num).toInt(),
      required: json['required'] as bool,
      role: $enumDecode(_$SlotRoleEnumMap, json['role']),
      semanticScope: json['semantic_scope'] as String,
      sentencingType:
          $enumDecodeNullable(_$SentencingTypeEnumMap, json['sentencing_type']),
    );

Map<String, dynamic> _$SlotToJson(Slot instance) => <String, dynamic>{
      'slot_id': instance.slotId,
      'slot_name': instance.slotName,
      'analysis_level': instance.analysisLevel,
      'required': instance.required,
      'role': _$SlotRoleEnumMap[instance.role]!,
      'semantic_scope': instance.semanticScope,
      'sentencing_type': _$SentencingTypeEnumMap[instance.sentencingType],
    };

const _$SlotRoleEnumMap = {
  SlotRole.qualification: '定性',
  SlotRole.exclusion: '排除',
  SlotRole.explanation: '解释',
  SlotRole.statistics: '统计',
};

const _$SentencingTypeEnumMap = {
  SentencingType.aggravating: 'aggravating',
  SentencingType.mitigating: 'mitigating',
  SentencingType.neutral: 'neutral',
};
