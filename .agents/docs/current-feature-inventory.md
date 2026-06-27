# 현재 기능 인벤토리

디자인 리뉴얼 전에, 현재 프론트엔드에 구현되어 있는 기능을 `페이지 / 섹션 / 액션 / 데이터소스` 기준으로 정리한 문서이다.

목표:

- 나중에 화면 구조가 바뀌어도 현재 기능을 새 위치에 다시 연결할 수 있게 한다.
- "A/B에서 C 영역에 이 기능 연결" 같은 요청을 섹션 ID 기준으로 바로 작업할 수 있게 한다.
- 현재 구현이 `실제 백엔드 연결`, `실시간 WS`, `샘플 입력`, `플레이스홀더`, `미사용 구현` 중 어디에 속하는지 구분한다.

기준 코드:

- 앱 셸/화면/위젯: `lib/src/app.dart`
- API 클라이언트: `lib/src/core/exchange_api_client.dart`
- 상태/기능 컨트롤러: `lib/src/core/*.dart`

## 연결 상태 표기

- `backend_rest`: Stock-exchange-BE REST API 호출
- `backend_rest_ws`: REST + WebSocket 실시간 구독
- `backend_rest_sample_input`: 실제 API는 호출하지만 입력값/파일값은 현재 샘플 값 사용
- `local_navigation`: 로컬 탭/라우팅 전환만 담당
- `local_backend_entry`: 로컬 UI 액션이 실제 백엔드 기능 진입점 역할을 함
- `local_filter_on_backend_data`: 백엔드에서 받은 데이터를 프론트에서 필터링
- `visual_only`: 데이터 연결 없이 시각 요소만 존재
- `placeholder_white`: 현재 빈 흰색 블록만 존재
- `dormant`: 구현은 있으나 현재 화면 트리에서 사용되지 않음

## 시스템 배선

### API 기본 진입점

- 환경 변수: `EXCHANGE_API_BASE_URL`
- 기본값: `http://localhost:3000`
- 정의 위치: `ExchangeEnvironment` in `lib/src/core/exchange_api_client.dart`

### 공통 데이터 흐름

`UI Widget -> Controller -> ExchangeApiClient -> Stock-exchange-BE`

실시간 시세/지수는 아래 흐름을 추가로 사용한다.

`UI Widget -> Controller -> MarketQuoteLiveClient / MarketIndexLiveClient -> ws(s)://.../ws/market`

### 앱 셸에서 컨트롤러 생성/주입

모든 컨트롤러 생성과 주입은 `ExchangeShell`에서 수행한다.

- 세션: `ExchangeSessionController`
- 계좌: `AccountController`
- 주문/포트폴리오: `TradeController`
- 종목 상세: `MarketDetailController`
- 지수: `MarketIndexController`
- 시세/검색: `MarketQuoteController`
- 알림: `NotificationController`
- 세금환급: `TaxController`

## 글로벌 셸

### `shell.header`

- 파일/위젯: `AppHeader` + `_SessionAction` + `_WalletBadge`
- 위치: `ExchangeShell`
- 현재 타이틀: `Markets`
- 상태:
  - `shell.header.brand_logo`: 헤더 좌측 로고 이미지
    - 구현: `assets/icons/logo_symbol.png`
    - 연결상태: `visual_only`
  - `shell.header.auth_button`
    - 표시: `Sign in` 또는 로그인한 `username`
    - 동작: 인증 다이얼로그 오픈
    - 연결상태: `backend_rest`
  - `shell.header.wallet_badge`
    - 표시: `USD cash`
    - 데이터: `AccountController`
    - 연결상태: `backend_rest`

### `shell.nav`

- 파일/위젯: `AppBottomNavigation`
- 탭 ID:
  - `shell.nav.market`
  - `shell.nav.portfolio`
  - `shell.nav.orders`
  - `shell.nav.alerts`
  - `shell.nav.tax`
- 동작: `IndexedStack` 탭 전환
- 연결상태: `local_navigation`

## 오버레이 / 공통 진입 기능

### `overlay.auth.dialog`

- 파일/위젯: `_AuthDialog`
- 진입:
  - `shell.header.auth_button`
  - 미로그인 상태에서 일부 패널의 `Sign in` 버튼
- 필드:
  - `overlay.auth.dialog.username`
  - `overlay.auth.dialog.password`
