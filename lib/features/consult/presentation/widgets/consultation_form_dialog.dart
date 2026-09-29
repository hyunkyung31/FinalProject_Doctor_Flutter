import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/theme/app_theme.dart';

// ============================================================
// STEP 1. 협진 요청 Result
// POST /api/consultations/ Request Body 기준
// ============================================================

class ConsultationFormResult {
  final int patientId;
  final String patientName;

  final String subject;
  final String note;

  final int assignedDoctorId;
  final String assignedDoctorName;

  final int encounterId;

  final String priority;
  final DateTime dueAt;

  const ConsultationFormResult({
    required this.patientId,
    required this.patientName,
    required this.subject,
    required this.note,
    required this.assignedDoctorId,
    required this.assignedDoctorName,
    required this.encounterId,
    required this.priority,
    required this.dueAt,
  });
}

// ============================================================
// STEP 2. Dialog Helper
// 기존 호출부 호환 유지
// ============================================================

Future<ConsultationFormResult?> showConsultationFormDialog({
  required BuildContext context,
}) {
  return showDialog<ConsultationFormResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return const ConsultationFormDialog();
    },
  );
}

// ============================================================
// STEP 3. Consultation Form Dialog
// ============================================================

class ConsultationFormDialog extends StatefulWidget {
  const ConsultationFormDialog({super.key});

  @override
  State<ConsultationFormDialog> createState() => _ConsultationFormDialogState();
}

