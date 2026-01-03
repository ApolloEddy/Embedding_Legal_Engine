// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'case_extraction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvolvedPerson _$InvolvedPersonFromJson(Map<String, dynamic> json) =>
    InvolvedPerson(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String?,
      actionSummary: json['action_summary'] as String?,
    );

Map<String, dynamic> _$InvolvedPersonToJson(InvolvedPerson instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'role': instance.role,
      'action_summary': instance.actionSummary,
    };

SlotExtraction _$SlotExtractionFromJson(Map<String, dynamic> json) =>
    SlotExtraction(
      slotId: json['slot_id'] as String,
      slotText: json['slot_text'] as String?,
      slotEmbedding: (json['slot_embedding'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      confidence: (json['confidence'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$SlotExtractionToJson(SlotExtraction instance) =>
    <String, dynamic>{
      'slot_id': instance.slotId,
      'slot_text': instance.slotText,
      'slot_embedding': instance.slotEmbedding,
      'confidence': instance.confidence,
    };

CaseExtraction _$CaseExtractionFromJson(Map<String, dynamic> json) =>
    CaseExtraction(
      originalCaseText: json['original_case_text'] as String,
      extractedAt: DateTime.parse(json['extracted_at'] as String),
      embeddingModelId: json['embedding_model_id'] as String,
      slotExtractions: (json['slot_extractions'] as List<dynamic>)
          .map((e) => SlotExtraction.fromJson(e as Map<String, dynamic>))
          .toList(),
      involvedPersons: (json['involved_persons'] as List<dynamic>?)
          ?.map((e) => InvolvedPerson.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CaseExtractionToJson(CaseExtraction instance) =>
    <String, dynamic>{
      'original_case_text': instance.originalCaseText,
      'extracted_at': instance.extractedAt.toIso8601String(),
      'embedding_model_id': instance.embeddingModelId,
      'slot_extractions':
          instance.slotExtractions.map((e) => e.toJson()).toList(),
      'involved_persons':
          instance.involvedPersons?.map((e) => e.toJson()).toList(),
    };
