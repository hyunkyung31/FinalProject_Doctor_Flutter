import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/widgets/app_shell.dart';

import '../data/services/consultation_service.dart';
import 'consultation_ui_models.dart';
import 'widgets/consultation_detail_panel.dart';
import 'widgets/consultation_form_dialog.dart';
import 'widgets/consultation_list_panel.dart';

// ============================================================
// STEP 1. Consultation Page
// 실제 Backend /consultations API 연결
// ============================================================

class ConsultationPage extends StatefulWidget {
  const ConsultationPage({super.key});

  @override
  State<ConsultationPage> createState() => _ConsultationPageState();
}

class _ConsultationPageState extends State<ConsultationPage> {
  List<ConsultationUiModel> _consultations = [];

  ConsultationService? _consultationService;

  int? _selectedId;
  bool _showCompactDetail = false;

  bool _isLoading = true;
  bool _isDetailLoading = false;

  String? _loadError;

  // ============================================================
  // STEP 2. Auth / Service 초기화
  // ============================================================

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_consultationService != null) {
      return;
    }

    final auth = context.read<AuthProvider>();

    _consultationService = ConsultationService(
      apiClient: auth.authService.apiClient,
    );

    _loadConsultations();
  }

  int? get _currentDoctorId {
    return context.read<AuthProvider>().currentUser?.doctorId;
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
  // STEP 3. 협진 목록 조회
  // GET /consultations/
  // ============================================================

  Future<void> _loadConsultations({int? preferredSelectedId}) async {
    final service = _consultationService;

    if (service == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final currentDoctorId = _currentDoctorId;

      if (currentDoctorId == null) {
        throw StateError('현재 로그인 의사의 doctor_id를 확인할 수 없습니다.');
      }

      final apiItems = await service.fetchConsultations();

      final patientIds = apiItems
          .map((item) => item.patientId)
          .toSet()
          .toList();

      final patientMap = await _loadPatientSummaries(patientIds);

      final uiItems = apiItems.map((item) {
        return _mapListItemToUi(
          item,
          patient: patientMap[item.patientId],
          currentDoctorId: currentDoctorId,
        );
      }).toList();

      uiItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) {
        return;
      }

      int? nextSelectedId = preferredSelectedId;

      if (nextSelectedId == null ||
          !uiItems.any((item) => item.id == nextSelectedId)) {
        nextSelectedId = uiItems.isEmpty ? null : uiItems.first.id;
      }

      setState(() {
        _consultations = uiItems;
        _selectedId = nextSelectedId;
        _isLoading = false;
        _loadError = null;
      });

      debugPrint(
        '[CONSULT] 협진 목록 조회 완료: '
        '${uiItems.length}건',
      );

      if (nextSelectedId != null) {
        await _loadConsultationDetail(nextSelectedId);
      }
    } catch (error) {
      debugPrint('[CONSULT] 협진 목록 조회 실패: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  // ============================================================
  // STEP 4. Patient 요약 조회
  // GET /patients/{patientId}/
  // ============================================================

  Future<Map<int, _ConsultationPatientSummary>> _loadPatientSummaries(
    List<int> patientIds,
  ) async {
    final auth = context.read<AuthProvider>();

    final entries = await Future.wait(
      patientIds.map((patientId) async {
        try {
          final response = await auth.authService.apiClient.dio.get(
            ApiEndpoints.patientDetail(patientId),
          );

          if (response.data is! Map) {
            return MapEntry(
              patientId,
              _ConsultationPatientSummary(
                patientId: patientId,
                name: '환자 #$patientId',
                medicalRecordNo: '-',
              ),
            );
          }

          final data = Map<String, dynamic>.from(response.data as Map);

          return MapEntry(
            patientId,
            _ConsultationPatientSummary(
              patientId: patientId,
              name: data['name']?.toString().trim().isNotEmpty == true
                  ? data['name'].toString()
                  : '환자 #$patientId',
              medicalRecordNo: data['medical_record_no']?.toString() ?? '-',
            ),
          );
        } catch (error) {
          debugPrint(
            '[CONSULT] 환자 조회 실패: '
            'patientId=$patientId, '
            'error=$error',
          );

          return MapEntry(
            patientId,
            _ConsultationPatientSummary(
              patientId: patientId,
              name: '환자 #$patientId',
              medicalRecordNo: '-',
            ),
          );
        }
      }),
    );

    return Map<int, _ConsultationPatientSummary>.fromEntries(entries);
  }

  // ============================================================
  // STEP 5. 협진 상세 조회
  // GET /consultations/{id}/
  // ============================================================

  Future<void> _loadConsultationDetail(int consultationId) async {
    final service = _consultationService;

    if (service == null) {
      return;
    }

    setState(() {
      _isDetailLoading = true;
    });

    try {
      final detail = await service.fetchConsultationDetail(consultationId);

      final patientMap = await _loadPatientSummaries([
        detail.consultation.patientId,
      ]);

      final currentDoctorId = _currentDoctorId;

      if (currentDoctorId == null) {
        throw StateError('현재 로그인 의사의 doctor_id를 확인할 수 없습니다.');
      }

      final uiModel = _mapDetailToUi(
        detail,
        patient: patientMap[detail.consultation.patientId],
        currentDoctorId: currentDoctorId,
      );

      if (!mounted) {
        return;
      }

      _replaceConsultation(uiModel);

      setState(() {
        _isDetailLoading = false;
      });

      debugPrint(
        '[CONSULT] 협진 상세 조회 완료: '
        'id=$consultationId',
      );
    } catch (error) {
      debugPrint(
        '[CONSULT] 협진 상세 조회 실패: '
        'id=$consultationId, '
        'error=$error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isDetailLoading = false;
      });

      _showMessage('협진 상세 정보를 불러오지 못했습니다.');
    }
  }

  // ============================================================
  // STEP 6. 협진 요청 생성
  // POST /consultations/
  // ============================================================

  Future<void> _openCreateDialog() async {
    final result = await showConsultationFormDialog(context: context);

    if (result == null || !mounted) {
      return;
    }

    final service = _consultationService;

    if (service == null) {
      return;
    }

    try {
      final created = await service.createConsultation(
        patientId: result.patientId,
        subject: result.subject,
        note: result.note,
        assignedDoctorId: result.assignedDoctorId,
        encounterId: result.encounterId,
        priority: result.priority,
        dueAt: result.dueAt,
      );

      final createdId = created.consultation.id;

      await _loadConsultations(preferredSelectedId: createdId);

      if (!mounted) {
        return;
      }

      setState(() {
        _showCompactDetail = true;
      });

      _showMessage('협진 요청이 등록되었습니다.');
    } catch (error) {
      debugPrint('[CONSULT] 협진 요청 실패: $error');

      if (!mounted) {
        return;
      }

      _showMessage('협진 요청을 등록하지 못했습니다.');
    }
  }

  // ============================================================
  // STEP 7. 협진 수락
  // POST /consultations/{id}/accept/
  // ============================================================

  Future<void> _accept() async {
    final selected = _selected;
    final service = _consultationService;

    if (selected == null || service == null) {
      return;
    }

    try {
      await service.acceptConsultation(selected.id);

      await _loadConsultations(preferredSelectedId: selected.id);

      if (!mounted) {
        return;
      }

      _showMessage('협진을 수락했습니다.');
    } catch (error) {
      debugPrint('[CONSULT] 협진 수락 실패: $error');

      if (!mounted) {
        return;
      }

      _showMessage('협진을 수락하지 못했습니다.');
    }
  }

  // ============================================================
  // STEP 8. 협진 완료
  // POST /consultations/{id}/complete/
  // ============================================================

  Future<void> _complete() async {
    final selected = _selected;
    final service = _consultationService;

    if (selected == null || service == null) {
      return;
    }

    try {
      await service.completeConsultation(selected.id);

      await _loadConsultations(preferredSelectedId: selected.id);

      if (!mounted) {
        return;
      }

      _showMessage('협진을 완료했습니다.');
    } catch (error) {
      debugPrint('[CONSULT] 협진 완료 실패: $error');

      if (!mounted) {
        return;
      }

      _showMessage('협진을 완료하지 못했습니다.');
    }
  }

  // ============================================================
  // STEP 9. 협진 회수
  // POST /consultations/{id}/withdraw/
  // ============================================================

  Future<void> _withdraw() async {
    final selected = _selected;
    final service = _consultationService;

    if (selected == null || service == null) {
      return;
    }

    final reason = await _showWithdrawDialog();

    if (reason == null || reason.trim().isEmpty || !mounted) {
      return;
    }

    try {
      await service.withdrawConsultation(
        consultationId: selected.id,
        reason: reason.trim(),
      );

      await _loadConsultations(preferredSelectedId: selected.id);

      if (!mounted) {
        return;
      }

      _showMessage('협진 요청을 회수했습니다.');
    } catch (error) {
      debugPrint('[CONSULT] 협진 회수 실패: $error');

      if (!mounted) {
        return;
      }

      _showMessage('협진 요청을 회수하지 못했습니다.');
    }
  }

  Future<String?> _showWithdrawDialog() {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('협진 회수'),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: '회수 사유',
              hintText: '회수 사유를 입력해 주세요.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(controller.text.trim());
              },
              child: const Text('회수'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // STEP 10. 협진 의견
  // POST /consultations/{id}/opinions/
  // ============================================================

  Future<void> _addOpinion(ConsultationOpinionUiModel opinion) async {
    final selected = _selected;
    final service = _consultationService;

    if (selected == null || service == null) {
      return;
    }

    try {
      await service.addOpinion(
        consultationId: selected.id,
        opinionText: opinion.opinionText,
        isFinal: opinion.isFinal,
      );

      await _loadConsultationDetail(selected.id);

      if (!mounted) {
        return;
      }

      _showMessage('협진 의견이 등록되었습니다.');
    } catch (error) {
      debugPrint('[CONSULT] 협진 의견 등록 실패: $error');

      if (!mounted) {
        return;
      }

      _showMessage('협진 의견을 등록하지 못했습니다.');
    }
  }

  // ============================================================
  // STEP 11. List API → UI
  // ============================================================

  ConsultationUiModel _mapListItemToUi(
    ConsultationApiItem item, {
    required _ConsultationPatientSummary? patient,
    required int currentDoctorId,
  }) {
    final requesterProfile = item.requestedByProfile;

    final assignedProfile = item.assignedDoctorProfile;

    final requesterName = _profileText(
      requesterProfile,
      'name',
      fallback: '요청 의료진',
    );

    final requesterDepartment = _profileText(
      requesterProfile,
      'department_name',
      fallback: '진료과 미확인',
    );

    final requesterTitle = _nullableProfileText(requesterProfile, 'title');

    final assignedName = _profileText(
      assignedProfile,
      'name',
      fallback: '담당 의료진',
    );

    final assignedDepartment = _profileText(
      assignedProfile,
      'department_name',
      fallback: '진료과 미확인',
    );

    final assignedTitle = _nullableProfileText(assignedProfile, 'title');

    return ConsultationUiModel(
      id: item.id,
      patientId: item.patientId,
      patientName: patient?.name ?? '환자 #${item.patientId}',
      patientMeta:
          patient?.medicalRecordNo == null || patient!.medicalRecordNo == '-'
          ? 'Patient #${item.patientId}'
          : 'MRN ${patient.medicalRecordNo}',
      subject: item.subject,
      note: item.requestNote,
      assignedDoctorId: item.assignedDoctorId,
      assignedDoctorName: assignedName,
      assignedDepartment: assignedDepartment,
      encounterId: item.encounterId,
      priority: item.priority,
      dueAt: item.dueAt,
      status: _parseConsultationStatus(item.status),
      direction: item.requestedById == currentDoctorId
          ? ConsultationUiDirection.sent
          : ConsultationUiDirection.received,
      createdAt: item.createdAt,
      participants: [
        ConsultationParticipantUiModel(
          id: -1,
          doctorId: item.requestedById,
          doctorName: requesterName,
          department: requesterDepartment,
          roleLabel: '요청 의료진',
          title: requesterTitle,
        ),
        if (item.assignedDoctorId != item.requestedById)
          ConsultationParticipantUiModel(
            id: -2,
            doctorId: item.assignedDoctorId,
            doctorName: assignedName,
            department: assignedDepartment,
            roleLabel: '담당 의료진',
            title: assignedTitle,
          ),
      ],
      references: const [],
      opinions: const [],
      followUp: null,
      aiSummary: null,
      isDemo: false,
    );
  }

  // ============================================================
  // STEP 12. Detail API → UI
  // ============================================================

  ConsultationUiModel _mapDetailToUi(
    ConsultationDetailApiResult detail, {
    required _ConsultationPatientSummary? patient,
    required int currentDoctorId,
  }) {
    final consultation = detail.consultation;

    final base = _mapListItemToUi(
      consultation,
      patient: patient,
      currentDoctorId: currentDoctorId,
    );

    final participants = detail.participants.map(_mapParticipant).toList();

    final references = detail.references.map(_mapReference).toList();

    final opinions = detail.opinions.map(_mapOpinion).toList();

    return base.copyWith(
      participants: participants.isEmpty ? base.participants : participants,
      references: references,
      opinions: opinions,
    );
  }

  ConsultationParticipantUiModel _mapParticipant(Map<String, dynamic> json) {
    final profile = json['staff_profile'];

    final profileMap = profile is Map
        ? Map<String, dynamic>.from(profile)
        : null;

    final rawRole = json['participant_role']?.toString().toUpperCase() ?? '';

    return ConsultationParticipantUiModel(
      id: _intValue(json['id']),
      doctorId: _intValue(json['doctor']),
      doctorName: _profileText(profileMap, 'name', fallback: '의료진'),
      department: _profileText(
        profileMap,
        'department_name',
        fallback: '진료과 미확인',
      ),
      roleLabel: _participantRoleLabel(rawRole),
      title: _nullableProfileText(profileMap, 'title'),
    );
  }

  ConsultationReferenceUiModel _mapReference(Map<String, dynamic> json) {
    final referenceType = json['reference_type']?.toString() ?? 'REFERENCE';

    final referenceId = _intValue(json['reference_id']);

    return ConsultationReferenceUiModel(
      id: _intValue(json['id']),
      referenceTypeLabel: _referenceTypeLabel(referenceType),
      referenceId: referenceId,
      title: '${_referenceTypeLabel(referenceType)} #$referenceId',
      description: '협진에 연결된 참조 자료',
    );
  }

  ConsultationOpinionUiModel _mapOpinion(Map<String, dynamic> json) {
    final profile = json['author_profile'];

    final profileMap = profile is Map
        ? Map<String, dynamic>.from(profile)
        : null;

    return ConsultationOpinionUiModel(
      id: _intValue(json['id']),
      doctorId: _intValue(json['doctor']),
      doctorName: _profileText(profileMap, 'name', fallback: '의료진'),
      department: _profileText(
        profileMap,
        'department_name',
        fallback: '진료과 미확인',
      ),
      opinionText: json['opinion_text']?.toString() ?? '',
      isFinal: json['is_final'] == true,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  // ============================================================
  // STEP 13. Replace
  // ============================================================

  void _replaceConsultation(ConsultationUiModel updated) {
    final index = _consultations.indexWhere((item) => item.id == updated.id);

    if (index < 0) {
      return;
    }

    setState(() {
      final copied = [..._consultations];

      copied[index] = updated;

      _consultations = copied;
    });
  }

  // ============================================================
  // STEP 14. Responsive UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
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
          child: _buildBody(
            useSplitView: useSplitView,
            width: screenSize.width,
          ),
        ),
      ),
    );
  }

  Widget _buildBody({required bool useSplitView, required double width}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null && _consultations.isEmpty) {
      return _ConsultationLoadError(onRetry: _loadConsultations);
    }

    if (useSplitView) {
      return _buildSplitView(width);
    }

    return _buildCompactView();
  }

  Widget _buildSplitView(double width) {
    final selected = _selected;

    final railWidth = width >= 1250 ? 390.0 : 330.0;

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

              _loadConsultationDetail(consultation.id);
            },
            onCreate: _openCreateDialog,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: selected == null
              ? const _EmptyDetail()
              : Stack(
                  children: [
                    _buildDetailPanel(
                      consultation: selected,
                      showBackButton: false,
                    ),
                    if (_isDetailLoading)
                      const Positioned.fill(
                        child: IgnorePointer(child: _DetailLoadingOverlay()),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildCompactView() {
    final selected = _selected;

    if (_showCompactDetail && selected != null) {
      return Stack(
        children: [
          _buildDetailPanel(consultation: selected, showBackButton: true),
          if (_isDetailLoading)
            const Positioned.fill(
              child: IgnorePointer(child: _DetailLoadingOverlay()),
            ),
        ],
      );
    }

    return ConsultationListPanel(
      consultations: _consultations,
      selectedId: _selectedId,
      onSelected: (consultation) {
        setState(() {
          _selectedId = consultation.id;
          _showCompactDetail = true;
        });

        _loadConsultationDetail(consultation.id);
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

  // ============================================================
  // STEP 15. Message
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }
}

// ============================================================
// STEP 16. Parser Helpers
// ============================================================

ConsultationUiStatus _parseConsultationStatus(String value) {
  switch (value.toUpperCase()) {
    case 'REQUESTED':
    case 'PENDING':
      return ConsultationUiStatus.requested;

    case 'ACCEPTED':
    case 'IN_PROGRESS':
      return ConsultationUiStatus.inProgress;

    case 'COMPLETED':
      return ConsultationUiStatus.completed;

    case 'WITHDRAWN':
    case 'REJECTED':
    case 'CANCELED':
    case 'CANCELLED':
      return ConsultationUiStatus.withdrawn;

    default:
      return ConsultationUiStatus.requested;
  }
}

String _participantRoleLabel(String value) {
  switch (value) {
    case 'REQUESTER':
    case 'REQUESTED_BY':
    case 'OWNER':
      return '요청 의료진';

    case 'ASSIGNEE':
    case 'ASSIGNED':
    case 'CONSULTANT':
      return '담당 의료진';

    default:
      return value.isEmpty ? '참여 의료진' : value;
  }
}

String _referenceTypeLabel(String value) {
  switch (value.toUpperCase()) {
    case 'EXAMINATION':
      return '검사';

    case 'AI_ANALYSIS':
    case 'AI_RESULT':
      return 'AI';

    case 'REPORT':
      return '보고서';

    case 'IMAGING':
    case 'IMAGE':
      return '영상';

    default:
      return value;
  }
}

String _profileText(
  Map<String, dynamic>? profile,
  String key, {
  required String fallback,
}) {
  final value = profile?[key]?.toString().trim();

  if (value == null || value.isEmpty) {
    return fallback;
  }

  return value;
}

String? _nullableProfileText(Map<String, dynamic>? profile, String key) {
  final value = profile?[key]?.toString().trim();

  if (value == null || value.isEmpty) {
    return null;
  }

  return value;
}

int _intValue(dynamic value) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

// ============================================================
// STEP 17. Patient Summary
// ============================================================

class _ConsultationPatientSummary {
  final int patientId;
  final String name;
  final String medicalRecordNo;

  const _ConsultationPatientSummary({
    required this.patientId,
    required this.name,
    required this.medicalRecordNo,
  });
}

// ============================================================
// STEP 18. Loading / Error
// ============================================================

class _DetailLoadingOverlay extends StatelessWidget {
  const _DetailLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appBackground.withValues(alpha: 0.35),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}

class _ConsultationLoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _ConsultationLoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.appBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 32,
              color: context.appTextSecondary,
            ),
            const SizedBox(height: 10),
            Text(
              '협진 목록을 불러오지 못했습니다.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STEP 19. Empty Detail
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
