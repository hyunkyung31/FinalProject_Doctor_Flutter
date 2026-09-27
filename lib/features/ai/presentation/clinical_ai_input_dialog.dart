import 'package:flutter/material.dart';

import '../data/services/ai_analysis_service.dart';
import 'clinical_ai_fields.dart';

// ============================================================
// STEP 1. Clinical AI 입력 Dialog
// ============================================================

class ClinicalAiInputDialog extends StatefulWidget {
  final int examinationId;
  final ClinicalInputPrefillRecord prefill;

  const ClinicalAiInputDialog({
    super.key,
    required this.examinationId,
    required this.prefill,
  });

  @override
  State<ClinicalAiInputDialog> createState() => _ClinicalAiInputDialogState();
}

class _ClinicalAiInputDialogState extends State<ClinicalAiInputDialog> {
  final _formKey = GlobalKey<FormState>();

  late final Map<String, dynamic> _values;
  late final Set<String> _prefilledKeys;

  final Map<String, TextEditingController> _numberControllers = {};

  late final TextEditingController _diastolicBpController;

  late final ValueNotifier<int> _completedCountNotifier;

  // ============================================================
  // STEP 2. 초기화
  // ============================================================

  @override
  void initState() {
    super.initState();

    _values = Map<String, dynamic>.from(widget.prefill.values);

    _prefilledKeys = widget.prefill.values.keys.toSet();

    for (final field in clinicalAiFields) {
      if (field.type != ClinicalFieldType.number) {
        continue;
      }

      _numberControllers[field.name] = TextEditingController(
        text: _displayValue(_values[field.name]),
      );
    }

    // 현재 AI 모델에는 DBP 필드가 없으므로
    // 이완기 혈압은 화면 입력용으로만 관리한다.
    _diastolicBpController = TextEditingController();

    _completedCountNotifier = ValueNotifier<int>(_calculateCompletedCount());
  }

  @override
  void dispose() {
    for (final controller in _numberControllers.values) {
      controller.dispose();
    }

    _diastolicBpController.dispose();
    _completedCountNotifier.dispose();

    super.dispose();
  }

  // ============================================================
  // STEP 3. 입력 완료 개수
  // ============================================================

  int _calculateCompletedCount() {
    var count = 0;

    for (final field in clinicalAiFields) {
      final value = _values[field.name];

      if (value == null) {
        continue;
      }

      if (value is String && value.trim().isEmpty) {
        continue;
      }

      count += 1;
    }

    return count;
  }

  void _syncCompletedCount() {
    final count = _calculateCompletedCount();

    if (_completedCountNotifier.value != count) {
      _completedCountNotifier.value = count;
    }
  }

  // ============================================================
  // STEP 4. 숫자 입력 처리
  // ============================================================

  void _updateNumber(ClinicalFieldDefinition field, String text) {
    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      _values.remove(field.name);

      if (field.name == 'Weight' || field.name == 'Length') {
        _recalculateBmi();
      }

      _syncCompletedCount();
      return;
    }

    final number = double.tryParse(trimmed);

    if (number == null) {
      _values.remove(field.name);
      _syncCompletedCount();
      return;
    }

    _values[field.name] = number;

    if (field.name == 'Weight' || field.name == 'Length') {
      _recalculateBmi();
    }

