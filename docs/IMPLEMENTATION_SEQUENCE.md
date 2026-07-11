# 변경 구현 순서

이 문서는 Stock-exchange-FE 변경 순서다. 현재 기능 배선은 `.agents/docs/current-feature-inventory.md`를 기준으로 한다.

1. 화면 ID, controller, `ExchangeApiClient`, REST/WebSocket 계약을 확인한다.
2. 디자인 토큰과 공통 widget을 우선 재사용하고 로딩·빈 상태·오류·stale·재연결 상태를 함께 설계한다.
3. API key와 provider credential을 앱에 추가하지 않고 access/refresh token은 secure storage로 관리한다.
4. controller·parsing 단위 테스트와 주요 사용자 동작 widget test를 추가한다.
5. 기능 인벤토리, 컴포넌트 기준, README·아키텍처·로컬 테스트 문서를 갱신한다.
6. format, analyze, test와 iOS Simulator build를 실행한다.
7. `feature`에서 작업 브랜치를 만들고 PR 체크 통과 후 `feature`, 이어서 `main`에 병합한다.

세무 흐름은 실제 파일 선택, 세 문서 순차 업로드, OCR 진행·실패·검수 상태와 개인정보 마스킹을 함께 검증한다.