- 액션:
  - `overlay.auth.dialog.sign_in` -> `ExchangeSessionController.login`
  - `overlay.auth.dialog.create_account` -> `ExchangeSessionController.signUpAndLogin`
  - `overlay.auth.dialog.sign_out` -> `ExchangeSessionController.signOut`
- API:
  - `POST /api/v1/auth/login`
  - `POST /api/v1/auth/signup`
  - `POST /api/v1/auth/token/refresh`
- 연결상태: `backend_rest`

## 페이지 인벤토리

## 1. Market 페이지

- 페이지 ID: `page.market`
- 파일/위젯: `MarketScreen`
- 진입 탭: `shell.nav.market`

### `page.market.search`

- 위젯: `AppSearchField`
- 식별 키: `market-stock-search-field`
- 역할: 국내 종목 통합 검색 입력
- 액션:
  - 입력 debounce 250ms
  - 검색어 비움 -> 결과 패널 제거, 홈 섹션 복귀
- API: `GET /api/v1/stocks/search`
- 연결상태: `backend_rest`

### `page.market.search_results`

- 위젯: `_StockSearchResultsPanel`
- 역할: 검색 결과 리스트 / 검색 오류 / empty 처리
- 액션:
  - 종목 선택 -> `page.stock_detail`
- API: `GET /api/v1/stocks/search`
- 연결상태: `backend_rest`

### `page.market.filters`

- 위젯: `_MarketFilters`
- 역할: 시장 필터 선택 (`ALL`, `KOSPI`, `KOSDAQ` 계열)
- 액션:
  - 필터 변경 -> 시세 snapshot 재호출 + 실시간 재구독
- API:
  - `GET /api/v1/market/quotes`
  - WS `/ws/market`
- 연결상태: `backend_rest_ws`

### `page.market.indices`

- 위젯: `_MarketIndicesPanel`
- 역할: 한국 시장 주요 지수 표시
- API:
  - `GET /api/v1/market/indices`
  - WS topic `/topic/market/indices`
- 연결상태: `backend_rest_ws`

### `page.market.popular_stocks`

- 위젯: `_PopularStocksPanel`
- 역할: 홈 인기종목 리스트
- 현재 종목코드 하드코딩:
  - `005930`, `000660`, `035720`, `035420`, `005380`, `000270`, `068270`, `105560`, `055550`, `086790`
- 액션:
  - 종목 탭 -> `page.stock_detail`
- API:
  - `GET /api/v1/market/quotes`
  - WS `/ws/market`
- 연결상태: `backend_rest_ws`

## 2. Stock Detail 페이지

- 페이지 ID: `page.stock_detail`
- 파일/위젯: `StockDetailScreen`, `_StockDetailPanel`
- 진입:
  - `page.market.search_results`
  - `page.market.popular_stocks`

### `page.stock_detail.summary`

- 위젯: `_DetailLivePricePanel`
- 역할: 현재가, KRW/USD 가격, 등락률, 실시간 상태, 시간외 데이터
- API:
  - `GET /api/v1/stocks/{stockCode}`
  - WS `/ws/market`
- 연결상태: `backend_rest_ws`

### `page.stock_detail.chart`

- 위젯: `_MarketHistoryChartPanel`
- 역할: 기간별 차트 (`1D`, `1W`, `1M` 계열)
- 액션:
  - 기간 선택 -> 차트 재조회
- API:
  - `GET /api/v1/market/stocks/{stockCode}/chart`
  - 실시간 quote를 보조 점 데이터로 추가
- 연결상태: `backend_rest_ws`

### `page.stock_detail.orderbook`

- 위젯: `_OrderBookPreview`
- 역할: 호가 상/하위 레벨 표시
- 동작:
  - 2초 주기 refresh
- API: `GET /api/v1/market/stocks/{stockCode}/orderbook`
- 연결상태: `backend_rest`

### `page.stock_detail.foreign_ownership`

- 위젯: `_ForeignOwnershipGaugePanel`
- 역할: 외국인 보유율 / 한도 소진율 게이지
- 식별 키:
  - `foreign-ownership-rate-gauge`
  - `foreign-limit-rate-gauge`
- API: `GET /api/v1/stocks/{stockCode}`
- 연결상태: `backend_rest`

### `page.stock_detail.trade_bar`

