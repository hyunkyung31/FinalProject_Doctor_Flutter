import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/access_control.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';

import 'examination_ui_models.dart';
import 'widgets/examination_order_panel.dart';
import 'widgets/examination_progress_panel.dart';
import 'widgets/examination_result_panel.dart';
import 'widgets/examination_section_tabs.dart';

// ============================================================
// STEP 1. Examinations Page
// ============================================================

class ExaminationsPage extends StatefulWidget {
  const ExaminationsPage({super.key});

  @override
  State<ExaminationsPage> createState() => _ExaminationsPageState();
}

class _ExaminationsPageState extends State<ExaminationsPage> {
  ExaminationSection _selectedSection = ExaminationSection.orders;

  late List<ExaminationOrderUiModel> _orders;
  late List<ExaminationExecutionUiModel> _examinations;

  late List<ExaminationResultUiModel> _results;

  // ============================================================
  // STEP 2. Reference Data
  // ============================================================

  static const List<ExaminationTypeUiModel> _types = [
    ExaminationTypeUiModel(
      id: 4,
      code: 'ANGIO_2D',
      name: '2D 관상동맥 혈관조영술',
      category: 'IMAGING',
      modality: 'XA',
      description: '혈관조영 검사',
      isActive: true,
    ),
    ExaminationTypeUiModel(
      id: 2,
      code: 'CCTA',
      name: '관상동맥 CT 혈관조영술',
      category: 'IMAGING',
      modality: 'CT',
      description: '관상동맥 CCTA 검사',
      isActive: true,
    ),
    ExaminationTypeUiModel(
      id: 6,
      code: 'CCTA_3D',
      name: '관상동맥 CT 혈관조영술',
      category: 'IMAGING',
      modality: 'CT',
      description: '3D 시연 검사',
      isActive: true,
    ),
    ExaminationTypeUiModel(
      id: 3,
      code: 'ANGIOGRAPHY',
      name: '관상동맥조영술',
      category: 'PROCEDURE',
      modality: 'XA',
      description: '관상동맥 혈관조영술 검사',
      isActive: true,
    ),
    ExaminationTypeUiModel(
      id: 5,
      code: 'CARDIAC_LAB_PANEL',
      name: '심혈관 혈액·임상 패널',
      category: 'LAB',
      modality: null,
      description: '심혈관 혈액·임상 패널',
      isActive: true,
    ),
    ExaminationTypeUiModel(
      id: 1,
      code: 'BLOOD',
      name: '혈액검사',
      category: 'LAB',
      modality: null,
      description: '심혈관 관련 혈액검사',
      isActive: true,
    ),
  ];

  // ============================================================
  // STEP 3. Mock Patient
  // Patient API 연결 전 UI 확인용
  // ============================================================

  static const List<ExaminationPatientUiModel> _patients = [
    ExaminationPatientUiModel(id: 1629, name: '김OO', age: 68, gender: '남'),
    ExaminationPatientUiModel(id: 1628, name: '박OO', age: 59, gender: '여'),
    ExaminationPatientUiModel(id: 1627, name: '이OO', age: 65, gender: '남'),
    ExaminationPatientUiModel(id: 1626, name: '최OO', age: 71, gender: '남'),
  ];

  // ============================================================
  // STEP 4. Encounter
  // ============================================================

