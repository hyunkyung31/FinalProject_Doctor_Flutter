import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../patients/presentation/widgets/patient_detail_tabs.dart';
import '../appointment_ui_model.dart';

// ============================================================
// STEP 1. Appointment Detail Panel
// ============================================================

class AppointmentDetailPanel extends StatelessWidget {
  final AppointmentUiModel? appointment;
  final PatientUiModel? patient;

  final bool canManage;

  final ValueChanged<AppointmentUiModel> onAccept;

  const AppointmentDetailPanel({
    super.key,
    required this.appointment,
    required this.patient,
    required this.canManage,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final item = appointment;

    if (item == null) {
      return const _EmptyDetail();
    }

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ======================================================
          // Header
          // ======================================================
          _DetailHeader(appointment: item, patient: patient),

          Divider(height: 1, color: context.appBorder),

          // ======================================================
          // Body
          // ======================================================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ================================================
                  // 신청자 정보
                  // ================================================
                  _DetailCard(
                    title: '신청자 정보',
                    icon: Icons.person_outline_rounded,
                    children: [
                      _DetailRow(label: '이름', value: item.applicantName),

                      _DetailRow(label: '생년월일', value: item.applicantBirthDate),

                      _DetailRow(label: '성별', value: item.genderText),

                      _DetailRow(
                        label: '연락처',
                        value: _formatContact(item.applicantContact),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ================================================
                  // 예약 정보
                  // ================================================
                  _DetailCard(
                    title: '예약 정보',
                    icon: Icons.calendar_today_outlined,
                    children: [
                      _DetailRow(label: '예약번호', value: '#${item.id}'),

                      _DetailRow(
                        label: '예약 일시',
                        value: _formatDateTime(item.reservedAt),
                      ),

                      _DetailRow(
                        label: '신청일',
                        value: _formatDateTime(item.createdAt),
                      ),

                      _DetailRow(
                        label: '상태',
                        valueWidget: _StatusBadge(status: item.status),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ================================================
                  // 환자 연결 정보
                  // ================================================
                  _DetailCard(
                    title: '환자 연결',
                    icon: Icons.link_rounded,
                    children: [
                      _DetailRow(
                        label: '연결 상태',
                        value: patient == null ? '아직 연결되지 않음' : '연결됨',
                      ),

                      if (patient != null) ...[
                        _DetailRow(label: '환자명', value: patient!.name),

                        _DetailRow(
                          label: '환자번호',
                          value: patient!.medicalRecordNo.isEmpty
                              ? '#${patient!.patientId}'
                              : patient!.medicalRecordNo,
                        ),

                        _DetailRow(label: '생년월일', value: patient!.birthDate),

                        _DetailRow(label: '성별', value: patient!.gender),

                        _DetailRow(
                          label: '연락처',
                          value: patient!.phone.isEmpty
                              ? '-'
                              : _formatContact(patient!.phone),
                        ),
                      ],

                      _DetailRow(
                        label: '담당 의료진',
                        value: item.doctor == null ? '-' : '#${item.doctor}',
                      ),

                      _DetailRow(
                        label: '진료과',
                        value: item.department == null
                            ? '-'
                            : '#${item.department}',
                      ),
                    ],
                  ),

                  // ================================================
                  // ACCEPTED
                  // ================================================
                  if (item.status == AppointmentStatus.accepted) ...[
                    const SizedBox(height: 12),

                    _DetailCard(
                      title: '승인 정보',
                      icon: Icons.verified_outlined,
                      children: [
                        _DetailRow(
                          label: '승인일',
                          value: item.acceptedAt == null
                              ? '-'
                              : _formatDateTime(item.acceptedAt!),
                        ),

                        _DetailRow(
                          label: '승인자',
                          value: item.acceptedBy == null
                              ? '-'
                              : '#${item.acceptedBy}',
                        ),
                      ],
                    ),
                  ],

                  // ================================================
                  // CANCELED
                  // ================================================
                  if (item.status == AppointmentStatus.canceled) ...[
                    const SizedBox(height: 12),

                    _DetailCard(
                      title: '취소 정보',
                      icon: Icons.event_busy_outlined,
                      children: [
                        _DetailRow(
                          label: '취소일',
                          value: item.canceledAt == null
                              ? '-'
                              : _formatDateTime(item.canceledAt!),
                        ),

                        _DetailRow(
                          label: '취소 사유',
                          value: item.cancelReason ?? '-',
                        ),

                        _DetailRow(
                          label: '취소 처리자',
                          value: item.canceledBy == null
                              ? '-'
                              : '#${item.canceledBy}',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ======================================================
          // Footer Action
          // REQUESTED + 관리 권한일 때만 승인 표시
          // ======================================================
          if (item.status == AppointmentStatus.requested)
            _ActionFooter(
              appointment: item,
              canManage: canManage,
              onAccept: () {
                onAccept(item);
              },
            ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 2. Header
// ============================================================

class _DetailHeader extends StatelessWidget {
  final AppointmentUiModel appointment;
  final PatientUiModel? patient;

  const _DetailHeader({required this.appointment, required this.patient});

  @override
  Widget build(BuildContext context) {
    final displayName = patient?.name ?? appointment.applicantName;

    final displayAge = patient?.age ?? appointment.age;

    final displayGender = patient?.gender ?? appointment.genderText;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.appSurfaceSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.event_note_outlined,
              size: 21,
              color: context.appBrand,
            ),
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
                        displayName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ),

                    const SizedBox(width: 7),

                    Text(
                      '$displayAge세 · $displayGender',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: context.appTextSecondary,
                      ),
                    ),

                    const SizedBox(width: 9),

                    _StatusBadge(status: appointment.status),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  '예약 #${appointment.id} · '
                  '${_formatDateTime(appointment.reservedAt)}',
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
// STEP 3. Action Footer
// ============================================================

class _ActionFooter extends StatelessWidget {
  final AppointmentUiModel appointment;
  final bool canManage;

  final VoidCallback onAccept;

  const _ActionFooter({
    required this.appointment,
    required this.canManage,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(top: BorderSide(color: context.appBorder)),
      ),
      child: canManage
          ? Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '예약 승인 대기',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        color: context.appTextPrimary,
                        ),
                      ),

                      SizedBox(height: 3),

                      Text(
                        '신청 정보를 확인한 후 예약을 승인해 주세요.',
                        style: TextStyle(
                          fontSize: 9.5,
                        color: context.appTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                FilledButton.icon(
                  onPressed: onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(112, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text(
                    '예약 승인',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 16,
                  color: context.appTextSecondary,
                ),

                SizedBox(width: 7),

                Text(
                  '예약 조회 권한만 있습니다.',
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
// STEP 4. Detail Card
// ============================================================

class _DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _DetailCard({
    required this.title,
    required this.icon,
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

              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.appTextPrimary,
                ),
              ),
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
// STEP 5. Detail Row
// ============================================================

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;

  const _DetailRow({required this.label, this.value, this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: context.appTextSecondary,
              ),
            ),
          ),

          Expanded(
            child:
                valueWidget ??
                Text(
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
// STEP 6. Status Badge
// ============================================================

class _StatusBadge extends StatelessWidget {
  final AppointmentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color foreground;
    Color background;

    switch (status) {
      case AppointmentStatus.requested:
        foreground = AppColors.warning;
        background = AppColors.warningBackground;
        break;

      case AppointmentStatus.accepted:
        foreground = AppColors.success;
        background = AppColors.successBackground;
        break;

      case AppointmentStatus.canceled:
        foreground = AppColors.danger;
        background = AppColors.dangerBackground;
        break;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status.label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 7. Empty Detail
// ============================================================

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 38,
              color: context.appTextDisabled,
            ),

            SizedBox(height: 10),

            Text(
              '예약을 선택해 주세요.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.appTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STEP 8. Date Format
// ============================================================

String _formatDateTime(DateTime date) {
  final local = date.toLocal();

  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '${local.year}.$month.$day $hour:$minute';
}

// ============================================================
// STEP 9. Contact Format
// ============================================================

String _formatContact(String value) {
  final numbers = value.replaceAll(RegExp(r'[^0-9]'), '');

  if (numbers.startsWith('82') && numbers.length >= 11) {
    final local = '0${numbers.substring(2)}';

    if (local.length == 11) {
      return '${local.substring(0, 3)}-'
          '${local.substring(3, 7)}-'
          '${local.substring(7)}';
    }
  }

  if (numbers.length == 11) {
    return '${numbers.substring(0, 3)}-'
        '${numbers.substring(3, 7)}-'
        '${numbers.substring(7)}';
  }

  return value;
}