- 위젯: `_DetailTradeActionBar`
- 역할: 상세 화면에서 매수/매도 진입
- 액션:
  - `page.stock_detail.trade_bar.sell`
  - `page.stock_detail.trade_bar.buy`
  - 미로그인 시 인증 다이얼로그 오픈
- 연결상태: `local_backend_entry`

### `overlay.order_sheet`

- 위젯: `_DetailOrderSheet`
- 역할: 종목 상세 기반 주문 입력
- 필드:
  - `overlay.order_sheet.qty`
  - `overlay.order_sheet.limit_price`
- 액션:
  - `overlay.order_sheet.check_orderability`
  - `overlay.order_sheet.submit_order`
- API:
  - `GET /api/v1/accounts/{accountId}/trades/orderability`
  - `POST /api/v1/accounts/{accountId}/trades`
- 연결상태: `backend_rest`

## 3. Portfolio 페이지

- 페이지 ID: `page.portfolio`
- 파일/위젯: `PortfolioScreen`
- 진입 탭: `shell.nav.portfolio`

### `page.portfolio.balance`

- 위젯: `_BalancePanel`
- 역할: USD 현금 잔고, 입금, ledger entry
- 필드:
  - `page.portfolio.balance.deposit_amount`
- 액션:
  - `page.portfolio.balance.refresh`
  - `page.portfolio.balance.deposit`
- API:
  - `GET /api/v1/accounts/{accountId}`
  - `POST /api/v1/accounts/{accountId}/deposits`
- 연결상태: `backend_rest`

### `page.portfolio.holdings`

- 위젯: `_HoldingsPanel`
- 역할: 보유 종목 리스트 + 포트폴리오 요약 지표
- 액션:
  - `page.portfolio.holdings.refresh`
  - 미로그인 시 `Sign in`
- API: `GET /api/v1/accounts/{accountId}/portfolio`
- 연결상태: `backend_rest`

### `page.portfolio.quotes.portfolio`

- 위젯: `_AccountQuoteSnapshotPanel`
- 역할: 보유 종목 시세 snapshot 표시
- 액션:
  - 로그인 후 idle 상태이면 자동 load
- API:
  - `GET /api/v1/accounts/{accountId}/market/quotes/portfolio`
  - 관련 실시간 quote controller 사용
- 연결상태: `backend_rest_ws`

### `page.portfolio.quotes.watchlist`

- 위젯: `_AccountQuoteSnapshotPanel`
- 역할: watchlist 종목 시세 snapshot 표시
- API:
  - `GET /api/v1/accounts/{accountId}/market/quotes/watchlist`
  - 관련 실시간 quote controller 사용
- 연결상태: `backend_rest_ws`

### `page.portfolio.placeholder.cash_ledger`

- 위젯: `_BackendPendingWhiteBlock`
- 이전 역할: 하드코드 `USD cash ledger` 안내 패널
- 현재 상태: 빈 흰색 placeholder
- 연결상태: `placeholder_white`

## 4. Orders 페이지

- 페이지 ID: `page.orders`
- 파일/위젯: `OrdersScreen`
- 진입 탭: `shell.nav.orders`

### `page.orders.history`

- 위젯: `_TradeHistoryPanel`
- 역할: 주문내역 + 체결내역 표시
- 액션:
  - `page.orders.history.refresh`
  - 미로그인 시 `Sign in`
- API:
  - `GET /api/v1/accounts/{accountId}/trades`
  - `GET /api/v1/accounts/{accountId}/orders`
- 연결상태: `backend_rest`

## 5. Alerts 페이지

- 페이지 ID: `page.alerts`
- 파일/위젯: `AlertsScreen`
- 진입 탭: `shell.nav.alerts`

### `page.alerts.inbox`

- 위젯: `_AlertInboxPanel`
- 역할: 알림/뉴스/디바이스 상태를 하나의 패널에서 관리
- API 묶음:
  - `GET /api/v1/accounts/{accountId}/notifications`
  - `GET /api/v1/stocks/{stockCode}/intelligence`
  - `GET /api/v1/accounts/{accountId}/notifications/devices`
- 연결상태: `backend_rest`

### `page.alerts.inbox.filters`

- 위젯: `_AlertFilters`
- 역할: 알림 필터 선택
- 액션:
  - `page.alerts.inbox.filters.select`
- 데이터소스: `NotificationController.setFilter`
- 연결상태: `local_filter_on_backend_data`

### `page.alerts.inbox.metrics`