  static final List<ExaminationEncounterUiModel> _encounters = [
    ExaminationEncounterUiModel(
      id: 1213,
      encounterType: 'INITIAL',
      visitDate: DateTime(2026, 8, 31, 14, 41),
      status: 'COMPLETED',
      outcome: '진료 완료',
      reservationId: null,
      patientId: 1629,
      doctorId: 6,
    ),
    ExaminationEncounterUiModel(
      id: 1212,
      encounterType: 'INITIAL',
      visitDate: DateTime(2026, 8, 31, 14, 41),
      status: 'COMPLETED',
      outcome: '진료 완료',
      reservationId: null,
      patientId: 1628,
      doctorId: 5,
    ),
    ExaminationEncounterUiModel(
      id: 1211,
      encounterType: 'INITIAL',
      visitDate: DateTime(2026, 8, 31, 14, 41),
      status: 'COMPLETED',
      outcome: '진료 완료',
      reservationId: null,
      patientId: 1627,
      doctorId: 4,
    ),
    ExaminationEncounterUiModel(
      id: 1210,
      encounterType: 'INITIAL',
      visitDate: DateTime(2026, 8, 31, 14, 41),
      status: 'COMPLETED',
      outcome: '진료 완료',
      reservationId: null,
      patientId: 1626,
      doctorId: 3,
    ),
  ];

  // ============================================================
  // STEP 5. Init
  // ============================================================

  @override
  void initState() {
    super.initState();

    _orders = _buildOrders();
    _examinations = _buildExaminations();
    _results = _buildResults();
  }

  // ============================================================
  // STEP 6. Role UI
  //
  // 현재 단계:
  // - 의사 : 오더 / 결과확정 UI
  // - 간호사 : 검사 수행 UI
  //
  // 실제 API 연결 시 Backend Permission을 최종 기준으로 변경
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final isDoctor = auth.role == UserRole.doctor;

    final isNurse = auth.role == UserRole.nurse;

