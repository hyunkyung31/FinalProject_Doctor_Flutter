import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';

import '../data/services/patient_service.dart';

import 'widgets/patient_detail_panel.dart';
import 'widgets/patient_detail_tabs.dart';
import 'widgets/patient_list_panel.dart';
import 'widgets/patient_responsive_layout.dart';

// ============================================================
// STEP 1. Patients Page
// 실제 Patient API 기반 화면
// ============================================================

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  // ============================================================
  // STEP 2. Patient Data
  // ============================================================

  List<PatientUiModel> _patients = [];

  bool _isLoading = true;

  String? _loadError;

  // ============================================================
  // STEP. Patient Timeline 상태
  // ============================================================

  List<PatientTimelineItem> _timelineItems = [];

  bool _isTimelineLoading = false;

  String? _timelineError;

  // ============================================================
  // STEP. 상세 필터 상태
  // ============================================================

  String? _birthDateFilter;

  // ============================================================
  // STEP 3. 검색 상태
  // ============================================================

  Timer? _searchDebounce;

  String _searchQuery = '';

  // Scope 변경 시 검색창을 초기화하기 위한 Key
  int _listPanelResetVersion = 0;

  // ============================================================
  // STEP 4. Patient List Scope
  // 전체 / 내 담당 / 협진 / 최근 조회
  // ============================================================

  PatientListScope _selectedScope = PatientListScope.all;

  // ============================================================
  // STEP 5. Pagination 상태
  // ============================================================

  int _currentPage = 1;

  int _totalCount = 0;

  bool _hasPreviousPage = false;

  bool _hasNextPage = false;

  bool _isPageLoading = false;

  // ============================================================
  // STEP. Compact Layout 상태
  // 세로 / 좁은 화면에서 List ↔ Detail 전환
  // ============================================================

  bool _showCompactDetail = false;

  // ============================================================
  // STEP 6. 화면 상태
  // ============================================================

  String? _selectedPatientId;

  PatientDetailTab _selectedTab = PatientDetailTab.overview;

  // ============================================================
  // STEP 7. 선택된 Patient
  // ============================================================

  PatientUiModel? get _selectedPatient {
    if (_selectedPatientId == null) {
      return null;
    }

    for (final patient in _patients) {
      if (patient.id == _selectedPatientId) {
        return patient;
      }
    }

    return null;
  }

  // ============================================================
  // STEP 8. Init
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPatients(page: 1);
    });
  }

  // ============================================================
  // STEP 9. Dispose
  // ============================================================

  @override
  void dispose() {
    _searchDebounce?.cancel();

    super.dispose();
  }

  // ============================================================
  // STEP 10. 전체 환자 목록 조회
  // GET /patients/?page={page}
  // ============================================================

  Future<void> _loadPatients({required int page}) async {
    try {
      if (mounted) {
        setState(() {
          _isPageLoading = true;
        });
      }

      final auth = context.read<AuthProvider>();

      final patientService = PatientService(
        apiClient: auth.authService.apiClient,
      );

      final result = await patientService.fetchPatientPage(page: page);

      if (!mounted) {
        return;
      }

      // 다른 Scope 또는 검색으로 이동한 경우
      // 이전 요청 결과는 반영하지 않음
      if (_selectedScope != PatientListScope.all || _searchQuery.isNotEmpty) {
        return;
      }

      setState(() {
        _patients = result.patients;

        _currentPage = page;
        _totalCount = result.count;
        _hasPreviousPage = result.hasPrevious;
        _hasNextPage = result.hasNext;

        _isLoading = false;
        _isPageLoading = false;
        _loadError = null;

        _selectedTab = PatientDetailTab.overview;

        if (_patients.isEmpty) {
          _selectedPatientId = null;
        } else {
          _selectedPatientId = _patients.first.id;
        }
      });

      debugPrint(
        '[PATIENTS] 전체 환자 목록 조회 완료: '
        'page=$page, '
        'pageCount=${result.patients.length}건, '
        'total=${result.count}건',
      );

      if (_patients.isNotEmpty) {
        await _loadPatientOverviewData(_patients.first);
      }
    } catch (error) {
      debugPrint(
        '[PATIENTS] 전체 환자 목록 조회 실패: '
        'page=$page, '
        'error=$error',
      );

      if (!mounted) {
        return;
      }

      if (_selectedScope != PatientListScope.all || _searchQuery.isNotEmpty) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isPageLoading = false;

        if (_patients.isEmpty) {
          _loadError = error.toString();
          _selectedPatientId = null;
        }
      });

      if (_patients.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('환자 목록을 불러오지 못했습니다.')));
      }
    }
  }

  // ============================================================
  // STEP. 생년월일 필터 환자 조회
  // GET /patients/?birth_date=YYYY-MM-DD
  // ============================================================

  Future<void> _loadPatientsByBirthDate({
    required String birthDate,
    required int page,
  }) async {
    try {
      if (mounted) {
        setState(() {
          _isPageLoading = true;
        });
      }

      final auth = context.read<AuthProvider>();

      final patientService = PatientService(
        apiClient: auth.authService.apiClient,
      );

      final result = await patientService.fetchPatientsByBirthDate(
        birthDate: birthDate,
        page: page,
      );

      if (!mounted || _birthDateFilter != birthDate) {
        return;
      }

      if (_birthDateFilter != birthDate) {
        return;
      }

      setState(() {
        _patients = result.patients;

        _currentPage = page;
        _totalCount = result.count;
        _hasPreviousPage = result.hasPrevious;
        _hasNextPage = result.hasNext;

        _isLoading = false;
        _isPageLoading = false;
        _loadError = null;

        _selectedTab = PatientDetailTab.overview;

        if (_patients.isEmpty) {
          _selectedPatientId = null;
        } else {
          _selectedPatientId = _patients.first.id;
        }
      });

      debugPrint(
        '[PATIENTS] 생년월일 필터 완료: '
        'birthDate=$birthDate, '
        'page=$page, '
        'pageCount=${result.patients.length}건, '
        'total=${result.count}건',
      );

      if (_patients.isNotEmpty) {
        await _loadPatientOverviewData(_patients.first);
      }
    } catch (error) {
      debugPrint(
        '[PATIENTS] 생년월일 필터 실패: '
        'birthDate=$birthDate, '
        'page=$page, '
        'error=$error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isPageLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('생년월일 조건으로 환자를 불러오지 못했습니다.')),
      );
    }
  }

  // ============================================================
  // STEP. API 날짜 형식
  // YYYY-MM-DD
  // ============================================================

  String _formatApiDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // ============================================================
  // STEP. 상세 필터 Dialog
  // 현재 단계: 생년월일
  // ============================================================

  Future<void> _openDetailFilter() async {
    DateTime? selectedDate;

    if (_birthDateFilter != null) {
      selectedDate = DateTime.tryParse(_birthDateFilter!);
    }

    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        DateTime? tempDate = selectedDate;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final dateText = tempDate == null
                ? '선택하지 않음'
                : _formatApiDate(tempDate!);

            return AlertDialog(
              title: const Text(
                '상세 필터',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '생년월일',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: tempDate ?? DateTime(1970, 1, 1),
                          firstDate: DateTime(1900, 1, 1),
                          lastDate: DateTime.now(),
                        );

                        if (pickedDate == null) {
                          return;
                        }

                        setDialogState(() {
                          tempDate = pickedDate;
                        });
                      },
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              size: 17,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dateText,
                              style: TextStyle(
                                fontSize: 12,
                                color: tempDate == null
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, '__RESET__');
                  },
                  child: const Text('초기화'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: tempDate == null
                      ? null
                      : () {
                          Navigator.pop(
                            dialogContext,
                            _formatApiDate(tempDate!),
                          );
                        },
                  child: const Text('적용'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    _searchDebounce?.cancel();

    // ==========================================================
    // 필터 초기화
    // ==========================================================

    if (result == '__RESET__') {
      setState(() {
        _birthDateFilter = null;
        _searchQuery = '';
        _selectedScope = PatientListScope.all;
        _listPanelResetVersion++;
        _currentPage = 1;
      });

      await _loadPatients(page: 1);

      return;
    }

    // ==========================================================
    // 생년월일 필터 적용
    // 상세 필터는 전체 환자를 기준으로 검색
    // ==========================================================

    setState(() {
      _birthDateFilter = result;
      _searchQuery = '';
      _selectedScope = PatientListScope.all;
      _listPanelResetVersion++;
      _currentPage = 1;
    });

    await _loadPatientsByBirthDate(birthDate: result, page: 1);
  }

  // ============================================================
  // STEP 11. 최근 조회 환자 목록
  // GET /me/recent-patients/?page={page}
  // ============================================================

  Future<void> _loadRecentPatients({required int page}) async {
    try {
      if (mounted) {
        setState(() {
          _isPageLoading = true;
        });
      }

      final auth = context.read<AuthProvider>();

      final patientService = PatientService(
        apiClient: auth.authService.apiClient,
      );

      final result = await patientService.fetchRecentPatients(page: page);

      if (!mounted) {
        return;
      }

      // 최근 조회 Scope를 벗어난 경우
      // 이전 요청 결과를 반영하지 않음
      if (_selectedScope != PatientListScope.recent) {
        return;
      }

      setState(() {
        _patients = result.patients;

        _currentPage = page;
        _totalCount = result.count;
        _hasPreviousPage = result.hasPrevious;
        _hasNextPage = result.hasNext;

        _isLoading = false;
        _isPageLoading = false;
        _loadError = null;

        _selectedTab = PatientDetailTab.overview;

        if (_patients.isEmpty) {
          _selectedPatientId = null;
        } else {
          _selectedPatientId = _patients.first.id;
        }
      });

      debugPrint(
        '[PATIENTS] 최근 조회 환자 목록 완료: '
        'page=$page, '
        'pageCount=${result.patients.length}건, '
        'total=${result.count}건',
      );

      if (_patients.isNotEmpty) {
        await _loadPatientOverviewData(_patients.first);
      }
    } catch (error) {
      debugPrint(
        '[PATIENTS] 최근 조회 환자 목록 실패: '
        'page=$page, '
        'error=$error',
      );

      if (!mounted) {
        return;
      }

      if (_selectedScope != PatientListScope.recent) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isPageLoading = false;

        if (_patients.isEmpty) {
          _loadError = error.toString();
          _selectedPatientId = null;
        }
      });

      if (_patients.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('최근 조회 환자를 불러오지 못했습니다.')));
      }
    }
  }

  // ============================================================
  // 내 담당 환자 목록
  // GET /patients/?assigned_to_me=true
  // ============================================================

  Future<void> _loadAssignedPatients({required int page}) async {
    try {
      if (mounted) {
        setState(() {
          _isPageLoading = true;
        });
      }

      final auth = context.read<AuthProvider>();

      final patientService = PatientService(
        apiClient: auth.authService.apiClient,
      );

      final result = await patientService.fetchAssignedPatientPage(page: page);

      if (!mounted) {
        return;
      }

      if (_selectedScope != PatientListScope.assigned) {
        return;
      }

      setState(() {
        _patients = result.patients;

        _currentPage = page;
        _totalCount = result.count;
        _hasPreviousPage = result.hasPrevious;
        _hasNextPage = result.hasNext;

        _isLoading = false;
        _isPageLoading = false;
        _loadError = null;

        _selectedTab = PatientDetailTab.overview;

        if (_patients.isEmpty) {
          _selectedPatientId = null;
        } else {
          _selectedPatientId = _patients.first.id;
        }
      });

      debugPrint(
        '[PATIENTS] 내 담당 환자 목록 조회 완료: '
        'page=$page, '
        'pageCount=${result.patients.length}건, '
        'total=${result.count}건',
      );

      if (_patients.isNotEmpty) {
        await _loadPatientOverviewData(_patients.first);
      }
    } catch (error) {
      debugPrint(
        '[PATIENTS] 내 담당 환자 목록 조회 실패: '
        'page=$page, '
        'error=$error',
      );

      if (!mounted || _selectedScope != PatientListScope.assigned) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isPageLoading = false;

        if (_patients.isEmpty) {
          _loadError = error.toString();
          _selectedPatientId = null;
        }
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('담당 환자를 불러오지 못했습니다.')));
    }
  }

  // ============================================================
  // STEP 12. Scope 변경
  // ============================================================

  void _changeScope(PatientListScope scope) {
    if (_selectedScope == scope) {
      return;
    }

    // ==========================================================
    // 협진 API는 Backend 수정 대기
    // ==========================================================

    if (scope == PatientListScope.consultation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('협진 환자 API는 Backend 수정 후 연결합니다.')),
      );
      return;
    }

    _searchDebounce?.cancel();

    setState(() {
      // Scope를 실제로 변경할 때만 상세 필터 해제
      _birthDateFilter = null;

      _selectedScope = scope;

      // 목록 범위를 바꾸면 검색 초기화
      _searchQuery = '';

      // 검색 TextField 초기화
      _listPanelResetVersion++;

      _currentPage = 1;
      _selectedPatientId = null;
      _selectedTab = PatientDetailTab.overview;

      // Compact에서는 목록으로 복귀
      _showCompactDetail = false;
    });

    if (scope == PatientListScope.assigned) {
      _loadAssignedPatients(page: 1);
      return;
    }

    if (scope == PatientListScope.recent) {
      _loadRecentPatients(page: 1);
      return;
    }

    _loadPatients(page: 1);
  }

  // ============================================================
  // STEP 13. 검색어 변경
  // 검색은 전체 환자를 대상으로 수행
  // ============================================================

  void _onSearchChanged(String value) {
    final query = value.trim();

    _searchDebounce?.cancel();

    // ==========================================================
    // 검색 시작
    // 검색은 전체 환자 기준이므로 Scope / 상세 필터 해제
    // ==========================================================

    if (query.isNotEmpty) {
      setState(() {
        _birthDateFilter = null;

        if (_selectedScope != PatientListScope.all) {
          _selectedScope = PatientListScope.all;
        }
      });
    }

    _searchQuery = query;

    // ==========================================================
    // 검색어 삭제
    // 전체 환자 목록으로 복귀
    // ==========================================================

    if (query.isEmpty) {
      _loadPatients(page: 1);
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _searchPatients(query, page: 1);
    });
  }

  // ============================================================
  // STEP 14. 실제 환자 검색
  // GET /patients/search/?q={query}&page={page}
  // ============================================================

  Future<void> _searchPatients(String query, {required int page}) async {
    try {
      if (mounted) {
        setState(() {
          _isPageLoading = true;
        });
      }

      final auth = context.read<AuthProvider>();

      final patientService = PatientService(
        apiClient: auth.authService.apiClient,
      );

      final result = await patientService.searchPatientPage(query, page: page);

      if (!mounted) {
        return;
      }

      if (_selectedScope != PatientListScope.all || _searchQuery != query) {
        return;
      }

      setState(() {
        _patients = result.patients;

        _currentPage = page;
        _totalCount = result.count;
        _hasPreviousPage = result.hasPrevious;
        _hasNextPage = result.hasNext;

        _isLoading = false;
        _isPageLoading = false;
        _loadError = null;

        _selectedTab = PatientDetailTab.overview;

        if (_patients.isEmpty) {
          _selectedPatientId = null;
        } else {
          _selectedPatientId = _patients.first.id;
        }
      });

      debugPrint(
        '[PATIENTS] 환자 검색 완료: '
        'query=$query, '
        'page=$page, '
        'pageCount=${result.patients.length}건, '
        'total=${result.count}건',
      );

      if (_patients.isNotEmpty) {
        await _loadPatientOverviewData(_patients.first);
      }
    } catch (error) {
      debugPrint(
        '[PATIENTS] 환자 검색 실패: '
        'query=$query, '
        'page=$page, '
        'error=$error',
      );

      if (!mounted) {
        return;
      }

      if (_selectedScope != PatientListScope.all ||
          _searchQuery.isNotEmpty ||
          _birthDateFilter != null) {
        return;
      }

      setState(() {
        _isPageLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('환자 검색 중 오류가 발생했습니다.')));
    }
  }

  // ============================================================
  // STEP 15. 이전 페이지
  // ============================================================

  void _goPreviousPage() {
    if (_isPageLoading || !_hasPreviousPage || _currentPage <= 1) {
      return;
    }

    final previousPage = _currentPage - 1;

    if (_birthDateFilter != null) {
      _loadPatientsByBirthDate(
        birthDate: _birthDateFilter!,
        page: previousPage,
      );
      return;
    }

    if (_selectedScope == PatientListScope.assigned) {
      _loadAssignedPatients(page: previousPage);
      return;
    }

    if (_selectedScope == PatientListScope.recent) {
      _loadRecentPatients(page: previousPage);
      return;
    }

    if (_searchQuery.isNotEmpty) {
      _searchPatients(_searchQuery, page: previousPage);
      return;
    }

    _loadPatients(page: previousPage);
  }

  // ============================================================
  // STEP 16. 다음 페이지
  // ============================================================

  void _goNextPage() {
    if (_isPageLoading || !_hasNextPage) {
      return;
    }

    final nextPage = _currentPage + 1;

    if (_birthDateFilter != null) {
      _loadPatientsByBirthDate(birthDate: _birthDateFilter!, page: nextPage);
      return;
    }

    if (_selectedScope == PatientListScope.assigned) {
      _loadAssignedPatients(page: nextPage);
      return;
    }

    if (_selectedScope == PatientListScope.recent) {
      _loadRecentPatients(page: nextPage);
      return;
    }

    if (_searchQuery.isNotEmpty) {
      _searchPatients(_searchQuery, page: nextPage);
      return;
    }

    _loadPatients(page: nextPage);
  }

  // ============================================================
  // STEP. 환자 Timeline 조회
  // GET /patients/{patientId}/timeline/
  // ============================================================

  Future<void> _loadPatientTimeline(PatientUiModel patient) async {
    final requestedPatientId = patient.patientId;

    setState(() {
      _isTimelineLoading = true;
      _timelineError = null;
    });

    try {
      final auth = context.read<AuthProvider>();

      final patientService = PatientService(
        apiClient: auth.authService.apiClient,
      );

      final result = await patientService.fetchPatientTimeline(
        requestedPatientId,
      );

      if (!mounted) {
        return;
      }

      // 조회 중 다른 환자로 이동했다면 이전 결과 무시
      if (_selectedPatient?.patientId != requestedPatientId) {
        return;
      }

      setState(() {
        _timelineItems = result;
        _isTimelineLoading = false;
        _timelineError = null;
      });

      debugPrint(
        '[PATIENTS] Timeline 조회 완료: '
        'patientId=$requestedPatientId, '
        'count=${result.length}',
      );
    } catch (error) {
      debugPrint(
        '[PATIENTS] Timeline 조회 실패: '
        'patientId=$requestedPatientId, '
        'error=$error',
      );

      if (!mounted || _selectedPatient?.patientId != requestedPatientId) {
        return;
      }

      setState(() {
        _timelineItems = [];
        _isTimelineLoading = false;
        _timelineError = error.toString();
      });
    }
  }

  // ============================================================
  // STEP. 환자 개요 데이터 조회
  // Integrated Data + Timeline
  // ============================================================

  Future<void> _loadPatientOverviewData(PatientUiModel patient) async {
    await Future.wait([
      _loadPatientIntegratedData(patient),
      _loadPatientTimeline(patient),
    ]);
  }

  // ============================================================
  // STEP 17. 선택 환자 통합 데이터 조회
  // GET /patients/{patientId}/integrated-data/
  // ============================================================

  Future<void> _loadPatientIntegratedData(PatientUiModel patient) async {
    try {
      final auth = context.read<AuthProvider>();

      final patientService = PatientService(
        apiClient: auth.authService.apiClient,
      );

      final updatedPatient = await patientService.fetchIntegratedPatient(
        patient,
      );

      if (!mounted) {
        return;
      }

      if (_selectedPatientId != patient.id) {
        return;
      }

      final index = _patients.indexWhere(
        (item) => item.patientId == patient.patientId,
      );

      if (index < 0) {
        return;
      }

      setState(() {
        _patients[index] = updatedPatient;
      });

      debugPrint(
        '[PATIENTS] 통합 데이터 조회 완료: '
        'patientId=${patient.patientId}, '
        'department=${updatedPatient.department}, '
        'doctor=${updatedPatient.doctorName}, '
        'labs=${updatedPatient.labMeasurementCount}, '
        'ct=${updatedPatient.ctStudyCount}, '
        'angio=${updatedPatient.angiographySequenceCount}',
      );
    } catch (error) {
      debugPrint(
        '[PATIENTS] 통합 데이터 조회 실패: '
        'patientId=${patient.patientId}, '
        'error=$error',
      );
    }
  }

  // ============================================================
  // STEP 18. 환자 조회 기록
  // POST /patients/{patientId}/view/
  // ============================================================

  Future<void> _recordPatientView(PatientUiModel patient) async {
    try {
      final auth = context.read<AuthProvider>();

      final patientService = PatientService(
        apiClient: auth.authService.apiClient,
      );

      await patientService.recordPatientView(patient.patientId);

      debugPrint(
        '[PATIENTS] 환자 조회 기록 완료: '
        'patientId=${patient.patientId}',
      );
    } catch (error) {
      debugPrint(
        '[PATIENTS] 환자 조회 기록 실패: '
        'patientId=${patient.patientId}, '
        'error=$error',
      );
    }
  }

  // ============================================================
  // STEP. 환자 선택
  // 가로: 상세 환자 변경
  // 세로: 환자 선택 후 상세 화면으로 이동
  // ============================================================

  void _selectPatient(PatientUiModel patient) {
    setState(() {
      _selectedPatientId = patient.id;
      _selectedTab = PatientDetailTab.overview;

      // Compact 화면에서는 상세 화면 표시
      _showCompactDetail = true;

      // 다른 환자의 Timeline 데이터 초기화
      _timelineItems = [];
      _isTimelineLoading = false;
      _timelineError = null;
    });

    _recordPatientView(patient);
    _loadPatientOverviewData(patient);
  }

  // ============================================================
  // STEP 20. Tab 변경
  // ============================================================

  void _changeTab(PatientDetailTab tab) {
    if (_selectedTab == tab) {
      return;
    }

    setState(() {
      _selectedTab = tab;
    });
  }

  // ============================================================
  // STEP. 환자 상세 → 검사 관리 이동
  // 선택한 환자 Context를 Query Parameter로 전달
  // ============================================================

  void _openExaminationManagement(PatientUiModel patient) {
    final uri = Uri(
      path: AppRoutes.examinations,
      queryParameters: {'patientId': patient.patientId.toString()},
    );

    context.go(uri.toString());
  }

  // ============================================================
  // STEP 21. Patient Detail 상태
  // ============================================================

  // ============================================================
  // STEP 21. Patient Detail 상태
  // ============================================================

  Widget _buildPatientDetail() {
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            '환자 정보를 불러오지 못했습니다.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final selectedPatient = _selectedPatient;

    if (selectedPatient == null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: const Text(
          '선택된 환자가 없습니다.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      );
    }

    // ==========================================================
    // 검사 결과 편집 권한
    // 간호사만 결과 입력 UI 사용
    // ==========================================================

    final authProvider = context.watch<AuthProvider>();
    final canEditLabResults = authProvider.isNurse;

    return PatientDetailPanel(
      patient: selectedPatient,
      selectedTab: _selectedTab,
      onTabChanged: _changeTab,
      timelineItems: _timelineItems,
      isTimelineLoading: _isTimelineLoading,
      timelineError: _timelineError,
      canEditLabResults: canEditLabResults,
      onOpenExaminationManagement: () {
        _openExaminationManagement(selectedPatient);
      },
    );
  }

  // ============================================================
  // STEP 22. UI
  // 가로 / 세로 Responsive Layout
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AppShell(
      pageTitle: '환자',
      selectedIndex: 1,
      body: Material(
        color: AppColors.background,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 900;

            return Container(
              color: AppColors.background,
              padding: isCompact
                  ? const EdgeInsets.fromLTRB(12, 8, 12, 12)
                  : const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: PatientResponsiveLayout(
                showCompactDetail: _showCompactDetail,
                onBackToList: () {
                  setState(() {
                    _showCompactDetail = false;
                  });
                },

                // ==================================================
                // Patient List
                // ==================================================
                patientList: PatientListPanel(
                  key: ValueKey(_listPanelResetVersion),
                  patients: _patients,
                  selectedPatientId: _selectedPatientId ?? '',
                  onPatientSelected: _selectPatient,
                  onSearchChanged: _onSearchChanged,
                  onDetailFilterTap: _openDetailFilter,

                  // Scope
                  selectedScope: _selectedScope,
                  onScopeChanged: _changeScope,

                  // Pagination
                  totalCount: _totalCount,
                  currentPage: _currentPage,
                  hasPreviousPage: _hasPreviousPage && !_isPageLoading,
                  hasNextPage: _hasNextPage && !_isPageLoading,
                  onPreviousPage: _goPreviousPage,
                  onNextPage: _goNextPage,
                ),

                // ==================================================
                // Patient Detail
                // ==================================================
                patientDetail: _buildPatientDetail(),
              ),
            );
          },
        ),
      ),
    );
  }
}
