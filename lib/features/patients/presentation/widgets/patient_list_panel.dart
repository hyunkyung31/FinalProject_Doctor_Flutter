import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/theme/app_theme.dart';
import 'patient_detail_tabs.dart';

// ============================================================
// STEP 1. Patient List Scope
// 환자 목록 조회 범위
// ============================================================

enum PatientListScope { all, assigned, consultation, recent }

class PatientListPanel extends StatefulWidget {
  final List<PatientUiModel> patients;
  final String selectedPatientId;
  final ValueChanged<PatientUiModel> onPatientSelected;

  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onDetailFilterTap;

  final PatientListScope selectedScope;
  final ValueChanged<PatientListScope>? onScopeChanged;

  // ============================================================
  // Pagination
  // ============================================================

  final int totalCount;
  final int currentPage;
  final int pageSize;

  final bool hasPreviousPage;
  final bool hasNextPage;

  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;

  const PatientListPanel({
    super.key,
    required this.patients,
    required this.selectedPatientId,
    required this.onPatientSelected,
    this.onSearchChanged,
    this.selectedScope = PatientListScope.all,
    this.onScopeChanged,
    this.totalCount = 0,
    this.currentPage = 1,
    this.pageSize = 20,
    this.hasPreviousPage = false,
    this.hasNextPage = false,
    this.onPreviousPage,
    this.onNextPage,
    this.onDetailFilterTap,
  });

  @override
  State<PatientListPanel> createState() => _PatientListPanelState();
}

class _PatientListPanelState extends State<PatientListPanel> {
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';

  // ============================================================
  // STEP. Scope별 환자 수 표시
  // ============================================================

  String _getCountLabel() {
    switch (widget.selectedScope) {
      case PatientListScope.all:
        return '전체 ${widget.totalCount}명';

      case PatientListScope.assigned:
        return '담당 ${widget.totalCount}명';

      case PatientListScope.consultation:
        return '협진 ${widget.totalCount}명';

      case PatientListScope.recent:
        return '최근 ${widget.totalCount}명';
    }
  }

  // ============================================================
  // STEP 2. Dispose
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // STEP 3. 전체 페이지 수
  // ============================================================

  int get _totalPages {
    if (widget.totalCount <= 0) {
      return 1;
    }

    return (widget.totalCount / widget.pageSize).ceil();
  }

