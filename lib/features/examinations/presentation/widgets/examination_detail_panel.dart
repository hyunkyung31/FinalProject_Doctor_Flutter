import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../examination_ui_models.dart';

// ============================================================
// 검사 오더 상세
// ============================================================

typedef ExaminationOrderEditCallback =
    Future<ExaminationOrderUiModel?> Function({
      required int orderId,
      required String priority,
      required String clinicalNote,
    });

class ExaminationOrderDetailPanel extends StatelessWidget {
  final ExaminationOrderUiModel order;
  final ExaminationTypeUiModel type;
  final ExaminationEncounterUiModel encounter;
  final ExaminationPatientUiModel patient;

  final bool canOrder;
  final ExaminationOrderEditCallback onUpdateOrder;
  final VoidCallback onSchedule;
  final VoidCallback onCancel;
  final VoidCallback onPrepareExecution;

  final bool canEnterLabResult;
  final String? labResultStatus;
  final bool labResultLoaded;
  final VoidCallback? onLabResultAction;

  const ExaminationOrderDetailPanel({
    super.key,
    required this.order,
    required this.type,
    required this.encounter,
    required this.patient,
    required this.canOrder,
    required this.onUpdateOrder,
    required this.onSchedule,
    required this.onCancel,
    required this.onPrepareExecution,
    this.canEnterLabResult = false,
    this.labResultStatus,
    this.labResultLoaded = true,
    this.onLabResultAction,
  });

  bool get _canEditOrder {
    return canOrder &&
        (order.status == 'ORDERED' || order.status == 'SCHEDULED');
  }

