import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:legal_engine_shared/legal_engine_shared.dart';
import '../services/asset_loader_service.dart';
import '../services/llm_extraction_service.dart';
import '../engines/local_analysis_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用状态管理
class AppProvider extends ChangeNotifier {
  final AssetLoaderService _assetLoader = AssetLoaderService();
  final LocalAnalysisEngine _analysisEngine = LocalAnalysisEngine();
  LlmExtractionService? _extractionService;

  // 资产状态
  YamlBase? get yamlBase => _assetLoader.yamlBase;
  EmbeddingPackage? get embeddingPackage => _assetLoader.embeddingPackage;

  String? _yamlPath;
  String? get yamlPath => _yamlPath;

  String? _embeddingPath;
  String? get embeddingPath => _embeddingPath;

  // LLM 配置
  LlmConfig? _llmConfig;
  LlmConfig? get llmConfig => _llmConfig;

  // 配置来源（用于 UI 显示）
  String? _configSource;
  String? get configSource => _configSource;

  // 案件分析状态
  String _caseText = '';
  String get caseText => _caseText;

  CaseExtraction? _caseExtraction;
  CaseExtraction? get caseExtraction => _caseExtraction;

  AnalysisResult? _analysisResult;
  AnalysisResult? get analysisResult => _analysisResult;

  // 分析配置
  int _analysisLevel = 1;
  int get analysisLevel => _analysisLevel;

  double _similarityThreshold = 0.45;
  double get similarityThreshold => _similarityThreshold;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isExtracting = false;  // 防抖标志

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  // 当前阶段
  int _currentPhase = 1;
  int get currentPhase => _currentPhase;

  // Persistence Keys
  static const String _keyYamlPath = 'p_b_yaml_path';
  static const String _keyPakPath = 'p_b_pak_path';
  static const String _keyApiKey = 'p_b_api_key';
  static const String _keyModel = 'p_b_model';
  static const String _keyDim = 'p_b_dim';

  /// 初始化：加载持久化状态
  Future<void> init() async {
    await _loadSavedState();
  }

  /// 加载保存的状态
  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Android/iOS: 优先尝试加载内置资产
    if (Platform.isAndroid || Platform.isIOS) {
      await _tryLoadBundledAssets();
      
      // 如果内置资产加载成功，只恢复 LLM 配置
      if (yamlBase != null && embeddingPackage != null) {
        final apiKey = prefs.getString(_keyApiKey);
        if (apiKey != null && apiKey.isNotEmpty) {
          final model = prefs.getString(_keyModel);
          final dim = prefs.getInt(_keyDim);
          final config = LlmConfig.aliyunDashScope(
            apiKey: apiKey,
            model: model ?? 'text-embedding-v4',
            dimension: dim ?? 1024,
          );
          configureLlm(config);
          _configSource = '已保存的配置';
        }
        return; // 移动端完成初始化
      }
    }
    
    // 2. 桌面端优先尝试从 secrets.yaml 自动加载 LLM 配置
    if (!Platform.isAndroid && !Platform.isIOS) {
      try {
        final aliyunConfig = await SecretsLoader.getAliyunConfig();
        final config = LlmConfig.aliyunDashScope(
          apiKey: aliyunConfig.apiKey,
          model: aliyunConfig.embeddingModel,
          dimension: aliyunConfig.embeddingDimension,
        );
        configureLlm(config);
        _configSource = '自动加载自 secrets.yaml';
      } catch (e) {
        print('secrets.yaml 加载跳过: $e');
        // 回退到 SharedPreferences
        final apiKey = prefs.getString(_keyApiKey);
        if (apiKey != null && apiKey.isNotEmpty) {
          final model = prefs.getString(_keyModel);
          final dim = prefs.getInt(_keyDim);
          final config = LlmConfig.aliyunDashScope(
            apiKey: apiKey,
            model: model ?? 'text-embedding-v4',
            dimension: dim ?? 1024,
          );
          configureLlm(config);
          _configSource = '已保存的配置';
        }
      }
    }

    // 3. 桌面端恢复 YAML 路径
    final savedYamlPath = prefs.getString(_keyYamlPath);
    if (savedYamlPath != null) {
      await loadYamlBase(savedYamlPath);
    }

    // 4. 桌面端恢复 Embedding 包
    final savedPakPath = prefs.getString(_keyPakPath);
    if (savedPakPath != null) {
      await loadEmbeddingPackage(savedPakPath);
    }
    
