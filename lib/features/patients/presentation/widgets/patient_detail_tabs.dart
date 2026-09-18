import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/theme/app_theme.dart';

// ============================================================
// LAB. 환자 검사 측정값 Model
// integrated-data의 lab_measurements 기준
// ============================================================

class PatientLabMeasurement {
  final int? measurementId;
  final int? clinicalVariableId;

  final String code;
  final String name;
  final String displayName;

  final String value;
  final String unit;

  final int? referenceRangeId;
  final double? referenceMin;
  final double? referenceMax;
  final String referenceText;

  final String abnormalFlag;
  final String validationStatus;

  final DateTime? measuredAt;

  const PatientLabMeasurement({
    required this.measurementId,
    required this.clinicalVariableId,
    required this.code,
    required this.name,
    required this.displayName,
    required this.value,
    required this.unit,
    required this.referenceRangeId,
    required this.referenceMin,
    required this.referenceMax,
    required this.referenceText,
    required this.abnormalFlag,
    required this.validationStatus,
    required this.measuredAt,
  });

  factory PatientLabMeasurement.fromJson(Map<String, dynamic> json) {
    return PatientLabMeasurement(
      measurementId: _parseInt(json['measurement_id'] ?? json['id']),
      clinicalVariableId: _parseInt(json['clinical_variable_id']),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      displayName:
          json['display_name']?.toString() ?? json['name']?.toString() ?? '',
      value: _parseValue(json),
      unit: json['unit']?.toString() ?? '',
      referenceRangeId: _parseInt(json['reference_range_id']),
      referenceMin: _parseDouble(json['reference_min']),
      referenceMax: _parseDouble(json['reference_max']),
      referenceText: json['reference_text']?.toString() ?? '',
      abnormalFlag: json['abnormal_flag']?.toString().toUpperCase() ?? '',
      validationStatus:
          json['validation_status']?.toString().toUpperCase() ?? '',
      measuredAt: DateTime.tryParse(json['measured_at']?.toString() ?? ''),
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

  static String _parseValue(Map<String, dynamic> json) {
    final value =
        json['value'] ??
        json['value_numeric'] ??
        json['value_text'] ??
        json['value_boolean'];

    return value?.toString() ?? '-';
  }

  String get displayValue {
    if (unit.isEmpty) {
      return value;
    }

    return '$value $unit';
  }

  bool get isAbnormal {
    return abnormalFlag == 'HIGH' || abnormalFlag == 'LOW';
  }

  bool get isHigh => abnormalFlag == 'HIGH';

  bool get isLow => abnormalFlag == 'LOW';

  bool get isNormal => abnormalFlag == 'NORMAL';
}

// ============================================================
// TIMELINE. 환자 진료이력 Model
// GET /patients/{patientId}/timeline
// ============================================================

class PatientTimelineItem {
  final String eventType;
  final int referenceId;
  final DateTime? occurredAt;
  final String title;
  final String status;
  final String summary;
  final Map<String, dynamic> data;

  const PatientTimelineItem({
    required this.eventType,
    required this.referenceId,
    required this.occurredAt,
    required this.title,
    required this.status,
    required this.summary,
    required this.data,
  });

  factory PatientTimelineItem.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];

    return PatientTimelineItem(
      eventType: json['event_type']?.toString() ?? '',
      referenceId: (json['reference_id'] as num?)?.toInt() ?? 0,
      occurredAt: DateTime.tryParse(json['occurred_at']?.toString() ?? ''),
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      data: rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : <String, dynamic>{},
    );
  }
}

// ============================================================
// STEP 1. 환자 UI Model
// 실제 Patient API + 기존 UI 호환
// ============================================================

class PatientUiModel {
  // ==========================================================
  // Backend 실제 Patient 기본 정보
  // ==========================================================

  final int patientId;
  final String medicalRecordNo;

  final String name;
  final String birthDate;
  final String gender;
  final String phone;
  final String status;

  final DateTime? registeredAt;

  // ==========================================================
  // Integrated Data
  // ==========================================================

  final String department;
  final String doctorName;

  final List<PatientLabMeasurement> labMeasurements;

  final int labMeasurementCount;
  final int ctStudyCount;
  final int angiographySequenceCount;

  // ==========================================================
  // 아직 실제 API가 확인되지 않은 UI 정보
  // ==========================================================

  final String careType;
  final bool highRisk;
  final bool aiPending;
  final String currentTask;

  final String primaryDiagnosis;
  final String riskFactors;
  final String allergy;

  final String latestExam;
  final String latestExamDate;

  final String aiSummary;
  final String nextAppointment;

  const PatientUiModel({
    required this.patientId,
    required this.medicalRecordNo,
    required this.name,
    required this.birthDate,
    required this.gender,
    required this.phone,
    required this.status,
    required this.registeredAt,
    this.department = '진료과 정보 없음',
    this.doctorName = '담당 의료진 정보 없음',
    this.labMeasurements = const [],
    this.labMeasurementCount = 0,
    this.ctStudyCount = 0,
    this.angiographySequenceCount = 0,
    this.careType = '미확인',
    this.highRisk = false,
    this.aiPending = false,
    this.currentTask = '현재 업무 정보 없음',
    this.primaryDiagnosis = '진단 정보 없음',
    this.riskFactors = '위험 요인 정보 없음',
    this.allergy = '알레르기 정보 없음',
    this.latestExam = '검사 정보 없음',
    this.latestExamDate = '-',
    this.aiSummary = 'AI 분석 정보 없음',
    this.nextAppointment = '예정된 일정 정보 없음',
  });

