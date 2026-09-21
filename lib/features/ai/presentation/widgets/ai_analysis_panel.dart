import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/theme/app_theme.dart';
import '../ai_ui_models.dart';

// ============================================================
// STEP 1. Analysis Panel
// ============================================================

class AiAnalysisPanel extends StatefulWidget {
  final List<AiAnalysisUiModel> analyses;
  final List<AiInputUiModel> inputs;
  final List<AiJobUiModel> jobs;
  final List<AiAnalysisResultSummaryUiModel> resultSummaries;

  final VoidCallback onCreateAnalysis;

  final ValueChanged<AiAnalysisUiModel> onRetry;
  final ValueChanged<AiAnalysisUiModel> onCancel;
  final ValueChanged<AiAnalysisUiModel> onAnalysisSelected;

  const AiAnalysisPanel({
    super.key,
    required this.analyses,
    required this.inputs,
    required this.jobs,
    required this.resultSummaries,
    required this.onCreateAnalysis,
    required this.onRetry,
    required this.onCancel,
    required this.onAnalysisSelected,
  });

  @override
  State<AiAnalysisPanel> createState() => _AiAnalysisPanelState();
}

class _AiAnalysisPanelState extends State<AiAnalysisPanel> {
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';
  String _statusFilter = 'ALL';
  String _typeFilter = 'ALL';

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
          _analysisTypeLabel(
            analysis.analysisType,
          ).toLowerCase().contains(query) ||
          analysis.id.toString().contains(query) ||
          analysis.examinationId.toString().contains(query);

      final matchesStatus = _matchesStatus(analysis, _statusFilter);

      final matchesType = _matchesType(analysis, _typeFilter);

