import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:legal_engine_shared/legal_engine_shared.dart';
import '../services/yaml_service.dart';
import '../services/llm_service.dart';
import '../services/embedding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用状态管理
class AppProvider extends ChangeNotifier {
  final YamlService _yamlService = YamlService();
  LlmService? _llmService;
  EmbeddingService? _embeddingService;

  // 当前加载的 YAML 基座
  YamlBase? _yamlBase;
  YamlBase? get yamlBase => _yamlBase;

  // 当前 YAML 文件路径
  String? _currentYamlPath;
  String? get currentYamlPath => _currentYamlPath;

  // LLM 配置
  LlmConfig? _llmConfig;
  LlmConfig? get llmConfig => _llmConfig;

  // 配置来源（用于 UI 显示）
  String? _configSource;
  String? get configSource => _configSource;

  // 法律条文
  List<LawArticle> _articles = [];
  List<LawArticle> get articles => _articles;

  // Embedding 包
  EmbeddingPackage? _embeddingPackage;
  EmbeddingPackage? get embeddingPackage => _embeddingPackage;

  // 状态
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  // Embedding 进度
  int _embeddingProgress = 0;
  int get embeddingProgress => _embeddingProgress;

  int _embeddingTotal = 0;
  int get embeddingTotal => _embeddingTotal;

  String _embeddingStatus = '';
  String get embeddingStatus => _embeddingStatus;

  // Persistence Keys
  static const String _keyApiKey = 'p_a_api_key';
  static const String _keyModel = 'p_a_model';
  static const String _keyDim = 'p_a_dim';

  /// 初始化
  Future<void> init() async {
    await _loadSavedState();
  }

