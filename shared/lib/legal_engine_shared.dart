/// Shared data structures and validators for Legal Engine system
library legal_engine_shared;

// Models
export 'models/yaml_base_model.dart';
export 'models/slot_model.dart';
export 'models/crime_model.dart';
export 'models/embedding_package_model.dart';
export 'models/case_extraction_model.dart';
export 'models/analysis_result_model.dart';
export 'models/tiered_analysis_model.dart';

// Schemas
export 'schemas/json_schemas.dart';

// Validators
export 'validators/json_schema_validator.dart';

// Utils
export 'utils/similarity_calculator.dart';
export 'utils/law_article_parser.dart';
export 'utils/secrets_loader.dart';
export 'utils/input_sanitizer.dart';

