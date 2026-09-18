import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/auth/access_control.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../examinations/data/services/examination_service.dart';
import '../../../examinations/presentation/examination_ui_models.dart';
import '../../../examinations/presentation/widgets/examination_order_composer.dart';
import 'patient_detail_tabs.dart';

class PatientExaminationOrderSection extends StatefulWidget {
  final PatientUiModel patient;

  const PatientExaminationOrderSection({super.key, required this.patient});

  @override
  State<PatientExaminationOrderSection> createState() =>
      _PatientExaminationOrderSectionState();
}

class _PatientExaminationOrderSectionState
    extends State<PatientExaminationOrderSection> {
  List<ExaminationEncounterUiModel> _patientEncounters = [];
  List<ExaminationOrderUiModel> _orders = [];
  List<ExaminationTypeUiModel> _types = [];

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
  void didUpdateWidget(covariant PatientExaminationOrderSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.patient.patientId != widget.patient.patientId) {
      _loadData();
    }
  }

  ExaminationService _service() {
    final auth = context.read<AuthProvider>();

    return ExaminationService(apiClient: auth.authService.apiClient);
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final service = _service();

      final encounters = await service.fetchEncounters();
      final orders = await service.fetchExaminationOrders();
      final types = await service.fetchExaminationTypes();

      final patientEncounters =
          encounters
              .where(
                (encounter) => encounter.patientId == widget.patient.patientId,
              )
              .toList()
            ..sort((a, b) => b.visitDate.compareTo(a.visitDate));

      final encounterIds = patientEncounters
          .map((encounter) => encounter.id)
          .toSet();

      final patientOrders =
          orders
              .where((order) => encounterIds.contains(order.encounterId))
              .toList()
            ..sort((a, b) => b.orderedAt.compareTo(a.orderedAt));

      if (!mounted) {
        return;
      }

      setState(() {
        _patientEncounters = patientEncounters;
        _orders = patientOrders;
        _types = types;
        _isLoading = false;
        _loadError = null;
      });
    } catch (error) {
      debugPrint('[PatientExaminationOrderSection] 검사 오더 조회 실패: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = '검사 오더를 불러오지 못했습니다.';
      });
    }
  }

  Future<void> _showCreateOrderDialog() async {
    if (_patientEncounters.isEmpty) {
      _showMessage('검사 오더를 연결할 진료 기록이 없습니다.');
      return;
    }

    if (_types.isEmpty) {
      _showMessage('사용 가능한 검사 항목이 없습니다.');
      return;
    }

    final examinationPatient = ExaminationPatientUiModel(
      id: widget.patient.patientId,
      name: widget.patient.name,
      age: widget.patient.age,
      gender: widget.patient.gender,
    );

    final initialEncounterId = _patientEncounters.first.id;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return ExaminationOrderComposer(
          patients: [examinationPatient],
          encounters: _patientEncounters,
          types: _types,
          initialPatientId: widget.patient.patientId,
          initialEncounterId: initialEncounterId,
          lockPatientSelection: true,
          dialogMode: true,
          onSubmit:
              ({
                required int encounterId,
                required int examinationTypeId,
                required String priority,
                required String clinicalNote,
              }) async {
                try {
                  return await _service().createExaminationOrder(
                    encounterId: encounterId,
                    examinationTypeId: examinationTypeId,
                    priority: priority,
                    clinicalNote: clinicalNote,
                  );
                } catch (error) {
                  debugPrint(
                    '[PatientExaminationOrderSection] '
                    '검사 오더 생성 실패: $error',
                  );

                  return null;
                }
              },
          onCreated: (createdOrder) {
            if (mounted) {
              setState(() {
                _orders = [
                  createdOrder,
                  ..._orders.where((order) => order.id != createdOrder.id),
                ];
              });
            }

            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }

            _showMessage('검사 오더 #${createdOrder.id}가 생성되었습니다.');
          },
          onCancel: () {
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
          },
        );
      },
    );
  }

  ExaminationTypeUiModel? _findType(int typeId) {
    for (final type in _types) {
      if (type.id == typeId) {
        return type;
      }
    }

    return null;
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDoctor = auth.role == UserRole.doctor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: context.appSurfaceSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.assignment_add,
                size: 15,
                color: context.appBrand,
              ),
            ),

            const SizedBox(width: 9),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '검사 오더',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.appTextPrimary,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    '환자에게 처방된 검사와 진행 상태를 확인합니다.',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: context.appTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isDoctor)
              SizedBox(
                height: 34,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _showCreateOrderDialog,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 14),
                  label: const Text(
                    '검사 오더',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const _OrderMessage(text: '검사 오더를 불러오는 중입니다.', showProgress: true)
        else if (_loadError != null)
          _OrderMessage(text: _loadError!, onRetry: _loadData)
        else if (_orders.isEmpty)
          const _OrderMessage(text: '등록된 검사 오더가 없습니다.')
        else
          Container(
            decoration: BoxDecoration(
              color: context.appSurface,
              border: Border.all(color: context.appBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                const _OrderTableHeader(),

                Divider(height: 1, color: context.appBorder),

                for (var index = 0; index < _orders.length; index++) ...[
                  _OrderCard(
                    order: _orders[index],
                    type: _findType(_orders[index].examinationTypeId),
                  ),

                  if (index != _orders.length - 1)
                    Divider(height: 1, color: context.appBorder),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

// ============================================================
// 검사 오더 Table Header
// ============================================================

class _OrderTableHeader extends StatelessWidget {
  const _OrderTableHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return const SizedBox.shrink();
        }

        final headerStyle = TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
          color: context.appTextSecondary,
        );

        return Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: context.appSurfaceSoft,
          child: Row(
            children: [
              Expanded(flex: 46, child: Text('검사명', style: headerStyle)),

              const SizedBox(width: 12),

              Expanded(
                flex: 24,
                child: Text(
                  '오더일시',
                  textAlign: TextAlign.center,
                  style: headerStyle,
                ),
              ),

              const SizedBox(width: 10),

              SizedBox(
                width: 50,
                child: Text(
                  '우선순위',
                  textAlign: TextAlign.center,
                  style: headerStyle,
                ),
              ),

              const SizedBox(width: 7),

              SizedBox(
                width: 52,
                child: Text(
                  '상태',
                  textAlign: TextAlign.center,
                  style: headerStyle,
                ),
              ),

              const SizedBox(width: 19),
            ],
          ),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final ExaminationOrderUiModel order;
  final ExaminationTypeUiModel? type;

  const _OrderCard({required this.order, required this.type});

  @override
  Widget build(BuildContext context) {
    final clinicalNote = _displayClinicalNote(order.clinicalNote);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 620) {
                return _buildCompactLayout(context, clinicalNote);
              }

              return _buildWideLayout(context);
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Wide Layout
  // ============================================================

  Widget _buildWideLayout(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 46,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type == null ? '검사' : _typeDisplayName(type!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: context.appTextPrimary,
                  ),
                ),

                const SizedBox(height: 1),

                Text(
                  '오더 #${order.id} · 진료 #${order.encounterId}',
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

          const SizedBox(width: 12),

          Expanded(
            flex: 24,
            child: Text(
              _formatDateTime(order.orderedAt),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 8.5, color: context.appTextSecondary),
            ),
          ),

          const SizedBox(width: 10),

          SizedBox(
            width: 50,
            child: Center(child: _PriorityBadge(priority: order.priority)),
          ),

          const SizedBox(width: 7),

          SizedBox(
            width: 52,
            child: Center(child: _OrderStatusBadge(status: order.status)),
          ),

          const SizedBox(width: 3),

          SizedBox(
            width: 16,
            child: Icon(
              Icons.chevron_right_rounded,
              size: 15,
              color: context.appTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Compact Layout
  // ============================================================

  Widget _buildCompactLayout(BuildContext context, String clinicalNote) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: context.appSurfaceSoft,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(_typeIcon(type), size: 15, color: context.appBrand),
            ),

            const SizedBox(width: 9),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type == null ? '검사' : _typeDisplayName(type!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: context.appTextPrimary,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    _formatDateTime(order.orderedAt),
                    style: TextStyle(
                      fontSize: 9,
                      color: context.appTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            _PriorityBadge(priority: order.priority),

            const SizedBox(width: 6),

            _OrderStatusBadge(status: order.status),
          ],
        ),

        if (clinicalNote.isNotEmpty) ...[
          const SizedBox(height: 8),

          Text(
            clinicalNote,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              height: 1.4,
              color: context.appTextSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final isUrgent = priority.trim().toUpperCase() == 'URGENT';

    final color = isUrgent ? AppColors.danger : context.appTextSecondary;

    return Container(
      constraints: const BoxConstraints(minWidth: 42),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isUrgent ? '긴급' : '일반',
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _OrderStatusBadge extends StatelessWidget {
  final String status;

  const _OrderStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toUpperCase();

    final String label;
    final Color color;

    switch (normalized) {
      case 'ORDERED':
        label = '오더';
        color = AppColors.primaryBlue;
        break;

      case 'SCHEDULED':
        label = '예약';
        color = AppColors.secondaryBlue;
        break;

      case 'IN_PROGRESS':
        label = '진행 중';
        color = context.appPrimary;
        break;

      case 'COMPLETED':
        label = '완료';
        color = AppColors.success;
        break;

      case 'CANCELED':
        label = '취소';
        color = AppColors.danger;
        break;

      default:
        label = status.isEmpty ? '-' : status;
        color = context.appTextSecondary;
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 48),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _OrderMessage extends StatelessWidget {
  final String text;
  final bool showProgress;
  final VoidCallback? onRetry;

  const _OrderMessage({
    required this.text,
    this.showProgress = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.appSurfaceSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          if (showProgress) ...[
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),

            const SizedBox(height: 10),
          ],

          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: context.appTextSecondary),
          ),

          if (onRetry != null) ...[
            const SizedBox(height: 8),

            TextButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ],
      ),
    );
  }
}

String _typeDisplayName(ExaminationTypeUiModel type) {
  switch (type.code.trim().toUpperCase()) {
    case 'BLOOD':
    case 'CARDIAC_LAB_PANEL':
      return '혈액검사';

    case 'ANGIO_2D':
    case 'ANGIOGRAPHY':
      return '관상동맥조영술';

    case 'CCTA':
    case 'CCTA_3D':
      return '관상동맥 CT 검사';

    default:
      return type.name.trim().isEmpty ? type.code : type.name;
  }
}

IconData _typeIcon(ExaminationTypeUiModel? type) {
  final category = type?.category.trim().toUpperCase() ?? '';

  switch (category) {
    case 'LAB':
      return Icons.science_outlined;

    case 'IMAGING':
      return Icons.monitor_heart_outlined;

    case 'PROCEDURE':
      return Icons.video_library_outlined;

    default:
      return Icons.medical_services_outlined;
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toUtc().add(const Duration(hours: 9));

  return '${local.year}.'
      '${local.month.toString().padLeft(2, '0')}.'
      '${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String _displayClinicalNote(String? value) {
  final text = value?.trim() ?? '';

  if (text.isEmpty) {
    return '';
  }

  return text.replaceFirst(RegExp(r'^\[SYNTHETIC:[^\]]+\]\s*'), '').trim();
}
