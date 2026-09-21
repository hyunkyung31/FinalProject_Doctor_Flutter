// ============================================================
// STEP 1. Clinical AI 입력 필드 타입
// ============================================================

enum ClinicalFieldType { number, binary, select }

// ============================================================
// STEP 2. Clinical AI 선택 옵션
// ============================================================

class ClinicalFieldOption {
  final dynamic value;
  final String label;

  const ClinicalFieldOption({required this.value, required this.label});
}

// ============================================================
// STEP 3. Clinical AI 입력 필드
// ============================================================

class ClinicalFieldDefinition {
  final String name;
  final String label;
  final String group;
  final ClinicalFieldType type;
  final double? step;
  final List<ClinicalFieldOption> options;

  const ClinicalFieldDefinition({
    required this.name,
    required this.label,
    required this.group,
    required this.type,
    this.step,
    this.options = const [],
  });
}

// ============================================================
// STEP 4. 공통 선택 옵션
// ============================================================

// 질환 / 과거력
const clinicalDiseaseOptions = [
  ClinicalFieldOption(value: 1, label: '있음'),
  ClinicalFieldOption(value: 0, label: '없음'),
];

// 증상 / 소견 / 행동 여부
const clinicalBinaryOptions = [
  ClinicalFieldOption(value: 1, label: '예'),
  ClinicalFieldOption(value: 0, label: '아니오'),
];

// 성별
const clinicalSexOptions = [
  ClinicalFieldOption(value: 1, label: '남자'),
  ClinicalFieldOption(value: 0, label: '여자'),
];

// BBB
const clinicalBbbOptions = [
  ClinicalFieldOption(value: 'N', label: '없음'),
  ClinicalFieldOption(value: 'LBBB', label: 'LBBB'),
  ClinicalFieldOption(value: 'RBBB', label: 'RBBB'),
];

// VHD
const clinicalVhdOptions = [
  ClinicalFieldOption(value: 'N', label: '없음'),
  ClinicalFieldOption(value: 'mild', label: '경도'),
  ClinicalFieldOption(value: 'Moderate', label: '중등도'),
  ClinicalFieldOption(value: 'Severe', label: '중증'),
];

// ============================================================
// STEP 5. Clinical AI 54개 입력 변수
//
// Backend key 이름은 모델 입력과 연결되므로 변경하지 않는다.
// ============================================================

