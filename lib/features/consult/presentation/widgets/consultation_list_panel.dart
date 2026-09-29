import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/theme/app_theme.dart';
import '../consultation_ui_models.dart';

// ============================================================
// STEP 1. Consultation List Panel
// ============================================================

class ConsultationListPanel extends StatefulWidget {
  final List<ConsultationUiModel> consultations;
  final int? selectedId;
  final ValueChanged<ConsultationUiModel> onSelected;
  final VoidCallback onCreate;

  const ConsultationListPanel({
    super.key,
    required this.consultations,
    required this.selectedId,
    required this.onSelected,
    required this.onCreate,
  });

  @override
  State<ConsultationListPanel> createState() => _ConsultationListPanelState();
}

class _ConsultationListPanelState extends State<ConsultationListPanel> {
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';
  ConsultationUiStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // STEP 2. Filter
  // ============================================================

  List<ConsultationUiModel> get _filtered {
    final query = _searchText.trim().toLowerCase();

    return widget.consultations.where((item) {
      final requester = item.requester?.doctorName ?? '';

      final matchesQuery =
          query.isEmpty ||
          item.patientName.toLowerCase().contains(query) ||
          item.patientMeta.toLowerCase().contains(query) ||
          item.subject.toLowerCase().contains(query) ||
          item.assignedDoctorName.toLowerCase().contains(query) ||
          requester.toLowerCase().contains(query);

      final matchesStatus =
          _statusFilter == null || item.status == _statusFilter;

      return matchesQuery && matchesStatus;
    }).toList();
  }

  int get _activeCount {
    return widget.consultations.where((item) {
      return item.status == ConsultationUiStatus.requested ||
          item.status == ConsultationUiStatus.inProgress;
    }).length;
  }

  // ============================================================
  // STEP 3. UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildHeader(),
          Divider(height: 1, color: context.appBorder),
          _buildSearch(),
          _buildStatusFilter(),
          Divider(height: 1, color: context.appBorder),
          Expanded(
            child: items.isEmpty
                ? _buildEmpty()
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: context.appBorder),
                    itemBuilder: (context, index) {
                      final consultation = items[index];

                      return _ConsultationListItem(
                        consultation: consultation,
                        selected: consultation.id == widget.selectedId,
                        onTap: () {
                          widget.onSelected(consultation);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 4. Header
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '협진 목록',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.appTextPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '전체 ${widget.consultations.length}건 · 진행 중 $_activeCount건',
                  style: TextStyle(
                    fontSize: 9,
                    color: context.appTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: widget.onCreate,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              minimumSize: const Size(0, 36),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 15),
            label: const Text(
              '협진 요청',
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 5. Search
  // ============================================================

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 9),
      child: SizedBox(
        height: 38,
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchText = value;
            });
          },
          style: TextStyle(fontSize: 10, color: context.appTextPrimary),
          decoration: InputDecoration(
            hintText: '환자명, 협진 제목, 의료진 검색',
            hintStyle: TextStyle(fontSize: 9.5, color: context.appTextDisabled),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 17,
              color: context.appTextSecondary,
            ),
            filled: true,
            fillColor: context.appBackground,
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: context.appBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primaryBlue),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP 6. Status Filter
  // ============================================================

  Widget _buildStatusFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Row(
        children: [
          Expanded(
            child: _StatusSegment(
              label: '전체',
              selected: _statusFilter == null,
              onTap: () {
                setState(() {
                  _statusFilter = null;
                });
              },
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _StatusSegment(
              label: '요청',
              selected: _statusFilter == ConsultationUiStatus.requested,
              onTap: () {
                setState(() {
                  _statusFilter = ConsultationUiStatus.requested;
                });
              },
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _StatusSegment(
              label: '진행',
              selected: _statusFilter == ConsultationUiStatus.inProgress,
              onTap: () {
                setState(() {
                  _statusFilter = ConsultationUiStatus.inProgress;
                });
              },
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _StatusSegment(
              label: '완료',
              selected: _statusFilter == ConsultationUiStatus.completed,
              onTap: () {
                setState(() {
                  _statusFilter = ConsultationUiStatus.completed;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 7. Empty
  // ============================================================

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 28,
              color: context.appTextDisabled,
            ),
            const SizedBox(height: 8),
            Text(
              '조건에 맞는 협진이 없습니다.',
              style: TextStyle(fontSize: 10, color: context.appTextSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STEP 8. Consultation List Item
// ============================================================

class _ConsultationListItem extends StatelessWidget {
  final ConsultationUiModel consultation;
  final bool selected;
  final VoidCallback onTap;

  const _ConsultationListItem({
    required this.consultation,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final requester = consultation.requester;

    return Material(
      color: selected ? context.appSurfaceSoft : context.appSurface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(15, 13, 14, 13),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected ? context.appBrand : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                consultation.patientName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: context.appTextPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              consultation.patientMeta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 8.5,
                                color: context.appTextDisabled,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          consultation.subject,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                            color: context.appTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ConsultationStatusBadge(status: consultation.status),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Icon(
                    consultation.direction == ConsultationUiDirection.received
                        ? Icons.call_received_rounded
                        : Icons.call_made_rounded,
                    size: 12,
                    color: context.appTextSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    consultation.direction.shortLabel,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      color: context.appTextSecondary,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Container(
                    width: 2,
                    height: 2,
                    decoration: BoxDecoration(
                      color: context.appTextDisabled,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      requester == null
                          ? consultation.assignedDoctorName
                          : '${requester.doctorName} → ${consultation.assignedDoctorName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8.5,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatShortDate(consultation.createdAt),
                    style: TextStyle(
                      fontSize: 8,
                      color: context.appTextDisabled,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 9. Status Segment
// ============================================================

class _StatusSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? context.appBrand : context.appBackground,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: selected ? context.appBrand : context.appBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 8.8,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : context.appTextSecondary,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 10. Status Badge
// ============================================================

class _ConsultationStatusBadge extends StatelessWidget {
  final ConsultationUiStatus status;

  const _ConsultationStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      ConsultationUiStatus.requested => '요청',
      ConsultationUiStatus.inProgress => '진행',
      ConsultationUiStatus.completed => '완료',
      ConsultationUiStatus.withdrawn => '회수',
    };

    final foreground = switch (status) {
      ConsultationUiStatus.requested => AppColors.warning,
      ConsultationUiStatus.inProgress => AppColors.primaryBlue,
      ConsultationUiStatus.completed => AppColors.success,
      ConsultationUiStatus.withdrawn => AppColors.danger,
    };

    final background = switch (status) {
      ConsultationUiStatus.requested => AppColors.warningBackground,
      ConsultationUiStatus.inProgress => context.appSurfaceSoft,
      ConsultationUiStatus.completed => AppColors.successBackground,
      ConsultationUiStatus.withdrawn => AppColors.dangerBackground,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}

// ============================================================
// STEP 11. Helpers
// ============================================================

String _formatShortDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '$month.$day';
}
