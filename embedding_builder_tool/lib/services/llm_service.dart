import 'dart:convert';
import 'package:http/http.dart' as http;

/// LLM 服务配置
class LlmConfig {
  final String apiEndpoint;
  final String apiKey;
  final String embeddingModel;
  final int embeddingDimension;

  const LlmConfig({
    required this.apiEndpoint,
    required this.apiKey,
    required this.embeddingModel,
    required this.embeddingDimension,
  });

  /// 阿里云百炼 Embedding 默认配置 (text-embedding-v4)
  factory LlmConfig.aliyunDashScope({
    required String apiKey,
    String model = 'text-embedding-v4',
    int dimension = 1024,
  }) {
    return LlmConfig(
      apiEndpoint: 'https://dashscope.aliyuncs.com/api/v1/services/embeddings/text-embedding/text-embedding',
      apiKey: apiKey,
      embeddingModel: model,
      embeddingDimension: dimension,
    );
  }

  /// OpenAI Embedding 配置
  factory LlmConfig.openAI({
    required String apiKey,
    String model = 'text-embedding-3-small',
    int dimension = 1536,
  }) {
    return LlmConfig(
      apiEndpoint: 'https://api.openai.com/v1/embeddings',
      apiKey: apiKey,
      embeddingModel: model,
      embeddingDimension: dimension,
    );
  }
}

/// LLM 服务
/// 
/// 用于调用 Embedding API 计算文本的向量表示。
/// 全流程使用同一个 embedding 模型。
class LlmService {
  final LlmConfig config;
  final http.Client _httpClient;

  LlmService({
    required this.config,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// 计算单个文本的 Embedding
  Future<List<double>> computeEmbedding(String text) async {
    final embeddings = await computeEmbeddings([text]);
    if (embeddings.isEmpty) {
      throw Exception('Failed to compute embedding: empty response');
    }
    return embeddings.first;
  }

  /// 批量计算文本的 Embedding
  Future<List<List<double>>> computeEmbeddings(List<String> texts) async {
    if (texts.isEmpty) return [];

    // 判断 API 类型并调用相应的实现
    if (config.apiEndpoint.contains('dashscope')) {
      return _computeAliyunEmbeddings(texts);
    } else {
      return _computeOpenAIEmbeddings(texts);
    }
  }

  /// 阿里云 DashScope Embedding API
  Future<List<List<double>>> _computeAliyunEmbeddings(List<String> texts) async {
    final requestBody = {
      'model': config.embeddingModel,
      'input': {
        'texts': texts,
      },
      'parameters': {
        'dimension': config.embeddingDimension,
      },
    };

    final response = await _httpClient.post(
      Uri.parse(config.apiEndpoint),
      headers: {
        'Authorization': 'Bearer ${config.apiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      throw Exception('Aliyun API error: ${response.statusCode} - ${response.body}');
    }

    final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
    final output = responseJson['output'] as Map<String, dynamic>;
    final embeddings = output['embeddings'] as List<dynamic>;

    return embeddings.map((e) {
      final vector = e['embedding'] as List<dynamic>;
      return vector.map((v) => (v as num).toDouble()).toList();
    }).toList();
  }

  /// OpenAI Embedding API
  Future<List<List<double>>> _computeOpenAIEmbeddings(List<String> texts) async {
    final requestBody = {
      'model': config.embeddingModel,
      'input': texts,
    };

    // 如果支持维度参数
    if (config.embeddingModel.contains('text-embedding-3')) {
      requestBody['dimensions'] = config.embeddingDimension;
    }

    final response = await _httpClient.post(
      Uri.parse(config.apiEndpoint),
      headers: {
        'Authorization': 'Bearer ${config.apiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI API error: ${response.statusCode} - ${response.body}');
    }

    final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
    final data = responseJson['data'] as List<dynamic>;

    // 按 index 排序确保顺序正确
    data.sort((a, b) => (a['index'] as int).compareTo(b['index'] as int));

    return data.map((e) {
      final embedding = e['embedding'] as List<dynamic>;
      return embedding.map((v) => (v as num).toDouble()).toList();
    }).toList();
  }

  /// 关闭 HTTP 客户端
  void dispose() {
    _httpClient.close();
  }
}
