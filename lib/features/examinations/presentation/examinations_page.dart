import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/access_control.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/widgets/app_shell.dart';
import '../../patients/data/services/patient_service.dart';
import '../data/services/examination_service.dart';

import 'examination_ui_models.dart';
import 'widgets/examination_result_panel.dart';
import 'widgets/examination_section_tabs.dart';
import 'widgets/examination_worklist_panel.dart';

// ============================================================
// STEP 1. Examinations Page
// 환자 상세 > 검사 이력 화면에서 전달받을 Context 지원
// ============================================================

class ExaminationsPage extends StatefulWidget {
  final int? initialPatientId;
  final int? initialEncounterId;
  final int? initialOrderId;

  final bool openCreateOrder;

  const ExaminationsPage({
    super.key,
    this.initialPatientId,
    this.initialEncounterId,
    this.initialOrderId,
    this.openCreateOrder = false,
  });

  @override
  State<ExaminationsPage> createState() => _ExaminationsPageState();
}

class _ExaminationsPageState extends State<ExaminationsPage> {
  ExaminationSection _selectedSection = ExaminationSection.orders;

  List<ExaminationTypeUiModel> _types = [];
  List<ExaminationEncounterUiModel> _encounters = [];
  List<ExaminationPatientUiModel> _patients = [];

  List<ExaminationOrderUiModel> _orders = [];
  final List<ExaminationExecutionUiModel> _examinations = [];
  final List<ExaminationResultUiModel> _results = [];

  // ============================================================
  // 실제 API로 생성한 검사 수행 목록
  // ============================================================

  final List<ExaminationExecutionUiModel> _realExaminations = [];

  final Set<int> _loadedExecutionOrderIds = <int>{};
  final Set<int> _loadingExecutionOrderIds = <int>{};

  final Map<int, int> _realResultIdByExaminationId = <int, int>{};
  final Map<int, String> _realResultStatusByExaminationId = <int, String>{};

  final Set<int> _loadedResultExaminationIds = <int>{};
  final Set<int> _loadingResultExaminationIds = <int>{};

  bool _isTypeLoading = false;
  bool _isEncounterLoading = false;
  bool _isPatientLoading = false;

  // ============================================================
  // STEP. 검사 관리 초기 로딩
  // 실제 환자 / Encounter / Order 준비 전 Mock UI 노출 방지
  // ============================================================

  bool _isInitialDataLoading = true;

  // ============================================================
  // STEP. 환자 화면에서 전달된 Context 여부
  // ============================================================

  bool get _hasPatientContext => widget.initialPatientId != null;

  // ============================================================
  // STEP. 환자 Context 기준 검사 오더
  // 환자 상세에서 진입한 경우 해당 환자의 오더만 표시
  // 사이드바에서 직접 진입한 경우 전체 오더 표시
  // ============================================================

  List<ExaminationOrderUiModel> get _contextOrders {
    final patientId = widget.initialPatientId;

    if (patientId == null) {
      return _orders;
    }

    final encounterIds = <int>{};

    for (final encounter in _encounters) {
      if (encounter.patientId == patientId) {
        encounterIds.add(encounter.id);
      }
    }

    return _orders
        .where((order) => encounterIds.contains(order.encounterId))
        .toList();
  }

  ExaminationPatientUiModel? get _contextPatient {
    final patientId = widget.initialPatientId;

    if (patientId == null) {
      return null;
    }

    for (final patient in _patients) {
      if (patient.id == patientId) {
        return patient;
      }
    }

    return null;
  }

  // ============================================================
  // STEP 5. Init
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await Future.wait([
          _loadExaminationTypes(),
          _loadEncounters(),
          _loadExaminationPatients(),
        ]);

