import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/theme/app_theme.dart';
import '../consultation_ui_models.dart';

// ============================================================
// STEP 1. Consultation Rail
//
// 가로 태블릿에서는 얇은 Case Rail 역할을 합니다.
// 세로/좁은 화면에서는 전체 폭 목록으로 그대로 사용합니다.
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
  ConsultationUiDirection? _directionFilter;

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
          item.subject.toLowerCase().contains(query) ||
          item.assignedDoctorName.toLowerCase().contains(query) ||
          requester.toLowerCase().contains(query);

      final matchesStatus =
          _statusFilter == null || item.status == _statusFilter;
      final matchesDirection =
          _directionFilter == null || item.direction == _directionFilter;

      return matchesQuery && matchesStatus && matchesDirection;
    }).toList();
  }

  int get _activeCount {
    return widget.consultations
        .where(
          (item) =>
              item.status != ConsultationUiStatus.completed &&
              item.status != ConsultationUiStatus.withdrawn,
        )
        .length;
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildHeader(),
          _buildSearch(),
          const SizedBox(height: 9),
          _buildFilters(),
          const SizedBox(height: 10),
          Divider(height: 1, color: context.appBorder),
          Expanded(
            child: items.isEmpty
                ? _buildEmpty()
                : ListView.separated(
                    padding: const EdgeInsets.all(9),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 7),
                    itemBuilder: (context, index) {
                      final consultation = items[index];

                      return _CaseRailItem(
                        consultation: consultation,
                        selected: consultation.id == widget.selectedId,
                        onTap: () => widget.onSelected(consultation),
                      );
                    },
                  ),
          ),
          _buildCreateButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 9),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: context.appSurfaceSoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              Icons.groups_2_outlined,
              size: 18,
              color: context.appBrand,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '협진',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: context.appTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '진행 중 $_activeCount건',
                  style: TextStyle(
                    fontSize: 8.8,
                    color: context.appTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          _SmallCountBadge(count: widget.consultations.length),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: 37,
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchText = value;
            });
          },
          style: TextStyle(fontSize: 10, color: context.appTextPrimary),
          decoration: InputDecoration(
            hintText: '환자 · 제목 · 의료진',
            hintStyle: TextStyle(fontSize: 9.5, color: context.appTextDisabled),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 16,
              color: context.appTextSecondary,
            ),
            filled: true,
            fillColor: context.appBackground,
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide(color: context.appBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.primaryBlue),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SegmentButton(
                  label: '전체',
                  selected: _directionFilter == null,
                  onTap: () => setState(() => _directionFilter = null),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _SegmentButton(
                  label: '받은',
                  selected:
                      _directionFilter == ConsultationUiDirection.received,
                  onTap: () => setState(
                    () => _directionFilter = ConsultationUiDirection.received,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _SegmentButton(
                  label: '보낸',
                  selected: _directionFilter == ConsultationUiDirection.sent,
                  onTap: () => setState(
                    () => _directionFilter = ConsultationUiDirection.sent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 28,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _StatusChip(
                  label: '전체 상태',
                  selected: _statusFilter == null,
                  onTap: () => setState(() => _statusFilter = null),
                ),
                const SizedBox(width: 5),
                _StatusChip(
                  label: '요청',
                  selected: _statusFilter == ConsultationUiStatus.requested,
                  onTap: () => setState(
                    () => _statusFilter = ConsultationUiStatus.requested,
                  ),
                ),
                const SizedBox(width: 5),
                _StatusChip(
                  label: '진행',
                  selected: _statusFilter == ConsultationUiStatus.inProgress,
                  onTap: () => setState(
                    () => _statusFilter = ConsultationUiStatus.inProgress,
                  ),
                ),
                const SizedBox(width: 5),
                _StatusChip(
                  label: '완료',
                  selected: _statusFilter == ConsultationUiStatus.completed,
                  onTap: () => setState(
                    () => _statusFilter = ConsultationUiStatus.completed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 25,
              color: context.appTextDisabled,
            ),
            const SizedBox(height: 8),
            Text(
              '조건에 맞는 협진이 없습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9.5, color: context.appTextSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.appBorder)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: widget.onCreate,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy,
            minimumSize: const Size(0, 42),
          ),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('협진 요청'),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 4. Case Item
// ============================================================

class _CaseRailItem extends StatelessWidget {
  final ConsultationUiModel consultation;
  final bool selected;
  final VoidCallback onTap;

  const _CaseRailItem({
    required this.consultation,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final requester = consultation.requester;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? context.appSurfaceSoft : context.appSurface,
            borderRadius: BorderRadius.circular(12),
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
                      consultation.patientName,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: context.appTextPrimary,
                      ),
                    ),
                  ),
                  _CaseStatusBadge(status: consultation.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                consultation.subject,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.8,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${requester?.department ?? '-'} → ${consultation.assignedDepartment}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 8.5,
                  color: context.appTextSecondary,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Icon(
                    consultation.direction == ConsultationUiDirection.received
                        ? Icons.call_received_rounded
                        : Icons.call_made_rounded,
                    size: 11,
                    color: context.appTextDisabled,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    consultation.direction.shortLabel,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: context.appTextSecondary,
                    ),
                  ),
                  const Spacer(),
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
// STEP 5. Small Components
// ============================================================

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : context.appBackground,
          borderRadius: BorderRadius.circular(8),
          border: selected ? null : Border.all(color: context.appBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 8.7,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : context.appTextSecondary,
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? context.appSurfaceSoft : context.appBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : context.appBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 8.2,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.primaryBlue : context.appTextSecondary,
          ),
        ),
      ),
    );
  }
}

class _SmallCountBadge extends StatelessWidget {
  final int count;

  const _SmallCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 28),
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.appSurfaceSoft,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: context.appBrand,
        ),
      ),
    );
  }
}

class _CaseStatusBadge extends StatelessWidget {
  final ConsultationUiStatus status;

  const _CaseStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final Color background;

    switch (status) {
      case ConsultationUiStatus.requested:
        color = AppColors.warning;
        background = AppColors.warningBackground;
        break;
      case ConsultationUiStatus.inProgress:
        color = AppColors.primaryBlue;
        background = context.appSurfaceSoft;
        break;
      case ConsultationUiStatus.completed:
        color = AppColors.success;
        background = AppColors.successBackground;
        break;
      case ConsultationUiStatus.withdrawn:
        color = AppColors.danger;
        background = AppColors.dangerBackground;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 7.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

String _formatShortDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$month.$day';
}
