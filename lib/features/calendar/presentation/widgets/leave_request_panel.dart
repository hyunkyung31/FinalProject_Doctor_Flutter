import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

// ============================================================
// STEP 1. 휴무 신청 내부 화면 구분
// 일반 의사 : 내 신청만 표시
// 과장 권한 : 내 신청 / 승인 요청 표시
// ============================================================

enum LeaveRequestView { myRequests, approvalRequests }

// ============================================================
// STEP 2. 휴무 신청 상태 Filter
// ============================================================

enum LeaveStatusFilter { all, pending, approved, rejected }

// ============================================================
// STEP 3. 디자인 확인용 Sample Model
// API 연결 후 실제 Model로 교체 예정
// ============================================================

class _LeaveRequestPreview {
  final String date;
  final String type;
  final String reason;
  final String requestedAt;
  final String status;

  const _LeaveRequestPreview({
    required this.date,
    required this.type,
    required this.reason,
    required this.requestedAt,
    required this.status,
  });
}

// ============================================================
// STEP 4. Leave Request Panel
// ============================================================

class LeaveRequestPanel extends StatefulWidget {
  final bool canApproveLeave;
  final VoidCallback onCreateRequest;

  const LeaveRequestPanel({
    super.key,
    required this.canApproveLeave,
    required this.onCreateRequest,
  });

  @override
  State<LeaveRequestPanel> createState() => _LeaveRequestPanelState();
}

class _LeaveRequestPanelState extends State<LeaveRequestPanel> {
  LeaveRequestView _selectedView = LeaveRequestView.myRequests;

  LeaveStatusFilter _selectedStatus = LeaveStatusFilter.all;

  // ============================================================
  // 디자인 확인용 Sample Data
  // API 연결 시 삭제
  // ============================================================

  static const List<_LeaveRequestPreview> _previewRequests = [
    _LeaveRequestPreview(
      date: '2026.09.18',
      type: '연차',
      reason: '개인 사유',
      requestedAt: '2026.09.11',
      status: 'PENDING',
    ),
    _LeaveRequestPreview(
      date: '2026.09.24',
      type: '오후 반차',
      reason: '병원 방문',
      requestedAt: '2026.09.10',
      status: 'APPROVED',
    ),
    _LeaveRequestPreview(
      date: '2026.09.30',
      type: '오전 반차',
      reason: '개인 일정',
      requestedAt: '2026.09.08',
      status: 'REJECTED',
    ),
  ];

  // ============================================================
  // Filtered Data
  // ============================================================

