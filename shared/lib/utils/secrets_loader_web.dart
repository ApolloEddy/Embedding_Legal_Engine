import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';
import '../models/secrets_config.dart';

/// 密钥配置加载器 (Web Implementation)
class SecretsLoader {
  static Map<String, dynamic>? _cached;

  /// 加载密钥配置
  /// 
  /// Web 端尝试从 assets/secrets.yaml 加载
  static Future<Map<String, dynamic>> load([String? customPath]) async {
    if (_cached != null) return _cached!;

    try {
      // Web 端始终从 assets 加载，忽略 customPath
      final content = await rootBundle.loadString('assets/secrets.yaml');
      final yaml = loadYaml(content) as YamlMap;
      _cached = _yamlMapToMap(yaml);
      return _cached!;
    } catch (e) {
      throw Exception('Web 端加载 secrets.yaml 失败: $e');
    }
  }

  static Future<AliyunConfig> getAliyunConfig() async {
    final secrets = await load();
    final aliyun = secrets['aliyun'] as Map<String, dynamic>?;
    if (aliyun == null) {
      throw Exception('secrets.yaml 中缺少 aliyun 配置');
    }

    return AliyunConfig(
      apiKey: aliyun['api_key'] as String,
      embeddingEndpoint: aliyun['embedding_endpoint'] as String,
      embeddingModel: aliyun['embedding_model'] as String,
      embeddingDimension: aliyun['embedding_dimension'] as int? ?? 1024,
      llmEndpoint: aliyun['llm_endpoint'] as String?,
      llmModel: aliyun['llm_model'] as String? ?? 'qwen-max',
    );
  }

  static Map<String, dynamic> _yamlMapToMap(YamlMap yamlMap) {
    final result = <String, dynamic>{};
    for (final key in yamlMap.keys) {
      final value = yamlMap[key];
      if (value is YamlMap) {
        result[key.toString()] = _yamlMapToMap(value);
      } else if (value is YamlList) {
        result[key.toString()] = value.toList();
      } else {
        result[key.toString()] = value;
      }
    }
    return result;
  }

  static void clearCache() {
    _cached = null;
  }
}