      return matchesSearch && matchesStatus && matchesType;
    }).toList();
  }

  bool _matchesStatus(AiAnalysisUiModel analysis, String filter) {
    switch (filter) {
      case 'WAITING':
        return analysis.status == 'REQUESTED' || analysis.status == 'QUEUED';

      case 'RUNNING':
        return analysis.status == 'RUNNING';

      case 'SUCCEEDED':
        return analysis.status == 'SUCCEEDED';

      case 'FAILED':
        return analysis.status == 'FAILED';

      case 'ALL':
      default:
        return true;
    }
  }

  bool _matchesType(AiAnalysisUiModel analysis, String filter) {
    switch (filter) {
      case 'CLINICAL':
        return analysis.analysisType == 'CLINICAL';

      case 'ANGIO_2D':
        return analysis.analysisType == 'ANGIO_2D';

      case 'CCTA':
        return analysis.analysisType == 'CCTA' ||
            analysis.analysisType == 'CCTA_SEGMENTATION';

      case 'ALL':
      default:
        return true;
    }
  }

  int _statusCount(String filter) {
    return widget.analyses.where((analysis) {
      return _matchesType(analysis, _typeFilter) &&
          _matchesStatus(analysis, filter);
    }).length;
  }

  // ============================================================
  // Selected Analysis
  // ============================================================

  AiAnalysisUiModel? get _selected {
    for (final analysis in widget.analyses) {
      if (analysis.id == _selectedId) {
        return analysis;
      }
    }

    return null;
  }

  // ============================================================
  // Selected Input
  // ============================================================

  AiInputUiModel? _inputFor(AiAnalysisUiModel analysis) {
    for (final input in widget.inputs) {
      if (input.analysisId == analysis.id) {
        return input;
      }
    }

    return null;
  }

  // ============================================================
  // Selected Job
  // 가장 최근 Job 사용
  // ============================================================

  AiJobUiModel? _jobFor(AiAnalysisUiModel analysis) {
    AiJobUiModel? latest;

    for (final job in widget.jobs) {
      if (job.analysisId != analysis.id) {
        continue;
      }

      if (latest == null || job.id > latest.id) {
        latest = job;
      }
    }

    return latest;
  }

  // ============================================================
  // Selected Result
  // 가장 최근 Result 사용
  // ============================================================

  AiAnalysisResultSummaryUiModel? _resultFor(AiAnalysisUiModel analysis) {
    AiAnalysisResultSummaryUiModel? latest;

    for (final result in widget.resultSummaries) {
      if (result.analysisId != analysis.id) {
        continue;
      }

      if (latest == null || result.id > latest.id) {
        latest = result;
      }
    }

    return latest;
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
                  job: _jobFor(selected),
                  result: _resultFor(selected),
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
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'AI 분석',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.appTextPrimary,
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
            child: Row(
              children: [
                Expanded(
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
                        fillColor: context.appBackground,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: context.appBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: context.appBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.appBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _typeFilter,
                      isDense: true,
                      borderRadius: BorderRadius.circular(10),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: context.appTextPrimary,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ALL', child: Text('전체 분석')),
                        DropdownMenuItem(
                          value: 'CLINICAL',
                          child: Text('혈액·임상'),
                        ),
                        DropdownMenuItem(
                          value: 'ANGIO_2D',
                          child: Text('2D 혈관조영'),
                        ),
                        DropdownMenuItem(value: 'CCTA', child: Text('3D CCTA')),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _typeFilter = value;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 9),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _FilterButton(
                  text: '전체 ${_statusCount('ALL')}',
                  selected: _statusFilter == 'ALL',
                  onTap: () {
                    setState(() {
                      _statusFilter = 'ALL';
                    });
                  },
                ),

                const SizedBox(width: 5),

                _FilterButton(
                  text: '대기 ${_statusCount('WAITING')}',
                  selected: _statusFilter == 'WAITING',
                  onTap: () {
                    setState(() {
                      _statusFilter = 'WAITING';
                    });
                  },
                ),

                const SizedBox(width: 5),

                _FilterButton(
                  text: '분석 중 ${_statusCount('RUNNING')}',
                  selected: _statusFilter == 'RUNNING',
                  onTap: () {
                    setState(() {
                      _statusFilter = 'RUNNING';
                    });
                  },
                ),

                const SizedBox(width: 5),

                _FilterButton(
                  text: '완료 ${_statusCount('SUCCEEDED')}',
                  selected: _statusFilter == 'SUCCEEDED',
                  onTap: () {
                    setState(() {
                      _statusFilter = 'SUCCEEDED';
                    });
                  },
                ),

                const SizedBox(width: 5),

                _FilterButton(
                  text: '실패 ${_statusCount('FAILED')}',
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

          Divider(height: 1, color: context.appBorder),

          Expanded(
            child: analyses.isEmpty
                ? Center(
                    child: Text(
                      '조건에 맞는 AI 분석이 없습니다.',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.appTextSecondary,
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

                          widget.onAnalysisSelected(analysis);
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
          color: selected ? context.appSurfaceSoft : context.appSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : context.appBorder,
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
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.appTextPrimary,
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
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: context.appTextPrimary,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              '#${analysis.id} · 검사 #${analysis.examinationId}',
              style: TextStyle(fontSize: 9.5, color: context.appTextSecondary),
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
  final AiJobUiModel? job;
  final AiAnalysisResultSummaryUiModel? result;

  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const _AnalysisDetailPanel({
    required this.analysis,
    required this.input,
    required this.job,
    required this.result,
    required this.onRetry,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
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
                    color: context.appSurfaceSoft,
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
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: context.appTextPrimary,
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
                        style: TextStyle(
                          fontSize: 10.5,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: context.appBorder),

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
                    title: 'AI 작업 정보',
                    icon: Icons.memory_rounded,
                    children: job == null
                        ? const [_InfoRow(label: 'Job', value: '작업 정보 없음')]
                        : [
                            _InfoRow(label: 'Job ID', value: '#${job!.id}'),
                            _InfoRow(
                              label: '모델 버전',
                              value: '#${job!.aiModelVersion}',
                            ),
                            _InfoRow(label: '작업 상태', value: job!.status),
                            _InfoRow(
                              label: '재시도',
                              value: '${job!.retryCount}회',
                            ),
                            if (job!.workerId != null)
                              _InfoRow(label: 'Worker', value: job!.workerId!),
                            _InfoRow(
                              label: '진행률',
                              value:
                                  '${job!.progressPercent.toStringAsFixed(0)}%',
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 6, bottom: 2),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: LinearProgressIndicator(
                                  value: (job!.progressPercent / 100).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                  minHeight: 7,
                                  backgroundColor: context.appSurfaceSoft,
                                  color: AppColors.navy,
                                ),
                              ),
                            ),
                            if (job!.errorMessage != null &&
                                job!.errorMessage!.isNotEmpty)
                              _InfoRow(label: '오류', value: job!.errorMessage!),
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

                  if (result != null) ...[
                    const SizedBox(height: 12),

                    _InfoCard(
                      title: 'AI 결과 요약',
                      icon: Icons.auto_graph_rounded,
                      children: [
                        _InfoRow(label: 'Result ID', value: '#${result!.id}'),
                        _InfoRow(label: '결과 유형', value: result!.resultType),
                        _InfoRow(label: '검토 상태', value: result!.status),
                        if (result!.confidence != null)
                          _InfoRow(
                            label: 'Confidence',
                            value:
                                '${(result!.confidence! * 100).toStringAsFixed(1)}%',
                          ),
                        _InfoRow(label: '요약', value: result!.summaryText),
                        if (result!.resultJson['probability'] != null)
                          _InfoRow(
                            label: '위험 확률',
                            value:
                                '${(((result!.resultJson['probability'] as num).toDouble()) * 100).toStringAsFixed(1)}%',
                          ),
                        if (result!.resultJson['prediction'] != null)
                          _InfoRow(
                            label: '예측값',
                            value: result!.resultJson['prediction'].toString(),
                          ),
                      ],
                    ),
                  ],

                  if (analysis.status == 'SUCCEEDED') ...[
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
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppColors.primaryBlue,
                          ),

                          SizedBox(width: 8),
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
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(top: BorderSide(color: context.appBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 10.5, color: context.appTextSecondary),
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
        color: context.appSurface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: context.appBorder),
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
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.appTextPrimary,
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
              style: TextStyle(fontSize: 10, color: context.appTextSecondary),
            ),
          ),

          Expanded(
            child: valueWidget != null
                ? Align(alignment: Alignment.centerLeft, child: valueWidget!)
                : Text(
                    value ?? '-',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: context.appTextPrimary,
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
            color: selected ? AppColors.navy : context.appSurfaceSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : context.appTextSecondary,
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
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
      ),
      child: Center(
        child: Text(
          'AI 분석 항목을 선택해 주세요.',
          style: TextStyle(fontSize: 11.5, color: context.appTextSecondary),
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
    case 'CLINICAL':
    case 'LAB':
      return '혈액·임상 AI 분석';

    case 'ANGIO_2D':
      return '2D 혈관조영 AI 분석';

    case 'CCTA':
      return 'CCTA AI 분석';

    case 'CCTA_SEGMENTATION':
      return 'CCTA 혈관 분할';

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
