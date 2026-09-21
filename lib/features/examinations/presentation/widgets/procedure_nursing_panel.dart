import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_context.dart';
import '../examination_ui_models.dart';

// ============================================================
// STEP 1. 시술 간호 이벤트 UI Model
// 실제 API 연결 시 procedure_nursing_events 응답으로 교체
// ============================================================

class ProcedureNursingEventUiModel {
  final int id;
  final DateTime recordedAt;
  final String eventCode;
  final String label;
  final String? note;
  final bool canceled;

  const ProcedureNursingEventUiModel({
    required this.id,
    required this.recordedAt,
    required this.eventCode,
    required this.label,
    required this.note,
    this.canceled = false,
  });
}

// ============================================================
// STEP 2. 시술 간호 기록 Panel
// ============================================================

class ProcedureNursingPanel extends StatefulWidget {
  final ExaminationExecutionUiModel examination;
  final ExaminationTypeUiModel type;
  final ExaminationPatientUiModel patient;

  final bool canEdit;

  const ProcedureNursingPanel({
    super.key,
    required this.examination,
    required this.type,
    required this.patient,
    required this.canEdit,
  });

  @override
  State<ProcedureNursingPanel> createState() => _ProcedureNursingPanelState();
}

class _ProcedureNursingPanelState extends State<ProcedureNursingPanel> {
  final TextEditingController _summaryController = TextEditingController();

  final TextEditingController _bloodPressureController =
      TextEditingController();

  final TextEditingController _heartRateController = TextEditingController();

  final TextEditingController _spo2Controller = TextEditingController();

  final List<ProcedureNursingEventUiModel> _events = [];

  int _nextEventId = 1;

  bool _isFinalized = false;

  // ============================================================
  // STEP 3. Dispose
  // ============================================================

  @override
  void dispose() {
    _summaryController.dispose();
    _bloodPressureController.dispose();
    _heartRateController.dispose();
    _spo2Controller.dispose();

    super.dispose();
  }

  // ============================================================
  // STEP 4. 이벤트 등록
  // ============================================================

  void _addEvent({required String eventCode, required String label}) {
    if (!widget.canEdit || _isFinalized) {
      return;
    }

    setState(() {
      _events.insert(
        0,
        ProcedureNursingEventUiModel(
          id: _nextEventId++,
          recordedAt: DateTime.now(),
          eventCode: eventCode,
          label: label,
          note: null,
        ),
      );
    });

    _showMessage('$label 기록이 추가되었습니다.');
  }

  // ============================================================
  // STEP 5. 차트 임시 저장
  // ============================================================

  void _saveDraft() {
    if (!widget.canEdit || _isFinalized) {
      return;
    }

    _showMessage('시술 간호 차트가 임시 저장되었습니다. 실제 API는 아직 연결하지 않았습니다.');
  }

  // ============================================================
  // STEP 6. 차트 최종 확정
  // ============================================================

  void _finalizeChart() {
    if (!widget.canEdit || _isFinalized) {
      return;
    }

    setState(() {
      _isFinalized = true;
    });

    _showMessage('시술 간호 기록이 최종 확정되었습니다.');
  }

  // ============================================================
  // STEP 7. 이벤트 취소
  // 실제 시스템에서는 삭제 대신 취소 이력 생성
  // ============================================================

  void _cancelEvent(ProcedureNursingEventUiModel event) {
    if (!widget.canEdit || _isFinalized) {
      return;
    }

    final index = _events.indexWhere((item) => item.id == event.id);

    if (index < 0) {
      return;
    }

    setState(() {
      _events[index] = ProcedureNursingEventUiModel(
        id: event.id,
        recordedAt: event.recordedAt,
        eventCode: event.eventCode,
        label: event.label,
        note: event.note,
        canceled: true,
      );
    });
  }

