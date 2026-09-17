import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'patient_detail_tabs.dart';

// ============================================================
// STEP 1. Patient Header
// 환자 식별 / 기본 정보 / 담당 진료 정보
// ============================================================

class PatientHeader extends StatelessWidget {
  final PatientUiModel patient;

  const PatientHeader({super.key, required this.patient});

  // ==========================================================
  // 생년월일
  // ==========================================================

  String _formatBirthDate(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      return '생년월일 정보 없음';
    }

    return normalized.replaceAll('-', '.');
  }

  // ==========================================================
  // 연락처
  // ==========================================================

  String _formatPhone(String value) {
    var normalized = value.trim().replaceAll(' ', '').replaceAll('-', '');

    if (normalized.isEmpty) {
      return '연락처 정보 없음';
    }

    if (normalized.startsWith('+82')) {
      normalized = '0${normalized.substring(3)}';
    } else if (normalized.startsWith('82') && !normalized.startsWith('820')) {
      normalized = '0${normalized.substring(2)}';
    }

    if (normalized.length == 11 && normalized.startsWith('010')) {
      return '${normalized.substring(0, 3)}-'
          '${normalized.substring(3, 7)}-'
          '${normalized.substring(7, 11)}';
    }

    return value.trim();
  }

  // ==========================================================
  // 진료 정보
  // ==========================================================

  String? _department() {
    final value = patient.department.trim();

    if (value.isEmpty || value == '진료과 정보 없음') {
      return null;
    }

    return value;
  }

  String? _doctor() {
    final value = patient.doctorName.trim();

    if (value.isEmpty || value == '담당 의료진 정보 없음') {
      return null;
    }

    return value;
  }

  @override
  Widget build(BuildContext context) {
    final department = _department();
    final doctor = _doctor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      color: AppColors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                // ==================================================
                // Name / Age / Gender
                // ==================================================
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      patient.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${patient.age}세 · ${patient.gender}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // ==================================================
                // 환자 식별 정보
                // ==================================================
                Wrap(
                  spacing: 7,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _HeaderText(text: patient.id),
                    const _HeaderDot(),
                    _HeaderText(text: _formatBirthDate(patient.birthDate)),
                    const _HeaderDot(),
                    _HeaderText(text: _formatPhone(patient.phone)),
                  ],
                ),

                if (department != null || doctor != null) ...[
                  const SizedBox(height: 5),

                  // ==================================================
                  // 진료 정보
                  // ==================================================
                  Wrap(
                    spacing: 7,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (department != null)
                        _HeaderText(text: department, emphasized: true),

                      if (department != null && doctor != null)
                        const _HeaderDot(),

                      if (doctor != null)
                        _HeaderText(text: doctor, emphasized: true),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 2. Header Text
// ============================================================

class _HeaderText extends StatelessWidget {
  final String text;
  final bool emphasized;

  const _HeaderText({required this.text, this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
        color: emphasized ? AppColors.navy : AppColors.textSecondary,
      ),
    );
  }
}

// ============================================================
// STEP 3. Header Separator
// ============================================================

class _HeaderDot extends StatelessWidget {
  const _HeaderDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: const BoxDecoration(
        color: AppColors.border,
        shape: BoxShape.circle,
      ),
    );
  }
}