- 위젯: `_Metric` 집합
- 역할: unread / total / k-news / push devices 카운트 표시
- 데이터소스: `NotificationState`
- 연결상태: `backend_rest`

### `page.alerts.inbox.list`

- 위젯: `_NotificationRow`
- 역할: 알림 카드 리스트
- 액션:
  - `page.alerts.inbox.list.mark_read`
- API: `POST /api/v1/accounts/{accountId}/notifications/{notificationId}/read`
- 연결상태: `backend_rest`

### `page.alerts.devices`

- 위젯: `_NotificationDevicePanel`
- 역할: 푸시 디바이스 등록/해제
- 액션:
  - `page.alerts.devices.register`
  - `page.alerts.devices.disable`
- API:
  - `POST /api/v1/accounts/{accountId}/notifications/devices`
  - `DELETE /api/v1/accounts/{accountId}/notifications/devices/{deviceTokenId}`
- 연결상태: `backend_rest`

### `page.alerts.feed`

- 위젯: `_StockIntelligencePanel`
- 역할: 종목 intelligence / AI 번역 요약 표시
- 데이터소스: `StockIntelligenceFeed`
- API: `GET /api/v1/stocks/{stockCode}/intelligence`
- 연결상태: `backend_rest`

## 6. Tax Refund 페이지

- 페이지 ID: `page.tax`
- 파일/위젯: `TaxScreen`
- 진입 탭: `shell.nav.tax`

### `page.tax.status`

- 위젯: `_TaxRefundStatusPanel`
- 역할: 환급 케이스 상태, ref, split, timeline, 문서명, 매칭 거래, 영수증, recapture notice 표시
- 액션:
  - `page.tax.status.refresh`
- API: `GET /api/v1/accounts/{accountId}/tax/refund-status`
- 연결상태: `backend_rest`

### `page.tax.status.split`

- 위젯: `_TaxRefundSplit`
- 역할: 원천징수 세액 split bar
- 데이터소스: `TaxRefundCase`
- 연결상태: `backend_rest`

### `page.tax.status.documents`

- 위젯:
  - `_TaxDocumentChecklist`
  - `_TaxInputSummary`
  - `_TaxAdvanceReceipt`
  - `_TaxRecaptureNotice`
  - `_TaxMatchedTradeRow`
- 역할: 상태 세부 설명 묶음
- 데이터소스: `TaxRefundCase`
- 연결상태: `backend_rest`

### `page.tax.request`

- 위젯: `_TaxRefundRequestPanel`
- 역할: 문서 업로드 + 환급 요청 생성 + 상태 sync
- 기본 필드:
  - `taxYear` 기본값 `2026`
  - `treatyCountry` 기본값 `US`
  - `residenceFile` 기본값 `residence.pdf`
  - `reducedTaxFile` 기본값 `reduced-tax.pdf`
  - `advancePaymentRequested` 기본값 `true`
- 액션:
  - `page.tax.request.attach_sample_documents`
  - `page.tax.request.submit_refund_request`
  - `page.tax.request.sync_hana_status`
- API:
  - `POST /api/v1/accounts/{accountId}/tax/documents`
  - `POST /api/v1/accounts/{accountId}/tax/refund-cases`
  - `POST /api/v1/accounts/{accountId}/tax/refund-status/sync`
- 연결상태: `backend_rest_sample_input`
- 주의:
  - 파일 선택 UI가 아니라 샘플 바이트 업로드를 사용한다.
  - 실제 파일 picker 연결 전까지는 화면만 실사용 구조이고 입력은 샘플이다.

### `page.tax.request.upload_metadata`

- 위젯: `_InfoPanel` inside `_TaxRefundRequestPanel`
- 역할: 업로드된 문서 메타데이터 요약
- 데이터소스: `TaxState.uploadedDocuments`
- 연결상태: `backend_rest`

### `page.tax.placeholder.recapture`

- 위젯: `_BackendPendingWhiteBlock`
- 이전 역할: 하드코드 `Recapture risk` 안내 패널
- 현재 상태: 빈 흰색 placeholder
- 연결상태: `placeholder_white`

## 현재 미사용(dormant) 구현

아래 구현은 코드에는 있으나 현재 화면 트리에 연결되지 않았다.

### `dormant.session.status_panel`

