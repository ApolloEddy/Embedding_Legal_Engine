/// JSON Schema 定义
/// 
/// 用于验证 LLM 输出格式和数据结构

/// Embedding 计算输出的 Schema（程序 A）
const String embeddingOutputSchema = r'''
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["slot_embeddings"],
  "properties": {
    "slot_embeddings": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["slot_id", "embedding_vector"],
        "properties": {
          "slot_id": {
            "type": "string",
            "minLength": 1
          },
          "embedding_vector": {
            "type": "array",
            "items": {
              "type": "number"
            },
            "minItems": 1
          }
        }
      }
    }
  }
}
''';

/// 案件事实提取输出的 Schema（程序 B Phase 2）
const String caseExtractionSchema = r'''
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["slot_extractions"],
  "properties": {
    "slot_extractions": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["slot_id"],
        "properties": {
          "slot_id": {
            "type": "string",
            "minLength": 1
          },
          "slot_text": {
            "type": ["string", "null"]
          },
          "slot_embedding": {
            "type": ["array", "null"],
            "items": {
              "type": "number"
            }
          },
          "confidence": {
            "type": ["number", "null"],
            "minimum": 0,
            "maximum": 1
          }
        }
      }
    },
    "involved_persons": {
      "type": ["array", "null"],
      "items": {
        "type": "object",
        "required": ["id", "name"],
        "properties": {
          "id": {
            "type": "string"
          },
          "name": {
            "type": "string"
          },
          "role": {
            "type": ["string", "null"]
          },
          "action_summary": {
            "type": ["string", "null"]
          }
        }
      }
    }
  }
}
''';

/// Embedding 包的 Schema
const String embeddingPackageSchema = r'''
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["embedding_model_id", "embedding_version", "created_at", "dimension", "embeddings"],
  "properties": {
    "embedding_model_id": {
      "type": "string",
      "minLength": 1
    },
    "embedding_version": {
      "type": "string",
      "pattern": "^\\d+\\.\\d+\\.\\d+$"
    },
    "created_at": {
      "type": "string",
      "format": "date-time"
    },
    "dimension": {
      "type": "integer",
      "minimum": 1
    },
    "embeddings": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["slot_id", "embedding_vector"],
        "properties": {
          "slot_id": {
            "type": "string"
          },
          "embedding_vector": {
            "type": "array",
            "items": {
              "type": "number"
            }
          },
          "source_article_id": {
            "type": ["string", "null"]
          }
        }
      }
    }
  }
}
''';
