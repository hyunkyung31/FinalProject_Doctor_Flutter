import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';
import 'package:go_router/go_router.dart';

import '../../../patients/presentation/widgets/patient_detail_tabs.dart';
import 'dashboard_section_card.dart';

// ============================================================
// Recent Patients Card
// ============================================================

class RecentPatientsCard extends StatelessWidget {
  final List<PatientUiModel> patients;
  final int totalCount;
  final bool loadFailed;

  const RecentPatientsCard({
    super.key,
    required this.patients,
    required this.totalCount,
    required this.loadFailed,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardSectionCard(
      title: '최근 본 환자',
      actionLabel: '전체보기',
      onAction: () {
        context.go('/patients');
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (loadFailed) {
      return SizedBox(
        height: 184,
        child: Center(
          child: Text(
            '최근 본 환자를 불러오지 못했습니다.',
            style: TextStyle(fontSize: 9.5, color: context.appTextSecondary),
          ),
        ),
      );
    }

    if (patients.isEmpty) {
      return SizedBox(
        height: 184,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_search_outlined,
                size: 24,
                color: context.appTextSecondary,
              ),
              const SizedBox(height: 7),
              Text(
                '최근 조회한 환자가 없습니다.',
                style: TextStyle(
                  fontSize: 9.5,
                  color: context.appTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // ========================================================
        // Summary Row
        // ========================================================
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: context.appBorder)),
          ),
          child: Row(
            children: [
              Text(
                '최근 조회 순',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: context.appTextSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '총 $totalCount명',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: context.appTextSecondary,
                ),
              ),
            ],
          ),
        ),

        // ========================================================
        // Patient Rows
        // ========================================================
        for (final patient in patients.take(4))
          _RecentPatientRow(
            patient: patient,
            onTap: () {
              context.go('/patients');
            },
          ),
      ],
    );
  }
}

class _RecentPatientRow extends StatelessWidget {
  final PatientUiModel patient;
  final VoidCallback onTap;

  const _RecentPatientRow({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final medicalRecordNo = patient.medicalRecordNo.trim().isEmpty
        ? '-'
        : patient.medicalRecordNo;

    final ageText = patient.age > 0 ? '${patient.age}세' : '나이 미상';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: context.appBorder)),
          ),
          child: Row(
            children: [
              // 작은 상태 포인트만 유지
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: context.appBrand,
                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.8,
                        fontWeight: FontWeight.w700,
                        color: context.appTextPrimary,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      '$medicalRecordNo · '
                      '${patient.gender} · $ageText',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons.chevron_right_rounded,
                size: 15,
                color: context.appTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
