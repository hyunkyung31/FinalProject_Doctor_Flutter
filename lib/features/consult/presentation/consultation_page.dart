import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
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

  // ============================================================
  // STEP 3. Selected
  // ============================================================

  ConsultationUiModel? get _selected {
    for (final consultation in _consultations) {
      if (consultation.id == _selectedId) {
        return consultation;
      }
    }

    return null;
  }

  // ============================================================
  // STEP 4. Create
  // ============================================================

  Future<void> _openCreateDialog() async {
    final result = await showConsultationFormDialog(context: context);

    if (result == null) {
      return;
    }

    final consultation = ConsultationUiModel(
      id: DateTime.now().millisecondsSinceEpoch,
      patientId: result.patientId,
      patientName: result.patientName,
      patientMeta: '환자 정보 UI DEMO',
      subject: result.subject,
      note: result.note,
      assignedDoctorId: result.assignedDoctorId,
      assignedDoctorName: result.assignedDoctorName,
      assignedDepartment: '진료과 미연결',
      encounterId: result.encounterId,
      priority: result.priority,
      dueAt: result.dueAt,
      status: ConsultationUiStatus.requested,
      createdAt: DateTime.now(),
      participants: [
        ConsultationParticipantUiModel(
          id: 1,
          doctorId: result.assignedDoctorId,
          doctorName: result.assignedDoctorName,
          department: '진료과 미연결',
          roleLabel: '담당 의료진',
        ),
      ],
      references: [],
      opinions: [],
    );

    setState(() {
      _consultations = [consultation, ..._consultations];

      _selectedId = consultation.id;
    });

    _showMessage('협진 요청이 UI에 생성되었습니다. 실제 POST API는 아직 연결하지 않았습니다.');
  }

  // ============================================================
  // STEP 5. Status Action
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

    _showMessage('협진 요청을 UI에서 철회 처리했습니다.');
  }

  void _updateStatus(ConsultationUiStatus status) {
    final selected = _selected;

    if (selected == null) {
      return;
    }

    final index = _consultations.indexWhere((item) => item.id == selected.id);

    if (index < 0) {
      return;
    }

    setState(() {
      _consultations[index] = selected.copyWith(status: status);
    });
  }

  // ============================================================
  // STEP 6. UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final selected = _selected;

    return AppShell(
      pageTitle: '협진',
      selectedIndex: 6,
      body: Material(
        color: AppColors.background,
        child: Container(
          color: AppColors.background,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Row(
            children: [
              Expanded(
                flex: 4,
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

              const SizedBox(width: 14),

              Expanded(
                flex: 6,
                child: selected == null
                    ? const _EmptyDetail()
                    : ConsultationDetailPanel(
                        key: ValueKey(selected.id),
                        consultation: selected,
                        onAccept: _accept,
                        onComplete: _complete,
                        onWithdraw: _withdraw,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP 7. Message
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  // ============================================================
  // STEP 8. Mock Data
  //
  // 실제 GET /api/consultations/ 는 현재 Backend 500.
  // 따라서 아래 데이터는 전부 UI DEMO.
  // ============================================================

  List<ConsultationUiModel> _buildMockConsultations() {
    return [
      ConsultationUiModel(
        id: 101,
        patientId: 1629,
        patientName: '김OO',
        patientMeta: '68세 · 남',
        subject: 'CCTA 및 LAD 협착 소견 협진',
        note: 'CCTA 및 2D 혈관조영 AI 결과에서 LAD 근위부 병변이 확인되어 심장혈관흉부외과 의견을 요청합니다.',
        assignedDoctorId: 7,
        assignedDoctorName: '박OO 의사',
        assignedDepartment: '심장혈관흉부외과',
        encounterId: 1213,
        priority: 'NORMAL',
        dueAt: DateTime(2026, 9, 15, 18),
        status: ConsultationUiStatus.inProgress,
        createdAt: DateTime(2026, 9, 13, 11, 20),
        participants: [
          ConsultationParticipantUiModel(
            id: 1,
            doctorId: 1,
            doctorName: '김OO 의사',
            department: '순환기내과',
            roleLabel: '요청 의료진',
          ),
          ConsultationParticipantUiModel(
            id: 2,
            doctorId: 7,
            doctorName: '박OO 의사',
            department: '심장혈관흉부외과',
            roleLabel: '담당 의료진',
          ),
        ],
        references: [
          ConsultationReferenceUiModel(
            id: 1,
            referenceTypeLabel: '영상',
            referenceId: 1007,
            title: 'CCTA Study #1007',
            description: '관상동맥 CT 혈관조영술 영상',
          ),
          ConsultationReferenceUiModel(
            id: 2,
            referenceTypeLabel: 'AI',
            referenceId: 101,
            title: '2D 혈관조영 AI 결과',
            description: 'LAD 근위부 협착 의심 · UI DEMO',
          ),
        ],
        opinions: [
          ConsultationOpinionUiModel(
            id: 1,
            doctorId: 7,
            doctorName: '박OO 의사',
            department: '심장혈관흉부외과',
            opinionText: '영상과 임상 상태를 함께 검토 중입니다. 추가 평가 후 최종 의견을 남기겠습니다.',
            isFinal: false,
            createdAt: DateTime(2026, 9, 13, 13, 10),
          ),
        ],
      ),

      ConsultationUiModel(
        id: 102,
        patientId: 1630,
        patientName: '이OO',
        patientMeta: '65세 · 남',
        subject: '관상동맥조영술 결과 협진 요청',
        note: '혈관조영술 결과에 대한 추가 의견을 요청합니다.',
        assignedDoctorId: 8,
        assignedDoctorName: '최OO 의사',
        assignedDepartment: '심장혈관흉부외과',
        encounterId: 1214,
        priority: 'NORMAL',
        dueAt: DateTime(2026, 9, 16, 18),
        status: ConsultationUiStatus.requested,
        createdAt: DateTime(2026, 9, 13, 14, 30),
        participants: const [
          ConsultationParticipantUiModel(
            id: 3,
            doctorId: 8,
            doctorName: '최OO 의사',
            department: '심장혈관흉부외과',
            roleLabel: '담당 의료진',
          ),
        ],
        references: const [],
        opinions: const [],
      ),

      ConsultationUiModel(
        id: 103,
        patientId: 1620,
        patientName: '정OO',
        patientMeta: '59세 · 여',
        subject: '심혈관 위험도 종합 검토',
        note: '혈액검사와 영상 결과를 종합하여 추적 검사 계획에 대한 협진을 요청했습니다.',
        assignedDoctorId: 6,
        assignedDoctorName: '한OO 의사',
        assignedDepartment: '순환기내과',
        encounterId: 1201,
        priority: 'NORMAL',
        dueAt: DateTime(2026, 9, 12, 18),
        status: ConsultationUiStatus.completed,
        createdAt: DateTime(2026, 9, 10, 9, 15),
        participants: const [
          ConsultationParticipantUiModel(
            id: 4,
            doctorId: 6,
            doctorName: '한OO 의사',
            department: '순환기내과',
            roleLabel: '협진 의료진',
          ),
        ],
        references: const [],
        opinions: [
          ConsultationOpinionUiModel(
            id: 2,
            doctorId: 6,
            doctorName: '한OO 의사',
            department: '순환기내과',
            opinionText: '현재 검사 결과를 기준으로 추적 관찰 및 추가 평가를 권고합니다.',
            isFinal: true,
            createdAt: DateTime(2026, 9, 12, 10, 20),
          ),
        ],
      ),
    ];
  }
}

// ============================================================
// STEP 9. Empty Detail
// ============================================================

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Text(
          '협진 항목을 선택해 주세요.',
          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
