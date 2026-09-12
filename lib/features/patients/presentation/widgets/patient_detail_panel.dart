import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'patient_detail_tabs.dart';

// ============================================================
// STEP 1. Patient Detail Panel
// ============================================================

class PatientDetailPanel extends StatelessWidget {
  final PatientUiModel patient;

  final PatientDetailTab selectedTab;

  final ValueChanged<PatientDetailTab> onTabChanged;

  const PatientDetailPanel({
    super.key,
    required this.patient,
    required this.selectedTab,
    required this.onTabChanged,
  });

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
          // ======================================================
          // Patient Header
          // ======================================================
          _PatientHeader(patient: patient),

          // ======================================================
          // Tabs
          // ======================================================
          PatientDetailTabs(selectedTab: selectedTab, onChanged: onTabChanged),

          // ======================================================
          // Tab Content
          // ======================================================
          Expanded(child: _buildTabContent(context)),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 2. Tab Content
  // ============================================================

  Widget _buildTabContent(BuildContext context) {
    switch (selectedTab) {
      case PatientDetailTab.overview:
        return _OverviewTab(patient: patient);

      case PatientDetailTab.timeline:
        return _TimelineTab(patient: patient);

      case PatientDetailTab.examinations:
        return _ExaminationTab(patient: patient);

      case PatientDetailTab.imaging:
        return _ImagingTab(patient: patient);

      case PatientDetailTab.ai:
        return _AiTab(patient: patient);
    }
  }
}

// ============================================================
// STEP 3. Patient Header
// ============================================================

class _PatientHeader extends StatelessWidget {
  final PatientUiModel patient;