        await _loadExaminationOrdersSafely();
      } finally {
        if (mounted) {
          setState(() {
            _isInitialDataLoading = false;
          });
        }
      }
    });
  }

  // ============================================================
  // STEP. 실제 검사 화면 환자 전체 조회
  // GET /api/patients/?page=N
  // ============================================================

  Future<void> _loadExaminationPatients() async {
    if (_isPatientLoading) {
      return;
    }

    setState(() {
      _isPatientLoading = true;
    });

    try {
      final auth = context.read<AuthProvider>();

      final patientService = PatientService(
        apiClient: auth.authService.apiClient,
      );

      final allPatients = <ExaminationPatientUiModel>[];

      var page = 1;
      var hasNext = true;
      var totalCount = 0;

      while (hasNext) {
        final result = await patientService.fetchPatientPage(page: page);

        totalCount = result.count;

        allPatients.addAll(
          result.patients.map(
            (patient) => ExaminationPatientUiModel(
              id: patient.patientId,
              name: patient.name,
              age: patient.age,
              gender: patient.gender,
            ),
          ),
        );

        hasNext = result.hasNext;
        page += 1;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _patients = allPatients;
      });

      debugPrint(
        '[ExaminationsPage] 실제 환자 '
        '${allPatients.length}건 조회 완료 '
        '(전체 $totalCount건)',
      );
    } catch (error) {
      debugPrint('[ExaminationsPage] 환자 조회 실패: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isPatientLoading = false;
        });
      }
    }
  }

  // ============================================================
  // STEP. 실제 검사 오더 안전 조회
  // 현재 접근 가능한 Patient와 연결되는 Order만 화면에 반영
  // ============================================================

  Future<void> _loadExaminationOrdersSafely() async {
    try {
      final auth = context.read<AuthProvider>();

      final examinationService = ExaminationService(
        apiClient: auth.authService.apiClient,
      );

      final orders = await examinationService.fetchExaminationOrders();

      final typeIds = _types.map((item) => item.id).toSet();

      final encounterMap = {
        for (final encounter in _encounters) encounter.id: encounter,
      };

      final patientIds = _patients.map((item) => item.id).toSet();

      final validOrders = <ExaminationOrderUiModel>[];

      var missingTypeCount = 0;
      var missingEncounterCount = 0;
      var missingPatientCount = 0;

      for (final order in orders) {
        // ========================================================
        // 검사 종류 확인
        // ========================================================

        if (!typeIds.contains(order.examinationTypeId)) {
          missingTypeCount += 1;
          continue;
        }

        // ========================================================
        // Encounter 확인
        // ========================================================

        final encounter = encounterMap[order.encounterId];

        if (encounter == null) {
          missingEncounterCount += 1;
          continue;
        }

        // ========================================================
        // 현재 접근 가능한 Patient 확인
        // ========================================================

        if (!patientIds.contains(encounter.patientId)) {
          missingPatientCount += 1;
          continue;
        }

        validOrders.add(order);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _orders = validOrders;
      });

      debugPrint(
        '[ExaminationsPage] 실제 검사 오더 '
        '${orders.length}건 조회 완료',
      );

      debugPrint(
        '[ExaminationsPage] 화면 표시 가능 오더 '
        '${validOrders.length}건',
      );

      debugPrint(
        '[ExaminationsPage] 제외 오더 - '
        'type=$missingTypeCount, '
        'encounter=$missingEncounterCount, '
        'patient=$missingPatientCount',
      );
    } catch (error) {
      debugPrint('[ExaminationsPage] 실제 검사 오더 조회 실패: $error');
    }
  }

  Future<void> _loadExecutionsForOrder(ExaminationOrderUiModel order) async {
    final orderId = order.id;

    if (_loadedExecutionOrderIds.contains(orderId) ||
        _loadingExecutionOrderIds.contains(orderId)) {
      return;
    }

    ExaminationTypeUiModel? orderType;

    for (final type in _types) {
      if (type.id == order.examinationTypeId) {
        orderType = type;
        break;
      }
    }

    if (orderType == null) {
      return;
    }

    _loadingExecutionOrderIds.add(orderId);

    try {
      final auth = context.read<AuthProvider>();

      final examinationService = ExaminationService(
        apiClient: auth.authService.apiClient,
      );

      final executions = await examinationService
          .fetchExaminationExecutionsByOrder(orderId);

      if (!mounted) {
        return;
      }

      setState(() {
        _realExaminations.removeWhere(
          (examination) => examination.orderId == orderId,
        );

        _realExaminations.addAll(executions);

        _realExaminations.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        _loadedExecutionOrderIds.add(orderId);
      });

      debugPrint(
        '[ExaminationsPage] 오더 #$orderId Execution '
        '${executions.length}건 조회 완료',
      );

      for (final examination in executions) {
        await _loadResultsForExamination(examination.id);
      }
    } catch (error) {
      debugPrint('[ExaminationsPage] 오더 #$orderId Execution 조회 실패: $error');
    } finally {
      _loadingExecutionOrderIds.remove(orderId);
    }
  }

  Future<void> _loadResultsForExamination(int examinationId) async {
    if (_loadedResultExaminationIds.contains(examinationId) ||
        _loadingResultExaminationIds.contains(examinationId)) {
      return;
    }

    _loadingResultExaminationIds.add(examinationId);

    try {
      final auth = context.read<AuthProvider>();

      final response = await auth.authService.apiClient.dio.get(
        '/examinations/$examinationId/results/',
      );

      final responseData = response.data;

      if (responseData is! List) {
        throw const FormatException('검사 결과 응답 형식이 올바르지 않습니다.');
      }

      final results = responseData
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      // 정정 결과가 여러 버전 존재할 수 있으므로 최신 version을 우선 사용
      results.sort((a, b) {
        final versionA = (a['version'] as num?)?.toInt() ?? 0;
        final versionB = (b['version'] as num?)?.toInt() ?? 0;

        final versionCompare = versionB.compareTo(versionA);

        if (versionCompare != 0) {
          return versionCompare;
        }

        final createdAtA =
            DateTime.tryParse(a['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);

        final createdAtB =
            DateTime.tryParse(b['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);

        return createdAtB.compareTo(createdAtA);
      });

      final latestResult = results.isEmpty ? null : results.first;

      if (!mounted) {
        return;
      }

      setState(() {
        _realResultIdByExaminationId.remove(examinationId);
        _realResultStatusByExaminationId.remove(examinationId);

        if (latestResult != null) {
          final resultId = (latestResult['id'] as num?)?.toInt();
          final status = latestResult['status']?.toString().toUpperCase();

          if (resultId != null) {
            _realResultIdByExaminationId[examinationId] = resultId;
          }

          if (status != null && status.isNotEmpty) {
            _realResultStatusByExaminationId[examinationId] = status;
          }
        }

        _loadedResultExaminationIds.add(examinationId);
      });

      final resultId = _realResultIdByExaminationId[examinationId];
      final resultStatus = _realResultStatusByExaminationId[examinationId];

      debugPrint(
        '[ExaminationsPage] Examination #$examinationId Result 조회 완료: '
        'resultId=${resultId ?? '없음'}, '
        'status=${resultStatus ?? '없음'}',
      );
    } catch (error) {
      debugPrint(
        '[ExaminationsPage] Examination #$examinationId Result 조회 실패: $error',
      );
    } finally {
      _loadingResultExaminationIds.remove(examinationId);
    }
  }

  // ============================================================
  // STEP 6. 실제 검사 종류 조회
  // GET /api/examinations/types/
  // ============================================================

  Future<void> _loadExaminationTypes() async {
    if (_isTypeLoading) {
      return;
    }

    setState(() {
      _isTypeLoading = true;
    });

    try {
      final auth = context.read<AuthProvider>();

      final examinationService = ExaminationService(
        apiClient: auth.authService.apiClient,
      );

      final types = await examinationService.fetchExaminationTypes();

      if (!mounted) {
        return;
      }

      setState(() {
        _types = types;
      });

      debugPrint('[ExaminationsPage] 실제 검사 종류 ${types.length}건 조회 완료');
    } catch (error) {
      if (!mounted) {
        return;
      }

      debugPrint('[ExaminationsPage] 검사 종류 조회 실패: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isTypeLoading = false;
        });
      }
    }
  }

  // ============================================================
  // STEP 7. 실제 Encounter 조회
  // GET /api/encounters/
  // ============================================================

  Future<void> _loadEncounters() async {
    if (_isEncounterLoading) {
      return;
    }

    setState(() {
      _isEncounterLoading = true;
    });

    try {
      final auth = context.read<AuthProvider>();

      final examinationService = ExaminationService(
        apiClient: auth.authService.apiClient,
      );

      final encounters = await examinationService.fetchEncounters();

      if (!mounted) {
        return;
      }

      setState(() {
        _encounters = encounters;
      });

      debugPrint('[ExaminationsPage] 실제 Encounter ${encounters.length}건 조회 완료');
    } catch (error) {
      debugPrint('[ExaminationsPage] Encounter 조회 실패: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isEncounterLoading = false;
        });
      }
    }
  }

  // ============================================================
  // STEP 6. Role UI
  //
  // 현재 단계:
  // - 의사 : 오더 / 결과확정 UI
  // - 간호사 : 검사 수행 UI
  //
  // 실제 API 연결 시 Backend Permission을 최종 기준으로 변경
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final isDoctor = auth.role == UserRole.doctor;

    final isNurse = auth.role == UserRole.nurse;

    return AppShell(
      pageTitle: '검사 관리',
      selectedIndex: 3,
      body: Material(
        color: context.appBackground,
        child: Container(
          color: context.appBackground,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: _isInitialDataLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ============================================================
                    // 환자 상세 > 검사 이력에서 진입한 경우 Context 표시
                    // ============================================================
                    if (_hasPatientContext && _contextPatient != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: context.appSurfaceSoft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: context.appBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 18,
                              color: context.appBrand,
                            ),

                            const SizedBox(width: 9),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_contextPatient!.name} 환자의 검사 관리',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: context.appTextPrimary,
                                    ),
                                  ),

                                  const SizedBox(height: 2),

                                  Text(
                                    '환자 상세의 검사 이력에서 이동했습니다.',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: context.appTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Text(
                              _contextPatient!.id.toString(),
                              style: TextStyle(
                                fontSize: 10.5,
                                color: context.appTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),
                    ],

                    // ==================================================
                    // Section Tabs
                    // ==================================================
                    ExaminationSectionTabs(
                      selectedSection: _selectedSection,
                      onChanged: (section) {
                        setState(() {
                          _selectedSection = section;
                        });
                      },
                    ),

                    const SizedBox(height: 10),

                    // ==================================================
                    // Content
                    // ==================================================
                    Expanded(
                      child: _buildSection(
                        isDoctor: isDoctor,
                        isNurse: isNurse,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP 7. Selected Section
  // ============================================================

  Widget _buildSection({required bool isDoctor, required bool isNurse}) {
    switch (_selectedSection) {
      case ExaminationSection.orders:
        return ExaminationWorklistPanel(
          key: ValueKey(widget.initialPatientId ?? 'all'),
          orders: _contextOrders,
          examinations: _realExaminations,
          types: _types,
          encounters: _encounters,
          patients: _patients,
          resultStatusByExaminationId: _realResultStatusByExaminationId,
          loadedResultExaminationIds: _loadedResultExaminationIds,

          initialPatientId: widget.initialPatientId,
          initialEncounterId: widget.initialEncounterId,
          initialOrderId: widget.initialOrderId,

          autoSelectFirstOrder: _hasPatientContext,
          openCreateOrder: widget.openCreateOrder,

          canOrder: isDoctor,
          canPerform: isDoctor,
          canEditProcedureNursing: isNurse,

          onCreateOrder: _createExaminationOrder,
          onUpdateOrder: _updateExaminationOrder,
          onOrderSelected: _loadExecutionsForOrder,

          onSchedule: (order) {
            _scheduleOrder(order);
          },

          onCancel: (order) {
            _cancelOrder(order);
          },

          onPrepareExecution: _prepareExaminationExecution,

          onStart: _startExamination,
          onComplete: _completeExamination,
          onFail: _failExamination,
        );

      case ExaminationSection.results:
        return ExaminationResultPanel(
          results: _results,
          examinations: _examinations,
          orders: _orders,
          types: _types,
          encounters: _encounters,
          patients: _patients,

          canFinalize: isDoctor,
          onFinalize: _finalizeResult,
        );
    }
  }

  Future<ExaminationOrderUiModel?> _createExaminationOrder({
    required int encounterId,
    required int examinationTypeId,
    required String priority,
    required String clinicalNote,
  }) async {
    try {
      final auth = context.read<AuthProvider>();

      final examinationService = ExaminationService(
        apiClient: auth.authService.apiClient,
      );

      final createdOrder = await examinationService.createExaminationOrder(
        encounterId: encounterId,
        examinationTypeId: examinationTypeId,
        priority: priority,
        clinicalNote: clinicalNote,
      );

      if (!mounted) {
        return null;
      }

      setState(() {
        _orders = [
          createdOrder,
          ..._orders.where((order) => order.id != createdOrder.id),
        ];
      });

      _showMessage('검사 오더 #${createdOrder.id}가 생성되었습니다.');

      debugPrint(
        '[ExaminationsPage] 검사 오더 생성 완료: '
        'orderId=${createdOrder.id}, '
        'encounterId=${createdOrder.encounterId}, '
        'typeId=${createdOrder.examinationTypeId}',
      );

      return createdOrder;
    } catch (error) {
      debugPrint('[ExaminationsPage] 검사 오더 생성 실패: $error');

      return null;
    }
  }

  Future<ExaminationOrderUiModel?> _updateExaminationOrder({
    required int orderId,
    required String priority,
    required String clinicalNote,
  }) async {
    try {
      final auth = context.read<AuthProvider>();

      final examinationService = ExaminationService(
        apiClient: auth.authService.apiClient,
      );

      final updatedOrder = await examinationService.updateExaminationOrder(
        orderId: orderId,
        priority: priority,
        clinicalNote: clinicalNote,
      );

      if (!mounted) {
        return null;
      }

      setState(() {
        _orders = _orders.map((order) {
          return order.id == updatedOrder.id ? updatedOrder : order;
        }).toList();
      });

      _showMessage('검사 오더 #${updatedOrder.id}가 수정되었습니다.');

      debugPrint(
        '[ExaminationsPage] 검사 오더 수정 완료: '
        'orderId=${updatedOrder.id}, '
        'priority=${updatedOrder.priority}',
      );

      return updatedOrder;
    } catch (error) {
      debugPrint('[ExaminationsPage] 검사 오더 수정 실패: $error');

      if (mounted) {
        _showMessage('검사 오더를 수정하지 못했습니다.');
      }

      return null;
    }
  }

  // ============================================================
  // STEP. 실제 검사 수행 준비
  //
  // 대상:
  // - IMAGING
  // - PROCEDURE
  //
  // LAB:
  // - Execution 수행 흐름 사용하지 않음
  // - 추후 간호사 결과 입력 Workflow로 연결
  // ============================================================

  Future<void> _prepareExaminationExecution(
    ExaminationOrderUiModel order,
  ) async {
    ExaminationTypeUiModel? selectedType;

    for (final type in _types) {
      if (type.id == order.examinationTypeId) {
        selectedType = type;
        break;
      }
    }

    if (selectedType == null) {
      _showMessage('검사 종류 정보를 찾을 수 없습니다.');
      return;
    }

    if (selectedType.category == 'LAB') {
      _showMessage('혈액 검사는 결과 입력 Workflow를 사용합니다.');
      return;
    }

    // ============================================================
    // STEP. 기본 검사 장소
    // ============================================================

    String defaultLocation;

    switch (selectedType.code) {
      case 'ANGIO_2D':
      case 'ANGIOGRAPHY':
        defaultLocation = '혈관조영실';
        break;

      case 'CCTA':
      case 'CCTA_3D':
        defaultLocation = 'CT 촬영실';
        break;

      default:
        defaultLocation = selectedType.category == 'PROCEDURE'
            ? '시술실'
            : '영상검사실';
    }

    final scheduledLocation = order.scheduledLocation?.trim();

    final initialLocation =
        scheduledLocation != null && scheduledLocation.isNotEmpty
        ? scheduledLocation
        : defaultLocation;

    String locationValue = initialLocation;

    final location = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            '검사 수행 준비',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 420,
            child: TextFormField(
              initialValue: initialLocation,
              onChanged: (value) {
                locationValue = value;
              },
              decoration: const InputDecoration(
                labelText: '검사 장소',
                hintText: '검사 장소를 입력하세요.',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                FocusScope.of(dialogContext).unfocus();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                final value = locationValue.trim();

                if (value.isEmpty) {
                  return;
                }

                FocusScope.of(dialogContext).unfocus();
                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('수행 준비'),
            ),
          ],
        );
      },
    );

    if (location == null || location.trim().isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    try {
      final auth = context.read<AuthProvider>();

      final examinationService = ExaminationService(
        apiClient: auth.authService.apiClient,
      );

      final createdExamination = await examinationService
          .createExaminationExecution(
            orderId: order.id,
            location: location,
            attemptNo: 1,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _realExaminations.removeWhere(
          (item) => item.id == createdExamination.id,
        );

        _realExaminations.insert(0, createdExamination);

        _loadedExecutionOrderIds.add(order.id);

        _selectedSection = ExaminationSection.orders;
      });

      // Backend에서 Order 상태가 함께 변경될 수 있으므로 다시 조회
      await _loadExaminationOrdersSafely();

      if (!mounted) {
        return;
      }

      _showMessage('검사 수행 #${createdExamination.id}가 준비되었습니다.');
    } catch (error) {
      debugPrint('[ExaminationsPage] 검사 수행 생성 실패: $error');

      if (mounted) {
        _showMessage('검사 수행을 준비하지 못했습니다.');
      }
    }
  }

  // ============================================================
  // STEP 8. Mock Order Action
  // ============================================================

  void _scheduleOrder(ExaminationOrderUiModel order) {
    final index = _orders.indexWhere((item) => item.id == order.id);

    if (index < 0) {
      return;
    }

    setState(() {
      _orders[index] = order.copyWith(
        scheduledAt: DateTime(2026, 9, 15, 10, 0),
        scheduledLocation: '검사실',
      );
    });

    _showMessage('검사 일정이 UI에 반영되었습니다. 실제 API는 아직 연결하지 않았습니다.');
  }

  void _cancelOrder(ExaminationOrderUiModel order) {
    final index = _orders.indexWhere((item) => item.id == order.id);

    if (index < 0) {
      return;
    }

    setState(() {
      _orders[index] = order.copyWith(
        status: 'CANCELED',
        canceledAt: DateTime.now(),
        cancelReason: 'UI 테스트 취소',
      );
    });

    _showMessage('검사 오더가 UI에서 취소 처리되었습니다.');
  }

  // ============================================================
  // STEP. 실제 검사 수행 Action
  // SCHEDULED → IN_PROGRESS → COMPLETED / FAILED
  // ============================================================

  Future<void> _startExamination(
    ExaminationExecutionUiModel examination,
  ) async {
    try {
      final auth = context.read<AuthProvider>();

      final examinationService = ExaminationService(
        apiClient: auth.authService.apiClient,
      );

      final updated = await examinationService.startExaminationExecution(
        examination.id,
      );

      if (!mounted) {
        return;
      }

      _updateRealExamination(updated);

      await _loadExaminationOrdersSafely();

      if (mounted) {
        _showMessage('검사를 시작했습니다.');
      }
    } catch (error) {
      debugPrint('[ExaminationsPage] 검사 시작 실패: $error');

      if (mounted) {
        _showMessage('검사를 시작하지 못했습니다.');
      }
    }
  }

  // ============================================================
  // STEP. 실제 검사 완료
  // ============================================================

  Future<void> _completeExamination(
    ExaminationExecutionUiModel examination,
  ) async {
    try {
      final auth = context.read<AuthProvider>();

      final examinationService = ExaminationService(
        apiClient: auth.authService.apiClient,
      );

      final updated = await examinationService.completeExaminationExecution(
        examination.id,
      );

      if (!mounted) {
        return;
      }

      _updateRealExamination(updated);

      await _loadExaminationOrdersSafely();

      if (mounted) {
        _showMessage('검사가 완료 처리되었습니다.');
      }
    } catch (error) {
      debugPrint('[ExaminationsPage] 검사 완료 실패: $error');

      if (mounted) {
        _showMessage('검사를 완료 처리하지 못했습니다.');
      }
    }
  }

  // ============================================================
  // STEP. 실제 검사 실패
  // 실패 사유 입력 후 Backend 반영
  // ============================================================

  Future<void> _failExamination(ExaminationExecutionUiModel examination) async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            '검사 실패 처리',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 420,
            child: TextField(
              controller: reasonController,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '실패 사유',
                hintText: '검사 실패 또는 중단 사유를 입력하세요.',
                border: OutlineInputBorder(),
              ),
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
                final value = reasonController.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('실패 처리'),
            ),
          ],
        );
      },
    );

    reasonController.dispose();

    if (reason == null || reason.trim().isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    try {
      final auth = context.read<AuthProvider>();

      final examinationService = ExaminationService(
        apiClient: auth.authService.apiClient,
      );

      final updated = await examinationService.failExaminationExecution(
        examinationId: examination.id,
        reason: reason,
      );

      if (!mounted) {
        return;
      }

      _updateRealExamination(updated);

      await _loadExaminationOrdersSafely();

      if (mounted) {
        _showMessage('검사가 실패 상태로 변경되었습니다.');
      }
    } catch (error) {
      debugPrint('[ExaminationsPage] 검사 실패 처리 오류: $error');

      if (mounted) {
        _showMessage('검사 실패 처리를 완료하지 못했습니다.');
      }
    }
  }

  // ============================================================
  // STEP. 실제 Execution 상태 갱신
  // ============================================================

  void _updateRealExamination(ExaminationExecutionUiModel updated) {
    final index = _realExaminations.indexWhere((item) => item.id == updated.id);

    setState(() {
      if (index < 0) {
        _realExaminations.insert(0, updated);
      } else {
        _realExaminations[index] = updated;
      }
    });
  }

  // ============================================================
  // STEP 10. Mock Finalize
  // ============================================================

  void _finalizeResult(ExaminationResultUiModel result) {
    final index = _results.indexWhere((item) => item.id == result.id);

    if (index < 0) {
      return;
    }

    setState(() {
      _results[index] = result.copyWith(
        status: 'FINAL',
        confirmedAt: DateTime.now(),
        confirmedBy: 3,
      );
    });

    _showMessage('검사 결과가 최종 확정되었습니다.');
  }

  // ============================================================
  // STEP 11. Message
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }
}
