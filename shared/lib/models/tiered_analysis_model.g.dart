// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tiered_analysis_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CoreElementsResult _$CoreElementsResultFromJson(Map<String, dynamic> json) =>
    CoreElementsResult(
      hitSlots: (json['hit_slots'] as List<dynamic>)
          .map((e) => SlotMatchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      missingSlots: (json['missing_slots'] as List<dynamic>)
          .map((e) => SlotMatchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      uncertainSlots: (json['uncertain_slots'] as List<dynamic>)
          .map((e) => SlotMatchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      coverageScore: (json['coverage_score'] as num).toDouble(),
      isPreliminaryConstituted: json['is_preliminary_constituted'] as bool,
    );

Map<String, dynamic> _$CoreElementsResultToJson(CoreElementsResult instance) =>
    <String, dynamic>{
      'hit_slots': instance.hitSlots.map((e) => e.toJson()).toList(),
      'missing_slots': instance.missingSlots.map((e) => e.toJson()).toList(),
      'uncertain_slots':
          instance.uncertainSlots.map((e) => e.toJson()).toList(),
      'coverage_score': instance.coverageScore,
      'is_preliminary_constituted': instance.isPreliminaryConstituted,
    };

ExclusionResult _$ExclusionResultFromJson(Map<String, dynamic> json) =>
    ExclusionResult(
      hitExclusions: (json['hit_exclusions'] as List<dynamic>)
          .map((e) => SlotMatchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      isExcluded: json['is_excluded'] as bool,
    );

Map<String, dynamic> _$ExclusionResultToJson(ExclusionResult instance) =>
    <String, dynamic>{
      'hit_exclusions': instance.hitExclusions.map((e) => e.toJson()).toList(),
      'is_excluded': instance.isExcluded,
    };

SentencingResult _$SentencingResultFromJson(Map<String, dynamic> json) =>
    SentencingResult(
      aggravatingFactors: (json['aggravating_factors'] as List<dynamic>)
          .map((e) => SlotMatchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      mitigatingFactors: (json['mitigating_factors'] as List<dynamic>)
          .map((e) => SlotMatchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      sentencingLevel:
          $enumDecode(_$SentencingLevelEnumMap, json['sentencing_level']),
    );

Map<String, dynamic> _$SentencingResultToJson(SentencingResult instance) =>
    <String, dynamic>{
      'aggravating_factors':
          instance.aggravatingFactors.map((e) => e.toJson()).toList(),
      'mitigating_factors':
          instance.mitigatingFactors.map((e) => e.toJson()).toList(),
      'sentencing_level': _$SentencingLevelEnumMap[instance.sentencingLevel]!,
    };

const _$SentencingLevelEnumMap = {
  SentencingLevel.minor: 'minor',
  SentencingLevel.normal: 'normal',
  SentencingLevel.serious: 'serious',
  SentencingLevel.verySevere: 'very_severe',
};

TieredCrimeAnalysis _$TieredCrimeAnalysisFromJson(Map<String, dynamic> json) =>
    TieredCrimeAnalysis(
      crimeId: json['crime_id'] as String,
      crimeName: json['crime_name'] as String,
      coreElements: CoreElementsResult.fromJson(
          json['core_elements'] as Map<String, dynamic>),
      exclusionAnalysis: json['exclusion_analysis'] == null
          ? null
          : ExclusionResult.fromJson(
              json['exclusion_analysis'] as Map<String, dynamic>),
      sentencingAnalysis: json['sentencing_analysis'] == null
          ? null
          : SentencingResult.fromJson(
              json['sentencing_analysis'] as Map<String, dynamic>),
      finalConclusion:
          $enumDecode(_$CrimeConclusionEnumMap, json['final_conclusion']),
      overallScore: (json['overall_score'] as num).toDouble(),
      explanationText: json['explanation_text'] as String,
    );

Map<String, dynamic> _$TieredCrimeAnalysisToJson(
        TieredCrimeAnalysis instance) =>
    <String, dynamic>{
      'crime_id': instance.crimeId,
      'crime_name': instance.crimeName,
      'core_elements': instance.coreElements.toJson(),
      'exclusion_analysis': instance.exclusionAnalysis?.toJson(),
      'sentencing_analysis': instance.sentencingAnalysis?.toJson(),
      'final_conclusion': _$CrimeConclusionEnumMap[instance.finalConclusion]!,
      'overall_score': instance.overallScore,
      'explanation_text': instance.explanationText,
    };

const _$CrimeConclusionEnumMap = {
  CrimeConclusion.notConstitutedMissingElements:
      'not_constituted_missing_elements',
  CrimeConclusion.notConstitutedExcluded: 'not_constituted_excluded',
  CrimeConclusion.constitutedMinor: 'constituted_minor',
  CrimeConclusion.constitutedNormal: 'constituted_normal',
  CrimeConclusion.constitutedSerious: 'constituted_serious',
  CrimeConclusion.constitutedVerySevere: 'constituted_very_severe',
  CrimeConclusion.uncertain: 'uncertain',
};

TieredAnalysisResult _$TieredAnalysisResultFromJson(
        Map<String, dynamic> json) =>
    TieredAnalysisResult(
      analyzedAt: DateTime.parse(json['analyzed_at'] as String),
      yamlVersion: json['yaml_version'] as String,
      embeddingVersion: json['embedding_version'] as String,
      similarityThreshold: (json['similarity_threshold'] as num).toDouble(),
      crimeAnalyses: (json['crime_analyses'] as List<dynamic>)
          .map((e) => TieredCrimeAnalysis.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TieredAnalysisResultToJson(
        TieredAnalysisResult instance) =>
    <String, dynamic>{
      'analyzed_at': instance.analyzedAt.toIso8601String(),
      'yaml_version': instance.yamlVersion,
      'embedding_version': instance.embeddingVersion,
      'similarity_threshold': instance.similarityThreshold,
      'crime_analyses': instance.crimeAnalyses.map((e) => e.toJson()).toList(),
    };
