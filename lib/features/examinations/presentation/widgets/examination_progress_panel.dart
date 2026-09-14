import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../examination_ui_models.dart';
import 'examination_detail_panel.dart';
import 'procedure_nursing_panel.dart';

// ============================================================
// STEP 1. Progress Panel
// ============================================================

class ExaminationProgressPanel extends StatefulWidget {
  final List<ExaminationExecutionUiModel> examinations;

  final List<ExaminationOrderUiModel> orders;
  final List<ExaminationTypeUiModel> types;
  final List<ExaminationEncounterUiModel> encounters;
  final List<ExaminationPatientUiModel> patients;

  final bool canPerform;
  final bool canEditProcedureNursing;

  final ValueChanged<ExaminationExecutionUiModel> onStart;

  final ValueChanged<ExaminationExecutionUiModel> onComplete;

  final ValueChanged<ExaminationExecutionUiModel> onFail;

  const ExaminationProgressPanel({
    super.key,
    required this.examinations,
    required this.orders,
    required this.types,
    required this.encounters,
    required this.patients,
    required this.canPerform,
    required this.canEditProcedureNursing,
    required this.onStart,
    required this.onComplete,
    required this.onFail,
  });

  @override
  State<ExaminationProgressPanel> createState() =>
      _ExaminationProgressPanelState();
}

class _ExaminationProgressPanelState extends State<ExaminationProgressPanel> {
  int? _selectedId;

  String _statusFilter = 'ALL';

  // ============================================================
  // STEP 2. Init
  // ============================================================

  @override
  void initState() {
    super.initState();

    if (widget.examinations.isNotEmpty) {
      _selectedId = widget.examinations.first.id;
    }
  }

  ExaminationOrderUiModel _orderFor(ExaminationExecutionUiModel examination) {
    return widget.orders.firstWhere((item) => item.id == examination.orderId);
  }

  ExaminationTypeUiModel _typeFor(ExaminationExecutionUiModel examination) {
    final order = _orderFor(examination);

    return widget.types.firstWhere(
      (item) => item.id == order.examinationTypeId,
    );
  }

  ExaminationPatientUiModel _patientFor(
    ExaminationExecutionUiModel examination,
  ) {
    final order = _orderFor(examination);

    final encounter = widget.encounters.firstWhere(
      (item) => item.id == order.encounterId,
    );

    return widget.patients.firstWhere((item) => item.id == encounter.patientId);
  }

  List<ExaminationExecutionUiModel> get _filtered {
    if (_statusFilter == 'ALL') {
      return widget.examinations;
    }

    return widget.examinations
        .where((item) => item.status == _statusFilter)
        .toList();
  }

  ExaminationExecutionUiModel? get _selected {
    for (final item in widget.examinations) {
      if (item.id == _selectedId) {
        return item;
      }
    }

    return null;
  }

