import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../data/services/appointment_questionnaire_service.dart';
import '../appointment_ui_model.dart';
import '../questionnaire_ui_models.dart';

// ============================================================
// STEP 1. Questionnaire Management Panel
//
// - 응답 없음: 미제출
// - SUBMITTED: 검토 대기
// - REVIEWED: 검토 완료
// ============================================================

class AppointmentQuestionnairePanel extends StatefulWidget {
  final List<AppointmentUiModel> appointments;
  final DateTime selectedDate;

  const AppointmentQuestionnairePanel({
    super.key,
    required this.appointments,
    required this.selectedDate,
  });

  @override
  State<AppointmentQuestionnairePanel> createState() =>
      _AppointmentQuestionnairePanelState();
}

class _AppointmentQuestionnairePanelState
    extends State<AppointmentQuestionnairePanel> {
  final Map<int, List<QuestionnaireResponseUiModel>> _responseMap = {};
  final Set<int> _failedReservationIds = {};

  bool _isLoading = false;
  int? _selectedReservationId;
  int _loadGeneration = 0;

  List<AppointmentUiModel> get _activeAppointments {
    final result = widget.appointments
        .where((item) => item.status != AppointmentStatus.canceled)
        .toList();

    result.sort((a, b) => a.reservedAt.compareTo(b.reservedAt));

    return result;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuestionnaires();
    });
  }

  @override
  void didUpdateWidget(covariant AppointmentQuestionnairePanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldKey = _appointmentKey(oldWidget.appointments);
    final newKey = _appointmentKey(widget.appointments);

    if (oldKey != newKey) {
      _loadQuestionnaires();
    }
  }

  String _appointmentKey(List<AppointmentUiModel> appointments) {
    final ids = appointments.map((item) => item.id).toList()..sort();
    return ids.join(',');
  }

  // ============================================================
  // STEP 2. 선택 날짜 예약의 문진 조회
  // ============================================================

  Future<void> _loadQuestionnaires() async {
    final generation = ++_loadGeneration;
    final appointments = _activeAppointments;

    if (appointments.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _responseMap.clear();
        _failedReservationIds.clear();
        _selectedReservationId = null;
      });

      return;
    }

    setState(() {
      _isLoading = true;
      _responseMap.clear();
      _failedReservationIds.clear();
    });

    final auth = context.read<AuthProvider>();

    final service = AppointmentQuestionnaireService(
      apiClient: auth.authService.apiClient,
    );

    final results = await Future.wait(
      appointments.map((appointment) async {
        try {
          final responses = await service.fetchQuestionnaireResponses(
            appointment.id,
          );

          return _QuestionnaireFetchResult(
            reservationId: appointment.id,
            responses: responses,
          );
        } catch (error) {
          debugPrint(
            '[QUESTIONNAIRE] 조회 실패: '
            'reservationId=${appointment.id}, error=$error',
          );

          return _QuestionnaireFetchResult(
            reservationId: appointment.id,
            responses: const [],
            failed: true,
          );
        }
      }),
    );

    if (!mounted || generation != _loadGeneration) {
      return;
    }

    final responseMap = <int, List<QuestionnaireResponseUiModel>>{};
    final failedIds = <int>{};

    for (final result in results) {
      responseMap[result.reservationId] = result.responses;

      if (result.failed) {
        failedIds.add(result.reservationId);
      }
    }

    final reservationIds = appointments.map((item) => item.id).toSet();

    var selectedReservationId = _selectedReservationId;

    if (selectedReservationId == null ||
        !reservationIds.contains(selectedReservationId)) {
      selectedReservationId = _findFirstReviewPendingId(
        appointments,
        responseMap,
        failedIds,
      );

      selectedReservationId ??= appointments.first.id;
    }

    setState(() {
      _responseMap
        ..clear()
        ..addAll(responseMap);

      _failedReservationIds
        ..clear()
        ..addAll(failedIds);

      _selectedReservationId = selectedReservationId;
      _isLoading = false;
    });
  }

  int? _findFirstReviewPendingId(
    List<AppointmentUiModel> appointments,
    Map<int, List<QuestionnaireResponseUiModel>> responseMap,
    Set<int> failedIds,
  ) {
    for (final appointment in appointments) {
      if (failedIds.contains(appointment.id)) {
        continue;
      }

      final responses = responseMap[appointment.id] ?? const [];

      if (_resolveStatus(responses) == _QuestionnaireDisplayStatus.submitted) {
        return appointment.id;
      }
    }

    return null;
  }

  // ============================================================
  // STEP 3. Status
  // ============================================================

  _QuestionnaireDisplayStatus _statusFor(int reservationId) {
    if (_failedReservationIds.contains(reservationId)) {
      return _QuestionnaireDisplayStatus.failed;
    }

    return _resolveStatus(_responseMap[reservationId] ?? const []);
  }

  _QuestionnaireDisplayStatus _resolveStatus(
    List<QuestionnaireResponseUiModel> responses,
  ) {
    if (responses.isEmpty) {
      return _QuestionnaireDisplayStatus.notSubmitted;
    }

    final allReviewed = responses.every(
      (item) => item.status == QuestionnaireResponseStatus.reviewed,
    );

    if (allReviewed) {
      return _QuestionnaireDisplayStatus.reviewed;
    }

    return _QuestionnaireDisplayStatus.submitted;
  }

  int _countStatus(_QuestionnaireDisplayStatus status) {
    return _activeAppointments
        .where((item) => _statusFor(item.id) == status)
        .length;
  }

  // ============================================================
  // STEP 4. UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final appointments = _activeAppointments;
    final selectedAppointment = _findAppointment(_selectedReservationId);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),

          if (_isLoading) const LinearProgressIndicator(minHeight: 2),

          _buildSummary(context),

          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),

          Expanded(
            child: appointments.isEmpty
                ? const _EmptyQuestionnaireDay()
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 310,
                        child: _buildReservationList(context, appointments),
                      ),

                      VerticalDivider(
                        width: 1,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),

                      Expanded(
                        child: _buildDetail(context, selectedAppointment),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final date = widget.selectedDate;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '사전 문진 관리',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 3),

                Text(
                  '${date.year}.${_two(date.month)}.${_two(date.day)} '
                  '예약 환자의 제출 문진을 확인합니다.',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: '새로고침',
            onPressed: _isLoading ? null : _loadQuestionnaires,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    final total = _activeAppointments.length;
    final submitted = _countStatus(_QuestionnaireDisplayStatus.submitted);
    final reviewed = _countStatus(_QuestionnaireDisplayStatus.reviewed);
    final notSubmitted = _countStatus(_QuestionnaireDisplayStatus.notSubmitted);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: '예약 환자',
              value: total,
              icon: Icons.event_available_outlined,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              label: '검토 대기',
              value: submitted,
              icon: Icons.pending_actions_outlined,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              label: '검토 완료',
              value: reviewed,
              icon: Icons.task_alt_rounded,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              label: '미제출',
              value: notSubmitted,
              icon: Icons.assignment_late_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationList(
    BuildContext context,
    List<AppointmentUiModel> appointments,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: appointments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 7),
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        final selected = appointment.id == _selectedReservationId;
        final status = _statusFor(appointment.id);

        return _QuestionnaireReservationTile(
          appointment: appointment,
          status: status,
          selected: selected,
          onTap: () {
            setState(() {
              _selectedReservationId = appointment.id;
            });
          },
        );
      },
    );
  }

  Widget _buildDetail(BuildContext context, AppointmentUiModel? appointment) {
    if (appointment == null) {
      return const _SelectQuestionnairePatient();
    }

    final status = _statusFor(appointment.id);

    if (status == _QuestionnaireDisplayStatus.failed) {
      return _QuestionnaireMessage(
        icon: Icons.sync_problem_rounded,
        title: '문진 조회에 실패했습니다.',
        message: '서버 연결 후 새로고침해 주세요.',
        actionLabel: '다시 조회',
        onPressed: _loadQuestionnaires,
      );
    }

    final responses = _responseMap[appointment.id] ?? const [];

    if (responses.isEmpty) {
      return const _QuestionnaireMessage(
        icon: Icons.assignment_outlined,
        title: '아직 제출된 문진이 없습니다.',
        message: '작성 중인 DRAFT 문진은 Staff 조회 API에서 제외됩니다.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
      children: [
        _PatientQuestionnaireHeader(appointment: appointment, status: status),
        const SizedBox(height: 14),

        for (var index = 0; index < responses.length; index++) ...[
          _QuestionnaireResponseCard(response: responses[index]),
          if (index != responses.length - 1) const SizedBox(height: 12),
        ],

        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 17,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '현재 화면은 기존 Backend의 제출 문진 조회 기능만 사용합니다. '
                  '문진 수정이나 REVIEWED 상태 변경은 수행하지 않습니다.',
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.45,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  AppointmentUiModel? _findAppointment(int? reservationId) {
    if (reservationId == null) {
      return null;
    }

    for (final appointment in _activeAppointments) {
      if (appointment.id == reservationId) {
        return appointment;
      }
    }

    return null;
  }
}

// ============================================================
// STEP 5. Reservation Tile
// ============================================================

class _QuestionnaireReservationTile extends StatelessWidget {
  final AppointmentUiModel appointment;
  final _QuestionnaireDisplayStatus status;
  final bool selected;
  final VoidCallback onTap;

  const _QuestionnaireReservationTile({
    required this.appointment,
    required this.status,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final time = appointment.reservedAt.toLocal();

    return Material(
      color: selected
          ? Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.45)
          : Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${_two(time.hour)}:${_two(time.minute)}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment.applicantName.isEmpty
                          ? '예약 #${appointment.id}'
                          : appointment.applicantName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _QuestionnaireStatusBadge(status: status),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 17,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 6. Detail Header
// ============================================================

class _PatientQuestionnaireHeader extends StatelessWidget {
  final AppointmentUiModel appointment;
  final _QuestionnaireDisplayStatus status;

  const _PatientQuestionnaireHeader({
    required this.appointment,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final reservedAt = appointment.reservedAt.toLocal();

    return Row(
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.person_outline_rounded,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appointment.applicantName.isEmpty
                    ? '예약 #${appointment.id}'
                    : appointment.applicantName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '예약 ${reservedAt.year}.${_two(reservedAt.month)}.'
                '${_two(reservedAt.day)} '
                '${_two(reservedAt.hour)}:${_two(reservedAt.minute)}',
                style: TextStyle(
                  fontSize: 10.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        _QuestionnaireStatusBadge(status: status),
      ],
    );
  }
}

// ============================================================
// STEP 7. Response Card
// ============================================================

class _QuestionnaireResponseCard extends StatelessWidget {
  final QuestionnaireResponseUiModel response;

  const _QuestionnaireResponseCard({required this.response});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    response.displayTemplateName,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _ResponseStatusBadge(status: response.status),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
            child: Wrap(
              spacing: 18,
              runSpacing: 6,
              children: [
                _MetaText(
                  label: '제출',
                  value: _formatDateTime(response.submittedAt),
                ),
                if (response.reviewedAt != null)
                  _MetaText(
                    label: '검토',
                    value: _formatDateTime(response.reviewedAt),
                  ),
                if (response.reviewedBy != null)
                  _MetaText(label: '검토자 ID', value: '#${response.reviewedBy}'),
              ],
            ),
          ),
          if (response.answers.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 6, 13, 14),
              child: Text(
                '표시할 응답 항목이 없습니다.',
                style: TextStyle(
                  fontSize: 10.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ..._buildAnswerWidgets(response.answers),
        ],
      ),
    );
  }
}

List<Widget> _buildAnswerWidgets(List<QuestionnaireAnswerUiModel> answers) {
  final widgets = <Widget>[];
  int? previousStep;

  for (final answer in answers) {
    final step = answer.questionStep;

    if (step != null && step != previousStep) {
      widgets.add(_QuestionnaireStepHeader(step: step));

      previousStep = step;
    }

    widgets.add(_AnswerRow(answer: answer));
  }

  return widgets;
}

class _QuestionnaireStepHeader extends StatelessWidget {
  final int step;

  const _QuestionnaireStepHeader({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 9, 13, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Text(
        '$step단계',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  final QuestionnaireAnswerUiModel answer;

  const _AnswerRow({required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Text(
              answer.displayQuestion,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.4,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 4,
            child: Text(
              answer.displayAnswer,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 10.5,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 8. Common Widgets
// ============================================================

class _SummaryCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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

class _QuestionnaireStatusBadge extends StatelessWidget {
  final _QuestionnaireDisplayStatus status;

  const _QuestionnaireStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: config.foreground,
        ),
      ),
    );
  }
}

class _ResponseStatusBadge extends StatelessWidget {
  final QuestionnaireResponseStatus status;

  const _ResponseStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final displayStatus = switch (status) {
      QuestionnaireResponseStatus.reviewed =>
        _QuestionnaireDisplayStatus.reviewed,
      QuestionnaireResponseStatus.submitted =>
        _QuestionnaireDisplayStatus.submitted,
      QuestionnaireResponseStatus.unknown => _QuestionnaireDisplayStatus.failed,
    };

    return _QuestionnaireStatusBadge(status: displayStatus);
  }
}

class _MetaText extends StatelessWidget {
  final String label;
  final String value;

  const _MetaText({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label  ',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
      style: const TextStyle(fontSize: 9.5),
    );
  }
}

class _QuestionnaireMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;

  const _QuestionnaireMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 38,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.45,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onPressed != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SelectQuestionnairePatient extends StatelessWidget {
  const _SelectQuestionnairePatient();

  @override
  Widget build(BuildContext context) {
    return const _QuestionnaireMessage(
      icon: Icons.assignment_ind_outlined,
      title: '예약 환자를 선택해 주세요.',
      message: '왼쪽 목록에서 환자를 선택하면 제출된 사전 문진을 확인할 수 있습니다.',
    );
  }
}

class _EmptyQuestionnaireDay extends StatelessWidget {
  const _EmptyQuestionnaireDay();

  @override
  Widget build(BuildContext context) {
    return const _QuestionnaireMessage(
      icon: Icons.event_busy_outlined,
      title: '해당 날짜의 예약이 없습니다.',
      message: '왼쪽 달력에서 예약이 있는 날짜를 선택해 주세요.',
    );
  }
}

// ============================================================
// STEP 9. Local Types / Helpers
// ============================================================

enum _QuestionnaireDisplayStatus { notSubmitted, submitted, reviewed, failed }

class _QuestionnaireFetchResult {
  final int reservationId;
  final List<QuestionnaireResponseUiModel> responses;
  final bool failed;

  const _QuestionnaireFetchResult({
    required this.reservationId,
    required this.responses,
    this.failed = false,
  });
}

class _StatusConfig {
  final String label;
  final Color foreground;
  final Color background;

  const _StatusConfig({
    required this.label,
    required this.foreground,
    required this.background,
  });
}

_StatusConfig _statusConfig(
  BuildContext context,
  _QuestionnaireDisplayStatus status,
) {
  final colors = Theme.of(context).colorScheme;

  switch (status) {
    case _QuestionnaireDisplayStatus.notSubmitted:
      return _StatusConfig(
        label: '미제출',
        foreground: colors.onSurfaceVariant,
        background: colors.surfaceContainerHighest,
      );
    case _QuestionnaireDisplayStatus.submitted:
      return _StatusConfig(
        label: '검토 대기',
        foreground: colors.onTertiaryContainer,
        background: colors.tertiaryContainer,
      );
    case _QuestionnaireDisplayStatus.reviewed:
      return _StatusConfig(
        label: '검토 완료',
        foreground: colors.onPrimaryContainer,
        background: colors.primaryContainer,
      );
    case _QuestionnaireDisplayStatus.failed:
      return _StatusConfig(
        label: '조회 실패',
        foreground: colors.onErrorContainer,
        background: colors.errorContainer,
      );
  }
}

String _two(int value) {
  return value.toString().padLeft(2, '0');
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return '-';
  }

  final local = value.toLocal();

  return '${local.year}.${_two(local.month)}.${_two(local.day)} '
      '${_two(local.hour)}:${_two(local.minute)}';
}
