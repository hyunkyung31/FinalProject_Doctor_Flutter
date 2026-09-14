import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../consultation_ui_models.dart';

// ============================================================
// STEP 1. Consultation Detail Panel
//
// 실제 Backend:
// - participants
// - references
// - opinions
// - accept / complete / withdraw
//
// 현재 GET /api/consultations/ 500으로 실제 연동 전.
// ============================================================

class ConsultationDetailPanel extends StatefulWidget {
  final ConsultationUiModel consultation;

  final VoidCallback onAccept;
  final VoidCallback onComplete;
  final VoidCallback onWithdraw;

  const ConsultationDetailPanel({
    super.key,
    required this.consultation,
    required this.onAccept,
    required this.onComplete,
    required this.onWithdraw,
  });

  @override
  State<ConsultationDetailPanel> createState() =>
      _ConsultationDetailPanelState();
}

class _ConsultationDetailPanelState extends State<ConsultationDetailPanel> {
  final TextEditingController _messageController = TextEditingController();

  // 현재 로그인 의료진 ID는 실제 Auth 연동 전 UI DEMO 기준입니다.
  // 실제 연결 시 AuthProvider의 user id로 교체합니다.
  static const int _demoCurrentDoctorId = 1;

  late List<ConsultationOpinionUiModel> _opinions;

  bool _isFinalOpinion = false;

  // ============================================================
  // STEP 2. Init / Update / Dispose
  // ============================================================

  @override
  void initState() {
    super.initState();

    _opinions = List<ConsultationOpinionUiModel>.from(
      widget.consultation.opinions,
    );
  }

