# 구현 로드맵

전체 구현 순서와 단계별 완료 기준은 `docs/IMPLEMENTATION_SEQUENCE.md`를 따른다.

## M1 프론트엔드 하네스
- Flutter 앱 scaffold: Done
- iOS target 설정
- Android target 설정
- 라우팅과 전역 레이아웃: Partial
- API client와 인증 세션 controller 연동: Partial
- English 기본 UI와 USD 표시/충전 기준: Partial
- 디자인 토큰과 공통 컴포넌트: Partial
- Flutter lint, widget test, integration test 하네스: Partial

## M2 시장/주문 화면
- 종목 검색: Partial
- 전체 종목 REST snapshot 시세 목록: Partial
- 시장별, watchlist, 보유종목 REST snapshot/WebSocket 시세 목록: Partial
- 실시간 시세 WebSocket 구독과 tick 반영: Partial
- WebSocket 재연결, stale 표시, REST snapshot refresh: Partial
- KRW 가격과 USD 환산 가격 동시 표시: Partial
- 적용 환율 기준시각/출처와 stale 상태 UI: Partial
- 과거 시세 차트: Partial
- 종목 상세 현재가/호가: Partial
- 외국인 보유율 게이지와 예측 boundary: Partial
- VI/상·하한가 배지: Partial
- 아이디/비밀번호 회원가입·로그인 form과 mock USD 계좌 화면: Partial
- 실제 결제 없는 달러 충전 화면: Partial
- 자체 mock ledger 모의 주문 패드와 제한 안내 팝업: Partial
- 매도 실현손익 표시: Partial

## M3 뉴스·공시 인텔리전스
- K-News 탭: Partial
- 이벤트 태그, 감성, 중요도 표시: Partial
- 원문 링크 열기: Partial
- 통합 알림함과 필터: Partial
- 실시간 push/reconnect 상태 UI: Partial

## M4 세무 환급 화면
- 서류 업로드와 파일 validation: Partial
- 단계별 상태 타임라인: Partial
- 환급 대상 안내와 정산 상세
- 매도 실현손익 기반 환급 입력 데이터 확인: Partial
- 환급 신청
- 선지급 완료 영수증과 사후 환수 리스크 고지: Partial

## M5 품질/운영
- 접근성 점검
- 모바일 viewport QA
- API 오류/빈 상태 처리
- E2E 테스트
- 민감정보 마스킹 점검