    return AppShell(
      pageTitle: '검사',
      selectedIndex: 3,
      body: Material(
        color: AppColors.background,
        child: Container(
          color: AppColors.background,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // Section Tabs
              // ==================================================
              ExaminationSectionTabs(
                selectedSection: _selectedSection,
                onChanged: (section) {
                  setState(() {
                    _selectedSection = section;
                  });
                },
              ),

              const SizedBox(height: 10),

              // ==================================================
              // Content
              // ==================================================
              Expanded(
                child: _buildSection(isDoctor: isDoctor, isNurse: isNurse),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP 7. Selected Section
  // ============================================================

  Widget _buildSection({required bool isDoctor, required bool isNurse}) {
    switch (_selectedSection) {
      case ExaminationSection.orders:
        return ExaminationOrderPanel(
          orders: _orders,
          types: _types,
          encounters: _encounters,
          patients: _patients,

          canOrder: isDoctor,

          onCreateOrder: () {
            _showMessage('검사 오더 등록 Dialog는 다음 단계에서 연결합니다.');
          },

          onSchedule: (order) {
            _scheduleOrder(order);
          },

          onCancel: (order) {
            _cancelOrder(order);
          },
        );

      case ExaminationSection.progress:
        return ExaminationProgressPanel(
          examinations: _examinations,
          orders: _orders,
          types: _types,
          encounters: _encounters,
          patients: _patients,

          canPerform: isNurse,
          canEditProcedureNursing: isNurse,

          onStart: _startExamination,
          onComplete: _completeExamination,
          onFail: _failExamination,
        );

      case ExaminationSection.results:
        return ExaminationResultPanel(
          results: _results,
          examinations: _examinations,
          orders: _orders,
          types: _types,
          encounters: _encounters,
          patients: _patients,

          canFinalize: isDoctor,

          onFinalize: _finalizeResult,
        );
    }
  }

  // ============================================================
  // STEP 8. Mock Order Action
  // ============================================================

  void _scheduleOrder(ExaminationOrderUiModel order) {
    final index = _orders.indexWhere((item) => item.id == order.id);

    if (index < 0) {
      return;
    }

    setState(() {
      _orders[index] = order.copyWith(
        scheduledAt: DateTime(2026, 9, 15, 10, 0),
        scheduledLocation: '검사실',
      );
    });

    _showMessage('검사 일정이 UI에 반영되었습니다. 실제 API는 아직 연결하지 않았습니다.');
  }

  void _cancelOrder(ExaminationOrderUiModel order) {
    final index = _orders.indexWhere((item) => item.id == order.id);

    if (index < 0) {
      return;
    }

    setState(() {
      _orders[index] = order.copyWith(
        status: 'CANCELED',
        canceledAt: DateTime.now(),
        cancelReason: 'UI 테스트 취소',
      );
    });

    _showMessage('검사 오더가 UI에서 취소 처리되었습니다.');
  }

  // ============================================================
  // STEP 9. Mock Examination Action
  // ============================================================

  void _startExamination(ExaminationExecutionUiModel examination) {
    _updateExamination(examination.copyWith(status: 'IN_PROGRESS'));

    _showMessage('검사를 시작했습니다.');
  }

  void _completeExamination(ExaminationExecutionUiModel examination) {
    _updateExamination(
      examination.copyWith(status: 'COMPLETED', performedAt: DateTime.now()),
    );

    _showMessage('검사가 완료 처리되었습니다.');
  }

  void _failExamination(ExaminationExecutionUiModel examination) {
    _updateExamination(examination.copyWith(status: 'FAILED'));

    _showMessage('검사가 실패 상태로 변경되었습니다.');
  }

  void _updateExamination(ExaminationExecutionUiModel updated) {
    final index = _examinations.indexWhere((item) => item.id == updated.id);

    if (index < 0) {
      return;
    }

    setState(() {
      _examinations[index] = updated;
    });
  }

  // ============================================================
  // STEP 10. Mock Finalize
  // ============================================================

  void _finalizeResult(ExaminationResultUiModel result) {
    final index = _results.indexWhere((item) => item.id == result.id);

    if (index < 0) {
      return;
    }

    setState(() {
      _results[index] = result.copyWith(
        status: 'FINAL',
        confirmedAt: DateTime.now(),
        confirmedBy: 3,
      );
    });

    _showMessage('검사 결과가 최종 확정되었습니다.');
  }

  // ============================================================
  // STEP 11. Message
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  // ============================================================
  // STEP 12. Mock Orders
  // ============================================================

  List<ExaminationOrderUiModel> _buildOrders() {
    return [
      ExaminationOrderUiModel(
        id: 1409,
        priority: 'NORMAL',
        clinicalNote: '관상동맥조영술 시행',
        status: 'ORDERED',
        orderedAt: DateTime(2026, 9, 13, 8, 40),
        scheduledAt: DateTime(2026, 9, 13, 9, 0),
        scheduledLocation: '혈관조영실',
        canceledAt: null,
        cancelReason: null,
        encounterId: 1210,
        examinationTypeId: 3,
        orderedBy: 3,
        canceledBy: null,
      ),

      ExaminationOrderUiModel(
        id: 1415,
        priority: 'NORMAL',
        clinicalNote: '환자',
        status: 'ORDERED',
        orderedAt: DateTime(2026, 9, 11, 16, 50),
        scheduledAt: null,
        scheduledLocation: null,
        canceledAt: null,
        cancelReason: null,
        encounterId: 1213,
        examinationTypeId: 4,
        orderedBy: 3,
        canceledBy: null,
      ),

      ExaminationOrderUiModel(
        id: 1414,
        priority: 'NORMAL',
        clinicalNote: null,
        status: 'CANCELED',
        orderedAt: DateTime(2026, 9, 11, 16, 12),
        scheduledAt: null,
        scheduledLocation: null,
        canceledAt: DateTime(2026, 9, 11, 16, 42),
        cancelReason: '오입력',
        encounterId: 1213,
        examinationTypeId: 2,
        orderedBy: 3,
        canceledBy: 6,
      ),

      ExaminationOrderUiModel(
        id: 1413,
        priority: 'NORMAL',
        clinicalNote: '심혈관 혈액·임상 패널',
        status: 'COMPLETED',
        orderedAt: DateTime(2026, 8, 31, 14, 58),
        scheduledAt: DateTime(2026, 8, 31, 14, 41),
        scheduledLocation: '진단검사의학과',
        canceledAt: null,
        cancelReason: null,
        encounterId: 1213,
        examinationTypeId: 5,
        orderedBy: 6,
        canceledBy: null,
      ),

      ExaminationOrderUiModel(
        id: 1412,
        priority: 'NORMAL',
        clinicalNote: 'CCTA 검사',
        status: 'COMPLETED',
        orderedAt: DateTime(2026, 8, 31, 14, 58),
        scheduledAt: DateTime(2026, 8, 31, 14, 41),
        scheduledLocation: 'CT 촬영실',
        canceledAt: null,
        cancelReason: null,
        encounterId: 1213,
        examinationTypeId: 6,
        orderedBy: 6,
        canceledBy: null,
      ),

      ExaminationOrderUiModel(
        id: 1411,
        priority: 'NORMAL',
        clinicalNote: '혈액 패널 추적',
        status: 'COMPLETED',
        orderedAt: DateTime(2026, 8, 31, 14, 58),
        scheduledAt: DateTime(2026, 8, 31, 15, 10),
        scheduledLocation: '진단검사의학과',
        canceledAt: null,
        cancelReason: null,
        encounterId: 1212,
        examinationTypeId: 1,
        orderedBy: 5,
        canceledBy: null,
      ),

      ExaminationOrderUiModel(
        id: 1410,
        priority: 'NORMAL',
        clinicalNote: 'CCTA 검사',
        status: 'ORDERED',
        orderedAt: DateTime(2026, 9, 12, 9, 30),
        scheduledAt: DateTime(2026, 9, 13, 11, 0),
        scheduledLocation: 'CT 촬영실',
        canceledAt: null,
        cancelReason: null,
        encounterId: 1211,
        examinationTypeId: 2,
        orderedBy: 4,
        canceledBy: null,
      ),
    ];
  }

  // ============================================================
  // STEP 13. Mock Examination
  // ============================================================

  List<ExaminationExecutionUiModel> _buildExaminations() {
    return [
      ExaminationExecutionUiModel(
        id: 2005,
        attemptNo: 1,
        performedAt: null,
        location: '혈관조영실',
        status: 'IN_PROGRESS',
        createdAt: DateTime(2026, 9, 13, 9, 0),
        orderId: 1409,
      ),

      ExaminationExecutionUiModel(
        id: 2001,
        attemptNo: 1,
        performedAt: null,
        location: '혈관조영실',
        status: 'READY',
        createdAt: DateTime(2026, 9, 12, 8, 30),
        orderId: 1415,
      ),

      ExaminationExecutionUiModel(
        id: 2002,
        attemptNo: 1,
        performedAt: null,
        location: 'CT 촬영실',
        status: 'IN_PROGRESS',
        createdAt: DateTime(2026, 9, 12, 9, 10),
        orderId: 1410,
      ),

      ExaminationExecutionUiModel(
        id: 2003,
        attemptNo: 1,
        performedAt: DateTime(2026, 8, 31, 15, 0),
        location: '진단검사의학과',
        status: 'COMPLETED',
        createdAt: DateTime(2026, 8, 31, 14, 45),
        orderId: 1413,
      ),

      ExaminationExecutionUiModel(
        id: 2004,
        attemptNo: 1,
        performedAt: DateTime(2026, 8, 31, 15, 20),
        location: '진단검사의학과',
        status: 'COMPLETED',
        createdAt: DateTime(2026, 8, 31, 15, 10),
        orderId: 1411,
      ),
    ];
  }

  // ============================================================
  // STEP 14. Mock Results
  // ============================================================

  List<ExaminationResultUiModel> _buildResults() {
    return [
      ExaminationResultUiModel(
        id: 4,
        resultType: 'LAB_PANEL',
        version: 1,
        collectedAt: DateTime(2026, 8, 31, 15, 1),
        status: 'FINAL',
        createdAt: DateTime(2026, 8, 31, 15, 1),
        summaryText: null,
        confirmedAt: DateTime(2026, 8, 31, 15, 2),
        examinationId: 2003,
        confirmedBy: 1,
        measurements: _mockMeasurements(),
      ),

      ExaminationResultUiModel(
        id: 5,
        resultType: 'LAB_PANEL',
        version: 1,
        collectedAt: DateTime(2026, 8, 31, 15, 21),
        status: 'VALIDATED',
        createdAt: DateTime(2026, 8, 31, 15, 21),
        summaryText: '검증 완료 후 최종 확정 대기',
        confirmedAt: null,
        examinationId: 2004,
        confirmedBy: null,
        measurements: _mockMeasurements().take(6).toList(),
      ),
    ];
  }

  // ============================================================
  // STEP 15. Measurements
  // 실제 응답의 값/단위 구조를 축약 적용
  // ============================================================

  List<ExaminationMeasurementUiModel> _mockMeasurements() {
    final now = DateTime(2026, 8, 31, 15, 1);

    return [
      ExaminationMeasurementUiModel(
        id: 46,
        valueNumeric: '78.000000',
        valueText: null,
        valueBoolean: null,
        unit: 'mg/dL',
        abnormalFlag: null,
        measuredAt: now,
        validationStatus: 'VALID',
        validationMessage: null,
        clinicalVariableId: 1,
      ),
      ExaminationMeasurementUiModel(
        id: 47,
        valueNumeric: '1.200000',
        valueText: null,
        valueBoolean: null,
        unit: 'mg/dL',
        abnormalFlag: null,
        measuredAt: now,
        validationStatus: 'VALID',
        validationMessage: null,
        clinicalVariableId: 2,
      ),
      ExaminationMeasurementUiModel(
        id: 48,
        valueNumeric: '63.000000',
        valueText: null,
        valueBoolean: null,
        unit: 'mg/dL',
        abnormalFlag: null,
        measuredAt: now,
        validationStatus: 'VALID',
        validationMessage: null,
        clinicalVariableId: 3,
      ),
      ExaminationMeasurementUiModel(
        id: 49,
        valueNumeric: '55.000000',
        valueText: null,
        valueBoolean: null,
        unit: 'mg/dL',
        abnormalFlag: null,
        measuredAt: now,
        validationStatus: 'VALID',
        validationMessage: null,
        clinicalVariableId: 4,
      ),
      ExaminationMeasurementUiModel(
        id: 50,
        valueNumeric: '27.000000',
        valueText: null,
        valueBoolean: null,
        unit: 'mg/dL',
        abnormalFlag: null,
        measuredAt: now,
        validationStatus: 'VALID',
        validationMessage: null,
        clinicalVariableId: 5,
      ),
      ExaminationMeasurementUiModel(
        id: 51,
        valueNumeric: '30.000000',
        valueText: null,
        valueBoolean: null,
        unit: 'mg/dL',
        abnormalFlag: null,
        measuredAt: now,
        validationStatus: 'VALID',
        validationMessage: null,
        clinicalVariableId: 6,
      ),
      ExaminationMeasurementUiModel(
        id: 52,
        valueNumeric: '76.000000',
        valueText: null,
        valueBoolean: null,
        unit: 'mm/hr',
        abnormalFlag: null,
        measuredAt: now,
        validationStatus: 'VALID',
        validationMessage: null,
        clinicalVariableId: 7,
      ),
      ExaminationMeasurementUiModel(
        id: 53,
        valueNumeric: '12.100000',
        valueText: null,
        valueBoolean: null,
        unit: 'g/dL',
        abnormalFlag: null,
        measuredAt: now,
        validationStatus: 'VALID',
        validationMessage: null,
        clinicalVariableId: 8,
      ),
    ];
  }
}