  Future<void> _openOrderEditDialog(BuildContext context) async {
    var priority = order.priority;
    var isSaving = false;

    final noteController = TextEditingController(
      text: order.clinicalNote ?? '',
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                '검사 오더 수정',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '우선순위',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 7),

                    DropdownButtonFormField<String>(
                      initialValue: priority,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'NORMAL', child: Text('일반')),
                        DropdownMenuItem(value: 'URGENT', child: Text('응급')),
                        DropdownMenuItem(value: 'STAT', child: Text('긴급')),
                      ],
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() {
                                  priority = value;
                                });
                              }
                            },
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      '임상 메모',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 7),

                    TextField(
                      controller: noteController,
                      enabled: !isSaving,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: '검사 요청사항 또는 임상 메모를 입력하세요.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setDialogState(() {
                            isSaving = true;
                          });

                          final updatedOrder = await onUpdateOrder(
                            orderId: order.id,
                            priority: priority,
                            clinicalNote: noteController.text,
                          );

                          if (!dialogContext.mounted) {
                            return;
                          }

                          if (updatedOrder != null) {
                            Navigator.of(dialogContext).pop();
                            return;
                          }

                          setDialogState(() {
                            isSaving = false;
                          });
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                  ),
                  child: Text(isSaving ? '저장 중...' : '저장'),
                ),
              ],
            );
          },
        );
      },
    );

    noteController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLab = type.category == 'LAB';

    Widget? footer;

    if (isLab) {
      if (order.status != 'CANCELED' && labResultLoaded) {
        footer = _LabResultFooter(
          canEnterLabResult: canEnterLabResult,
          resultStatus: labResultStatus,
          resultLoaded: labResultLoaded,
          onLabResultAction: onLabResultAction,
        );
      }
    } else if (order.status == 'ORDERED') {
      footer = _OrderFooter(
        canOrder: canOrder,
        showPrepareExecution:
            type.category == 'IMAGING' || type.category == 'PROCEDURE',
        onSchedule: onSchedule,
        onCancel: onCancel,
        onPrepareExecution: onPrepareExecution,
      );
    }

    return _DetailShell(
      header: _DetailHeader(
        icon: Icons.science_outlined,
        title: type.name,
        subtitle: '${patient.name} · ${patient.age}세 · ${patient.gender}',
        status: order.status,
      ),
      body: [
        _InfoCard(
          title: '검사 오더',
          icon: Icons.assignment_outlined,
          action: _canEditOrder
              ? TextButton.icon(
                  onPressed: () {
                    _openOrderEditDialog(context);
                  },
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text(
                    '수정',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                )
              : null,
          children: [
            _InfoRow(label: '오더 번호', value: '#${order.id}'),
            _InfoRow(label: '검사 코드', value: type.code),
            _InfoRow(label: '검사 구분', value: _categoryLabel(type.category)),
            _InfoRow(label: 'Modality', value: type.modality ?? '-'),
            _InfoRow(label: '우선순위', value: _priorityLabel(order.priority)),
            _InfoRow(
              label: '현재 상태',
              valueWidget: ExaminationStatusBadge(status: order.status),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: '진료 연결',
          icon: Icons.link_rounded,
          children: [
            _InfoRow(label: '환자', value: '${patient.name} (#${patient.id})'),
            _InfoRow(label: 'Encounter', value: '#${encounter.id}'),
            _InfoRow(
              label: '진료 상태',
              value: _encounterStatusLabel(encounter.status),
            ),
            _InfoRow(label: '처방 의료진', value: '#${order.orderedBy}'),
          ],
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: '일정 · 메모',
          icon: Icons.event_note_outlined,
          children: [
            _InfoRow(label: '처방일', value: formatExamDateTime(order.orderedAt)),
            _InfoRow(
              label: '예정일',
              value: order.scheduledAt == null
                  ? '미지정'
                  : formatExamDateTime(order.scheduledAt!),
            ),
            _InfoRow(label: '검사 장소', value: order.scheduledLocation ?? '미지정'),
            _InfoRow(label: '임상 메모', value: order.clinicalNote ?? '-'),
          ],
        ),
        if (order.status == 'CANCELED') ...[
          const SizedBox(height: 12),
          _InfoCard(
            title: '취소 정보',
            icon: Icons.event_busy_outlined,
            children: [
              _InfoRow(
                label: '취소일',
                value: order.canceledAt == null
                    ? '-'
                    : formatExamDateTime(order.canceledAt!),
              ),
              _InfoRow(label: '취소 사유', value: order.cancelReason ?? '-'),
            ],
          ),
        ],
      ],
      footer: footer,
    );
  }
}

// ============================================================
// STEP 2. 검사 수행 상세
// ============================================================

class ExaminationProgressDetailPanel extends StatelessWidget {
  final ExaminationExecutionUiModel examination;

  final ExaminationOrderUiModel order;
  final ExaminationTypeUiModel type;
  final ExaminationPatientUiModel patient;

  final bool canPerform;

  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback onFail;

  const ExaminationProgressDetailPanel({
    super.key,
    required this.examination,
    required this.order,
    required this.type,
    required this.patient,
    required this.canPerform,
    required this.onStart,
    required this.onComplete,
    required this.onFail,
  });

  @override
  Widget build(BuildContext context) {
    return _DetailShell(
      header: _DetailHeader(
        icon: Icons.play_circle_outline_rounded,
        title: type.name,
        subtitle: '${patient.name} · ${patient.age}세 · ${patient.gender}',
        status: examination.status,
      ),
      body: [
        _InfoCard(
          title: '검사 수행 정보',
          icon: Icons.monitor_heart_outlined,
          children: [
            _InfoRow(label: '검사 ID', value: '#${examination.id}'),
            _InfoRow(label: '연결 오더', value: '#${order.id}'),
            _InfoRow(label: '시도 횟수', value: '${examination.attemptNo}회'),
            _InfoRow(label: '검사 장소', value: examination.location),
            _InfoRow(
              label: '현재 상태',
              valueWidget: ExaminationStatusBadge(status: examination.status),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: '시간 정보',
          icon: Icons.schedule_outlined,
          children: [
            _InfoRow(
              label: '생성일',
              value: formatExamDateTime(examination.createdAt),
            ),
            _InfoRow(
              label: '수행일',
              value: examination.performedAt == null
                  ? '-'
                  : formatExamDateTime(examination.performedAt!),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: '오더 정보',
          icon: Icons.assignment_outlined,
          children: [
            _InfoRow(label: '검사 종류', value: type.name),
            _InfoRow(label: '우선순위', value: _priorityLabel(order.priority)),
            _InfoRow(label: '임상 메모', value: order.clinicalNote ?? '-'),
          ],
        ),
      ],
      footer: _ProgressFooter(
        status: examination.status,
        canPerform: canPerform,
        onStart: onStart,
        onComplete: onComplete,
        onFail: onFail,
      ),
    );
  }
}

// ============================================================
// STEP 3. 검사 결과 상세
// ============================================================

class ExaminationResultDetailPanel extends StatelessWidget {
  final ExaminationResultUiModel result;

  final ExaminationExecutionUiModel examination;
  final ExaminationOrderUiModel order;
  final ExaminationTypeUiModel type;
  final ExaminationPatientUiModel patient;

  final bool canFinalize;

  final VoidCallback onFinalize;

  const ExaminationResultDetailPanel({
    super.key,
    required this.result,
    required this.examination,
    required this.order,
    required this.type,
    required this.patient,
    required this.canFinalize,
    required this.onFinalize,
  });

  @override
  Widget build(BuildContext context) {
    return _DetailShell(
      header: _DetailHeader(
        icon: Icons.fact_check_outlined,
        title: type.name,
        subtitle: '${patient.name} · ${patient.age}세 · ${patient.gender}',
        status: result.status,
      ),
      body: [
        _InfoCard(
          title: '결과 정보',
          icon: Icons.description_outlined,
          children: [
            _InfoRow(label: '결과 ID', value: '#${result.id}'),
            _InfoRow(label: '결과 유형', value: result.resultType),
            _InfoRow(label: '버전', value: 'v${result.version}'),
            _InfoRow(
              label: '수집일',
              value: formatExamDateTime(result.collectedAt),
            ),
            _InfoRow(
              label: '상태',
              valueWidget: ExaminationStatusBadge(status: result.status),
            ),
          ],
        ),
        if (result.measurements.isNotEmpty) ...[
          const SizedBox(height: 12),
          _MeasurementCard(measurements: result.measurements),
        ],
        const SizedBox(height: 12),
        _InfoCard(
          title: '확정 정보',
          icon: Icons.verified_outlined,
          children: [
            _InfoRow(
              label: '확정일',
              value: result.confirmedAt == null
                  ? '미확정'
                  : formatExamDateTime(result.confirmedAt!),
            ),
            _InfoRow(
              label: '확정 의료진',
              value: result.confirmedBy == null
                  ? '-'
                  : '#${result.confirmedBy}',
            ),
            _InfoRow(label: '요약', value: result.summaryText ?? '-'),
          ],
        ),
      ],
      footer: result.status != 'FINAL'
          ? _ResultFooter(canFinalize: canFinalize, onFinalize: onFinalize)
          : null,
    );
  }
}

// ============================================================
// STEP 4. 공통 Detail Shell
// ============================================================

class _DetailShell extends StatelessWidget {
  final Widget header;
  final List<Widget> body;
  final Widget? footer;

  const _DetailShell({
    required this.header,
    required this.body,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          header,

          Divider(height: 1, color: context.appBorder),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: body),
            ),
          ),

          ?footer,
        ],
      ),
    );
  }
}