  // ============================================================
  // STEP 4. 화면
  // ============================================================

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
          // ======================================================
          // Header
          // ======================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '환자 목록',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.appTextPrimary,
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.totalCount > 0
                        ? _getCountLabel()
                        : '${widget.patients.length}명',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: context.appTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ============================================================
          // STEP. 검색 + 상세 필터
          // 검색과 필터를 같은 기능 영역으로 배치
          // ============================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                // ========================================================
                // 환자 검색
                // ========================================================
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchText = value;
                        });

                        widget.onSearchChanged?.call(value);
                      },
                      style: TextStyle(
                        fontSize: 12,
                        color: context.appTextPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: '환자명 · 환자번호 검색',
                        hintStyle: TextStyle(
                          fontSize: 11,
                          color: context.appTextDisabled,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: context.appTextSecondary,
                        ),
                        suffixIcon: _searchText.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();

                                  setState(() {
                                    _searchText = '';
                                  });

                                  widget.onSearchChanged?.call('');
                                },
                                icon: const Icon(Icons.close_rounded, size: 16),
                              ),
                        filled: true,
                        fillColor: context.appBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: BorderSide(color: context.appBorder),
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
              ],
            ),
          ),

          // ======================================================
          // Patient Scope
          // 환자 조회 / 협진 / 최근 조회
          // ======================================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: _ScopeButton(
                    label: '환자 조회',
                    selected: widget.selectedScope == PatientListScope.all,
                    onTap: () {
                      widget.onScopeChanged?.call(PatientListScope.all);
                    },
                  ),
                ),

                const SizedBox(width: 5),

                Expanded(
                  child: _ScopeButton(
                    label: '협진',
                    selected:
                        widget.selectedScope == PatientListScope.consultation,
                    onTap: () {
                      widget.onScopeChanged?.call(
                        PatientListScope.consultation,
                      );
                    },
                  ),
                ),

                const SizedBox(width: 5),

                Expanded(
                  child: _ScopeButton(
                    label: '최근 조회',
                    selected: widget.selectedScope == PatientListScope.recent,
                    onTap: () {
                      widget.onScopeChanged?.call(PatientListScope.recent);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Divider(height: 1, color: context.appBorder),

          // ======================================================
          // Patient List
          // ======================================================
          Expanded(
            child: widget.patients.isEmpty
                ? const _EmptyPatientList()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    itemCount: widget.patients.length,
                    separatorBuilder: (context, index) {
                      return Divider(
                        height: 1,
                        indent: 12,
                        endIndent: 12,
                        color: context.appBorder,
                      );
                    },
                    itemBuilder: (context, index) {
                      final patient = widget.patients[index];

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

          Divider(height: 1, color: context.appBorder),

          // ======================================================
          // Pagination
          // ======================================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: _PaginationButton(
                    icon: Icons.chevron_left_rounded,
                    label: '이전',
                    enabled: widget.hasPreviousPage,
                    onTap: widget.onPreviousPage,
                  ),
                ),

                const SizedBox(width: 10),

                Container(
                  constraints: const BoxConstraints(minWidth: 70),
                  alignment: Alignment.center,
                  child: Text(
                    '${widget.currentPage} / $_totalPages',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: context.appTextPrimary,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _PaginationButton(
                    icon: Icons.chevron_right_rounded,
                    label: '다음',
                    enabled: widget.hasNextPage,
                    onTap: widget.onNextPage,
                    iconOnRight: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Patient Scope Button
// ============================================================

class _ScopeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ScopeButton({
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
            color: selected ? AppColors.navy : context.appSurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
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
// STEP 5. Patient List Item
// 실제 환자 기본정보만 표시
// 이름 / 나이 / 성별 / 환자번호 / 생년월일 / 연락처
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

  // ==========================================================
  // 생년월일 표시 형식
  // 1978-05-20 → 1978.05.20
  // ==========================================================

  String _formatBirthDate(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      return '생년월일 없음';
    }

    return normalized.replaceAll('-', '.');
  }

  // ==========================================================
  // 연락처 표시 형식
  // +821012345678 → 010-1234-5678
  // 01073000100   → 010-7300-0100
  // ==========================================================

  String _formatPhone(String value) {
    var normalized = value.trim().replaceAll(' ', '').replaceAll('-', '');

    if (normalized.isEmpty) {
      return '연락처 없음';
    }

    // +82 국가번호를 국내 형식으로 변경
    if (normalized.startsWith('+82')) {
      normalized = '0${normalized.substring(3)}';
    } else if (normalized.startsWith('82') && !normalized.startsWith('820')) {
      normalized = '0${normalized.substring(2)}';
    }

    // 휴대전화 010-0000-0000
    if (normalized.length == 11 && normalized.startsWith('010')) {
      return '${normalized.substring(0, 3)}-'
          '${normalized.substring(3, 7)}-'
          '${normalized.substring(7, 11)}';
    }

    return value.trim();
  }

  @override
  Widget build(BuildContext context) {
    final birthDate = _formatBirthDate(patient.birthDate);
    final phone = _formatPhone(patient.phone);

    final showStatus =
        patient.status.isNotEmpty && patient.status.toUpperCase() != 'ACTIVE';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),

          // ========================================================
          // 선택 환자 강조
          // 다크모드에서는 한 단계 밝은 청회색 배경 사용
          // ========================================================
          decoration: BoxDecoration(
            color: selected
                ? context.isDarkMode
                      ? const Color(0xFF354A5B)
                      : const Color(0xFFEAF2F8)
                : Colors.transparent,

            borderRadius: BorderRadius.circular(9),

            border: selected
                ? Border.all(color: context.appPrimary.withValues(alpha: 0.45))
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ==================================================
              // 선택 표시
              // 선택된 환자만 왼쪽 파란 라인 표시
              // ==================================================
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: selected ? 4 : 3,
                height: 72,
                decoration: BoxDecoration(
                  color: selected ? context.appPrimary : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(9),
                    bottomLeft: Radius.circular(9),
                  ),
                ),
              ),

              // ==================================================
              // Patient Information
              // ==================================================
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ============================================
                      // 이름 / 나이 / 성별
                      // ============================================
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              patient.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                color: context.appTextPrimary,
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          Text(
                            '${patient.age}세 · ${patient.gender}',
                            style: TextStyle(
                              fontSize: 10.3,
                              fontWeight: FontWeight.w500,
                              color: context.appTextSecondary,
                            ),
                          ),

                          if (showStatus) ...[
                            const SizedBox(width: 7),

                            _PatientStatusBadge(status: patient.status),
                          ],
                        ],
                      ),

                      const SizedBox(height: 5),

                      // ============================================
                      // 환자번호
                      // ============================================
                      Text(
                        patient.id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: context.appTextSecondary,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // ============================================
                      // 생년월일 / 연락처
                      // ============================================
                      Row(
                        children: [
                          Icon(
                            Icons.cake_outlined,
                            size: 11,
                            color: context.appTextDisabled,
                          ),

                          const SizedBox(width: 4),

                          Text(
                            birthDate,
                            style: TextStyle(
                              fontSize: 10,
                              color: context.appTextSecondary,
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '·',
                              style: TextStyle(
                                fontSize: 10,
                                color: context.appTextDisabled,
                              ),
                            ),
                          ),

                          Icon(
                            Icons.phone_outlined,
                            size: 11,
                            color: context.appTextDisabled,
                          ),

                          const SizedBox(width: 4),

                          Expanded(
                            child: Text(
                              phone,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: context.appTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
// STEP 6. Patient Status Badge
// ACTIVE는 숨기고 예외 상태만 표시
// ============================================================

class _PatientStatusBadge extends StatelessWidget {
  final String status;

  const _PatientStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.toUpperCase();

    String label;
    Color color;

    switch (normalizedStatus) {
      case 'INACTIVE':
        label = '비활성';
        color = context.appTextSecondary;
        break;

      case 'SUSPENDED':
        label = '이용 제한';
        color = AppColors.danger;
        break;

      default:
        label = status;
        color = context.appTextSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ============================================================
// STEP 7. Pagination Button
// ============================================================

class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onTap;
  final bool iconOnRight;

  const _PaginationButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.iconOnRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final foregroundColor = enabled
        ? context.appTextPrimary
        : context.appTextDisabled;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? context.appSurface : context.appBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.appBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!iconOnRight) ...[
                Icon(icon, size: 16, color: foregroundColor),

                const SizedBox(width: 3),
              ],

              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: foregroundColor,
                ),
              ),

              if (iconOnRight) ...[
                const SizedBox(width: 3),

                Icon(icon, size: 16, color: foregroundColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 8. Empty Patient List
// ============================================================

class _EmptyPatientList extends StatelessWidget {
  const _EmptyPatientList();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 34,
            color: context.appTextDisabled,
          ),

          SizedBox(height: 10),

          Text(
            '검색 결과가 없습니다.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.appTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
