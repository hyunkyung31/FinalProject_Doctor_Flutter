// ============================================================
// STEP 1. 검사 종류
// GET /api/examinations/types/ 구조 기준
// ============================================================

class ExaminationTypeUiModel {
  final int id;
  final String code;
  final String name;
  final String category;
  final String? modality;
  final String description;
  final bool isActive;

  const ExaminationTypeUiModel({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.modality,
    required this.description,
    required this.isActive,
  });

  factory ExaminationTypeUiModel.fromJson(Map<String, dynamic> json) {
    return ExaminationTypeUiModel(
      id: json['id'] as int,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      modality: json['modality']?.toString(),
      description: json['description']?.toString() ?? '',
      isActive: json['is_active'] == true,
    );
  }
}

// ============================================================
// STEP 2. 화면 표시용 최소 환자 정보
// 실제 API 연결 시 Patient API 데이터로 교체
// ============================================================

class ExaminationPatientUiModel {
  final int id;
  final String name;
  final int age;
  final String gender;

  const ExaminationPatientUiModel({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
  });
}

// ============================================================
// Encounter
// GET /api/encounters/ 구조 기준
// ============================================================

class ExaminationEncounterUiModel {
  final int id;
  final String encounterType;
  final DateTime visitDate;
  final String status;
  final String? outcome;

  final DateTime? startedAt;
  final DateTime? completedAt;

  final int? reservationId;
  final int patientId;
  final int doctorId;

  const ExaminationEncounterUiModel({
    required this.id,
    required this.encounterType,
    required this.visitDate,
    required this.status,
    required this.outcome,
    required this.startedAt,
    required this.completedAt,
    required this.reservationId,
    required this.patientId,
    required this.doctorId,
  });

  factory ExaminationEncounterUiModel.fromJson(Map<String, dynamic> json) {
    return ExaminationEncounterUiModel(
      id: json['id'] as int,
      encounterType: json['encounter_type']?.toString() ?? '',
      visitDate: DateTime.parse(json['visit_date'].toString()),
      status: json['status']?.toString() ?? '',
      outcome: json['outcome']?.toString(),
      startedAt: json['started_at'] == null
          ? null
          : DateTime.parse(json['started_at'].toString()),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'].toString()),
      reservationId: json['reservation'] as int?,
      patientId: json['patient'] as int,
      doctorId: json['doctor'] as int,
    );
  }
}

// ============================================================
// STEP 4. 검사 오더
// GET /api/examinations/orders/ 구조 기준
// ============================================================

class ExaminationOrderUiModel {
  final int id;

  final String priority;
  final String? clinicalNote;
  final String status;

  final DateTime orderedAt;
  final DateTime? scheduledAt;
  final String? scheduledLocation;

  final DateTime? canceledAt;
  final String? cancelReason;

  final int encounterId;
  final int examinationTypeId;
  final int orderedBy;

  final int? canceledBy;

  const ExaminationOrderUiModel({
    required this.id,
    required this.priority,
    required this.clinicalNote,
    required this.status,
    required this.orderedAt,
    required this.scheduledAt,
    required this.scheduledLocation,
    required this.canceledAt,
    required this.cancelReason,
    required this.encounterId,
    required this.examinationTypeId,
    required this.orderedBy,
    required this.canceledBy,
  });

  factory ExaminationOrderUiModel.fromJson(Map<String, dynamic> json) {
    return ExaminationOrderUiModel(
      id: json['id'] as int,
      priority: json['priority']?.toString() ?? '',
      clinicalNote: json['clinical_note']?.toString(),
      status: json['status']?.toString() ?? '',
      orderedAt: DateTime.parse(json['ordered_at'].toString()),
      scheduledAt: json['scheduled_at'] == null
          ? null
          : DateTime.parse(json['scheduled_at'].toString()),
      scheduledLocation: json['scheduled_location']?.toString(),
      canceledAt: json['canceled_at'] == null
          ? null
          : DateTime.parse(json['canceled_at'].toString()),
      cancelReason: json['cancel_reason']?.toString(),
      encounterId: json['encounter'] as int,
      examinationTypeId: json['examination_type'] as int,
      orderedBy: json['ordered_by'] as int,
      canceledBy: json['canceled_by'] as int?,
    );
  }