  @override
  void didUpdateWidget(covariant ConsultationDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 다른 협진을 선택한 경우에만 대화 내역을 새로 불러옵니다.
    if (oldWidget.consultation.id != widget.consultation.id) {
      _opinions = List<ConsultationOpinionUiModel>.from(
        widget.consultation.opinions,
      );

      _messageController.clear();
      _isFinalOpinion = false;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();

    super.dispose();
  }

  // ============================================================
  // STEP 3. Helpers
  // ============================================================

  ConsultationParticipantUiModel? get _requester {
    for (final participant in widget.consultation.participants) {
      if (participant.roleLabel.contains('요청')) {
        return participant;
      }
    }

    if (widget.consultation.participants.isNotEmpty) {
      return widget.consultation.participants.first;
    }

    return null;
  }

  bool get _canWriteOpinion {
    return widget.consultation.status == ConsultationUiStatus.inProgress;
  }

  // ============================================================
  // STEP 4. UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildHeader(),
          _buildContextToolbar(),

          const Divider(height: 1, color: AppColors.border),

          Expanded(child: _buildConversation()),

          _buildBottomArea(),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 5. Header
  // ============================================================

  Widget _buildHeader() {
    final item = widget.consultation;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 13, 18, 12),
      color: AppColors.surface,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.groups_2_outlined,
              size: 20,
              color: AppColors.navy,
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
                        item.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    _StatusBadge(status: item.status),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  '${item.patientName} · ${item.patientMeta}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          const _DemoBadge(),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 6. Context Toolbar
  // ============================================================

  Widget _buildContextToolbar() {
    final item = widget.consultation;

    return Container(
      height: 49,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: AppColors.background,
      child: Row(
        children: [
          _ContextInfo(
            icon: Icons.local_hospital_outlined,
            text: item.assignedDepartment,
          ),

          const SizedBox(width: 16),

          _ContextInfo(
            icon: Icons.person_outline_rounded,
            text: item.assignedDoctorName,
          ),

          const SizedBox(width: 16),

          _ContextInfo(
            icon: Icons.schedule_outlined,
            text: '기한 ${_formatShortDateTime(item.dueAt)}',
          ),

          const Spacer(),

          _ToolbarButton(
            icon: Icons.group_outlined,
            label: '참여자 ${item.participants.length}',
            onTap: _showParticipantsDialog,
          ),

          const SizedBox(width: 6),

          _ToolbarButton(
            icon: Icons.attach_file_rounded,
            label: '참조 ${item.references.length}',
            onTap: _showReferencesDialog,
          ),

          const SizedBox(width: 6),

          _ToolbarButton(
            icon: Icons.info_outline_rounded,
            label: '협진 정보',
            onTap: _showConsultationInfoDialog,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 7. Conversation
  // ============================================================

  Widget _buildConversation() {
    final item = widget.consultation;

    return Container(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        children: [
          _DateDivider(text: _formatDate(item.createdAt)),

          const SizedBox(height: 12),

          _SystemMessage(
            text: '${_requester?.doctorName ?? '의료진'}이 협진을 요청했습니다.',
          ),

          const SizedBox(height: 14),

          _buildRequestBubble(),

          if (item.references.isNotEmpty) ...[
            const SizedBox(height: 16),

            _ConversationSectionLabel(
              icon: Icons.attach_file_rounded,
              text: '참조 자료 ${item.references.length}건',
            ),

            const SizedBox(height: 8),

            for (final reference in item.references) ...[
              _ReferenceAttachmentCard(
                reference: reference,
                onTap: () {
                  _showMessage('${reference.title} 연결은 실제 API 연동 후 구현합니다.');
                },
              ),
              const SizedBox(height: 7),
            ],
          ],

          if (item.status == ConsultationUiStatus.inProgress ||
              item.status == ConsultationUiStatus.completed) ...[
            const SizedBox(height: 12),

            _SystemMessage(
              text: item.status == ConsultationUiStatus.completed
                  ? '협진이 수락되어 의료진 의견을 공유했습니다.'
                  : '협진이 수락되었습니다. 의료진 의견을 공유할 수 있습니다.',
            ),
          ],

          if (_opinions.isNotEmpty) ...[
            const SizedBox(height: 14),

            for (final opinion in _opinions) ...[
              _OpinionBubble(
                opinion: opinion,
                isMine: opinion.doctorId == _demoCurrentDoctorId,
              ),
              const SizedBox(height: 11),
            ],
          ],

          if (item.status == ConsultationUiStatus.completed) ...[
            const SizedBox(height: 4),

            const _SystemMessage(text: '협진이 완료되었습니다.'),
          ],

          if (item.status == ConsultationUiStatus.withdrawn) ...[
            const SizedBox(height: 4),

            const _SystemMessage(text: '협진 요청이 철회되었습니다.'),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // STEP 8. Request Bubble
  // ============================================================

  Widget _buildRequestBubble() {
    final item = widget.consultation;
    final requester = _requester;

    final isMine = requester?.doctorId == _demoCurrentDoctorId;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                requester == null
                    ? '협진 요청'
                    : '${requester.doctorName} · ${requester.department}',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            const SizedBox(height: 5),

            Container(
              padding: const EdgeInsets.fromLTRB(13, 11, 13, 10),
              decoration: BoxDecoration(
                color: isMine ? AppColors.navy : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isMine ? 12 : 3),
                  bottomRight: Radius.circular(isMine ? 3 : 12),
                ),
                border: isMine ? null : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.subject,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isMine ? Colors.white : AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    item.note.isEmpty ? '협진 요청 내용이 없습니다.' : item.note,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.55,
                      color: isMine ? Colors.white : AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _formatTime(item.createdAt),
                    style: TextStyle(
                      fontSize: 8.5,
                      color: isMine ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STEP 9. Bottom Area
  // ============================================================

  Widget _buildBottomArea() {
    final status = widget.consultation.status;

    if (status == ConsultationUiStatus.requested) {
      return _buildRequestedFooter();
    }

    if (status == ConsultationUiStatus.inProgress) {
      return _buildComposer();
    }

    return _buildReadOnlyFooter();
  }

  // ============================================================
  // STEP 10. Requested Footer
  // ============================================================

  Widget _buildRequestedFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.mark_chat_unread_outlined,
            size: 16,
            color: AppColors.textSecondary,
          ),

          const SizedBox(width: 8),

          const Expanded(
            child: Text(
              '협진을 수락하면 담당 의료진과 의견을 주고받을 수 있습니다.',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ),

          OutlinedButton(
            onPressed: widget.onWithdraw,
            child: const Text('요청 철회'),
          ),

          const SizedBox(width: 8),

          FilledButton.icon(
            onPressed: widget.onAccept,
            style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
            icon: const Icon(Icons.check_rounded, size: 15),
            label: const Text('협진 수락'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 11. Chat Composer
  // ============================================================

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _ComposerIconButton(
                icon: Icons.attach_file_rounded,
                tooltip: '참조 자료',
                onPressed: _showReferencesDialog,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 42,
                    maxHeight: 88,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 3,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: '협진 의견을 입력해 주세요.',
                      hintStyle: TextStyle(
                        fontSize: 10,
                        color: AppColors.textDisabled,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              SizedBox(
                height: 42,
                child: FilledButton.icon(
                  onPressed: _sendOpinion,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 15),
                  label: const Text('전송', style: TextStyle(fontSize: 10)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              const SizedBox(width: 42),

              InkWell(
                onTap: () {
                  setState(() {
                    _isFinalOpinion = !_isFinalOpinion;
                  });
                },
                borderRadius: BorderRadius.circular(7),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: Checkbox(
                          value: _isFinalOpinion,
                          onChanged: (value) {
                            setState(() {
                              _isFinalOpinion = value ?? false;
                            });
                          },
                          visualDensity: VisualDensity.compact,
                        ),
                      ),

                      const SizedBox(width: 5),

                      Text(
                        '최종 의견으로 등록',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: _isFinalOpinion
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _isFinalOpinion
                              ? AppColors.navy
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              OutlinedButton.icon(
                onPressed: widget.onComplete,
                icon: const Icon(Icons.task_alt_rounded, size: 14),
                label: const Text('협진 완료', style: TextStyle(fontSize: 9.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 12. Read Only Footer
  // ============================================================

  Widget _buildReadOnlyFooter() {
    final completed =
        widget.consultation.status == ConsultationUiStatus.completed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Icon(
            completed ? Icons.task_alt_rounded : Icons.block_outlined,
            size: 15,
            color: AppColors.textSecondary,
          ),

          const SizedBox(width: 7),

          Text(
            completed
                ? '완료된 협진입니다. 대화 내역은 조회만 가능합니다.'
                : '철회된 협진입니다. 대화 내역은 조회만 가능합니다.',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 13. Send Opinion
  // ============================================================

  void _sendOpinion() {
    if (!_canWriteOpinion) {
      return;
    }

    final text = _messageController.text.trim();

    if (text.isEmpty) {
      _showMessage('협진 의견을 입력해 주세요.');

      return;
    }

    final opinion = ConsultationOpinionUiModel(
      id: DateTime.now().millisecondsSinceEpoch,
      doctorId: _demoCurrentDoctorId,
      doctorName: '김OO 의사',
      department: '순환기내과',
      opinionText: text,
      isFinal: _isFinalOpinion,
      createdAt: DateTime.now(),
    );

    setState(() {
      _opinions.add(opinion);

      _messageController.clear();
      _isFinalOpinion = false;
    });

    _showMessage('협진 의견이 UI에 추가되었습니다. 실제 POST API는 아직 연결하지 않았습니다.');
  }

  // ============================================================
  // STEP 14. Participants Dialog
  // ============================================================

  Future<void> _showParticipantsDialog() async {
    final participants = widget.consultation.participants;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 430,
            constraints: const BoxConstraints(maxHeight: 520),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogHeader(
                  title: '협진 참여자',
                  subtitle: '${participants.length}명',
                  icon: Icons.group_outlined,
                  onClose: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),

                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(14),
                    itemCount: participants.length,
                    separatorBuilder: (_, _) {
                      return const SizedBox(height: 7);
                    },
                    itemBuilder: (context, index) {
                      final participant = participants[index];

                      return _ParticipantDialogCard(participant: participant);
                    },
                  ),
                ),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();

                      _showMessage(
                        '참여자 추가는 Backend 협진 API 수정 후 doctor_id / role과 연결합니다.',
                      );
                    },
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 15),
                    label: const Text('참여자 추가'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // STEP 15. References Dialog
  // ============================================================

  Future<void> _showReferencesDialog() async {
    final references = widget.consultation.references;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 450,
            constraints: const BoxConstraints(maxHeight: 520),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogHeader(
                  title: '참조 자료',
                  subtitle: '${references.length}건',
                  icon: Icons.attach_file_rounded,
                  onClose: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),

                if (references.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Text(
                      '등록된 참조 자료가 없습니다.',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(14),
                      itemCount: references.length,
                      separatorBuilder: (_, _) {
                        return const SizedBox(height: 7);
                      },
                      itemBuilder: (context, index) {
                        final reference = references[index];

                        return _ReferenceAttachmentCard(
                          reference: reference,
                          onTap: () {
                            Navigator.of(dialogContext).pop();

                            _showMessage(
                              '${reference.title} 연결은 실제 API 연동 후 구현합니다.',
                            );
                          },
                        );
                      },
                    ),
                  ),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();

                      _showMessage('reference_type 허용값 확인 후 참조 추가 API를 연결합니다.');
                    },
                    icon: const Icon(Icons.add_link_rounded, size: 15),
                    label: const Text('참조 추가'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // STEP 16. Consultation Info Dialog
  // ============================================================

  Future<void> _showConsultationInfoDialog() async {
    final item = widget.consultation;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 430,
            padding: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogHeader(
                  title: '협진 정보',
                  subtitle: 'Consultation #${item.id}',
                  icon: Icons.info_outline_rounded,
                  onClose: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
                  child: Column(
                    children: [
                      _DialogInfoRow(
                        label: '환자',
                        value: '${item.patientName} · ${item.patientMeta}',
                      ),
                      _DialogInfoRow(
                        label: 'Patient ID',
                        value: '#${item.patientId}',
                      ),
                      _DialogInfoRow(
                        label: 'Encounter',
                        value: '#${item.encounterId}',
                      ),
                      _DialogInfoRow(label: '우선순위', value: item.priority),
                      _DialogInfoRow(
                        label: '담당 의료진',
                        value: item.assignedDoctorName,
                      ),
                      _DialogInfoRow(
                        label: '진료과',
                        value: item.assignedDepartment,
                      ),
                      _DialogInfoRow(
                        label: '요청일',
                        value: _formatDateTime(item.createdAt),
                      ),
                      _DialogInfoRow(
                        label: '기한',
                        value: _formatDateTime(item.dueAt),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // STEP 17. Message
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
// STEP 18. Opinion Bubble
// ============================================================

class _OpinionBubble extends StatelessWidget {
  final ConsultationOpinionUiModel opinion;
  final bool isMine;

  const _OpinionBubble({required this.opinion, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (opinion.isFinal) ...[
                  const _FinalOpinionBadge(),
                  const SizedBox(width: 6),
                ],

                Text(
                  '${opinion.doctorName} · ${opinion.department}',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            Container(
              padding: const EdgeInsets.fromLTRB(13, 10, 13, 9),
              decoration: BoxDecoration(
                color: opinion.isFinal
                    ? AppColors.successBackground
                    : isMine
                    ? AppColors.navy
                    : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isMine ? 12 : 3),
                  bottomRight: Radius.circular(isMine ? 3 : 12),
                ),
                border: Border.all(
                  color: opinion.isFinal
                      ? AppColors.success
                      : isMine
                      ? AppColors.navy
                      : AppColors.border,
                ),
              ),
              child: Text(
                opinion.opinionText,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.55,
                  color: opinion.isFinal
                      ? AppColors.textPrimary
                      : isMine
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
              ),
            ),

            const SizedBox(height: 4),

            Text(
              _formatTime(opinion.createdAt),
              style: const TextStyle(
                fontSize: 8.5,
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
// STEP 19. Reference Attachment
// ============================================================

class _ReferenceAttachmentCard extends StatelessWidget {
  final ConsultationReferenceUiModel reference;
  final VoidCallback onTap;

  const _ReferenceAttachmentCard({
    required this.reference,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  size: 16,
                  color: AppColors.navy,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reference.title,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      reference.description,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  reference.referenceTypeLabel,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),

              const SizedBox(width: 5),

              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 20. Toolbar Components
// ============================================================

class _ContextInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContextInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),

        const SizedBox(width: 5),

        Text(
          text,
          style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: AppColors.navy),

            const SizedBox(width: 4),

            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STEP 21. System / Divider
// ============================================================

class _DateDivider extends StatelessWidget {
  final String text;

  const _DateDivider({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 8.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),

        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

class _SystemMessage extends StatelessWidget {
  final String text;

  const _SystemMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 8.8, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _ConversationSectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ConversationSectionLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),

        const SizedBox(width: 5),

        Text(
          text,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STEP 22. Composer Button
// ============================================================

class _ComposerIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ComposerIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: AppColors.navy),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 23. Dialog Components
// ============================================================

class _DialogHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onClose;

  const _DialogHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 13, 10, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: AppColors.navy),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ParticipantDialogCard extends StatelessWidget {
  final ConsultationParticipantUiModel participant;

  const _ParticipantDialogCard({required this.participant});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.surfaceSoft,
            child: Icon(
              Icons.person_outline_rounded,
              size: 16,
              color: AppColors.navy,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.doctorName,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  participant.department,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Text(
            participant.roleLabel,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _DialogInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
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
                fontSize: 10,
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

// ============================================================
// STEP 24. Badges
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
        background = AppColors.surfaceSoft;
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _DemoBadge extends StatelessWidget {
  const _DemoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warningBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'UI DEMO',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: AppColors.warning,
        ),
      ),
    );
  }
}

class _FinalOpinionBadge extends StatelessWidget {
  const _FinalOpinionBadge();

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
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: AppColors.success,
        ),
      ),
    );
  }
}

// ============================================================
// STEP 25. Date Helpers
// ============================================================

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

String _formatShortDateTime(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');

  final day = date.day.toString().padLeft(2, '0');

  final hour = date.hour.toString().padLeft(2, '0');

  final minute = date.minute.toString().padLeft(2, '0');

  return '$month.$day $hour:$minute';
}

String _formatDateTime(DateTime date) {
  return '${_formatDate(date)} ${_formatTime(date)}';
}
