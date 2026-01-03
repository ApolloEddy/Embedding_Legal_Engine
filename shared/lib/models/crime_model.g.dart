// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crime_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Crime _$CrimeFromJson(Map<String, dynamic> json) => Crime(
      crimeId: json['crime_id'] as String,
      crimeName: json['crime_name'] as String,
      applicableCaseType: json['applicable_case_type'] as String,
      requiredSlots: (json['required_slots'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      optionalSlots: (json['optional_slots'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      exclusionSlots: (json['exclusion_slots'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      explanationTemplate: json['explanation_template'] as String,
    );

Map<String, dynamic> _$CrimeToJson(Crime instance) => <String, dynamic>{
      'crime_id': instance.crimeId,
      'crime_name': instance.crimeName,
      'applicable_case_type': instance.applicableCaseType,
      'required_slots': instance.requiredSlots,
      'optional_slots': instance.optionalSlots,
      'exclusion_slots': instance.exclusionSlots,
      'explanation_template': instance.explanationTemplate,
    };
