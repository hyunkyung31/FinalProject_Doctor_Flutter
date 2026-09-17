import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../examinations/data/services/examination_service.dart';
import '../../../examinations/presentation/examination_ui_models.dart';
import '../../data/services/patient_care_service.dart';
import 'patient_detail_tabs.dart';

class PatientCareTab extends StatefulWidget {
  final PatientUiModel patient;
  final List<PatientTimelineItem> timelineItems;
  final VoidCallback onOpenExaminations;
  final VoidCallback onOpenPrescriptions;
  final bool embedded;
  final Future<List<ExaminationEncounterUiModel>> Function()? encounterLoader;

  const PatientCareTab({
    super.key,
    required this.patient,
    required this.timelineItems,
    required this.onOpenExaminations,
    required this.onOpenPrescriptions,
    this.encounterLoader,
    this.embedded = false,
  });

  @override
  State<PatientCareTab> createState() => _PatientCareTabState();
}

class _PatientCareTabState extends State<PatientCareTab> {
  List<ExaminationEncounterUiModel> _encounters = [];
  List<PatientVitalSign> _vitalSigns = [];
  List<PatientEncounterNote> _notes = [];
  List<PatientMedicalHistory> _medicalHistories = [];
  List<PatientAllergy> _allergies = [];

  bool _isLoading = true;
  bool _isSavingVitalSign = false;
  bool _isSavingNote = false;
  bool _isUpdatingEncounter = false;
  bool _isSavingMedicalHistory = false;
  bool _isSavingAllergy = false;

