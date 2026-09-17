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

  const PatientCareTab({super.key, required this.patient});

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

      final medicalHistories = await careService.fetchMedicalHistories(
        widget.patient.patientId,
      );

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

      final allergies = await careService.fetchAllergies(
        widget.patient.patientId,
      );

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

      final encounters = await examinationService.fetchEncounters();

      final patientEncounters =
          encounters
              .where(
                (encounter) => encounter.patientId == widget.patient.patientId,
              )
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
        vitalSigns = await careService.fetchVitalSigns(mainEncounter.id);

        notes = await careService.fetchNotes(mainEncounter.id);

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

      if (!mounted) {
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
      if (!mounted) {
        return;
      }

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
        'patientId=${widget.patient.patientId}, '
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCurrentEncounterCard(),

        const SizedBox(height: 12),

        _buildVitalSignsCard(),

        const SizedBox(height: 12),

        _buildNotesCard(),

        const SizedBox(height: 12),

        _buildClinicalSummaryCard(),

        const SizedBox(height: 12),

        _buildPreviousEncounterCard(),
      ],
    );
  }

  Widget _buildCurrentEncounterCard() {
    final encounter = _mainEncounter;
    final auth = context.watch<AuthProvider>();
    final isDoctor = !auth.isNurse;

    final canStart =
        encounter != null &&
        isDoctor &&
        encounter.status.toUpperCase() == 'OPEN' &&
        encounter.startedAt == null &&
        encounter.completedAt == null;

    final canComplete =
        encounter != null &&
        isDoctor &&
        encounter.status.toUpperCase() == 'OPEN' &&
        encounter.startedAt != null &&
        encounter.completedAt == null;

    return _SectionCard(
      title: _activeEncounter != null ? '현재 진료' : '최근 진료',
      icon: Icons.medical_information_outlined,
      action: canStart
          ? FilledButton.icon(
              onPressed: _isUpdatingEncounter
                  ? null
                  : () {
                      _startEncounter(encounter);
                    },
              icon: const Icon(Icons.play_arrow_rounded, size: 15),
              label: Text(
                _isUpdatingEncounter ? '처리 중' : '진료 시작',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : canComplete
          ? FilledButton.icon(
              onPressed: _isUpdatingEncounter
                  ? null
                  : () {
                      _openCompleteEncounterDialog(encounter);
                    },
              icon: const Icon(Icons.check_rounded, size: 15),
              label: Text(
                _isUpdatingEncounter ? '처리 중' : '진료 완료',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
      child: encounter == null
          ? const _EmptyMessage(text: '등록된 진료 정보가 없습니다.')
          : Column(
              children: [
                _InfoRow(
                  label: '진료일',
                  value: _formatDateTime(encounter.visitDate),
                ),
                _InfoRow(
                  label: '진료 유형',
                  value: _encounterTypeLabel(encounter.encounterType),
                ),
                _InfoRow(
                  label: '진료 상태',
                  valueWidget: _StatusBadge(
                    text: _encounterStatusLabel(encounter),
                    color: _encounterStatusColor(encounter),
                  ),
                ),
                _InfoRow(label: '진료과', value: widget.patient.department),
                _InfoRow(label: '담당 의료진', value: widget.patient.doctorName),
                if (encounter.startedAt != null)
                  _InfoRow(
                    label: '진료 시작',
                    value: _formatDateTime(encounter.startedAt!),
                  ),
                if (encounter.completedAt != null)
                  _InfoRow(
                    label: '진료 완료',
                    value: _formatDateTime(encounter.completedAt!),
                  ),
                _InfoRow(
                  label: '진료 결과',
                  value: _normalizedText(encounter.outcome),
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

    return _SectionCard(
      title: '활력징후',
      icon: Icons.monitor_heart_outlined,
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
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (latest.measuredAt != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      '측정 ${_formatDateTime(latest.measuredAt!)}',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _VitalValue(
                      label: '혈압',
                      value:
                          '${latest.systolicBp ?? '-'}'
                          '/'
                          '${latest.diastolicBp ?? '-'}',
                      unit: 'mmHg',
                    ),
                    _VitalValue(
                      label: '맥박',
                      value: latest.pulseRate?.toString() ?? '-',
                      unit: 'bpm',
                    ),
                    _VitalValue(
                      label: '호흡수',
                      value: latest.respiratoryRate?.toString() ?? '-',
                      unit: '/min',
                    ),
                    _VitalValue(
                      label: '체온',
                      value: _formatNumber(latest.bodyTemperature),
                      unit: '℃',
                    ),
                    _VitalValue(
                      label: 'SpO₂',
                      value: _formatNumber(latest.oxygenSaturation),
                      unit: '%',
                    ),
                    if (latest.heightCm != null)
                      _VitalValue(
                        label: '키',
                        value: _formatNumber(latest.heightCm),
                        unit: 'cm',
                      ),
                    if (latest.weightKg != null)
                      _VitalValue(
                        label: '체중',
                        value: _formatNumber(latest.weightKg),
                        unit: 'kg',
                      ),
                  ],
                ),
              ],
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
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _NumberInput(
                            controller: oxygenController,
                            label: '산소포화도',
                            suffix: '%',
                            required: true,
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
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _NumberInput(
                            controller: weightController,
                            label: '체중',
                            suffix: 'kg',
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

                Navigator.pop(
                  dialogContext,
                  _VitalSignDraft(
                    systolicBp: int.parse(systolicController.text.trim()),
                    diastolicBp: int.parse(diastolicController.text.trim()),
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

  Widget _buildClinicalSummaryCard() {
    final auth = context.watch<AuthProvider>();

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
                  icon: const Icon(Icons.add_rounded, size: 15),
                  label: Text(
                    _isSavingMedicalHistory ? '저장 중' : '과거력 추가',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: _isSavingAllergy ? null : _openAllergyDialog,
                  icon: const Icon(Icons.add_rounded, size: 15),
                  label: Text(
                    _isSavingAllergy ? '저장 중' : '알레르기 추가',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
      child: Column(
        children: [
          _InfoRow(label: '과거력', value: _medicalHistorySummary()),
          _InfoRow(label: '주요 진단', value: widget.patient.primaryDiagnosis),
          _InfoRow(label: '알레르기', value: _allergySummary()),
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

          return '$name ($year.$month.$day~)';
        })
        .join(', ');
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
        .join(', ');
  }

  Widget _buildPreviousEncounterCard() {
    final encounters = _previousEncounters;

    return _SectionCard(
      title: '이전 진료',
      icon: Icons.history_rounded,
      child: encounters.isEmpty
          ? const _EmptyMessage(text: '이전 진료기록이 없습니다.')
          : Column(
              children: encounters.take(5).map((encounter) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDateTime(encounter.visitDate),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _encounterTypeLabel(encounter.encounterType),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusBadge(
                        text: _statusLabel(encounter.status),
                        color: _statusColor(encounter.status),
                      ),
                    ],
                  ),
                );
              }).toList(),
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

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.action,
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
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;

  const _InfoRow({required this.label, this.value, this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child:
                valueWidget ??
                Text(
                  value ?? '-',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
          ),
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

class _VitalValue extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _VitalValue({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 8.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumberInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;

  final bool integerOnly;
  final bool required;
  final double? maxValue;

  const _NumberInput({
    required this.controller,
    required this.label,
    required this.suffix,
    this.integerOnly = false,
    this.required = false,
    this.maxValue,
  });

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

        if (integerOnly) {
          final parsed = int.tryParse(normalized);

          if (parsed == null) {
            return '정수를 입력해 주세요.';
          }

          if (parsed <= 0) {
            return '0보다 큰 값을 입력해 주세요.';
          }

          if (maxValue != null && parsed > maxValue!) {
            return '${maxValue!.toInt()} 이하로 입력해 주세요.';
          }

          return null;
        }

        final parsed = double.tryParse(normalized);

        if (parsed == null) {
          return '숫자를 입력해 주세요.';
        }

        if (parsed <= 0) {
          return '0보다 큰 값을 입력해 주세요.';
        }

        if (maxValue != null && parsed > maxValue!) {
          return '${maxValue!.toInt()} 이하로 입력해 주세요.';
        }

        return null;
      },
    );
  }
}
