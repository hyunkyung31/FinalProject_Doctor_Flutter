import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/theme/app_theme.dart';
import '../consultation_ui_models.dart';

// ============================================================
// STEP 1. Consultation Detail Panel
//
// Tablet Consult Cockpit
// - 협진 상태/진행 단계
// - 협진 요청
// - 핵심 임상 요약
// - Clinical Evidence
// - 최근 협진 기록
// - 하단 Action Dock
// ============================================================

class ConsultationDetailPanel extends StatefulWidget {
  final ConsultationUiModel consultation;

  final VoidCallback onAccept;
  final VoidCallback onComplete;
  final VoidCallback onWithdraw;
  final ValueChanged<ConsultationOpinionUiModel> onOpinionAdded;

  final bool showBackButton;
  final VoidCallback? onBack;

  const ConsultationDetailPanel({
    super.key,
    required this.consultation,
    required this.onAccept,
    required this.onComplete,
    required this.onWithdraw,
    required this.onOpinionAdded,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  State<ConsultationDetailPanel> createState() =>
      _ConsultationDetailPanelState();
}

class _ConsultationDetailPanelState extends State<ConsultationDetailPanel> {
  static const int _demoCurrentDoctorId = 4;
  static const String _demoCurrentDoctorName = '이서준';
  static const String _demoCurrentDepartment = '순환기내과';

  // ============================================================
  // STEP 2. UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final horizontalPadding = wide ? 16.0 : 12.0;

          return Column(
            children: [
              // 환자/협진 상태는 스크롤과 관계없이 항상 보이도록 고정합니다.
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  14,
                  horizontalPadding,
                  0,
                ),
                child: _buildHero(wide),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRequestAndSummary(wide),
                      const SizedBox(height: 16),
                      _buildEvidenceSection(wide),
                      const SizedBox(height: 16),
                      _buildBottomWorkspace(wide),
                    ],
                  ),
                ),
              ),
              _buildActionDock(),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // STEP 3. Hero
  // ============================================================

  Widget _buildHero(bool wide) {
    final item = widget.consultation;

    return _CockpitCard(
      padding: EdgeInsets.fromLTRB(wide ? 18 : 14, 14, wide ? 18 : 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showBackButton) ...[
                IconButton(
                  onPressed: widget.onBack,
                  tooltip: '협진 목록',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.arrow_back_rounded, size: 19),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _StatusBadge(status: item.status),
                        _DirectionBadge(direction: item.direction),
                        _DueBadge(dueAt: item.dueAt),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      '${item.patientName} · ${item.subject}',
                      maxLines: wide ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: wide ? 18 : 16,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: context.appTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ParticipantStack(
                participants: item.participants,
                onTap: _showParticipantsSheet,
              ),
            ],
          ),
          const SizedBox(height: 13),
          _ConsultationStepper(status: item.status),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 4. Request + Clinical Summary
  // ============================================================

  Widget _buildRequestAndSummary(bool wide) {
    final requestCard = _buildRequestCard();
    final summaryCard = _buildClinicalSummaryCard();

    if (!wide) {
      return Column(
        children: [requestCard, const SizedBox(height: 10), summaryCard],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 7, child: requestCard),
        const SizedBox(width: 10),
        Expanded(flex: 4, child: summaryCard),
      ],
    );
  }

  Widget _buildRequestCard() {
    final item = widget.consultation;
    final requester = item.requester;

    return _CockpitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionIcon(icon: Icons.assignment_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '요청 내용',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: context.appTextPrimary,
                  ),
                ),
              ),
              _TinyPill(text: '우선순위 · ${item.priorityLabel}'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.note.isEmpty ? '등록된 협진 요청 내용이 없습니다.' : item.note,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.55,
              color: context.appTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _MetaChip(
                icon: Icons.person_outline_rounded,
                text: requester == null
                    ? '요청 의료진 -'
                    : '${requester.doctorName} · ${requester.department}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalSummaryCard() {
    final followUp = widget.consultation.followUp;
    final metrics = followUp?.clinicalMetrics ?? const [];

    return _CockpitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionIcon(icon: Icons.monitor_heart_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '핵심 지표',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: context.appTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (metrics.isEmpty)
            _EmptyMiniState(
              icon: Icons.monitor_heart_outlined,
              text: '표시할 임상 지표가 없습니다.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final visibleMetrics = metrics.take(4).toList();
                const gap = 8.0;
                final itemWidth = (constraints.maxWidth - gap) / 2;

                return Wrap(
                  spacing: gap,
                  runSpacing: 6,
                  children: [
                    for (final metric in visibleMetrics)
                      SizedBox(
                        width: itemWidth,
                        child: _ClinicalMetricCompact(metric: metric),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 5. Clinical Evidence
  // ============================================================

  Widget _buildEvidenceSection(bool wide) {
    final item = widget.consultation;
    final evidenceCards = <Widget>[];

    if (item.followUp?.cctaExaminationId != null) {
      evidenceCards.add(
        _EvidenceCard(
          kind: _EvidenceKind.ccta,
          eyebrow: 'CCTA',
          title: '관상동맥 CT 혈관조영술',
          primaryValue: 'Exam #${item.followUp!.cctaExaminationId}',
          secondaryValue: item.followUp!.cctaResultStatus ?? '결과 확인',
          onTap: _showCctaSheet,
        ),
      );
    }

    if (item.aiSummary != null) {
      final ai = item.aiSummary!;
      evidenceCards.add(
        _EvidenceCard(
          kind: _EvidenceKind.ai,
          eyebrow: ai.analysisType,
          title: '2D 혈관조영 AI',
          primaryValue:
              'L ${ai.leftSignificantScore.toStringAsFixed(3)} · R ${ai.rightSignificantScore.toStringAsFixed(3)}',
          secondaryValue: ai.resultStatus.replaceAll('_', ' '),
          onTap: _showAiSheet,
        ),
      );
    }

    if ((item.followUp?.clinicalMetrics ?? const []).isNotEmpty) {
      evidenceCards.add(
        _EvidenceCard(
          kind: _EvidenceKind.lab,
          eyebrow: 'LAB',
          title: '심혈관 혈액·임상 패널',
          primaryValue: '${item.followUp!.clinicalMetrics.length}개 지표',
          secondaryValue: '추적검사',
          onTap: _showLabSheet,
        ),
      );
    }

    for (final reference in item.references.take(1)) {
      evidenceCards.add(
        _EvidenceCard(
          kind: _EvidenceKind.reference,
          eyebrow: reference.referenceTypeLabel,
          title: reference.title,
          primaryValue: '#${reference.referenceId}',
          secondaryValue: reference.description,
          onTap: () => _showReferenceSheet(reference),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '근거 자료',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: context.appTextPrimary,
          ),
        ),
        const SizedBox(height: 9),
        if (evidenceCards.isEmpty)
          _CockpitCard(
            child: _EmptyMiniState(
              icon: Icons.folder_open_outlined,
              text: '연결된 임상 근거 자료가 없습니다.',
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 760
                  ? (evidenceCards.length >= 3 ? 3 : evidenceCards.length)
                  : constraints.maxWidth >= 480
                  ? (evidenceCards.length >= 2 ? 2 : evidenceCards.length)
                  : 1;

              final safeColumns = columns == 0 ? 1 : columns;
              final cardWidth =
                  (constraints.maxWidth - ((safeColumns - 1) * 9)) /
                  safeColumns;

              return Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  for (final card in evidenceCards)
                    SizedBox(width: cardWidth, child: card),
                ],
              );
            },
          ),
      ],
    );
  }

  // ============================================================
  // STEP 6. Bottom Workspace
  // ============================================================

  Widget _buildBottomWorkspace(bool wide) {
    final records = _buildRecentRecordsCard();
    final contextCard = _buildPatientContextCard();

    if (!wide) {
      return Column(
        children: [records, const SizedBox(height: 10), contextCard],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 7, child: records),
        const SizedBox(width: 10),
        Expanded(flex: 4, child: contextCard),
      ],
    );
  }

  Widget _buildRecentRecordsCard() {
    final opinions = [...widget.consultation.opinions]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return _CockpitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionIcon(icon: Icons.history_rounded),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '최근 협진 의견',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: context.appTextPrimary,
                  ),
                ),
              ),
              if (opinions.isNotEmpty) _TinyPill(text: '${opinions.length}건'),
            ],
          ),
          const SizedBox(height: 10),
          if (opinions.isEmpty)
            const _EmptyMiniState(
              icon: Icons.rate_review_outlined,
              text: '등록된 의견이 없습니다.',
              compact: true,
            )
          else ...[
            for (final opinion in opinions.take(2)) ...[
              _RecentOpinionRow(opinion: opinion),
              if (opinion != opinions.take(2).last)
                Divider(height: 14, color: context.appBorder),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showAllOpinionsSheet,
                icon: const Icon(Icons.article_outlined, size: 15),
                label: const Text('전체 의견 보기'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPatientContextCard() {
    final item = widget.consultation;
    final followUp = item.followUp;

    return _CockpitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionIcon(icon: Icons.fact_check_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '진료 컨텍스트',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: context.appTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (followUp != null)
            _InfoLine(label: 'MRN', value: followUp.medicalRecordNo),
          if (followUp?.encounterId != null)
            _InfoLine(label: 'Encounter', value: '#${followUp!.encounterId}'),
          if (followUp != null)
            _InfoLine(label: '추적 단계', value: followUp.stageLabel),
          _InfoLine(
            label: '담당 의료진',
            value: '${item.assignedDoctorName} · ${item.assignedDepartment}',
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showParticipantsSheet,
              icon: const Icon(Icons.group_outlined, size: 15),
              label: Text('참여 의료진 ${item.participants.length}명'),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 7. Action Dock
  // ============================================================

  Widget _buildActionDock() {
    final item = widget.consultation;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(top: BorderSide(color: context.appBorder)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;

          final shareButton = _DockButton(
            icon: Icons.add_link_rounded,
            label: '자료 공유',
            onPressed: item.isReadOnly ? null : _showSharePlaceholder,
          );

          final opinionButton = _DockButton(
            icon: Icons.edit_note_rounded,
            label: '의견 작성',
            onPressed: item.canWriteOpinion ? _showOpinionDialog : null,
          );

          final primaryButton = _buildPrimaryDockButton();

          if (compact) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: shareButton),
                    const SizedBox(width: 8),
                    Expanded(child: opinionButton),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: primaryButton),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: shareButton),
              const SizedBox(width: 8),
              Expanded(child: opinionButton),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: primaryButton),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPrimaryDockButton() {
    final item = widget.consultation;

    if (item.canAccept) {
      return _DockButton(
        icon: Icons.check_circle_outline_rounded,
        label: '협진 수락',
        primary: true,
        onPressed: widget.onAccept,
      );
    }

    if (item.canWithdraw) {
      return _DockButton(
        icon: Icons.undo_rounded,
        label: '협진 회수',
        danger: true,
        onPressed: widget.onWithdraw,
      );
    }

    if (item.canComplete) {
      return _DockButton(
        icon: Icons.task_alt_rounded,
        label: '협진 완료',
        primary: true,
        onPressed: widget.onComplete,
      );
    }

    return _DockButton(
      icon: item.status == ConsultationUiStatus.completed
          ? Icons.verified_rounded
          : Icons.block_outlined,
      label: item.status == ConsultationUiStatus.completed
          ? '완료된 협진'
          : '철회된 협진',
      onPressed: null,
    );
  }

  // ============================================================
  // STEP 8. Opinion Dialog
  // ============================================================

  Future<void> _showOpinionDialog() async {
    final textController = TextEditingController();
    var isFinal = false;

    final result = await showDialog<ConsultationOpinionUiModel>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: context.appSurface,
              title: const Text('협진 의견 작성'),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: textController,
                      minLines: 5,
                      maxLines: 8,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: '협진 의견을 입력해 주세요.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      value: isFinal,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        '최종 의견으로 등록',
                        style: TextStyle(fontSize: 11),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          isFinal = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('취소'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    final text = textController.text.trim();
                    if (text.isEmpty) {
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      ConsultationOpinionUiModel(
                        id: DateTime.now().millisecondsSinceEpoch,
                        doctorId: _demoCurrentDoctorId,
                        doctorName: _demoCurrentDoctorName,
                        department: _demoCurrentDepartment,
                        opinionText: text,
                        isFinal: isFinal,
                        createdAt: DateTime.now(),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                  ),
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: const Text('등록'),
                ),
              ],
            );
          },
        );
      },
    );

    textController.dispose();

    if (result != null) {
      widget.onOpinionAdded(result);
      _showMessage('협진 의견이 UI에 등록되었습니다. 실제 POST API 연결 지점입니다.');
    }
  }

  // ============================================================
  // STEP 9. Sheets
  // ============================================================

  Future<void> _showCctaSheet() async {
    final followUp = widget.consultation.followUp;
    if (followUp == null) {
      return;
    }

    await _showInfoSheet(
      title: 'CCTA 검사 정보',
      icon: Icons.scanner_outlined,
      children: [
        _SheetInfoRow(label: '검사', value: '관상동맥 CT 혈관조영술'),
        _SheetInfoRow(
          label: 'Examination',
          value: '#${followUp.cctaExaminationId ?? '-'}',
        ),
        _SheetInfoRow(
          label: '시행일',
          value: followUp.cctaPerformedAt == null
              ? '-'
              : _formatDate(followUp.cctaPerformedAt!),
        ),
        _SheetInfoRow(label: '위치', value: followUp.cctaLocation ?? '-'),
        _SheetInfoRow(label: '결과 상태', value: followUp.cctaResultStatus ?? '-'),
      ],
    );
  }

  Future<void> _showAiSheet() async {
    final ai = widget.consultation.aiSummary;
    if (ai == null) {
      return;
    }

    await _showInfoSheet(
      title: 'ANGIO 2D AI 결과',
      icon: Icons.psychology_alt_outlined,
      children: [
        _SheetInfoRow(label: 'Analysis', value: '#${ai.analysisId}'),
        _SheetInfoRow(label: 'Result', value: '#${ai.resultId}'),
        _SheetInfoRow(label: '상태', value: ai.resultStatus),
        const SizedBox(height: 8),
        _AiSideResult(
          side: 'LEFT',
          positive: ai.leftSignificantPositive,
          score: ai.leftSignificantScore,
        ),
        const SizedBox(height: 8),
        _AiSideResult(
          side: 'RIGHT',
          positive: ai.rightSignificantPositive,
          score: ai.rightSignificantScore,
        ),
        const SizedBox(height: 10),
        _SheetInfoRow(
          label: '분석 규모',
          value: '${ai.seriesCount} series · ${ai.frameCount} frames',
        ),
        if (ai.warning != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: context.appSurfaceSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.appBorder),
            ),
            child: Text(
              ai.warning!,
              style: TextStyle(
                fontSize: 9.5,
                height: 1.45,
                color: context.appTextSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showLabSheet() async {
    final metrics = widget.consultation.followUp?.clinicalMetrics ?? const [];

    await _showInfoSheet(
      title: '최신 임상 지표',
      icon: Icons.biotech_outlined,
      children: [
        for (final metric in metrics) ...[
          _SheetInfoRow(
            label: metric.label,
            value:
                '${metric.value}${metric.unit == null ? '' : ' ${metric.unit}'}'
                '${metric.flag == null ? '' : ' · ${metric.flag}'}',
          ),
        ],
      ],
    );
  }

  Future<void> _showReferenceSheet(
    ConsultationReferenceUiModel reference,
  ) async {
    await _showInfoSheet(
      title: reference.title,
      icon: Icons.link_rounded,
      children: [
        _SheetInfoRow(label: '유형', value: reference.referenceTypeLabel),
        _SheetInfoRow(
          label: 'Reference ID',
          value: '#${reference.referenceId}',
        ),
        _SheetInfoRow(label: '설명', value: reference.description),
      ],
    );
  }

  Future<void> _showParticipantsSheet() async {
    final participants = widget.consultation.participants;

    await _showInfoSheet(
      title: '협진 참여 의료진',
      icon: Icons.groups_2_outlined,
      children: [
        for (final participant in participants) ...[
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: context.appBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.appBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: context.appSurfaceSoft,
                  child: Text(
                    _initial(participant.doctorName),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: context.appBrand,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        participant.doctorName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: context.appTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${participant.department}${participant.title == null ? '' : ' · ${participant.title}'}',
                        style: TextStyle(
                          fontSize: 9,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _TinyPill(text: participant.roleLabel),
              ],
            ),
          ),
          const SizedBox(height: 7),
        ],
      ],
    );
  }

  Future<void> _showAllOpinionsSheet() async {
    final opinions = [...widget.consultation.opinions]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    await _showInfoSheet(
      title: '협진 의견 기록',
      icon: Icons.article_outlined,
      children: opinions.isEmpty
          ? [
              _EmptyMiniState(
                icon: Icons.rate_review_outlined,
                text: '등록된 협진 의견이 없습니다.',
              ),
            ]
          : [
              for (final opinion in opinions) ...[
                _OpinionRecordCard(opinion: opinion),
                const SizedBox(height: 8),
              ],
            ],
    );
  }

  Future<void> _showInfoSheet({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final height = MediaQuery.sizeOf(sheetContext).height;

        return SafeArea(
          child: Container(
            constraints: BoxConstraints(maxHeight: height * 0.78),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
                  child: Row(
                    children: [
                      _SectionIcon(icon: icon),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: context.appTextPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded, size: 19),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: context.appBorder),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSharePlaceholder() {
    _showMessage('자료 공유 UI입니다. 실제 references POST API 연결 단계에서 구현합니다.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }
}

// ============================================================
// STEP 10. Cockpit Components
// ============================================================

class _CockpitCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _CockpitCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
      ),
      child: child,
    );
  }
}

class _SectionIcon extends StatelessWidget {
  final IconData icon;

  const _SectionIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 31,
      height: 31,
      decoration: BoxDecoration(
        color: context.appSurfaceSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: context.appBrand),
    );
  }
}

class _TinyPill extends StatelessWidget {
  final String text;

  const _TinyPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.appSurfaceSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: context.appTextSecondary,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: context.appBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: context.appTextSecondary),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 8.8,
              fontWeight: FontWeight.w600,
              color: context.appTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicalMetricCompact extends StatelessWidget {
  final ConsultationClinicalMetricUiModel metric;

  const _ClinicalMetricCompact({required this.metric});

  @override
  Widget build(BuildContext context) {
    final flag = metric.flag?.toUpperCase();
    final abnormal = flag == 'HIGH' || flag == 'LOW' || flag == 'ABNORMAL';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: context.appSurfaceSoft,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 7.8,
                    fontWeight: FontWeight.w700,
                    color: context.appTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: metric.value,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: context.appTextPrimary,
                          ),
                        ),
                        if (metric.unit != null)
                          TextSpan(
                            text: ' ${metric.unit}',
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w500,
                              color: context.appTextSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (metric.flag != null) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: abnormal
                    ? AppColors.warning.withValues(alpha: 0.10)
                    : context.appBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                metric.flag!,
                style: TextStyle(
                  fontSize: 6.5,
                  fontWeight: FontWeight.w800,
                  color: abnormal
                      ? AppColors.warning
                      : context.appTextSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _EvidenceKind { ccta, ai, lab, reference }

class _EvidenceCard extends StatelessWidget {
  final _EvidenceKind kind;
  final String eyebrow;
  final String title;
  final String primaryValue;
  final String secondaryValue;
  final VoidCallback onTap;

  const _EvidenceCard({
    required this.kind,
    required this.eyebrow,
    required this.title,
    required this.primaryValue,
    required this.secondaryValue,
    required this.onTap,
  });

  IconData get _icon {
    switch (kind) {
      case _EvidenceKind.ccta:
        return Icons.scanner_outlined;
      case _EvidenceKind.ai:
        return Icons.psychology_alt_outlined;
      case _EvidenceKind.lab:
        return Icons.biotech_outlined;
      case _EvidenceKind.reference:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 108),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.appBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.appSurfaceSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      eyebrow,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: context.appBrand,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(_icon, size: 17, color: context.appTextSecondary),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                primaryValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: kind == _EvidenceKind.ai ? 13 : 11,
                  fontWeight: FontWeight.w800,
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                secondaryValue,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 8.5,
                  color: context.appTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentOpinionRow extends StatelessWidget {
  final ConsultationOpinionUiModel opinion;

  const _RecentOpinionRow({required this.opinion});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: context.appSurfaceSoft,
          child: Text(
            _initial(opinion.doctorName),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: context.appBrand,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 5,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    opinion.doctorName,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: context.appTextPrimary,
                    ),
                  ),
                  _TinyPill(text: opinion.department),
                  if (opinion.isFinal) const _FinalBadge(),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                opinion.opinionText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  height: 1.45,
                  color: context.appTextSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _formatTime(opinion.createdAt),
          style: TextStyle(fontSize: 8, color: context.appTextDisabled),
        ),
      ],
    );
  }
}

class _OpinionRecordCard extends StatelessWidget {
  final ConsultationOpinionUiModel opinion;

  const _OpinionRecordCard({required this.opinion});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appBackground,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: opinion.isFinal ? AppColors.success : context.appBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${opinion.doctorName} · ${opinion.department}',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: context.appTextPrimary,
                  ),
                ),
              ),
              if (opinion.isFinal) const _FinalBadge(),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            opinion.opinionText,
            style: TextStyle(
              fontSize: 10,
              height: 1.55,
              color: context.appTextSecondary,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _formatDateTime(opinion.createdAt),
            style: TextStyle(fontSize: 8.5, color: context.appTextDisabled),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: TextStyle(fontSize: 8.5, color: context.appTextSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: context.appTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMiniState extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool compact;

  const _EmptyMiniState({
    required this.icon,
    required this.text,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: compact ? 10 : 18,
      ),
      decoration: BoxDecoration(
        color: context.appBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: compact ? 17 : 20, color: context.appTextDisabled),
          SizedBox(height: compact ? 4 : 7),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.3,
              height: 1.45,
              color: context.appTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 11. Status / Stepper / Participants
// ============================================================

class _ConsultationStepper extends StatelessWidget {
  final ConsultationUiStatus status;

  const _ConsultationStepper({required this.status});

  int get _currentStep {
    switch (status) {
      case ConsultationUiStatus.requested:
        return 0;
      case ConsultationUiStatus.inProgress:
        return 2;
      case ConsultationUiStatus.completed:
        return 3;
      case ConsultationUiStatus.withdrawn:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['요청', '수락', '의견 작성', '완료'];
    final current = _currentStep;

    return Row(
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          _StepNode(
            label: labels[index],
            completed:
                status != ConsultationUiStatus.withdrawn && index < current,
            current:
                status != ConsultationUiStatus.withdrawn && index == current,
          ),
          if (index < labels.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                color:
                    status != ConsultationUiStatus.withdrawn && index < current
                    ? AppColors.primaryBlue
                    : context.appBorder,
              ),
            ),
        ],
      ],
    );
  }
}

class _StepNode extends StatelessWidget {
  final String label;
  final bool completed;
  final bool current;

  const _StepNode({
    required this.label,
    required this.completed,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final active = completed || current;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed ? AppColors.primaryBlue : context.appSurface,
            border: Border.all(
              color: active ? AppColors.primaryBlue : context.appBorder,
              width: current ? 2.4 : 1.4,
            ),
          ),
          child: completed
              ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 8.2,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? context.appTextPrimary : context.appTextDisabled,
          ),
        ),
      ],
    );
  }
}