    _syncCompletedCount();
  }

  // ============================================================
  // STEP 5. BMI 자동 계산
  // ============================================================

  void _recalculateBmi() {
    final weight = _asDouble(_values['Weight']);

    final height = _asDouble(_values['Length']);

    final bmiController = _numberControllers['BMI'];

    if (weight == null || height == null || weight <= 0 || height <= 0) {
      _values.remove('BMI');

      if (bmiController != null && bmiController.text.isNotEmpty) {
        bmiController.clear();
      }

      _syncCompletedCount();
      return;
    }

    final heightMeter = height / 100;

    final bmi = weight / (heightMeter * heightMeter);

    final roundedBmi = double.parse(bmi.toStringAsFixed(2));

    _values['BMI'] = roundedBmi;

    final displayValue = _displayValue(roundedBmi);

    if (bmiController != null && bmiController.text != displayValue) {
      bmiController.value = TextEditingValue(
        text: displayValue,
        selection: TextSelection.collapsed(offset: displayValue.length),
      );
    }

    _syncCompletedCount();
  }

  double? _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }

  // ============================================================
  // STEP 6. 값 표시
  // ============================================================

  String _displayValue(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is double) {
      if (value == value.roundToDouble()) {
        return value.toInt().toString();
      }

      return value.toString();
    }

    return value.toString();
  }

  // ============================================================
  // STEP 7. 단위
  // ============================================================

  String? _unitForField(ClinicalFieldDefinition field) {
    switch (field.name) {
      case 'Weight':
        return 'kg';

      case 'Length':
        return 'cm';

      case 'PR':
        return 'bpm';

      case 'EF-TTE':
        return '%';

      default:
        return null;
    }
  }

  // ============================================================
  // STEP 8. 자동 입력 Badge
  // ============================================================

  Widget _buildAutoBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 11,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            '자동 입력',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 9. 일반 숫자 입력
  // ============================================================

  Widget _buildNumberInput(ClinicalFieldDefinition field) {
    final controller = _numberControllers[field.name]!;

    return SizedBox(
      width: 280,
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: false,
        ),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          hintText: '입력',
          isDense: true,
          border: const OutlineInputBorder(),
          suffixText: _unitForField(field),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 13,
          ),
        ),
        validator: (value) {
          final text = value?.trim() ?? '';

          if (text.isEmpty) {
            return '입력이 필요합니다.';
          }

          if (double.tryParse(text) == null) {
            return '숫자를 입력해 주세요.';
          }

          return null;
        },
        onChanged: (value) {
          _updateNumber(field, value);
        },
      ),
    );
  }

  // ============================================================
  // STEP 10. 혈압 입력
  //
  // 화면:
  // 수축기 / 이완기
  //
  // AI:
  // BP = 수축기 혈압만 전달
  // ============================================================

  Widget _buildBloodPressureInput(ClinicalFieldDefinition field) {
    final systolicController = _numberControllers['BP']!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: 165,
              child: TextFormField(
                controller: systolicController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                  signed: false,
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                  labelText: '수축기',
                  hintText: '120',
                  suffixText: 'mmHg',
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 13,
                  ),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return '입력이 필요합니다.';
                  }

                  if (double.tryParse(text) == null) {
                    return '숫자를 입력해 주세요.';
                  }

                  return null;
                },
                onChanged: (value) {
                  _updateNumber(field, value);
                },
              ),
            ),

            Text(
              '/',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

            SizedBox(
              width: 165,
              child: TextFormField(
                controller: _diastolicBpController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                  signed: false,
                ),
                decoration: const InputDecoration(
                  labelText: '이완기',
                  hintText: '80',
                  suffixText: 'mmHg',
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Clinical AI 모델에는 수축기 혈압(BP)이 사용됩니다.',
          style: TextStyle(
            fontSize: 9.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 11. 선택 입력
  // ============================================================

  Widget _buildChoiceInput(ClinicalFieldDefinition field) {
    return _ClinicalChoiceInput(
      initialValue: _values[field.name],
      options: field.options,
      onChanged: (value) {
        if (value == null) {
          _values.remove(field.name);
        } else {
          _values[field.name] = value;
        }

        _syncCompletedCount();
      },
    );
  }

  // ============================================================
  // STEP 12. 설문지 한 줄
  // ============================================================

  Widget _buildQuestionRow(ClinicalFieldDefinition field) {
    final isPrefilled = _prefilledKeys.contains(field.name);

    Widget input;

    if (field.name == 'BP') {
      input = _buildBloodPressureInput(field);
    } else if (field.type == ClinicalFieldType.number) {
      input = _buildNumberInput(field);
    } else {
      input = _buildChoiceInput(field);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 650;

        final label = Row(
          children: [
            Expanded(
              child: Text(
                field.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isPrefilled) ...[const SizedBox(width: 8), _buildAutoBadge()],
          ],
        );

        if (!isWide) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [label, const SizedBox(height: 10), input],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 250,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: label,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Align(alignment: Alignment.centerLeft, child: input),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // STEP 13. Section
  // ============================================================

  Widget _buildSection(String groupName) {
    final fields = clinicalAiFields
        .where((field) => field.group == groupName)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            groupName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),

          for (var i = 0; i < fields.length; i++) ...[
            _buildQuestionRow(fields[i]),
            if (i != fields.length - 1)
              Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // STEP 14. Submit
  // ============================================================

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;

    final completedCount = _calculateCompletedCount();

    if (!valid || completedCount != clinicalAiFields.length) {
      return;
    }

    final payload = <String, dynamic>{};

    for (final field in clinicalAiFields) {
      payload[field.name] = _values[field.name];
    }

    // 중요:
    // 이완기 혈압은 현재 Clinical AI 54개 입력 변수에 없으므로
    // payload에 추가하지 않는다.
    //
    // 따라서 payload는 정확히 54개를 유지한다.

    Navigator.of(context).pop(payload);
  }

  // ============================================================
  // STEP 15. Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    const groups = ['기본 정보', '병력 및 위험인자', '진찰 및 증상', '심전도 및 심초음파', '혈액검사'];

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      title: Row(
        children: [
          const Expanded(
            child: Text(
              'Clinical AI 분석 입력',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          ValueListenableBuilder<int>(
            valueListenable: _completedCountNotifier,
            builder: (context, count, child) {
              return Text(
                '$count / ${clinicalAiFields.length}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: count == clinicalAiFields.length
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
        ],
      ),
      content: SizedBox(
        width: 850,
        height: 650,
        child: Column(
          children: [
            // ----------------------------------------------------
            // 환자 / 검사 정보
            // ----------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.prefill.patient.name}'
                      ' · Patient #'
                      '${widget.prefill.patient.patientId}'
                      ' · Examination #'
                      '${widget.examinationId}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: _completedCountNotifier,
                    builder: (context, count, child) {
                      final remaining = clinicalAiFields.length - count;

                      return Text(
                        remaining == 0 ? '입력 완료' : '$remaining개 입력 필요',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: remaining == 0
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ----------------------------------------------------
            // 진행률
            // ----------------------------------------------------
            ValueListenableBuilder<int>(
              valueListenable: _completedCountNotifier,
              builder: (context, count, child) {
                return LinearProgressIndicator(
                  value: count / clinicalAiFields.length,
                );
              },
            ),

            const SizedBox(height: 14),

            // ----------------------------------------------------
            // Clinical 설문
            // ----------------------------------------------------
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: groups.length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 14);
                  },
                  itemBuilder: (context, index) {
                    return _buildSection(groups[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('취소'),
        ),
        ValueListenableBuilder<int>(
          valueListenable: _completedCountNotifier,
          builder: (context, count, child) {
            final complete = count == clinicalAiFields.length;

            return FilledButton.icon(
              onPressed: complete ? _submit : null,
              icon: const Icon(Icons.psychology_outlined, size: 18),
              label: Text(
                complete ? 'AI 분석 실행' : '$count / ${clinicalAiFields.length}',
              ),
            );
          },
        ),
      ],
    );
  }
}

// ============================================================
// STEP 16. Choice 입력
//
// 하나를 선택할 때 해당 위젯만 rebuild
// ============================================================

class _ClinicalChoiceInput extends StatefulWidget {
  final dynamic initialValue;
  final List<ClinicalFieldOption> options;
  final ValueChanged<dynamic> onChanged;

  const _ClinicalChoiceInput({
    required this.initialValue,
    required this.options,
    required this.onChanged,
  });

  @override
  State<_ClinicalChoiceInput> createState() => _ClinicalChoiceInputState();
}

class _ClinicalChoiceInputState extends State<_ClinicalChoiceInput> {
  dynamic _selectedValue;

  @override
  void initState() {
    super.initState();

    _selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = _selectedValue != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.options.map((option) {
            final selected = _selectedValue == option.value;

            return ChoiceChip(
              label: Text(
                option.label,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: selected,
              showCheckmark: true,
              onSelected: (_) {
                setState(() {
                  _selectedValue = option.value;
                });

                widget.onChanged(option.value);
              },
            );
          }).toList(),
        ),
        if (!hasValue) ...[
          const SizedBox(height: 6),
          Text(
            '선택이 필요합니다.',
            style: TextStyle(
              fontSize: 9,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
