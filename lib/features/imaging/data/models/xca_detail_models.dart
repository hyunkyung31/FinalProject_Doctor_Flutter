// ============================================================
// STEP 1. XCA Detail
// ============================================================

class XcaDetailRecord {
  final int id;
  final int backendPatientId;
  final int examinationId;
  final int analysisId;
  final int resultId;

  final String status;
  final String? sourceSubjectId;

  final List<XcaSequenceRecord> sequences;

  const XcaDetailRecord({
    required this.id,
    required this.backendPatientId,
    required this.examinationId,
    required this.analysisId,
    required this.resultId,
    required this.status,
    required this.sourceSubjectId,
    required this.sequences,
  });

  factory XcaDetailRecord.fromJson(Map<String, dynamic> json) {
    final inputSnapshot = _toMap(json['input_snapshot']);

    final sequenceItems = _toMapList(inputSnapshot['sequences']);

    // XCADetail의 series_json.
    // series_id는 현재 sequence_no와 대응한다.
    final seriesItems = _toMapList(json['series']);

    final seriesByNumber = <String, Map<String, dynamic>>{};

    for (final item in seriesItems) {
      final seriesNo = item['series_id']?.toString();

      if (seriesNo != null && seriesNo.isNotEmpty) {
        seriesByNumber[seriesNo] = item;
      }
    }

    final sequences = sequenceItems.map((item) {
      final sequenceNo = item['sequence_no']?.toString() ?? '-';

      return XcaSequenceRecord.fromJson(
        item,
        seriesMetadata: seriesByNumber[sequenceNo],
      );
    }).toList();

    return XcaDetailRecord(
      id: _toInt(json['id']) ?? 0,
      backendPatientId: _toInt(json['backend_patient_id']) ?? 0,
      examinationId: _toInt(json['examination_id']) ?? 0,
      analysisId: _toInt(json['analysis_id']) ?? 0,
      resultId: _toInt(json['result_id']) ?? 0,
      status: json['status']?.toString() ?? '',
      sourceSubjectId: inputSnapshot['source_subject_id']?.toString(),
      sequences: sequences,
    );
  }
}

// ============================================================
// STEP 2. XCA Sequence
// ============================================================

class XcaSequenceRecord {
  final int sequenceId;
  final String sequenceNo;
  final String side;
  final int frameCount;

  final List<int> suspectedFrameIndices;
  final int? representativeFrameIndex;
  final String? representativeSelection;

  const XcaSequenceRecord({
    required this.sequenceId,
    required this.sequenceNo,
    required this.side,
    required this.frameCount,
    required this.suspectedFrameIndices,
    required this.representativeFrameIndex,
    required this.representativeSelection,
  });

  factory XcaSequenceRecord.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? seriesMetadata,
  }) {
    final metadata = seriesMetadata ?? <String, dynamic>{};

    return XcaSequenceRecord(
      sequenceId: _toInt(json['sequence_id']) ?? 0,
      sequenceNo: json['sequence_no']?.toString() ?? '-',
      side: json['side']?.toString().toUpperCase() ?? 'UNKNOWN',
      frameCount:
          _toInt(json['frame_count']) ?? _toInt(metadata['n_frames']) ?? 0,
      suspectedFrameIndices: _toIntList(metadata['suspected_frame_indices']),
      representativeFrameIndex: _toInt(metadata['representative_frame_index']),
      representativeSelection: metadata['representative_selection']?.toString(),
    );
  }

  String get sideLabel {
    switch (side) {
      case 'LEFT':
        return '좌측 관상동맥';

      case 'RIGHT':
        return '우측 관상동맥';

      default:
        return '미분류';
    }
  }
}

// ============================================================
// STEP 3. Frame Asset
// ============================================================

class XcaFrameAsset {
  final int? fileAssetId;
  final String url;
  final int expiresIn;

  const XcaFrameAsset({
    required this.fileAssetId,
    required this.url,
    required this.expiresIn,
  });

  static XcaFrameAsset? fromDynamic(dynamic value) {
    if (value is! Map) {
      return null;
    }

    final json = Map<String, dynamic>.from(value);

    final url = json['url']?.toString() ?? '';

    if (url.isEmpty) {
      return null;
    }

    return XcaFrameAsset(
      fileAssetId: _toInt(json['file_asset_id']),
      url: url,
      expiresIn: _toInt(json['expires_in']) ?? 0,
    );
  }
}