  ExaminationOrderUiModel copyWith({
    String? status,
    DateTime? scheduledAt,
    String? scheduledLocation,
    DateTime? canceledAt,
    String? cancelReason,
    int? canceledBy,
  }) {
    return ExaminationOrderUiModel(
      id: id,
      priority: priority,
      clinicalNote: clinicalNote,
      status: status ?? this.status,
      orderedAt: orderedAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      scheduledLocation: scheduledLocation ?? this.scheduledLocation,
      canceledAt: canceledAt ?? this.canceledAt,
      cancelReason: cancelReason ?? this.cancelReason,
      encounterId: encounterId,
      examinationTypeId: examinationTypeId,
      orderedBy: orderedBy,
      canceledBy: canceledBy ?? this.canceledBy,
    );
  }
}

// ============================================================
// STEP 5. 실제 검사 수행
// GET /api/examinations/{id}/ 구조 기준
// ============================================================

class ExaminationExecutionUiModel {
  final int id;
  final int attemptNo;

  final DateTime? performedAt;
  final String location;

  final String status;

  final DateTime createdAt;

  final int orderId;

  const ExaminationExecutionUiModel({
    required this.id,
    required this.attemptNo,
    required this.performedAt,
    required this.location,
    required this.status,
    required this.createdAt,
    required this.orderId,
  });

  ExaminationExecutionUiModel copyWith({
    DateTime? performedAt,
    String? location,
    String? status,
  }) {
    return ExaminationExecutionUiModel(
      id: id,
      attemptNo: attemptNo,
      performedAt: performedAt ?? this.performedAt,
      location: location ?? this.location,
      status: status ?? this.status,
      createdAt: createdAt,
      orderId: orderId,
    );
  }

  factory ExaminationExecutionUiModel.fromJson(Map<String, dynamic> json) {
    return ExaminationExecutionUiModel(
      id: (json['id'] as num).toInt(),
      attemptNo: (json['attempt_no'] as num).toInt(),
      performedAt: json['performed_at'] == null
          ? null
          : DateTime.parse(json['performed_at'].toString()),
      location: json['location']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: DateTime.parse(json['created_at'].toString()),
      orderId: (json['order'] as num).toInt(),
    );
  }
}

class ExaminationResultUiModel {
  final int id;

  final String resultType;
  final int version;

  final DateTime collectedAt;
  final String status;

  final DateTime createdAt;

  final String? summaryText;
  final DateTime? confirmedAt;

  final int examinationId;
  final int? confirmedBy;

  final List<ExaminationMeasurementUiModel> measurements;

  const ExaminationResultUiModel({
    required this.id,
    required this.resultType,
    required this.version,
    required this.collectedAt,
    required this.status,
    required this.createdAt,
    required this.summaryText,
    required this.confirmedAt,
    required this.examinationId,
    required this.confirmedBy,
    required this.measurements,
  });

