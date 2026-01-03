import 'dart:convert';

/// JSON Schema 校验器
/// 
/// 所有 LLM 输出必须为 JSON。
/// 必须实现 schema 校验。
class JsonSchemaValidator {
  /// 校验 JSON 字符串是否符合基本格式
  static ValidationResult validateJson(String jsonString) {
    try {
      json.decode(jsonString);
      return ValidationResult.success();
    } catch (e) {
      return ValidationResult.failure('Invalid JSON format: $e');
    }
  }

  /// 校验 Embedding 输出格式
  static ValidationResult validateEmbeddingOutput(Map<String, dynamic> data) {
    final errors = <String>[];

    // 检查必需字段
    if (!data.containsKey('slot_embeddings')) {
      errors.add('Missing required field: slot_embeddings');
      return ValidationResult.failure(errors.join('; '));
    }

    final embeddings = data['slot_embeddings'];
    if (embeddings is! List) {
      errors.add('slot_embeddings must be an array');
      return ValidationResult.failure(errors.join('; '));
    }

    // 校验每个 embedding
    for (var i = 0; i < embeddings.length; i++) {
      final item = embeddings[i];
      if (item is! Map<String, dynamic>) {
        errors.add('slot_embeddings[$i] must be an object');
        continue;
      }

      if (!item.containsKey('slot_id') || item['slot_id'] is! String) {
        errors.add('slot_embeddings[$i].slot_id is required and must be a string');
      }

      if (!item.containsKey('embedding_vector') || item['embedding_vector'] is! List) {
        errors.add('slot_embeddings[$i].embedding_vector is required and must be an array');
      } else {
        final vector = item['embedding_vector'] as List;
        if (vector.isEmpty) {
          errors.add('slot_embeddings[$i].embedding_vector cannot be empty');
        }
        for (var j = 0; j < vector.length; j++) {
          if (vector[j] is! num) {
            errors.add('slot_embeddings[$i].embedding_vector[$j] must be a number');
          }
        }
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors.join('; '));
    }
    return ValidationResult.success();
  }

  /// 校验案件提取输出格式
  static ValidationResult validateCaseExtraction(Map<String, dynamic> data) {
    final errors = <String>[];

    // 检查必需字段
    if (!data.containsKey('slot_extractions')) {
      errors.add('Missing required field: slot_extractions');
      return ValidationResult.failure(errors.join('; '));
    }

    final extractions = data['slot_extractions'];
    if (extractions is! List) {
      errors.add('slot_extractions must be an array');
      return ValidationResult.failure(errors.join('; '));
    }

    // 校验每个提取结果
    for (var i = 0; i < extractions.length; i++) {
      final item = extractions[i];
      if (item is! Map<String, dynamic>) {
        errors.add('slot_extractions[$i] must be an object');
        continue;
      }

      if (!item.containsKey('slot_id') || item['slot_id'] is! String) {
        errors.add('slot_extractions[$i].slot_id is required and must be a string');
      }

      // 验证 slot_embedding 如果存在，必须由 slot_text 派生
      if (item.containsKey('slot_embedding') && item['slot_embedding'] != null) {
        if (!item.containsKey('slot_text') || item['slot_text'] == null) {
          errors.add('slot_extractions[$i].slot_embedding exists but slot_text is missing');
        }
      }
    }

    // 校验涉案人员（可选字段）
    if (data.containsKey('involved_persons') && data['involved_persons'] != null) {
      final persons = data['involved_persons'];
      if (persons is! List) {
        errors.add('involved_persons must be an array');
      } else {
        for (var i = 0; i < persons.length; i++) {
          final person = persons[i];
          if (person is! Map<String, dynamic>) {
            errors.add('involved_persons[$i] must be an object');
            continue;
          }
          if (!person.containsKey('id') || person['id'] is! String) {
            errors.add('involved_persons[$i].id is required');
          }
          if (!person.containsKey('name') || person['name'] is! String) {
            errors.add('involved_persons[$i].name is required');
          }
        }
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors.join('; '));
    }
    return ValidationResult.success();
  }

  /// 校验 Embedding 包格式
  static ValidationResult validateEmbeddingPackage(Map<String, dynamic> data) {
    final errors = <String>[];

    // 检查必需字段
    final requiredFields = [
      'embedding_model_id',
      'embedding_version',
      'created_at',
      'dimension',
      'embeddings',
    ];

    for (final field in requiredFields) {
      if (!data.containsKey(field)) {
        errors.add('Missing required field: $field');
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors.join('; '));
    }

    // 类型校验
    if (data['embedding_model_id'] is! String) {
      errors.add('embedding_model_id must be a string');
    }
    if (data['embedding_version'] is! String) {
      errors.add('embedding_version must be a string');
    }
    if (data['dimension'] is! int) {
      errors.add('dimension must be an integer');
    }
    if (data['embeddings'] is! List) {
      errors.add('embeddings must be an array');
    }

    // 校验 embeddings 数组
    if (data['embeddings'] is List) {
      final embeddings = data['embeddings'] as List;
      int? expectedDimension = data['dimension'] as int?;

      for (var i = 0; i < embeddings.length; i++) {
        final item = embeddings[i];
        if (item is! Map<String, dynamic>) {
          errors.add('embeddings[$i] must be an object');
          continue;
        }

        if (!item.containsKey('slot_id')) {
          errors.add('embeddings[$i].slot_id is required');
        }

        if (!item.containsKey('embedding_vector') || item['embedding_vector'] is! List) {
          errors.add('embeddings[$i].embedding_vector is required');
        } else {
          final vector = item['embedding_vector'] as List;
          // 验证维度一致性
          if (expectedDimension != null && vector.length != expectedDimension) {
            errors.add(
                'embeddings[$i].embedding_vector has ${vector.length} dimensions, expected $expectedDimension');
          }
        }
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors.join('; '));
    }
    return ValidationResult.success();
  }
}

/// 校验结果
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult._({
    required this.isValid,
    this.errorMessage,
  });

  factory ValidationResult.success() => const ValidationResult._(isValid: true);

  factory ValidationResult.failure(String message) => ValidationResult._(
        isValid: false,
        errorMessage: message,
      );
}
