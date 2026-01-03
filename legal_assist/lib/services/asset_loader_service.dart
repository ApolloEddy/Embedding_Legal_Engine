import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';
import 'package:legal_engine_shared/legal_engine_shared.dart';

/// 资产加载服务
/// 
/// 负责加载只读资产文件：
/// - YAML 基座文件
/// - Embedding 包
/// 
/// 两个程序之间只允许通过只读文件资产交互，
/// 禁止共享运行态逻辑或内存状态。
class AssetLoaderService {
  YamlBase? _yamlBase;
  EmbeddingPackage? _embeddingPackage;

  YamlBase? get yamlBase => _yamlBase;
  set yamlBase(YamlBase? value) => _yamlBase = value;
  
  EmbeddingPackage? get embeddingPackage => _embeddingPackage;
  set embeddingPackage(EmbeddingPackage? value) => _embeddingPackage = value;

  /// 加载应用内置资产（从Flutter assets目录）
  Future<void> loadBundledAssets() async {
    // 加载内置 YAML 基座
    final yamlContent = await rootBundle.loadString('assets/legal_base.yaml');
    _yamlBase = _parseYaml(yamlContent);
    
    // 加载内置 Embedding 包
    final pakContent = await rootBundle.loadString('assets/v4-embedding-刑法.pak');
    final json = jsonDecode(pakContent) as Map<String, dynamic>;
    
    final validation = JsonSchemaValidator.validateEmbeddingPackage(json);
    if (!validation.isValid) {
      throw Exception('内置 Embedding 包格式校验失败: ${validation.errorMessage}');
    }
    
    _embeddingPackage = EmbeddingPackage.fromJson(json);
  }

  /// 加载 YAML 基座文件
  Future<YamlBase> loadYamlBase(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('YAML 基座文件不存在', filePath);
    }

    final content = await file.readAsString();
    _yamlBase = _parseYaml(content);
    return _yamlBase!;
  }

  /// 加载 Embedding 包
  Future<EmbeddingPackage> loadEmbeddingPackage(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('Embedding 包文件不存在', filePath);
    }

    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;

    // 校验格式
    final validation = JsonSchemaValidator.validateEmbeddingPackage(json);
    if (!validation.isValid) {
      throw Exception('Embedding 包格式校验失败: ${validation.errorMessage}');
    }

    _embeddingPackage = EmbeddingPackage.fromJson(json);
    return _embeddingPackage!;
  }

  /// 验证资产一致性（包括模型一致性和维度一致性）
  ValidationResult validateAssetConsistency({
    String? currentModelId,
    int? currentDimension,  // 新增：维度校验
  }) {
    if (_yamlBase == null || _embeddingPackage == null) {
      return ValidationResult.failure('请先加载 YAML 基座和 Embedding 包');
    }

    final errors = <String>[];

    // 检查模型ID是否一致
    if (currentModelId != null && _embeddingPackage!.embeddingModelId != currentModelId) {
      errors.add(
          '模型不匹配: 包使用 ${_embeddingPackage!.embeddingModelId}, 当前配置使用 $currentModelId');
    }

    // 检查维度是否一致
    if (currentDimension != null && _embeddingPackage!.embeddings.isNotEmpty) {
      final pkgDimension = _embeddingPackage!.embeddings.first.embeddingVector.length;
      if (pkgDimension != currentDimension) {
        errors.add(
            '维度不匹配: 包使用 $pkgDimension 维, 当前配置使用 $currentDimension 维');
      }
    }

    // 检查所有 slot 是否有对应的 embedding
    for (final slot in _yamlBase!.slots) {
      final embedding = _embeddingPackage!.getEmbeddingBySlotId(slot.slotId);
      if (embedding == null) {
        errors.add('Slot ${slot.slotId} 缺少对应的 Embedding');
      }
    }

    // 检查 embedding 包中是否有多余的 slot
    for (final embedding in _embeddingPackage!.embeddings) {
      final slot = _yamlBase!.findSlotById(embedding.slotId);
      if (slot == null) {
        errors.add('Embedding ${embedding.slotId} 在 YAML 中不存在');
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors.join('; '));
    }
    return ValidationResult.success();
  }

  // === Private methods ===

  YamlBase _parseYaml(String yamlContent) {
    final yamlMap = loadYaml(yamlContent) as YamlMap;

    final yamlVersion = yamlMap['yaml_version'] as String? ?? '1.0.0';
    final legalSystemTypeStr = yamlMap['legal_system_type'] as String? ?? 'criminal';
    final legalSystemType = _parseLegalSystemType(legalSystemTypeStr);

    final analysisLevels = <AnalysisLevel>[];
    final levelsYaml = yamlMap['analysis_levels'] as YamlList?;
    if (levelsYaml != null) {
      for (final levelYaml in levelsYaml) {
        analysisLevels.add(AnalysisLevel(
          level: levelYaml['level'] as int,
          name: levelYaml['name'] as String,
        ));
      }
    }

    final slots = <Slot>[];
    final slotsYaml = yamlMap['slots'] as YamlList?;
    if (slotsYaml != null) {
      for (final slotYaml in slotsYaml) {
        slots.add(_parseSlot(slotYaml));
      }
    }

    final crimes = <Crime>[];
    final crimesYaml = yamlMap['crimes'] as YamlList?;
    if (crimesYaml != null) {
      for (final crimeYaml in crimesYaml) {
        crimes.add(_parseCrime(crimeYaml));
      }
    }

    return YamlBase(
      yamlVersion: yamlVersion,
      legalSystemType: legalSystemType,
      analysisLevels: analysisLevels,
      slots: slots,
      crimes: crimes,
    );
  }

  LegalSystemType _parseLegalSystemType(String value) {
    switch (value.toLowerCase()) {
      case 'criminal':
        return LegalSystemType.criminal;
      case 'administrative':
        return LegalSystemType.administrative;
      case 'civil':
        return LegalSystemType.civil;
      default:
        return LegalSystemType.criminal;
    }
  }

  Slot _parseSlot(dynamic slotYaml) {
    return Slot(
      slotId: slotYaml['slot_id'] as String,
      slotName: slotYaml['slot_name'] as String,
      analysisLevel: slotYaml['analysis_level'] as int,
      required: slotYaml['required'] as bool? ?? false,
      role: _parseSlotRole(slotYaml['role'] as String),
      semanticScope: slotYaml['semantic_scope'] as String,
    );
  }

  SlotRole _parseSlotRole(String value) {
    switch (value) {
      case '定性':
        return SlotRole.qualification;
      case '排除':
        return SlotRole.exclusion;
      case '解释':
        return SlotRole.explanation;
      case '统计':
        return SlotRole.statistics;
      default:
        return SlotRole.qualification;
    }
  }

  Crime _parseCrime(dynamic crimeYaml) {
    return Crime(
      crimeId: crimeYaml['crime_id'] as String,
      crimeName: crimeYaml['crime_name'] as String,
      applicableCaseType: crimeYaml['applicable_case_type'] as String,
      requiredSlots: _parseStringList(crimeYaml['required_slots']),
      optionalSlots: _parseStringList(crimeYaml['optional_slots']),
      exclusionSlots: _parseStringList(crimeYaml['exclusion_slots']),
      explanationTemplate: crimeYaml['explanation_template'] as String? ?? '',
    );
  }

  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is YamlList) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }
}