// ============================================================
// STEP 5. Detail Header
// ============================================================

class _DetailHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;

  const _DetailHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.appSurfaceSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 21, color: context.appBrand),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ),

                    const SizedBox(width: 9),

                    ExaminationStatusBadge(status: status),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: context.appTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 6. Info Card
// ============================================================

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? action;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    this.action,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: context.appBrand),

              const SizedBox(width: 7),

              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.appTextPrimary,
                  ),
                ),
              ),

              ?action,
            ],
          ),

          const SizedBox(height: 12),

          ...children,
        ],
      ),
    );
  }
}

// ============================================================
// STEP 7. Info Row
// ============================================================

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;

  const _InfoRow({required this.label, this.value, this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: context.appTextSecondary,
              ),
            ),
          ),

          Expanded(
            child: valueWidget != null
                ? Align(alignment: Alignment.centerLeft, child: valueWidget!)
                : Text(
                    value ?? '-',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: context.appTextPrimary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 8. Measurement
// clinical_variable 이름은 아직 API 연결 전이므로 ID 표시
// ============================================================

class _MeasurementCard extends StatelessWidget {
  final List<ExaminationMeasurementUiModel> measurements;

  const _MeasurementCard({required this.measurements});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: context.appBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.biotech_outlined, size: 16, color: context.appBrand),

                const SizedBox(width: 7),

                Text(
                  '측정 결과',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.appTextPrimary,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: context.appBorder),

          Container(
            color: context.appSurfaceSoft,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('검사 항목', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: context.appTextSecondary)),
                ),
                Expanded(flex: 2, child: Text('결과', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: context.appTextSecondary))),
                Expanded(flex: 2, child: Text('단위', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: context.appTextSecondary))),
                Expanded(flex: 2, child: Text('검증', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: context.appTextSecondary))),
              ],
            ),
          ),

          for (int i = 0; i < measurements.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      '임상변수 #${measurements[i].clinicalVariableId}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: context.appTextPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      measurements[i].displayValue,
                      style: TextStyle(
                        fontSize: 10,
                        color: context.appTextPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      measurements[i].unit ?? '-',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      measurements[i].validationStatus,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: measurements[i].validationStatus == 'VALID'
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (i != measurements.length - 1)
              Divider(height: 1, color: context.appBorder),
          ],
        ],
      ),
    );
  }
}

