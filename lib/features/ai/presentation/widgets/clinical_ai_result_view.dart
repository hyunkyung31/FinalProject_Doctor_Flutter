import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../ai_ui_models.dart';

// ============================================================
// STEP 1. Clinical AI Result View
// ============================================================

class ClinicalAiResultView extends StatelessWidget {
  final AiResultUiModel result;

  const ClinicalAiResultView({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final resultJson = result.resultJson;

    final prediction = _toInt(resultJson['prediction']);
    final probability = _toDouble(resultJson['probability']);
    final threshold = _toDouble(resultJson['threshold']);

    final warnings = _stringList(resultJson['warnings']);

    final explanation = resultJson['explanation'] is Map
        ? Map<String, dynamic>.from(resultJson['explanation'] as Map)
        : <String, dynamic>{};

    final explanationType = explanation['type']?.toString() ?? '-';
    final explanationMethod = explanation['method']?.toString() ?? '-';

    final topFeatures = _mapList(explanation['top_features']);

    final inputSnapshot = result.inputSnapshot;

    final unitMismatchFields = _labFields.where((field) {
      return _isUnitMismatch(field, result.labReferences[field.name]);
    }).toList();

    final missingFields = _clinicalFields
        .where(
          (field) =>
              !inputSnapshot.containsKey(field.name) ||
              inputSnapshot[field.name] == null ||
              inputSnapshot[field.name].toString().trim().isEmpty,
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ========================================================
        // STEP 2. CAD Risk Summary
        // ========================================================
        _ResultSection(
          title: 'Clinical AI CAD 위험도',
          icon: Icons.monitor_heart_outlined,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'AI 예측',
                      value: prediction == 1 ? '위험 신호 있음' : '위험 신호 낮음',
                      subLabel: 'Prediction $prediction',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      label: '예측 확률',
                      value: probability == null
                          ? '-'
                          : '${(probability * 100).toStringAsFixed(1)}%',
                      subLabel: 'CAD risk probability',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      label: '판단 기준',
                      value: threshold == null
                          ? '-'
                          : '${(threshold * 100).toStringAsFixed(1)}%',
                      subLabel: 'Model threshold',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _InfoRow(label: '결과 상태', value: _statusLabel(result.status)),
              _InfoRow(
                label: '결과 유형',
                value: result.resultType.isEmpty ? '-' : result.resultType,
              ),
              _InfoRow(label: '모델', value: result.modelLabel),
              _InfoRow(label: 'Examination', value: '#${result.examinationId}'),
              _InfoRow(label: 'Analysis', value: '#${result.analysisId}'),
              _InfoRow(
                label: 'Confidence',
                value: result.confidence == null
                    ? '-'
                    : '${(result.confidence! * 100).toStringAsFixed(1)}%',
              ),
            ],
          ),
        ),

        // ========================================================
        // STEP 3. Warning
        // ========================================================
        if (warnings.isNotEmpty) ...[
          const SizedBox(height: 12),

          _ResultSection(
            title: '입력 데이터 주의사항',
            icon: Icons.warning_amber_rounded,
            child: Column(
              children: [
                for (final warning in warnings)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 7),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warningBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _warningLabel(warning),
                            style: const TextStyle(
                              fontSize: 10,
                              height: 1.5,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],

        // ========================================================
        // STEP 4. SHAP
        // ========================================================
        const SizedBox(height: 12),

        _ResultSection(
          title: 'AI 판단 근거 · XAI',
          icon: Icons.psychology_alt_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SmallChip(label: explanationType),
                  const SizedBox(width: 6),
                  _SmallChip(label: explanationMethod),
                ],
              ),

              const SizedBox(height: 12),

              if (topFeatures.isEmpty)
                Text(
                  'XAI 설명 데이터가 없습니다.',
                  style: TextStyle(
                    fontSize: 10,
                    color: context.appTextSecondary,
                  ),
                )
              else
                Column(
                  children: [
                    for (var index = 0; index < topFeatures.length; index++)
                      _ShapFeatureRow(
                        rank: index + 1,
                        data: topFeatures[index],
                      ),
                  ],
                ),

              const SizedBox(height: 8),

              Text(
                'SHAP 값은 해당 변수가 모델 예측을 어느 방향으로 얼마나 변화시켰는지를 나타냅니다. '
                '의학적 인과관계나 확진을 의미하지 않습니다.',
                style: TextStyle(
                  fontSize: 9,
                  height: 1.5,
                  color: context.appTextSecondary,
                ),
              ),
            ],
          ),
        ),

