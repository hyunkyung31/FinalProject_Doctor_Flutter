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

  @override
  void initState() {
    super.initState();

    _values = Map<String, dynamic>.from(widget.prefill.values);

    _prefilledKeys = widget.prefill.values.keys.toSet();
  }

  // ============================================================
  // STEP 2. 진행률
  // ============================================================

  int get _completedCount {
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

  bool get _isComplete => _completedCount == clinicalAiFields.length;

  // ============================================================
  // STEP 3. 숫자 입력 처리
  // ============================================================

  void _updateNumber(ClinicalFieldDefinition field, String text) {
    final trimmed = text.trim();

    setState(() {
      if (trimmed.isEmpty) {
        _values.remove(field.name);
        return;
      }

      final number = double.tryParse(trimmed);

      if (number == null) {
        _values.remove(field.name);
        return;
      }

      _values[field.name] = number;

      if (field.name == 'Weight' || field.name == 'Length') {
        _recalculateBmi();
      }
    });
  }

  void _recalculateBmi() {
    final weight = _asDouble(_values['Weight']);

    final height = _asDouble(_values['Length']);

    if (weight == null || height == null || weight <= 0 || height <= 0) {
      return;
    }

    final heightMeter = height / 100;

    final bmi = weight / (heightMeter * heightMeter);

    _values['BMI'] = double.parse(bmi.toStringAsFixed(2));
  }

  double? _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }

  // ============================================================
  // STEP 4. 입력값 표시
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
  // STEP 5. 입력 필드
  // ============================================================

  Widget _buildField(ClinicalFieldDefinition field) {
    switch (field.type) {
      case ClinicalFieldType.number:
        return _buildNumberField(field);

      case ClinicalFieldType.binary:
      case ClinicalFieldType.select:
        return _buildChoiceField(field);
    }
  }

  Widget _buildNumberField(ClinicalFieldDefinition field) {
    final isPrefilled = _prefilledKeys.contains(field.name);

    return TextFormField(
      key: ValueKey('${field.name}-${_values[field.name]}'),
      initialValue: _displayValue(_values[field.name]),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: field.label,
        border: const OutlineInputBorder(),
        suffixIcon: isPrefilled
            ? const Tooltip(
                message: '저장된 데이터에서 자동 입력됨',
                child: Icon(Icons.auto_awesome, size: 16),
              )
            : null,
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
    );
  }

  Widget _buildChoiceField(ClinicalFieldDefinition field) {
    final currentValue = _values[field.name];

    final isPrefilled = _prefilledKeys.contains(field.name);

    final hasValue = currentValue != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: hasValue
              ? Theme.of(context).colorScheme.outlineVariant
              : Theme.of(context).colorScheme.error.withValues(alpha: 0.55),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  field.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (isPrefilled)
                Tooltip(
                  message: '저장된 데이터에서 자동 입력됨',
                  child: Icon(
                    Icons.auto_awesome,
                    size: 15,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),

          // ------------------------------------------------------
          // 버튼형 선택
          // ------------------------------------------------------
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: field.options.map((option) {
              final selected = currentValue == option.value;

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
                    _values[field.name] = option.value;
                  });
                },
              );
            }).toList(),
          ),

          if (!hasValue) ...[
            const SizedBox(height: 7),
            Text(
              '선택이 필요합니다.',
              style: TextStyle(
                fontSize: 9,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
  // ============================================================
  // STEP 6. 그룹 UI
  // ============================================================

  Widget _buildGroup(String groupName) {
    final fields = clinicalAiFields
        .where((field) => field.group == groupName)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
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
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 620;

              final itemWidth = isWide
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: fields.map((field) {
                  return SizedBox(width: itemWidth, child: _buildField(field));
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 7. Submit
  // ============================================================

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;

    if (!valid || !_isComplete) {
      return;
    }

    final payload = <String, dynamic>{};

    for (final field in clinicalAiFields) {
      payload[field.name] = _values[field.name];
    }

    Navigator.of(context).pop(payload);
  }

  // ============================================================
  // STEP 8. Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    const groups = ['기본 정보', '병력 및 위험인자', '진찰 및 증상', '심전도 및 심초음파', '혈액검사'];

    final remaining = clinicalAiFields.length - _completedCount;

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
          Text(
            '$_completedCount / '
            '${clinicalAiFields.length}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _isComplete
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 820,
        height: 640,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
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
                  Text(
                    remaining == 0 ? '입력 완료' : '$remaining개 입력 필요',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: remaining == 0
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _completedCount / clinicalAiFields.length,
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (var i = 0; i < groups.length; i++) ...[
                        _buildGroup(groups[i]),
                        if (i != groups.length - 1) const SizedBox(height: 14),
                      ],
                    ],
                  ),
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
        FilledButton.icon(
          onPressed: _isComplete ? _submit : null,
          icon: const Icon(Icons.psychology_outlined, size: 18),
          label: Text(_isComplete ? 'AI 분석 실행' : '$_completedCount / 54'),
        ),
      ],
    );
  }
}