class _ParticipantStack extends StatelessWidget {
  final List<ConsultationParticipantUiModel> participants;
  final VoidCallback onTap;

  const _ParticipantStack({required this.participants, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final visible = participants.take(2).toList();
    final remain = participants.length - visible.length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < visible.length; index++) ...[
              if (index > 0) const SizedBox(width: 4),
              CircleAvatar(
                radius: 17,
                backgroundColor: context.appSurfaceSoft,
                child: Text(
                  _initial(visible[index].doctorName),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: context.appBrand,
                  ),
                ),
              ),
            ],
            if (remain > 0) ...[
              const SizedBox(width: 4),
              CircleAvatar(
                radius: 17,
                backgroundColor: context.appBackground,
                child: Text(
                  '+$remain',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: context.appTextSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STEP 12. Dock / Sheet Components
// ============================================================

class _DockButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final bool danger;

  const _DockButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          minimumSize: const Size(0, 46),
        ),
        icon: Icon(icon, size: 16),
        label: Text(label),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: danger ? AppColors.danger : null,
        minimumSize: const Size(0, 46),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

class _SheetInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _SheetInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 9.5, color: context.appTextSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: context.appTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiSideResult extends StatelessWidget {
  final String side;
  final bool positive;
  final double score;

  const _AiSideResult({
    required this.side,
    required this.positive,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: context.appBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  side,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: context.appTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Significant stenosis',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: context.appTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          _TinyPill(text: positive ? 'Positive' : 'Negative'),
          const SizedBox(width: 8),
          Text(
            'AI score ${score.toStringAsFixed(3)}',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: context.appTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 13. Badges
// ============================================================

class _StatusBadge extends StatelessWidget {
  final ConsultationUiStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final Color background;

    switch (status) {
      case ConsultationUiStatus.requested:
        color = AppColors.warning;
        background = AppColors.warningBackground;
        break;
      case ConsultationUiStatus.inProgress:
        color = AppColors.primaryBlue;
        background = context.appSurfaceSoft;
        break;
      case ConsultationUiStatus.completed:
        color = AppColors.success;
        background = AppColors.successBackground;
        break;
      case ConsultationUiStatus.withdrawn:
        color = AppColors.danger;
        background = AppColors.dangerBackground;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _DirectionBadge extends StatelessWidget {
  final ConsultationUiDirection direction;

  const _DirectionBadge({required this.direction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: context.appBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
      ),
      child: Text(
        direction.shortLabel,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: context.appTextSecondary,
        ),
      ),
    );
  }
}

class _DueBadge extends StatelessWidget {
  final DateTime dueAt;

  const _DueBadge({required this.dueAt});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = dueAt.difference(now);
    final expired = diff.isNegative;
    final day = diff.inDays;
    final label = expired
        ? '기한 경과'
        : day <= 0
        ? '오늘 ${_formatTime(dueAt)}'
        : 'D-$day · ${_formatTime(dueAt)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: expired ? AppColors.dangerBackground : context.appBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: expired ? AppColors.danger : context.appBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 11,
            color: expired ? AppColors.danger : context.appTextSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: expired ? AppColors.danger : context.appTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinalBadge extends StatelessWidget {
  const _FinalBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.successBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        '최종 의견',
        style: TextStyle(
          fontSize: 7.5,
          fontWeight: FontWeight.w800,
          color: AppColors.success,
        ),
      ),
    );
  }
}

// ============================================================
// STEP 14. Helpers
// ============================================================

String _initial(String name) {
  if (name.trim().isEmpty) {
    return '-';
  }

  return name.trim().substring(0, 1);
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}.$month.$day';
}

String _formatTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatDateTime(DateTime date) {
  return '${_formatDate(date)} ${_formatTime(date)}';
}
