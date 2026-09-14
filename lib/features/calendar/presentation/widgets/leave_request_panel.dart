import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

// ============================================================
// STEP 1. 휴무 신청 내부 화면 구분
//
// 일반 의사 : 내 신청만 표시
// 승인 권한 : 내 신청 / 승인 요청 표시
// ============================================================

enum LeaveRequestView { myRequests, approvalRequests }

// ============================================================
// STEP 2. 휴무 신청 상태 Filter
// ============================================================

enum LeaveStatusFilter { all, pending, approved, rejected }

// ============================================================
// STEP 3. 내 휴무 신청 Preview Model
//
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
// STEP 4. 승인 요청 Preview Model
//
// 현재 휴무 승인 API Schema 미확인.
// 따라서 승인 목록은 UI DEMO 전용 Model 사용.
//
// Backend 연결 시:
// - requester
// - department
// - leaveDate
// - leaveType
// - reason
// - requestedAt
// - status
//
// 등의 실제 필드에 맞춰 교체.
// ============================================================

class _LeaveApprovalPreview {
  final int id;

  final String requesterName;
  final String department;

  final String date;
  final String type;
  final String reason;
  final String requestedAt;

  final String status;

  const _LeaveApprovalPreview({
    required this.id,
    required this.requesterName,
    required this.department,
    required this.date,
    required this.type,
    required this.reason,
    required this.requestedAt,
    required this.status,
  });

  _LeaveApprovalPreview copyWith({String? status}) {
    return _LeaveApprovalPreview(
      id: id,
      requesterName: requesterName,
      department: department,
      date: date,
      type: type,
      reason: reason,
      requestedAt: requestedAt,
      status: status ?? this.status,
    );
  }
}

