import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';
import 'package:provider/provider.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/security/reauthentication_dialog.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/attendance_request.dart';
import '../../data/services/attendance_request_service.dart';

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
// ============================================================

class _LeaveRequestPreview {
  final int id;

  final String date;
  final String type;
  final String requestedAt;
  final String status;

  const _LeaveRequestPreview({
    required this.id,
    required this.date,
    required this.type,
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
  final String requestedAt;

  final String status;

  const _LeaveApprovalPreview({
    required this.id,
    required this.requesterName,
    required this.department,
    required this.date,
    required this.type,
    required this.requestedAt,
    required this.status,
  });
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
  // STEP 6. 실제 휴무 신청 API 상태
  // ============================================================

  final List<_LeaveRequestPreview> _requests = [];
  final List<_LeaveApprovalPreview> _approvalRequests = [];
  LeaveBalance? _leaveBalance;

  bool _isLoading = true;
  String? _loadError;

  bool _didInitialLoad = false;
  int? _cancellingRequestId;
  int? _processingApprovalRequestId;

  // ============================================================
  // STEP 7. 실제 휴무 신청 데이터 초기 조회
  // ============================================================

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didInitialLoad) {
      return;
    }

    _didInitialLoad = true;

    unawaited(_loadRequests());
  }

  // ============================================================
  // STEP 8. 내 신청 + 승인 요청 조회
  // ============================================================

