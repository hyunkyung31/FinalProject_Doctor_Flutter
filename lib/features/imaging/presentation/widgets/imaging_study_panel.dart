import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../imaging_ui_models.dart';

// ============================================================
// STEP 1. Study / Series Panel
// ============================================================

class ImagingStudyPanel extends StatefulWidget {
  final List<ImagingStudyUiModel> studies;
  final List<ImagingSeriesUiModel> series;

  final int? selectedStudyId;
  final int? selectedSeriesId;

  final ValueChanged<ImagingStudyUiModel> onStudySelected;
  final ValueChanged<ImagingSeriesUiModel> onSeriesSelected;

  const ImagingStudyPanel({
    super.key,
    required this.studies,
    required this.series,
    required this.selectedStudyId,
    required this.selectedSeriesId,
    required this.onStudySelected,
    required this.onSeriesSelected,
  });

  @override
  State<ImagingStudyPanel> createState() => _ImagingStudyPanelState();
}

class _ImagingStudyPanelState extends State<ImagingStudyPanel> {
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';

  // ============================================================
  // STEP 2. Dispose
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // STEP 3. Filter
  // ============================================================

  List<ImagingStudyUiModel> get _filteredStudies {
    final query = _searchText.trim().toLowerCase();

    if (query.isEmpty) {
      return widget.studies;
    }

    return widget.studies.where((study) {
      return study.id.toString().contains(query) ||
          study.examinationId.toString().contains(query) ||
          study.modality.toLowerCase().contains(query);
    }).toList();
  }

  List<ImagingSeriesUiModel> _seriesFor(ImagingStudyUiModel study) {
    return widget.series
        .where((series) => series.imagingStudyId == study.id)
        .toList();
  }

  // ============================================================
  // STEP 4. UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // ======================================================
          // Header
          // ======================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '영상 목록',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_filteredStudies.length}건',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // Search
          // ======================================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
                style: const TextStyle(fontSize: 11),
                decoration: InputDecoration(
                  hintText: 'Study · 검사번호 · Modality 검색',
                  hintStyle: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textDisabled,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 17,
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primaryBlue),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 11),

          const Divider(height: 1, color: AppColors.border),

          // ======================================================
          // Study List
          // ======================================================
          Expanded(
            child: _filteredStudies.isEmpty
                ? const Center(
                    child: Text(
                      '조건에 맞는 영상이 없습니다.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: _filteredStudies.length,
                    separatorBuilder: (_, _) {
                      return const SizedBox(height: 8);
                    },
                    itemBuilder: (context, index) {
                      final study = _filteredStudies[index];

                      final selected = widget.selectedStudyId == study.id;

                      return _StudyCard(
                        study: study,
                        series: _seriesFor(study),
                        selected: selected,
                        selectedSeriesId: widget.selectedSeriesId,
                        onStudySelected: () {
                          widget.onStudySelected(study);
                        },
                        onSeriesSelected: widget.onSeriesSelected,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 5. Study Card
// ============================================================

class _StudyCard extends StatelessWidget {
  final ImagingStudyUiModel study;
  final List<ImagingSeriesUiModel> series;

  final bool selected;
  final int? selectedSeriesId;

  final VoidCallback onStudySelected;
  final ValueChanged<ImagingSeriesUiModel> onSeriesSelected;

  const _StudyCard({
    required this.study,
    required this.series,
    required this.selected,
    required this.selectedSeriesId,
    required this.onStudySelected,
    required this.onSeriesSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? AppColors.surfaceSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? AppColors.primaryBlue : AppColors.border,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onStudySelected,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 31,
                          height: 31,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            study.modality == 'XA'
                                ? Icons.play_circle_outline_rounded
                                : Icons.view_in_ar_outlined,
                            size: 17,
                            color: AppColors.navy,
                          ),
                        ),

                        const SizedBox(width: 9),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${study.modality} · Study #${study.id}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),

                                  if (study.isDemo) ...[
                                    const SizedBox(width: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.warningBackground,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'UI DEMO',
                                        style: TextStyle(
                                          fontSize: 7.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.warning,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              const SizedBox(height: 4),

                              Text(
                                '검사 #${study.examinationId} · ${_formatDate(study.displayDate)}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        _StudyStatusBadge(study: study),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Series ${study.seriesCount} · Instance ${study.instanceCount}',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ====================================================
          // Selected Study → Series
          // ====================================================
          if (selected && series.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.border),

            for (final item in series)
              _SeriesItem(
                series: item,
                selected: selectedSeriesId == item.id,
                onTap: () {
                  onSeriesSelected(item);
                },
              ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// STEP 6. Series Item
// ============================================================

class _SeriesItem extends StatelessWidget {
  final ImagingSeriesUiModel series;
  final bool selected;
  final VoidCallback onTap;

  const _SeriesItem({
    required this.series,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 9, 13, 9),
        color: selected ? AppColors.background : Colors.transparent,
        child: Row(
          children: [
            Icon(
              Icons.subdirectory_arrow_right_rounded,
              size: 14,
              color: selected ? AppColors.navy : AppColors.textSecondary,
            ),

            const SizedBox(width: 7),

            Expanded(
              child: Text(
                series.description ?? 'Series #${series.id}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.navy : AppColors.textPrimary,
                ),
              ),
            ),

            Text(
              '${series.instanceCount}',
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STEP 7. Status Badge
// ============================================================

class _StudyStatusBadge extends StatelessWidget {
  final ImagingStudyUiModel study;

  const _StudyStatusBadge({required this.study});

  @override
  Widget build(BuildContext context) {
    Color foreground;
    Color background;

    switch (study.status) {
      case 'RECEIVED':
        foreground = AppColors.success;
        background = AppColors.successBackground;
        break;

      case 'ERROR':
        foreground = AppColors.danger;
        background = AppColors.dangerBackground;
        break;

      default:
        foreground = AppColors.textSecondary;
        background = AppColors.surfaceSoft;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        study.statusLabel,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '${date.year}.$month.$day';
}
