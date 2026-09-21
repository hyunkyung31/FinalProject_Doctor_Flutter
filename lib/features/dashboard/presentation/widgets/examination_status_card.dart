import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../examinations/data/services/examination_service.dart';
import '../../../examinations/presentation/examination_ui_models.dart';
import 'dashboard_section_card.dart';

class ExaminationStatusCard extends StatefulWidget {
  final int refreshVersion;

  const ExaminationStatusCard({super.key, this.refreshVersion = 0});

  @override
  State<ExaminationStatusCard> createState() => _ExaminationStatusCardState();
}

class _ExaminationStatusCardState extends State<ExaminationStatusCard> {
  List<ExaminationOrderUiModel> _orders = [];
  Map<int, ExaminationTypeUiModel> _typeMap = {};

  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void didUpdateWidget(covariant ExaminationStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshVersion != widget.refreshVersion) {
      _loadData();
    }
  }

  ExaminationService _service() {
    final auth = context.read<AuthProvider>();

    return ExaminationService(apiClient: auth.authService.apiClient);
  }

  Future<void> _loadData() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final service = _service();

      final results = await Future.wait([
        service.fetchExaminationOrders(),
        service.fetchExaminationTypes(),
      ]);

      final orders = results[0] as List<ExaminationOrderUiModel>;

      final types = results[1] as List<ExaminationTypeUiModel>;

      final activeOrders = orders.where((order) {
        final status = order.status.toUpperCase();

        return status == 'SCHEDULED' ||
            status == 'ORDERED' ||
            status == 'IN_PROGRESS';
      }).toList();

      activeOrders.sort(_compareOrders);

      if (!mounted) {
        return;
      }

      setState(() {
        _orders = activeOrders;
        _typeMap = {for (final type in types) type.id: type};
        _isLoading = false;
      });

      debugPrint(
        '[DASHBOARD] 검사 진행 현황 조회 완료: '
        '${activeOrders.length}건',
      );
    } catch (error) {
      debugPrint('[DASHBOARD] 검사 진행 현황 조회 실패: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = '검사 현황을 불러오지 못했습니다.';
      });
    }
  }

  int _compareOrders(ExaminationOrderUiModel a, ExaminationOrderUiModel b) {
    final aStatus = a.status.toUpperCase();
    final bStatus = b.status.toUpperCase();

    final aWeight = _statusWeight(aStatus);
    final bWeight = _statusWeight(bStatus);

    if (aWeight != bWeight) {
      return aWeight.compareTo(bWeight);
    }

    final aDate = a.scheduledAt ?? a.orderedAt;
    final bDate = b.scheduledAt ?? b.orderedAt;

    return bDate.compareTo(aDate);
  }

  int _statusWeight(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return 0;
      case 'SCHEDULED':
        return 1;
      case 'ORDERED':
        return 2;
      default:
        return 3;
    }
  }

  int get _scheduledCount {
    return _orders.where((order) {
      return order.status.toUpperCase() == 'SCHEDULED';
    }).length;
  }

  int get _orderedCount {
    return _orders.where((order) {
      return order.status.toUpperCase() == 'ORDERED';
    }).length;
  }

  int get _inProgressCount {
    return _orders.where((order) {
      return order.status.toUpperCase() == 'IN_PROGRESS';
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return DashboardSectionCard(
      title: '검사 진행 현황',
      actionLabel: '전체보기',
      onAction: () {
        context.go('/examinations');
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 10, 13, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummary(),

            const SizedBox(height: 10),

            if (_isLoading)
              const SizedBox(
                height: 112,
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              )
            else if (_loadError != null)
              SizedBox(
                height: 112,
                child: Center(
                  child: Text(
                    _loadError!,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: context.appTextSecondary,
                    ),
                  ),
                ),
              )
            else if (_orders.isEmpty)
              SizedBox(
                height: 112,
                child: Center(
                  child: Text(
                    '대기 중인 검사가 없습니다.',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: context.appTextSecondary,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: [
                  for (final order in _orders.take(4))
                    _ExaminationRow(
                      order: order,
                      type: _typeMap[order.examinationTypeId],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Row(
      children: [
        _SummaryItem(
          label: '진행',
          count: _inProgressCount,
          foreground: AppColors.primaryBlue,
          background: AppColors.surfaceSoft,
        ),

        const SizedBox(width: 6),

        _SummaryItem(
          label: '예정',
          count: _scheduledCount,
          foreground: AppColors.success,
          background: AppColors.successBackground,
        ),

        const SizedBox(width: 6),

        _SummaryItem(
          label: '오더',
          count: _orderedCount,
          foreground: AppColors.warning,
          background: AppColors.warningBackground,
        ),

        const Spacer(),

        Text(
          '총 ${_orders.length}건',
          style: const TextStyle(
            fontSize: 8.8,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final int count;
  final Color foreground;
  final Color background;

  const _SummaryItem({
    required this.label,
    required this.count,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExaminationRow extends StatelessWidget {
  final ExaminationOrderUiModel order;
  final ExaminationTypeUiModel? type;

  const _ExaminationRow({required this.order, required this.type});

  @override
  Widget build(BuildContext context) {
    final status = order.status.toUpperCase();

    final date = order.scheduledAt ?? order.orderedAt;
    final displayDate = _toKst(date);

    final typeName = type?.name.trim().isNotEmpty == true
        ? type!.name
        : '검사 #${order.examinationTypeId}';

    final location = order.scheduledLocation?.trim() ?? '';

    return InkWell(
      onTap: () {
        context.go('/examinations');
      },
      borderRadius: BorderRadius.circular(7),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 3),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _statusBackground(status),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _typeIcon(type),
                size: 15,
                color: _statusColor(status),
              ),
            ),

            const SizedBox(width: 9),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    typeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: context.appTextPrimary,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    '${_formatDateTime(displayDate)}'
                    '${location.isEmpty ? '' : ' · $location'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8,
                      color: context.appTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 7),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _statusBackground(status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _statusLabel(status),
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: _statusColor(status),
                ),
              ),
            ),

            const SizedBox(width: 3),

            Icon(
              Icons.chevron_right_rounded,
              size: 15,
              color: context.appTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'IN_PROGRESS':
      return '진행 중';
    case 'SCHEDULED':
      return '검사 예정';
    case 'ORDERED':
      return '오더';
    default:
      return status;
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'IN_PROGRESS':
      return AppColors.primaryBlue;
    case 'SCHEDULED':
      return AppColors.success;
    case 'ORDERED':
      return AppColors.warning;
    default:
      return AppColors.textSecondary;
  }
}

Color _statusBackground(String status) {
  switch (status) {
    case 'IN_PROGRESS':
      return AppColors.surfaceSoft;
    case 'SCHEDULED':
      return AppColors.successBackground;
    case 'ORDERED':
      return AppColors.warningBackground;
    default:
      return AppColors.surfaceSoft;
  }
}

IconData _typeIcon(ExaminationTypeUiModel? type) {
  final category = type?.category.toUpperCase() ?? '';

  switch (category) {
    case 'LAB':
      return Icons.science_outlined;
    case 'IMAGING':
      return Icons.image_outlined;
    case 'PROCEDURE':
      return Icons.monitor_heart_outlined;
    default:
      return Icons.medical_services_outlined;
  }
}

DateTime _toKst(DateTime date) {
  final kst = date.toUtc().add(const Duration(hours: 9));

  return DateTime(kst.year, kst.month, kst.day, kst.hour, kst.minute);
}

String _formatDateTime(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '$month.$day $hour:$minute';
}