  Future<void> _loadRequests({bool showLoading = true}) async {
    if (mounted && showLoading) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final auth = context.read<AuthProvider>();

      final service = AttendanceRequestService(
        apiClient: auth.authService.apiClient,
      );

      final myRequestsFuture = service.fetchMyRequests();

      final adminRequestsFuture = widget.canApproveLeave
          ? service.fetchAdminRequests()
          : Future.value(<AttendanceRequest>[]);

      final leaveBalanceFuture = service.fetchLeaveBalance();

      final results = await Future.wait([
        myRequestsFuture,
        adminRequestsFuture,
        leaveBalanceFuture,
      ]);

      if (!mounted) {
        return;
      }

      final myRequests = results[0] as List<AttendanceRequest>;

      final adminRequests = results[1] as List<AttendanceRequest>;

      final leaveBalance = results[2] as LeaveBalance;

      setState(() {
        _requests
          ..clear()
          ..addAll(myRequests.map(_mapMyRequest));

        _approvalRequests
          ..clear()
          ..addAll(adminRequests.map(_mapApprovalRequest));

        _leaveBalance = leaveBalance;

        _isLoading = false;
        _loadError = null;
      });

      debugPrint(
        '[ATTENDANCE] 내 신청 ${myRequests.length}건 / '
        '승인 요청 ${adminRequests.length}건 조회 완료',
      );
      debugPrint(
        '[ATTENDANCE] 내 신청 ${myRequests.length}건 / '
        '승인 요청 ${adminRequests.length}건 / '
        '잔여 연차 ${leaveBalance.remainingDays}일',
      );
    } catch (error) {
      debugPrint('[ATTENDANCE] 휴무 신청 조회 실패: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = '휴무 신청 정보를 불러오지 못했습니다.';
      });
    }
  }

  // ============================================================
  // STEP 9. API Model → 기존 UI Model
  // ============================================================

  _LeaveRequestPreview _mapMyRequest(AttendanceRequest request) {
    return _LeaveRequestPreview(
      id: request.id,
      date: _formatLeaveDate(request),
      type: request.attendanceTypeLabel,
      requestedAt: _formatDate(request.createdAt.toLocal()),
      status: request.status,
    );
  }

  _LeaveApprovalPreview _mapApprovalRequest(AttendanceRequest request) {
    return _LeaveApprovalPreview(
      id: request.id,
      requesterName: request.requesterName,
      department: '',
      date: _formatLeaveDate(request),
      type: request.attendanceTypeLabel,
      requestedAt: _formatDate(request.createdAt.toLocal()),
      status: request.status,
    );
  }

  // ============================================================
  // STEP 10. 표시용 Formatter
  // ============================================================

  String _formatLeaveDate(AttendanceRequest request) {
    final start = _formatDate(request.startDate);
    final end = _formatDate(request.endDate);

    if (request.attendanceType == AttendanceType.hourlyLeave) {
      final startTime = _formatApiTime(request.startTime);
      final endTime = _formatApiTime(request.endTime);

      if (startTime != null && endTime != null) {
        return '$start $startTime ~ $endTime';
      }
    }

    if (start == end) {
      return start;
    }

    return '$start ~ $end';
  }

  String? _formatApiTime(String? value) {
    if (value == null) {
      return null;
    }

    final text = value.trim();

    if (text.length >= 5) {
      return text.substring(0, 5);
    }

    return text.isEmpty ? null : text;
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year.$month.$day';
  }

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

    if (oldWidget.canApproveLeave != widget.canApproveLeave) {
      unawaited(_loadRequests());
    }
  }
  // ============================================================
  // STEP 9. 내 신청 Filtered Data
  // ============================================================

  List<_LeaveRequestPreview> get _filteredRequests {
    switch (_myRequestStatus) {
      case LeaveStatusFilter.all:
        return _requests;

      case LeaveStatusFilter.pending:
        return _requests.where((item) => item.status == 'PENDING').toList();

      case LeaveStatusFilter.approved:
        return _requests.where((item) => item.status == 'APPROVED').toList();

      case LeaveStatusFilter.rejected:
        return _requests.where((item) => item.status == 'REJECTED').toList();
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
    // ==========================================================
    // 휴무 신청 API 로딩
    // ==========================================================

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // ==========================================================
    // 휴무 신청 API 조회 실패
    // ==========================================================

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 32,
              color: Theme.of(context).colorScheme.error,
            ),

            const SizedBox(height: 10),

            Text(
              _loadError!,
              style: TextStyle(fontSize: 12, color: context.appTextSecondary),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _loadRequests,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    // ==========================================================
    // 정상 화면
    // ==========================================================

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
              count: _requests.length,
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

            if (_leaveBalance != null) ...[
              _LeaveBalanceBadge(balance: _leaveBalance!),

              const SizedBox(width: 10),
            ],

            // ====================================================
            // 휴무 신청
            // ====================================================
            SizedBox(
              height: 34,
              child: TextButton.icon(
                onPressed: widget.onCreateRequest,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  backgroundColor: context.appSurfaceSoft,
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
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
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
            color: context.appSurfaceSoft,
            child: Row(
              children: [
                Expanded(
                  flex: 24,
                  child: Text('휴무일', style: _headerStyle(context)),
                ),

                Expanded(
                  flex: 18,
                  child: Text('구분', style: _headerStyle(context)),
                ),

                Expanded(
                  flex: 22,
                  child: Text('신청일', style: _headerStyle(context)),
                ),

                Expanded(
                  flex: 18,
                  child: Text(
                    '상태',
                    textAlign: TextAlign.center,
                    style: _headerStyle(context),
                  ),
                ),

                Expanded(
                  flex: 18,
                  child: Text(
                    '처리',
                    textAlign: TextAlign.center,
                    style: _headerStyle(context),
                  ),
                ),
              ],
            ),
          ),

          if (requests.isEmpty)
            const SizedBox(height: 180, child: _LeaveEmptyState()),

          if (requests.isNotEmpty)
            for (int index = 0; index < requests.length; index++) ...[
              _LeaveRequestRow(
                request: requests[index],
                isCancelling: _cancellingRequestId == requests[index].id,
                onCancel: () {
                  _cancelRequest(requests[index]);
                },
              ),

              if (index != requests.length - 1)
                Divider(height: 1, thickness: 1, color: context.appBorder),
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

            Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 14,
                  color: context.appTextSecondary,
                ),

                SizedBox(width: 5),

                Text(
                  '같은 진료과 의료진 요청',
                  style: TextStyle(
                    fontSize: 10,
                    color: context.appTextSecondary,
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
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ======================================================
          // Table Header
          // 신청 사유는 현재 휴무 정책에서 사용하지 않음
          // ======================================================
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: context.appSurfaceSoft,
            child: Row(
              children: [
                Expanded(
                  flex: 22,
                  child: Text('신청자', style: _headerStyle(context)),
                ),

                Expanded(
                  flex: 20,
                  child: Text('휴무일', style: _headerStyle(context)),
                ),

                Expanded(
                  flex: 16,
                  child: Text('구분', style: _headerStyle(context)),
                ),

                Expanded(
                  flex: 16,
                  child: Text('신청일', style: _headerStyle(context)),
                ),

                Expanded(
                  flex: 14,
                  child: Text(
                    '상태',
                    textAlign: TextAlign.center,
                    style: _headerStyle(context),
                  ),
                ),

                Expanded(
                  flex: 20,
                  child: Text(
                    '처리',
                    textAlign: TextAlign.center,
                    style: _headerStyle(context),
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
                isProcessing:
                    _processingApprovalRequestId == requests[index].id,
                onApprove: () {
                  _approveRequest(requests[index]);
                },
                onReject: () {
                  _rejectRequest(requests[index]);
                },
              ),

              if (index != requests.length - 1)
                Divider(height: 1, thickness: 1, color: context.appBorder),
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
    return _requests.where((item) => item.status == status).length;
  }

  int _countApprovalStatus(String status) {
    return _approvalRequests.where((item) => item.status == status).length;
  }

  // ============================================================
  // STEP 18. 내 휴무 신청 취소
  // ============================================================

  Future<void> _cancelRequest(_LeaveRequestPreview request) async {
    if (request.status != 'PENDING') {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('휴무 신청 취소'),
          content: Text('${request.date} ${request.type} 신청을 취소하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('닫기'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('신청 취소'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _cancellingRequestId = request.id;
    });

    try {
      final auth = context.read<AuthProvider>();

      final service = AttendanceRequestService(
        apiClient: auth.authService.apiClient,
      );

      await service.cancelRequest(request.id);

      if (!mounted) {
        return;
      }

      debugPrint(
        '[ATTENDANCE] 휴무 신청 취소 성공 '
        'requestId=${request.id}',
      );

      await _loadRequests();

      if (!mounted) {
        return;
      }

      _showMessage('휴무 신청이 취소되었습니다.');
    } catch (error) {
      debugPrint('[ATTENDANCE] 휴무 신청 취소 실패: $error');

      if (!mounted) {
        return;
      }

      _showMessage('휴무 신청을 취소하지 못했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _cancellingRequestId = null;
        });
      }
    }
  }

  // ============================================================
  // STEP 19. 휴무 승인
  //
  // 1) 승인 확인
  // 2) 민감 작업 재인증
  // 3) 실제 승인 API 호출
  // 4) 목록 새로고침
  // ============================================================

  Future<void> _approveRequest(_LeaveApprovalPreview request) async {
    if (request.status != 'PENDING' || _processingApprovalRequestId != null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('휴무 승인'),
          content: Text(
            '${request.requesterName}님의 '
            '${request.date} ${request.type} 신청을 '
            '승인하시겠습니까?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
              ),
              child: const Text('승인'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    // ==========================================================
    // 민감 작업 재인증
    // ==========================================================

    final reauthenticated = await ensureSensitiveReauthentication(context);

    if (!reauthenticated || !mounted) {
      return;
    }

    setState(() {
      _processingApprovalRequestId = request.id;
    });

    try {
      final auth = context.read<AuthProvider>();

      final service = AttendanceRequestService(
        apiClient: auth.authService.apiClient,
      );

      // ========================================================
      // Backend Schema상 review_comment는 string으로 전송
      // null 전송 금지
      // ========================================================

      await service.approveRequest(requestId: request.id, reviewComment: '승인');

      if (!mounted) {
        return;
      }

      debugPrint(
        '[ATTENDANCE] 휴무 승인 성공 '
        'requestId=${request.id}',
      );

      await _loadRequests(showLoading: false);

      if (!mounted) {
        return;
      }

      _showMessage('휴무 신청을 승인했습니다.');
    } on DioException catch (error) {
      debugPrint(
        '[ATTENDANCE] 휴무 승인 실패 '
        'requestId=${request.id}, '
        'status=${error.response?.statusCode}, '
        'data=${error.response?.data}',
      );

      if (!mounted) {
        return;
      }

      String message = '휴무 신청을 승인하지 못했습니다.';

      final data = error.response?.data;

      if (data is Map) {
        final detail = data['detail'];

        if (detail != null && detail.toString().trim().isNotEmpty) {
          message = detail.toString();
        } else if (data.isNotEmpty) {
          message = data.values.first.toString();
        }
      }

      _showMessage(message);
    } catch (error) {
      debugPrint(
        '[ATTENDANCE] 휴무 승인 오류 '
        'requestId=${request.id}, '
        'error=$error',
      );

      if (!mounted) {
        return;
      }

      _showMessage('휴무 신청을 승인하지 못했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _processingApprovalRequestId = null;
        });
      }
    }
  }

  // ============================================================
  // STEP 20. 휴무 반려
  //
  // 반려 사유(review_comment)는 Backend 필수 값.
  // ============================================================

  Future<void> _rejectRequest(_LeaveApprovalPreview request) async {
    if (request.status != 'PENDING' || _processingApprovalRequestId != null) {
      return;
    }

    final auth = context.read<AuthProvider>();

    final reviewComment = await _showRejectCommentDialog(request);

    if (reviewComment == null || !mounted) {
      return;
    }

    final reauthenticated = await ensureSensitiveReauthentication(context);

    if (!reauthenticated || !mounted) {
      return;
    }

    setState(() {
      _processingApprovalRequestId = request.id;
    });

    try {
      final service = AttendanceRequestService(
        apiClient: auth.authService.apiClient,
      );

      await service.rejectRequest(
        requestId: request.id,
        reviewComment: reviewComment,
      );

      if (!mounted) {
        return;
      }

      debugPrint(
        '[ATTENDANCE] 휴무 반려 성공 '
        'requestId=${request.id}',
      );

      await _loadRequests(showLoading: false);

      if (!mounted) {
        return;
      }

      _showMessage('휴무 신청을 반려했습니다.');
    } catch (error) {
      debugPrint(
        '[ATTENDANCE] 휴무 반려 실패 '
        'requestId=${request.id}, error=$error',
      );

      if (!mounted) {
        return;
      }

      _showMessage('휴무 신청을 반려하지 못했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _processingApprovalRequestId = null;
        });
      }
    }
  }

  // ============================================================
  // STEP 21. 반려 사유 Dialog
  // ============================================================

  Future<String?> _showRejectCommentDialog(
    _LeaveApprovalPreview request,
  ) async {
    final controller = TextEditingController();
    String? errorText;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('휴무 신청 반려'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${request.requesterName}님의 '
                      '${request.date} ${request.type} 신청을 반려합니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.appTextSecondary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: controller,
                      autofocus: true,
                      minLines: 3,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        labelText: '반려 사유',
                        hintText: '반려 사유를 입력해 주세요.',
                        errorText: errorText,
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '반려 사유는 처리 기록에 저장됩니다.',
                      style: TextStyle(
                        fontSize: 10,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () {
                    final comment = controller.text.trim();

                    if (comment.isEmpty) {
                      setDialogState(() {
                        errorText = '반려 사유를 입력해 주세요.';
                      });
                      return;
                    }

                    Navigator.of(dialogContext).pop(comment);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  child: const Text('반려'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    return result;
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

TextStyle _headerStyle(BuildContext context) => TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: context.appTextSecondary,
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
            color: isSelected ? context.appSurfaceSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryBlue.withValues(alpha: 0.22)
                  : context.appBorder,
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
                  color: isSelected ? AppColors.navy : context.appTextSecondary,
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
            color: isSelected ? AppColors.navy : context.appSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.navy : context.appBorder,
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
                  color: isSelected ? Colors.white : context.appTextSecondary,
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
                      : context.appTextDisabled,
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
// Leave Balance Badge
// ============================================================

class _LeaveBalanceBadge extends StatelessWidget {
  final LeaveBalance balance;

  const _LeaveBalanceBadge({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.event_available_outlined,
            size: 16,
            color: AppColors.secondaryBlue,
          ),

          const SizedBox(width: 7),

          Text(
            '${balance.year} 잔여 연차',
            style: TextStyle(fontSize: 10.5, color: context.appTextSecondary),
          ),

          const SizedBox(width: 6),

          Text(
            '${_formatDays(balance.remainingDays)}일',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: context.appTextPrimary,
            ),
          ),

          const SizedBox(width: 8),

          Container(width: 1, height: 14, color: context.appBorder),

          const SizedBox(width: 8),

          Text(
            '사용 ${_formatDays(balance.usedDays)}일',
            style: TextStyle(fontSize: 9.5, color: context.appTextSecondary),
          ),
        ],
      ),
    );
  }

  static String _formatDays(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }

    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

// ============================================================
// STEP 23. 내 휴무 신청 Row
// ============================================================

class _LeaveRequestRow extends StatelessWidget {
  final _LeaveRequestPreview request;

  final VoidCallback onCancel;
  final bool isCancelling;

  const _LeaveRequestRow({
    required this.request,
    required this.onCancel,
    required this.isCancelling,
  });

  @override
  Widget build(BuildContext context) {
    final canCancel = request.status == 'PENDING';

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 24,
            child: Text(
              request.date,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: context.appTextPrimary,
              ),
            ),
          ),

          Expanded(
            flex: 18,
            child: Text(
              request.type,
              style: TextStyle(fontSize: 12, color: context.appTextPrimary),
            ),
          ),

          Expanded(
            flex: 22,
            child: Text(
              request.requestedAt,
              style: TextStyle(fontSize: 11.5, color: context.appTextSecondary),
            ),
          ),

          Expanded(
            flex: 18,
            child: Align(
              alignment: Alignment.center,
              child: _LeaveStatusBadge(status: request.status),
            ),
          ),

          Expanded(
            flex: 18,
            child: Center(
              child: canCancel
                  ? SizedBox(
                      height: 28,
                      child: OutlinedButton(
                        onPressed: isCancelling ? null : onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: isCancelling
                            ? const SizedBox(
                                width: 13,
                                height: 13,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                '취소',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    )
                  : Text(
                      '-',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.appTextDisabled,
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
// STEP 24. 승인 요청 Row
// ============================================================

class _LeaveApprovalRow extends StatelessWidget {
  final _LeaveApprovalPreview request;

  final VoidCallback onApprove;
  final VoidCallback onReject;

  final bool isProcessing;

  const _LeaveApprovalRow({
    required this.request,
    required this.onApprove,
    required this.onReject,
    required this.isProcessing,
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
            flex: 22,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.requesterName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: context.appTextPrimary,
                  ),
                ),

                if (request.department.isNotEmpty) ...[
                  const SizedBox(height: 2),

                  Text(
                    request.department,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      color: context.appTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ======================================================
          // 휴무일
          // ======================================================
          Expanded(
            flex: 20,
            child: Text(
              request.date,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: context.appTextPrimary,
              ),
            ),
          ),

          // ======================================================
          // 구분
          // ======================================================
          Expanded(
            flex: 16,
            child: Text(
              request.type,
              style: TextStyle(fontSize: 11, color: context.appTextPrimary),
            ),
          ),

          // ======================================================
          // 신청일
          // ======================================================
          Expanded(
            flex: 16,
            child: Text(
              request.requestedAt,
              style: TextStyle(fontSize: 10.5, color: context.appTextSecondary),
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
            flex: 20,
            child: _buildActionArea(context, isPending: isPending),
          ),
        ],
      ),
    );
  }

  Widget _buildActionArea(BuildContext context, {required bool isPending}) {
    if (!isPending) {
      return Center(
        child: Text(
          '-',
          style: TextStyle(fontSize: 11, color: context.appTextDisabled),
        ),
      );
    }

    if (isProcessing) {
      return const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ApprovalActionButton(label: '반려', danger: true, onPressed: onReject),

        const SizedBox(width: 5),

        _ApprovalActionButton(label: '승인', onPressed: onApprove),
      ],
    );
  }
}

// ============================================================
// STEP 25. 승인 / 반려 Action Button
// ============================================================

class _ApprovalActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

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
          child: Text(
            label,
            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600),
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
          foregroundColor: Colors.white,
          minimumSize: const Size(42, 28),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600),
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
        color: _background(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: _foreground(context),
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

      case 'CANCELLED':
      case 'CANCELED':
        return '취소';

      default:
        return status;
    }
  }

  Color _foreground(BuildContext context) {
    switch (status) {
      case 'PENDING':
        return AppColors.warning;

      case 'APPROVED':
        return AppColors.success;

      case 'REJECTED':
        return AppColors.danger;

      case 'CANCELLED':
      case 'CANCELED':
        return context.appTextSecondary;

      default:
        return context.appTextSecondary;
    }
  }

  Color _background(BuildContext context) {
    switch (status) {
      case 'PENDING':
        return AppColors.warningBackground;

      case 'APPROVED':
        return AppColors.successBackground;

      case 'REJECTED':
        return AppColors.dangerBackground;

      case 'CANCELLED':
      case 'CANCELED':
        return context.appSurfaceSoft;

      default:
        return context.appSurfaceSoft;
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
    return Center(
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
              color: context.appTextPrimary,
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
    return Center(
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
              color: context.appTextPrimary,
            ),
          ),

          SizedBox(height: 4),

          Text(
            '같은 진료과 의료진의 휴무 요청이 표시됩니다.',
            style: TextStyle(fontSize: 10.5, color: context.appTextSecondary),
          ),
        ],
      ),
    );
  }
}
