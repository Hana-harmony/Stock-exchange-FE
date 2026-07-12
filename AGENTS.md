# AGENTS.md

## 공통 지침
- API key, push token, 외부 API credential은 프론트엔드 코드와 문서 예시에 원문으로 남기지 않는다.
- 사용자 식별자, 세무 파일명, 거래내역 등 민감 데이터는 화면 예시에서도 마스킹한다.
- 접근성, 반응형 레이아웃, 로딩/오류/빈 상태를 함께 설계한다.
- 변경 후 가능한 범위에서 lint, type check, UI test를 실행하고 결과를 기록한다.
- 테스트코드 작성 방법: .agents/skills/testing/SKILL.md

## 피그마 MCP 지침
- .agents/figma.md를 참고한다


## 서비스 경계
- 이 레포는 Flutter 기반 iOS/Android 현지 거래소 MTS 프론트엔드다.
- 운영 대상 플랫폼은 iOS와 Android다. Web target은 내부 QA·데모 요청이 있을 때만 검토한다.
- Stock-exchange-BE API만 호출한다.
- Hana-OmniLens-API와 Hannah-Montana-AI를 브라우저에서 직접 호출하지 않는다.
- 실제 주문 실행, 정산, 환급 지급/환수는 백엔드 상태를 표시할 뿐 프론트엔드에서 결정하지 않는다.

## 구현 원칙
- Flutter/Dart 기준의 프로젝트 구조, lint, widget test, integration test를 우선한다.
- 운영성 화면은 과장된 마케팅 UI보다 조용하고 스캔 가능한 MTS/거래 앱 UI를 우선한다.
- VI, 상·하한가, 외국인 한도, 환급금 선지급 리스크 문구는 사용자가 오해하지 않도록 명확히 표시한다.
- 실시간 피드는 중복 이벤트와 reconnect 상태를 자연스럽게 처리한다.
- 뉴스 상세는 `imageUrls`가 비었거나 원격 이미지 로드가 실패하면 대체 문구나 고정 높이 영역을 만들지 않는다.
