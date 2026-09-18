import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/theme/app_theme.dart';
import '../consultation_ui_models.dart';

// ============================================================
// STEP 1. List Panel
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
  ConsultationUiStatus? _filter;

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

  List<ConsultationUiModel> get _filtered {
    final query = _searchText.trim().toLowerCase();

    return widget.consultations.where((item) {
      final matchesQuery =
          query.isEmpty ||
          item.patientName.toLowerCase().contains(query) ||
          item.subject.toLowerCase().contains(query) ||
          item.assignedDoctorName.toLowerCase().contains(query);

      final matchesStatus = _filter == null || item.status == _filter;

      return matchesQuery && matchesStatus;
    }).toList();
  }

  // ============================================================
  // STEP 4. UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final consultations = _filtered;

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
                    '협진 목록',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.appTextPrimary,
                    ),
                  ),
                ),

                FilledButton.icon(
                  onPressed: widget.onCreate,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    minimumSize: const Size(100, 36),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 15),
                  label: const Text('협진 요청', style: TextStyle(fontSize: 10.5)),
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
                  hintText: '환자 · 협진 제목 · 의료진 검색',
                  prefixIcon: const Icon(Icons.search_rounded, size: 17),
                  filled: true,
                  fillColor: context.appBackground,
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
          ),

          const SizedBox(height: 9),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _FilterButton(
                  text: '전체',
                  selected: _filter == null,
                  onTap: () {
                    setState(() {
                      _filter = null;
                    });
                  },
                ),
                const SizedBox(width: 5),
                _FilterButton(
                  text: '요청',
                  selected: _filter == ConsultationUiStatus.requested,
                  onTap: () {
                    setState(() {
                      _filter = ConsultationUiStatus.requested;
                    });
                  },
                ),
                const SizedBox(width: 5),
                _FilterButton(
                  text: '진행',
                  selected: _filter == ConsultationUiStatus.inProgress,
                  onTap: () {
                    setState(() {
                      _filter = ConsultationUiStatus.inProgress;
                    });
                  },
                ),
                const SizedBox(width: 5),
                _FilterButton(
                  text: '완료',
                  selected: _filter == ConsultationUiStatus.completed,
                  onTap: () {
                    setState(() {
                      _filter = ConsultationUiStatus.completed;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Divider(height: 1, color: context.appBorder),

          Expanded(
            child: consultations.isEmpty
                ? Center(
                    child: Text(
                      '조건에 맞는 협진이 없습니다.',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.appTextSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: consultations.length,
                    separatorBuilder: (_, _) {
                      return const SizedBox(height: 7);
                    },
                    itemBuilder: (context, index) {
                      final item = consultations[index];

                      return _ConsultationListItem(
                        consultation: item,
                        selected: item.id == widget.selectedId,
                        onTap: () {
                          widget.onSelected(item);
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
// STEP 5. Item
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
                    consultation.patientName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.appTextPrimary,
                    ),
                  ),
                ),

                if (consultation.isDemo) ...[
                  const _DemoBadge(),
                  const SizedBox(width: 5),
                ],

                _StatusBadge(status: consultation.status),
              ],
            ),

            const SizedBox(height: 6),

            Text(
              consultation.subject,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: context.appTextPrimary,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              '${consultation.assignedDepartment} · ${consultation.assignedDoctorName}',
              style: TextStyle(
                fontSize: 9.5,
                color: context.appTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STEP 6. Filter
// ============================================================

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

// ============================================================
// STEP 7. Badges
// ============================================================

class _StatusBadge extends StatelessWidget {
  final ConsultationUiStatus status;

  const _StatusBadge({required this.status});

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
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 8.5,
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
