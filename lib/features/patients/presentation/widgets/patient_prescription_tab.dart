import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../examinations/data/services/examination_service.dart';
import '../../data/services/patient_prescription_service.dart';
import 'patient_detail_tabs.dart';
import 'prescription_sign_dialog.dart';

class PatientPrescriptionTab extends StatefulWidget {
  final PatientUiModel patient;

  const PatientPrescriptionTab({super.key, required this.patient});

  @override
  State<PatientPrescriptionTab> createState() => _PatientPrescriptionTabState();
}

class _PatientPrescriptionTabState extends State<PatientPrescriptionTab> {
  List<PatientPrescriptionDetail> _prescriptions = [];

  bool _isLoading = true;
  String? _loadError;
  bool _isCreatingPrescription = false;
  int? _runningDurCheckPrescriptionId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPrescriptions();
    });
  }

  @override
  void didUpdateWidget(covariant PatientPrescriptionTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.patient.patientId != widget.patient.patientId) {
      _loadPrescriptions();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  Future<void> _loadPrescriptions() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final auth = context.read<AuthProvider>();

      final service = PatientPrescriptionService(
        apiClient: auth.authService.apiClient,
      );

      final summaries = await service.fetchPrescriptions(
        widget.patient.patientId,
      );

      final details = await Future.wait(
        summaries.map(
          (prescription) => service.fetchPrescriptionDetail(prescription.id),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _prescriptions = details;
        _isLoading = false;
        _loadError = null;
      });
    } catch (error) {
      debugPrint(
        '[PatientPrescriptionTab] 처방 조회 실패: '
        'patientId=${widget.patient.patientId}, error=$error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _prescriptions = [];
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  Future<void> _openCreatePrescriptionDialog() async {
    final notesController = TextEditingController();

    final notes = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            '처방 추가',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 460,
            child: TextField(
              controller: notesController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '처방 메모',
                hintText: '처방 관련 메모를 입력해 주세요.',
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
                Navigator.pop(dialogContext, notesController.text.trim());
              },
              child: const Text('처방 생성'),
            ),
          ],
        );
      },
    );

    if (notes == null || !mounted) {
      return;
    }

    await _createPrescription(notes);
  }

  Future<void> _createPrescription(String notes) async {
    setState(() {
      _isCreatingPrescription = true;
    });

    try {
      final auth = context.read<AuthProvider>();

      final examinationService = ExaminationService(
        apiClient: auth.authService.apiClient,
      );

      final prescriptionService = PatientPrescriptionService(
        apiClient: auth.authService.apiClient,
      );

      final encounters = await examinationService.fetchEncounters();

      final patientEncounters =
          encounters
              .where(
                (encounter) => encounter.patientId == widget.patient.patientId,
              )
              .toList()
            ..sort((a, b) => b.visitDate.compareTo(a.visitDate));

      if (patientEncounters.isEmpty) {
        if (mounted) {
          _showMessage('진료 정보가 없어 처방을 생성할 수 없습니다.');
        }

        return;
      }

      final encounter = patientEncounters.first;

      await prescriptionService.createPrescription(
        encounterId: encounter.id,
        patientId: widget.patient.patientId,
        notes: notes,
      );

      if (!mounted) {
        return;
      }

      await _loadPrescriptions();

      if (mounted) {
        _showMessage('처방 초안이 생성되었습니다.');
      }
    } catch (error) {
      debugPrint('[PatientPrescriptionTab] 처방 생성 실패: $error');

      if (mounted) {
        _showMessage('처방을 생성하지 못했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingPrescription = false;
        });
      }
    }
  }

  Future<void> _openAddMedicationDialog(int prescriptionId) async {
    final auth = context.read<AuthProvider>();

    final service = PatientPrescriptionService(
      apiClient: auth.authService.apiClient,
    );

    final added = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _MedicationAddDialog(
          service: service,
          prescriptionId: prescriptionId,
        );
      },
    );

    if (added != true || !mounted) {
      return;
    }

    await _loadPrescriptions();

    if (mounted) {
      _showMessage('처방 약물이 추가되었습니다.');
    }
  }

  Future<void> _runDurCheck(int prescriptionId) async {
    setState(() {
      _runningDurCheckPrescriptionId = prescriptionId;
    });

    try {
      final auth = context.read<AuthProvider>();

      final service = PatientPrescriptionService(
        apiClient: auth.authService.apiClient,
      );

      final result = await service.runDurCheck(prescriptionId);

      if (!mounted) {
        return;
      }

      await _loadPrescriptions();

      if (!mounted) {
        return;
      }

      final status = result.status.toUpperCase();

      switch (status) {
        case 'PASSED':
          _showMessage('DUR 검사를 통과했습니다.');
          break;

        case 'WARNING':
          _showMessage('DUR 경고가 확인되었습니다.');
          break;

        case 'FAILED':
          _showMessage('DUR 검사에서 확인이 필요한 항목이 있습니다.');
          break;

        default:
          _showMessage('DUR 검사가 완료되었습니다.');
      }
    } catch (error) {
      debugPrint('[PatientPrescriptionTab] DUR 검사 실패: $error');

      if (mounted) {
        _showMessage('DUR 검사를 실행하지 못했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _runningDurCheckPrescriptionId = null;
        });
      }
    }
  }

  Future<void> _openSignPrescriptionDialog(int prescriptionId) async {
    final auth = context.read<AuthProvider>();

    final service = PatientPrescriptionService(
      apiClient: auth.authService.apiClient,
    );

    final signed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PrescriptionSignDialog(
          service: service,
          prescriptionId: prescriptionId,
        );
      },
    );

    if (signed != true || !mounted) {
      return;
    }

    await _loadPrescriptions();

    if (mounted) {
      _showMessage('처방 서명이 완료되었습니다.');
    }
  }

  bool _canSignPrescription(PatientPrescriptionDetail detail) {
    if (detail.prescription.status.toUpperCase() != 'DRAFT') {
      return false;
    }

    if (detail.items.isEmpty || detail.durChecks.isEmpty) {
      return false;
    }

    final checks = [...detail.durChecks]
      ..sort((a, b) {
        final aDate = a.checkedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.checkedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

    return checks.first.status.toUpperCase() == 'PASSED';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '처방 정보를 불러오지 못했습니다.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _loadPrescriptions,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    final auth = context.watch<AuthProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '처방 이력',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (!auth.isNurse)
                TextButton.icon(
                  onPressed: _isCreatingPrescription
                      ? null
                      : _openCreatePrescriptionDialog,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(
                    _isCreatingPrescription ? '등록 중' : '처방 추가',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _prescriptions.isEmpty
              ? const Center(
                  child: Text(
                    '등록된 처방이 없습니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _prescriptions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final detail = _prescriptions[index];

                    return _PrescriptionCard(
                      detail: detail,
                      canAddMedication:
                          !auth.isNurse &&
                          detail.prescription.status.toUpperCase() == 'DRAFT',
                      canRunDurCheck:
                          !auth.isNurse &&
                          detail.prescription.status.toUpperCase() == 'DRAFT' &&
                          detail.items.isNotEmpty,
                      canSign: !auth.isNurse && _canSignPrescription(detail),
                      isRunningDurCheck:
                          _runningDurCheckPrescriptionId ==
                          detail.prescription.id,
                      onAddMedication: () {
                        _openAddMedicationDialog(detail.prescription.id);
                      },
                      onRunDurCheck: () {
                        _runDurCheck(detail.prescription.id);
                      },
                      onSign: () {
                        _openSignPrescriptionDialog(detail.prescription.id);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final PatientPrescriptionDetail detail;

  final bool canAddMedication;
  final bool canRunDurCheck;
  final bool canSign;
  final bool isRunningDurCheck;

  final VoidCallback onAddMedication;
  final VoidCallback onRunDurCheck;
  final VoidCallback onSign;

  const _PrescriptionCard({
    required this.detail,
    required this.canAddMedication,
    required this.canRunDurCheck,
    required this.canSign,
    required this.isRunningDurCheck,
    required this.onAddMedication,
    required this.onRunDurCheck,
    required this.onSign,
  });

  @override
  Widget build(BuildContext context) {
    final prescription = detail.prescription;

    final durChecks = [...detail.durChecks]
      ..sort((a, b) {
        final aDate = a.checkedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.checkedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

    final latestDurCheck = durChecks.isEmpty ? null : durChecks.first;

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
              Expanded(
                child: Text(
                  _formatDate(prescription.prescribedAt),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _PrescriptionStatusBadge(status: prescription.status),
            ],
          ),

          if (prescription.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              prescription.notes,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],

          const SizedBox(height: 12),

          if (detail.items.isEmpty)
            const Text(
              '등록된 처방 약물이 없습니다.',
              style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
            )
          else
            ...detail.items.map((item) => _PrescriptionItemCard(item: item)),

          if (canAddMedication || canRunDurCheck || canSign) ...[
            const SizedBox(height: 6),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (canAddMedication)
                  TextButton.icon(
                    onPressed: onAddMedication,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text(
                      '약물 추가',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                if (canRunDurCheck) ...[
                  const SizedBox(width: 6),
                  OutlinedButton.icon(
                    onPressed: isRunningDurCheck ? null : onRunDurCheck,
                    icon: isRunningDurCheck
                        ? const SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.health_and_safety_outlined,
                            size: 15,
                          ),
                    label: Text(
                      isRunningDurCheck ? '검사 중' : 'DUR 검사',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],

                if (canSign) ...[
                  const SizedBox(width: 6),
                  FilledButton.icon(
                    onPressed: onSign,
                    icon: const Icon(Icons.draw_outlined, size: 15),
                    label: const Text(
                      '처방 서명',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],

          if (latestDurCheck != null) ...[
            const SizedBox(height: 10),
            _DurStatusRow(status: latestDurCheck.status),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '처방일 정보 없음';
    }

    final kst = value.toUtc().add(const Duration(hours: 9));

    final year = kst.year.toString();
    final month = kst.month.toString().padLeft(2, '0');
    final day = kst.day.toString().padLeft(2, '0');

    return '$year.$month.$day';
  }
}

class _MedicationAddDialog extends StatefulWidget {
  final PatientPrescriptionService service;
  final int prescriptionId;

  const _MedicationAddDialog({
    required this.service,
    required this.prescriptionId,
  });

  @override
  State<_MedicationAddDialog> createState() => _MedicationAddDialogState();
}

class _MedicationAddDialogState extends State<_MedicationAddDialog> {
  final _searchController = TextEditingController();
  final _doseController = TextEditingController();
  final _doseUnitController = TextEditingController(text: 'mg');
  final _frequencyController = TextEditingController(text: '1');
  final _durationController = TextEditingController(text: '7');
  final _instructionsController = TextEditingController();
  final _noteController = TextEditingController();

  List<PrescriptionMedication> _searchResults = [];

  PrescriptionMedication? _selectedMedication;

  String _route = 'PO';

  bool _isSearching = false;
  bool _isSaving = false;

  String? _searchError;

  @override
  void dispose() {
    _searchController.dispose();
    _doseController.dispose();
    _doseUnitController.dispose();
    _frequencyController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    _noteController.dispose();

    super.dispose();
  }

  Future<void> _searchMedications() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _searchError = '검색할 약품명을 입력해 주세요.';
      });

      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final results = await widget.service.searchMedications(query);

      if (!mounted) {
        return;
      }

      setState(() {
        _searchResults = results;

        if (results.isEmpty) {
          _searchError = '검색된 약품이 없습니다.';
        }
      });
    } catch (error) {
      debugPrint('[MedicationAddDialog] 약품 검색 실패: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _searchResults = [];
        _searchError = '약품을 검색하지 못했습니다.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _saveMedication() async {
    final medication = _selectedMedication;

    if (medication == null) {
      _showError('추가할 약품을 선택해 주세요.');
      return;
    }

    final doseValue = double.tryParse(_doseController.text.trim());

    if (doseValue == null || doseValue <= 0) {
      _showError('올바른 투여 용량을 입력해 주세요.');
      return;
    }

    final doseUnit = _doseUnitController.text.trim();

    if (doseUnit.isEmpty) {
      _showError('용량 단위를 입력해 주세요.');
      return;
    }

    final frequencyPerDay = int.tryParse(_frequencyController.text.trim());

    if (frequencyPerDay == null || frequencyPerDay <= 0) {
      _showError('1일 복용 횟수를 입력해 주세요.');
      return;
    }

    final durationDays = int.tryParse(_durationController.text.trim());

    if (durationDays == null || durationDays <= 0) {
      _showError('복용 기간을 입력해 주세요.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final startDate = DateTime.now();

      final endDate = startDate.add(Duration(days: durationDays - 1));

      await widget.service.createPrescriptionItem(
        prescriptionId: widget.prescriptionId,
        medicationId: medication.id,
        doseValue: doseValue,
        doseUnit: doseUnit,
        frequencyPerDay: frequencyPerDay,
        durationDays: durationDays,
        route: _route,
        instructions: _instructionsController.text,
        note: _noteController.text,
        startDate: startDate,
        endDate: endDate,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      debugPrint('[MedicationAddDialog] 처방 약물 추가 실패: $error');

      if (mounted) {
        _showError('처방 약물을 추가하지 못했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        '처방 약물 추가',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      enabled: !_isSaving,
                      onSubmitted: (_) {
                        _searchMedications();
                      },
                      decoration: const InputDecoration(
                        labelText: '약품 검색',
                        hintText: '예: 심콜',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isSearching || _isSaving
                        ? null
                        : _searchMedications,
                    child: _isSearching
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('검색'),
                  ),
                ],
              ),
              if (_searchError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _searchError!,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.danger,
                  ),
                ),
              ],
              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final medication = _searchResults[index];

                      final selected = _selectedMedication?.id == medication.id;

                      return ListTile(
                        dense: true,
                        selected: selected,
                        title: Text(
                          medication.name,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          [
                            if (medication.manufacturer.trim().isNotEmpty)
                              medication.manufacturer,
                            if (medication.ingredient.trim().isNotEmpty)
                              medication.ingredient,
                          ].join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 9.5),
                        ),
                        trailing: selected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                                size: 20,
                              )
                            : null,
                        onTap: _isSaving
                            ? null
                            : () {
                                setState(() {
                                  _selectedMedication = medication;
                                });
                              },
                      );
                    },
                  ),
                ),
              ],
              if (_selectedMedication != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.medication_outlined,
                        size: 18,
                        color: AppColors.navy,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedMedication!.name,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _doseController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: '1회 용량',
                          hintText: '20',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _doseUnitController,
                        decoration: const InputDecoration(
                          labelText: '단위',
                          hintText: 'mg',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _frequencyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '1일 횟수',
                          hintText: '1',
                          suffixText: '회',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '복용 기간',
                          hintText: '7',
                          suffixText: '일',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _route,
                  decoration: const InputDecoration(
                    labelText: '투여 경로',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'PO', child: Text('경구 (PO)')),
                    DropdownMenuItem(value: 'IV', child: Text('정맥주사 (IV)')),
                    DropdownMenuItem(value: 'IM', child: Text('근육주사 (IM)')),
                    DropdownMenuItem(value: 'SC', child: Text('피하주사 (SC)')),
                  ],
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _route = value;
                          });
                        },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _instructionsController,
                  decoration: const InputDecoration(
                    labelText: '복약 지시',
                    hintText: '예: 1일 1회 복용',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _noteController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: '약물 메모',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () {
                  Navigator.of(context).pop(false);
                },
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _selectedMedication == null || _isSaving
              ? null
              : _saveMedication,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('약물 추가'),
        ),
      ],
    );
  }
}

class _PrescriptionItemCard extends StatelessWidget {
  final PatientPrescriptionItem item;

  const _PrescriptionItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final medicationName = item.medication.name.trim().isEmpty
        ? '약물 정보 없음'
        : item.medication.name;

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
          Text(
            medicationName,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _buildDoseSummary(item),
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
          ),
          if (item.instructions.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              item.instructions,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _buildDoseSummary(PatientPrescriptionItem item) {
    final values = <String>[];

    final dose = _normalizedDose(item.doseValue);

    if (dose.isNotEmpty || item.doseUnit.trim().isNotEmpty) {
      values.add('${dose.isEmpty ? '-' : dose} ${item.doseUnit}'.trim());
    }

    if (item.frequencyPerDay != null) {
      values.add('1일 ${item.frequencyPerDay}회');
    }

    if (item.durationDays != null) {
      values.add('${item.durationDays}일');
    }

    if (item.route.trim().isNotEmpty) {
      values.add(_routeLabel(item.route));
    }

    return values.isEmpty ? '-' : values.join(' · ');
  }

  String _normalizedDose(String value) {
    final parsed = double.tryParse(value);

    if (parsed == null) {
      return value.trim();
    }

    if (parsed == parsed.roundToDouble()) {
      return parsed.toInt().toString();
    }

    return parsed.toString();
  }

  String _routeLabel(String route) {
    switch (route.toUpperCase()) {
      case 'PO':
        return '경구(PO)';
      case 'IV':
        return '정맥주사(IV)';
      case 'IM':
        return '근육주사(IM)';
      case 'SC':
      case 'SQ':
        return '피하주사(${route.toUpperCase()})';
      default:
        return route;
    }
  }
}

class _DurStatusRow extends StatelessWidget {
  final String status;

  const _DurStatusRow({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.toUpperCase();

    final text = switch (normalizedStatus) {
      'PASSED' => '통과',
      'WARNING' => '경고',
      'FAILED' => '실패',
      'PENDING' => '검사 중',
      _ => status.isEmpty ? '-' : status,
    };

    final color = switch (normalizedStatus) {
      'PASSED' => AppColors.success,
      'WARNING' => AppColors.warning,
      'FAILED' => AppColors.danger,
      _ => AppColors.textSecondary,
    };

    return Row(
      children: [
        const Text(
          'DUR 검사',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _PrescriptionStatusBadge extends StatelessWidget {
  final String status;

  const _PrescriptionStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.toUpperCase();

    final text = switch (normalizedStatus) {
      'DRAFT' => '초안',
      'SIGNED' => '서명 완료',
      'CANCELED' => '취소',
      'CANCELLED' => '취소',
      _ => status.isEmpty ? '-' : status,
    };

    final color = switch (normalizedStatus) {
      'SIGNED' => AppColors.success,
      'DRAFT' => AppColors.warning,
      'CANCELED' || 'CANCELLED' => AppColors.danger,
      _ => AppColors.textSecondary,
    };

    return Container(
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
    );
  }
}
