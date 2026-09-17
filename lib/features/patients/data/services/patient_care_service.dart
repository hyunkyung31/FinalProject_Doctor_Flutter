import '../../../../core/network/api_client.dart';

class PatientVitalSign {
  final int id;
  final int? systolicBp;
  final int? diastolicBp;
  final int? pulseRate;
  final int? respiratoryRate;

  final double? bodyTemperature;
  final double? oxygenSaturation;
  final double? heightCm;
  final double? weightKg;

  final DateTime? measuredAt;
  final DateTime? createdAt;

  final int encounterId;
  final int measuredBy;

  const PatientVitalSign({
    required this.id,
    required this.systolicBp,
    required this.diastolicBp,
    required this.pulseRate,
    required this.respiratoryRate,
    required this.bodyTemperature,
    required this.oxygenSaturation,
    required this.heightCm,
    required this.weightKg,
    required this.measuredAt,
    required this.createdAt,
    required this.encounterId,
    required this.measuredBy,
  });

  factory PatientVitalSign.fromJson(Map<String, dynamic> json) {
    return PatientVitalSign(
      id: _parseInt(json['id']) ?? 0,
      systolicBp: _parseInt(json['systolic_bp']),
      diastolicBp: _parseInt(json['diastolic_bp']),
      pulseRate: _parseInt(json['pulse_rate']),
      respiratoryRate: _parseInt(json['respiratory_rate']),
      bodyTemperature: _parseDouble(json['body_temperature']),
      oxygenSaturation: _parseDouble(json['oxygen_saturation']),
      heightCm: _parseDouble(json['height_cm']),
      weightKg: _parseDouble(json['weight_kg']),
      measuredAt: DateTime.tryParse(json['measured_at']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      encounterId: _parseInt(json['encounter']) ?? 0,
      measuredBy: _parseInt(json['measured_by']) ?? 0,
    );
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
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }
}

class PatientEncounterNote {
  final int id;
  final String noteType;
  final String noteText;
  final String status;

  final DateTime? confirmedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final int encounterId;
  final int authorId;

  const PatientEncounterNote({
    required this.id,
    required this.noteType,
    required this.noteText,
    required this.status,
    required this.confirmedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.encounterId,
    required this.authorId,
  });