class _LabResultFooter extends StatelessWidget {
  final bool canEnterLabResult;
  final String? resultStatus;
  final bool resultLoaded;
  final VoidCallback? onLabResultAction;

  const _LabResultFooter({
    required this.canEnterLabResult,
    required this.resultStatus,
    required this.resultLoaded,
    required this.onLabResultAction,
  });

  @override
  Widget build(BuildContext context) {
    final status = resultStatus?.toUpperCase();

    if (!resultLoaded) {
      return const _ReadOnlyFooter(text: '혈액 검사 결과 상태를 확인하고 있습니다...');
    }

    if (status == 'FINAL') {
      return const _ReadOnlyFooter(text: '혈액 검사 결과가 최종 확정되었습니다.');
    }

    if (status == 'VALIDATED') {
      return const _ReadOnlyFooter(text: '혈액 검사 결과 검토가 완료되어 최종 확정을 기다리고 있습니다.');
    }

    if (status != null && status != 'DRAFT') {
      return const _ReadOnlyFooter(text: '현재 상태에서는 혈액 검사 결과를 수정할 수 없습니다.');
    }

    if (!canEnterLabResult) {
      return const _ReadOnlyFooter(text: '현재 역할에서는 혈액 검사 결과를 조회할 수 있습니다.');
    }

    final isDraft = status == 'DRAFT';

    return _ActionContainer(
      child: Row(
        children: [
          Expanded(
            child: Text(
              isDraft ? '작성 중인 혈액 검사 결과가 있습니다.' : '혈액 검사 결과가 아직 입력되지 않았습니다.',
              style: TextStyle(
                fontSize: 10.5,
                color: context.appTextSecondary,
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: onLabResultAction,
            style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
            icon: Icon(
              isDraft ? Icons.edit_outlined : Icons.add_rounded,
              size: 16,
            ),
            label: Text(isDraft ? '결과 수정' : '결과 입력'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Order Footer
// 영상 / 시술 검사에서만 실제 검사 수행 준비 제공
// ============================================================

class _OrderFooter extends StatelessWidget {
  final bool canOrder;
  final bool showPrepareExecution;

  final VoidCallback onSchedule;
  final VoidCallback onCancel;
  final VoidCallback onPrepareExecution;

  const _OrderFooter({
    required this.canOrder,
    required this.showPrepareExecution,
    required this.onSchedule,
    required this.onCancel,
    required this.onPrepareExecution,
  });

  @override
  Widget build(BuildContext context) {
    if (!canOrder) {
      return const _ReadOnlyFooter(text: '현재 역할에서는 검사 오더를 조회할 수 있습니다.');
    }

    return _ActionContainer(
      child: Row(
        children: [
          Expanded(
            child: Text(
              '검사 오더 관리',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: context.appTextSecondary,
              ),
            ),
          ),

          OutlinedButton(onPressed: onCancel, child: const Text('오더 취소')),

          const SizedBox(width: 8),

          OutlinedButton(onPressed: onSchedule, child: const Text('일정 등록')),

          if (showPrepareExecution) ...[
            const SizedBox(width: 8),

            FilledButton.icon(
              onPressed: onPrepareExecution,
              style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
              icon: const Icon(Icons.play_circle_outline_rounded, size: 16),
              label: const Text('검사 수행 준비'),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// STEP 10. Progress Footer
// ============================================================

class _ProgressFooter extends StatelessWidget {
  final String status;
  final bool canPerform;

  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback onFail;

  const _ProgressFooter({
    required this.status,
    required this.canPerform,
    required this.onStart,
    required this.onComplete,
    required this.onFail,
  });

  @override
  Widget build(BuildContext context) {
    if (!canPerform) {
      return const _ReadOnlyFooter(text: '현재 역할에서는 검사 진행 상태를 조회할 수 있습니다.');
    }

    if (status == 'SCHEDULED' || status == 'READY') {
      return _ActionContainer(
        child: Row(
          children: [
            Expanded(
              child: Text(
                '검사 대기 상태입니다.',
                style: TextStyle(
                  fontSize: 10.5,
                  color: context.appTextSecondary,
                ),
              ),
            ),

            FilledButton.icon(
              onPressed: onStart,
              style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
              icon: const Icon(Icons.play_arrow_rounded, size: 16),
              label: const Text('검사 시작'),
            ),
          ],
        ),
      );
    }

    if (status == 'IN_PROGRESS') {
      return _ActionContainer(
        child: Row(
          children: [
            Expanded(
              child: Text(
                '검사가 진행 중입니다.',
                style: TextStyle(
                  fontSize: 10.5,
                  color: context.appTextSecondary,
                ),
              ),
            ),

            OutlinedButton(onPressed: onFail, child: const Text('검사 실패')),

            const SizedBox(width: 8),

            FilledButton.icon(
              onPressed: onComplete,
              style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('검사 완료'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// ============================================================
// STEP 11. Result Footer
// ============================================================

class _ResultFooter extends StatelessWidget {
  final bool canFinalize;
  final VoidCallback onFinalize;

  const _ResultFooter({required this.canFinalize, required this.onFinalize});

  @override
  Widget build(BuildContext context) {
    if (!canFinalize) {
      return const _ReadOnlyFooter(text: '현재 역할에서는 검사 결과를 조회할 수 있습니다.');
    }

    return _ActionContainer(
      child: Row(
        children: [
          Expanded(
            child: Text(
              '결과를 검토한 후 최종 확정할 수 있습니다.',
              style: TextStyle(fontSize: 10.5, color: context.appTextSecondary),
            ),
          ),

          FilledButton.icon(
            onPressed: onFinalize,
            style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
            icon: const Icon(Icons.verified_outlined, size: 16),
            label: const Text('결과 확정'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 12. Action Container
// ============================================================

class _ActionContainer extends StatelessWidget {
  final Widget child;

  const _ActionContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(top: BorderSide(color: context.appBorder)),
      ),
      child: child,
    );
  }
}

class _ReadOnlyFooter extends StatelessWidget {
  final String text;

  const _ReadOnlyFooter({required this.text});

  @override
  Widget build(BuildContext context) {
    return _ActionContainer(
      child: Row(
        children: [
          Icon(
            Icons.visibility_outlined,
            size: 15,
            color: context.appTextSecondary,
          ),

          const SizedBox(width: 7),

          Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              color: context.appTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 13. Status Badge
// ============================================================

class ExaminationStatusBadge extends StatelessWidget {
  final String status;

  const ExaminationStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, status);
    final background = _statusBackground(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ============================================================
// STEP 14. 공통 Helpers
// ============================================================

String formatExamDateTime(DateTime date) {
  final local = date.toUtc().add(const Duration(hours: 9));

  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '${local.year}.$month.$day $hour:$minute';
}

String _categoryLabel(String category) {
  switch (category) {
    case 'LAB':
      return '혈액검사';

    case 'IMAGING':
      return '영상';

    case 'PROCEDURE':
      return '시술';

    default:
      return category;
  }
}

String _priorityLabel(String priority) {
  switch (priority) {
    case 'NORMAL':
      return '일반';

    case 'URGENT':
      return '응급';

    case 'STAT':
      return '긴급';

    default:
      return priority;
  }
}

String _encounterStatusLabel(String status) {
  switch (status.trim().toUpperCase()) {
    case 'COMPLETED':
      return '완료';

    case 'IN_PROGRESS':
      return '진행 중';

    case 'CANCELED':
      return '취소';

    case 'SCHEDULED':
      return '예약';

    default:
      return status;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'ORDERED':
      return '오더';

    case 'SCHEDULED':
      return '검사 예정';

    case 'READY':
      return '검사 대기';

    case 'IN_PROGRESS':
      return '진행 중';

    case 'COMPLETED':
      return '완료';

    case 'FAILED':
      return '실패';

    case 'CANCELED':
      return '취소';

    case 'DRAFT':
      return '작성 중';

    case 'VALIDATED':
      return '검증 완료';

    case 'FINAL':
      return '최종 확정';

    default:
      return status;
  }
}

Color _statusColor(BuildContext context, String status) {
  switch (status) {
    case 'COMPLETED':
    case 'FINAL':
    case 'VALIDATED':
      return AppColors.success;

    case 'ORDERED':
    case 'SCHEDULED':
    case 'READY':
    case 'DRAFT':
      return AppColors.warning;

    case 'IN_PROGRESS':
      return AppColors.primaryBlue;

    case 'FAILED':
    case 'CANCELED':
      return AppColors.danger;

    default:
      return context.appTextSecondary;
  }
}

Color _statusBackground(BuildContext context, String status) {
  switch (status) {
    case 'COMPLETED':
    case 'FINAL':
    case 'VALIDATED':
      return AppColors.successBackground;

    case 'ORDERED':
    case 'SCHEDULED':
    case 'READY':
    case 'DRAFT':
      return AppColors.warningBackground;

    case 'IN_PROGRESS':
      return context.appSurfaceSoft;

    case 'FAILED':
    case 'CANCELED':
      return AppColors.dangerBackground;

    default:
      return context.appSurfaceSoft;
  }
}
