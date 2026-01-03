// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'embedding_package_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SlotEmbedding _$SlotEmbeddingFromJson(Map<String, dynamic> json) =>
    SlotEmbedding(
      slotId: json['slot_id'] as String,
      embeddingVector: (json['embedding_vector'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      sourceArticleId: json['source_article_id'] as String?,
    );

Map<String, dynamic> _$SlotEmbeddingToJson(SlotEmbedding instance) =>
    <String, dynamic>{
      'slot_id': instance.slotId,
      'embedding_vector': instance.embeddingVector,
      'source_article_id': instance.sourceArticleId,
    };

EmbeddingPackage _$EmbeddingPackageFromJson(Map<String, dynamic> json) =>
    EmbeddingPackage(
      embeddingModelId: json['embedding_model_id'] as String,
      embeddingVersion: json['embedding_version'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      dimension: (json['dimension'] as num).toInt(),
      embeddings: (json['embeddings'] as List<dynamic>)
          .map((e) => SlotEmbedding.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$EmbeddingPackageToJson(EmbeddingPackage instance) =>
    <String, dynamic>{
      'embedding_model_id': instance.embeddingModelId,
      'embedding_version': instance.embeddingVersion,
      'created_at': instance.createdAt.toIso8601String(),
      'dimension': instance.dimension,
      'embeddings': instance.embeddings.map((e) => e.toJson()).toList(),
    };
