import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:legal_engine_shared/legal_engine_shared.dart';

/// YAML 基座服务
/// 
/// 负责读取、解析和保存 YAML 基座文件。
/// YAML 是系统的唯一权威结构定义。
class YamlService {
  /// 从文件读取 YAML 基座
  Future<YamlBase> loadFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('YAML 文件不存在', filePath);
    }

    final content = await file.readAsString();
    return parseYaml(content);
  }

  /// 解析 YAML 字符串为 YamlBase 对象
  YamlBase parseYaml(String yamlContent) {
    final yamlMap = loadYaml(yamlContent) as YamlMap;
    
    // 解析全局信息
    final yamlVersion = yamlMap['yaml_version'] as String? ?? '1.0.0';
    final legalSystemTypeStr = yamlMap['legal_system_type'] as String? ?? 'criminal';
    final legalSystemType = _parseLegalSystemType(legalSystemTypeStr);

    // 解析分析层级
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

    // 解析 Slots
    final slots = <Slot>[];
    final slotsYaml = yamlMap['slots'] as YamlList?;
    if (slotsYaml != null) {
      for (final slotYaml in slotsYaml) {
        slots.add(_parseSlot(slotYaml));
      }
    }

    // 解析 Crimes
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

  /// 将 YamlBase 转换为 YAML 格式字符串
  String toYamlString(YamlBase yamlBase) {
    final buffer = StringBuffer();
    
    buffer.writeln('yaml_version: "${yamlBase.yamlVersion}"');
    buffer.writeln('legal_system_type: "${_legalSystemTypeToString(yamlBase.legalSystemType)}"');
    
    // 分析层级
    buffer.writeln('analysis_levels:');
    for (final level in yamlBase.analysisLevels) {
      buffer.writeln('  - level: ${level.level}');
      buffer.writeln('    name: "${level.name}"');
    }
    
    // Slots
    buffer.writeln('\nslots:');
    for (final slot in yamlBase.slots) {
      buffer.writeln('  - slot_id: "${slot.slotId}"');
      buffer.writeln('    slot_name: "${slot.slotName}"');
      buffer.writeln('    analysis_level: ${slot.analysisLevel}');
      buffer.writeln('    required: ${slot.required}');
      buffer.writeln('    role: "${_slotRoleToString(slot.role)}"');
      buffer.writeln('    semantic_scope: "${slot.semanticScope}"');
    }
    
    // Crimes
    buffer.writeln('\ncrimes:');
    for (final crime in yamlBase.crimes) {
      buffer.writeln('  - crime_id: "${crime.crimeId}"');
      buffer.writeln('    crime_name: "${crime.crimeName}"');
      buffer.writeln('    applicable_case_type: "${crime.applicableCaseType}"');
      buffer.writeln('    required_slots: [${crime.requiredSlots.map((s) => '"$s"').join(', ')}]');
      buffer.writeln('    optional_slots: [${crime.optionalSlots.map((s) => '"$s"').join(', ')}]');
      buffer.writeln('    exclusion_slots: [${crime.exclusionSlots.map((s) => '"$s"').join(', ')}]');
      buffer.writeln('    explanation_template: |');
      for (final line in crime.explanationTemplate.split('\n')) {
        buffer.writeln('      $line');
      }
    }
    
    return buffer.toString();
  }

  /// 保存 YamlBase 到文件
  Future<void> saveToFile(YamlBase yamlBase, String filePath) async {
    final content = toYamlString(yamlBase);
    final file = File(filePath);
    await file.writeAsString(content);
  }

  /// 创建默认的 YAML 基座模板
  YamlBase createDefaultTemplate() {
    return YamlBase(
      yamlVersion: '1.0.0',
      legalSystemType: LegalSystemType.criminal,
      analysisLevels: [
        const AnalysisLevel(level: 1, name: '核心要件'),
        const AnalysisLevel(level: 2, name: '辅助要件'),
        const AnalysisLevel(level: 3, name: '情节要素'),
      ],
      slots: [
        const Slot(
          slotId: 'S001',
          slotName: '主体适格性',
          analysisLevel: 1,
          required: true,
          role: SlotRole.qualification,
          semanticScope: '行为主体是否具备刑事责任能力',
        ),
        const Slot(
          slotId: 'S002',
          slotName: '主观故意',
          analysisLevel: 1,
          required: true,
          role: SlotRole.qualification,
          semanticScope: '行为人是否存在犯罪故意或过失',
        ),
        const Slot(
          slotId: 'S003',
          slotName: '正当防卫',
          analysisLevel: 2,
          required: false,
          role: SlotRole.exclusion,
          semanticScope: '是否构成正当防卫或紧急避险',
        ),
      ],
      crimes: [
        const Crime(
          crimeId: 'C001',
          crimeName: '故意杀人罪',
          applicableCaseType: 'criminal',
          requiredSlots: ['S001', 'S002'],
          optionalSlots: [],
          exclusionSlots: ['S003'],
          explanationTemplate: '''根据《刑法》第二百三十二条，故意杀人的，处死刑、无期徒刑或者十年以上有期徒刑。
本案中，{slot_analysis}。''',
        ),
      ],
    );
  }

  // === Private helper methods ===

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

  String _legalSystemTypeToString(LegalSystemType type) {
    switch (type) {
      case LegalSystemType.criminal:
        return 'criminal';
      case LegalSystemType.administrative:
        return 'administrative';
      case LegalSystemType.civil:
        return 'civil';
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

  String _slotRoleToString(SlotRole role) {
    switch (role) {
      case SlotRole.qualification:
        return '定性';
      case SlotRole.exclusion:
        return '排除';
      case SlotRole.explanation:
        return '解释';
      case SlotRole.statistics:
        return '统计';
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