// ============================================================
// STEP 5. Leave Request Panel
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

  LeaveStatusFilter _myRequestStatus = LeaveStatusFilter.all;

  LeaveStatusFilter _approvalStatus = LeaveStatusFilter.all;

  // ============================================================
  // STEP 6. 내 신청 Sample Data
  //
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
  // STEP 7. 승인 요청 Sample Data
  //
  // 같은 진료과 의료진의 휴무 요청을 가정한 UI DEMO.
  //
  // 실제 구현에서는 Backend가 승인 권한과 진료과 범위를
  // 판단하여 현재 사용자가 처리할 수 있는 요청만 반환해야 함.
  // ============================================================

  final List<_LeaveApprovalPreview> _approvalRequests = [
    const _LeaveApprovalPreview(
      id: 101,
      requesterName: '박OO 의사',
      department: '순환기내과',
      date: '2026.09.19',
      type: '연차',
      reason: '가족 일정',
      requestedAt: '2026.09.13',
      status: 'PENDING',
    ),
    const _LeaveApprovalPreview(
      id: 102,
      requesterName: '최OO 의사',
      department: '순환기내과',
      date: '2026.09.21',
      type: '오전 반차',
      reason: '병원 방문',
      requestedAt: '2026.09.13',
      status: 'PENDING',
    ),
    const _LeaveApprovalPreview(
      id: 103,
      requesterName: '이OO 의사',
      department: '순환기내과',
      date: '2026.09.23',
      type: '오후 반차',
      reason: '개인 일정',
      requestedAt: '2026.09.12',
      status: 'PENDING',
    ),
    const _LeaveApprovalPreview(
      id: 104,
      requesterName: '정OO 의사',
      department: '순환기내과',
      date: '2026.09.16',
      type: '연차',
      reason: '교육 참석',
      requestedAt: '2026.09.09',
      status: 'APPROVED',
    ),
  ];

  // ============================================================
  // STEP 8. 권한 변경 대응
  //
  // Dev Role Switch 등으로 승인 권한이 사라졌는데
  // 승인 요청 탭에 머물러 있는 상황 방지.
  // ============================================================

  @override
  void didUpdateWidget(covariant LeaveRequestPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.canApproveLeave &&
        !widget.canApproveLeave &&
        _selectedView == LeaveRequestView.approvalRequests) {
      _selectedView = LeaveRequestView.myRequests;
    }
  }

  // ============================================================
  // STEP 9. 내 신청 Filtered Data
  // ============================================================

  List<_LeaveRequestPreview> get _filteredRequests {
    switch (_myRequestStatus) {
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

  // ============================================================
  // STEP 10. 승인 요청 Filtered Data
  // ============================================================

  List<_LeaveApprovalPreview> get _filteredApprovalRequests {
    switch (_approvalStatus) {
      case LeaveStatusFilter.all:
        return _approvalRequests;

      case LeaveStatusFilter.pending:
        return _approvalRequests
            .where((item) => item.status == 'PENDING')
            .toList();

      case LeaveStatusFilter.approved:
        return _approvalRequests
            .where((item) => item.status == 'APPROVED')
            .toList();

      case LeaveStatusFilter.rejected:
        return _approvalRequests
            .where((item) => item.status == 'REJECTED')
            .toList();
    }
  }

  // ============================================================
  // STEP 11. Main UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ========================================================
        // 승인 권한 보유자:
        // 내 신청 / 승인 요청
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
  // STEP 12. 승인 권한 View Tabs
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
          count: _countApprovalStatus('PENDING'),
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
  // STEP 13. 내 신청 Section
  // ============================================================

  Widget _buildMyRequestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ========================================================
        // Toolbar
        // ========================================================
        Row(
          children: [
            _StatusFilterButton(
              label: '전체',
              count: _previewRequests.length,
              isSelected: _myRequestStatus == LeaveStatusFilter.all,
              onTap: () {
                _changeMyRequestStatus(LeaveStatusFilter.all);
              },
            ),

            const SizedBox(width: 8),

            _StatusFilterButton(
              label: '승인 대기',
              count: _countMyStatus('PENDING'),
              isSelected: _myRequestStatus == LeaveStatusFilter.pending,
              onTap: () {
                _changeMyRequestStatus(LeaveStatusFilter.pending);
              },
            ),

            const SizedBox(width: 8),

            _StatusFilterButton(
              label: '승인',
              count: _countMyStatus('APPROVED'),
              isSelected: _myRequestStatus == LeaveStatusFilter.approved,
              onTap: () {
                _changeMyRequestStatus(LeaveStatusFilter.approved);
              },
            ),

            const SizedBox(width: 8),

            _StatusFilterButton(
              label: '반려',
              count: _countMyStatus('REJECTED'),
              isSelected: _myRequestStatus == LeaveStatusFilter.rejected,
              onTap: () {
                _changeMyRequestStatus(LeaveStatusFilter.rejected);
              },
            ),

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

        const SizedBox(height: 8),

        // ========================================================
        // 신청 목록
        // ========================================================
        _buildRequestListCard(),
      ],
    );
  }

  // ============================================================
  // STEP 14. 내 신청 List Card
  //
  // 기존 구조 유지:
  // - 수동 tableHeight 없음
  // - ListView 없음
  // - 데이터 행 개수만큼 자연스럽게 높이 사용
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

          if (requests.isEmpty)
            const SizedBox(height: 180, child: _LeaveEmptyState()),

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
  // STEP 15. 승인 요청 Section
  // ============================================================

  Widget _buildApprovalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ========================================================
        // Toolbar
        // ========================================================
        Row(
          children: [
            _StatusFilterButton(
              label: '전체',
              count: _approvalRequests.length,
              isSelected: _approvalStatus == LeaveStatusFilter.all,
              onTap: () {
                _changeApprovalStatus(LeaveStatusFilter.all);
              },
            ),

            const SizedBox(width: 8),

            _StatusFilterButton(
              label: '승인 대기',
              count: _countApprovalStatus('PENDING'),
              isSelected: _approvalStatus == LeaveStatusFilter.pending,
              onTap: () {
                _changeApprovalStatus(LeaveStatusFilter.pending);
              },
            ),

            const SizedBox(width: 8),

            _StatusFilterButton(
              label: '승인',
              count: _countApprovalStatus('APPROVED'),
              isSelected: _approvalStatus == LeaveStatusFilter.approved,
              onTap: () {
                _changeApprovalStatus(LeaveStatusFilter.approved);
              },
            ),

            const SizedBox(width: 8),

            _StatusFilterButton(
              label: '반려',
              count: _countApprovalStatus('REJECTED'),
              isSelected: _approvalStatus == LeaveStatusFilter.rejected,
              onTap: () {
                _changeApprovalStatus(LeaveStatusFilter.rejected);
              },
            ),

            const Spacer(),

            const Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),

                SizedBox(width: 5),

                Text(
                  '같은 진료과 의료진 요청',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 8),

        // ========================================================
        // 승인 요청 목록
        // ========================================================
        _buildApprovalListCard(),
      ],
    );
  }

  // ============================================================
  // STEP 16. 승인 요청 List Card
  //
  // 내 신청과 동일하게 content-sized 방식 유지.
  // ============================================================

  Widget _buildApprovalListCard() {
    final requests = _filteredApprovalRequests;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ======================================================
          // Table Header
          // ======================================================
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: AppColors.surfaceSoft,
            child: const Row(
              children: [
                Expanded(flex: 18, child: Text('신청자', style: _headerStyle)),

                Expanded(flex: 16, child: Text('휴무일', style: _headerStyle)),

                Expanded(flex: 14, child: Text('구분', style: _headerStyle)),

                Expanded(flex: 23, child: Text('신청 사유', style: _headerStyle)),

                Expanded(flex: 15, child: Text('신청일', style: _headerStyle)),

                Expanded(
                  flex: 14,
                  child: Text(
                    '상태',
                    textAlign: TextAlign.center,
                    style: _headerStyle,
                  ),
                ),

                Expanded(
                  flex: 18,
                  child: Text(
                    '처리',
                    textAlign: TextAlign.center,
                    style: _headerStyle,
                  ),
                ),
              ],
            ),
          ),

          if (requests.isEmpty)
            const SizedBox(height: 180, child: _ApprovalEmptyState()),

          if (requests.isNotEmpty)
            for (int index = 0; index < requests.length; index++) ...[
              _LeaveApprovalRow(
                request: requests[index],
                onApprove: () {
                  _approveRequest(requests[index].id);
                },
                onReject: () {
                  _rejectRequest(requests[index].id);
                },
              ),

              if (index != requests.length - 1)
                const Divider(height: 1, thickness: 1, color: AppColors.border),
            ],
        ],
      ),
    );
  }

  // ============================================================
  // STEP 17. Filter Helpers
  // ============================================================

  void _changeMyRequestStatus(LeaveStatusFilter status) {
    if (_myRequestStatus == status) {
      return;
    }

    setState(() {
      _myRequestStatus = status;
    });
  }

  void _changeApprovalStatus(LeaveStatusFilter status) {
    if (_approvalStatus == status) {
      return;
    }

    setState(() {
      _approvalStatus = status;
    });
  }

  int _countMyStatus(String status) {
    return _previewRequests.where((item) => item.status == status).length;
  }

  int _countApprovalStatus(String status) {
    return _approvalRequests.where((item) => item.status == status).length;
  }

  // ============================================================
  // STEP 18. 승인 / 반려 Mock Action
  //
  // 실제 API Schema 확인 후 POST/PATCH 호출로 교체.
  // ============================================================

  void _approveRequest(int id) {
    final index = _approvalRequests.indexWhere((item) => item.id == id);

    if (index < 0) {
      return;
    }

    if (_approvalRequests[index].status != 'PENDING') {
      return;
    }

    setState(() {
      _approvalRequests[index] = _approvalRequests[index].copyWith(
        status: 'APPROVED',
      );
    });

    _showMessage('휴무 요청을 UI에서 승인 처리했습니다. 실제 API는 아직 연결하지 않았습니다.');
  }

  void _rejectRequest(int id) {
    final index = _approvalRequests.indexWhere((item) => item.id == id);

    if (index < 0) {
      return;
    }

    if (_approvalRequests[index].status != 'PENDING') {
      return;
    }

    setState(() {
      _approvalRequests[index] = _approvalRequests[index].copyWith(
        status: 'REJECTED',
      );
    });

    _showMessage('휴무 요청을 UI에서 반려 처리했습니다. 실제 API는 아직 연결하지 않았습니다.');
  }

  // ============================================================
  // STEP 19. SnackBar
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }
}