  // ==========================================================
  // Patient List JSON → PatientUiModel
  // GET /api/patients/
  // ==========================================================

  factory PatientUiModel.fromJson(Map<String, dynamic> json) {
    return PatientUiModel(
      patientId: (json['id'] as num).toInt(),
      medicalRecordNo: json['medical_record_no']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      birthDate: json['birth_date']?.toString() ?? '',
      gender: _parseGender(json['gender']?.toString()),
      phone: json['contact']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      registeredAt: _parseNullableDateTime(json['registered_at']),
    );
  }

  // ==========================================================
  // 화면 표시용 기존 id 호환
  // ==========================================================

  String get id => medicalRecordNo;

  // ==========================================================
  // 나이 계산
  // ==========================================================

  int get age {
    final parsedBirthDate = DateTime.tryParse(birthDate);

    if (parsedBirthDate == null) {
      return 0;
    }

    final now = DateTime.now();

    var result = now.year - parsedBirthDate.year;

    final birthdayPassed =
        now.month > parsedBirthDate.month ||
        (now.month == parsedBirthDate.month && now.day >= parsedBirthDate.day);

    if (!birthdayPassed) {
      result -= 1;
    }

    return result;
  }

  // ==========================================================
  // Gender 변환
  // ==========================================================

  static String _parseGender(String? value) {
    switch (value?.toUpperCase()) {
      case 'M':
      case 'MALE':
        return '남';

      case 'F':
      case 'FEMALE':
        return '여';

      default:
        return '미상';
    }
  }

  // ==========================================================
  // Nullable DateTime
  // ==========================================================

  static DateTime? _parseNullableDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  // ==========================================================
  // Integrated Data 적용
  // ==========================================================

  PatientUiModel copyWithIntegratedData({
    String? department,
    String? doctorName,
    List<PatientLabMeasurement>? labMeasurements,
    int? labMeasurementCount,
    int? ctStudyCount,
    int? angiographySequenceCount,
  }) {
    return PatientUiModel(
      patientId: patientId,
      medicalRecordNo: medicalRecordNo,
      name: name,
      birthDate: birthDate,
      gender: gender,
      phone: phone,
      status: status,
      registeredAt: registeredAt,
      department: department ?? this.department,
      doctorName: doctorName ?? this.doctorName,
      labMeasurements: labMeasurements ?? this.labMeasurements,
      labMeasurementCount: labMeasurementCount ?? this.labMeasurementCount,
      ctStudyCount: ctStudyCount ?? this.ctStudyCount,
      angiographySequenceCount:
          angiographySequenceCount ?? this.angiographySequenceCount,
      careType: careType,
      highRisk: highRisk,
      aiPending: aiPending,
      currentTask: currentTask,
      primaryDiagnosis: primaryDiagnosis,
      riskFactors: riskFactors,
      allergy: allergy,
      latestExam: latestExam,
      latestExamDate: latestExamDate,
      aiSummary: aiSummary,
      nextAppointment: nextAppointment,
    );
  }
}

// ============================================================
// STEP 2. Patient Detail Tab
// ============================================================

enum PatientDetailTab {
  overview,
  care,
  examinations,
  prescriptions,
  aiCdss,
  results,
}

// ============================================================
// STEP 3. Patient Detail Tabs
// ============================================================

class PatientDetailTabs extends StatelessWidget {
  final PatientDetailTab selectedTab;
  final ValueChanged<PatientDetailTab> onChanged;

  const PatientDetailTabs({
    super.key,
    required this.selectedTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,

      // ========================================================
      // Light / Dark Theme 대응
      // ========================================================
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(
          top: BorderSide(color: context.appBorder),
          bottom: BorderSide(color: context.appBorder),
        ),
      ),

      child: Row(
        children: [
          Expanded(
            child: _PatientTabButton(
              label: '개요',
              tab: PatientDetailTab.overview,
              selectedTab: selectedTab,
              onChanged: onChanged,
            ),
          ),

          Expanded(
            child: _PatientTabButton(
              label: '진료',
              tab: PatientDetailTab.care,
              selectedTab: selectedTab,
              onChanged: onChanged,
            ),
          ),

          Expanded(
            child: _PatientTabButton(
              label: 'AI 분석',
              tab: PatientDetailTab.aiCdss,
              selectedTab: selectedTab,
              onChanged: onChanged,
            ),
          ),

          Expanded(
            child: _PatientTabButton(
              label: '결과',
              tab: PatientDetailTab.results,
              selectedTab: selectedTab,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 4. Patient Tab Button
// ============================================================

class _PatientTabButton extends StatelessWidget {
  final String label;
  final PatientDetailTab tab;
  final PatientDetailTab selectedTab;
  final ValueChanged<PatientDetailTab> onChanged;

  const _PatientTabButton({
    required this.label,
    required this.tab,
    required this.selectedTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedTab == tab;

    return Material(
      // ========================================================
      // 선택 탭은 기존 CardioAI Blue 유지
      // 비선택 탭은 현재 Theme Surface 사용
      // ========================================================
      color: selected ? AppColors.primaryBlue : context.appSurface,

      child: InkWell(
        onTap: () {
          onChanged(tab);
        },

        child: Container(
          height: 44,
          alignment: Alignment.center,

          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: context.appBorder,
                width: tab == PatientDetailTab.results ? 0 : 1,
              ),
            ),
          ),

          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,

              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,

              color: selected ? Colors.white : context.appTextSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
