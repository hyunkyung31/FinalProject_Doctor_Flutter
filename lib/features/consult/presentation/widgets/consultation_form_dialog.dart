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
// STEP 3. Dialog
// ============================================================

class ConsultationFormDialog extends StatefulWidget {
  const ConsultationFormDialog({super.key});

  @override
  State<ConsultationFormDialog> createState() => _ConsultationFormDialogState();
}

class _ConsultationFormDialogState extends State<ConsultationFormDialog> {
  final TextEditingController _patientIdController = TextEditingController(
    text: '1629',
  );

  final TextEditingController _patientNameController = TextEditingController(
    text: '김OO',
  );

  final TextEditingController _subjectController = TextEditingController();

  final TextEditingController _noteController = TextEditingController();

  final TextEditingController _doctorIdController = TextEditingController(
    text: '3',
  );

  final TextEditingController _doctorNameController = TextEditingController(
    text: '박OO 의사',
  );

  final TextEditingController _encounterController = TextEditingController(
    text: '1213',
  );

  String _priority = 'NORMAL';

  DateTime _dueAt = DateTime(2026, 9, 20, 18);

  // ============================================================
  // STEP 4. Dispose
  // ============================================================

  @override
  void dispose() {
    _patientIdController.dispose();
    _patientNameController.dispose();
    _subjectController.dispose();
    _noteController.dispose();
    _doctorIdController.dispose();
    _doctorNameController.dispose();
    _encounterController.dispose();

    super.dispose();
  }

  // ============================================================
  // STEP 5. Save
  // ============================================================

  void _submit() {
    final patientId = int.tryParse(_patientIdController.text.trim());

    final doctorId = int.tryParse(_doctorIdController.text.trim());

    final encounterId = int.tryParse(_encounterController.text.trim());

    if (patientId == null ||
        doctorId == null ||
        encounterId == null ||
        _subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('필수 항목을 확인해 주세요.')));

      return;
    }

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
  // STEP 6. Due Date
  // ============================================================

  Future<void> _pickDueDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _dueAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (result == null) {
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
  // STEP 7. UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 520,
          maxWidth: 520,
          maxHeight: screenHeight * 0.88,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: context.appBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.appBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ==================================================
              // Header
              // ==================================================
              Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: context.appSurfaceSoft,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        Icons.groups_outlined,
                        size: 19,
                        color: context.appBrand,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '협진 요청',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: context.appTextPrimary,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            '환자와 담당 의료진을 선택하여 협진을 요청합니다.',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: context.appTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close_rounded, size: 19),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // Body
              // ==================================================
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _FormCard(
                        title: '환자 · 진료',
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _TextField(
                                    label: '환자 ID',
                                    controller: _patientIdController,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: _TextField(
                                    label: '환자',
                                    controller: _patientNameController,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            _TextField(
                              label: 'Encounter ID',
                              controller: _encounterController,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      _FormCard(
                        title: '협진 내용',
                        child: Column(
                          children: [
                            _TextField(
                              label: '제목 *',
                              controller: _subjectController,
                              hintText: '예: CCTA 결과 관련 협진 요청',
                            ),

                            const SizedBox(height: 10),

                            _TextField(
                              label: '요청 내용',
                              controller: _noteController,
                              hintText: '협진 요청 내용을 입력해 주세요.',
                              minLines: 3,
                              maxLines: 4,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      _FormCard(
                        title: '담당 의료진 · 일정',
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _TextField(
                                    label: '의료진 ID',
                                    controller: _doctorIdController,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: _TextField(
                                    label: '담당 의료진',
                                    controller: _doctorNameController,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _priority,
                                    decoration: InputDecoration(
                                      labelText: '우선순위',
                                      filled: true,
                                      fillColor: context.appSurface,
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'NORMAL',
                                        child: Text('일반'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'URGENT',
                                        child: Text('긴급'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value == null) {
                                        return;
                                      }

                                      setState(() {
                                        _priority = value;
                                      });
                                    },
                                  ),
                                ),

                                const SizedBox(width: 8),

                                Expanded(
                                  child: InkWell(
                                    onTap: _pickDueDate,
                                    borderRadius: BorderRadius.circular(8),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: '기한',
                                        filled: true,
                                        fillColor: context.appSurface,
                                        border: OutlineInputBorder(),
                                      ),
                                      child: Text(
                                        _formatDate(_dueAt),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: context.appTextPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ==================================================
              // Footer
              // ==================================================
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '* UI DEMO · 실제 API 연결 전',
                        style: TextStyle(
                          fontSize: 9,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ),

                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('취소'),
                    ),

                    const SizedBox(width: 8),

                    FilledButton.icon(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navy,
                      ),
                      icon: const Icon(Icons.send_outlined, size: 15),
                      label: const Text('협진 요청'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 8. Form Widgets
// ============================================================

class _FormCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _FormCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: context.appTextPrimary,
            ),
          ),

          const SizedBox(height: 10),

          child,
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  final String? hintText;

  final int minLines;
  final int maxLines;

  const _TextField({
    required this.label,
    required this.controller,
    this.hintText,
    this.minLines = 1,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 10.5),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: context.appSurface,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');

  final day = date.day.toString().padLeft(2, '0');

  return '${date.year}.$month.$day';
}
