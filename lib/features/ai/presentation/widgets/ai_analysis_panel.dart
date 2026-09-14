import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../ai_ui_models.dart';

// ============================================================
// STEP 1. Analysis Panel
// ============================================================

class AiAnalysisPanel extends StatefulWidget {
  final List<AiAnalysisUiModel> analyses;
  final List<AiInputUiModel> inputs;

  final VoidCallback onCreateAnalysis;

  final ValueChanged<AiAnalysisUiModel> onRetry;
  final ValueChanged<AiAnalysisUiModel> onCancel;

  const AiAnalysisPanel({
    super.key,
    required this.analyses,
    required this.inputs,
    required this.onCreateAnalysis,
    required this.onRetry,
    required this.onCancel,
  });

  @override
  State<AiAnalysisPanel> createState() => _AiAnalysisPanelState();
}

class _AiAnalysisPanelState extends State<AiAnalysisPanel> {
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';
  String _statusFilter = 'ALL';

  int? _selectedId;

  // ============================================================
  // STEP 2. Init / Dispose
  // ============================================================

  @override
  void initState() {
    super.initState();

    if (widget.analyses.isNotEmpty) {
      _selectedId = widget.analyses.first.id;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // STEP 3. Filter
  // ============================================================

  List<AiAnalysisUiModel> get _filtered {
    final query = _searchText.trim().toLowerCase();

    return widget.analyses.where((analysis) {
      final matchesSearch =
          query.isEmpty ||
          analysis.patientName.toLowerCase().contains(query) ||
          analysis.analysisType.toLowerCase().contains(query) ||
          analysis.id.toString().contains(query) ||
          analysis.examinationId.toString().contains(query);

      final matchesStatus =
          _statusFilter == 'ALL' || analysis.status == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  AiAnalysisUiModel? get _selected {
    for (final analysis in widget.analyses) {
      if (analysis.id == _selectedId) {
        return analysis;
      }
    }

    return null;
  }

  AiInputUiModel? _inputFor(AiAnalysisUiModel analysis) {
    for (final input in widget.inputs) {
      if (input.analysisId == analysis.id) {
        return input;
      }
    }

    return null;
  }

  // ============================================================
  // STEP 4. UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final selected = _selected;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ======================================================
        // Left
        // ======================================================
        Expanded(flex: 4, child: _buildListPanel()),

        const SizedBox(width: 14),

        // ======================================================
        // Right
        // ======================================================
        Expanded(
          flex: 6,
          child: selected == null
              ? const _EmptyDetail()
              : _AnalysisDetailPanel(
                  analysis: selected,
                  input: _inputFor(selected),
                  onRetry: () {
                    widget.onRetry(selected);
                  },
                  onCancel: () {
                    widget.onCancel(selected);
                  },
                ),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 5. List
  // ============================================================

  Widget _buildListPanel() {
    final analyses = _filtered;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'AI 분석',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                FilledButton.icon(
                  onPressed: widget.onCreateAnalysis,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    minimumSize: const Size(100, 36),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 15),
                  label: const Text('분석 요청', style: TextStyle(fontSize: 10.5)),
                ),
              ],
            ),
          ),

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
                  hintText: '환자 · 분석 종류 · 분석번호 검색',
                  prefixIcon: const Icon(Icons.search_rounded, size: 17),
                  filled: true,
                  fillColor: AppColors.background,
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

          const SizedBox(height: 9),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _FilterButton(
                  text: '전체',
                  selected: _statusFilter == 'ALL',
                  onTap: () {
                    setState(() {
                      _statusFilter = 'ALL';
                    });
                  },
                ),

                const SizedBox(width: 5),

                _FilterButton(
                  text: '진행',
                  selected: _statusFilter == 'RUNNING',
                  onTap: () {
                    setState(() {
                      _statusFilter = 'RUNNING';
                    });
                  },
                ),

                const SizedBox(width: 5),

                _FilterButton(
                  text: '완료',
                  selected: _statusFilter == 'SUCCEEDED',
                  onTap: () {
                    setState(() {
                      _statusFilter = 'SUCCEEDED';
                    });
                  },
                ),

                const SizedBox(width: 5),

                _FilterButton(
                  text: '실패',
                  selected: _statusFilter == 'FAILED',
                  onTap: () {
                    setState(() {
                      _statusFilter = 'FAILED';
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          const Divider(height: 1, color: AppColors.border),

          Expanded(
            child: analyses.isEmpty
                ? const Center(
                    child: Text(
                      '조건에 맞는 AI 분석이 없습니다.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: analyses.length,
                    separatorBuilder: (_, _) {
                      return const SizedBox(height: 7);
                    },
                    itemBuilder: (context, index) {
                      final analysis = analyses[index];

                      return _AnalysisListItem(
                        analysis: analysis,
                        selected: analysis.id == _selectedId,
                        onTap: () {
                          setState(() {
                            _selectedId = analysis.id;
                          });
                        },
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
// STEP 6. List Item
// ============================================================

class _AnalysisListItem extends StatelessWidget {
  final AiAnalysisUiModel analysis;
  final bool selected;
  final VoidCallback onTap;

  const _AnalysisListItem({
    required this.analysis,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    analysis.patientName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                if (analysis.isDemo) ...[
                  const _DemoBadge(),
                  const SizedBox(width: 5),
                ],

                AiStatusBadge(status: analysis.status),
              ],
            ),

            const SizedBox(height: 5),

            Text(
              _analysisTypeLabel(analysis.analysisType),
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              '#${analysis.id} · 검사 #${analysis.examinationId}',
              style: const TextStyle(
                fontSize: 9.5,
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
// STEP 7. Detail
// ============================================================

class _AnalysisDetailPanel extends StatelessWidget {
  final AiAnalysisUiModel analysis;
  final AiInputUiModel? input;

  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const _AnalysisDetailPanel({
    required this.analysis,
    required this.input,
    required this.onRetry,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_outlined,
                    size: 21,
                    color: AppColors.navy,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _analysisTypeLabel(analysis.analysisType),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          if (analysis.isDemo) ...[
                            const _DemoBadge(),
                            const SizedBox(width: 5),
                          ],

                          AiStatusBadge(status: analysis.status),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '${analysis.patientName} · ${analysis.patientMeta}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoCard(
                    title: '분석 정보',
                    icon: Icons.analytics_outlined,
                    children: [
                      _InfoRow(label: 'Analysis ID', value: '#${analysis.id}'),
                      _InfoRow(
                        label: 'Examination',
                        value: '#${analysis.examinationId}',
                      ),
                      _InfoRow(label: '분석 종류', value: analysis.analysisType),
                      _InfoRow(
                        label: '요청 의료진',
                        value: '#${analysis.requestedBy}',
                      ),
                      _InfoRow(
                        label: '상태',
                        valueWidget: AiStatusBadge(status: analysis.status),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _InfoCard(
                    title: '입력 데이터',
                    icon: Icons.input_outlined,
                    children: input == null
                        ? const [_InfoRow(label: 'Input', value: '연결 정보 없음')]
                        : [
                            _InfoRow(
                              label: 'Input Type',
                              value: input!.inputType,
                            ),
                            _InfoRow(
                              label: 'Source',
                              value: input!.sourceLabel,
                            ),
                            _InfoRow(
                              label: 'File Asset',
                              value: input!.fileAssetId == null
                                  ? '-'
                                  : '#${input!.fileAssetId}',
                            ),
                            _InfoRow(
                              label: '검증 상태',
                              value: input!.validationStatus,
                            ),
                          ],
                  ),

                  const SizedBox(height: 12),

                  _InfoCard(
                    title: '시간 정보',
                    icon: Icons.schedule_outlined,
                    children: [
                      _InfoRow(
                        label: '요청일',
                        value: formatAiDateTime(analysis.requestedAt),
                      ),
                      _InfoRow(
                        label: '완료일',
                        value: analysis.completedAt == null
                            ? '-'
                            : formatAiDateTime(analysis.completedAt!),
                      ),
                    ],
                  ),

                  if (analysis.status == 'SUCCEEDED') ...[
                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppColors.primaryBlue,
                          ),

                          SizedBox(width: 8),

                          Expanded(
                            child: Text(
                              '현재 Backend에는 Analysis 메타데이터는 존재하지만 Job / Result가 생성되지 않은 항목이 있습니다. 실제 결과 연결 전까지 결과 화면은 UI DEMO 데이터로 표시됩니다.',
                              style: TextStyle(
                                fontSize: 9.5,
                                height: 1.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (analysis.status == 'FAILED')
            _ActionFooter(
              text: '분석 작업이 실패했습니다.',
              buttonLabel: '재시도',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            )
          else if (analysis.status == 'RUNNING')
            _ActionFooter(
              text: 'AI 분석이 진행 중입니다.',
              buttonLabel: '분석 취소',
              icon: Icons.close_rounded,
              onPressed: onCancel,
              outlined: true,
            ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 8. Footer
// ============================================================

class _ActionFooter extends StatelessWidget {
  final String text;
  final String buttonLabel;
  final IconData icon;

  final VoidCallback onPressed;

  final bool outlined;

  const _ActionFooter({
    required this.text,
    required this.buttonLabel,
    required this.icon,
    required this.onPressed,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          if (outlined)
            OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 15),
              label: Text(buttonLabel),
            )
          else
            FilledButton.icon(
              onPressed: onPressed,
              style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
              icon: Icon(icon, size: 15),
              label: Text(buttonLabel),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 9. Shared Widgets
// ============================================================

class AiStatusBadge extends StatelessWidget {
  final String status;

  const AiStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final background = _statusBackground(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _DemoBadge extends StatelessWidget {
  const _DemoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warningBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'UI DEMO',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: AppColors.warning,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.navy),

              const SizedBox(width: 7),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;

  const _InfoRow({required this.label, this.value, this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          Expanded(
            child: valueWidget != null
                ? Align(alignment: Alignment.centerLeft, child: valueWidget!)
                : Text(
                    value ?? '-',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Text(
          'AI 분석 항목을 선택해 주세요.',
          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 10. Helpers
// ============================================================

String formatAiDateTime(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');

  final day = date.day.toString().padLeft(2, '0');

  final hour = date.hour.toString().padLeft(2, '0');

  final minute = date.minute.toString().padLeft(2, '0');

  return '${date.year}.$month.$day $hour:$minute';
}

String _analysisTypeLabel(String type) {
  switch (type) {
    case 'CCTA':
      return 'CCTA AI 분석';

    case 'ANGIO_2D':
      return '2D 혈관조영 AI 분석';

    case 'LAB':
      return '혈액·임상 AI 분석';

    default:
      return type;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'REQUESTED':
      return '요청됨';

    case 'QUEUED':
      return '대기';

    case 'RUNNING':
      return '분석 중';

    case 'SUCCEEDED':
      return '완료';

    case 'FAILED':
      return '실패';

    case 'CANCELED':
      return '취소';

    default:
      return status;
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'SUCCEEDED':
      return AppColors.success;

    case 'RUNNING':
      return AppColors.primaryBlue;

    case 'FAILED':
    case 'CANCELED':
      return AppColors.danger;

    default:
      return AppColors.warning;
  }
}

Color _statusBackground(String status) {
  switch (status) {
    case 'SUCCEEDED':
      return AppColors.successBackground;

    case 'RUNNING':
      return AppColors.surfaceSoft;

    case 'FAILED':
    case 'CANCELED':
      return AppColors.dangerBackground;

    default:
      return AppColors.warningBackground;
  }
}
