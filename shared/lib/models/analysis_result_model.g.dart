// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_result_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SlotMatchResult _$SlotMatchResultFromJson(Map<String, dynamic> json) =>
    SlotMatchResult(
      slotId: json['slot_id'] as String,
      slotName: json['slot_name'] as String,
      status: $enumDecode(_$SlotMatchStatusEnumMap, json['status']),
      similarityScore: (json['similarity_score'] as num?)?.toDouble(),
      statusReason: json['status_reason'] as String?,
    );

Map<String, dynamic> _$SlotMatchResultToJson(SlotMatchResult instance) =>
    <String, dynamic>{
      'slot_id': instance.slotId,
      'slot_name': instance.slotName,
      'status': _$SlotMatchStatusEnumMap[instance.status]!,
      'similarity_score': instance.similarityScore,
      'status_reason': instance.statusReason,
    };

const _$SlotMatchStatusEnumMap = {
  SlotMatchStatus.hit: 'hit',
  SlotMatchStatus.missing: 'missing',
  SlotMatchStatus.uncertain: 'uncertain',
};

CrimeAnalysisResult _$CrimeAnalysisResultFromJson(Map<String, dynamic> json) =>
    CrimeAnalysisResult(
      crimeId: json['crime_id'] as String,
      crimeName: json['crime_name'] as String,
      isConstituted: json['is_constituted'] as bool?,
      overallScore: (json['overall_score'] as num).toDouble(),
      hitRequiredSlots: (json['hit_required_slots'] as List<dynamic>)
          .map((e) => SlotMatchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      missingRequiredSlots: (json['missing_required_slots'] as List<dynamic>)
          .map((e) => SlotMatchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      hitExclusionSlots: (json['hit_exclusion_slots'] as List<dynamic>)
          .map((e) => SlotMatchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      uncertainSlots: (json['uncertain_slots'] as List<dynamic>)
          .map((e) => SlotMatchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      explanationText: json['explanation_text'] as String?,
    );

Map<String, dynamic> _$CrimeAnalysisResultToJson(
        CrimeAnalysisResult instance) =>
    <String, dynamic>{
      'crime_id': instance.crimeId,
      'crime_name': instance.crimeName,
      'is_constituted': instance.isConstituted,
      'overall_score': instance.overallScore,
      'hit_required_slots':
          instance.hitRequiredSlots.map((e) => e.toJson()).toList(),
      'missing_required_slots':
          instance.missingRequiredSlots.map((e) => e.toJson()).toList(),
      'hit_exclusion_slots':
          instance.hitExclusionSlots.map((e) => e.toJson()).toList(),
      'uncertain_slots':
          instance.uncertainSlots.map((e) => e.toJson()).toList(),
      'explanation_text': instance.explanationText,
    };

AnalysisResult _$AnalysisResultFromJson(Map<String, dynamic> json) =>
    AnalysisResult(
      analyzedAt: DateTime.parse(json['analyzed_at'] as String),
      yamlVersion: json['yaml_version'] as String,
      embeddingVersion: json['embedding_version'] as String,
      analysisLevel: (json['analysis_level'] as num).toInt(),
      similarityThreshold: (json['similarity_threshold'] as num).toDouble(),
      crimeResults: (json['crime_results'] as List<dynamic>)
          .map((e) => CrimeAnalysisResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AnalysisResultToJson(AnalysisResult instance) =>
    <String, dynamic>{
      'analyzed_at': instance.analyzedAt.toIso8601String(),
      'yaml_version': instance.yamlVersion,
      'embedding_version': instance.embeddingVersion,
      'analysis_level': instance.analysisLevel,
      'similarity_threshold': instance.similarityThreshold,
      'crime_results': instance.crimeResults.map((e) => e.toJson()).toList(),
    };
