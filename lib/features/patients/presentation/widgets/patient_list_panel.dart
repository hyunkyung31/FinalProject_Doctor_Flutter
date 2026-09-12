import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'patient_detail_tabs.dart';

// ============================================================
// STEP 1. 환자 Filter
// ============================================================

enum _PatientFilter { all, outpatient, inpatient, highRisk }

// ============================================================
// STEP 2. Patient List Panel
// ============================================================

class PatientListPanel extends StatefulWidget {
  final List<PatientUiModel> patients;
  final String selectedPatientId;
  final ValueChanged<PatientUiModel> onPatientSelected;

  const PatientListPanel({
    super.key,
    required this.patients,
    required this.selectedPatientId,
    required this.onPatientSelected,
  });

  @override
  State<PatientListPanel> createState() => _PatientListPanelState();
}

class _PatientListPanelState extends State<PatientListPanel> {
  final TextEditingController _searchController = TextEditingController();

  _PatientFilter _selectedFilter = _PatientFilter.all;

  String _searchText = '';

  // ============================================================
  // STEP 3. Dispose
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // STEP 4. Filtered Patients
  // ============================================================

  List<PatientUiModel> get _filteredPatients {
    final query = _searchText.trim().toLowerCase();

    return widget.patients.where((patient) {
      // ========================================================
      // 검색
      // ========================================================

      final matchesSearch =
          query.isEmpty ||
          patient.name.toLowerCase().contains(query) ||
          patient.id.toLowerCase().contains(query);

      if (!matchesSearch) {
        return false;
      }

      // ========================================================
      // Filter
      // ========================================================

      switch (_selectedFilter) {
        case _PatientFilter.all:
          return true;

        case _PatientFilter.outpatient:
          return patient.careType == '외래';

        case _PatientFilter.inpatient:
          return patient.careType == '입원';

        case _PatientFilter.highRisk:
          return patient.highRisk;
      }
    }).toList();
  }

  // ============================================================
  // STEP 5. 화면
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final filteredPatients = _filteredPatients;

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
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '환자 리스트',
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
                    '${filteredPatients.length}명',
                    style: const TextStyle(
                      fontSize: 10,
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
              height: 40,
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '환자명 · 환자번호 검색',
                  hintStyle: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textDisabled,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: _searchText.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();

                            setState(() {
                              _searchText = '';
                            });
                          },
                          icon: const Icon(Icons.close_rounded, size: 16),
                        ),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: const BorderSide(
                      color: AppColors.primaryBlue,
                      width: 1.3,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ======================================================
          // Filter
          // ======================================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: _FilterButton(
                    label: '전체',
                    selected: _selectedFilter == _PatientFilter.all,
                    onTap: () {
                      _changeFilter(_PatientFilter.all);
                    },
                  ),
                ),

                const SizedBox(width: 5),

                Expanded(
                  child: _FilterButton(
                    label: '외래',
                    selected: _selectedFilter == _PatientFilter.outpatient,
                    onTap: () {
                      _changeFilter(_PatientFilter.outpatient);
                    },
                  ),
                ),

                const SizedBox(width: 5),

                Expanded(
                  child: _FilterButton(
                    label: '입원',
                    selected: _selectedFilter == _PatientFilter.inpatient,
                    onTap: () {
                      _changeFilter(_PatientFilter.inpatient);
                    },
                  ),
                ),

                const SizedBox(width: 5),

                Expanded(
                  child: _FilterButton(
                    label: '고위험',
                    selected: _selectedFilter == _PatientFilter.highRisk,
                    onTap: () {
                      _changeFilter(_PatientFilter.highRisk);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          const Divider(height: 1, color: AppColors.border),

          // ======================================================
          // Patient List
          // ======================================================
          Expanded(
            child: filteredPatients.isEmpty
                ? const _EmptyPatientList()
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredPatients.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 8);
                    },
                    itemBuilder: (context, index) {
                      final patient = filteredPatients[index];

                      return _PatientListItem(
                        patient: patient,
                        selected: widget.selectedPatientId == patient.id,
                        onTap: () {
                          widget.onPatientSelected(patient);
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
  // STEP 6. Filter 변경
  // ============================================================

  void _changeFilter(_PatientFilter filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }
}

// ============================================================
// STEP 7. Filter Button
// ============================================================

class _FilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 31,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 8. Patient List Item
// ============================================================

class _PatientListItem extends StatelessWidget {
  final PatientUiModel patient;
  final bool selected;
  final VoidCallback onTap;

  const _PatientListItem({
    required this.patient,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
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
              // ==================================================
              // 이름 / 상태
              // ==================================================
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: patient.highRisk
                          ? AppColors.danger
                          : AppColors.success,
                    ),
                  ),

                  const SizedBox(width: 7),

                  Expanded(
                    child: Text(
                      '${patient.name} · ${patient.age}세',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  _SmallBadge(
                    text: patient.careType,
                    color: AppColors.primaryBlue,
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                '${patient.id} · ${patient.gender}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 7),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      patient.currentTask,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  if (patient.aiPending) ...[
                    const SizedBox(width: 6),

                    _SmallBadge(text: 'AI 검토', color: AppColors.warning),
                  ],

                  if (patient.highRisk) ...[
                    const SizedBox(width: 6),

                    _SmallBadge(text: '고위험', color: AppColors.danger),
                  ],
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
// STEP 9. Small Badge
// ============================================================

class _SmallBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _SmallBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ============================================================
// STEP 10. Empty
// ============================================================

class _EmptyPatientList extends StatelessWidget {
  const _EmptyPatientList();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 34,
            color: AppColors.textDisabled,
          ),

          SizedBox(height: 10),

          Text(
            '검색 결과가 없습니다.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
