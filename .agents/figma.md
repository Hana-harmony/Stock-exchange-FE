# 작업 전 분석 순서
구현을 시작하기 전에 반드시 아래 순서로 현재 상태를 먼저 분석해 주세요.

## 1. 기존 프론트엔드 화면 구조 파악

- 현재 존재하는 화면 목록
- 라우팅 구조
- 각 화면에서 사용하는 API 또는 Mock 데이터
- 상태관리 방식
- 공통으로 반복되는 UI 요소

## 2. Figma 구조 파악

- 화면별 Frame 확인
- 공통 Header / Bottom Navigation / Button / Input / Card / Modal 등 반복 UI 확인
- 기존 Component, Variant, Style, Variable, Token 확인
- 화면별 디자인 링크 정리

## 3. 매핑표 작성

- 기존 코드 화면과 Figma 화면을 1:1로 매핑
- 매핑이 불명확한 화면은 임의 구현하지 말고 `확인 필요`로 보고
- Figma에 없는 상태 화면은 기존 동작을 유지하되 디자인 시스템에 맞춰 최소한으로 보완

---

# 핵심 작업 원칙

## 1. UI를 Figma 기준으로 교체

기존 프론트 초안의 디자인은 임시 구현물로 보고, 최종 UI는 Figma 기준으로 맞춰 주세요.

- 색상
- 폰트 크기
- Font Weight
- Line Height
- Radius
- Shadow
- Spacing
- Padding / Margin
- Button 높이
- Input 높이
- Card 구조
- 화면 간 여백
- Safe Area
- Bottom Navigation 위치

Hex 값이나 임의 스타일을 직접 하드코딩하지 말고, Figma Variables 또는 Style Token을 우선 사용해 주세요.

## 2. 컴포넌트 우선 원칙

반복되는 UI는 화면마다 새로 만들지 말고, 먼저 공통 컴포넌트로 분리한 뒤 재사용해 주세요.

우선 컴포넌트화 대상:

- Header / App Bar
- Bottom Navigation
- Button
- Disabled Button
- Input Field
- Search Bar
- Card
- Category Chip
- Filter Chip
- Modal / Bottom Sheet
- Loading Skeleton
- Empty State
- Error State
- Toast
- 입력_에러 컴포넌트

각 화면에서는 공통 컴포넌트의 Instance 또는 재사용 가능한 Widget/Component를 활용해 주세요.

Header나 Bottom Navigation처럼 여러 화면에서 반복되는 요소는 나중에 한 번 수정하면 전체 화면에 반영될 수 있는 구조로 만들어 주세요.

## 3. Figma Component / Variant 재사용

새 컴포넌트를 만들기 전에 Figma 내 기존 컴포넌트를 먼저 탐색해 주세요.

- 동일하거나 유사한 컴포넌트가 있으면 반드시 재사용
- Variant가 있으면 상태별 Variant 사용
- 없을 때만 새 컴포넌트 생성
- 중복 컴포넌트 생성 금지

예시:

- Button / Enabled
- Button / Disabled
- Button / Loading
- Input / Default
- Input / Focused
- Input / Error
- Chip / Selected
- Chip / Unselected

## 5. 4uto Layout 기준 반영

Figma의 Auto Layout 구조를 최대한 코드 구조에 반영해 주세요.

- Absolute Position은 디자인상 필수인 경우만 사용
- Hug / Fill Container 설정 확인
- Fixed Width / Fixed Height 여부 확인
- 모바일 기준 반응형 유지
- iPhone 16 Pro 기준으로 우선 구현
- Safe Area 고려
- Bottom Navigation과 콘텐츠가 겹치지 않게 처리

## 5. 기존 화면과 Figma 화면 매핑

기존 프론트 코드에 있는 화면을 Figma 화면과 매핑해서 작업해 주세요.

Figma 화면이 없는 경우에는 기존 화면 구조를 유지하되, 공통 디자인 시스템에 맞춰 최소한으로 정리해 주세요.

---

# 상태 처리 원칙

모든 API 호출 화면은 아래 상태를 고려해 주세요.

- Loading
- Empty
- Success
- Validation Error
- Network Error
- Server Error

Figma에 별도 상태 화면이 없는 경우:

- Loading: Skeleton UI 또는 기존 Loading Indicator를 디자인 시스템에 맞게 적용
- Empty: Empty State 컴포넌트 생성 또는 공통 스타일 적용
- Validation Error: 입력_에러 컴포넌트 사용
- Network Error / Server Error: Toast 또는 Error State 사용

입력창 에러가 발생했을 경우에는 `입력_에러` 컴포넌트를 활용해 주세요.