// ============================================================
// STEP 4. Bounding Box
// bbox_xywh = [x, y, width, height]
// ============================================================

class XcaBoundingBox {
  final double x;
  final double y;
  final double width;
  final double height;
  final int? areaPixels;

  const XcaBoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.areaPixels,
  });

  factory XcaBoundingBox.fromJson(Map<String, dynamic> json) {
    final bbox = json['bbox_xywh'];
    final values = bbox is List ? bbox : const [];

    double read(int index) {
      if (index >= values.length) {
        return 0;
      }

      return _toDouble(values[index]) ?? 0;
    }

    return XcaBoundingBox(
      x: read(0),
      y: read(1),
      width: read(2),
      height: read(3),
      areaPixels: _toInt(json['area_pixels']),
    );
  }
}

// ============================================================
// STEP 5. XCA Frame
// ============================================================

class XcaFrameRecord {
  final int id;
  final int detailId;

  final int sequenceId;
  final String sequenceNo;

  final int frameIndex;

  final int width;
  final int height;

  final double? softMax;
  final double? postPresence;
  final double? postAreaRatio;

  final String localizationLabel;
  final String localizationValidation;

  final XcaFrameAsset source;
  final XcaFrameAsset? mask;
  final XcaFrameAsset? preview;

  final List<XcaBoundingBox> boundingBoxes;

  const XcaFrameRecord({
    required this.id,
    required this.detailId,
    required this.sequenceId,
    required this.sequenceNo,
    required this.frameIndex,
    required this.width,
    required this.height,
    required this.softMax,
    required this.postPresence,
    required this.postAreaRatio,
    required this.localizationLabel,
    required this.localizationValidation,
    required this.source,
    required this.mask,
    required this.preview,
    required this.boundingBoxes,
  });

  factory XcaFrameRecord.fromJson(Map<String, dynamic> json) {
    final source = XcaFrameAsset.fromDynamic(json['source']);

    if (source == null) {
      throw const FormatException('XCA Frame에 source 영상 URL이 없습니다.');
    }

    final features = _toMap(json['features']);

    final localization = _toMap(json['localization']);

    final componentItems = _toMapList(localization['source_components']);

    return XcaFrameRecord(
      id: _toInt(json['id']) ?? 0,
      detailId: _toInt(json['detail_id']) ?? 0,
      sequenceId: _toInt(json['sequence_id']) ?? 0,
      sequenceNo: json['sequence_no']?.toString() ?? '-',
      frameIndex: _toInt(json['frame_index']) ?? 0,
      width: _toInt(json['width']) ?? 512,
      height: _toInt(json['height']) ?? 512,
      softMax: _toDouble(features['soft_max']),
      postPresence: _toDouble(features['post_presence']),
      postAreaRatio: _toDouble(features['post_area_ratio']),
      localizationLabel:
          localization['label']?.toString() ?? 'suspected_stenosis_region',
      localizationValidation: localization['validation']?.toString() ?? '',
      source: source,
      mask: XcaFrameAsset.fromDynamic(json['mask']),
      preview: XcaFrameAsset.fromDynamic(json['preview']),
      boundingBoxes: componentItems.map(XcaBoundingBox.fromJson).toList(),
    );
  }

  bool get hasAiLocalization {
    return preview != null || mask != null || boundingBoxes.isNotEmpty;
  }
}

// ============================================================
// STEP 6. Parser Helpers
// ============================================================

Map<String, dynamic> _toMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return <String, dynamic>{};
}

List<Map<String, dynamic>> _toMapList(dynamic value) {
  if (value is! List) {
    return <Map<String, dynamic>>[];
  }

  return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
}

List<int> _toIntList(dynamic value) {
  if (value is! List) {
    return <int>[];
  }

  final result = <int>[];

  for (final item in value) {
    final parsed = _toInt(item);

    if (parsed != null) {
      result.add(parsed);
    }
  }

  return result;
}

int? _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '');
}

double? _toDouble(dynamic value) {
  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '');
}
