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
// STEP 3. Encounter
// GET /api/encounters/ 구조 기준
// ============================================================

class ExaminationEncounterUiModel {
  final int id;
  final String encounterType;
  final DateTime visitDate;
  final String status;
  final String? outcome;

  final int? reservationId;
  final int patientId;
  final int doctorId;

  const ExaminationEncounterUiModel({
    required this.id,
    required this.encounterType,
    required this.visitDate,
    required this.status,
    required this.outcome,
    required this.reservationId,
    required this.patientId,
    required this.doctorId,
  });
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
}

// ============================================================
// STEP 6. 검사 결과
// GET /api/examinations/{id}/results/ 구조 기준
// ============================================================

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

// ============================================================
// STEP 7. 혈액검사 Measurement
// GET /api/examinations/results/{id}/ 구조 기준
// ============================================================

class ExaminationMeasurementUiModel {
  final int id;

  final String? valueNumeric;
  final String? valueText;
  final bool? valueBoolean;

  final String? unit;

  final String? abnormalFlag;

  final DateTime measuredAt;

  final String validationStatus;
  final String? validationMessage;

  final int clinicalVariableId;

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
  });

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
}
