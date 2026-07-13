# 기능 분류와 레포 책임

## 플랫폼

| 항목 | 책임 | 상태 |
| --- | --- | --- |
| Flutter 앱 하네스 | Stock-exchange-FE | Done |
| Flutter 기반 iOS 앱 target 설정 | Stock-exchange-FE | Done |
| Flutter 기반 Android 앱 target 설정 | Stock-exchange-FE | Done |
| Flutter Web 운영 서비스 | Out of scope | Out of scope |
| English 기본 UI | Stock-exchange-FE | Done |
| USD 기본 표시·충전·모의 주문 화폐 | Stock-exchange-FE | Done |
| Stock-exchange-BE REST API client와 auth session header | Stock-exchange-FE | Done |
| 인증 세션 controller와 session store 경계 | Stock-exchange-FE | Done |
| token secure storage 기반 session 보관 | Stock-exchange-FE | Done |
| 로그인과 비밀번호 확인·거래 PIN 생성 3단계 회원가입 form, session controller 화면 바인딩 | Stock-exchange-FE | Done |
| Mock USD account 조회와 deposit 화면 바인딩 | Stock-exchange-FE | Done |
| 자체 mock ledger orderability/trade/portfolio 화면 바인딩 | Stock-exchange-FE | Done |
| Market quote REST snapshot controller와 화면 바인딩 | Stock-exchange-FE | Done |
| Watchlist/portfolio quote REST snapshot 화면 바인딩 | Stock-exchange-FE | Done |
| Market quote STOMP WebSocket client와 tick 병합 | Stock-exchange-FE | Done |
| Watchlist/portfolio quote WebSocket 화면 바인딩 | Stock-exchange-FE | Done |

## 1. 한국 주식 주문 지원

| 화면/기능 | 책임 | 상태 |
| --- | --- | --- |
| 전체/시장별 종목 REST snapshot 시세 목록 | Stock-exchange-FE | Done |
| watchlist/보유종목 REST snapshot 시세 목록 | Stock-exchange-FE | Done |
| 실시간 시세 WebSocket 구독과 재연결/복구 UI | Stock-exchange-FE | Done |
| 하단 탭 선택·재선택 시 화면 snapshot 새로고침 | Stock-exchange-FE | Done |
| KRW 가격과 USD 환산 가격 동시 표시 | Stock-exchange-FE | Done |
| 적용 환율 기준시각/출처와 stale 상태 표시 | Stock-exchange-FE | Done |
| 과거 시세 차트 | Stock-exchange-FE | Done |
| 종목 상세 현재가와 원화 기준 가격 | Stock-exchange-FE | Done |
| 외국인 투자한도 게이지 | Stock-exchange-FE | Done |
| 당일 예상 지분율 범위 | Stock-exchange-FE | Done |
| VI 발동, 단일가 매매, 상·하한가 배지 | Stock-exchange-FE | Done |
| 아이디/비밀번호 확인·6자리 거래 PIN 회원가입과 로그인 | Stock-exchange-FE | Done |
| mock USD 계좌 잔고와 거래 PIN을 사용하는 실제 결제 없는 달러 충전 화면 | Stock-exchange-FE | Done |
| 자체 mock ledger 모의 주문 패드와 주문 제한 안내 | Stock-exchange-FE | Done |
| 매도 내역과 실현손익 표시 | Stock-exchange-FE | Done |
| 실제 주문 체결 | Out of scope | Out of scope |

## 2. 뉴스·공시 인텔리전스

| 화면/기능 | 책임 | 상태 |
| --- | --- | --- |
| 종목별 K-News 탭 | Stock-exchange-FE | Done |
| 번역 제목, What/Why/Impact 3줄 요약, 원문 링크 | Stock-exchange-FE | Done |
| 기사 이미지 썸네일과 원문/번역 전문 preview | Stock-exchange-FE | Done |
| AI 번역 glossary와 quality flag 표시 | Stock-exchange-FE | Done |
| 중요도, 감성, 리스크, 이벤트 태그 표시 | Stock-exchange-FE | Done |
| 통합 알림함 All/My Portfolio/Watchlist 필터 | Stock-exchange-FE | Done |
| Push device 등록·조회·비활성화 UI | Stock-exchange-FE | Done |
| 실시간 푸시 타임라인 | Stock-exchange-FE | Done |

## 3. 세무 전산화 및 환급금 선지급

| 화면/기능 | 책임 | 상태 |
| --- | --- | --- |
| 거주자증명서와 조세조약 신청서 업로드 | Stock-exchange-FE | Done |
| 단계별 제출/검증/환급 상태 타임라인 | Stock-exchange-FE | Done |
| 정부 검증 상태와 참조 번호 표시 | Stock-exchange-FE | Done |
| 국세/지방세 환급 금액 비중 시각화 | Stock-exchange-FE | Done |
| 환급 신청과 선지급 완료 영수증 | Stock-exchange-FE | Done |
| 매도 실현손익 기반 환급 입력 데이터 확인 | Stock-exchange-FE | Done |
| 사후 환수 리스크 고지 | Stock-exchange-FE | Done |