  // ============================================================
  // STEP 8. UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ======================================================
        // Header
        // ======================================================
        Container(
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
          decoration: BoxDecoration(
            color: context.appSurface,
            border: Border(bottom: BorderSide(color: context.appBorder)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.appSurfaceSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.medical_information_outlined,
                  size: 18,
                  color: context.appBrand,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '시술 간호 기록',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.appTextPrimary,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '${widget.patient.name} · ${widget.type.name}',
                      style: TextStyle(
                        fontSize: 10,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              if (_isFinalized)
                _StatusBadge(text: '최종 확정', color: AppColors.success)
              else
                _StatusBadge(text: '작성 중', color: AppColors.warning),
            ],
          ),
        ),

        // ======================================================
        // Content
        // ======================================================
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // 시술 전 확인
                // ==================================================
                _SectionCard(
                  title: '시술 전 확인',
                  icon: Icons.fact_check_outlined,
                  child: Column(
                    children: [
                      _InfoRow(
                        label: '환자',
                        value:
                            '${widget.patient.name} · ${widget.patient.age}세 · ${widget.patient.gender}',
                      ),

                      _InfoRow(label: '검사', value: widget.type.name),

                      _InfoRow(
                        label: '검사실',
                        value: widget.examination.location,
                      ),

                      const SizedBox(height: 5),

                      Row(
                        children: [
                          Expanded(
                            child: _MeasurementField(
                              label: '혈압',
                              hintText: '120/80',
                              controller: _bloodPressureController,
                              enabled:
                                  widget.canEdit &&
                                  !_isFinalized &&
                                  widget.examination.status == 'IN_PROGRESS',
                            ),
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: _MeasurementField(
                              label: '심박수',
                              hintText: '72',
                              controller: _heartRateController,
                              enabled: widget.canEdit && !_isFinalized,
                            ),
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: _MeasurementField(
                              label: 'SpO₂',
                              hintText: '98',
                              controller: _spo2Controller,
                              enabled: widget.canEdit && !_isFinalized,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ==================================================
                // 시술 중 이벤트
                // ==================================================
                _SectionCard(
                  title: '시술 중 기록',
                  icon: Icons.timeline_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _EventButton(
                              label: '시술 시작',
                              icon: Icons.play_arrow_rounded,
                              enabled: widget.canEdit && !_isFinalized,
                              onPressed: () {
                                _addEvent(
                                  eventCode: 'PROCEDURE_START',
                                  label: '시술 시작',
                                );
                              },
                            ),
                          ),

                          const SizedBox(width: 7),

                          Expanded(
                            child: _EventButton(
                              label: '카테터 삽입',
                              icon: Icons.arrow_downward_rounded,
                              enabled: widget.canEdit && !_isFinalized,
                              onPressed: () {
                                _addEvent(
                                  eventCode: 'CATHETER_INSERTED',
                                  label: '카테터 삽입',
                                );
                              },
                            ),
                          ),

                          const SizedBox(width: 7),

                          Expanded(
                            child: _EventButton(
                              label: '조영제 투여',
                              icon: Icons.water_drop_outlined,
                              enabled: widget.canEdit && !_isFinalized,
                              onPressed: () {
                                _addEvent(
                                  eventCode: 'CONTRAST_ADMINISTERED',
                                  label: '조영제 투여',
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      if (_events.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: context.appBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '아직 기록된 시술 이벤트가 없습니다.',
                            style: TextStyle(
                              fontSize: 10,
                              color: context.appTextSecondary,
                            ),
                          ),
                        )
                      else
                        Column(
                          children: [
                            for (final event in _events)
                              _ProcedureEventRow(
                                event: event,
                                canEdit: widget.canEdit && !_isFinalized,
                                onCancel: () {
                                  _cancelEvent(event);
                                },
                              ),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ==================================================
                // 간호 메모
                // ==================================================
                _SectionCard(
                  title: '간호 메모',
                  icon: Icons.edit_note_rounded,
                  child: TextField(
                    controller: _summaryController,
                    enabled: widget.canEdit && !_isFinalized,
                    minLines: 3,
                    maxLines: 5,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: context.appTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: '시술 중 특이사항이나 간호 내용을 입력해 주세요.',
                      hintStyle: TextStyle(
                        fontSize: 10,
                        color: context.appTextDisabled,
                      ),
                      filled: true,
                      fillColor: context.appBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: context.appBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: context.appBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ======================================================
        // Footer
        // ======================================================
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.appSurface,
            border: Border(top: BorderSide(color: context.appBorder)),
          ),
          child: widget.canEdit
              ? Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isFinalized
                            ? '최종 확정된 기록입니다.'
                            : '작성 중인 기록은 임시 저장할 수 있습니다.',
                        style: TextStyle(
                          fontSize: 10,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ),

                    if (!_isFinalized &&
                        widget.examination.status == 'IN_PROGRESS') ...[
                      OutlinedButton(
                        onPressed: _saveDraft,
                        child: const Text('임시 저장'),
                      ),

                      const SizedBox(width: 8),

                      FilledButton.icon(
                        onPressed: _finalizeChart,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.navy,
                        ),
                        icon: const Icon(Icons.verified_outlined, size: 15),
                        label: const Text('기록 확정'),
                      ),
                    ],
                  ],
                )
              : Row(
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      size: 15,
                      color: context.appTextSecondary,
                    ),

                    SizedBox(width: 7),

                    Text(
                      '현재 역할에서는 시술 간호 기록을 조회할 수 있습니다.',
                      style: TextStyle(
                        fontSize: 10,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 9. Message
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
// STEP 10. Section Card
// ============================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: context.appBrand),

              const SizedBox(width: 7),

              Text(
                title,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: context.appTextPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 11),

          child,
        ],
      ),
    );
  }
}

// ============================================================
// STEP 11. Info Row
// ============================================================

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                color: context.appTextSecondary,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 10,
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
// STEP 12. Measurement Field
// ============================================================

class _MeasurementField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool enabled;

  const _MeasurementField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: context.appTextSecondary,
          ),
        ),

        const SizedBox(height: 5),

        SizedBox(
          height: 36,
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: const TextStyle(fontSize: 10.5),
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: context.appBackground,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.appBorder),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STEP 13. Event Button
// ============================================================

class _EventButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _EventButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 38),
        foregroundColor: context.appBrand,
        side: BorderSide(color: context.appBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 15),
      label: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ============================================================
// STEP 14. Event Row
// ============================================================

class _ProcedureEventRow extends StatelessWidget {
  final ProcedureNursingEventUiModel event;
  final bool canEdit;
  final VoidCallback onCancel;

  const _ProcedureEventRow({
    required this.event,
    required this.canEdit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: event.canceled
            ? AppColors.dangerBackground
            : context.appBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(
              _formatTime(event.recordedAt),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: context.appTextSecondary,
              ),
            ),
          ),

          Expanded(
            child: Text(
              event.canceled ? '${event.label} · 취소됨' : event.label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                decoration: event.canceled ? TextDecoration.lineThrough : null,
                color: event.canceled
                    ? AppColors.danger
                    : context.appTextPrimary,
              ),
            ),
          ),

          if (canEdit && !event.canceled)
            PopupMenuButton<String>(
              tooltip: '기록 관리',
              padding: EdgeInsets.zero,
              onSelected: (value) {
                if (value == 'cancel') {
                  onCancel();
                }
              },
              itemBuilder: (_) {
                return const [
                  PopupMenuItem(value: 'cancel', child: Text('기록 취소')),
                ];
              },
              child: SizedBox(
                width: 28,
                height: 24,
                child: Icon(
                  Icons.more_horiz_rounded,
                  size: 17,
                  color: context.appTextSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 15. Status Badge
// ============================================================

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

String _formatTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');

  final minute = date.minute.toString().padLeft(2, '0');

  final second = date.second.toString().padLeft(2, '0');

  return '$hour:$minute:$second';
}