  factory PatientEncounterNote.fromJson(Map<String, dynamic> json) {
    return PatientEncounterNote(
      id: _parseInt(json['id']) ?? 0,
      noteType: json['note_type']?.toString() ?? '',
      noteText: json['note_text']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      confirmedAt: DateTime.tryParse(json['confirmed_at']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      encounterId: _parseInt(json['encounter']) ?? 0,
      authorId: _parseInt(json['author']) ?? 0,
    );
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
}

class PatientMedicalHistory {
  final int id;
  final String conditionCode;
  final String conditionName;
  final DateTime? onsetDate;
  final DateTime? resolvedDate;
  final String status;
  final String note;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final int patientId;
  final int recordedBy;

  const PatientMedicalHistory({
    required this.id,
    required this.conditionCode,
    required this.conditionName,
    required this.onsetDate,
    required this.resolvedDate,
    required this.status,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    required this.patientId,
    required this.recordedBy,
  });

  factory PatientMedicalHistory.fromJson(Map<String, dynamic> json) {
    return PatientMedicalHistory(
      id: _parseInt(json['id']) ?? 0,
      conditionCode: json['condition_code']?.toString() ?? '',
      conditionName: json['condition_name']?.toString() ?? '',
      onsetDate: DateTime.tryParse(json['onset_date']?.toString() ?? ''),
      resolvedDate: DateTime.tryParse(json['resolved_date']?.toString() ?? ''),
      status: json['status']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      patientId: _parseInt(json['patient']) ?? 0,
      recordedBy: _parseInt(json['recorded_by']) ?? 0,
    );
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
}

class PatientAllergy {
  final int id;
  final String allergenType;
  final String allergenName;
  final String reaction;
  final String severity;
  final String status;

  final bool isNoKnownAllergy;
  final String? note;

  final DateTime? verifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final int patientId;
  final int verifiedBy;
  final int recordedBy;

  const PatientAllergy({
    required this.id,
    required this.allergenType,
    required this.allergenName,
    required this.reaction,
    required this.severity,
    required this.status,
    required this.isNoKnownAllergy,
    required this.note,
    required this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.patientId,
    required this.verifiedBy,
    required this.recordedBy,
  });

  factory PatientAllergy.fromJson(Map<String, dynamic> json) {
    return PatientAllergy(
      id: _parseInt(json['id']) ?? 0,
      allergenType: json['allergen_type']?.toString() ?? '',
      allergenName: json['allergen_name']?.toString() ?? '',
      reaction: json['reaction']?.toString() ?? '',
      severity: json['severity']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      isNoKnownAllergy: json['is_no_known_allergy'] == true,
      note: json['note']?.toString(),
      verifiedAt: DateTime.tryParse(json['verified_at']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      patientId: _parseInt(json['patient']) ?? 0,
      verifiedBy: _parseInt(json['verified_by']) ?? 0,
      recordedBy: _parseInt(json['recorded_by']) ?? 0,
    );
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
}

class PatientCareService {
  final ApiClient apiClient;

  PatientCareService({required this.apiClient});

  Future<List<PatientMedicalHistory>> fetchMedicalHistories(
    int patientId,
  ) async {
    final response = await apiClient.dio.get(
      '/patients/$patientId/medical-histories/',
    );

    final responseData = response.data;

    if (responseData is! List) {
      throw const FormatException('과거력 응답 형식이 올바르지 않습니다.');
    }

    return responseData.map((item) {
      if (item is! Map) {
        throw const FormatException('과거력 항목 형식이 올바르지 않습니다.');
      }

      return PatientMedicalHistory.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  Future<List<PatientAllergy>> fetchAllergies(int patientId) async {
    final response = await apiClient.dio.get('/patients/$patientId/allergies/');

    final responseData = response.data;

    if (responseData is! List) {
      throw const FormatException('알레르기 응답 형식이 올바르지 않습니다.');
    }

    return responseData.map((item) {
      if (item is! Map) {
        throw const FormatException('알레르기 항목 형식이 올바르지 않습니다.');
      }

      return PatientAllergy.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  Future<PatientAllergy> createAllergy({
    required int patientId,
    required String allergenName,
    required String reaction,
    String allergenType = 'DRUG',
    String severity = 'MILD',
    String status = 'ACTIVE',
  }) async {
    final normalizedName = allergenName.trim();
    final normalizedReaction = reaction.trim();

    if (normalizedName.isEmpty) {
      throw const FormatException('알레르기 원인을 입력해야 합니다.');
    }

    final response = await apiClient.dio.post(
      '/patients/$patientId/allergies/',
      data: {
        'allergen_type': allergenType.trim().toUpperCase(),
        'allergen_name': normalizedName,
        'reaction': normalizedReaction,
        'severity': severity.trim().toUpperCase(),
        'status': status.trim().toUpperCase(),
      },
    );

    if (response.data is! Map) {
      throw const FormatException('알레르기 등록 응답 형식이 올바르지 않습니다.');
    }

    return PatientAllergy.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<PatientMedicalHistory> createMedicalHistory({
    required int patientId,
    required String conditionName,
    String conditionCode = '',
    DateTime? onsetDate,
    DateTime? resolvedDate,
    String status = 'ACTIVE',
    String note = '',
  }) async {
    final normalizedName = conditionName.trim();

    if (normalizedName.isEmpty) {
      throw const FormatException('질환명을 입력해야 합니다.');
    }

    final response = await apiClient.dio.post(
      '/patients/$patientId/medical-histories/',
      data: {
        'condition_code': conditionCode.trim(),
        'condition_name': normalizedName,
        'onset_date': onsetDate == null ? null : _formatDate(onsetDate),
        'resolved_date': resolvedDate == null
            ? null
            : _formatDate(resolvedDate),
        'status': status.trim().toUpperCase(),
        'note': note.trim(),
      },
    );

    if (response.data is! Map) {
      throw const FormatException('과거력 등록 응답 형식이 올바르지 않습니다.');
    }

    return PatientMedicalHistory.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<PatientVitalSign>> fetchVitalSigns(int encounterId) async {
    final response = await apiClient.dio.get(
      '/encounters/$encounterId/vital-signs/',
    );

    final responseData = response.data;

    if (responseData is! List) {
      throw const FormatException('활력징후 응답 형식이 올바르지 않습니다.');
    }

    return responseData.map((item) {
      if (item is! Map) {
        throw const FormatException('활력징후 항목 형식이 올바르지 않습니다.');
      }

      return PatientVitalSign.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  Future<PatientVitalSign> createVitalSign({
    required int encounterId,
    required int systolicBp,
    required int diastolicBp,
    required int pulseRate,
    required int respiratoryRate,
    required double bodyTemperature,
    required double oxygenSaturation,
    double? heightCm,
    double? weightKg,
  }) async {
    final response = await apiClient.dio.post(
      '/encounters/$encounterId/vital-signs/',
      data: {
        'systolic_bp': systolicBp,
        'diastolic_bp': diastolicBp,
        'pulse_rate': pulseRate,
        'respiratory_rate': respiratoryRate,
        'body_temperature': bodyTemperature,
        'oxygen_saturation': oxygenSaturation,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'measured_at': DateTime.now().toUtc().toIso8601String(),
      },
    );

    if (response.data is! Map) {
      throw const FormatException('활력징후 등록 응답 형식이 올바르지 않습니다.');
    }

    return PatientVitalSign.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<PatientEncounterNote>> fetchNotes(int encounterId) async {
    final response = await apiClient.dio.get('/encounters/$encounterId/notes/');

    final responseData = response.data;

    if (responseData is! List) {
      throw const FormatException('진료기록 응답 형식이 올바르지 않습니다.');
    }

    return responseData.map((item) {
      if (item is! Map) {
        throw const FormatException('진료기록 항목 형식이 올바르지 않습니다.');
      }

      return PatientEncounterNote.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  Future<PatientEncounterNote> createNote({
    required int encounterId,
    required String noteText,
    String noteType = 'HISTORY',
  }) async {
    final normalizedText = noteText.trim();

    if (normalizedText.isEmpty) {
      throw const FormatException('진료기록 내용을 입력해야 합니다.');
    }

    final response = await apiClient.dio.post(
      '/encounters/$encounterId/notes/',
      data: {'note_type': noteType, 'note_text': normalizedText},
    );

    if (response.data is! Map) {
      throw const FormatException('진료기록 등록 응답 형식이 올바르지 않습니다.');
    }

    return PatientEncounterNote.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<PatientEncounterNote> updateNote({
    required int noteId,
    required String noteText,
  }) async {
    final normalizedText = noteText.trim();

    if (normalizedText.isEmpty) {
      throw const FormatException('진료기록 내용을 입력해야 합니다.');
    }

    final response = await apiClient.dio.patch(
      '/encounter-notes/$noteId/',
      data: {'note_text': normalizedText, 'status': 'DRAFT'},
    );

    if (response.data is! Map) {
      throw const FormatException('진료기록 수정 응답 형식이 올바르지 않습니다.');
    }

    return PatientEncounterNote.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<PatientEncounterNote> confirmNote(int noteId) async {
    final response = await apiClient.dio.post(
      '/encounter-notes/$noteId/confirm/',
    );

    if (response.data is! Map) {
      throw const FormatException('진료기록 확정 응답 형식이 올바르지 않습니다.');
    }

    return PatientEncounterNote.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Map<String, dynamic>> startEncounter({
    required int encounterId,
  }) async {
    final response = await apiClient.dio.post(
      '/encounters/$encounterId/start/',
    );

    if (response.data is! Map) {
      throw const FormatException('진료 시작 응답 형식이 올바르지 않습니다.');
    }

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> completeEncounter({
    required int encounterId,
    required String outcome,
  }) async {
    final normalizedOutcome = outcome.trim();

    if (normalizedOutcome.isEmpty) {
      throw const FormatException('진료 결과를 입력해야 합니다.');
    }

    final response = await apiClient.dio.post(
      '/encounters/$encounterId/complete/',
      data: {'outcome': normalizedOutcome},
    );

    if (response.data is! Map) {
      throw const FormatException('진료 완료 응답 형식이 올바르지 않습니다.');
    }

    return Map<String, dynamic>.from(response.data as Map);
  }

  String _formatDate(DateTime value) {
    final year = value.year.toString();
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
