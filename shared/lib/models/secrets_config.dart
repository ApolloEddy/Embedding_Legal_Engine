/// 阿里云配置
class AliyunConfig {
  final String apiKey;
  final String embeddingEndpoint;
  final String embeddingModel;
  final int embeddingDimension;
  final String? llmEndpoint;
  final String llmModel;

  const AliyunConfig({
    required this.apiKey,
    required this.embeddingEndpoint,
    required this.embeddingModel,
    required this.embeddingDimension,
    this.llmEndpoint,
    required this.llmModel,
  });
}
