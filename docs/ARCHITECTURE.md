# 아키텍처

## 목적
- Flutter 기반 iOS/Android 영어 MTS 앱으로 현지 투자자가 모든 한국 상장주식 정보를 이해하고, USD 기준 모의 주문을 실행하고, 보유/관심 종목의 뉴스·공시를 빠르게 확인하도록 화면을 제공한다.
- 세무 서류 제출과 환급/선지급 상태를 단계별로 안내한다.

## 플랫폼 경계
- 운영 앱은 Flutter 기반 iOS/Android 앱이다.
- Stock-exchange-FE는 Stock-exchange-BE API와 WebSocket만 호출한다.
- Hana-OmniLens-API, Hannah-Montana-AI, KIS/KRX/FX provider는 모바일 앱에서 직접 호출하지 않는다.
- Flutter Web은 운영 대상이 아니며, 필요 시 내부 QA/데모 용도로만 별도 검토한다.
- 기본 사용자 언어는 English, 기본 표시·충전·모의 주문 화폐는 USD다.

## 화면 구성
- `auth`: 아이디/비밀번호 회원가입, 로그인
- `market`: 전체/시장별 종목 실시간 시세 목록, 종목 검색, 종목 상세, 현재가/호가, 과거 시세 차트 표시
- `account`: mock USD 계좌 잔고, 실제 결제 없는 달러 충전
- `order`: 자체 mock ledger 모의 주문 패드, 주문 가능 여부, VI/상·하한가 제한 안내
- `portfolio`: 보유종목, USD 평가금액, watchlist, 매도 실현손익
- `intelligence`: K-News 피드, 원문 링크, 감성/중요도/리스크/이벤트 태그, AI 번역 glossary/quality flag
- `notifications`: All, My Portfolio, Watchlist 필터가 있는 통합 알림함과 push device registration
- `tax`: 서류 업로드, 검증 상태, 환급 대상 안내, 정산 상세, 선지급 완료와 리스크 고지

## 데이터 흐름
1. FE는 Stock-exchange-BE에서 전체/시장별/watchlist/보유종목 실시간 시세 snapshot을 REST로 먼저 조회하고 KRW 가격과 USD 가격을 함께 표시한다.
2. FE는 Stock-exchange-BE의 quote WebSocket을 구독해 장중 가격, 호가, 등락률, VI/단일가/상·하한가 상태 tick과 USD 환산 가격 tick을 실시간 반영한다.
3. WebSocket 재연결 또는 누락 감지 시 REST snapshot으로 복구한 뒤 stream을 재구독한다.
4. FE는 Stock-exchange-BE에서 Hana-OmniLens-API의 KRX 기반 과거 시세 DB를 재가공한 차트 데이터를 REST로 조회한다.
5. FE는 Stock-exchange-BE에서 종목 상세와 orderability 데이터를 조회한다.
6. 종목 상세 화면은 현재가 KRW, USD 환산 가격, 적용 환율 기준시각/출처, 외국인 보유율, 당일 예측 범위, VI/단일가/상·하한가 상태를 표시한다.
7. 회원가입은 아이디/비밀번호만 받고, 가입 후 mock USD 계좌와 충전 화면을 제공한다.
8. 주문 패드는 BE의 주문 가능 여부 결과를 바탕으로 제한 안내 팝업을 표시하고, 실제 주문이 아닌 자체 mock 거래임을 표시한다.
9. 매도 내역과 실현손익은 포트폴리오와 세무 환급/선지급 화면에서 이어서 조회한다.
10. 알림함과 K-News 피드는 BE가 저장한 Hana-OmniLens-API 이벤트를 조회하거나 실시간 스트림으로 받는다. 앱은 계좌별 push device token 등록/비활성화 REST 계약도 호출한다.
11. 세무 화면은 BE가 관리하는 서류 업로드 상태와 Hana-OmniLens-API 세무 상태 동기화 결과를 표시한다.

