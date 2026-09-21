import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../core/widgets/app_shell.dart';

import 'consultation_ui_models.dart';
import 'widgets/consultation_detail_panel.dart';
import 'widgets/consultation_form_dialog.dart';
import 'widgets/consultation_list_panel.dart';

// ============================================================
// STEP 1. Consultation Page
// ============================================================

class ConsultationPage extends StatefulWidget {
  const ConsultationPage({super.key});

  @override
  State<ConsultationPage> createState() => _ConsultationPageState();
}

class _ConsultationPageState extends State<ConsultationPage> {
  late List<ConsultationUiModel> _consultations;

  int? _selectedId;
  bool _showCompactDetail = false;

  // 실제 Auth 연결 전 UI DEMO 기준
  static const int _demoCurrentDoctorId = 4;
  static const String _demoCurrentDoctorName = '이서준';
  static const String _demoCurrentDepartment = '순환기내과';

  // ============================================================
  // STEP 2. Init
  // ============================================================

  @override
  void initState() {
    super.initState();

    _consultations = _buildMockConsultations();

    if (_consultations.isNotEmpty) {
      _selectedId = _consultations.first.id;
    }
  }

  ConsultationUiModel? get _selected {
    for (final consultation in _consultations) {
      if (consultation.id == _selectedId) {
        return consultation;
      }
    }

    return null;
  }

  // ============================================================
  // STEP 3. Create
  // POST /api/consultations/
  // ============================================================

  Future<void> _openCreateDialog() async {
    final result = await showConsultationFormDialog(context: context);

    if (result == null || !mounted) {
      return;
    }

    final consultation = ConsultationUiModel(
      id: DateTime.now().millisecondsSinceEpoch,
      patientId: result.patientId,
      patientName: result.patientName,
      patientMeta: '환자 정보 연결 대기',
      subject: result.subject,
      note: result.note,
      assignedDoctorId: result.assignedDoctorId,
      assignedDoctorName: result.assignedDoctorName,
      assignedDepartment: '진료과 미연결',
      encounterId: result.encounterId,
      priority: result.priority,
      dueAt: result.dueAt,
      status: ConsultationUiStatus.requested,
      direction: ConsultationUiDirection.sent,
      createdAt: DateTime.now(),
      participants: [
        const ConsultationParticipantUiModel(
          id: 1,
          doctorId: _demoCurrentDoctorId,
          doctorName: _demoCurrentDoctorName,
          department: _demoCurrentDepartment,
          roleLabel: '요청 의료진',
          title: '순환기내과 전문의',
        ),
        ConsultationParticipantUiModel(
          id: 2,
          doctorId: result.assignedDoctorId,
          doctorName: result.assignedDoctorName,
          department: '진료과 미연결',
          roleLabel: '담당 의료진',
        ),
      ],
      references: const [],
      opinions: const [],
    );

    setState(() {
      _consultations = [consultation, ..._consultations];
      _selectedId = consultation.id;
      _showCompactDetail = true;
    });

    _showMessage('협진 요청이 UI에 생성되었습니다. 실제 POST API는 아직 연결하지 않았습니다.');
  }

  // ============================================================
  // STEP 4. Status Actions
  // ============================================================

  void _accept() {
    _updateStatus(ConsultationUiStatus.inProgress);
    _showMessage('협진을 UI에서 수락 처리했습니다.');
  }

  void _complete() {
    _updateStatus(ConsultationUiStatus.completed);
    _showMessage('협진을 UI에서 완료 처리했습니다.');
  }

  void _withdraw() {
    _updateStatus(ConsultationUiStatus.withdrawn);
    _showMessage('협진 요청을 UI에서 회수 처리했습니다.');
  }

  void _updateStatus(ConsultationUiStatus status) {
    final selected = _selected;

    if (selected == null) {
      return;
    }

    _replaceConsultation(selected.copyWith(status: status));
  }

  // ============================================================
  // STEP 5. Opinion
  // POST /api/consultations/{consultation_id}/opinions/
  // ============================================================

  void _addOpinion(ConsultationOpinionUiModel opinion) {
    final selected = _selected;

    if (selected == null) {
      return;
    }

    _replaceConsultation(
      selected.copyWith(opinions: [...selected.opinions, opinion]),
    );
  }

  void _replaceConsultation(ConsultationUiModel updated) {
    final index = _consultations.indexWhere((item) => item.id == updated.id);

    if (index < 0) {
      return;
    }

    setState(() {
      _consultations[index] = updated;
    });
  }

  // ============================================================
  // STEP 6. Responsive UI
  //
  // Landscape Tablet:
  // Case Rail + Consult Cockpit
  //
  // Portrait / Narrow:
  // List -> Cockpit
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // AppShell 내부 body 영역에서 LayoutBuilder가 0/비정상 제약을 받는
    // 환경을 피하기 위해 화면 크기는 MediaQuery로만 판단합니다.
    // 실제 본문 배치는 기존에 정상 동작하던 Container + Row 구조를 유지합니다.
    final screenSize = MediaQuery.sizeOf(context);
    final orientation = MediaQuery.orientationOf(context);
    final useSplitView =
        orientation == Orientation.landscape && screenSize.width >= 900;