  factory ExaminationResultUiModel.fromJson(Map<String, dynamic> json) {
    final measurementsData = json['measurements'];

    final measurements = measurementsData is List
        ? measurementsData
              .whereType<Map>()
              .map(
                (item) => ExaminationMeasurementUiModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <ExaminationMeasurementUiModel>[];

    return ExaminationResultUiModel(
      id: (json['id'] as num).toInt(),
      resultType: json['result_type']?.toString() ?? '',
      version: (json['version'] as num?)?.toInt() ?? 1,
      collectedAt: DateTime.parse(json['collected_at'].toString()),
      status: json['status']?.toString() ?? '',
      createdAt: DateTime.parse(json['created_at'].toString()),
      summaryText: json['summary_text']?.toString(),
      confirmedAt: json['confirmed_at'] == null
          ? null
          : DateTime.parse(json['confirmed_at'].toString()),
      examinationId: (json['examination'] as num).toInt(),
      confirmedBy: (json['confirmed_by'] as num?)?.toInt(),
      measurements: measurements,
    );
  }

  factory ExaminationResultUiModel.fromDetailJson(Map<String, dynamic> json) {
    final resultData = json['result'];
    final measurementsData = json['measurements'];

    if (resultData is! Map) {
      throw const FormatException('검사 결과 상세 result 형식이 올바르지 않습니다.');
    }

    final baseResult = ExaminationResultUiModel.fromJson(
      Map<String, dynamic>.from(resultData),
    );

    final measurements = measurementsData is List
        ? measurementsData
              .whereType<Map>()
              .map(
                (item) => ExaminationMeasurementUiModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <ExaminationMeasurementUiModel>[];

    return ExaminationResultUiModel(
      id: baseResult.id,
      resultType: baseResult.resultType,
      version: baseResult.version,
      collectedAt: baseResult.collectedAt,
      status: baseResult.status,
      createdAt: baseResult.createdAt,
      summaryText: baseResult.summaryText,
      confirmedAt: baseResult.confirmedAt,
      examinationId: baseResult.examinationId,
      confirmedBy: baseResult.confirmedBy,
      measurements: measurements,
    );
  }

  ExaminationResultUiModel copyWith({
    String? status,
    DateTime? confirmedAt,
    int? confirmedBy,
  }) {
    return ExaminationResultUiModel(
      id: id,
      resultType: resultType,
      version: version,
      collectedAt: collectedAt,
      status: status ?? this.status,
      createdAt: createdAt,
      summaryText: summaryText,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      examinationId: examinationId,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      measurements: measurements,
    );
  }
}

class ExaminationMeasurementUiModel {
  final int id;

  final int clinicalVariableId;

  final String code;
  final String name;
  final String displayName;

  final int? referenceRangeId;
  final double? referenceMin;
  final double? referenceMax;
  final String? referenceText;

  final String? valueNumeric;
  final String? valueText;
  final bool? valueBoolean;

  final String? unit;
  final String? abnormalFlag;

  final DateTime measuredAt;

  final String validationStatus;
  final String? validationMessage;

  final DateTime? validatedAt;
  final int? examinationResultId;
  final int? validatedBy;

  const ExaminationMeasurementUiModel({
    required this.id,
    required this.valueNumeric,
    required this.valueText,
    required this.valueBoolean,
    required this.unit,
    required this.abnormalFlag,
    required this.measuredAt,
    required this.validationStatus,
    required this.validationMessage,
    required this.clinicalVariableId,
    this.code = '',
    this.name = '',
    this.displayName = '',
    this.referenceRangeId,
    this.referenceMin,
    this.referenceMax,
    this.referenceText,
    this.validatedAt,
    this.examinationResultId,
    this.validatedBy,
  });

  factory ExaminationMeasurementUiModel.fromJson(Map<String, dynamic> json) {
    return ExaminationMeasurementUiModel(
      id: _parseInt(json['id']) ?? 0,
      clinicalVariableId:
          _parseInt(
            json['clinical_variable_id'] ?? json['clinical_variable'],
          ) ??
          0,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      referenceRangeId: _parseInt(json['reference_range_id']),
      referenceMin: _parseDouble(json['reference_min']),
      referenceMax: _parseDouble(json['reference_max']),
      referenceText: json['reference_text']?.toString(),
      valueNumeric: json['value_numeric']?.toString(),
      valueText: json['value_text']?.toString(),
      valueBoolean: json['value_boolean'] is bool
          ? json['value_boolean'] as bool
          : null,
      unit: json['unit']?.toString(),
      abnormalFlag: json['abnormal_flag']?.toString(),
      measuredAt: DateTime.parse(json['measured_at'].toString()),
      validationStatus: json['validation_status']?.toString() ?? '',
      validationMessage: json['validation_message']?.toString(),
      validatedAt: json['validated_at'] == null
          ? null
          : DateTime.parse(json['validated_at'].toString()),
      examinationResultId: _parseInt(json['examination_result']),
      validatedBy: _parseInt(json['validated_by']),
    );
  }

  String get displayLabel {
    if (displayName.trim().isNotEmpty) {
      return displayName;
    }

    if (name.trim().isNotEmpty) {
      return name;
    }

    if (code.trim().isNotEmpty) {
      return code;
    }

    return '검사 항목';
  }

  String get displayValue {
    if (valueNumeric != null) {
      final number = double.tryParse(valueNumeric!);

      if (number == null) {
        return valueNumeric!;
      }

      if (number == number.roundToDouble()) {
        return number.toInt().toString();
      }

      return number.toStringAsFixed(2);
    }

    if (valueText != null) {
      return valueText!;
    }

    if (valueBoolean != null) {
      return valueBoolean! ? 'Yes' : 'No';
    }

    return '-';
  }

  double? get numericValue {
    return double.tryParse(valueNumeric ?? '');
  }

  bool get isAbnormal {
    final flag = abnormalFlag?.trim().toUpperCase() ?? '';

    return flag == 'HIGH' || flag == 'LOW';
  }

  String get abnormalLabel {
    switch (abnormalFlag?.trim().toUpperCase()) {
      case 'HIGH':
        return '높음';
      case 'LOW':
        return '낮음';
      case 'NORMAL':
        return '정상';
      default:
        return '-';
    }
  }

  static int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }

  static double? _parseDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }
}
