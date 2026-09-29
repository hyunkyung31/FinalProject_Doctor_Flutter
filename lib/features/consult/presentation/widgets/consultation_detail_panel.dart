import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/theme/app_theme.dart';
import '../consultation_ui_models.dart';

// ============================================================
// STEP 1. Consultation Detail Panel
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

enum _ConsultationDetailTab { overview, participants, references, opinions }

class _ConsultationDetailPanelState extends State<ConsultationDetailPanel> {
  _ConsultationDetailTab _selectedTab = _ConsultationDetailTab.overview;

  // ============================================================
  // STEP 2. Consultation 변경 시 첫 탭으로 복귀
  // ============================================================

  @override
  void didUpdateWidget(covariant ConsultationDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.consultation.id != widget.consultation.id) {
      _selectedTab = _ConsultationDetailTab.overview;
    }
  }

  // ============================================================
  // STEP 3. Main UI
  // ============================================================

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
          _buildHeader(),
          Divider(height: 1, color: context.appBorder),
          _buildTabs(),
          Divider(height: 1, color: context.appBorder),
          Expanded(child: _buildSelectedTab()),
          _buildActionDock(),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 4. Header
  // ============================================================

  Widget _buildHeader() {
    final item = widget.consultation;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
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
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _StatusBadge(status: item.status),
                    _DirectionBadge(direction: item.direction),
                    if (item.dueAt != null)
                      _SimpleBadge(
                        icon: Icons.schedule_outlined,
                        text: '기한 ${_formatDateTime(item.dueAt!)}',
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.patientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ),

                    const SizedBox(width: 7),

                    Text(
                      item.patientMeta,
                      style: TextStyle(
                        fontSize: 9,
                        color: context.appTextDisabled,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  item.subject,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: context.appTextPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          _ParticipantSummary(participants: item.participants),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 5. Tabs
  // ============================================================

  Widget _buildTabs() {
    return SizedBox(
      height: 45,
      child: Row(
        children: [
          Expanded(
            child: _DetailTabButton(
              icon: Icons.dashboard_outlined,
              label: '개요',
              selected: _selectedTab == _ConsultationDetailTab.overview,
              onTap: () {
                setState(() {
                  _selectedTab = _ConsultationDetailTab.overview;
                });
              },
            ),
          ),

          Expanded(
            child: _DetailTabButton(
              icon: Icons.groups_outlined,
              label: '참여자',
              count: widget.consultation.participants.length,
              selected: _selectedTab == _ConsultationDetailTab.participants,
              onTap: () {
                setState(() {
                  _selectedTab = _ConsultationDetailTab.participants;
                });
              },
            ),
          ),

          Expanded(
            child: _DetailTabButton(
              icon: Icons.folder_copy_outlined,
              label: '참조',
              count: widget.consultation.references.length,
              selected: _selectedTab == _ConsultationDetailTab.references,
              onTap: () {
                setState(() {
                  _selectedTab = _ConsultationDetailTab.references;
                });
              },
            ),
          ),

          Expanded(
            child: _DetailTabButton(
              icon: Icons.rate_review_outlined,
              label: '협진 의견',
              count: widget.consultation.opinions.length,
              selected: _selectedTab == _ConsultationDetailTab.opinions,
              onTap: () {
                setState(() {
                  _selectedTab = _ConsultationDetailTab.opinions;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTab() {
    switch (_selectedTab) {
      case _ConsultationDetailTab.overview:
        return _buildOverview();

      case _ConsultationDetailTab.participants:
        return _buildParticipants();

      case _ConsultationDetailTab.references:
        return _buildReferences();

      case _ConsultationDetailTab.opinions:
        return _buildOpinions();
    }
  }

  // ============================================================
  // STEP 6. Overview
  // ============================================================

  Widget _buildOverview() {
    final item = widget.consultation;
    final requester = item.requester;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCard(
            title: '협진 정보',
            icon: Icons.info_outline_rounded,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth >= 600;

                final itemWidth = twoColumns
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 16,
                  runSpacing: 14,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _InfoField(label: '상태', value: item.status.label),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _InfoField(
                        label: '구분',
                        value: item.direction.label,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _InfoField(
                        label: '우선순위',
                        value: item.priorityLabel,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _InfoField(
                        label: '요청일',
                        value: _formatDateTime(item.createdAt),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _InfoField(
                        label: '기한',
                        value: item.dueAt == null
                            ? '-'
                            : _formatDateTime(item.dueAt!),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _InfoField(
                        label: 'Encounter',
                        value: item.encounterId == null
                            ? '-'
                            : '#${item.encounterId}',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          _SectionCard(
            title: '담당 의료진',
            icon: Icons.medical_services_outlined,
            child: Row(
              children: [
                Expanded(
                  child: _DoctorSummaryCard(
                    eyebrow: '요청 의료진',
                    name: requester?.doctorName ?? '요청 의료진 미확인',
                    department: requester?.department ?? '진료과 미확인',
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: context.appTextDisabled,
                  ),
                ),

                Expanded(
                  child: _DoctorSummaryCard(
                    eyebrow: '담당 의료진',
                    name: item.assignedDoctorName,
                    department: item.assignedDepartment,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _SectionCard(
            title: '협진 요청 내용',
            icon: Icons.assignment_outlined,
            trailing: _PriorityBadge(
              priority: item.priority,
              label: item.priorityLabel,
            ),
            child: Text(
              item.note.trim().isEmpty ? '등록된 협진 요청 내용이 없습니다.' : item.note,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.6,
                color: context.appTextSecondary,
              ),
            ),
          ),

          const SizedBox(height: 12),

          _SectionCard(
            title: '일정',
            icon: Icons.event_outlined,
            child: Column(
              children: [
                _ScheduleRow(
                  icon: Icons.schedule_outlined,
                  label: '완료 기한',
                  value: item.dueAt == null
                      ? '설정되지 않음'
                      : _formatDateTime(item.dueAt!),
                ),
                Divider(height: 20, color: context.appBorder),
                _ScheduleRow(
                  icon: Icons.history_rounded,
                  label: '협진 등록',
                  value: _formatDateTime(item.createdAt),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 7. Participants
  // ============================================================

  Widget _buildParticipants() {
    final participants = widget.consultation.participants;

    if (participants.isEmpty) {
      return const _EmptyTabState(
        icon: Icons.groups_outlined,
        title: '참여 의료진이 없습니다.',
        description: '등록된 협진 참여자가 없습니다.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: participants.length,
      separatorBuilder: (_, _) => const SizedBox(height: 9),
      itemBuilder: (context, index) {
        final participant = participants[index];

        return _ParticipantCard(participant: participant);
      },
    );
  }

  // ============================================================
  // STEP 8. References
  // ============================================================

  Widget _buildReferences() {
    final references = widget.consultation.references;

    if (references.isEmpty) {
      return const _EmptyTabState(
        icon: Icons.folder_open_outlined,
        title: '연결된 참조 자료가 없습니다.',
        description: '검사, 영상, AI 결과 또는 보고서를 협진에 연결할 수 있습니다.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: references.length,
      separatorBuilder: (_, _) => const SizedBox(height: 9),
      itemBuilder: (context, index) {
        final reference = references[index];

        return _ReferenceCard(reference: reference);
      },
    );
  }

  // ============================================================
  // STEP 9. Opinions
  // ============================================================

  Widget _buildOpinions() {
    final opinions = [...widget.consultation.opinions]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      children: [
        if (widget.consultation.canWriteOpinion)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: context.appSurface,
              border: Border(bottom: BorderSide(color: context.appBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '의견을 작성하여 협진 의료진과 공유할 수 있습니다.',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: context.appTextSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _showOpinionDialog,
                  icon: const Icon(Icons.edit_note_rounded, size: 15),
                  label: const Text('의견 작성'),
                ),
              ],
            ),
          ),

        Expanded(
          child: opinions.isEmpty
              ? const _EmptyTabState(
                  icon: Icons.rate_review_outlined,
                  title: '등록된 협진 의견이 없습니다.',
                  description: '협진이 진행되면 의료진 의견이 이곳에 표시됩니다.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: opinions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 9),
                  itemBuilder: (context, index) {
                    return _OpinionCard(opinion: opinions[index]);
                  },
                ),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 10. Action Dock
  // ============================================================

  Widget _buildActionDock() {
    final item = widget.consultation;

    if (item.status == ConsultationUiStatus.completed) {
      return _ReadOnlyActionDock(icon: Icons.verified_rounded, label: '완료된 협진');
    }

    if (item.status == ConsultationUiStatus.withdrawn) {
      return _ReadOnlyActionDock(icon: Icons.block_outlined, label: '회수된 협진');
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(top: BorderSide(color: context.appBorder)),
      ),
      child: Row(
        children: [
          if (item.canWriteOpinion) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showOpinionDialog,
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                icon: const Icon(Icons.edit_note_rounded, size: 16),
                label: const Text('의견 작성'),
              ),
            ),
            const SizedBox(width: 8),
          ],

          Expanded(
            flex: item.canWriteOpinion ? 2 : 1,
            child: _buildPrimaryAction(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryAction() {
    final item = widget.consultation;

    if (item.canAccept) {
      return FilledButton.icon(
        onPressed: widget.onAccept,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          minimumSize: const Size(0, 44),
        ),
        icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
        label: const Text('협진 수락'),
      );
    }

    if (item.canWithdraw) {
      return OutlinedButton.icon(
        onPressed: widget.onWithdraw,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          minimumSize: const Size(0, 44),
        ),
        icon: const Icon(Icons.undo_rounded, size: 16),
        label: const Text('협진 회수'),
      );
    }

    if (item.canComplete) {
      return FilledButton.icon(
        onPressed: widget.onComplete,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          minimumSize: const Size(0, 44),
        ),
        icon: const Icon(Icons.task_alt_rounded, size: 16),
        label: const Text('협진 완료'),
      );
    }

    return const SizedBox.shrink();
  }

  // ============================================================
  // STEP 11. Opinion Dialog
  //
  // author는 Backend에서 로그인 의료진으로 결정합니다.
  // Flutter 임시 모델의 의료진 필드는 POST payload에 사용하지 않습니다.
  // ============================================================

  Future<void> _showOpinionDialog() async {
    final controller = TextEditingController();
    var isFinal = false;

    final result = await showDialog<_OpinionDialogResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('협진 의견 작성'),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      minLines: 4,
                      maxLines: 7,
                      decoration: const InputDecoration(
                        labelText: '협진 의견',
                        hintText: '검토 의견을 입력해 주세요.',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      value: isFinal,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('최종 의견으로 등록'),
                      subtitle: const Text('최종 의견 여부를 함께 저장합니다.'),
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
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () {
                    final text = controller.text.trim();

                    if (text.isEmpty) {
                      return;
                    }

                    Navigator.of(
                      dialogContext,
                    ).pop(_OpinionDialogResult(text: text, isFinal: isFinal));
                  },
                  child: const Text('등록'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (result == null || !mounted) {
      return;
    }

    widget.onOpinionAdded(
      ConsultationOpinionUiModel(
        id: 0,
        doctorId: 0,
        doctorName: '',
        department: '',
        opinionText: result.text,
        isFinal: result.isFinal,
        createdAt: DateTime.now(),
      ),
    );
  }
}

// ============================================================
// STEP 12. Tab Button
// ============================================================

class _DetailTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const _DetailTabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? context.appBrand : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? context.appBrand : context.appTextSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? context.appBrand : context.appTextSecondary,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? context.appSurfaceSoft
                      : context.appBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? context.appBrand
                        : context.appTextDisabled,
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
// STEP 13. Section Card
// ============================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
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
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.appSurfaceSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: context.appBrand),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: context.appTextPrimary,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;

  const _InfoField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 8.5, color: context.appTextDisabled),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: context.appTextPrimary,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STEP 14. Doctor Summary
// ============================================================

class _DoctorSummaryCard extends StatelessWidget {
  final String eyebrow;
  final String name;
  final String department;

  const _DoctorSummaryCard({
    required this.eyebrow,
    required this.name,
    required this.department,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appBackground,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: context.appSurfaceSoft,
            child: Text(
              _initial(name),
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
                Text(
                  eyebrow,
                  style: TextStyle(fontSize: 8, color: context.appTextDisabled),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: context.appTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  department,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8.5,
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
// STEP 15. Participant
// ============================================================

class _ParticipantCard extends StatelessWidget {
  final ConsultationParticipantUiModel participant;

  const _ParticipantCard({required this.participant});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: context.appSurfaceSoft,
            child: Text(
              _initial(participant.doctorName),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: context.appBrand,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        participant.doctorName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    _SmallLabel(text: participant.roleLabel),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [participant.department, participant.title?.trim()]
                      .whereType<String>()
                      .where((value) => value.isNotEmpty)
                      .join(' · '),
                  style: TextStyle(
                    fontSize: 9,
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
// STEP 16. Reference
// ============================================================

class _ReferenceCard extends StatelessWidget {
  final ConsultationReferenceUiModel reference;

  const _ReferenceCard({required this.reference});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.appSurfaceSoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              _referenceIcon(reference.referenceTypeLabel),
              size: 18,
              color: context.appBrand,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _SmallLabel(text: reference.referenceTypeLabel),
                    const SizedBox(width: 7),
                    Text(
                      '#${reference.referenceId}',
                      style: TextStyle(
                        fontSize: 8,
                        color: context.appTextDisabled,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  reference.title,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: context.appTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reference.description,
                  style: TextStyle(
                    fontSize: 8.8,
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
// STEP 17. Opinion
// ============================================================

class _OpinionCard extends StatelessWidget {
  final ConsultationOpinionUiModel opinion;

  const _OpinionCard({required this.opinion});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              CircleAvatar(
                radius: 15,
                backgroundColor: context.appSurfaceSoft,
                child: Text(
                  _initial(opinion.doctorName),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: context.appBrand,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opinion.doctorName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: context.appTextPrimary,
                      ),
                    ),
                    Text(
                      opinion.department,
                      style: TextStyle(
                        fontSize: 8,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (opinion.isFinal) const _FinalBadge(),
              const SizedBox(width: 8),
              Text(
                _formatDateTime(opinion.createdAt),
                style: TextStyle(fontSize: 8, color: context.appTextDisabled),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            opinion.opinionText,
            style: TextStyle(
              fontSize: 10.2,
              height: 1.55,
              color: context.appTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 18. Schedule
// ============================================================

class _ScheduleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ScheduleRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: context.appTextSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(fontSize: 9, color: context.appTextSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: context.appTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STEP 19. Badges
// ============================================================

class _StatusBadge extends StatelessWidget {
  final ConsultationUiStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final foreground = switch (status) {
      ConsultationUiStatus.requested => AppColors.warning,
      ConsultationUiStatus.inProgress => AppColors.primaryBlue,
      ConsultationUiStatus.completed => AppColors.success,
      ConsultationUiStatus.withdrawn => AppColors.danger,
    };

    final background = switch (status) {
      ConsultationUiStatus.requested => AppColors.warningBackground,
      ConsultationUiStatus.inProgress => context.appSurfaceSoft,
      ConsultationUiStatus.completed => AppColors.successBackground,
      ConsultationUiStatus.withdrawn => AppColors.dangerBackground,
    };

    return _ColoredBadge(
      text: status.label,
      foreground: foreground,
      background: background,
    );
  }
}

class _DirectionBadge extends StatelessWidget {
  final ConsultationUiDirection direction;

  const _DirectionBadge({required this.direction});

  @override
  Widget build(BuildContext context) {
    return _ColoredBadge(
      text: direction.shortLabel,
      foreground: context.appTextSecondary,
      background: context.appBackground,
      borderColor: context.appBorder,
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;
  final String label;

  const _PriorityBadge({required this.priority, required this.label});

  @override
  Widget build(BuildContext context) {
    final urgent =
        priority.toUpperCase() == 'URGENT' || priority.toUpperCase() == 'HIGH';

    return _ColoredBadge(
      text: '우선순위 · $label',
      foreground: urgent ? AppColors.danger : context.appTextSecondary,
      background: urgent ? AppColors.dangerBackground : context.appBackground,
      borderColor: urgent ? null : context.appBorder,
    );
  }
}

class _SimpleBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SimpleBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.appBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: context.appTextSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: context.appTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColoredBadge extends StatelessWidget {
  final String text;
  final Color foreground;
  final Color background;
  final Color? borderColor;

  const _ColoredBadge({
    required this.text,
    required this.foreground,
    required this.background,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}

class _SmallLabel extends StatelessWidget {
  final String text;

  const _SmallLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: context.appSurfaceSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 7.5,
          fontWeight: FontWeight.w700,
          color: context.appTextSecondary,
        ),
      ),
    );
  }
}

class _FinalBadge extends StatelessWidget {
  const _FinalBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
// STEP 20. Participant Summary
// ============================================================

class _ParticipantSummary extends StatelessWidget {
  final List<ConsultationParticipantUiModel> participants;

  const _ParticipantSummary({required this.participants});

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return const SizedBox.shrink();
    }

    final visible = participants.take(3).toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < visible.length; index++)
          Transform.translate(
            offset: Offset(index == 0 ? 0 : -6.0 * index, 0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: context.appSurfaceSoft,
              child: Text(
                _initial(visible[index].doctorName),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: context.appBrand,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================
// STEP 21. Empty State
// ============================================================

class _EmptyTabState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _EmptyTabState({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: context.appTextDisabled),
            const SizedBox(height: 9),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, color: context.appTextSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STEP 22. Read Only Dock
// ============================================================

class _ReadOnlyActionDock extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ReadOnlyActionDock({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(top: BorderSide(color: context.appBorder)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: null,
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
          icon: Icon(icon, size: 16),
          label: Text(label),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 23. Opinion Result
// ============================================================

class _OpinionDialogResult {
  final String text;
  final bool isFinal;

  const _OpinionDialogResult({required this.text, required this.isFinal});
}

// ============================================================
// STEP 24. Helpers
// ============================================================

String _initial(String name) {
  final trimmed = name.trim();

  if (trimmed.isEmpty) {
    return '-';
  }

  return trimmed.substring(0, 1);
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

IconData _referenceIcon(String type) {
  final normalized = type.toUpperCase();

  if (normalized.contains('AI')) {
    return Icons.auto_awesome_outlined;
  }

  if (normalized.contains('검사') || normalized.contains('EXAM')) {
    return Icons.science_outlined;
  }

  if (normalized.contains('영상') || normalized.contains('IMAGE')) {
    return Icons.image_outlined;
  }

  if (normalized.contains('보고서') || normalized.contains('REPORT')) {
    return Icons.description_outlined;
  }

  return Icons.attach_file_rounded;
}
