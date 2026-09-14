import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';

import 'widgets/patient_detail_panel.dart';
import 'widgets/patient_detail_tabs.dart';
import 'widgets/patient_list_panel.dart';

// ============================================================
// STEP 1. Patients Page
// Mock Data 기반 1차 UI
// ============================================================

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  // ============================================================
  // STEP 2. Mock Patient Data
  // 추후 Backend API 연결 시 Service 데이터로 교체
  // ============================================================

  static const List<PatientUiModel> _patients = [
    PatientUiModel(
      id: 'P-20260428',
      name: '김OO',
      age: 68,
      gender: '남',
      department: '순환기내과',
      doctorName: '김OO 의사',
      careType: '외래',
      highRisk: true,
      aiPending: true,
      currentTask: 'CCTA 결과 상담',
      phone: '010-****-4281',
      primaryDiagnosis: '관상동맥질환 의심',
      riskFactors: '고혈압 · 이상지질혈증',
      allergy: '특이사항 없음',
      latestExam: 'CCTA',
      latestExamDate: '2026.09.11',
      aiSummary: 'LAD 협착 의심 · HIGH',
      nextAppointment: '2026.09.14 14:00 · 순환기내과 외래',
    ),

    PatientUiModel(
      id: 'P-20260391',
      name: '박OO',
      age: 78,
      gender: '여',
      department: '순환기내과',
      doctorName: '김OO 의사',
      careType: '외래',
      highRisk: false,
      aiPending: false,
      currentTask: '외래 진료',
      phone: '010-****-3912',
      primaryDiagnosis: '고혈압',
      riskFactors: '고혈압 · 고령',
      allergy: '없음',
      latestExam: '심전도 검사',
      latestExamDate: '2026.09.12',
      aiSummary: '특이 고위험 소견 없음',
      nextAppointment: '2026.09.26 10:30 · 경과 관찰',
    ),

    PatientUiModel(
      id: 'P-20260354',
      name: '이OO',
      age: 65,
      gender: '남',
      department: '순환기내과',
      doctorName: '김OO 의사',
      careType: '입원',
      highRisk: true,
      aiPending: true,
      currentTask: '영상의학과 협진',
      phone: '010-****-3547',
      primaryDiagnosis: '관상동맥 협착',
      riskFactors: '당뇨 · 흡연력',
      allergy: '조영제 주의',
      latestExam: '관상동맥 조영술',
      latestExamDate: '2026.09.12',
      aiSummary: 'RCA 중등도 협착 의심',
      nextAppointment: '2026.09.13 09:00 · 회진',
    ),

    PatientUiModel(
      id: 'P-20260287',
      name: '최OO',
      age: 71,
      gender: '남',
      department: '순환기내과',
      doctorName: '김OO 의사',
      careType: '외래',
      highRisk: false,
      aiPending: false,
      currentTask: '정기 추적 검사',
      phone: '010-****-2870',
      primaryDiagnosis: '안정형 협심증',
      riskFactors: '이상지질혈증',
      allergy: '없음',
      latestExam: '혈액 검사',
      latestExamDate: '2026.09.10',
      aiSummary: '이전 검사 대비 변화 없음',
      nextAppointment: '2026.10.02 15:00 · 정기 외래',
    ),

    PatientUiModel(
      id: 'P-20260241',
      name: '정OO',
      age: 59,
      gender: '여',
      department: '순환기내과',
      doctorName: '김OO 의사',
      careType: '외래',
      highRisk: false,
      aiPending: true,
      currentTask: 'AI 결과 검토',
      phone: '010-****-2415',
      primaryDiagnosis: '흉통 평가',
      riskFactors: '가족력',
      allergy: '없음',
      latestExam: 'CCTA',
      latestExamDate: '2026.09.09',
      aiSummary: 'LCX 경도 협착 가능성',
      nextAppointment: '2026.09.18 11:00 · 결과 상담',
    ),

    PatientUiModel(
      id: 'P-20260193',
      name: '한OO',
      age: 74,
      gender: '여',
      department: '심장혈관흉부외과',
      doctorName: '이OO 의사',
      careType: '입원',
      highRisk: true,
      aiPending: false,
      currentTask: '수술 전 평가',
      phone: '010-****-1936',
      primaryDiagnosis: '다혈관 관상동맥질환',
      riskFactors: '당뇨 · 고혈압',
      allergy: 'Penicillin',
      latestExam: '관상동맥 조영술',
      latestExamDate: '2026.09.11',
      aiSummary: '다혈관 병변 · 의료진 확인 완료',
      nextAppointment: '2026.09.13 08:00 · 수술 전 회진',
    ),

    PatientUiModel(
      id: 'P-20260152',
      name: '윤OO',
      age: 52,
      gender: '남',
      department: '순환기내과',
      doctorName: '김OO 의사',
      careType: '외래',
      highRisk: false,
      aiPending: false,
      currentTask: '검사 결과 확인',
      phone: '010-****-1529',
      primaryDiagnosis: '고지혈증',
      riskFactors: '이상지질혈증',
      allergy: '없음',
      latestExam: '혈액 검사',
      latestExamDate: '2026.09.08',
      aiSummary: 'AI 분석 대상 영상 없음',
      nextAppointment: '2026.10.07 13:30 · 외래 진료',
    ),
  ];

  // ============================================================
  // STEP 3. 화면 상태
  // ============================================================

  String _selectedPatientId = _patients.first.id;

  PatientDetailTab _selectedTab = PatientDetailTab.overview;

  // ============================================================
  // STEP 4. 선택된 Patient
  // ============================================================

  PatientUiModel get _selectedPatient {
    return _patients.firstWhere(
      (patient) => patient.id == _selectedPatientId,
      orElse: () => _patients.first,
    );
  }

  // ============================================================
  // STEP 5. 환자 선택
  // ============================================================

  void _selectPatient(PatientUiModel patient) {
    setState(() {
      _selectedPatientId = patient.id;

      // 환자를 변경하면 개요부터 표시
      _selectedTab = PatientDetailTab.overview;
    });
  }

  // ============================================================
  // STEP 6. Tab 변경
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
  // STEP 7. 화면
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AppShell(
      pageTitle: '환자',
      selectedIndex: 1,
      body: Material(
        color: AppColors.background,
        child: Container(
          color: AppColors.background,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==================================================
              // Left
              // Patient List
              // ==================================================
              Expanded(
                flex: 3,
                child: PatientListPanel(
                  patients: _patients,
                  selectedPatientId: _selectedPatientId,
                  onPatientSelected: _selectPatient,
                ),
              ),

              const SizedBox(width: 14),

              // ==================================================
              // Right
              // Patient Detail
              // ==================================================
              Expanded(
                flex: 7,
                child: PatientDetailPanel(
                  patient: _selectedPatient,
                  selectedTab: _selectedTab,
                  onTabChanged: _changeTab,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