// ============================================================
// STEP 20. Header Text Style
// ============================================================

const TextStyle _headerStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: AppColors.textSecondary,
);

// ============================================================
// STEP 21. View Tab Button
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
// STEP 22. Status Filter Button
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
// STEP 23. 내 휴무 신청 Row
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
// STEP 24. 승인 요청 Row
// ============================================================

class _LeaveApprovalRow extends StatelessWidget {
  final _LeaveApprovalPreview request;

  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _LeaveApprovalRow({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = request.status == 'PENDING';

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // ======================================================
          // 신청자
          // ======================================================
          Expanded(
            flex: 18,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.requesterName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  request.department,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // 휴무일
          // ======================================================
          Expanded(
            flex: 16,
            child: Text(
              request.date,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // ======================================================
          // 구분
          // ======================================================
          Expanded(
            flex: 14,
            child: Text(
              request.type,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // ======================================================
          // 신청 사유
          // ======================================================
          Expanded(
            flex: 23,
            child: Text(
              request.reason,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // ======================================================
          // 신청일
          // ======================================================
          Expanded(
            flex: 15,
            child: Text(
              request.requestedAt,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // ======================================================
          // 상태
          // ======================================================
          Expanded(
            flex: 14,
            child: Align(
              alignment: Alignment.center,
              child: _LeaveStatusBadge(status: request.status),
            ),
          ),

          // ======================================================
          // 처리
          // ======================================================
          Expanded(
            flex: 18,
            child: isPending
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ApprovalActionButton(
                        label: '반려',
                        danger: true,
                        onPressed: onReject,
                      ),

                      const SizedBox(width: 5),

                      _ApprovalActionButton(label: '승인', onPressed: onApprove),
                    ],
                  )
                : const Center(
                    child: Text(
                      '-',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textDisabled,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 25. 승인 / 반려 Action Button
// ============================================================

class _ApprovalActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  final bool danger;

  const _ApprovalActionButton({
    required this.label,
    required this.onPressed,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    if (danger) {
      return SizedBox(
        height: 28,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: const BorderSide(color: AppColors.danger),
            minimumSize: const Size(42, 28),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            '반려',
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return SizedBox(
      height: 28,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          minimumSize: const Size(42, 28),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text(
          '승인',
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 26. Status Badge
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
// STEP 27. Empty State - 내 신청
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

// ============================================================
// STEP 28. Empty State - 승인 요청
// ============================================================

class _ApprovalEmptyState extends StatelessWidget {
  const _ApprovalEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fact_check_outlined,
            size: 32,
            color: AppColors.secondaryBlue,
          ),

          SizedBox(height: 8),

          Text(
            '해당하는 승인 요청이 없습니다.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: 4),

          Text(
            '같은 진료과 의료진의 휴무 요청이 표시됩니다.',
            style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