const clinicalAiFields = <ClinicalFieldDefinition>[
  // ----------------------------------------------------------
  // 기본 정보 - 5
  // ----------------------------------------------------------
  ClinicalFieldDefinition(
    name: 'Age',
    label: '나이',
    group: '기본 정보',
    type: ClinicalFieldType.number,
  ),
  ClinicalFieldDefinition(
    name: 'Weight',
    label: '체중 (kg)',
    group: '기본 정보',
    type: ClinicalFieldType.number,
    step: 0.1,
  ),
  ClinicalFieldDefinition(
    name: 'Length',
    label: '신장 (cm)',
    group: '기본 정보',
    type: ClinicalFieldType.number,
    step: 0.1,
  ),
  ClinicalFieldDefinition(
    name: 'Sex',
    label: '성별',
    group: '기본 정보',
    type: ClinicalFieldType.select,
    options: clinicalSexOptions,
  ),
  ClinicalFieldDefinition(
    name: 'BMI',
    label: 'BMI',
    group: '기본 정보',
    type: ClinicalFieldType.number,
    step: 0.01,
  ),

  // ----------------------------------------------------------
  // 병력 및 위험인자 - 12
  //
  // 질환       → 있음 / 없음
  // 흡연·가족력 → 예 / 아니오
  // ----------------------------------------------------------
  ClinicalFieldDefinition(
    name: 'DM',
    label: '당뇨',
    group: '병력 및 위험인자',
    type: ClinicalFieldType.binary,
    options: clinicalDiseaseOptions,
  ),
  ClinicalFieldDefinition(
    name: 'HTN',
    label: '고혈압',
    group: '병력 및 위험인자',
    type: ClinicalFieldType.binary,
    options: clinicalDiseaseOptions,
  ),
  ClinicalFieldDefinition(
    name: 'Current Smoker',
    label: '현재 흡연',
    group: '병력 및 위험인자',
    type: ClinicalFieldType.binary,
    options: clinicalBinaryOptions,
  ),
  ClinicalFieldDefinition(
    name: 'EX-Smoker',
    label: '과거 흡연',
    group: '병력 및 위험인자',
    type: ClinicalFieldType.binary,
    options: clinicalBinaryOptions,
  ),
  ClinicalFieldDefinition(
    name: 'FH',
    label: '심혈관 가족력',
    group: '병력 및 위험인자',
    type: ClinicalFieldType.binary,
    options: clinicalBinaryOptions,
  ),
  ClinicalFieldDefinition(
    name: 'Obesity',
    label: '비만',
    group: '병력 및 위험인자',
    type: ClinicalFieldType.binary,
    options: clinicalDiseaseOptions,
  ),
  ClinicalFieldDefinition(
    name: 'CRF',
    label: '만성 신부전',
    group: '병력 및 위험인자',
    type: ClinicalFieldType.binary,
    options: clinicalDiseaseOptions,
  ),
  ClinicalFieldDefinition(
    name: 'CVA',
    label: '뇌혈관질환',
    group: '병력 및 위험인자',
    type: ClinicalFieldType.binary,
    options: clinicalDiseaseOptions,
  ),
  ClinicalFieldDefinition(
    name: 'Airway disease',
    label: '기도 질환',
    group: '병력 및 위험인자',
    type: ClinicalFieldType.binary,
    options: clinicalDiseaseOptions,
  ),
  ClinicalFieldDefinition(
    name: 'Thyroid Disease',
    label: '갑상선 질환',
    group: '병력 및 위험인자',
    type: ClinicalFieldType.binary,
    options: clinicalDiseaseOptions,
  ),
  ClinicalFieldDefinition(
    name: 'CHF',
    label: '심부전',
    group: '병력 및 위험인자',
    type: ClinicalFieldType.binary,
    options: clinicalDiseaseOptions,
  ),
  ClinicalFieldDefinition(
    name: 'DLP',
    label: '이상지질혈증',
    group: '병력 및 위험인자',
    type: ClinicalFieldType.binary,
    options: clinicalDiseaseOptions,
  ),

  // ----------------------------------------------------------
  // 진찰 및 증상 - 13
  // 증상 / 진찰 소견 → 예 / 아니오
  // ----------------------------------------------------------
  ClinicalFieldDefinition(
    name: 'BP',
    label: '수축기 혈압',
    group: '진찰 및 증상',
    type: ClinicalFieldType.number,
  ),
  ClinicalFieldDefinition(
    name: 'PR',
    label: '맥박',
    group: '진찰 및 증상',
    type: ClinicalFieldType.number,
  ),
  ClinicalFieldDefinition(
    name: 'Edema',
    label: '부종',
    group: '진찰 및 증상',
    type: ClinicalFieldType.binary,
    options: clinicalBinaryOptions,
  ),
  ClinicalFieldDefinition(
    name: 'Weak Peripheral Pulse',
    label: '말초 맥박 약화',
    group: '진찰 및 증상',
    type: ClinicalFieldType.binary,
    options: clinicalBinaryOptions,
  ),
  ClinicalFieldDefinition(
    name: 'Lung rales',
    label: '폐 수포음',
    group: '진찰 및 증상',
    type: ClinicalFieldType.binary,
    options: clinicalBinaryOptions,
  ),
  ClinicalFieldDefinition(
    name: 'Systolic Murmur',
    label: '수축기 심잡음',
    group: '진찰 및 증상',
    type: ClinicalFieldType.binary,
    options: clinicalBinaryOptions,
  ),
  ClinicalFieldDefinition(
    name: 'Diastolic Murmur',
    label: '이완기 심잡음',
    group: '진찰 및 증상',
    type: ClinicalFieldType.binary,
    options: clinicalBinaryOptions,
  ),
  ClinicalFieldDefinition(
    name: 'Typical Chest Pain',
    label: '전형적 흉통',
    group: '진찰 및 증상',
    type: ClinicalFieldType.binary,
    options: clinicalBinaryOptions,
  ),
  ClinicalFieldDefinition(
    name: 'Dyspnea',
    label: '호흡곤란',
    group: '진찰 및 증상',
    type: ClinicalFieldType.binary,
    options: clinicalBinaryOptions,
  ),
  ClinicalFieldDefinition(
    name: 'Function Class',
    label: '기능 등급',
    group: '진찰 및 증상',
    type: ClinicalFieldType.number,
  ),
  ClinicalFieldDefinition(
    name: 'Atypical',
    label: '비전형적 흉통',
    group: '진찰 및 증상',
    type: ClinicalFieldType.binary,
    options: clinicalBinaryOptions,
  ),
  ClinicalFieldDefinition(
    name: 'Nonanginal',
    label: '비협심증성 흉통',
    group: '진찰 및 증상',
    type: ClinicalFieldType.binary,
    options: clinicalBinaryOptions,
  ),
  ClinicalFieldDefinition(
    name: 'LowTH Ang',
    label: '저역치 협심증',
    group: '진찰 및 증상',
    type: ClinicalFieldType.binary,
    options: clinicalBinaryOptions,
  ),

  // ----------------------------------------------------------
  // 심전도 및 심초음파 - 10
  // ECG 소견 → 예 / 아니오
  // ----------------------------------------------------------
  ClinicalFieldDefinition(
    name: 'Q Wave',
    label: 'Q파',
    group: '심전도 및 심초음파',
    type: ClinicalFieldType.binary,
    options: clinicalBinaryOptions,
  ),
  ClinicalFieldDefinition(
    name: 'St Elevation',
    label: 'ST 상승',
    group: '심전도 및 심초음파',
    type: ClinicalFieldType.binary,
    options: clinicalBinaryOptions,
  ),
  ClinicalFieldDefinition(
    name: 'St Depression',
    label: 'ST 하강',
    group: '심전도 및 심초음파',
    type: ClinicalFieldType.binary,
    options: clinicalBinaryOptions,
  ),
  ClinicalFieldDefinition(
    name: 'Tinversion',
    label: 'T파 역전',
    group: '심전도 및 심초음파',
    type: ClinicalFieldType.binary,
    options: clinicalBinaryOptions,
  ),
  ClinicalFieldDefinition(
    name: 'LVH',
    label: '좌심실 비대',
    group: '심전도 및 심초음파',
    type: ClinicalFieldType.binary,
    options: clinicalBinaryOptions,
  ),
  ClinicalFieldDefinition(
    name: 'Poor R Progression',
    label: 'R파 진행 불량',
    group: '심전도 및 심초음파',
    type: ClinicalFieldType.binary,
    options: clinicalBinaryOptions,
  ),
  ClinicalFieldDefinition(
    name: 'BBB',
    label: '각차단 (BBB)',
    group: '심전도 및 심초음파',
    type: ClinicalFieldType.select,
    options: clinicalBbbOptions,
  ),
  ClinicalFieldDefinition(
    name: 'EF-TTE',
    label: '박출률 EF (%)',
    group: '심전도 및 심초음파',
    type: ClinicalFieldType.number,
    step: 0.1,
  ),
  ClinicalFieldDefinition(
    name: 'Region RWMA',
    label: '국소벽운동 이상',
    group: '심전도 및 심초음파',
    type: ClinicalFieldType.number,
  ),
  ClinicalFieldDefinition(
    name: 'VHD',
    label: '판막질환 (VHD)',
    group: '심전도 및 심초음파',
    type: ClinicalFieldType.select,
    options: clinicalVhdOptions,
  ),

  // ----------------------------------------------------------
  // 혈액검사 - 14
  // ----------------------------------------------------------
  ClinicalFieldDefinition(
    name: 'FBS',
    label: '공복혈당',
    group: '혈액검사',
    type: ClinicalFieldType.number,
  ),
  ClinicalFieldDefinition(
    name: 'CR',
    label: 'Creatinine',
    group: '혈액검사',
    type: ClinicalFieldType.number,
    step: 0.01,
  ),
  ClinicalFieldDefinition(
    name: 'TG',
    label: '중성지방',
    group: '혈액검사',
    type: ClinicalFieldType.number,
  ),
  ClinicalFieldDefinition(
    name: 'LDL',
    label: 'LDL',
    group: '혈액검사',
    type: ClinicalFieldType.number,
  ),
  ClinicalFieldDefinition(
    name: 'HDL',
    label: 'HDL',
    group: '혈액검사',
    type: ClinicalFieldType.number,
    step: 0.01,
  ),
  ClinicalFieldDefinition(
    name: 'BUN',
    label: 'BUN',
    group: '혈액검사',
    type: ClinicalFieldType.number,
  ),
  ClinicalFieldDefinition(
    name: 'ESR',
    label: 'ESR',
    group: '혈액검사',
    type: ClinicalFieldType.number,
  ),
  ClinicalFieldDefinition(
    name: 'HB',
    label: 'Hemoglobin',
    group: '혈액검사',
    type: ClinicalFieldType.number,
    step: 0.01,
  ),
  ClinicalFieldDefinition(
    name: 'K',
    label: 'Potassium',
    group: '혈액검사',
    type: ClinicalFieldType.number,
    step: 0.01,
  ),
  ClinicalFieldDefinition(
    name: 'Na',
    label: 'Sodium',
    group: '혈액검사',
    type: ClinicalFieldType.number,
  ),
  ClinicalFieldDefinition(
    name: 'WBC',
    label: 'WBC',
    group: '혈액검사',
    type: ClinicalFieldType.number,
  ),
  ClinicalFieldDefinition(
    name: 'Lymph',
    label: 'Lymphocyte',
    group: '혈액검사',
    type: ClinicalFieldType.number,
  ),
  ClinicalFieldDefinition(
    name: 'Neut',
    label: 'Neutrophil',
    group: '혈액검사',
    type: ClinicalFieldType.number,
  ),
  ClinicalFieldDefinition(
    name: 'PLT',
    label: 'Platelet',
    group: '혈액검사',
    type: ClinicalFieldType.number,
  ),
];