- 위젯: `_SessionStatusPanel`
- 역할: 페이지 내장형 세션 패널
- 상태: 현재는 헤더 인증 다이얼로그만 사용
- 연결상태: `dormant`

### `dormant.trade.mock_order_pad`

- 위젯: `_MockTradePanel`
- 역할: 독립형 모의 주문 패널
- 액션:
  - 주문가능 확인
  - mock order 실행
  - 포트폴리오/실현손익 참조
- API:
  - `GET /api/v1/accounts/{accountId}/trades/orderability`
  - `POST /api/v1/accounts/{accountId}/trades`
  - `GET /api/v1/accounts/{accountId}/portfolio`
- 상태: 현재 상세 화면의 `overlay.order_sheet`가 실제 진입점이고, 이 패널은 mount되지 않음
- 연결상태: `dormant`

## 컨트롤러 / API 요약

### `ExchangeSessionController`

- 로그인: `POST /api/v1/auth/login`
- 회원가입: `POST /api/v1/auth/signup`
- 토큰 갱신: `POST /api/v1/auth/token/refresh`

### `AccountController`

- 계좌조회: `GET /api/v1/accounts/{accountId}`
- USD 입금: `POST /api/v1/accounts/{accountId}/deposits`

### `MarketQuoteController`

- 종목 검색: `GET /api/v1/stocks/search`
- 시세 snapshot: `GET /api/v1/market/quotes`
- watchlist 시세: `GET /api/v1/accounts/{accountId}/market/quotes/watchlist`
- portfolio 시세: `GET /api/v1/accounts/{accountId}/market/quotes/portfolio`
- 실시간 WS: `/ws/market`

### `MarketIndexController`

- 지수 snapshot: `GET /api/v1/market/indices`
- 실시간 WS: `/ws/market`, topic `/topic/market/indices`

### `MarketDetailController`

- 종목 상세: `GET /api/v1/stocks/{stockCode}`
- 차트: `GET /api/v1/market/stocks/{stockCode}/chart`
- 호가창: `GET /api/v1/market/stocks/{stockCode}/orderbook`

### `TradeController`

- 포트폴리오: `GET /api/v1/accounts/{accountId}/portfolio`
- 체결내역: `GET /api/v1/accounts/{accountId}/trades`
- 주문내역: `GET /api/v1/accounts/{accountId}/orders`
- 주문가능성: `GET /api/v1/accounts/{accountId}/trades/orderability`
- 주문실행: `POST /api/v1/accounts/{accountId}/trades`

### `NotificationController`

- 알림목록: `GET /api/v1/accounts/{accountId}/notifications`
- 읽음처리: `POST /api/v1/accounts/{accountId}/notifications/{notificationId}/read`
- 종목 intelligence: `GET /api/v1/stocks/{stockCode}/intelligence`
- 디바이스 목록: `GET /api/v1/accounts/{accountId}/notifications/devices`
- 디바이스 등록: `POST /api/v1/accounts/{accountId}/notifications/devices`
- 디바이스 비활성화: `DELETE /api/v1/accounts/{accountId}/notifications/devices/{deviceTokenId}`

### `TaxController`

- 환급상태 조회: `GET /api/v1/accounts/{accountId}/tax/refund-status`
- 문서 업로드: `POST /api/v1/accounts/{accountId}/tax/documents`
- 환급케이스 생성: `POST /api/v1/accounts/{accountId}/tax/refund-cases`
- 상태 동기화: `POST /api/v1/accounts/{accountId}/tax/refund-status/sync`

## 나중에 작업 요청하는 방법

아래처럼 섹션 ID를 기준으로 요청하면 된다.

- "`page.market.search`를 새 홈 상단 hero 안으로 옮겨줘"
- "`page.stock_detail.trade_bar.buy` 기능을 `page.market.popular_stocks` 카드 내부 CTA에 연결해줘"
- "`page.tax.request.submit_refund_request`를 새 디자인의 C 버튼에 연결해줘"
- "`page.alerts.devices.register`를 마이페이지 알림 설정 섹션으로 이동해줘"
- "`dormant.trade.mock_order_pad`를 다시 살려서 별도 실험 페이지에 붙여줘"

## 참고

- 현재 화면 대부분은 `lib/src/app.dart` 한 파일 안에 구현되어 있다.
- 리디자인 시 기능은 유지하되, 가능한 경우 섹션 단위로 위젯 분리부터 같이 진행하는 것이 좋다.
