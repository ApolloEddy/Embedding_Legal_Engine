import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'embedding_package_model.g.dart';

/// 单个 Slot 的 Embedding
@JsonSerializable()
class SlotEmbedding extends Equatable {
  /// 对应的 slot_id
  @JsonKey(name: 'slot_id')
  final String slotId;

  /// Embedding 向量
  @JsonKey(name: 'embedding_vector')
  final List<double> embeddingVector;

  /// 来源法律条文标识
  @JsonKey(name: 'source_article_id')
  final String? sourceArticleId;

  const SlotEmbedding({
    required this.slotId,
    required this.embeddingVector,
    this.sourceArticleId,
  });

  factory SlotEmbedding.fromJson(Map<String, dynamic> json) =>
      _$SlotEmbeddingFromJson(json);

  Map<String, dynamic> toJson() => _$SlotEmbeddingToJson(this);

  /// Embedding 维度
  int get dimension => embeddingVector.length;

  @override
  List<Object?> get props => [slotId, embeddingVector, sourceArticleId];
}

/// Embedding 包模型
/// 
/// 只读资产，由程序 A 生成，由程序 B 加载使用。
/// 包中禁止出现任何解释性文本。
@JsonSerializable(explicitToJson: true)
class EmbeddingPackage extends Equatable {
  /// Embedding 模型 ID（如 text-embedding-3-small）
  @JsonKey(name: 'embedding_model_id')
  final String embeddingModelId;

  /// Embedding 包版本
  @JsonKey(name: 'embedding_version')
  final String embeddingVersion;

  /// 创建时间戳
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// Embedding 维度
  final int dimension;

  /// 所有 slot 的 embeddings
  final List<SlotEmbedding> embeddings;

  const EmbeddingPackage({
    required this.embeddingModelId,
    required this.embeddingVersion,
    required this.createdAt,
    required this.dimension,
    required this.embeddings,
  });

  factory EmbeddingPackage.fromJson(Map<String, dynamic> json) =>
      _$EmbeddingPackageFromJson(json);

  Map<String, dynamic> toJson() => _$EmbeddingPackageToJson(this);

  /// 根据 slot_id 获取 embedding
  SlotEmbedding? getEmbeddingBySlotId(String slotId) {
    try {
      return embeddings.firstWhere((e) => e.slotId == slotId);
    } catch (_) {
      return null;
    }
  }

  /// 获取所有 slot_id 列表
  List<String> get slotIds => embeddings.map((e) => e.slotId).toList();

  @override
  List<Object?> get props => [
        embeddingModelId,
        embeddingVersion,
        createdAt,
        dimension,
        embeddings,
      ];
}
