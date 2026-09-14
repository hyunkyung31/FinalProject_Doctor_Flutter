import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../examination_ui_models.dart';
import 'examination_detail_panel.dart';

// ============================================================
// STEP 1. 검사 종류 Filter
// ============================================================

enum _OrderCategoryFilter { all, lab, imaging, procedure }

// ============================================================
// STEP 2. Examination Order Panel
// ============================================================

class ExaminationOrderPanel extends StatefulWidget {
  final List<ExaminationOrderUiModel> orders;
  final List<ExaminationTypeUiModel> types;
  final List<ExaminationEncounterUiModel> encounters;
  final List<ExaminationPatientUiModel> patients;

  final bool canOrder;

  final VoidCallback onCreateOrder;

  final ValueChanged<ExaminationOrderUiModel> onSchedule;

  final ValueChanged<ExaminationOrderUiModel> onCancel;

  const ExaminationOrderPanel({
    super.key,
    required this.orders,
    required this.types,
    required this.encounters,
    required this.patients,
    required this.canOrder,
    required this.onCreateOrder,
    required this.onSchedule,
    required this.onCancel,
  });

  @override
  State<ExaminationOrderPanel> createState() => _ExaminationOrderPanelState();
}

class _ExaminationOrderPanelState extends State<ExaminationOrderPanel> {
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';

  _OrderCategoryFilter _filter = _OrderCategoryFilter.all;

  int? _selectedId;

  // ============================================================
  // STEP 3. Init
  // ============================================================

  @override
  void initState() {
    super.initState();

    if (widget.orders.isNotEmpty) {
      _selectedId = widget.orders.first.id;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // STEP 4. Resolve
  // ============================================================

  ExaminationTypeUiModel _typeFor(ExaminationOrderUiModel order) {
    return widget.types.firstWhere(
      (item) => item.id == order.examinationTypeId,
    );
  }

  ExaminationEncounterUiModel _encounterFor(ExaminationOrderUiModel order) {
    return widget.encounters.firstWhere((item) => item.id == order.encounterId);
  }

  ExaminationPatientUiModel _patientFor(ExaminationOrderUiModel order) {
    final encounter = _encounterFor(order);

    return widget.patients.firstWhere((item) => item.id == encounter.patientId);
  }

  // ============================================================
  // STEP 5. Filter
  // ============================================================

  List<ExaminationOrderUiModel> get _filteredOrders {
    return widget.orders.where((order) {
      final type = _typeFor(order);
      final patient = _patientFor(order);

      final query = _searchText.trim().toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          patient.name.toLowerCase().contains(query) ||
          type.name.toLowerCase().contains(query) ||
          order.id.toString().contains(query);

      if (!matchesSearch) {
        return false;
      }

      switch (_filter) {
        case _OrderCategoryFilter.all:
          return true;

        case _OrderCategoryFilter.lab:
          return type.category == 'LAB';

        case _OrderCategoryFilter.imaging:
          return type.category == 'IMAGING';

        case _OrderCategoryFilter.procedure:
          return type.category == 'PROCEDURE';
      }
    }).toList();
  }

  ExaminationOrderUiModel? get _selectedOrder {
    if (_selectedId == null) {
      return null;
    }

    for (final order in widget.orders) {
      if (order.id == _selectedId) {
        return order;
      }
    }

    return null;
  }

  // ============================================================
  // STEP 6. UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOrders;
    final selected = _selectedOrder;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 4, child: _buildListPanel(filtered)),

        const SizedBox(width: 14),

        Expanded(
          flex: 6,
          child: selected == null
              ? const _EmptyDetail()
              : ExaminationOrderDetailPanel(
                  order: selected,
                  type: _typeFor(selected),
                  encounter: _encounterFor(selected),
                  patient: _patientFor(selected),
                  canOrder: widget.canOrder,
                  onSchedule: () {
                    widget.onSchedule(selected);
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
  // STEP 7. List Panel
  // ============================================================

  Widget _buildListPanel(List<ExaminationOrderUiModel> orders) {
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
                    '검사 오더',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                if (widget.canOrder)
                  FilledButton.icon(
                    onPressed: widget.onCreateOrder,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      minimumSize: const Size(100, 36),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 15),
                    label: const Text(
                      '검사 오더',
                      style: TextStyle(fontSize: 10.5),
                    ),
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
                  hintText: '환자 · 검사명 · 오더번호 검색',
                  prefixIcon: const Icon(Icons.search_rounded, size: 17),
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

          const SizedBox(height: 9),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _FilterButton(
                  text: '전체',
                  selected: _filter == _OrderCategoryFilter.all,
                  onTap: () {
                    setState(() {
                      _filter = _OrderCategoryFilter.all;
                    });
                  },
                ),
                const SizedBox(width: 5),
                _FilterButton(
                  text: '혈액·임상',
                  selected: _filter == _OrderCategoryFilter.lab,
                  onTap: () {
                    setState(() {
                      _filter = _OrderCategoryFilter.lab;
                    });
                  },
                ),
                const SizedBox(width: 5),
                _FilterButton(
                  text: '영상',
                  selected: _filter == _OrderCategoryFilter.imaging,
                  onTap: () {
                    setState(() {
                      _filter = _OrderCategoryFilter.imaging;
                    });
                  },
                ),
                const SizedBox(width: 5),
                _FilterButton(
                  text: '시술',
                  selected: _filter == _OrderCategoryFilter.procedure,
                  onTap: () {
                    setState(() {
                      _filter = _OrderCategoryFilter.procedure;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          const Divider(height: 1, color: AppColors.border),

          Expanded(
            child: orders.isEmpty
                ? const Center(
                    child: Text(
                      '조건에 맞는 검사 오더가 없습니다.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: orders.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 7),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final type = _typeFor(order);
                      final patient = _patientFor(order);

                      return _OrderItem(
                        order: order,
                        type: type,
                        patient: patient,
                        selected: order.id == _selectedId,
                        onTap: () {
                          setState(() {
                            _selectedId = order.id;
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
// STEP 8. Order Item
// ============================================================

class _OrderItem extends StatelessWidget {
  final ExaminationOrderUiModel order;
  final ExaminationTypeUiModel type;
  final ExaminationPatientUiModel patient;

  final bool selected;
  final VoidCallback onTap;

  const _OrderItem({
    required this.order,
    required this.type,
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
                      patient.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  ExaminationStatusBadge(status: order.status),
                ],
              ),

              const SizedBox(height: 5),

              Text(
                type.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                '#${order.id} · ${formatExamDateTime(order.orderedAt)}',
                style: const TextStyle(
                  fontSize: 9.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 9. Filter Button
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
          '검사 오더를 선택해 주세요.',
          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