  String? _loadError;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCareData();
    });
  }

  @override
  void didUpdateWidget(covariant PatientCareTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.patient.patientId != widget.patient.patientId) {
      _loadCareData();
    }
  }

  Future<void> _loadCareData() async {
    final requestedPatientId = widget.patient.patientId;
    final totalStopwatch = Stopwatch()..start();

    Future<T> timed<T>(String name, Future<T> Function() action) async {
      final stopwatch = Stopwatch()..start();

      try {
        return await action();
      } finally {
        stopwatch.stop();

        debugPrint(
          '[CARE PERF] $name: '
          '${stopwatch.elapsedMilliseconds}ms',
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final auth = context.read<AuthProvider>();

      final examinationService = ExaminationService(
        apiClient: auth.authService.apiClient,
      );

      final careService = PatientCareService(
        apiClient: auth.authService.apiClient,
      );

      // 서로 의존하지 않는 3개 요청은 동시에 시작
      final medicalHistoriesFuture = timed(
        'medical histories',
        () => careService.fetchMedicalHistories(requestedPatientId),
      );

      final allergiesFuture = timed(
        'allergies',
        () => careService.fetchAllergies(requestedPatientId),
      );

      final encountersFuture = timed('encounters', () {
        final loader = widget.encounterLoader;

        if (loader != null) {
          return loader();
        }

        return examinationService.fetchEncounters();
      });

      final medicalHistories = await medicalHistoriesFuture;
      final allergies = await allergiesFuture;
      final encounters = await encountersFuture;

      medicalHistories.sort((a, b) {
        final aActive = a.status.toUpperCase() == 'ACTIVE';
        final bActive = b.status.toUpperCase() == 'ACTIVE';

        if (aActive != bActive) {
          return aActive ? -1 : 1;
        }

        final aDate = a.onsetDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.onsetDate ?? DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

      allergies.sort((a, b) {
        final aActive = a.status.toUpperCase() == 'ACTIVE';
        final bActive = b.status.toUpperCase() == 'ACTIVE';

        if (aActive != bActive) {
          return aActive ? -1 : 1;
        }

        final aDate = a.verifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.verifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

      final patientEncounters =
          encounters
              .where((encounter) => encounter.patientId == requestedPatientId)
              .toList()
            ..sort((a, b) => b.visitDate.compareTo(a.visitDate));

      ExaminationEncounterUiModel? mainEncounter;

      for (final encounter in patientEncounters) {
        if (!_isClosedEncounter(encounter)) {
          mainEncounter = encounter;
          break;
        }
      }

      if (mainEncounter == null && patientEncounters.isNotEmpty) {
        mainEncounter = patientEncounters.first;
      }

      List<PatientVitalSign> vitalSigns = [];
      List<PatientEncounterNote> notes = [];

      if (mainEncounter != null) {
        final encounterId = mainEncounter.id;

        final vitalSignsFuture = timed(
          'vital signs',
          () => careService.fetchVitalSigns(encounterId),
        );

        final notesFuture = timed(
          'notes',
          () => careService.fetchNotes(encounterId),
        );

        vitalSigns = await vitalSignsFuture;
        notes = await notesFuture;

        vitalSigns.sort((a, b) {
          final aDate = a.measuredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.measuredAt ?? DateTime.fromMillisecondsSinceEpoch(0);

          return bDate.compareTo(aDate);
        });

        notes.sort((a, b) {
          final aDate =
              a.updatedAt ??
              a.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0);

          final bDate =
              b.updatedAt ??
              b.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0);

          return bDate.compareTo(aDate);
        });
      }

      // 조회 도중 다른 환자를 선택했다면 이전 응답은 버림
      if (!mounted || widget.patient.patientId != requestedPatientId) {
        return;
      }

      setState(() {
        _encounters = patientEncounters;
        _vitalSigns = vitalSigns;
        _notes = notes;
        _medicalHistories = medicalHistories;
        _allergies = allergies;

        _isLoading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted || widget.patient.patientId != requestedPatientId) {
        return;
      }

      totalStopwatch.stop();

      debugPrint(
        '[CARE PERF] TOTAL: '
        '${totalStopwatch.elapsedMilliseconds}ms',
      );

      setState(() {
        _encounters = [];
        _vitalSigns = [];
        _notes = [];
        _medicalHistories = [];
        _allergies = [];

        _isLoading = false;
        _loadError = error.toString();
      });

      debugPrint(
        '[PatientCareTab] 진료 데이터 조회 실패: '
        'patientId=$requestedPatientId, '
        'error=$error',
      );
    }
  }

  bool _isClosedEncounter(ExaminationEncounterUiModel encounter) {
    final status = encounter.status.toUpperCase();

    return status == 'COMPLETED' ||
        status == 'CANCELED' ||
        status == 'CANCELLED';
  }

  ExaminationEncounterUiModel? get _activeEncounter {
    for (final encounter in _encounters) {
      if (!_isClosedEncounter(encounter)) {
        return encounter;
      }
    }

    return null;
  }

  ExaminationEncounterUiModel? get _mainEncounter {
    return _activeEncounter ?? (_encounters.isEmpty ? null : _encounters.first);
  }

  List<ExaminationEncounterUiModel> get _previousEncounters {
    final mainEncounter = _mainEncounter;

    if (mainEncounter == null) {
      return [];
    }

    return _encounters
        .where((encounter) => encounter.id != mainEncounter.id)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return _ErrorView(onRetry: _loadCareData);
    }

    final children = <Widget>[
      // 최근 진료
      _buildCurrentEncounterCard(),

      const SizedBox(height: 12),

      // 환자 임상정보
      _buildClinicalSummaryCard(),

      const SizedBox(height: 12),

      // 내원 이력
      _buildPreviousEncounterCard(),

      const SizedBox(height: 12),

      // 진료기록
      _buildNotesCard(),

      const SizedBox(height: 12),

      // 활력징후
      _buildVitalSignsCard(),
    ];

    if (widget.embedded) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      );
    }

    return ListView(padding: const EdgeInsets.all(16), children: children);
  }

  Widget _buildCurrentEncounterCard() {
    final encounter = _mainEncounter;
    final auth = context.watch<AuthProvider>();
    final isDoctor = !auth.isNurse;

    if (encounter == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const _EmptyMessage(text: '등록된 진료 정보가 없습니다.'),
      );
    }

    final canStart =
        isDoctor &&
        encounter.status.toUpperCase() == 'OPEN' &&
        encounter.startedAt == null &&
        encounter.completedAt == null;

    final canComplete =
        isDoctor &&
        encounter.status.toUpperCase() == 'OPEN' &&
        encounter.startedAt != null &&
        encounter.completedAt == null;

    final koreaVisitDate = encounter.visitDate.toUtc().add(
      const Duration(hours: 9),
    );

    final year = koreaVisitDate.year.toString();
    final month = koreaVisitDate.month.toString().padLeft(2, '0');
    final day = koreaVisitDate.day.toString().padLeft(2, '0');

    final visitDateText = '$year.$month.$day';

    final koreaNow = DateTime.now().toUtc().add(const Duration(hours: 9));

    final isToday =
        koreaVisitDate.year == koreaNow.year &&
        koreaVisitDate.month == koreaNow.month &&
        koreaVisitDate.day == koreaNow.day;

    final title = isToday ? '오늘 진료' : '최근 진료';

    Widget buildMetaItem({
      required IconData icon,
      required String label,
      required String value,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.navy),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    Widget? actionButton;

    if (canStart) {
      actionButton = FilledButton.icon(
        onPressed: _isUpdatingEncounter
            ? null
            : () {
                _startEncounter(encounter);
              },
        style: FilledButton.styleFrom(
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        icon: const Icon(Icons.play_arrow_rounded, size: 15),
        label: Text(
          _isUpdatingEncounter ? '처리 중' : '진료 시작',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
      );
    } else if (canComplete) {
      actionButton = FilledButton.icon(
        onPressed: _isUpdatingEncounter
            ? null
            : () {
                _openCompleteEncounterDialog(encounter);
              },
        style: FilledButton.styleFrom(
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        icon: const Icon(Icons.check_rounded, size: 15),
        label: Text(
          _isUpdatingEncounter ? '처리 중' : '진료 완료',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      visitDateText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(
                text: _encounterStatusLabel(encounter),
                color: _encounterStatusColor(encounter),
              ),
              if (actionButton != null) ...[
                const SizedBox(width: 8),
                actionButton,
              ],
            ],
          ),

          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              buildMetaItem(
                icon: Icons.person_outline,
                label: '담당의',
                value: _normalizedText(widget.patient.doctorName),
              ),
              buildMetaItem(
                icon: Icons.medical_services_outlined,
                label: '진료유형',
                value: _encounterTypeLabel(encounter.encounterType),
              ),
              buildMetaItem(
                icon: Icons.local_hospital_outlined,
                label: '진료과',
                value: _normalizedText(widget.patient.department),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _encounterStatusLabel(ExaminationEncounterUiModel encounter) {
    final status = encounter.status.toUpperCase();

    if (status == 'OPEN' &&
        encounter.startedAt == null &&
        encounter.completedAt == null) {
      return '진료 대기';
    }

    if (status == 'OPEN' &&
        encounter.startedAt != null &&
        encounter.completedAt == null) {
      return '진료 중';
    }

    if (status == 'COMPLETED') {
      return '진료 완료';
    }

    return _statusLabel(encounter.status);
  }

  Color _encounterStatusColor(ExaminationEncounterUiModel encounter) {
    final status = encounter.status.toUpperCase();

    if (status == 'OPEN' &&
        encounter.startedAt != null &&
        encounter.completedAt == null) {
      return AppColors.primaryBlue;
    }

    if (status == 'COMPLETED') {
      return AppColors.success;
    }

    return _statusColor(encounter.status);
  }

  Future<void> _startEncounter(ExaminationEncounterUiModel encounter) async {
    final requestedPatientId = widget.patient.patientId;

    setState(() {
      _isUpdatingEncounter = true;
    });

    try {
      final auth = context.read<AuthProvider>();

      if (auth.isNurse) {
        _showMessage('의사만 진료를 시작할 수 있습니다.');
        return;
      }

      final careService = PatientCareService(
        apiClient: auth.authService.apiClient,
      );

      final response = await careService.startEncounter(
        encounterId: encounter.id,
      );

      final updatedEncounter = ExaminationEncounterUiModel.fromJson(response);

      if (!mounted || widget.patient.patientId != requestedPatientId) {
        return;
      }

      setState(() {
        _encounters = _encounters.map((item) {
          return item.id == updatedEncounter.id ? updatedEncounter : item;
        }).toList();
      });

      _showMessage('진료가 시작되었습니다.');
    } catch (error) {
      debugPrint('[PatientCareTab] 진료 시작 실패: $error');

      if (mounted) {
        _showMessage('진료를 시작하지 못했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingEncounter = false;
        });
      }
    }
  }

  Future<void> _openCompleteEncounterDialog(
    ExaminationEncounterUiModel encounter,
  ) async {
    final formKey = GlobalKey<FormState>();
    var outcome = '';

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            '진료 완료',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: TextFormField(
                minLines: 4,
                maxLines: 7,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '진료 결과',
                  hintText: '진료 결과를 입력해 주세요.',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  outcome = value;
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '진료 결과를 입력해 주세요.';
                  }

                  return null;
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }

                Navigator.pop(dialogContext, outcome.trim());
              },
              child: const Text('진료 완료'),
            ),
          ],
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    await _completeEncounter(encounter: encounter, outcome: result);
  }

  Future<void> _completeEncounter({
    required ExaminationEncounterUiModel encounter,
    required String outcome,
  }) async {
    final requestedPatientId = widget.patient.patientId;

    setState(() {
      _isUpdatingEncounter = true;
    });

    try {
      final auth = context.read<AuthProvider>();

      if (auth.isNurse) {
        _showMessage('의사만 진료를 완료할 수 있습니다.');
        return;
      }

      final careService = PatientCareService(
        apiClient: auth.authService.apiClient,
      );

      final response = await careService.completeEncounter(
        encounterId: encounter.id,
        outcome: outcome,
      );

      final updatedEncounter = ExaminationEncounterUiModel.fromJson(response);

      if (!mounted || widget.patient.patientId != requestedPatientId) {
        return;
      }

      setState(() {
        _encounters = _encounters.map((item) {
          return item.id == updatedEncounter.id ? updatedEncounter : item;
        }).toList();
      });

      _showMessage('진료가 완료되었습니다.');
    } catch (error) {
      debugPrint('[PatientCareTab] 진료 완료 실패: $error');

      if (mounted) {
        _showMessage('진료를 완료하지 못했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingEncounter = false;
        });
      }
    }
  }

  Widget _buildVitalSignsCard() {
    final latest = _vitalSigns.isEmpty ? null : _vitalSigns.first;

    Widget headerCell(String label, String unit, {int flex = 1}) {
      return Expanded(
        flex: flex,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(height: 1),
              Text(
                unit,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 7.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      );
    }

    Widget valueCell(String value, {int flex = 1}) {
      return Expanded(
        flex: flex,
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      );
    }

    return _SectionCard(
      title: '활력징후',
      icon: Icons.monitor_heart_outlined,
      contentSpacing: 3,
      action: TextButton.icon(
        onPressed: _isSavingVitalSign ? null : _openVitalSignDialog,
        icon: const Icon(Icons.add_rounded, size: 15),
        label: Text(
          _isSavingVitalSign ? '저장 중' : '입력',
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
        ),
      ),
      child: latest == null
          ? const _EmptyMessage(text: '등록된 활력징후가 없습니다.')
          : Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    color: AppColors.surfaceSoft,
                    child: Row(
                      children: [
                        headerCell('측정일시', '', flex: 22),
                        headerCell('혈압', 'mmHg', flex: 14),
                        headerCell('맥박', 'bpm', flex: 11),
                        headerCell('호흡수', '/min', flex: 11),
                        headerCell('체온', '℃', flex: 11),
                        headerCell('SpO₂', '%', flex: 10),
                        headerCell('키', 'cm', flex: 11),
                        headerCell('체중', 'kg', flex: 11),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: AppColors.border),

                  SizedBox(
                    height: 42,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          valueCell(
                            latest.measuredAt == null
                                ? '-'
                                : _formatDateTime(latest.measuredAt!),
                            flex: 22,
                          ),
                          valueCell(
                            '${latest.systolicBp ?? '-'}'
                            '/'
                            '${latest.diastolicBp ?? '-'}',
                            flex: 14,
                          ),
                          valueCell(
                            latest.pulseRate?.toString() ?? '-',
                            flex: 11,
                          ),
                          valueCell(
                            latest.respiratoryRate?.toString() ?? '-',
                            flex: 11,
                          ),
                          valueCell(
                            _formatNumber(latest.bodyTemperature),
                            flex: 11,
                          ),
                          valueCell(
                            _formatNumber(latest.oxygenSaturation),
                            flex: 10,
                          ),
                          valueCell(
                            latest.heightCm == null
                                ? '-'
                                : _formatNumber(latest.heightCm),
                            flex: 11,
                          ),
                          valueCell(
                            latest.weightKg == null
                                ? '-'
                                : _formatNumber(latest.weightKg),
                            flex: 11,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNotesCard() {
    return _SectionCard(
      title: '진료기록',
      icon: Icons.edit_note_rounded,
      action: TextButton.icon(
        onPressed: _isSavingNote ? null : _openNoteDialog,
        icon: const Icon(Icons.edit_outlined, size: 15),
        label: Text(
          _isSavingNote ? '저장 중' : '작성',
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
        ),
      ),
      child: _notes.isEmpty
          ? const _EmptyMessage(text: '작성된 진료기록이 없습니다.')
          : Column(
              children: _notes.take(3).map((note) {
                final date = note.updatedAt ?? note.createdAt;
                final isDraft = note.status.toUpperCase() == 'DRAFT';

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (date != null)
                            Expanded(
                              child: Text(
                                _formatDateTime(date),
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          else
                            const Spacer(),

                          _StatusBadge(
                            text: _noteStatusLabel(note.status),
                            color: _noteStatusColor(note.status),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        note.noteText,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.5,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      if (isDraft) ...[
                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _isSavingNote
                                  ? null
                                  : () {
                                      _openEditNoteDialog(note);
                                    },
                              child: const Text(
                                '수정',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            const SizedBox(width: 4),

                            FilledButton(
                              onPressed: _isSavingNote
                                  ? null
                                  : () {
                                      _confirmNote(note);
                                    },
                              child: const Text(
                                '확정',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (!isDraft && note.confirmedAt != null) ...[
                        const SizedBox(height: 8),

                        Text(
                          '확정 ${_formatDateTime(note.confirmedAt!)}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Future<void> _openVitalSignDialog() async {
    final encounter = _mainEncounter;

    if (encounter == null) {
      _showMessage('진료 정보가 없어 활력징후를 입력할 수 없습니다.');
      return;
    }

    final systolicController = TextEditingController();
    final diastolicController = TextEditingController();
    final pulseController = TextEditingController();
    final respiratoryController = TextEditingController();
    final temperatureController = TextEditingController();
    final oxygenController = TextEditingController();
    final heightController = TextEditingController();
    final weightController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    final draft = await showDialog<_VitalSignDraft>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            '활력징후 입력',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _NumberInput(
                            controller: systolicController,
                            label: '수축기 혈압',
                            suffix: 'mmHg',
                            integerOnly: true,
                            required: true,
                            minValue: 30,
                            maxValue: 300,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _NumberInput(
                            controller: diastolicController,
                            label: '이완기 혈압',
                            suffix: 'mmHg',
                            integerOnly: true,
                            required: true,
                            minValue: 10,
                            maxValue: 200,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _NumberInput(
                            controller: pulseController,
                            label: '맥박',
                            suffix: 'bpm',
                            integerOnly: true,
                            required: true,
                            minValue: 10,
                            maxValue: 300,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _NumberInput(
                            controller: respiratoryController,
                            label: '호흡수',
                            suffix: '/min',
                            integerOnly: true,
                            required: true,
                            minValue: 1,
                            maxValue: 100,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _NumberInput(
                            controller: temperatureController,
                            label: '체온',
                            suffix: '℃',
                            required: true,
                            minValue: 20,
                            maxValue: 45,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _NumberInput(
                            controller: oxygenController,
                            label: '산소포화도',
                            suffix: '%',
                            required: true,
                            minValue: 1,
                            maxValue: 100,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _NumberInput(
                            controller: heightController,
                            label: '키',
                            suffix: 'cm',
                            minValue: 30,
                            maxValue: 250,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _NumberInput(
                            controller: weightController,
                            label: '체중',
                            suffix: 'kg',
                            minValue: 1,
                            maxValue: 500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }

                final systolic = int.parse(systolicController.text.trim());

                final diastolic = int.parse(diastolicController.text.trim());

                if (systolic <= diastolic) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('수축기 혈압은 이완기 혈압보다 커야 합니다.')),
                  );
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  _VitalSignDraft(
                    systolicBp: systolic,
                    diastolicBp: diastolic,
                    pulseRate: int.parse(pulseController.text.trim()),
                    respiratoryRate: int.parse(
                      respiratoryController.text.trim(),
                    ),
                    bodyTemperature: double.parse(
                      temperatureController.text.trim(),
                    ),
                    oxygenSaturation: double.parse(
                      oxygenController.text.trim(),
                    ),
                    heightCm: _parseOptionalDouble(heightController.text),
                    weightKg: _parseOptionalDouble(weightController.text),
                  ),
                );
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (draft == null || !mounted) {
      return;
    }

    await _saveVitalSign(encounterId: encounter.id, draft: draft);
  }

  Future<void> _saveVitalSign({
    required int encounterId,
    required _VitalSignDraft draft,
  }) async {
    setState(() {
      _isSavingVitalSign = true;
    });

    try {
      final auth = context.read<AuthProvider>();

      final careService = PatientCareService(
        apiClient: auth.authService.apiClient,
      );

      final created = await careService.createVitalSign(
        encounterId: encounterId,
        systolicBp: draft.systolicBp,
        diastolicBp: draft.diastolicBp,
        pulseRate: draft.pulseRate,
        respiratoryRate: draft.respiratoryRate,
        bodyTemperature: draft.bodyTemperature,
        oxygenSaturation: draft.oxygenSaturation,
        heightCm: draft.heightCm,
        weightKg: draft.weightKg,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _vitalSigns = [
          created,
          ..._vitalSigns.where((item) => item.id != created.id),
        ];
      });

      _showMessage('활력징후가 저장되었습니다.');
    } catch (error) {
      debugPrint('[PatientCareTab] 활력징후 저장 실패: $error');

      if (mounted) {
        _showMessage('활력징후를 저장하지 못했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingVitalSign = false;
        });
      }
    }
  }

  Future<void> _openNoteDialog() async {
    final encounter = _mainEncounter;

    if (encounter == null) {
      _showMessage('진료 정보가 없어 진료기록을 작성할 수 없습니다.');
      return;
    }

    final controller = TextEditingController();

    final noteText = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            '진료기록 작성',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 480,
            child: TextField(
              controller: controller,
              minLines: 5,
              maxLines: 9,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '진료 내용을 입력해 주세요.',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();

                if (text.isEmpty) {
                  return;
                }

                Navigator.pop(dialogContext, text);
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (noteText == null || !mounted) {
      return;
    }

    await _saveNote(encounterId: encounter.id, noteText: noteText);
  }

  Future<void> _openEditNoteDialog(PatientEncounterNote note) async {
    if (note.status.toUpperCase() != 'DRAFT') {
      _showMessage('확정된 진료기록은 수정할 수 없습니다.');
      return;
    }

    final controller = TextEditingController(text: note.noteText);

    final updatedText = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            '진료기록 수정',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 480,
            child: TextField(
              controller: controller,
              minLines: 5,
              maxLines: 9,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '진료 내용을 입력해 주세요.',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();

                if (text.isEmpty) {
                  return;
                }

                Navigator.pop(dialogContext, text);
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (updatedText == null || !mounted) {
      return;
    }

    await _updateNote(noteId: note.id, noteText: updatedText);
  }

  Future<void> _updateNote({
    required int noteId,
    required String noteText,
  }) async {
    setState(() {
      _isSavingNote = true;
    });

    try {
      final auth = context.read<AuthProvider>();

      final careService = PatientCareService(
        apiClient: auth.authService.apiClient,
      );

      final updated = await careService.updateNote(
        noteId: noteId,
        noteText: noteText,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _notes = _notes.map((note) {
          return note.id == updated.id ? updated : note;
        }).toList();
      });

      _showMessage('진료기록이 수정되었습니다.');
    } catch (error) {
      debugPrint('[PatientCareTab] 진료기록 수정 실패: $error');

      if (mounted) {
        _showMessage('진료기록을 수정하지 못했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingNote = false;
        });
      }
    }
  }

  Future<void> _confirmNote(PatientEncounterNote note) async {
    if (note.status.toUpperCase() != 'DRAFT') {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            '진료기록 확정',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: const Text(
            '이 진료기록을 최종 확정하시겠습니까?\n'
            '확정 후에는 수정하거나 삭제할 수 없습니다.',
            style: TextStyle(fontSize: 12, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('확정'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isSavingNote = true;
    });

    try {
      final auth = context.read<AuthProvider>();

      final careService = PatientCareService(
        apiClient: auth.authService.apiClient,
      );

      final updated = await careService.confirmNote(note.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _notes = _notes.map((item) {
          return item.id == updated.id ? updated : item;
        }).toList();
      });

      _showMessage('진료기록이 확정되었습니다.');
    } catch (error) {
      debugPrint('[PatientCareTab] 진료기록 확정 실패: $error');

      if (mounted) {
        _showMessage('진료기록을 확정하지 못했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingNote = false;
        });
      }
    }
  }

  Future<void> _saveNote({
    required int encounterId,
    required String noteText,
  }) async {
    setState(() {
      _isSavingNote = true;
    });

    try {
      final auth = context.read<AuthProvider>();

      final careService = PatientCareService(
        apiClient: auth.authService.apiClient,
      );

      final created = await careService.createNote(
        encounterId: encounterId,
        noteText: noteText,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _notes = [created, ..._notes.where((item) => item.id != created.id)];
      });

      _showMessage('진료기록이 저장되었습니다.');
    } catch (error) {
      debugPrint('[PatientCareTab] 진료기록 저장 실패: $error');

      if (mounted) {
        _showMessage('진료기록을 저장하지 못했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingNote = false;
        });
      }
    }
  }

  double? _parseOptionalDouble(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      return null;
    }

    return double.tryParse(normalized);
  }

  String _formatNumber(double? value) {
    if (value == null) {
      return '-';
    }

    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  String _noteStatusLabel(String value) {
    switch (value.toUpperCase()) {
      case 'DRAFT':
        return '초안';
      case 'CONFIRMED':
      case 'FINAL':
        return '확정';
      default:
        return value.isEmpty ? '-' : value;
    }
  }

  Color _noteStatusColor(String value) {
    switch (value.toUpperCase()) {
      case 'CONFIRMED':
      case 'FINAL':
        return AppColors.success;
      case 'DRAFT':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  // ============================================================
  // 환자 임상정보 카드 : 최근 진료 카드와 같은 정보형 레이아웃
  Widget _buildClinicalSummaryCard() {
    final auth = context.watch<AuthProvider>();

    final latestExam = widget.patient.latestExam.trim();
    final latestExamDate = widget.patient.latestExamDate.trim();
    final aiSummary = widget.patient.aiSummary.trim();

    final latestExamText = latestExam.isEmpty || latestExam == '검사 정보 없음'
        ? '최근 검사 정보 없음'
        : latestExamDate.isEmpty || latestExamDate == '-'
        ? latestExam
        : '$latestExam · $latestExamDate';

    final aiSummaryText = aiSummary.isEmpty || aiSummary == 'AI 분석 정보 없음'
        ? 'AI 분석 정보 없음'
        : aiSummary;

    Widget buildInfoRow({
      required String label,
      required String value,
      bool isLast = false,
    }) {
      return Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 76,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _SectionCard(
      title: '환자 임상정보',
      icon: Icons.monitor_heart_outlined,
      action: auth.isNurse
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: _isSavingMedicalHistory
                      ? null
                      : _openMedicalHistoryDialog,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 5,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 14),
                  label: Text(
                    _isSavingMedicalHistory ? '저장 중' : '과거력',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                TextButton.icon(
                  onPressed: _isSavingAllergy ? null : _openAllergyDialog,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 5,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 14),
                  label: Text(
                    _isSavingAllergy ? '저장 중' : '알레르기',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildInfoRow(
            label: '주진단',
            value: _normalizedText(widget.patient.primaryDiagnosis),
          ),
          buildInfoRow(label: '알레르기', value: _allergySummary()),
          buildInfoRow(label: '과거력', value: _medicalHistorySummary()),
          buildInfoRow(label: '최근 검사', value: latestExamText),
          buildInfoRow(label: 'AI 분석', value: aiSummaryText, isLast: true),
        ],
      ),
    );
  }

  String _medicalHistorySummary() {
    if (_medicalHistories.isEmpty) {
      return '등록된 과거력 없음';
    }

    return _medicalHistories
        .take(5)
        .map((history) {
          final name = history.conditionName.trim().isEmpty
              ? history.conditionCode
              : history.conditionName;

          if (history.onsetDate == null) {
            return name;
          }

          final date = history.onsetDate!;
          final year = date.year.toString();
          final month = date.month.toString().padLeft(2, '0');
          final day = date.day.toString().padLeft(2, '0');

          return '$name($year.$month.$day~)';
        })
        .join(' · ');
  }

  Future<void> _openMedicalHistoryDialog() async {
    final conditionNameController = TextEditingController();
    final conditionCodeController = TextEditingController();
    final onsetDateController = TextEditingController();
    final noteController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    final draft = await showDialog<_MedicalHistoryDraft>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            '과거력 추가',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: conditionNameController,
                      decoration: const InputDecoration(
                        labelText: '질환명',
                        hintText: '예: 고혈압',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '질환명을 입력해 주세요.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: conditionCodeController,
                      decoration: const InputDecoration(
                        labelText: '질환 코드',
                        hintText: '예: I10',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: onsetDateController,
                      decoration: const InputDecoration(
                        labelText: '발병일',
                        hintText: 'YYYY-MM-DD',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';

                        if (text.isEmpty) {
                          return null;
                        }

                        if (DateTime.tryParse(text) == null) {
                          return 'YYYY-MM-DD 형식으로 입력해 주세요.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: noteController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: '메모',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }

                final onsetText = onsetDateController.text.trim();

                Navigator.pop(
                  dialogContext,
                  _MedicalHistoryDraft(
                    conditionName: conditionNameController.text.trim(),
                    conditionCode: conditionCodeController.text.trim(),
                    onsetDate: onsetText.isEmpty
                        ? null
                        : DateTime.parse(onsetText),
                    note: noteController.text.trim(),
                  ),
                );
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (draft == null || !mounted) {
      return;
    }

    await _saveMedicalHistory(draft);
  }

  Future<void> _saveMedicalHistory(_MedicalHistoryDraft draft) async {
    setState(() {
      _isSavingMedicalHistory = true;
    });

    try {
      final auth = context.read<AuthProvider>();

      final careService = PatientCareService(
        apiClient: auth.authService.apiClient,
      );

      final created = await careService.createMedicalHistory(
        patientId: widget.patient.patientId,
        conditionName: draft.conditionName,
        conditionCode: draft.conditionCode,
        onsetDate: draft.onsetDate,
        note: draft.note,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _medicalHistories = [
          created,
          ..._medicalHistories.where((item) => item.id != created.id),
        ];
      });

      _showMessage('과거력이 등록되었습니다.');
    } catch (error) {
      debugPrint('[PatientCareTab] 과거력 등록 실패: $error');

      if (mounted) {
        _showMessage('과거력을 등록하지 못했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingMedicalHistory = false;
        });
      }
    }
  }

  Future<void> _openAllergyDialog() async {
    final allergenNameController = TextEditingController();
    final reactionController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    final draft = await showDialog<_AllergyDraft>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            '알레르기 추가',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: allergenNameController,
                    decoration: const InputDecoration(
                      labelText: '알레르기 원인',
                      hintText: '예: 페니실린',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '알레르기 원인을 입력해 주세요.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: reactionController,
                    decoration: const InputDecoration(
                      labelText: '반응',
                      hintText: '예: 발진',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  _AllergyDraft(
                    allergenName: allergenNameController.text.trim(),
                    reaction: reactionController.text.trim(),
                  ),
                );
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (draft == null || !mounted) {
      return;
    }

    await _saveAllergy(draft);
  }

  Future<void> _saveAllergy(_AllergyDraft draft) async {
    setState(() {
      _isSavingAllergy = true;
    });

    try {
      final auth = context.read<AuthProvider>();

      final careService = PatientCareService(
        apiClient: auth.authService.apiClient,
      );

      final created = await careService.createAllergy(
        patientId: widget.patient.patientId,
        allergenName: draft.allergenName,
        reaction: draft.reaction,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _allergies = [
          created,
          ..._allergies.where((item) => item.id != created.id),
        ];
      });

      _showMessage('알레르기가 등록되었습니다.');
    } catch (error) {
      debugPrint('[PatientCareTab] 알레르기 등록 실패: $error');

      if (mounted) {
        _showMessage('알레르기를 등록하지 못했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingAllergy = false;
        });
      }
    }
  }

  String _allergySummary() {
    if (_allergies.isEmpty) {
      return '등록된 알레르기 없음';
    }

    return _allergies
        .take(5)
        .map((allergy) {
          if (allergy.isNoKnownAllergy) {
            return '알려진 알레르기 없음';
          }

          final name = allergy.allergenName.trim().isEmpty
              ? '알레르기 정보'
              : allergy.allergenName;

          final reaction = allergy.reaction.trim();

          if (reaction.isEmpty) {
            return name;
          }

          return '$name · $reaction';
        })
        .join(' · ');
  }

  bool _isSameKstDate(DateTime first, DateTime second) {
    final firstKst = first.toUtc().add(const Duration(hours: 9));
    final secondKst = second.toUtc().add(const Duration(hours: 9));

    return firstKst.year == secondKst.year &&
        firstKst.month == secondKst.month &&
        firstKst.day == secondKst.day;
  }

  List<PatientTimelineItem> _examinationsForEncounter(
    ExaminationEncounterUiModel encounter,
  ) {
    final items = widget.timelineItems.where((item) {
      if (item.eventType.trim().toUpperCase() != 'EXAMINATION') {
        return false;
      }

      final occurredAt = item.occurredAt;

      if (occurredAt == null) {
        return false;
      }

      return _isSameKstDate(encounter.visitDate, occurredAt);
    }).toList();

    items.sort((a, b) {
      final aTime = a.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return bTime.compareTo(aTime);
    });

    return items;
  }

  String _examinationDisplayName(PatientTimelineItem item) {
    final code =
        item.data['examination_type_code']?.toString().trim().toUpperCase() ??
        '';

    switch (code) {
      case 'BLOOD':
      case 'CARDIAC_LAB_PANEL':
        return '혈액검사';

      case 'ANGIO_2D':
      case 'ANGIOGRAPHY':
        return '관상동맥조영술';

      case 'CCTA':
      case 'CCTA_3D':
        return '관상동맥 CT 검사';

      default:
        final title = item.title.trim();

        return title.isEmpty ? '검사' : title;
    }
  }

  String _examinationStatusLabel(String value) {
    switch (value.trim().toUpperCase()) {
      case 'COMPLETED':
      case 'SUCCEEDED':
        return '완료';

      case 'IN_PROGRESS':
      case 'RUNNING':
        return '진행 중';

      case 'SCHEDULED':
        return '예정';

      case 'ORDERED':
      case 'PENDING':
        return '대기';

      case 'FAILED':
        return '실패';

      case 'CANCELED':
      case 'CANCELLED':
        return '취소';

      default:
        return value.trim().isEmpty ? '-' : value;
    }
  }

  Color _examinationStatusColor(String value) {
    switch (value.trim().toUpperCase()) {
      case 'COMPLETED':
      case 'SUCCEEDED':
        return AppColors.success;

      case 'IN_PROGRESS':
      case 'RUNNING':
        return AppColors.primaryBlue;

      case 'FAILED':
        return AppColors.danger;

      case 'CANCELED':
      case 'CANCELLED':
        return AppColors.textSecondary;

      default:
        return AppColors.warning;
    }
  }

  Widget _buildEncounterExaminationHistory(
    ExaminationEncounterUiModel encounter,
  ) {
    final items = _examinationsForEncounter(encounter);

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 14, color: AppColors.border),

        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 68,
                child: Text(
                  '검사 이력',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${items.length}건',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(left: 68, bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _examinationDisplayName(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _examinationStatusColor(
                      item.status,
                    ).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _examinationStatusLabel(item.status),
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: _examinationStatusColor(item.status),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPreviousEncounterCard() {
    final encounters = _previousEncounters.take(5).toList();

    String visitDateText(DateTime value) {
      final kst = value.toUtc().add(const Duration(hours: 9));

      final year = kst.year.toString();
      final month = kst.month.toString().padLeft(2, '0');
      final day = kst.day.toString().padLeft(2, '0');

      return '$year.$month.$day';
    }

    Widget buildDetailRow({required String label, required String value}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 68,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 9.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 10.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildStatusChip(ExaminationEncounterUiModel encounter) {
      final color = _statusColor(encounter.status);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _statusLabel(encounter.status),
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );
    }

    return _SectionCard(
      title: '내원 이력',
      icon: Icons.history_rounded,
      child: encounters.isEmpty
          ? const _EmptyMessage(text: '이전 내원 이력이 없습니다.')
          : Column(
              children: [
                for (var index = 0; index < encounters.length; index++)
                  Material(
                    color: Colors.transparent,
                    shape: Border(
                      bottom: index == encounters.length - 1
                          ? BorderSide.none
                          : const BorderSide(color: AppColors.border),
                    ),
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.transparent,
                        collapsedBackgroundColor: Colors.transparent,
                        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                        childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                        title: Row(
                          children: [
                            Text(
                              visitDateText(encounters[index].visitDate),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _encounterTypeLabel(
                                encounters[index].encounterType,
                              ),
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            buildStatusChip(encounters[index]),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
                            child: Column(
                              children: [
                                buildDetailRow(
                                  label: '진료 유형',
                                  value: _encounterTypeLabel(
                                    encounters[index].encounterType,
                                  ),
                                ),
                                buildDetailRow(
                                  label: '진료 시작',
                                  value: encounters[index].startedAt == null
                                      ? '-'
                                      : _formatDateTime(
                                          encounters[index].startedAt!,
                                        ),
                                ),
                                buildDetailRow(
                                  label: '진료 완료',
                                  value: encounters[index].completedAt == null
                                      ? '-'
                                      : _formatDateTime(
                                          encounters[index].completedAt!,
                                        ),
                                ),
                                buildDetailRow(
                                  label: '진료 결과',
                                  value: _normalizedText(
                                    encounters[index].outcome,
                                  ),
                                ),
                                _buildEncounterExaminationHistory(
                                  encounters[index],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  String _encounterTypeLabel(String value) {
    switch (value.toUpperCase()) {
      case 'INITIAL':
        return '초진';
      case 'FOLLOW_UP':
      case 'FOLLOWUP':
        return '재진';
      case 'EMERGENCY':
        return '응급';
      case 'INPATIENT':
        return '입원';
      case 'OUTPATIENT':
        return '외래';
      default:
        return value.isEmpty ? '-' : value;
    }
  }

  String _statusLabel(String value) {
    switch (value.toUpperCase()) {
      case 'WAITING':
        return '대기';
      case 'READY':
        return '진료 대기';
      case 'IN_PROGRESS':
        return '진료 중';
      case 'COMPLETED':
        return '진료 완료';
      case 'CANCELED':
      case 'CANCELLED':
        return '취소';
      default:
        return value.isEmpty ? '-' : value;
    }
  }

  Color _statusColor(String value) {
    switch (value.toUpperCase()) {
      case 'IN_PROGRESS':
        return AppColors.primaryBlue;
      case 'COMPLETED':
        return AppColors.success;
      case 'CANCELED':
      case 'CANCELLED':
        return AppColors.textSecondary;
      default:
        return AppColors.warning;
    }
  }

  String _normalizedText(String? value) {
    var normalized = value?.trim();

    if (normalized == null || normalized.isEmpty) {
      return '-';
    }

    normalized = normalized.replaceFirst(
      RegExp(
        r'^\s*(?:\[(?:SYNTHETIC|PROGRESSION)[^\]]*\]\s*)+',
        caseSensitive: false,
      ),
      '',
    );

    normalized = normalized.trim();

    if (normalized.isEmpty) {
      return '-';
    }

    return normalized;
  }

  String _formatDateTime(DateTime value) {
    final kst = value.toUtc().add(const Duration(hours: 9));

    final year = kst.year.toString();
    final month = kst.month.toString().padLeft(2, '0');
    final day = kst.day.toString().padLeft(2, '0');
    final hour = kst.hour.toString().padLeft(2, '0');
    final minute = kst.minute.toString().padLeft(2, '0');

    return '$year.$month.$day $hour:$minute';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? action;
  final double contentSpacing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.action,
    this.contentSpacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: AppColors.navy),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              ?action,
            ],
          ),
          SizedBox(height: contentSpacing),
          child,
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String text;

  const _EmptyMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 28,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          const Text(
            '진료 정보를 불러오지 못했습니다.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

class _VitalSignDraft {
  final int systolicBp;
  final int diastolicBp;
  final int pulseRate;
  final int respiratoryRate;

  final double bodyTemperature;
  final double oxygenSaturation;

  final double? heightCm;
  final double? weightKg;

  const _VitalSignDraft({
    required this.systolicBp,
    required this.diastolicBp,
    required this.pulseRate,
    required this.respiratoryRate,
    required this.bodyTemperature,
    required this.oxygenSaturation,
    required this.heightCm,
    required this.weightKg,
  });
}

class _MedicalHistoryDraft {
  final String conditionName;
  final String conditionCode;
  final DateTime? onsetDate;
  final String note;

  const _MedicalHistoryDraft({
    required this.conditionName,
    required this.conditionCode,
    required this.onsetDate,
    required this.note,
  });
}

class _AllergyDraft {
  final String allergenName;
  final String reaction;

  const _AllergyDraft({required this.allergenName, required this.reaction});
}

class _NumberInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;

  final bool integerOnly;
  final bool required;
  final double? minValue;
  final double? maxValue;

  const _NumberInput({
    required this.controller,
    required this.label,
    required this.suffix,
    this.integerOnly = false,
    this.required = false,
    this.minValue,
    this.maxValue,
  });

  String _validationNumber(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final normalized = value?.trim() ?? '';

        if (normalized.isEmpty) {
          return required ? '필수 입력' : null;
        }

        final parsed = double.tryParse(normalized);

        if (parsed == null) {
          return integerOnly ? '정수를 입력해 주세요.' : '숫자를 입력해 주세요.';
        }

        if (integerOnly && parsed != parsed.truncateToDouble()) {
          return '정수를 입력해 주세요.';
        }

        if (minValue != null && parsed < minValue!) {
          return '${_validationNumber(minValue!)} 이상으로 입력해 주세요.';
        }

        if (maxValue != null && parsed > maxValue!) {
          return '${_validationNumber(maxValue!)} 이하로 입력해 주세요.';
        }

        return null;
      },
    );
  }
}
