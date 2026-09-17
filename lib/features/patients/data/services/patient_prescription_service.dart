import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';

class PatientPrescriptionSummary {
  final int id;
  final int encounterId;
  final int patientId;
  final int prescribedBy;
  final String status;
  final String notes;

  final DateTime? prescribedAt;
  final DateTime? signedAt;
  final DateTime? canceledAt;

  const PatientPrescriptionSummary({
    required this.id,
    required this.encounterId,
    required this.patientId,
    required this.prescribedBy,
    required this.status,
    required this.notes,
    required this.prescribedAt,
    required this.signedAt,
    required this.canceledAt,
  });

  factory PatientPrescriptionSummary.fromJson(Map<String, dynamic> json) {
    return PatientPrescriptionSummary(
      id: _parseInt(json['id']) ?? 0,
      encounterId: _parseInt(json['encounter']) ?? 0,
      patientId: _parseInt(json['patient']) ?? 0,
      prescribedBy: _parseInt(json['prescribed_by']) ?? 0,
      status: json['status']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      prescribedAt: DateTime.tryParse(json['prescribed_at']?.toString() ?? ''),
      signedAt: DateTime.tryParse(json['signed_at']?.toString() ?? ''),
      canceledAt: DateTime.tryParse(json['canceled_at']?.toString() ?? ''),
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

class PrescriptionMedication {
  final int id;
  final String code;
  final String name;
  final String ingredient;
  final String defaultUnit;
  final String manufacturer;

  const PrescriptionMedication({
    required this.id,
    required this.code,
    required this.name,
    required this.ingredient,
    required this.defaultUnit,
    required this.manufacturer,
  });

  factory PrescriptionMedication.fromJson(Map<String, dynamic> json) {
    return PrescriptionMedication(
      id: _parseInt(json['id']) ?? 0,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      ingredient: json['ingredient']?.toString() ?? '',
      defaultUnit: json['default_unit']?.toString() ?? '',
      manufacturer: json['manufacturer']?.toString() ?? '',
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

class PatientPrescriptionItem {
  final int id;
  final int prescriptionId;
  final int medicationId;

  final PrescriptionMedication medication;

  final String status;
  final String doseValue;
  final String doseUnit;

  final int? frequencyPerDay;
  final int? durationDays;

  final String route;
  final String instructions;
  final String note;

  const PatientPrescriptionItem({
    required this.id,
    required this.prescriptionId,
    required this.medicationId,
    required this.medication,
    required this.status,
    required this.doseValue,
    required this.doseUnit,
    required this.frequencyPerDay,
    required this.durationDays,
    required this.route,
    required this.instructions,
    required this.note,
  });

  factory PatientPrescriptionItem.fromJson(Map<String, dynamic> json) {
    final medicationData = json['medication_detail'];

    return PatientPrescriptionItem(
      id: _parseInt(json['id']) ?? 0,
      prescriptionId: _parseInt(json['prescription']) ?? 0,
      medicationId: _parseInt(json['medication']) ?? 0,
      medication: medicationData is Map
          ? PrescriptionMedication.fromJson(
              Map<String, dynamic>.from(medicationData),
            )
          : const PrescriptionMedication(
              id: 0,
              code: '',
              name: '',
              ingredient: '',
              defaultUnit: '',
              manufacturer: '',
            ),
      status: json['status']?.toString() ?? '',
      doseValue: json['dose_value']?.toString() ?? '',
      doseUnit: json['dose_unit']?.toString() ?? '',
      frequencyPerDay: _parseInt(json['frequency_per_day']),
      durationDays: _parseInt(json['duration_days']),
      route: json['route']?.toString() ?? '',
      instructions: json['instructions']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
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

class PatientPrescriptionDurCheck {
  final int id;
  final int prescriptionId;
  final String status;
  final DateTime? checkedAt;

  const PatientPrescriptionDurCheck({
    required this.id,
    required this.prescriptionId,
    required this.status,
    required this.checkedAt,
  });

  factory PatientPrescriptionDurCheck.fromJson(Map<String, dynamic> json) {
    return PatientPrescriptionDurCheck(
      id: _parseInt(json['id']) ?? 0,
      prescriptionId: _parseInt(json['prescription']) ?? 0,
      status: json['status']?.toString() ?? '',
      checkedAt: DateTime.tryParse(json['checked_at']?.toString() ?? ''),
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

class PatientPrescriptionDetail {
  final PatientPrescriptionSummary prescription;
  final List<PatientPrescriptionItem> items;
  final List<PatientPrescriptionDurCheck> durChecks;

  const PatientPrescriptionDetail({
    required this.prescription,
    required this.items,
    required this.durChecks,
  });

  factory PatientPrescriptionDetail.fromJson(Map<String, dynamic> json) {
    final prescriptionData = json['prescription'];

    if (prescriptionData is! Map) {
      throw const FormatException('처방 상세 prescription 형식이 올바르지 않습니다.');
    }

    final itemsData = json['items'];
    final durChecksData = json['dur_checks'];

    final items = itemsData is List
        ? itemsData
              .whereType<Map>()
              .map(
                (item) => PatientPrescriptionItem.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <PatientPrescriptionItem>[];

    final durChecks = durChecksData is List
        ? durChecksData
              .whereType<Map>()
              .map(
                (item) => PatientPrescriptionDurCheck.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <PatientPrescriptionDurCheck>[];

    return PatientPrescriptionDetail(
      prescription: PatientPrescriptionSummary.fromJson(
        Map<String, dynamic>.from(prescriptionData),
      ),
      items: items,
      durChecks: durChecks,
    );
  }
}

class PrescriptionReauthSession {
  final String token;
  final int expiresInSeconds;

  const PrescriptionReauthSession({
    required this.token,
    required this.expiresInSeconds,
  });
}

class PrescriptionSignatureUploadRequest {
  final String objectKey;
  final String uploadUrl;
  final Map<String, String> requiredHeaders;

  const PrescriptionSignatureUploadRequest({
    required this.objectKey,
    required this.uploadUrl,
    required this.requiredHeaders,
  });

  factory PrescriptionSignatureUploadRequest.fromJson(
    Map<String, dynamic> json,
  ) {
    final headersData = json['required_headers'];

    if (headersData is! Map) {
      throw const FormatException('서명 파일 업로드 헤더 형식이 올바르지 않습니다.');
    }

    final requiredHeaders = <String, String>{};

    for (final entry in headersData.entries) {
      requiredHeaders[entry.key.toString()] = entry.value.toString();
    }

    final objectKey = json['object_key']?.toString() ?? '';
    final uploadUrl = json['upload_url']?.toString() ?? '';

    if (objectKey.isEmpty || uploadUrl.isEmpty) {
      throw const FormatException('서명 파일 업로드 정보가 올바르지 않습니다.');
    }

    return PrescriptionSignatureUploadRequest(
      objectKey: objectKey,
      uploadUrl: uploadUrl,
      requiredHeaders: requiredHeaders,
    );
  }
}

class PatientPrescriptionService {
  final ApiClient apiClient;

  PatientPrescriptionService({required this.apiClient});

  Future<PatientPrescriptionSummary> createPrescription({
    required int encounterId,
    required int patientId,
    String notes = '',
  }) async {
    final response = await apiClient.dio.post(
      '/encounters/$encounterId/prescriptions/',
      data: {'patient_id': patientId, 'notes': notes.trim()},
    );

    if (response.data is! Map) {
      throw const FormatException('처방 등록 응답 형식이 올바르지 않습니다.');
    }

    return PatientPrescriptionSummary.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<PatientPrescriptionSummary>> fetchPrescriptions(
    int patientId,
  ) async {
    final response = await apiClient.dio.get(
      '/prescriptions/',
      queryParameters: {'patient_id': patientId},
    );

    final responseData = response.data;

    if (responseData is! List) {
      throw const FormatException('처방 목록 응답 형식이 올바르지 않습니다.');
    }

    final prescriptions = responseData.map((item) {
      if (item is! Map) {
        throw const FormatException('처방 목록 항목 형식이 올바르지 않습니다.');
      }

      return PatientPrescriptionSummary.fromJson(
        Map<String, dynamic>.from(item),
      );
    }).toList();

    prescriptions.sort((a, b) {
      final aDate = a.prescribedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.prescribedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return bDate.compareTo(aDate);
    });

    return prescriptions;
  }

  Future<PatientPrescriptionDetail> fetchPrescriptionDetail(
    int prescriptionId,
  ) async {
    final response = await apiClient.dio.get('/prescriptions/$prescriptionId/');

    if (response.data is! Map) {
      throw const FormatException('처방 상세 응답 형식이 올바르지 않습니다.');
    }

    return PatientPrescriptionDetail.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<PrescriptionMedication>> searchMedications(String query) async {
    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      return [];
    }

    final response = await apiClient.dio.get(
      '/medications/',
      queryParameters: {'search': normalizedQuery},
    );

    final responseData = response.data;

    if (responseData is! List) {
      throw const FormatException('약품 검색 응답 형식이 올바르지 않습니다.');
    }

    return responseData.map((item) {
      if (item is! Map) {
        throw const FormatException('약품 검색 항목 형식이 올바르지 않습니다.');
      }

      return PrescriptionMedication.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  Future<PatientPrescriptionDurCheck> runDurCheck(int prescriptionId) async {
    final response = await apiClient.dio.post(
      '/prescriptions/$prescriptionId/dur-check/',
    );

    if (response.data is! Map) {
      throw const FormatException('DUR 검사 응답 형식이 올바르지 않습니다.');
    }

    final responseData = Map<String, dynamic>.from(response.data as Map);

    final durCheckData = responseData['dur_check'];

    if (durCheckData is! Map) {
      throw const FormatException('DUR 검사 결과 형식이 올바르지 않습니다.');
    }

    return PatientPrescriptionDurCheck.fromJson(
      Map<String, dynamic>.from(durCheckData),
    );
  }

  Future<PatientPrescriptionItem> createPrescriptionItem({
    required int prescriptionId,
    required int medicationId,
    required double doseValue,
    required String doseUnit,
    required int frequencyPerDay,
    required int durationDays,
    required String route,
    required String instructions,
    String note = '',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (doseValue <= 0) {
      throw const FormatException('투여 용량은 0보다 커야 합니다.');
    }

    if (frequencyPerDay <= 0) {
      throw const FormatException('1일 복용 횟수는 1회 이상이어야 합니다.');
    }

    if (durationDays <= 0) {
      throw const FormatException('복용 기간은 1일 이상이어야 합니다.');
    }

    final response = await apiClient.dio.post(
      '/prescriptions/$prescriptionId/items/',
      data: {
        'medication_id': medicationId,
        'dose': doseValue.toString(),
        'dose_value': doseValue.toString(),
        'dose_unit': doseUnit.trim(),
        'frequency': frequencyPerDay,
        'frequency_per_day': frequencyPerDay,
        'duration': durationDays,
        'duration_days': durationDays,
        'route': route.trim().toUpperCase(),
        'instructions': instructions.trim(),
        'note': note.trim(),
        'start_date': startDate == null ? null : _formatDate(startDate),
        'end_date': endDate == null ? null : _formatDate(endDate),
      },
    );

    if (response.data is! Map) {
      throw const FormatException('처방 약물 등록 응답 형식이 올바르지 않습니다.');
    }

    return PatientPrescriptionItem.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<PrescriptionReauthSession> reauthenticateForSignature(
    String credential,
  ) async {
    final password = credential.trim();

    if (password.isEmpty) {
      throw const FormatException('비밀번호를 입력해 주세요.');
    }

    final response = await apiClient.dio.post(
      '/staff/reauthenticate/',
      data: {'auth_method': 'PASSWORD', 'credential': password},
    );

    if (response.data is! Map) {
      throw const FormatException('재인증 응답 형식이 올바르지 않습니다.');
    }

    final responseData = Map<String, dynamic>.from(response.data as Map);

    final reauthenticated = responseData['reauthenticated'] == true;

    final reauthToken = responseData['reauth_token']?.toString() ?? '';

    final expiresIn = _parseFileId(responseData['expires_in']) ?? 0;

    if (!reauthenticated || reauthToken.isEmpty || expiresIn <= 0) {
      throw const FormatException('직원 재인증에 실패했습니다.');
    }

    return PrescriptionReauthSession(
      token: reauthToken,
      expiresInSeconds: expiresIn,
    );
  }

  Future<PrescriptionSignatureUploadRequest> requestSignatureUpload({
    required String mimeType,
    required String checksum,
    required int size,
  }) async {
    final response = await apiClient.dio.post(
      '/files/upload-requests/',
      data: {'mime_type': mimeType, 'size': size, 'checksum': checksum},
    );

    if (response.data is! Map) {
      throw const FormatException('서명 파일 업로드 요청 응답 형식이 올바르지 않습니다.');
    }

    return PrescriptionSignatureUploadRequest.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> uploadSignatureBytes({
    required PrescriptionSignatureUploadRequest uploadRequest,
    required Uint8List bytes,
  }) async {
    if (bytes.isEmpty) {
      throw const FormatException('서명 이미지가 비어 있습니다.');
    }

    final uploadDio = Dio();

    await uploadDio.put(
      uploadRequest.uploadUrl,
      data: bytes,
      options: Options(
        headers: Map<String, dynamic>.from(uploadRequest.requiredHeaders),
        responseType: ResponseType.plain,
        validateStatus: (status) {
          return status != null && status >= 200 && status < 300;
        },
      ),
    );
  }

  Future<int> completeSignatureUpload({
    required String objectKey,
    required String checksum,
    required int size,
  }) async {
    final response = await apiClient.dio.post(
      '/files/upload-complete/',
      data: {'object_key': objectKey, 'checksum': checksum, 'size': size},
    );

    if (response.data is! Map) {
      throw const FormatException('서명 파일 업로드 완료 응답 형식이 올바르지 않습니다.');
    }

    final responseData = Map<String, dynamic>.from(response.data as Map);

    final fileId = _parseFileId(responseData['id']);

    if (fileId == null || fileId <= 0) {
      throw const FormatException('서명 파일 ID를 확인할 수 없습니다.');
    }

    return fileId;
  }

  Future<PatientPrescriptionDetail> signPrescription({
    required int prescriptionId,
    required int signatureFileId,
    required String reauthToken,
  }) async {
    final response = await apiClient.dio.post(
      '/prescriptions/$prescriptionId/sign/',
      data: {'signature_file_id': signatureFileId, 'reauth_token': reauthToken},
    );

    if (response.data is! Map) {
      throw const FormatException('처방 서명 응답 형식이 올바르지 않습니다.');
    }

    return PatientPrescriptionDetail.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<PatientPrescriptionDetail> signPrescriptionWithSignature({
    required int prescriptionId,
    required String reauthToken,
    required Uint8List signatureBytes,
  }) async {
    if (signatureBytes.isEmpty) {
      throw const FormatException('서명을 작성해 주세요.');
    }

    if (reauthToken.trim().isEmpty) {
      throw const FormatException('재인증 정보가 없습니다.');
    }

    final checksum = sha256.convert(signatureBytes).toString();

    final uploadRequest = await requestSignatureUpload(
      mimeType: 'image/png',
      checksum: checksum,
      size: signatureBytes.length,
    );

    await uploadSignatureBytes(
      uploadRequest: uploadRequest,
      bytes: signatureBytes,
    );

    final signatureFileId = await completeSignatureUpload(
      objectKey: uploadRequest.objectKey,
      checksum: checksum,
      size: signatureBytes.length,
    );

    return signPrescription(
      prescriptionId: prescriptionId,
      signatureFileId: signatureFileId,
      reauthToken: reauthToken,
    );
  }

  int? _parseFileId(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }

  String _formatDate(DateTime value) {
    final year = value.year.toString();
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
