import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../examination_ui_models.dart';

typedef ExaminationOrderCreateCallback =
    Future<ExaminationOrderUiModel?> Function({
      required int encounterId,
      required int examinationTypeId,
      required String priority,
      required String clinicalNote,
    });

class ExaminationOrderComposer extends StatefulWidget {
  final List<ExaminationPatientUiModel> patients;
  final List<ExaminationEncounterUiModel> encounters;
  final List<ExaminationTypeUiModel> types;

  final int? initialPatientId;
  final int? initialEncounterId;
  final bool lockPatientSelection;
  final bool dialogMode;

  final ExaminationOrderCreateCallback onSubmit;
  final ValueChanged<ExaminationOrderUiModel> onCreated;
  final VoidCallback onCancel;

  const ExaminationOrderComposer({
    super.key,
    required this.patients,
    required this.encounters,
    required this.types,
    required this.initialPatientId,
    required this.initialEncounterId,
    required this.lockPatientSelection,
    required this.onSubmit,
    required this.onCreated,
    required this.onCancel,
    this.dialogMode = false,
  });

  @override
  State<ExaminationOrderComposer> createState() =>
      _ExaminationOrderComposerState();
}

class _ExaminationOrderComposerState extends State<ExaminationOrderComposer> {
  int? _selectedPatientId;
  int? _selectedEncounterId;
  int? _selectedTypeId;

  String _selectedPriority = 'NORMAL';
  String _clinicalNote = '';

  bool _isSubmitting = false;
  String? _submitError;

  List<ExaminationPatientUiModel> get _availablePatients {
    final patientIds = widget.encounters
        .map((encounter) => encounter.patientId)
        .toSet();

    final result = widget.patients
        .where((patient) => patientIds.contains(patient.id))
        .toList();

    result.sort((a, b) => a.name.compareTo(b.name));

    return result;
  }

  List<ExaminationTypeUiModel> get _availableTypes {
    const visibleCodes = ['BLOOD', 'ANGIOGRAPHY', 'CCTA'];

    final activeTypes = {
      for (final type in widget.types)
        if (type.isActive) type.code: type,
    };

    return visibleCodes
        .map((code) => activeTypes[code])
        .whereType<ExaminationTypeUiModel>()
        .toList();
  }

  @override
  void initState() {
    super.initState();

    final availablePatients = _availablePatients;

    if (widget.initialPatientId != null &&
        availablePatients.any(
          (patient) => patient.id == widget.initialPatientId,
        )) {
      _selectedPatientId = widget.initialPatientId;
    }

    _syncEncounter(preferredEncounterId: widget.initialEncounterId);

    final availableTypes = _availableTypes;

    if (availableTypes.isNotEmpty) {
      _selectedTypeId = availableTypes.first.id;
    }
  }

  List<ExaminationEncounterUiModel> _encountersForPatient(int patientId) {
    final result = widget.encounters
        .where((encounter) => encounter.patientId == patientId)
        .toList();

    result.sort((a, b) => b.visitDate.compareTo(a.visitDate));

    return result;
  }

  void _syncEncounter({int? preferredEncounterId}) {
    final patientId = _selectedPatientId;

    if (patientId == null) {
      _selectedEncounterId = null;
      return;
    }

    final encounters = _encountersForPatient(patientId);

    if (encounters.isEmpty) {
      _selectedEncounterId = null;
      return;
    }

    if (preferredEncounterId != null &&
        encounters.any((encounter) => encounter.id == preferredEncounterId)) {
      _selectedEncounterId = preferredEncounterId;
      return;
    }

    _selectedEncounterId = encounters.first.id;
  }

  ExaminationPatientUiModel? get _selectedPatient {
    final patientId = _selectedPatientId;

    if (patientId == null) {
      return null;
    }

    for (final patient in widget.patients) {
      if (patient.id == patientId) {
        return patient;
      }
    }

    return null;
  }

