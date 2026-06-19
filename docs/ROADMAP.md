# 구현 로드맵

전체 구현 순서와 단계별 완료 기준은 `docs/IMPLEMENTATION_SEQUENCE.md`를 따른다.

## M1 프론트엔드 하네스
- Flutter 앱 scaffold: Done
- iOS target 설정: Done
- Android target 설정: Done
- 라우팅과 전역 레이아웃: Partial
- API client와 인증 세션 controller 연동: Partial
- token secure storage 기반 session 보관: Partial
- English 기본 UI와 USD 표시/충전 기준: Partial
- 디자인 토큰과 공통 컴포넌트: Partial
- Flutter lint, widget test, integration test 하네스: Partial

## M2 시장/주문 화면
- 종목 검색: Done
- 전체/시장별 종목 REST snapshot 시세 목록: Done
- watchlist/보유종목 REST snapshot 시세 목록: Done
- Market WebSocket 시세 목록과 tick 반영: Done
- watchlist/보유종목 WebSocket 시세 목록: Partial
- 실시간 시세 WebSocket 구독과 복구 UI: Partial
- WebSocket 재연결, stale 표시, REST snapshot refresh: Partial
- KRW 가격과 USD 환산 가격 동시 표시: Done
- 적용 환율 기준시각/출처와 stale 상태 UI: Done
- 과거 시세 차트: Done
- 종목 상세 현재가/호가: Partial
- 외국인 보유율 게이지: Done
- 당일 예측 boundary: Partial
- VI/상·하한가 배지: Partial
- 아이디/비밀번호 회원가입·로그인 form과 mock USD 계좌 화면: Partial
- 실제 결제 없는 달러 충전 화면: Partial
- 자체 mock ledger 모의 주문 패드와 제한 안내 팝업: Partial
- 매도 실현손익 표시: Partial

## M3 뉴스·공시 인텔리전스
- K-News 탭: Done
- 이벤트 태그, 감성, 중요도, 리스크 chip 표시: Done
- 원문 링크 표시: Done
- AI 번역 glossary와 quality flag chip 표시: Done
- 통합 알림함과 필터: Done
- Push device 등록·조회·비활성화 UI: Done
- 실시간 push/reconnect 상태 UI: Partial

## M4 세무 환급 화면
- 서류 업로드와 파일 validation: Partial
- 단계별 상태 타임라인: Done
- 환급 대상 안내와 정산 상세: Partial
- 정부 검증 상태와 참조 번호 표시: Done
- 국세/지방세 환급 금액 비중 시각화: Done
- 매도 실현손익 기반 환급 입력 데이터 확인: Done
- 환급 신청
- 선지급 완료 영수증과 사후 환수 리스크 고지: 사후 환수 리스크 고지 Done, 영수증 Partial

## M5 품질/운영
- 접근성 점검
- 모바일 viewport QA
- API 오류/빈 상태 처리
- E2E 테스트
- 민감정보 마스킹 점검