버튼이 비활성화 상태일 경우에는 `버튼_비활성화` 컴포넌트를 활용해 주세요.

입력 필드는 아래 기준을 따라 주세요.

- Unfocused: 외곽선 `iconbackground`
- Focused: 외곽선 `black`
- Error: Error color와 Error icon 사용

---

# 네비게이션 원칙

기존 명세 또는 코드에 존재하는 화면 이동은 유지해 주세요.

임의로 라우팅을 삭제하거나 변경하지 마세요.

예시:

- 홈 검색창 클릭 → 검색/둘러보기 화면
- 필터 버튼 클릭 → 필터 Bottom Sheet
- 카드 클릭 → 상세 화면
- Bottom Navigation 클릭 → 해당 탭 화면 이동

Figma 디자인상 화면 이동이 추가로 필요해 보이는 경우, 직접 구현하기 전에 `제안 사항`으로 보고해 주세요.

---

# API 작업 원칙

API 명세가 없는 경우 임의로 응답 구조를 추측하지 마세요.

- 기존 API 연동이 있으면 그대로 유지
- 기존 Mock Repository가 있으면 유지
- 필요한 경우 Mock 데이터는 UI 확인용으로만 최소 수정
- 임의 필드 생성 금지
- Request / Response 타입 변경 금지

API 구조 변경이 필요해 보이면 직접 변경하지 말고 보고해 주세요.

---

# 코드 리팩토링 원칙

디자인 적용 과정에서 중복 UI가 많다면 공통 컴포넌트로 분리해 주세요.

권장 분리 대상:

- `CommonHeader`
- `BottomNavigation`
- `PrimaryButton`
- `DisabledButton`
- `AppTextField`
- `ErrorTextField`
- `ReceiptCard`
- `SectionTitle`
- `EmptyState`
- `LoadingSkeleton`
- `AppToast`
- `AppBottomSheet`

단, 기존 기능 로직과 UI 리팩토링을 과도하게 섞지 말고, 변경 범위를 명확하게 유지해 주세요.

---

# 금지사항

- 기존 API 응답 구조 임의 변경 금지
- 기존 라우팅 경로 임의 변경 금지
- 기존 상태관리 방식 임의 교체 금지
- 화면마다 Header / Bottom Navigation을 중복 구현 금지
- Figma에 있는 컴포넌트를 무시하고 새로 만드는 것 금지
- Hex 값 직접 하드코딩 금지
- 기존 기능을 삭제하면서 디자인만 맞추는 것 금지

의미 없는 컴포넌트명 사용 금지:

- `Container1`
- `Frame23`
- `Widget1`
- `TempView`

---

# 네이밍 원칙

Figma Layer명과 실제 역할을 기준으로 의미 있는 이름을 사용해 주세요.

예시:

- `ActivityCard`
- `SearchBar`
- `CategoryChip`
- `FilterBottomSheet`
- `ReceiptCard`
- `ReceiptItemRow`
- `MonthlyReportCard`
- `SplitPaymentCard`
- `AppBottomNavigation`
- `AppHeader`

---

# 구현 완료 후 보고 형식

작업 완료 후 반드시 아래 내용을 보고해 주세요.

## 1. 변경한 화면 목록

- 화면명
- 변경 파일
- 대응 Figma Frame 링크
- 작업 내용 요약

## 2. 재사용한 컴포넌트 목록

- Figma 기존 컴포넌트
- 코드에서 재사용한 공통 컴포넌트

## 3. 새로 생성한 컴포넌트 목록

- 컴포넌트명
- 생성 이유
- 사용 위치

## 4. 새로 생성하거나 추가한 스타일 목록

- 색상
- 텍스트 스타일
- Radius
- Shadow
- Spacing

단, 기존 Figma Token으로 해결 가능한 경우 새 스타일을 만들지 마세요.

## 5. 기존 기능 보존 여부

아래 항목이 유지되었는지 체크해 주세요.

- API 연동
- 라우팅
- 상태관리
- Validation
- 화면 이동
- Error 처리

## 6. 임의로 판단한 사항

명세나 Figma에 없어 실무적으로 판단해서 처리한 부분을 정리해 주세요.

## 7. 구현하지 못한 항목

- 미구현 항목
- 이유
- 추가로 필요한 정보
- 후속 작업 제안

---

# 최종 목표

기존 프론트 초안의 기능은 유지하면서, 사용자가 보는 모든 화면을 Figma 디자인 시스템 기준으로 정리해 주세요.

작업 방향은 `새로 만들기`가 아니라 `기존 프론트에 디자인 시스템을 입히는 리팩토링`입니다.