  /// 加载保存的状态
  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. 桌面端优先尝试从 secrets.yaml 自动加载
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
        notifyListeners();
        return; // 成功加载，跳过 SharedPreferences
      } catch (e) {
        print('secrets.yaml 加载跳过: $e');
      }
    }
    
    // 2. 回退到 SharedPreferences
    final apiKey = prefs.getString(_keyApiKey);
    final model = prefs.getString(_keyModel);
    final dim = prefs.getInt(_keyDim);

    if (apiKey != null && apiKey.isNotEmpty) {
      final config = LlmConfig.aliyunDashScope(
        apiKey: apiKey,
        model: model ?? 'text-embedding-v4',
        dimension: dim ?? 1024,
      );
      configureLlm(config);
      _configSource = '已保存的配置';
    }
  }

  /// 清除缓存
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _llmConfig = null;
    _llmService = null;
    _embeddingService = null;
    notifyListeners();
  }

  /// 创建默认 YAML 模板
  void createDefaultTemplate() {
    _yamlBase = _yamlService.createDefaultTemplate();
    _currentYamlPath = null;
    notifyListeners();
  }

  /// 加载 YAML 文件
  Future<void> loadYamlFile(String filePath) async {
    _setLoading(true);
    _clearMessages();

    try {
      _yamlBase = await _yamlService.loadFromFile(filePath);
      _currentYamlPath = filePath;
      _setSuccess('YAML 文件加载成功');
    } catch (e) {
      _setError('加载 YAML 失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 保存 YAML 文件
  Future<void> saveYamlFile(String filePath) async {
    if (_yamlBase == null) {
      _setError('没有可保存的 YAML 数据');
      return;
    }

    _setLoading(true);
    _clearMessages();

    try {
      await _yamlService.saveToFile(_yamlBase!, filePath);
      _currentYamlPath = filePath;
      _setSuccess('YAML 文件保存成功');
    } catch (e) {
      _setError('保存 YAML 失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 更新 YAML 基座
  void updateYamlBase(YamlBase newYamlBase) {
    _yamlBase = newYamlBase;
    notifyListeners();
  }

  /// 添加 Slot
  void addSlot(Slot slot) {
    if (_yamlBase == null) return;
    final newSlots = List<Slot>.from(_yamlBase!.slots)..add(slot);
    _yamlBase = YamlBase(
      yamlVersion: _yamlBase!.yamlVersion,
      legalSystemType: _yamlBase!.legalSystemType,
      analysisLevels: _yamlBase!.analysisLevels,
      slots: newSlots,
      crimes: _yamlBase!.crimes,
    );
    notifyListeners();
  }

  /// 删除 Slot
  void removeSlot(String slotId) {
    if (_yamlBase == null) return;
    final newSlots = _yamlBase!.slots.where((s) => s.slotId != slotId).toList();
    _yamlBase = YamlBase(
      yamlVersion: _yamlBase!.yamlVersion,
      legalSystemType: _yamlBase!.legalSystemType,
      analysisLevels: _yamlBase!.analysisLevels,
      slots: newSlots,
      crimes: _yamlBase!.crimes,
    );
    notifyListeners();
  }

  /// 添加 Crime
  void addCrime(Crime crime) {
    if (_yamlBase == null) return;
    final newCrimes = List<Crime>.from(_yamlBase!.crimes)..add(crime);
    _yamlBase = YamlBase(
      yamlVersion: _yamlBase!.yamlVersion,
      legalSystemType: _yamlBase!.legalSystemType,
      analysisLevels: _yamlBase!.analysisLevels,
      slots: _yamlBase!.slots,
      crimes: newCrimes,
    );
    notifyListeners();
  }

  /// 删除 Crime
  void removeCrime(String crimeId) {
    if (_yamlBase == null) return;
    final newCrimes = _yamlBase!.crimes.where((c) => c.crimeId != crimeId).toList();
    _yamlBase = YamlBase(
      yamlVersion: _yamlBase!.yamlVersion,
      legalSystemType: _yamlBase!.legalSystemType,
      analysisLevels: _yamlBase!.analysisLevels,
      slots: _yamlBase!.slots,
      crimes: newCrimes,
    );
    notifyListeners();
  }

  /// 配置 LLM
  void configureLlm(LlmConfig config) {
    _llmConfig = config;
    _llmService = LlmService(config: config);
    _embeddingService = EmbeddingService(llmService: _llmService!);

    // Save
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_keyApiKey, config.apiKey);
      prefs.setString(_keyModel, config.embeddingModel);
      prefs.setInt(_keyDim, config.embeddingDimension);
    });

    notifyListeners();
  }

  /// 加载法律条文目录
  Future<void> loadArticlesFromDirectory(String directoryPath) async {
    if (_embeddingService == null) {
      _setError('请先配置 LLM');
      return;
    }

    _setLoading(true);
    _clearMessages();

    try {
      _articles = await _embeddingService!.loadArticlesFromDirectory(directoryPath);
      _setSuccess('已加载 ${_articles.length} 个法律条文文件');
    } catch (e) {
      _setError('加载法律条文失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 添加法律条文
  void addArticle(LawArticle article) {
    _articles = List.from(_articles)..add(article);
    notifyListeners();
  }

  /// 计算 Embedding
  Future<void> computeEmbeddings() async {
    if (_yamlBase == null) {
      _setError('请先加载或创建 YAML 基座');
      return;
    }
    if (_embeddingService == null) {
      _setError('请先配置 LLM');
      return;
    }

    _setLoading(true);
    _clearMessages();
    _embeddingProgress = 0;
    _embeddingTotal = _yamlBase!.slots.length;

    try {
      _embeddingPackage = await _embeddingService!.computeEmbeddings(
        yamlBase: _yamlBase!,
        articles: _articles,
        onProgress: (current, total, message) {
          _embeddingProgress = current;
          _embeddingTotal = total;
          _embeddingStatus = message;
          notifyListeners();
        },
      );
      _setSuccess('Embedding 计算完成，共 ${_embeddingPackage!.embeddings.length} 个 slot');
    } catch (e) {
      _setError('Embedding 计算失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 导出 Embedding 包
  Future<void> exportEmbeddingPackage(String filePath) async {
    if (_embeddingPackage == null) {
      _setError('没有可导出的 Embedding 包');
      return;
    }
    if (_embeddingService == null) {
      _setError('服务未初始化');
      return;
    }

    _setLoading(true);
    _clearMessages();

    try {
      await _embeddingService!.exportPackage(_embeddingPackage!, filePath);
      _setSuccess('Embedding 包已导出到: $filePath');
    } catch (e) {
      _setError('导出失败: $e');
    } finally {
      _setLoading(false);
    }
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