    // 5. 桌面端如果没有保存的资产路径，尝试加载内置资产
    if (yamlBase == null || embeddingPackage == null) {
      await _tryLoadBundledAssets();
    }
  }

  /// 尝试加载应用内置资产（Android APK场景）
  Future<void> _tryLoadBundledAssets() async {
    try {
      await _assetLoader.loadBundledAssets();
      if (_assetLoader.yamlBase != null && _assetLoader.embeddingPackage != null) {
        _yamlPath = '[内置资产]';
        _embeddingPath = '[内置资产]';
        _setSuccess('已自动加载内置法律资产');
      }
    } catch (e) {
      // 内置资产加载失败不报错，用户可手动选择文件
      print('内置资产加载跳过: $e');
    }
  }

  /// 清除所有配置和状态
  Future<void> clearAllState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    _yamlPath = null;
    _embeddingPath = null;
    _llmConfig = null;
    _extractionService = null;
    _assetLoader.yamlBase = null;  // 需要在 AssetLoaderService 中公开 setter 或重置方法，此处假设重新创建
    // 由于 AssetLoaderService 没有 reset 方法，我们最好重新实例化它或者只是清空 Provider 层的引用
    // 但 _assetLoader 是 final。我们需要在 AssetLoaderService 增加 reset。
    // 暂时先只清除 Provider 状态，AssetLoader 保持脏数据直到下次 reload？
    // 为了彻底清除，我们最好刷新页面状态。
    
    resetAnalysis();
    _successMessage = '所有配置已清除';
    notifyListeners();
  }

  /// 加载 YAML 基座
  Future<void> loadYamlBase(String filePath) async {
    _setLoading(true);
    _clearMessages();

    try {
      await _assetLoader.loadYamlBase(filePath);
      _yamlPath = filePath;
      
      // Save to prefs
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyYamlPath, filePath);

      _setSuccess('YAML 基座加载成功: ${yamlBase!.slots.length} 个 Slot, ${yamlBase!.crimes.length} 个罪名');
    } catch (e) {
      _setError('加载 YAML 失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 加载 Embedding 包
  Future<void> loadEmbeddingPackage(String filePath) async {
    _setLoading(true);
    _clearMessages();

    try {
      await _assetLoader.loadEmbeddingPackage(filePath);
      _embeddingPath = filePath;

      // Save to prefs
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPakPath, filePath);

      // 验证资产一致性（包括模型和维度）
      final validation = _assetLoader.validateAssetConsistency(
        currentModelId: _llmConfig?.embeddingModel,
        currentDimension: _llmConfig?.embeddingDimension,
      );
      if (!validation.isValid) {
        _setError('资产一致性检查失败: ${validation.errorMessage}');
      } else {
        _setSuccess('Embedding 包加载成功: ${embeddingPackage!.embeddings.length} 个 Embedding');
      }
    } catch (e) {
      _setError('加载 Embedding 包失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 配置 LLM
  void configureLlm(LlmConfig config) {
    _llmConfig = config;
    _extractionService = LlmExtractionService(config: config);
    
    // Save to prefs
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_keyApiKey, config.apiKey);
      prefs.setString(_keyModel, config.embeddingModel);
      prefs.setInt(_keyDim, config.embeddingDimension);
    });
    
    // 如果资产已加载，重新验证一致性
    if (_assetLoader.embeddingPackage != null) {
      final validation = _assetLoader.validateAssetConsistency(
        currentModelId: config.embeddingModel,
        currentDimension: config.embeddingDimension,
      );
      if (!validation.isValid) {
        _setError('配置变更导致不一致: ${validation.errorMessage}');
      } else {
        // 如果验证通过且之前是因为这个报错，清除错误
        if (_errorMessage != null && _errorMessage!.contains('模型不匹配')) {
          _clearMessages();
          _setSuccess('模型一致性验证通过');
        }
      }
    }
    
    notifyListeners();
  }

  /// 设置案情文本
  void setCaseText(String text) {
    _caseText = text;
    // 重置之前的分析结果
    _caseExtraction = null;
    _analysisResult = null;
    _currentPhase = 1;
    notifyListeners();
  }

  /// 设置分析层级
  void setAnalysisLevel(int level) {
    _analysisLevel = level;
    notifyListeners();
  }

  /// 设置相似度阈值
  void setSimilarityThreshold(double threshold) {
    _similarityThreshold = threshold;
    notifyListeners();
  }

  /// Phase 2: 提取案件事实
  Future<void> extractFacts() async {
    // 防抖：如果正在提取中，忽略重复请求
    if (_isExtracting) return;
    
    if (_caseText.isEmpty) {
      _setError('请输入案情描述');
      return;
    }
    if (yamlBase == null) {
      _setError('请先加载 YAML 基座');
      return;
    }
    if (_extractionService == null) {
      _setError('请先配置 LLM');
      return;
    }

    _isExtracting = true;  // 设置防抖标志
    _setLoading(true);
    _clearMessages();
    _currentPhase = 2;

    try {
      _caseExtraction = await _extractionService!.extractFacts(
        caseText: _caseText,
        slots: yamlBase!.slots,
      );
      _setSuccess('事实提取完成: 提取了 ${_caseExtraction!.extractedSlotIds.length} 个要素');
    } catch (e) {
      _setError('事实提取失败: $e');
    } finally {
      _isExtracting = false;  // 释放防抖标志
      _setLoading(false);
    }
  }

  /// Phase 3: 执行罪名分析（纯本地）
  void analyzeCase() {
    if (_caseExtraction == null) {
      _setError('请先提取案件事实');
      return;
    }
    if (yamlBase == null || embeddingPackage == null) {
      _setError('请先加载 YAML 基座和 Embedding 包');
      return;
    }

    _clearMessages();
    _currentPhase = 3;

    try {
      // Phase 3 是 100% 本地、确定性、白箱过程
      // 禁止调用 LLM、生成新的 embedding、修改 yaml
      _analysisResult = _analysisEngine.analyze(
        yamlBase: yamlBase!,
        legalEmbeddings: embeddingPackage!,
        caseExtraction: _caseExtraction!,
        analysisLevel: _analysisLevel,
        threshold: _similarityThreshold,
      );
      _setSuccess('分析完成');
    } catch (e) {
      _setError('分析失败: $e');
    }
  }

  /// 重置分析
  void resetAnalysis() {
    _caseText = '';
    _caseExtraction = null;
    _analysisResult = null;
    _currentPhase = 1;
    _clearMessages();
    notifyListeners();
  }

  // === Private methods ===

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _successMessage = null;
    notifyListeners();
  }

  void _setSuccess(String message) {
    _successMessage = message;
    _errorMessage = null;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    _clearMessages();
  }
}