class _ConsultationFormDialogState extends State<ConsultationFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // ============================================================
  // 테스트 데이터
  // 추후 실제 환자 / 의료진 선택 UI 연결 가능
  // ============================================================

  final TextEditingController _patientIdController = TextEditingController(
    text: '1629',
  );

  final TextEditingController _patientNameController = TextEditingController(
    text: '김OO',
  );

  final TextEditingController _encounterController = TextEditingController(
    text: '1213',
  );

  final TextEditingController _subjectController = TextEditingController();

  final TextEditingController _noteController = TextEditingController();

  final TextEditingController _doctorIdController = TextEditingController(
    text: '3',
  );

  final TextEditingController _doctorNameController = TextEditingController(
    text: '박OO 의사',
  );

  String _priority = 'NORMAL';

  late DateTime _dueAt;

  // ============================================================
  // STEP 4. Init
  // ============================================================

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    // 고정된 과거 날짜를 사용하지 않고
    // 현재 날짜 기준 3일 뒤 18:00을 기본 기한으로 사용합니다.
    _dueAt = DateTime(
      now.year,
      now.month,
      now.day,
      18,
    ).add(const Duration(days: 3));
  }

  // ============================================================
  // STEP 5. Dispose
  // ============================================================

  @override
  void dispose() {
    _patientIdController.dispose();
    _patientNameController.dispose();
    _encounterController.dispose();
    _subjectController.dispose();
    _noteController.dispose();
    _doctorIdController.dispose();
    _doctorNameController.dispose();

    super.dispose();
  }

  // ============================================================
  // STEP 6. Submit
  // ============================================================

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;

    if (!valid) {
      return;
    }

    final patientId = int.parse(_patientIdController.text.trim());

    final encounterId = int.parse(_encounterController.text.trim());

    final doctorId = int.parse(_doctorIdController.text.trim());

    Navigator.of(context).pop(
      ConsultationFormResult(
        patientId: patientId,
        patientName: _patientNameController.text.trim(),
        subject: _subjectController.text.trim(),
        note: _noteController.text.trim(),
        assignedDoctorId: doctorId,
        assignedDoctorName: _doctorNameController.text.trim(),
        encounterId: encounterId,
        priority: _priority,
        dueAt: _dueAt,
      ),
    );
  }

  // ============================================================
  // STEP 7. Due Date
  // ============================================================

  Future<void> _pickDueDate() async {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final initialDate = _dueAt.isBefore(today)
        ? today
        : DateTime(_dueAt.year, _dueAt.month, _dueAt.day);

    final result = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(today.year + 1, today.month, today.day),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _dueAt = DateTime(
        result.year,
        result.month,
        result.day,
        _dueAt.hour,
        _dueAt.minute,
      );
    });
  }

  // ============================================================
  // STEP 8. UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenSize.width < 700 ? 16 : 30,
        vertical: 24,
      ),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 560,
          maxWidth: 640,
          maxHeight: screenSize.height * 0.88,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.appBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),

              Divider(height: 1, color: context.appBorder),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildPatientSection(),

                        const SizedBox(height: 12),

                        _buildConsultationSection(),

                        const SizedBox(height: 12),

                        _buildDoctorSection(),
                      ],
                    ),
                  ),
                ),
              ),

              Divider(height: 1, color: context.appBorder),

              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP 9. Header
  // ============================================================

  Widget _buildHeader() {
    return Container(
      color: context.appSurface,
      padding: const EdgeInsets.fromLTRB(20, 17, 14, 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.appSurfaceSoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              Icons.groups_outlined,
              size: 18,
              color: context.appBrand,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '협진 요청',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: context.appTextPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '대상 환자와 담당 의료진을 확인하고 협진 내용을 작성해 주세요.',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: context.appTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: '닫기',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(
              Icons.close_rounded,
              size: 19,
              color: context.appTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 10. Patient Section
  // ============================================================

  Widget _buildPatientSection() {
    return _DialogSection(
      icon: Icons.person_outline_rounded,
      title: '대상 환자',
      subtitle: '협진 대상 환자와 진료 건을 확인합니다.',
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _AppTextField(
                  label: '환자명',
                  controller: _patientNameController,
                  icon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '환자명을 입력해 주세요.';
                    }

                    return null;
                  },
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _AppTextField(
                  label: '환자 ID',
                  controller: _patientIdController,
                  icon: Icons.tag_rounded,
                  keyboardType: TextInputType.number,
                  validator: _positiveIdValidator('환자 ID'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          _AppTextField(
            label: 'Encounter ID',
            controller: _encounterController,
            icon: Icons.medical_information_outlined,
            keyboardType: TextInputType.number,
            helperText: '현재 진료 건을 기준으로 협진을 연결합니다.',
            validator: _positiveIdValidator('Encounter ID'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 11. Consultation Section
  // ============================================================

  Widget _buildConsultationSection() {
    return _DialogSection(
      icon: Icons.assignment_outlined,
      title: '협진 내용',
      subtitle: '협진 목적과 확인이 필요한 내용을 작성합니다.',
      child: Column(
        children: [
          _AppTextField(
            label: '제목 *',
            controller: _subjectController,
            icon: Icons.title_rounded,
            hintText: '예: CCTA 결과 판독 및 치료 방향 협진',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '협진 제목을 입력해 주세요.';
              }

              return null;
            },
          ),

          const SizedBox(height: 10),

          _AppTextField(
            label: '요청 내용 *',
            controller: _noteController,
            icon: Icons.notes_rounded,
            hintText: '협진 배경, 확인 요청 사항, 참고할 임상 정보를 입력해 주세요.',
            minLines: 4,
            maxLines: 6,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '협진 요청 내용을 입력해 주세요.';
              }

              return null;
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 12. Doctor / Schedule Section
  // ============================================================

  Widget _buildDoctorSection() {
    return _DialogSection(
      icon: Icons.medical_services_outlined,
      title: '담당 의료진 · 일정',
      subtitle: '협진 담당 의료진과 우선순위, 완료 기한을 지정합니다.',
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _AppTextField(
                  label: '담당 의료진',
                  controller: _doctorNameController,
                  icon: Icons.badge_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '담당 의료진을 입력해 주세요.';
                    }

                    return null;
                  },
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _AppTextField(
                  label: '의료진 ID',
                  controller: _doctorIdController,
                  icon: Icons.tag_rounded,
                  keyboardType: TextInputType.number,
                  validator: _positiveIdValidator('의료진 ID'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '우선순위',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: context.appTextSecondary,
              ),
            ),
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              Expanded(
                child: _PriorityButton(
                  label: '일반',
                  icon: Icons.remove_rounded,
                  selected: _priority == 'NORMAL',
                  onTap: () {
                    setState(() {
                      _priority = 'NORMAL';
                    });
                  },
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _PriorityButton(
                  label: '긴급',
                  icon: Icons.priority_high_rounded,
                  selected: _priority == 'URGENT',
                  danger: true,
                  onTap: () {
                    setState(() {
                      _priority = 'URGENT';
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '완료 기한',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: context.appTextSecondary,
              ),
            ),
          ),

          const SizedBox(height: 7),

          InkWell(
            onTap: _pickDueDate,
            borderRadius: BorderRadius.circular(9),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              decoration: BoxDecoration(
                color: context.appBackground,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: context.appBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 31,
                    height: 31,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.appSurfaceSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: context.appBrand,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(_dueAt),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: context.appTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '기본 완료 시각 18:00',
                          style: TextStyle(
                            fontSize: 8.5,
                            color: context.appTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: context.appTextDisabled,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 13. Footer
  // ============================================================

  Widget _buildFooter() {
    return Container(
      color: context.appSurface,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: context.appTextDisabled,
          ),

          const SizedBox(width: 6),

          Expanded(
            child: Text(
              '* 표시 항목은 필수 입력입니다.',
              style: TextStyle(fontSize: 8.5, color: context.appTextSecondary),
            ),
          ),

          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: OutlinedButton.styleFrom(minimumSize: const Size(72, 40)),
            child: const Text('취소'),
          ),

          const SizedBox(width: 8),

          FilledButton.icon(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              minimumSize: const Size(112, 40),
            ),
            icon: const Icon(Icons.send_rounded, size: 15),
            label: const Text('협진 요청'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 14. Validators
  // ============================================================

  String? Function(String?) _positiveIdValidator(String label) {
    return (value) {
      final parsed = int.tryParse(value?.trim() ?? '');

      if (parsed == null || parsed <= 0) {
        return '$label를 확인해 주세요.';
      }

      return null;
    };
  }
}

// ============================================================
// STEP 15. Dialog Section
// ============================================================

class _DialogSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _DialogSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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

          const SizedBox(height: 13),

          child,
        ],
      ),
    );
  }
}

// ============================================================
// STEP 16. Text Field
// ============================================================

class _AppTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;

  final String? hintText;
  final String? helperText;

  final int minLines;
  final int maxLines;

  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _AppTextField({
    required this.label,
    required this.controller,
    required this.icon,
    this.hintText,
    this.helperText,
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(fontSize: 10.5, color: context.appTextPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        helperText: helperText,
        helperMaxLines: 2,
        prefixIcon: Icon(icon, size: 15),
        filled: true,
        fillColor: context.appBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: context.appBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: context.appBrand),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 17. Priority Button
// ============================================================

class _PriorityButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool danger;
  final VoidCallback onTap;

  const _PriorityButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = danger ? AppColors.danger : context.appBrand;

    final selectedBackground = danger
        ? AppColors.dangerBackground
        : context.appSurfaceSoft;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? selectedBackground : context.appBackground,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? selectedColor : context.appBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? selectedColor : context.appTextSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: selected ? selectedColor : context.appTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STEP 18. Date Helper
// ============================================================

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');

  final day = date.day.toString().padLeft(2, '0');

  return '${date.year}.$month.$day';
}