  const _PatientHeader({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 13),
      color: AppColors.surface,
      child: Row(
        children: [
          // ======================================================
          // Avatar
          // ======================================================
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 24,
              color: AppColors.navy,
            ),
          ),

          const SizedBox(width: 13),

          // ======================================================
          // Patient Information
          // ======================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      patient.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Text(
                      '${patient.age}세 · ${patient.gender}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(width: 10),

                    _StatusBadge(
                      text: patient.careType,
                      color: AppColors.primaryBlue,
                    ),

                    if (patient.highRisk) ...[
                      const SizedBox(width: 6),

                      _StatusBadge(text: '고위험', color: AppColors.danger),
                    ],

                    if (patient.aiPending) ...[
                      const SizedBox(width: 6),

                      _StatusBadge(text: 'AI 검토 대기', color: AppColors.warning),
                    ],
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  '${patient.id}   ·   ${patient.department}   ·   ${patient.doctorName}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  patient.currentTask,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // Quick Button
          // ======================================================
          OutlinedButton.icon(
            onPressed: () {
              _showMessage(context, '환자 상세 기능은 추후 연결합니다.');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy,
              minimumSize: const Size(100, 38),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 15),
            label: const Text(
              '환자 정보',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 4. Overview Tab
// ============================================================

class _OverviewTab extends StatelessWidget {
  final PatientUiModel patient;

  const _OverviewTab({required this.patient});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ======================================================
          // 1행
          // ======================================================
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InfoCard(
                  title: '기본 정보',
                  icon: Icons.badge_outlined,
                  children: [
                    _InfoRow(label: '환자번호', value: patient.id),
                    _InfoRow(label: '연락처', value: patient.phone),
                    _InfoRow(label: '진료 구분', value: patient.careType),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _InfoCard(
                  title: '주요 임상 정보',
                  icon: Icons.medical_information_outlined,
                  children: [
                    _InfoRow(label: '주요 진단', value: patient.primaryDiagnosis),
                    _InfoRow(label: '위험 요인', value: patient.riskFactors),
                    _InfoRow(label: '알레르기', value: patient.allergy),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ======================================================
          // 2행
          // ======================================================
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InfoCard(
                  title: '최근 검사',
                  icon: Icons.science_outlined,
                  children: [
                    _ImportantText(text: patient.latestExam),
                    const SizedBox(height: 5),
                    Text(
                      patient.latestExamDate,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _InfoCard(
                  title: 'AI 분석',
                  icon: Icons.auto_awesome_outlined,
                  children: [
                    _ImportantText(text: patient.aiSummary),
                    const SizedBox(height: 7),
                    _StatusBadge(
                      text: patient.aiPending ? '의료진 검토 대기' : '검토 완료',
                      color: patient.aiPending
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ======================================================
          // 다음 일정
          // ======================================================
          _InfoCard(
            title: '다음 일정',
            icon: Icons.event_available_outlined,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: AppColors.navy,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      patient.nextAppointment,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 5. Timeline Tab
// ============================================================

class _TimelineTab extends StatelessWidget {
  final PatientUiModel patient;

  const _TimelineTab({required this.patient});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _TimelineItem(
          date: '2026.09.12',
          title: patient.currentTask,
          description: '현재 진행 중인 진료 업무',
          icon: Icons.medical_services_outlined,
          color: AppColors.primaryBlue,
        ),

        _TimelineItem(
          date: patient.latestExamDate,
          title: patient.latestExam,
          description: '최근 검사 결과 등록',
          icon: Icons.science_outlined,
          color: AppColors.success,
        ),

        _TimelineItem(
          date: '2026.09.11',
          title: 'AI 분석',
          description: patient.aiSummary,
          icon: Icons.auto_awesome_outlined,
          color: AppColors.warning,
        ),

        const _TimelineItem(
          date: '2026.08.31',
          title: '순환기내과 외래 진료',
          description: '경과 관찰 및 추가 검사 계획 수립',
          icon: Icons.local_hospital_outlined,
          color: AppColors.secondaryBlue,
          last: true,
        ),
      ],
    );
  }
}

// ============================================================
// STEP 6. Examination Tab
// ============================================================

class _ExaminationTab extends StatelessWidget {
  final PatientUiModel patient;

  const _ExaminationTab({required this.patient});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _RecordCard(
          icon: Icons.favorite_outline_rounded,
          title: patient.latestExam,
          subtitle: '${patient.latestExamDate} · 결과 확인 가능',
          status: '완료',
          statusColor: AppColors.success,
          onTap: () {
            _showMessage(context, '${patient.latestExam} 상세');
          },
        ),

        const SizedBox(height: 9),

        _RecordCard(
          icon: Icons.bloodtype_outlined,
          title: '혈액 검사',
          subtitle: '2026.09.10 · CBC / Lipid / HbA1c',
          status: '완료',
          statusColor: AppColors.success,
          onTap: () {
            _showMessage(context, '혈액 검사 상세');
          },
        ),

        const SizedBox(height: 9),

        _RecordCard(
          icon: Icons.monitor_heart_outlined,
          title: '심전도 검사',
          subtitle: '2026.08.31 · 12 Lead ECG',
          status: '완료',
          statusColor: AppColors.success,
          onTap: () {
            _showMessage(context, '심전도 검사 상세');
          },
        ),
      ],
    );
  }
}

// ============================================================
// STEP 7. Imaging Tab
// ============================================================

class _ImagingTab extends StatelessWidget {
  final PatientUiModel patient;

  const _ImagingTab({required this.patient});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _RecordCard(
          icon: Icons.monitor_heart_outlined,
          title: 'CCTA',
          subtitle: '${patient.latestExamDate} · Coronary CT Angiography',
          status: '영상 있음',
          statusColor: AppColors.primaryBlue,
          actionText: '영상 보기',
          onTap: () {
            _showMessage(context, '영상 Viewer는 영상 메뉴에서 연결합니다.');
          },
        ),

        const SizedBox(height: 9),

        _RecordCard(
          icon: Icons.video_library_outlined,
          title: '관상동맥 조영술',
          subtitle: '2026.08.31 · CAG Series',
          status: '영상 있음',
          statusColor: AppColors.primaryBlue,
          actionText: '영상 보기',
          onTap: () {
            _showMessage(context, '관상동맥 조영술 Viewer 연결 예정');
          },
        ),
      ],
    );
  }
}

// ============================================================
// STEP 8. AI Tab
// ============================================================

class _AiTab extends StatelessWidget {
  final PatientUiModel patient;

  const _AiTab({required this.patient});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ======================================================
        // AI Summary
        // ======================================================
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '최근 AI 분석',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      patient.aiSummary,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              _StatusBadge(
                text: patient.aiPending ? '검토 대기' : '검토 완료',
                color: patient.aiPending
                    ? AppColors.warning
                    : AppColors.success,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        _RecordCard(
          icon: Icons.analytics_outlined,
          title: '관상동맥 협착 분석',
          subtitle: '2026.09.11 · 협착 위치 / 중증도 / Confidence',
          status: patient.aiPending ? '검토 대기' : '완료',
          statusColor: patient.aiPending
              ? AppColors.warning
              : AppColors.success,
          actionText: 'AI 결과',
          onTap: () {
            _showMessage(context, 'AI 상세 화면은 AI 메뉴에서 연결합니다.');
          },
        ),

        const SizedBox(height: 9),

        _RecordCard(
          icon: Icons.visibility_outlined,
          title: 'XAI 결과',
          subtitle: 'Grad-CAM 및 관심 영역 시각화',
          status: '생성 완료',
          statusColor: AppColors.primaryBlue,
          actionText: '결과 보기',
          onTap: () {
            _showMessage(context, 'XAI 상세 결과 연결 예정');
          },
        ),
      ],
    );
  }
}

// ============================================================
// STEP 9. Info Card
// ============================================================

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 126),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.navy),

              const SizedBox(width: 7),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
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
// STEP 10. Info Row
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 66,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 10.5,
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
// STEP 11. Important Text
// ============================================================

class _ImportantText extends StatelessWidget {
  final String text;

  const _ImportantText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

// ============================================================
// STEP 12. Timeline Item
// ============================================================

class _TimelineItem extends StatelessWidget {
  final String date;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool last;

  const _TimelineItem({
    required this.date,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                date,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),

          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),

              if (!last)
                Expanded(child: Container(width: 1, color: AppColors.border)),
            ],
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 13. Record Card
// ============================================================

class _RecordCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  final String status;
  final Color statusColor;

  final String actionText;

  final VoidCallback onTap;

  const _RecordCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.onTap,
    this.actionText = '상세보기',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: AppColors.navy),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          _StatusBadge(text: status, color: statusColor),

          const SizedBox(width: 10),

          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              actionText,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 14. Status Badge
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
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ============================================================
// STEP 15. Message
// ============================================================

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
}