  // ============================================================
  // STEP 3. UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final selected = _selected;

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '검사 진행',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      _StatusFilter(
                        text: '전체',
                        selected: _statusFilter == 'ALL',
                        onTap: () {
                          setState(() {
                            _statusFilter = 'ALL';
                          });
                        },
                      ),
                      const SizedBox(width: 5),
                      _StatusFilter(
                        text: '대기',
                        selected: _statusFilter == 'READY',
                        onTap: () {
                          setState(() {
                            _statusFilter = 'READY';
                          });
                        },
                      ),
                      const SizedBox(width: 5),
                      _StatusFilter(
                        text: '진행',
                        selected: _statusFilter == 'IN_PROGRESS',
                        onTap: () {
                          setState(() {
                            _statusFilter = 'IN_PROGRESS';
                          });
                        },
                      ),
                      const SizedBox(width: 5),
                      _StatusFilter(
                        text: '완료',
                        selected: _statusFilter == 'COMPLETED',
                        onTap: () {
                          setState(() {
                            _statusFilter = 'COMPLETED';
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                const Divider(height: 1, color: AppColors.border),

                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: _filtered.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 7),
                    itemBuilder: (context, index) {
                      final item = _filtered[index];

                      return _ProgressItem(
                        examination: item,
                        patient: _patientFor(item),
                        type: _typeFor(item),
                        selected: item.id == _selectedId,
                        onTap: () {
                          setState(() {
                            _selectedId = item.id;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          flex: 6,
          child: selected == null
              ? const _EmptyProgress()
              : _ProgressDetailArea(
                  examination: selected,
                  order: _orderFor(selected),
                  type: _typeFor(selected),
                  patient: _patientFor(selected),
                  canPerform: widget.canPerform,
                  canEditProcedureNursing: widget.canEditProcedureNursing,
                  onStart: () {
                    widget.onStart(selected);
                  },
                  onComplete: () {
                    widget.onComplete(selected);
                  },
                  onFail: () {
                    widget.onFail(selected);
                  },
                ),
        ),
      ],
    );
  }
}

// ============================================================
// STEP 4. Progress Item
// ============================================================

class _ProgressItem extends StatelessWidget {
  final ExaminationExecutionUiModel examination;
  final ExaminationPatientUiModel patient;
  final ExaminationTypeUiModel type;

  final bool selected;
  final VoidCallback onTap;

  const _ProgressItem({
    required this.examination,
    required this.patient,
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    patient.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                ExaminationStatusBadge(status: examination.status),
              ],
            ),

            const SizedBox(height: 5),

            Text(
              type.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              examination.location,
              style: const TextStyle(
                fontSize: 9.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STEP 5. Status Filter
// ============================================================

class _StatusFilter extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _StatusFilter({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyProgress extends StatelessWidget {
  const _EmptyProgress();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('검사를 선택해 주세요.'));
  }
}

// ============================================================
// STEP 6. 검사 진행 상세 + 시술 간호 기록
// ANGIOGRAPHY / ANGIO_2D 검사에서만 간호 기록 Tab 표시
// ============================================================

class _ProgressDetailArea extends StatefulWidget {
  final ExaminationExecutionUiModel examination;
  final ExaminationOrderUiModel order;
  final ExaminationTypeUiModel type;
  final ExaminationPatientUiModel patient;

  final bool canPerform;
  final bool canEditProcedureNursing;

  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback onFail;

  const _ProgressDetailArea({
    required this.examination,
    required this.order,
    required this.type,
    required this.patient,
    required this.canPerform,
    required this.canEditProcedureNursing,
    required this.onStart,
    required this.onComplete,
    required this.onFail,
  });

  @override
  State<_ProgressDetailArea> createState() => _ProgressDetailAreaState();
}

class _ProgressDetailAreaState extends State<_ProgressDetailArea> {
  bool _showNursingChart = false;

  bool get _supportsProcedureNursing {
    return widget.type.code == 'ANGIOGRAPHY' || widget.type.code == 'ANGIO_2D';
  }

  @override
  void didUpdateWidget(covariant _ProgressDetailArea oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.examination.id != widget.examination.id) {
      _showNursingChart = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_supportsProcedureNursing) {
      return ExaminationProgressDetailPanel(
        examination: widget.examination,
        order: widget.order,
        type: widget.type,
        patient: widget.patient,
        canPerform: widget.canPerform,
        onStart: widget.onStart,
        onComplete: widget.onComplete,
        onFail: widget.onFail,
      );
    }

    return Column(
      children: [
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: _DetailTabButton(
                  label: '검사 정보',
                  selected: !_showNursingChart,
                  onTap: () {
                    setState(() {
                      _showNursingChart = false;
                    });
                  },
                ),
              ),

              Expanded(
                child: _DetailTabButton(
                  label: '시술 간호 기록',
                  selected: _showNursingChart,
                  onTap: () {
                    setState(() {
                      _showNursingChart = true;
                    });
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Expanded(
          child: _showNursingChart
              ? Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ProcedureNursingPanel(
                    examination: widget.examination,
                    type: widget.type,
                    patient: widget.patient,
                    canEdit: widget.canEditProcedureNursing,
                  ),
                )
              : ExaminationProgressDetailPanel(
                  examination: widget.examination,
                  order: widget.order,
                  type: widget.type,
                  patient: widget.patient,
                  canPerform: widget.canPerform,
                  onStart: widget.onStart,
                  onComplete: widget.onComplete,
                  onFail: widget.onFail,
                ),
        ),
      ],
    );
  }
}

// ============================================================
// STEP 7. Detail Tab Button
// ============================================================

class _DetailTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DetailTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.navy : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.navy : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