  List<_LeaveRequestPreview> get _filteredRequests {
    switch (_selectedStatus) {
      case LeaveStatusFilter.all:
        return _previewRequests;

      case LeaveStatusFilter.pending:
        return _previewRequests
            .where((item) => item.status == 'PENDING')
            .toList();

      case LeaveStatusFilter.approved:
        return _previewRequests
            .where((item) => item.status == 'APPROVED')
            .toList();

      case LeaveStatusFilter.rejected:
        return _previewRequests
            .where((item) => item.status == 'REJECTED')
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ========================================================
        // 과장 권한 : 내 신청 / 승인 요청
        // ========================================================
        if (widget.canApproveLeave) ...[
          _buildViewTabs(),
          const SizedBox(height: 14),
        ],

        // ========================================================
        // Content
        // ========================================================
        Expanded(
          child: _selectedView == LeaveRequestView.myRequests
              ? _buildMyRequestSection()
              : _buildApprovalSection(),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 6. 과장 권한 View Tab
  // ============================================================

  Widget _buildViewTabs() {
    return Row(
      children: [
        _ViewTabButton(
          label: '내 신청',
          isSelected: _selectedView == LeaveRequestView.myRequests,
          onTap: () {
            setState(() {
              _selectedView = LeaveRequestView.myRequests;
            });
          },
        ),

        const SizedBox(width: 8),

        _ViewTabButton(
          label: '승인 요청',
          count: 3,
          isSelected: _selectedView == LeaveRequestView.approvalRequests,
          onTap: () {
            setState(() {
              _selectedView = LeaveRequestView.approvalRequests;
            });
          },
        ),
      ],
    );
  }

  // ============================================================
  // STEP 7. 내 신청 Section
  // 상태 Filter + 휴무 신청 버튼
  // ============================================================

  Widget _buildMyRequestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ========================================================
        // Toolbar
        // 왼쪽 : 상태 Filter
        // 오른쪽 : 휴무 신청
        // ========================================================
        Row(
          children: [
            // ====================================================
            // 전체
            // ====================================================
            _StatusFilterButton(
              label: '전체',
              count: _previewRequests.length,
              isSelected: _selectedStatus == LeaveStatusFilter.all,
              onTap: () {
                _changeStatus(LeaveStatusFilter.all);
              },
            ),

            const SizedBox(width: 8),

            // ====================================================
            // 승인 대기
            // ====================================================
            _StatusFilterButton(
              label: '승인 대기',
              count: _countStatus('PENDING'),
              isSelected: _selectedStatus == LeaveStatusFilter.pending,
              onTap: () {
                _changeStatus(LeaveStatusFilter.pending);
              },
            ),

            const SizedBox(width: 8),

            // ====================================================
            // 승인
            // ====================================================
            _StatusFilterButton(
              label: '승인',
              count: _countStatus('APPROVED'),
              isSelected: _selectedStatus == LeaveStatusFilter.approved,
              onTap: () {
                _changeStatus(LeaveStatusFilter.approved);
              },
            ),

            const SizedBox(width: 8),

            // ====================================================
            // 반려
            // ====================================================
            _StatusFilterButton(
              label: '반려',
              count: _countStatus('REJECTED'),
              isSelected: _selectedStatus == LeaveStatusFilter.rejected,
              onTap: () {
                _changeStatus(LeaveStatusFilter.rejected);
              },
            ),

            // ====================================================
            // 왼쪽 Filter / 오른쪽 버튼 분리
            // ====================================================
            const Spacer(),

            // ====================================================
            // 휴무 신청
            // ====================================================
            SizedBox(
              height: 34,
              child: TextButton.icon(
                onPressed: widget.onCreateRequest,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  backgroundColor: AppColors.surfaceSoft,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: AppColors.primaryBlue.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 17),
                label: const Text(
                  '휴무 신청',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),

        // ========================================================
        // Toolbar ↔ Table
        // ========================================================
        const SizedBox(height: 8),

        // ========================================================
        // 신청 목록
        // ========================================================
        _buildRequestListCard(),
      ],
    );
  }

  // ============================================================
  // STEP 8. 신청 List Card
  // 데이터 개수만큼 자연스럽게 높이 사용
  // 수동 tableHeight 계산 제거
  // ============================================================

  Widget _buildRequestListCard() {
    final requests = _filteredRequests;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),

      // 둥근 모서리 안쪽으로 내용 정리
      clipBehavior: Clip.antiAlias,

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ======================================================
          // Table Header
          // ======================================================
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            color: AppColors.surfaceSoft,
            child: const Row(
              children: [
                Expanded(flex: 18, child: Text('휴무일', style: _headerStyle)),

                Expanded(flex: 15, child: Text('구분', style: _headerStyle)),

                Expanded(flex: 32, child: Text('신청 사유', style: _headerStyle)),

                Expanded(flex: 20, child: Text('신청일', style: _headerStyle)),

                Expanded(
                  flex: 15,
                  child: Text(
                    '상태',
                    textAlign: TextAlign.center,
                    style: _headerStyle,
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // Empty State
          // ======================================================
          if (requests.isEmpty)
            const SizedBox(height: 180, child: _LeaveEmptyState()),

          // ======================================================
          // Request Rows
          // ListView 사용하지 않고 데이터 개수만큼 직접 표시
          // ======================================================
          if (requests.isNotEmpty)
            for (int index = 0; index < requests.length; index++) ...[
              _LeaveRequestRow(request: requests[index]),

              if (index != requests.length - 1)
                const Divider(height: 1, thickness: 1, color: AppColors.border),
            ],
        ],
      ),
    );
  }

  // ============================================================
  // STEP 9. 승인 요청 Section
  // 과장 권한 UI
  // API 연결 전 Preview
  // ============================================================

  Widget _buildApprovalSection() {
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fact_check_outlined,
                size: 36,
                color: AppColors.secondaryBlue,
              ),

              SizedBox(height: 10),

              Text(
                '휴무 승인 요청',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              SizedBox(height: 5),

              Text(
                '같은 진료과 의료진의 승인 대기 요청이 표시됩니다.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP 10. Helpers
  // ============================================================

  void _changeStatus(LeaveStatusFilter status) {
    if (_selectedStatus == status) {
      return;
    }

    setState(() {
      _selectedStatus = status;
    });
  }

  int _countStatus(String status) {
    return _previewRequests.where((item) => item.status == status).length;
  }
}

// ============================================================
// STEP 11. Header Text Style
// ============================================================

const TextStyle _headerStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: AppColors.textSecondary,
);

// ============================================================
// STEP 12. View Tab Button
// ============================================================

class _ViewTabButton extends StatelessWidget {
  final String label;
  final int? count;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryBlue.withValues(alpha: 0.22)
                  : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.navy : AppColors.textSecondary,
                ),
              ),

              if (count != null) ...[
                const SizedBox(width: 7),

                Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warningBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 13. Status Filter Button
// ============================================================

class _StatusFilterButton extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusFilterButton({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.navy : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.navy : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),

              const SizedBox(width: 6),

              Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.8)
                      : AppColors.textDisabled,
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
// STEP 14. Leave Request Row
// ============================================================

class _LeaveRequestRow extends StatelessWidget {
  final _LeaveRequestPreview request;

  const _LeaveRequestRow({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 18,
            child: Text(
              request.date,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          Expanded(
            flex: 15,
            child: Text(
              request.type,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          Expanded(
            flex: 32,
            child: Text(
              request.reason,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          Expanded(
            flex: 20,
            child: Text(
              request.requestedAt,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          Expanded(
            flex: 15,
            child: Align(
              alignment: Alignment.center,
              child: _LeaveStatusBadge(status: request.status),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 15. Status Badge
// ============================================================

class _LeaveStatusBadge extends StatelessWidget {
  final String status;

  const _LeaveStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: _foreground,
        ),
      ),
    );
  }

  String get _label {
    switch (status) {
      case 'PENDING':
        return '승인 대기';

      case 'APPROVED':
        return '승인';

      case 'REJECTED':
        return '반려';

      default:
        return status;
    }
  }

  Color get _foreground {
    switch (status) {
      case 'PENDING':
        return AppColors.warning;

      case 'APPROVED':
        return AppColors.success;

      case 'REJECTED':
        return AppColors.danger;

      default:
        return AppColors.textSecondary;
    }
  }

  Color get _background {
    switch (status) {
      case 'PENDING':
        return AppColors.warningBackground;

      case 'APPROVED':
        return AppColors.successBackground;

      case 'REJECTED':
        return AppColors.dangerBackground;

      default:
        return AppColors.surfaceSoft;
    }
  }
}

// ============================================================
// STEP 16. Empty State
// ============================================================

class _LeaveEmptyState extends StatelessWidget {
  const _LeaveEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 32,
            color: AppColors.secondaryBlue,
          ),

          SizedBox(height: 8),

          Text(
            '해당하는 휴무 신청이 없습니다.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