## 현재 구현 상태
- Flutter 앱 하네스, Material 3 기반 앱 shell, 하단 탭 navigation, widget test, GitHub Actions CI가 존재한다.
- Market, Portfolio, Alerts, Tax 탭의 영어 UI skeleton이 존재한다.
- Market 탭은 종목 검색, 시장/watchlist/portfolio 필터, KRW/USD 가격, WebSocket/REST 복구 상태, 환율 기준시각/출처 표시 영역을 가진다.
- Portfolio 탭은 mock USD cash, 실제 주문이 아닌 자체 ledger 기반 거래, 보유종목과 실현손익 연결 영역을 가진다.
- Alerts 탭은 Stock-exchange-BE의 `/api/v1/accounts/{accountId}/notifications`와 `/api/v1/stocks/{stockCode}/intelligence`를 호출해 AI 번역 뉴스·공시, 원문 링크, glossary/quality flag, My Portfolio/Watchlist 필터, 읽음 처리 상태를 표시한다.
- Tax 탭은 서류 상태, 환급 추정, 매도 실현손익 기반 입력, 선지급 후 환수 리스크 고지 영역을 가진다.
- `ExchangeApiClient`는 Stock-exchange-BE 공통 응답 envelope(`success/status/code/message/data`)를 파싱하고, bearer auth session header를 REST 요청에 적용한다.
- Auth signup/login/refresh/verify, account/deposit, market quote snapshot, watchlist/portfolio quote, notification, tax refund status endpoint 호출 골격이 존재한다.
- `ExchangeSessionController`는 login, restore, refresh, sign out 상태 전이를 관리하고, `ExchangeSessionStore` 경계를 통해 session 저장소를 분리한다.
- `SecureExchangeSessionStore`는 운영 앱 기본 session 저장소이며 `flutter_secure_storage`에 bearer token session을 JSON으로 보관한다.
- `AccountController`는 Stock-exchange-BE account REST 조회와 mock USD deposit 상태를 관리한다.
- `TradeController`는 Stock-exchange-BE orderability, mock trade execution, portfolio REST 상태를 관리한다.
- `TaxController`는 Stock-exchange-BE `GET /api/v1/accounts/{accountId}/tax/refund-status`를 조회해 세무 케이스, 정부 검증 상태, 참조번호, 예상 환급 금액을 관리한다.
- Market/Portfolio 세션 패널은 username/password 로그인, 회원가입 후 로그인, refresh, sign out 액션을 session controller에 바인딩한다.
- Portfolio mock cash 패널은 로그인된 accountId로 잔고를 조회하고, 입력 금액을 `amountUsd`로 보내 실제 결제 없는 mock deposit ledger를 생성한다.
- Portfolio mock order pad는 주문 전 `GET /trades/orderability`로 외국인 한도, VI, 단일가, 상·하한가 warning/blocking reason을 조회하고, backend code를 영어 사용자 문구로 변환해 표시한 뒤 `POST /trades`로 Stock-exchange-BE 자체 mock ledger만 갱신한다.
- `MarketQuoteController`는 Stock-exchange-BE `GET /api/v1/market/quotes` REST snapshot을 조회하고, quote/cache/FX metadata를 Market 화면에 바인딩한다.
- `MarketDetailController`는 Stock-exchange-BE `GET /api/v1/stocks/{stockCode}`, `GET /api/v1/market/stocks/{stockCode}/chart`, `GET /api/v1/market/stocks/{stockCode}/orderbook`을 함께 조회해 종목 상세, KRX 기반 과거 차트, 호가 snapshot을 Market 화면에 바인딩한다.
- Market 종목 상세 패널은 현재가 KRW와 USD 환산 가격, 외국인 보유율/한도소진율, VI/단일가/상·하한가 상태 badge, 최근 차트 종가, ask/bid 호가를 표시한다.
- `MarketQuoteLiveClient`는 Stock-exchange-BE `/ws/market` STOMP WebSocket에 연결하고 `/topic/market/quotes`, market, stock, account-scoped quote topic을 구독할 수 있다.
- Market 화면은 `Start live` 액션으로 quote WebSocket을 시작하고 수신 tick을 기존 quote list에 병합한다.
- `MarketQuoteController`는 WebSocket onDone/onError 시 마지막 구독 조건을 유지하고 backoff 지연 후 동일 topic을 재구독하며, 사용자가 `Stop`을 누르면 재연결 timer를 중단한다.
- Portfolio 화면은 Stock-exchange-BE account-scoped watchlist/portfolio quote REST snapshot을 bearer auth session의 accountId로 조회하고 account-scoped WebSocket topic을 구독한다.
- Tax 화면은 bearer auth session의 accountId로 refund status를 조회하고, caseId를 정부 검증 참조번호로 표시하며, 원천징수세 대비 조세조약세와 환급 가능분 비중을 시각화한다.
- 테스트 하네스는 `MemoryExchangeSessionStore`를 주입해 session 상태 전이를 검증한다.
- iOS/Android 플랫폼 target 디렉터리와 앱 ID, display name, Android network/push 권한, iOS Runner/Podfile 기본 설정이 존재한다.
