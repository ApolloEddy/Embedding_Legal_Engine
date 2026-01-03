import 'dart:math' as math;

/// 相似度计算器
/// 
/// Phase 3 使用的本地确定性算法。
/// 支持 cosine 和 dot product 两种相似度计算方式。
class SimilarityCalculator {
  /// 计算 Cosine 相似度
  /// 
  /// 返回值范围: [-1.0, 1.0]
  /// 1.0 表示完全相同，-1.0 表示完全相反，0 表示正交
  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('Vectors must have the same dimension: ${a.length} vs ${b.length}');
    }
    if (a.isEmpty) {
      throw ArgumentError('Vectors cannot be empty');
    }

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    // 处理零向量情况
    if (normA == 0.0 || normB == 0.0) {
      return 0.0;
    }

    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }

  /// 计算点积（Dot Product）
  /// 
  /// 适用于已归一化的向量
  static double dotProduct(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('Vectors must have the same dimension: ${a.length} vs ${b.length}');
    }
    if (a.isEmpty) {
      throw ArgumentError('Vectors cannot be empty');
    }

    double result = 0.0;
    for (int i = 0; i < a.length; i++) {
      result += a[i] * b[i];
    }
    return result;
  }

  /// 计算欧几里得距离
  /// 
  /// 返回值范围: [0, +∞)
  /// 值越小表示越相似
  static double euclideanDistance(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('Vectors must have the same dimension: ${a.length} vs ${b.length}');
    }
    if (a.isEmpty) {
      throw ArgumentError('Vectors cannot be empty');
    }

    double sumSquares = 0.0;
    for (int i = 0; i < a.length; i++) {
      final diff = a[i] - b[i];
      sumSquares += diff * diff;
    }
    return math.sqrt(sumSquares);
  }

  /// 归一化向量
  static List<double> normalize(List<double> vector) {
    if (vector.isEmpty) {
      throw ArgumentError('Vector cannot be empty');
    }

    double norm = 0.0;
    for (final v in vector) {
      norm += v * v;
    }
    norm = math.sqrt(norm);

    if (norm == 0.0) {
      return List.filled(vector.length, 0.0);
    }

    return vector.map((v) => v / norm).toList();
  }

  /// 判断相似度是否超过阈值
  /// 
  /// [similarity] 相似度分数
  /// [threshold] 阈值
  /// [margin] 不确定区间的边界（默认 0.1）
  /// 
  /// 返回: 
  /// - 1: 命中（相似度 >= threshold + margin）
  /// - 0: 不确定（threshold - margin <= 相似度 < threshold + margin）
  /// - -1: 未命中（相似度 < threshold - margin）
  static int classifySimilarity(
    double similarity, {
    required double threshold,
    double margin = 0.1,
  }) {
    if (similarity >= threshold + margin) {
      return 1; // 命中
    } else if (similarity >= threshold - margin) {
      return 0; // 不确定
    } else {
      return -1; // 未命中
    }
  }
  /// 计算向量模长 (Magnitude/Norm)
  static double magnitude(List<double> vector) {
    if (vector.isEmpty) return 0.0;
    double sum = 0.0;
    for (final v in vector) {
      sum += v * v;
    }
    return math.sqrt(sum);
  }
}
