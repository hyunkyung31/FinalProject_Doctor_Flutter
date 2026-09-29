import 'dart:convert';

// ============================================================
// STEP 1. Questionnaire Response Status
// ============================================================

enum QuestionnaireResponseStatus { submitted, reviewed, unknown }

extension QuestionnaireResponseStatusExtension on QuestionnaireResponseStatus {
  String get label {
    switch (this) {
      case QuestionnaireResponseStatus.submitted:
        return '검토 대기';
      case QuestionnaireResponseStatus.reviewed:
        return '검토 완료';
      case QuestionnaireResponseStatus.unknown:
        return '상태 확인 필요';
    }
  }
}

// ============================================================
// STEP 2. Questionnaire Option UI Model
// Backend options_json: [{"value": "...", "label": "..."}]
// ============================================================

class QuestionnaireOptionUiModel {
  final String value;
  final String label;

  const QuestionnaireOptionUiModel({required this.value, required this.label});

  factory QuestionnaireOptionUiModel.fromJson(Map<String, dynamic> json) {
    return QuestionnaireOptionUiModel(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

// ============================================================
// STEP 3. Questionnaire Answer UI Model
// ============================================================

class QuestionnaireAnswerUiModel {
  final int id;
  final int? responseId;
  final int? questionId;

  final String? questionText;
  final String? questionCode;
  final String? questionType;
  final int? questionStep;
  final int? questionDisplayOrder;

  final List<QuestionnaireOptionUiModel> questionOptions;

  final String? answerText;
  final num? answerNumeric;
  final bool? answerBoolean;
  final dynamic answerJson;

  final DateTime? createdAt;

  const QuestionnaireAnswerUiModel({
    required this.id,
    required this.responseId,
    required this.questionId,
    required this.questionText,
    required this.questionCode,
    required this.questionType,
    required this.questionStep,
    required this.questionDisplayOrder,
    required this.questionOptions,
    required this.answerText,
    required this.answerNumeric,
    required this.answerBoolean,
    required this.answerJson,
    required this.createdAt,
  });

  factory QuestionnaireAnswerUiModel.fromJson(Map<String, dynamic> json) {
    final questionRaw = json['question'];

    int? questionId;
    String? questionText;
    String? questionCode;
    String? questionType;
    int? questionStep;
    int? questionDisplayOrder;
    dynamic questionOptionsRaw;

    if (questionRaw is Map) {
      final question = Map<String, dynamic>.from(questionRaw);

      questionId = _toNullableInt(question['id']);
      questionText = _firstNonEmptyString([
        question['question_text'],
        question['text'],
        question['label'],
        question['title'],
      ]);
      questionCode = _firstNonEmptyString([
        question['question_code'],
        question['code'],
      ]);
      questionType = _firstNonEmptyString([
        question['question_type'],
        question['type'],
      ]);
      questionStep = _toNullableInt(question['step']);
      questionDisplayOrder = _toNullableInt(question['display_order']);
      questionOptionsRaw =
          question['options_json'] ?? question['question_options'];
    } else {
      questionId = _toNullableInt(questionRaw);
    }

    questionText ??= _firstNonEmptyString([
      json['question_text'],
      json['question_label'],
      json['label'],
    ]);

    questionCode ??= _firstNonEmptyString([
      json['question_code'],
      json['code'],
    ]);

    questionType ??= _firstNonEmptyString([
      json['question_type'],
      json['type'],
    ]);

    questionStep ??= _toNullableInt(json['question_step']);
    questionDisplayOrder ??= _toNullableInt(json['question_display_order']);

    questionOptionsRaw ??= json['question_options'] ?? json['options_json'];

    final questionOptions = _parseOptions(questionOptionsRaw);

    return QuestionnaireAnswerUiModel(
      id: _toInt(json['id']),
      responseId: _toNullableInt(json['response']),
      questionId: questionId,
      questionText: questionText,
      questionCode: questionCode,
      questionType: questionType,
      questionStep: questionStep,
      questionDisplayOrder: questionDisplayOrder,
      questionOptions: questionOptions,
      answerText: _nullableString(json['answer_label'] ?? json['answer_text']),
      answerNumeric: _toNullableNum(json['answer_numeric']),
      answerBoolean: _toNullableBool(json['answer_boolean']),
      answerJson: json['answer_json'],
      createdAt: _toNullableDateTime(json['created_at']),
    );
  }

  String get displayQuestion {
    final text = questionText?.trim();

    if (text != null && text.isNotEmpty) {
      return text;
    }

    final code = questionCode?.trim();

    if (code != null && code.isNotEmpty) {
      return code;
    }

    if (questionId != null) {
      return '문항 #$questionId';
    }

    return '문항';
  }

  String get displayAnswer {
    final type = questionType?.trim().toUpperCase();

    if (type == 'MULTI') {
      final multiValues = _extractMultiValues(answerJson);

      if (multiValues.isNotEmpty) {
        return multiValues.map(_labelForValue).join(', ');
      }
    }

    final text = answerText?.trim();

    if (text != null && text.isNotEmpty) {
      return _labelForValue(text);
    }

    if (answerNumeric != null) {
      return _formatNumber(answerNumeric!);
    }

    if (answerBoolean != null) {
      return answerBoolean! ? '예' : '아니오';
    }

    final jsonValue = answerJson;

    if (jsonValue == null) {
      return '-';
    }

    if (jsonValue is List) {
      if (jsonValue.isEmpty) {
        return '-';
      }

      return jsonValue
          .map((item) => _labelForValue(item.toString()))
          .join(', ');
    }

    if (jsonValue is Map) {
      return jsonEncode(jsonValue);
    }

    return _labelForValue(jsonValue.toString());
  }

  String _labelForValue(String rawValue) {
    final normalized = rawValue.trim();

    for (final option in questionOptions) {
      if (option.value == normalized) {
        final label = option.label.trim();

        if (label.isNotEmpty) {
          return label;
        }
      }
    }

    return normalized;
  }
}

// ============================================================
// STEP 4. Questionnaire Response UI Model
// ============================================================

class QuestionnaireResponseUiModel {
  final int id;
  final int reservationId;
  final int templateId;
  final int? patientAccountId;

  final QuestionnaireResponseStatus status;

  final DateTime? submittedAt;
  final int? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? templateName;
  final List<QuestionnaireAnswerUiModel> answers;

  const QuestionnaireResponseUiModel({
    required this.id,
    required this.reservationId,
    required this.templateId,
    required this.patientAccountId,
    required this.status,
    required this.submittedAt,
    required this.reviewedBy,
    required this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.templateName,
    required this.answers,
  });

  factory QuestionnaireResponseUiModel.fromJson(Map<String, dynamic> json) {
    final templateRaw = json['template'];

    int templateId = 0;
    String? templateName;

    if (templateRaw is Map) {
      final template = Map<String, dynamic>.from(templateRaw);

      templateId = _toInt(template['id']);
      templateName = _firstNonEmptyString([
        template['name'],
        template['title'],
        template['template_name'],
      ]);
    } else {
      templateId = _toInt(templateRaw);
    }

    templateName ??= _firstNonEmptyString([
      json['template_name'],
      json['questionnaire_name'],
    ]);

    final rawAnswers = json['answers'];

    final answers = rawAnswers is List
        ? rawAnswers
              .whereType<Map>()
              .map(
                (item) => QuestionnaireAnswerUiModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <QuestionnaireAnswerUiModel>[];

    answers.sort((a, b) {
      final stepCompare = (a.questionStep ?? 999).compareTo(
        b.questionStep ?? 999,
      );

      if (stepCompare != 0) {
        return stepCompare;
      }

      final orderCompare = (a.questionDisplayOrder ?? 999999).compareTo(
        b.questionDisplayOrder ?? 999999,
      );

      if (orderCompare != 0) {
        return orderCompare;
      }

      return (a.questionId ?? a.id).compareTo(b.questionId ?? b.id);
    });

    return QuestionnaireResponseUiModel(
      id: _toInt(json['id']),
      reservationId: _toInt(json['reservation']),
      templateId: templateId,
      patientAccountId: _toNullableInt(json['patient_account']),
      status: _parseStatus(json['status']),
      submittedAt: _toNullableDateTime(json['submitted_at']),
      reviewedBy: _toNullableInt(json['reviewed_by']),
      reviewedAt: _toNullableDateTime(json['reviewed_at']),
      createdAt: _toNullableDateTime(json['created_at']),
      updatedAt: _toNullableDateTime(json['updated_at']),
      templateName: templateName,
      answers: answers,
    );
  }

  String get displayTemplateName {
    final name = templateName?.trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    if (templateId > 0) {
      return '문진표 #$templateId';
    }

    return '사전 문진표';
  }
}

// ============================================================
// STEP 5. Parser Helpers
// ============================================================

QuestionnaireResponseStatus _parseStatus(dynamic value) {
  switch (value?.toString().toUpperCase()) {
    case 'SUBMITTED':
      return QuestionnaireResponseStatus.submitted;

    case 'REVIEWED':
      return QuestionnaireResponseStatus.reviewed;

    default:
      return QuestionnaireResponseStatus.unknown;
  }
}

List<QuestionnaireOptionUiModel> _parseOptions(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map(
        (item) => QuestionnaireOptionUiModel.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
      .where((item) => item.value.trim().isNotEmpty)
      .toList();
}

List<String> _extractMultiValues(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  if (value is Map) {
    final values = value['values'] ?? value['selected'] ?? value['items'];

    if (values is List) {
      return values
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
  }

  return const [];
}

int _toInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _toNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }

  final parsed = _toInt(value);

  return parsed > 0 ? parsed : null;
}

num? _toNullableNum(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value;
  }

  return num.tryParse(value.toString());
}

bool? _toNullableBool(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is bool) {
    return value;
  }

  final normalized = value.toString().trim().toLowerCase();

  if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
    return true;
  }

  if (normalized == 'false' || normalized == '0' || normalized == 'no') {
    return false;
  }

  return null;
}

DateTime? _toNullableDateTime(dynamic value) {
  final text = value?.toString().trim();

  if (text == null || text.isEmpty) {
    return null;
  }

  return DateTime.tryParse(text);
}

String? _nullableString(dynamic value) {
  if (value == null) {
    return null;
  }

  return value.toString();
}

String? _firstNonEmptyString(List<dynamic> values) {
  for (final value in values) {
    final text = value?.toString().trim();

    if (text != null && text.isNotEmpty) {
      return text;
    }
  }

  return null;
}

String _formatNumber(num value) {
  if (value is int) {
    return value.toString();
  }

  final doubleValue = value.toDouble();

  if (doubleValue == doubleValue.roundToDouble()) {
    return doubleValue.toInt().toString();
  }

  final text = doubleValue.toStringAsFixed(6);

  return text.replaceFirst(RegExp(r'\.?0+$'), '');
}
