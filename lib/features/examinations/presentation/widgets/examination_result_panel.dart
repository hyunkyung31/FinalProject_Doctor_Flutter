import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../examination_ui_models.dart';
import 'examination_detail_panel.dart';

// ============================================================
// STEP 1. Result Panel
// ============================================================

class ExaminationResultPanel extends StatefulWidget {
  final List<ExaminationResultUiModel> results;

  final List<ExaminationExecutionUiModel> examinations;

  final List<ExaminationOrderUiModel> orders;
  final List<ExaminationTypeUiModel> types;
  final List<ExaminationEncounterUiModel> encounters;
  final List<ExaminationPatientUiModel> patients;

  final bool canFinalize;

  final ValueChanged<ExaminationResultUiModel> onFinalize;

  const ExaminationResultPanel({
    super.key,
    required this.results,
    required this.examinations,
    required this.orders,
    required this.types,
    required this.encounters,
    required this.patients,
    required this.canFinalize,
    required this.onFinalize,
  });

  @override
  State<ExaminationResultPanel> createState() => _ExaminationResultPanelState();
}

class _ExaminationResultPanelState extends State<ExaminationResultPanel> {
  int? _selectedId;

  // ============================================================
  // STEP 2. Init
  // ============================================================

  @override
  void initState() {
    super.initState();

    if (widget.results.isNotEmpty) {
      _selectedId = widget.results.first.id;
    }
  }

  ExaminationResultUiModel? get _selected {
    for (final item in widget.results) {
      if (item.id == _selectedId) {
        return item;
      }
    }

    return null;
  }

  ExaminationExecutionUiModel _examinationFor(ExaminationResultUiModel result) {
    return widget.examinations.firstWhere(
      (item) => item.id == result.examinationId,
    );
  }

  ExaminationOrderUiModel _orderFor(ExaminationResultUiModel result) {
    final examination = _examinationFor(result);

    return widget.orders.firstWhere((item) => item.id == examination.orderId);
  }

  ExaminationTypeUiModel _typeFor(ExaminationResultUiModel result) {
    final order = _orderFor(result);

    return widget.types.firstWhere(
      (item) => item.id == order.examinationTypeId,
    );
  }

  ExaminationPatientUiModel _patientFor(ExaminationResultUiModel result) {
    final order = _orderFor(result);

    final encounter = widget.encounters.firstWhere(
      (item) => item.id == order.encounterId,
    );

    return widget.patients.firstWhere((item) => item.id == encounter.patientId);
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
                      '검사 결과',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),

                const Divider(height: 1, color: AppColors.border),

                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: widget.results.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 7),
                    itemBuilder: (context, index) {
                      final result = widget.results[index];

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedId = result.id;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: result.id == _selectedId
                                ? AppColors.surfaceSoft
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: result.id == _selectedId
                                  ? AppColors.primaryBlue
                                  : AppColors.border,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _patientFor(result).name,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),

                                  ExaminationStatusBadge(status: result.status),
                                ],
                              ),

                              const SizedBox(height: 5),

                              Text(
                                _typeFor(result).name,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                '${result.resultType} · v${result.version}',
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

        const SizedBox(width: 14),

        Expanded(
          flex: 6,
          child: selected == null
              ? const Center(child: Text('검사 결과를 선택해 주세요.'))
              : ExaminationResultDetailPanel(
                  result: selected,
                  examination: _examinationFor(selected),
                  order: _orderFor(selected),
                  type: _typeFor(selected),
                  patient: _patientFor(selected),
                  canFinalize: widget.canFinalize,
                  onFinalize: () {
                    widget.onFinalize(selected);
                  },
                ),
        ),
      ],
    );
  }
}