        // ========================================================
        // STEP 5. Clinical Input Validation
        // ========================================================
        const SizedBox(height: 12),

        _ResultSection(
          title: '입력 데이터 검증',
          icon: Icons.fact_check_outlined,
          child: Column(
            children: [
              _InfoRow(label: '입력 변수', value: '${inputSnapshot.length} / 54'),
              _InfoRow(
                label: '누락 변수',
                value: missingFields.isEmpty
                    ? '없음'
                    : '${missingFields.length}개',
              ),
              _InfoRow(
                label: '필수 입력 상태',
                value: missingFields.isEmpty ? '완료' : '확인 필요',
              ),
              _InfoRow(
                label: '단위 검증',
                value: unitMismatchFields.isEmpty
                    ? '완료'
                    : '${unitMismatchFields.length}개 확인 필요',
              ),

              if (missingFields.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final field in missingFields)
                        _SmallChip(label: field.label),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // ========================================================
        // STEP 6. Lab Results
        // ========================================================
        const SizedBox(height: 12),

        _ResultSection(
          title: '혈액검사 수치',
          icon: Icons.biotech_outlined,
          child: Column(
            children: [
              for (final field in _labFields)
                _ClinicalValueRow(
                  field: field,
                  value: inputSnapshot[field.name],
                  reference: result.labReferences[field.name],
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        _ResultSection(
          title: '이전 혈액검사 비교',
          icon: Icons.compare_arrows_rounded,
          child: result.previousLabSnapshot.isEmpty
              ? Text(
                  '비교 가능한 이전 혈액검사 결과가 없습니다.',
                  style: TextStyle(
                    fontSize: 10,
                    color: context.appTextSecondary,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _comparisonSourceLabel(result),
                      style: TextStyle(
                        fontSize: 9.5,
                        color: context.appTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final field in _labFields)
                      if (inputSnapshot[field.name] != null ||
                          result.previousLabSnapshot[field.name] != null)
                        _LabComparisonRow(
                          field: field,
                          currentValue: inputSnapshot[field.name],
                          previousValue: result.previousLabSnapshot[field.name],
                          reference: result.labReferences[field.name],
                        ),
                    const SizedBox(height: 8),
                    Text(
                      '증감 표시는 수치 변화만 의미하며 위험도 증가·감소를 뜻하지 않습니다.',
                      style: TextStyle(
                        fontSize: 8.5,
                        height: 1.4,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
        ),

        // ========================================================
        // STEP 7. Basic Clinical Inputs
        // ========================================================
        const SizedBox(height: 12),

        _ResultSection(
          title: '임상 입력값',
          icon: Icons.assignment_outlined,
          child: Column(
            children: [
              for (final field in _clinicalFields.where(
                (item) => !_labFieldNames.contains(item.name),
              ))
                _ClinicalValueRow(
                  field: field,
                  value: inputSnapshot[field.name],
                ),
            ],
          ),
        ),

        // ========================================================
        // STEP 8. Review notice
        // ========================================================
        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.appSurfaceSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.medical_information_outlined,
                size: 17,
                color: context.appBrand,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  '본 결과는 Clinical AI 모델의 예측 결과이며 의료진의 최종 진단을 대체하지 않습니다. '
                  'REVIEW_REQUIRED 상태의 결과는 임상 정보 및 영상 결과와 함께 검토해야 합니다.',
                  style: TextStyle(
                    fontSize: 9.5,
                    height: 1.55,
                    color: context.appTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STEP 9. SHAP Feature
// ============================================================

class _ShapFeatureRow extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> data;

  const _ShapFeatureRow({required this.rank, required this.data});

  @override
  Widget build(BuildContext context) {
    final feature = data['feature']?.toString() ?? '-';
    final value = data['value'];
    final shapValue = _toDouble(data['shap_value']) ?? 0;
    final direction = data['direction']?.toString().toLowerCase() ?? '';

    final isIncrease = shapValue > 0 || direction == 'increase';

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        border: Border.all(color: context.appBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: context.appTextSecondary,
              ),
            ),
          ),

          Expanded(
            flex: 3,
            child: Text(
              _featureLabel(feature),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: context.appTextPrimary,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              '값 $value',
              style: TextStyle(fontSize: 9.5, color: context.appTextSecondary),
            ),
          ),

          SizedBox(
            width: 90,
            child: Text(
              '${isIncrease ? '↑' : '↓'} '
              '${shapValue.abs().toStringAsFixed(4)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isIncrease ? AppColors.warning : AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 10. Clinical Value Row
// ============================================================

class _ClinicalValueRow extends StatelessWidget {
  final _ClinicalResultField field;
  final dynamic value;
  final ClinicalLabReferenceUiModel? reference;

  const _ClinicalValueRow({
    required this.field,
    required this.value,
    this.reference,
  });

  @override
  Widget build(BuildContext context) {
    final missing = value == null || value.toString().trim().isEmpty;
    final status = _clinicalStatus(value, reference);
    final statusColor = _clinicalStatusColor(context, status);
    final unit = _displayUnit(field, reference);
    final referenceLabel = _referenceRangeLabel(field, reference);
    final unitMismatch = _isUnitMismatch(field, reference);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.appBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: context.appTextPrimary,
                  ),
                ),
                if (referenceLabel != null)
                  Text(
                    referenceLabel,
                    style: TextStyle(
                      fontSize: 8.5,
                      color: context.appTextSecondary,
                    ),
                  ),
                if (unitMismatch)
                  Text(
                    '단위 확인 필요 · 응답 $unit / 기준 ${field.unit}',
                    style: const TextStyle(
                      fontSize: 8.2,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              missing
                  ? '-'
                  : '${_displayValue(field.name, value)}'
                        '${unit.isEmpty ? '' : ' $unit'}',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: context.appTextPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              status,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 10-1. Previous Lab Comparison Row
// ============================================================

class _LabComparisonRow extends StatelessWidget {
  final _ClinicalResultField field;
  final dynamic currentValue;
  final dynamic previousValue;
  final ClinicalLabReferenceUiModel? reference;

  const _LabComparisonRow({
    required this.field,
    required this.currentValue,
    required this.previousValue,
    required this.reference,
  });

  @override
  Widget build(BuildContext context) {
    final current = _toDouble(currentValue);
    final previous = _toDouble(previousValue);
    final unit = _displayUnit(field, reference);

    String changeText = '-';

    if (current != null && previous != null) {
      final delta = current - previous;

      if (delta.abs() < 0.000001) {
        changeText = '변화 없음';
      } else {
        final sign = delta > 0 ? '+' : '-';
        final arrow = delta > 0 ? '↑' : '↓';
        changeText =
            '$arrow $sign${_formatNumber(delta.abs())}'
            '${unit.isEmpty ? '' : ' $unit'}';
      }
    }

    String display(dynamic value) {
      if (value == null || value.toString().trim().isEmpty) {
        return '-';
      }

      return '${_displayValue(field.name, value)}'
          '${unit.isEmpty ? '' : ' $unit'}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.appBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              field.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: context.appTextPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              display(previousValue),
              style: TextStyle(fontSize: 9.5, color: context.appTextSecondary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              display(currentValue),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: context.appTextPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              changeText,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: changeText == '변화 없음'
                    ? context.appTextSecondary
                    : context.appBrand,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 11. Common Components
// ============================================================

class _ResultSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _ResultSection({
    required this.title,
    required this.icon,
    required this.child,
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
          child,
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String subLabel;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appSurfaceSoft,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 9, color: context.appTextSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: context.appTextPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subLabel,
            style: TextStyle(fontSize: 8, color: context.appTextSecondary),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 10, color: context.appTextSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: context.appTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;

  const _SmallChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.appSurfaceSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
          color: context.appTextSecondary,
        ),
      ),
    );
  }
}

// ============================================================
// STEP 12. Clinical Schema
//
// Backend clinical_input_schema.csv 기준.
// 범위는 정상 참고치가 아니라 모델 개발 데이터 범위.
// ============================================================

class _ClinicalResultField {
  final String name;
  final String label;
  final String unit;
  final double? min;
  final double? max;

  const _ClinicalResultField({
    required this.name,
    required this.label,
    this.unit = '',
    this.min,
    this.max,
  });
}

const _labFields = <_ClinicalResultField>[
  _ClinicalResultField(
    name: 'FBS',
    label: '공복혈당',
    unit: 'mg/dL',
    min: 62,
    max: 400,
  ),
  _ClinicalResultField(
    name: 'CR',
    label: 'Creatinine',
    unit: 'mg/dL',
    min: 0.5,
    max: 2.2,
  ),
  _ClinicalResultField(
    name: 'TG',
    label: 'Triglyceride',
    unit: 'mg/dL',
    min: 37,
    max: 1050,
  ),
  _ClinicalResultField(
    name: 'LDL',
    label: 'LDL',
    unit: 'mg/dL',
    min: 18,
    max: 232,
  ),
  _ClinicalResultField(
    name: 'HDL',
    label: 'HDL',
    unit: 'mg/dL',
    min: 15.9,
    max: 111,
  ),
  _ClinicalResultField(
    name: 'BUN',
    label: 'BUN',
    unit: 'mg/dL',
    min: 6,
    max: 52,
  ),
  _ClinicalResultField(
    name: 'ESR',
    label: 'ESR',
    unit: 'mm/hr',
    min: 1,
    max: 90,
  ),
  _ClinicalResultField(
    name: 'HB',
    label: 'Hemoglobin',
    unit: 'g/dL',
    min: 8.9,
    max: 17.6,
  ),
  _ClinicalResultField(
    name: 'K',
    label: 'Potassium',
    unit: 'mmol/L',
    min: 3,
    max: 6.6,
  ),
  _ClinicalResultField(
    name: 'Na',
    label: 'Sodium',
    unit: 'mmol/L',
    min: 128,
    max: 156,
  ),
  _ClinicalResultField(
    name: 'WBC',
    label: 'WBC',
    unit: '/µL',
    min: 3700,
    max: 18000,
  ),
  _ClinicalResultField(
    name: 'Lymph',
    label: 'Lymphocyte',
    unit: '%',
    min: 7,
    max: 60,
  ),
  _ClinicalResultField(
    name: 'Neut',
    label: 'Neutrophil',
    unit: '%',
    min: 32,
    max: 89,
  ),
  _ClinicalResultField(
    name: 'PLT',
    label: 'Platelet',
    unit: '10³/µL',
    min: 25,
    max: 742,
  ),
];

const _clinicalFields = <_ClinicalResultField>[
  _ClinicalResultField(name: 'Age', label: '나이', unit: '세', min: 30, max: 86),
  _ClinicalResultField(
    name: 'Weight',
    label: '체중',
    unit: 'kg',
    min: 48,
    max: 120,
  ),
  _ClinicalResultField(
    name: 'Length',
    label: '키',
    unit: 'cm',
    min: 140,
    max: 188,
  ),
  _ClinicalResultField(name: 'Sex', label: '성별'),
  _ClinicalResultField(
    name: 'BMI',
    label: 'BMI',
    unit: 'kg/m²',
    min: 18.1154,
    max: 40.9007,
  ),
  _ClinicalResultField(name: 'DM', label: '당뇨'),
  _ClinicalResultField(name: 'HTN', label: '고혈압'),
  _ClinicalResultField(name: 'Current Smoker', label: '현재 흡연'),
  _ClinicalResultField(name: 'EX-Smoker', label: '과거 흡연'),
  _ClinicalResultField(name: 'FH', label: '가족력'),
  _ClinicalResultField(name: 'Obesity', label: '비만'),
  _ClinicalResultField(name: 'CRF', label: '만성신부전'),
  _ClinicalResultField(name: 'CVA', label: '뇌혈관질환'),
  _ClinicalResultField(name: 'Airway disease', label: '기도질환'),
  _ClinicalResultField(name: 'Thyroid Disease', label: '갑상선질환'),
  _ClinicalResultField(name: 'CHF', label: '심부전'),
  _ClinicalResultField(name: 'DLP', label: '이상지질혈증'),

  _ClinicalResultField(
    name: 'BP',
    label: '수축기 혈압',
    unit: 'mmHg',
    min: 90,
    max: 190,
  ),
  _ClinicalResultField(name: 'PR', label: '맥박', unit: 'bpm', min: 50, max: 110),

  _ClinicalResultField(name: 'Edema', label: '부종'),
  _ClinicalResultField(name: 'Weak Peripheral Pulse', label: '약한 말초맥박'),
  _ClinicalResultField(name: 'Lung rales', label: '수포음'),
  _ClinicalResultField(name: 'Systolic Murmur', label: '수축기 잡음'),
  _ClinicalResultField(name: 'Diastolic Murmur', label: '이완기 잡음'),
  _ClinicalResultField(name: 'Typical Chest Pain', label: '전형적 흉통'),
  _ClinicalResultField(name: 'Dyspnea', label: '호흡곤란'),

  _ClinicalResultField(
    name: 'Function Class',
    label: 'Function Class',
    min: 0,
    max: 3,
  ),

  _ClinicalResultField(name: 'Atypical', label: '비전형적 흉통'),
  _ClinicalResultField(name: 'Nonanginal', label: '비협심증성 흉통'),
  _ClinicalResultField(name: 'LowTH Ang', label: 'Low Threshold Angina'),
  _ClinicalResultField(name: 'Q Wave', label: 'Q Wave'),
  _ClinicalResultField(name: 'St Elevation', label: 'ST Elevation'),
  _ClinicalResultField(name: 'St Depression', label: 'ST Depression'),
  _ClinicalResultField(name: 'Tinversion', label: 'T inversion'),
  _ClinicalResultField(name: 'LVH', label: 'LVH'),
  _ClinicalResultField(name: 'Poor R Progression', label: 'Poor R Progression'),
  _ClinicalResultField(name: 'BBB', label: 'BBB'),

  ..._labFields,

  _ClinicalResultField(
    name: 'EF-TTE',
    label: 'EF-TTE',
    unit: '%',
    min: 15,
    max: 60,
  ),
  _ClinicalResultField(
    name: 'Region RWMA',
    label: 'Region RWMA',
    min: 0,
    max: 4,
  ),
  _ClinicalResultField(name: 'VHD', label: 'VHD'),
];

const _labFieldNames = <String>{
  'FBS',
  'CR',
  'TG',
  'LDL',
  'HDL',
  'BUN',
  'ESR',
  'HB',
  'K',
  'Na',
  'WBC',
  'Lymph',
  'Neut',
  'PLT',
};

// ============================================================
// STEP 13. Helpers
// ============================================================

String _clinicalStatus(dynamic value, ClinicalLabReferenceUiModel? reference) {
  if (value == null || value.toString().trim().isEmpty) {
    return '누락';
  }

  if (reference == null) {
    return '확인';
  }

  final number = _toDouble(value);

  if (number != null) {
    if (reference.referenceMin != null && number < reference.referenceMin!) {
      return '낮음';
    }

    if (reference.referenceMax != null && number > reference.referenceMax!) {
      return '높음';
    }

    if (reference.referenceMin != null || reference.referenceMax != null) {
      return '정상';
    }
  }

  switch (reference.abnormalFlag?.trim().toUpperCase()) {
    case 'LOW':
    case 'L':
      return '낮음';
    case 'HIGH':
    case 'H':
      return '높음';
    case 'NORMAL':
    case 'N':
      return '정상';
    default:
      return '확인';
  }
}

Color _clinicalStatusColor(BuildContext context, String status) {
  switch (status) {
    case '정상':
      return AppColors.success;
    case '낮음':
      return AppColors.primaryBlue;
    case '높음':
      return AppColors.danger;
    case '누락':
      return AppColors.warning;
    default:
      return context.appTextSecondary;
  }
}

String _displayUnit(
  _ClinicalResultField field,
  ClinicalLabReferenceUiModel? reference,
) {
  final backendUnit = reference?.unit?.trim() ?? '';

  if (backendUnit.isNotEmpty) {
    return backendUnit;
  }

  return field.unit;
}

String? _referenceRangeLabel(
  _ClinicalResultField field,
  ClinicalLabReferenceUiModel? reference,
) {
  if (reference == null) {
    return null;
  }

  final unit = _displayUnit(field, reference);
  final min = reference.referenceMin;
  final max = reference.referenceMax;

  if (min != null && max != null) {
    return '참고 범위 ${_formatNumber(min)}–${_formatNumber(max)}'
        '${unit.isEmpty ? '' : ' $unit'}';
  }

  if (min != null) {
    return '참고 범위 ≥ ${_formatNumber(min)}'
        '${unit.isEmpty ? '' : ' $unit'}';
  }

  if (max != null) {
    return '참고 범위 ≤ ${_formatNumber(max)}'
        '${unit.isEmpty ? '' : ' $unit'}';
  }

  final text = reference.referenceText?.trim() ?? '';

  if (text.isNotEmpty) {
    return '참고 범위 $text${unit.isEmpty ? '' : ' $unit'}';
  }

  return null;
}

bool _isUnitMismatch(
  _ClinicalResultField field,
  ClinicalLabReferenceUiModel? reference,
) {
  final expected = field.unit.trim();
  final actual = reference?.unit?.trim() ?? '';

  if (expected.isEmpty || actual.isEmpty) {
    return false;
  }

  return _normalizeUnit(expected) != _normalizeUnit(actual);
}

String _normalizeUnit(String unit) {
  return unit
      .trim()
      .toLowerCase()
      .replaceAll('µ', 'u')
      .replaceAll('μ', 'u')
      .replaceAll('³', '^3')
      .replaceAll(' ', '');
}

String _comparisonSourceLabel(AiResultUiModel result) {
  final previousId = result.previousLabExaminationId;
  final currentId = result.currentLabExaminationId;

  final previousDate = _formatDate(result.previousLabExaminedAt);
  final currentDate = _formatDate(result.currentLabExaminedAt);

  final previousText = previousId == null
      ? '이전 LAB'
      : '이전 LAB #$previousId${previousDate == null ? '' : ' · $previousDate'}';

  final currentText = currentId == null
      ? '현재 AI 입력값'
      : '현재 LAB #$currentId${currentDate == null ? '' : ' · $currentDate'}';

  return '$previousText → $currentText 기준 비교';
}

String? _formatDate(DateTime? value) {
  if (value == null) {
    return null;
  }

  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');

  return '${value.year}.$month.$day';
}

List<String> _stringList(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value.map((item) => item.toString()).toList();
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

double? _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '');
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(2);
}

String _displayValue(String name, dynamic value) {
  if (value == null) {
    return '-';
  }

  const binaryNames = <String>{
    'DM',
    'HTN',
    'Current Smoker',
    'EX-Smoker',
    'FH',
    'Obesity',
    'CRF',
    'CVA',
    'Airway disease',
    'Thyroid Disease',
    'CHF',
    'DLP',
    'Edema',
    'Weak Peripheral Pulse',
    'Lung rales',
    'Systolic Murmur',
    'Diastolic Murmur',
    'Typical Chest Pain',
    'Dyspnea',
    'Atypical',
    'Nonanginal',
    'LowTH Ang',
    'Q Wave',
    'St Elevation',
    'St Depression',
    'Tinversion',
    'LVH',
    'Poor R Progression',
  };

  if (name == 'Sex') {
    return _toInt(value) == 1 ? '남' : '여';
  }

  if (binaryNames.contains(name)) {
    return _toInt(value) == 1 ? '있음' : '없음';
  }

  return value.toString();
}

String _statusLabel(String status) {
  switch (status.toUpperCase()) {
    case 'REVIEW_REQUIRED':
      return '의료진 검토 필요';

    case 'FINAL':
      return '최종 확정';

    case 'SUCCEEDED':
      return '분석 완료';

    default:
      return status.isEmpty ? '-' : status;
  }
}

String _warningLabel(String warning) {
  return warning.replaceAll(
    ' is outside the development range ',
    ' · 모델 개발 범위 초과: ',
  );
}

String _featureLabel(String feature) {
  const labels = <String, String>{
    'Typical Chest Pain': '전형적 흉통',
    'Atypical': '비전형적 흉통',
    'EF-TTE': 'EF-TTE',
    'Age': '나이',
    'FBS': '공복혈당',
    'CR': 'Creatinine',
    'TG': 'Triglyceride',
    'LDL': 'LDL',
    'HDL': 'HDL',
    'Na': 'Sodium',
    'K': 'Potassium',
  };

  return labels[feature] ?? feature;
}
