import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../patients/data/services/patient_service.dart';
import '../../../patients/presentation/widgets/patient_detail_tabs.dart';
import 'dashboard_section_card.dart';

class RecentPatientsCard extends StatefulWidget {
  final int refreshVersion;

  const RecentPatientsCard({super.key, this.refreshVersion = 0});

  @override
  State<RecentPatientsCard> createState() => _RecentPatientsCardState();
}

class _RecentPatientsCardState extends State<RecentPatientsCard> {
  List<PatientUiModel> _patients = [];
  int _totalCount = 0;

  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant RecentPatientsCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshVersion != widget.refreshVersion) {
      _load();
    }
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final auth = context.read<AuthProvider>();

      final service = PatientService(apiClient: auth.authService.apiClient);

      final result = await service.fetchRecentPatients(page: 1);

      if (!mounted) {
        return;
      }

      setState(() {
        _patients = result.patients;
        _totalCount = result.count;
        _isLoading = false;
      });

      debugPrint(
        '[DASHBOARD] 최근 본 환자 조회 완료: '
        '${result.patients.length}건 / total=${result.count}',
      );
    } catch (error) {
      debugPrint('[DASHBOARD] 최근 본 환자 조회 실패: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = '최근 본 환자를 불러오지 못했습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardSectionCard(
      title: '최근 본 환자',
      actionLabel: '전체보기',
      onAction: () {
        context.go('/patients');
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 10, 13, 12),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 170,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 1.8),
          ),
        ),
      );
    }

    if (_loadError != null) {
      return SizedBox(
        height: 170,
        child: Center(
          child: Text(
            _loadError!,
            style: TextStyle(fontSize: 9.5, color: context.appTextSecondary),
          ),
        ),
      );
    }

    if (_patients.isEmpty) {
      return SizedBox(
        height: 170,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_search_outlined,
                size: 24,
                color: context.appTextSecondary,
              ),
              const SizedBox(height: 7),
              Text(
                '최근 조회한 환자가 없습니다.',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '최근 조회 순',
              style: TextStyle(
                fontSize: 8.8,
                fontWeight: FontWeight.w600,
                color: context.appTextSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '총 $_totalCount명',
              style: TextStyle(
                fontSize: 8.8,
                fontWeight: FontWeight.w700,
                color: context.appTextSecondary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 7),

        for (final patient in _patients.take(4))
          _RecentPatientRow(
            patient: patient,
            onTap: () {
              context.go('/patients');
            },
          ),
      ],
    );
  }
}

class _RecentPatientRow extends StatelessWidget {
  final PatientUiModel patient;
  final VoidCallback onTap;

  const _RecentPatientRow({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final medicalRecordNo = patient.medicalRecordNo.trim().isEmpty
        ? '-'
        : patient.medicalRecordNo;

    final ageText = patient.age > 0 ? '${patient.age}세' : '나이 미상';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 3),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.appBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: context.appBrand,
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
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
                      '$medicalRecordNo · '
                      '${patient.gender} · $ageText',
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

              const SizedBox(width: 6),

              Icon(
                Icons.chevron_right_rounded,
                size: 15,
                color: context.appTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