    final horizontalPadding = screenSize.width < 700 ? 10.0 : 16.0;
    final verticalPadding = screenSize.width < 700 ? 10.0 : 8.0;

    return AppShell(
      pageTitle: '협진',
      selectedIndex: 6,
      body: Material(
        color: context.appBackground,
        child: Container(
          width: double.infinity,
          color: context.appBackground,
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            verticalPadding,
            horizontalPadding,
            16,
          ),
          child: useSplitView
              ? _buildSplitView(screenSize.width)
              : _buildCompactView(),
        ),
      ),
    );
  }

  Widget _buildSplitView(double width) {
    final selected = _selected;
    final railWidth = width >= 1250 ? 270.0 : 238.0;

    return Row(
      children: [
        SizedBox(
          width: railWidth,
          child: ConsultationListPanel(
            consultations: _consultations,
            selectedId: _selectedId,
            onSelected: (consultation) {
              setState(() {
                _selectedId = consultation.id;
              });
            },
            onCreate: _openCreateDialog,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: selected == null
              ? const _EmptyDetail()
              : _buildDetailPanel(
                  consultation: selected,
                  showBackButton: false,
                ),
        ),
      ],
    );
  }

  Widget _buildCompactView() {
    final selected = _selected;

    if (_showCompactDetail && selected != null) {
      return _buildDetailPanel(consultation: selected, showBackButton: true);
    }

    return ConsultationListPanel(
      consultations: _consultations,
      selectedId: _selectedId,
      onSelected: (consultation) {
        setState(() {
          _selectedId = consultation.id;
          _showCompactDetail = true;
        });
      },
      onCreate: _openCreateDialog,
    );
  }

  Widget _buildDetailPanel({
    required ConsultationUiModel consultation,
    required bool showBackButton,
  }) {
    return ConsultationDetailPanel(
      key: ValueKey(consultation.id),
      consultation: consultation,
      showBackButton: showBackButton,
      onBack: showBackButton
          ? () {
              setState(() {
                _showCompactDetail = false;
              });
            }
          : null,
      onAccept: _accept,
      onComplete: _complete,
      onWithdraw: _withdraw,
      onOpinionAdded: _addOpinion,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  // ============================================================
  // STEP 7. Mock / API-shaped Data
  //
  // 첫 번째 환자는 사용자가 확인한 실제 API 응답 구조/값을 기준으로 구성.
  //
  // Consultation
  // - consultation id 1
  // - patient 1626
  // - requester 이서준 doctor_id 4
  // - assigned 김도윤 doctor_id 3
  //
  // Follow-up
  // - encounter 1503
  // - CCTA examination 1668
  //
  // AI
  // - analysis 468
  // - result 16
  // ============================================================

  List<ConsultationUiModel> _buildMockConsultations() {
    return [
      ConsultationUiModel(
        id: 1,
        patientId: 1626,
        patientName: '한지호',
        patientMeta: 'MRN DEMO-0097',
        subject: '1차 추적검사 CCTA 결과 협진 요청',
        note:
            '1차 추적검사에서 관상동맥 CT 혈관조영술(CCTA_3D)이 완료되었습니다. SIGNIFICANT_LESION 환자의 추적관찰 결과에 대해 추가적인 협진 의견을 요청합니다.',
        assignedDoctorId: 3,
        assignedDoctorName: '김도윤',
        assignedDepartment: '순환기내과',
        encounterId: null,
        priority: 'NORMAL',
        dueAt: DateTime(2026, 9, 20, 3, 2, 20),
        status: ConsultationUiStatus.requested,
        direction: ConsultationUiDirection.sent,
        createdAt: DateTime(2026, 9, 20, 3, 13, 25),
        participants: const [
          ConsultationParticipantUiModel(
            id: 1,
            doctorId: 4,
            doctorName: '이서준',
            department: '순환기내과',
            roleLabel: '요청 의료진',
            title: '순환기내과 전문의',
          ),
          ConsultationParticipantUiModel(
            id: 2,
            doctorId: 3,
            doctorName: '김도윤',
            department: '순환기내과',
            roleLabel: '협진 의료진',
            title: '순환기내과 과장',
          ),
        ],
        references: const [],
        opinions: const [],
        followUp: ConsultationFollowUpUiModel(
          medicalRecordNo: 'DEMO-0097',
          stageLabel: '1차 추적검사',
          encounterId: 1503,
          visitDate: DateTime(2026, 9, 5),
          doctorName: '김도윤',
          doctorDepartment: '순환기내과',
          cctaExaminationId: 1668,
          cctaPerformedAt: DateTime(2026, 9, 8),
          cctaLocation: 'CT 촬영실',
          cctaResultStatus: 'FINAL',
          clinicalMetrics: const [
            ConsultationClinicalMetricUiModel(
              label: 'EF-TTE',
              value: '42.6',
              unit: '%',
              flag: 'LOW',
            ),
            ConsultationClinicalMetricUiModel(
              label: 'LDL',
              value: '152.23',
              unit: 'mg/dL',
              flag: 'HIGH',
            ),
            ConsultationClinicalMetricUiModel(
              label: 'HDL',
              value: '34.4',
              unit: 'mg/dL',
              flag: 'LOW',
            ),
            ConsultationClinicalMetricUiModel(
              label: 'Creatinine',
              value: '1.511',
              unit: 'mg/dL',
              flag: 'HIGH',
            ),
          ],
        ),
        aiSummary: const ConsultationAiSummaryUiModel(
          analysisId: 468,
          resultId: 16,
          analysisType: 'ANGIO_2D',
          resultStatus: 'REVIEW_REQUIRED',
          leftSignificantPositive: true,
          leftSignificantScore: 0.8518154183272847,
          rightSignificantPositive: true,
          rightSignificantScore: 0.9736131977550838,
          seriesCount: 11,
          frameCount: 458,
          warning: '외부 테스트 결과입니다. AI score는 협착률·보정된 신뢰도가 아닙니다.',
        ),
        isDemo: false,
      ),

      ConsultationUiModel(
        id: 102,
        patientId: 1630,
        patientName: '이OO',
        patientMeta: '65세 · 남',
        subject: '관상동맥조영술 결과 협진 요청',
        note: '관상동맥조영술에서 다혈관 병변이 의심됩니다. 추가 치료 방향에 대한 의견을 요청합니다.',
        assignedDoctorId: 4,
        assignedDoctorName: '이서준',
        assignedDepartment: '순환기내과',
        encounterId: 1214,
        priority: 'URGENT',
        dueAt: DateTime(2026, 9, 20, 18),
        status: ConsultationUiStatus.inProgress,
        direction: ConsultationUiDirection.received,
        createdAt: DateTime(2026, 9, 20, 11, 40),
        participants: const [
          ConsultationParticipantUiModel(
            id: 3,
            doctorId: 8,
            doctorName: '최OO 의사',
            department: '심장혈관흉부외과',
            roleLabel: '요청 의료진',
          ),
          ConsultationParticipantUiModel(
            id: 4,
            doctorId: 4,
            doctorName: '이서준',
            department: '순환기내과',
            roleLabel: '협진 의료진',
          ),
        ],
        references: const [
          ConsultationReferenceUiModel(
            id: 5,
            referenceTypeLabel: '영상',
            referenceId: 1011,
            title: 'CAG Study #1011',
            description: '관상동맥조영술 영상 · UI DEMO',
          ),
        ],
        opinions: [
          ConsultationOpinionUiModel(
            id: 11,
            doctorId: 8,
            doctorName: '최OO 의사',
            department: '심장혈관흉부외과',
            opinionText: '영상상 다혈관 병변 가능성이 있어 임상 상태와 함께 추가 평가가 필요합니다.',
            isFinal: false,
            createdAt: DateTime(2026, 9, 20, 12, 20),
          ),
        ],
        isDemo: true,
      ),

      ConsultationUiModel(
        id: 103,
        patientId: 1620,
        patientName: '정OO',
        patientMeta: '59세 · 여',
        subject: '심혈관 위험도 종합 검토',
        note: '혈액검사와 영상 결과를 종합하여 추적 검사 계획에 대한 협진을 요청했습니다.',
        assignedDoctorId: 4,
        assignedDoctorName: '이서준',
        assignedDepartment: '순환기내과',
        encounterId: 1201,
        priority: 'NORMAL',
        dueAt: DateTime(2026, 9, 19, 18),
        status: ConsultationUiStatus.completed,
        direction: ConsultationUiDirection.received,
        createdAt: DateTime(2026, 9, 18, 9, 15),
        participants: const [
          ConsultationParticipantUiModel(
            id: 5,
            doctorId: 6,
            doctorName: '한OO 의사',
            department: '가정의학과',
            roleLabel: '요청 의료진',
          ),
          ConsultationParticipantUiModel(
            id: 6,
            doctorId: 4,
            doctorName: '이서준',
            department: '순환기내과',
            roleLabel: '협진 의료진',
          ),
        ],
        references: const [],
        opinions: [
          ConsultationOpinionUiModel(
            id: 20,
            doctorId: 4,
            doctorName: '이서준',
            department: '순환기내과',
            opinionText: '현재 검사 결과를 기준으로 추적 관찰 및 위험인자 조절을 권고합니다.',
            isFinal: true,
            createdAt: DateTime(2026, 9, 19, 10, 20),
          ),
        ],
        isDemo: true,
      ),
    ];
  }
}

// ============================================================
// STEP 8. Empty Detail
// ============================================================

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Center(
        child: Text(
          '협진 항목을 선택해 주세요.',
          style: TextStyle(fontSize: 11, color: context.appTextSecondary),
        ),
      ),
    );
  }
}