  ExaminationEncounterUiModel? get _selectedEncounter {
    final encounterId = _selectedEncounterId;

    if (encounterId == null) {
      return null;
    }

    for (final encounter in widget.encounters) {
      if (encounter.id == encounterId) {
        return encounter;
      }
    }

    return null;
  }

  Future<void> _submit() async {
    if (_selectedPatientId == null) {
      setState(() {
        _submitError = '환자를 선택해 주세요.';
      });
      return;
    }

    if (_selectedEncounterId == null) {
      setState(() {
        _submitError = '연결 가능한 진료 기록이 없습니다.';
      });
      return;
    }

    if (_selectedTypeId == null) {
      setState(() {
        _submitError = '검사 종류를 선택해 주세요.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final createdOrder = await widget.onSubmit(
      encounterId: _selectedEncounterId!,
      examinationTypeId: _selectedTypeId!,
      priority: _selectedPriority,
      clinicalNote: _clinicalNote,
    );

    if (!mounted) {
      return;
    }

    if (createdOrder == null) {
      setState(() {
        _isSubmitting = false;
        _submitError = '검사 오더를 생성하지 못했습니다.';
      });
      return;
    }

    widget.onCreated(createdOrder);
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year.$month.$day';
  }

  String _typeDisplayName(ExaminationTypeUiModel type) {
    switch (type.code.trim().toUpperCase()) {
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
        return type.name.trim().isEmpty ? type.code : type.name;
    }
  }

  Widget _buildFormContent({required bool showTypeCode}) {
    final patient = _selectedPatient;
    final encounter = _selectedEncounter;
    final availableTypes = _availableTypes;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('환자'),
        const SizedBox(height: 7),

        _PatientSelector(
          patient: patient,
          encounterText: encounter == null
              ? null
              : '최근 진료  '
                    '${_formatDate(encounter.visitDate)}'
                    ' · 진료 #${encounter.id}'
                    ' · ${encounter.status}',
          patients: _availablePatients,
          enabled: !_isSubmitting,
          locked: widget.lockPatientSelection,
          onSelected: (selectedPatient) {
            setState(() {
              _selectedPatientId = selectedPatient.id;
              _syncEncounter();
              _submitError = null;
            });
          },
        ),

        const SizedBox(height: 18),

        Row(
          children: [
            const _SectionTitle('우선순위'),
            const Spacer(),

            _PrioritySegment(
              label: '일반',
              selected: _selectedPriority == 'NORMAL',
              urgent: false,
              onTap: _isSubmitting
                  ? null
                  : () {
                      setState(() {
                        _selectedPriority = 'NORMAL';
                      });
                    },
            ),

            const SizedBox(width: 6),

            _PrioritySegment(
              label: '긴급',
              selected: _selectedPriority == 'URGENT',
              urgent: true,
              onTap: _isSubmitting
                  ? null
                  : () {
                      setState(() {
                        _selectedPriority = 'URGENT';
                      });
                    },
            ),
          ],
        ),

        const SizedBox(height: 18),

        const _SectionTitle('검사 항목'),
        const SizedBox(height: 7),

        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var index = 0; index < availableTypes.length; index++)
                _ExaminationTypeRow(
                  type: availableTypes[index],
                  displayName: _typeDisplayName(availableTypes[index]),
                  selected: availableTypes[index].id == _selectedTypeId,
                  enabled: !_isSubmitting,
                  showCode: showTypeCode,
                  showBottomBorder: index != availableTypes.length - 1,
                  onTap: () {
                    setState(() {
                      _selectedTypeId = availableTypes[index].id;
                      _submitError = null;
                    });
                  },
                ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        const _SectionTitle('검사 메모'),
        const SizedBox(height: 7),

        TextFormField(
          enabled: !_isSubmitting,
          minLines: 3,
          maxLines: 4,
          onChanged: (value) {
            _clinicalNote = value;
          },
          decoration: const InputDecoration(
            hintText: '검사 목적이나 참고사항을 입력하세요.',
            border: OutlineInputBorder(),
          ),
        ),

        if (_submitError != null) ...[
          const SizedBox(height: 10),
          Text(
            _submitError!,
            style: const TextStyle(fontSize: 10.5, color: Colors.red),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return FilledButton.icon(
      onPressed: _isSubmitting ? null : _submit,
      style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
      icon: _isSubmitting
          ? const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.add_rounded, size: 16),
      label: Text(_isSubmitting ? '생성 중...' : '오더 생성'),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dialogMode) {
      return AlertDialog(
        title: const Text(
          '검사 오더 추가',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: _buildFormContent(showTypeCode: false),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : widget.onCancel,
            child: const Text('취소'),
          ),
          _buildSubmitButton(),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '검사 오더 추가',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '닫기',
                  onPressed: _isSubmitting ? null : widget.onCancel,
                  icon: const Icon(Icons.close_rounded, size: 19),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              child: _buildFormContent(showTypeCode: true),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSubmitting ? null : widget.onCancel,
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                _buildSubmitButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientSelector extends StatefulWidget {
  final ExaminationPatientUiModel? patient;
  final String? encounterText;

  final List<ExaminationPatientUiModel> patients;

  final bool enabled;
  final bool locked;

  final ValueChanged<ExaminationPatientUiModel> onSelected;

  const _PatientSelector({
    required this.patient,
    required this.encounterText,
    required this.patients,
    required this.enabled,
    required this.locked,
    required this.onSelected,
  });

  @override
  State<_PatientSelector> createState() => _PatientSelectorState();
}

class _PatientSelectorState extends State<_PatientSelector> {
  final LayerLink _layerLink = LayerLink();

  final GlobalKey _targetKey = GlobalKey();

  final TextEditingController _searchController = TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();

  OverlayEntry? _overlayEntry;

  String _searchText = '';

  bool get _isOpen => _overlayEntry != null;

  List<ExaminationPatientUiModel> get _filteredPatients {
    final query = _searchText.trim().toLowerCase();

    if (query.isEmpty) {
      return widget.patients.take(4).toList();
    }

    return widget.patients
        .where((patient) {
          final searchable =
              '${patient.name} '
                      '${patient.id} '
                      '${patient.age} '
                      '${patient.gender}'
                  .toLowerCase();

          return searchable.contains(query);
        })
        .take(8)
        .toList();
  }

  @override
  void didUpdateWidget(covariant _PatientSelector oldWidget) {
    super.didUpdateWidget(oldWidget);

    if ((!widget.enabled || widget.locked) && _isOpen) {
      _closeOverlay();
    }
  }

  @override
  void dispose() {
    _removeOverlay();

    _searchController.dispose();
    _searchFocusNode.dispose();

    super.dispose();
  }

  void _toggleOverlay() {
    if (!widget.enabled || widget.locked) {
      return;
    }

    if (_isOpen) {
      _closeOverlay();
    } else {
      _openOverlay();
    }
  }

  void _openOverlay() {
    if (_isOpen) {
      return;
    }

    final targetContext = _targetKey.currentContext;

    if (targetContext == null) {
      return;
    }

    final renderBox = targetContext.findRenderObject() as RenderBox?;

    if (renderBox == null) {
      return;
    }

    final targetSize = renderBox.size;

    _searchText = '';
    _searchController.clear();

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        final patients = _filteredPatients;

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeOverlay,
                child: const SizedBox.expand(),
              ),
            ),

            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, targetSize.height + 4),
              child: SizedBox(
                width: targetSize.width,
                child: Material(
                  color: AppColors.surface,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 42,
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: (value) {
                              _searchText = value;

                              _overlayEntry?.markNeedsBuild();
                            },
                            style: const TextStyle(fontSize: 10.5),
                            decoration: const InputDecoration(
                              hintText: '환자 이름 또는 ID 검색',
                              prefixIcon: Icon(Icons.search_rounded, size: 17),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 11,
                              ),
                            ),
                          ),
                        ),

                        const Divider(height: 1, color: AppColors.border),

                        if (patients.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              '검색 결과가 없습니다.',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        else
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 176),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: patients.length,
                              separatorBuilder: (context, index) {
                                return const Divider(
                                  height: 1,
                                  color: AppColors.border,
                                );
                              },
                              itemBuilder: (context, index) {
                                final patient = patients[index];

                                final selected =
                                    patient.id == widget.patient?.id;

                                return InkWell(
                                  onTap: () {
                                    widget.onSelected(patient);

                                    _closeOverlay();
                                  },
                                  child: Container(
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    color: selected
                                        ? AppColors.surfaceSoft
                                        : AppColors.surface,
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          child: selected
                                              ? const Icon(
                                                  Icons.check_rounded,
                                                  size: 15,
                                                  color: AppColors.navy,
                                                )
                                              : null,
                                        ),

                                        const SizedBox(width: 4),

                                        Expanded(
                                          child: Text(
                                            patient.name,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: selected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),

                                        Text(
                                          '${patient.age}세 · '
                                          '${patient.gender} · '
                                          '#${patient.id}',
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);

    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isOpen) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _closeOverlay() {
    if (!_isOpen) {
      return;
    }

    _removeOverlay();

    if (mounted) {
      setState(() {});
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;

    _searchText = '';
    _searchController.clear();
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Material(
        key: _targetKey,
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.locked ? null : _toggleOverlay,
          borderRadius: BorderRadius.circular(7),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: patient == null ? 44 : 54),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: _isOpen ? AppColors.primaryBlue : AppColors.border,
              ),
            ),
            child: patient == null
                ? Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        size: 17,
                        color: AppColors.textSecondary,
                      ),

                      const SizedBox(width: 9),

                      const Expanded(
                        child: Text(
                          '환자를 선택하세요',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),

                      if (!widget.locked)
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  patient.name,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),

                                const SizedBox(width: 8),

                                Text(
                                  '${patient.age}세 · '
                                  '${patient.gender} · '
                                  '#${patient.id}',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 3),

                            Text(
                              widget.encounterText ?? '연결 가능한 최근 진료 없음',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      Icon(
                        widget.locked
                            ? Icons.lock_outline_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ExaminationTypeRow extends StatelessWidget {
  final ExaminationTypeUiModel type;
  final String displayName;

  final bool selected;
  final bool enabled;
  final bool showCode;
  final bool showBottomBorder;

  final VoidCallback onTap;

  const _ExaminationTypeRow({
    required this.type,
    required this.displayName,
    required this.selected,
    required this.enabled,
    required this.showCode,
    required this.showBottomBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceSoft : AppColors.surface,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected ? AppColors.navy : Colors.transparent,
                width: 3,
              ),
              bottom: showBottomBorder
                  ? const BorderSide(color: AppColors.border)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 16,
                color: selected ? AppColors.navy : AppColors.textSecondary,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  displayName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (showCode) ...[
                const SizedBox(width: 8),
                Text(
                  type.code,
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PrioritySegment extends StatelessWidget {
  final String label;
  final bool selected;
  final bool urgent;
  final VoidCallback? onTap;

  const _PrioritySegment({
    required this.label,
    required this.selected,
    required this.urgent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBackground = urgent
        ? const Color(0xFFFFF1F1)
        : AppColors.surfaceSoft;

    final selectedBorder = urgent ? const Color(0xFFE57373) : AppColors.navy;

    final selectedText = urgent ? const Color(0xFFC73E3E) : AppColors.navy;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 30,
          constraints: const BoxConstraints(minWidth: 60),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? selectedBackground : AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? selectedBorder : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? selectedText : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}
