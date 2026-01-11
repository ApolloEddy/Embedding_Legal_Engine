import 'dart:io';
import 'package:yaml/yaml.dart';
import '../models/secrets_config.dart';

/// 密钥配置加载器 (IO implementation)
/// 从项目根目录的 secrets.yaml 加载敏感配置
class SecretsLoader {
  static Map<String, dynamic>? _cached;

  /// 加载密钥配置
  static Future<Map<String, dynamic>> load([String? customPath]) async {
    if (_cached != null) return _cached!;

    final paths = [
      customPath,
      'secrets.yaml',
      '../secrets.yaml',
      '../../secrets.yaml',
      '../../../secrets.yaml',
    ].whereType<String>();

    for (final path in paths) {
      final file = File(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        final yaml = loadYaml(content) as YamlMap;
        _cached = _yamlMapToMap(yaml);
        return _cached!;
      }
    }

    throw Exception(
      '未找到 secrets.yaml 配置文件!\n'
      '请复制 secrets.yaml.example 为 secrets.yaml 并填入 API Key'
    );
  }

  /// 获取阿里云配置
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

  /// 清除缓存（用于测试）
  static void clearCache() {
    _cached = null;
  }
}
