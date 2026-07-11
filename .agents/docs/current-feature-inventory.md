# 현재 기능 인벤토리

에이전트가 화면을 변경할 때 기능 누락을 막기 위한 코드 기준 인벤토리다. 최종 API 계약은 `lib/src/core/exchange_api_client.dart`, 화면 진입은 `lib/src/app.dart`와 `lib/src/features/exchange/`를 확인한다.

## 연결 상태

- `REST`: Stock-exchange-BE REST 연결
- `REST+WS`: REST 초기 snapshot과 `/ws/market` 실시간 갱신
- `LOCAL`: 화면 이동 또는 로컬 상태

## 앱 셸

| ID | 화면·동작 | 구현 | 연결 |
| --- | --- | --- | --- |
| `shell.header` | 브랜드, 검색, 알림, 계정 진입 | `app.dart` | LOCAL |
| `shell.nav.home` | 홈 | `exchange_pages.dart` | LOCAL |
| `shell.nav.discover` | 시장 뉴스·탐색 | `market_news/` | REST |
| `shell.nav.markets` | 지수·인기 종목·검색 | `market/market_screen.dart` | REST+WS |
| `shell.nav.watchlists` | 관심종목 | `watchlist/watchlist_screen.dart` | REST+WS |
| `shell.nav.accounts` | 계좌·포트폴리오·세무 | `accounts/` | REST+WS |
| `shell.nav.my` | 세션·설정 | `my/my_screen.dart` | REST |

## 인증과 계좌

| ID | 기능 | API |
| --- | --- | --- |
| `auth.signup` | 회원가입 후 mock USD 계좌 생성 | `POST /api/v1/auth/signup` |
| `auth.login` | access/refresh token 발급 | `POST /api/v1/auth/login` |
| `auth.refresh` | refresh rotation | `POST /api/v1/auth/token/refresh` |
| `account.balance` | 계좌와 USD 잔고 | `GET /api/v1/accounts/{accountId}` |
| `account.deposit` | mock USD 입금 | `POST /api/v1/accounts/{accountId}/deposits` |

토큰은 `SecureExchangeSessionStore`를 통해 `flutter_secure_storage`에 보관한다. 로그아웃 시 서버 세션과 로컬 토큰을 함께 제거한다.

## 시장과 종목 상세

| ID | 기능 | API·stream |
| --- | --- | --- |
| `market.indices` | KOSPI·KOSDAQ·KOSPI 200 | `GET /api/v1/market/indices`, `/topic/market/indices` |
| `market.quotes` | 시장 필터, 인기 종목, 현재가 | `GET /api/v1/market/quotes`, quote topic |
| `market.search` | 종목 검색·검색 순위·선택 기록 | `/api/v1/stocks/search*` |
| `stock.summary` | KRW/USD 가격, 등락, 외국인 한도, 거래 상태 | `GET /api/v1/stocks/{stockCode}` |
| `stock.chart` | 1D/1W/1M 차트 | `GET /api/v1/market/stocks/{stockCode}/chart` |
| `stock.orderbook` | 호가 | `GET /api/v1/market/stocks/{stockCode}/orderbook` |
| `stock.peers` | 글로벌 비교 3개와 핵심 강점 4개 | `GET /api/v1/stocks/{stockCode}/global-peers` |
| `stock.news` | 종목별 뉴스·공시와 원문 상세 | `GET /api/v1/stocks/{stockCode}/intelligence` |
| `stock.glossary` | 본문 금융 용어 클릭 해설 | `POST /api/v1/financial-terms/explain` |

상세 진입 시 수요 기반 실시간 구독을 요청하고 이탈 시 release API를 호출한다. stale·재연결·오류·빈 상태를 UI에서 구분한다.

## 관심종목·거래·자산

| ID | 기능 | API |
| --- | --- | --- |
| `watchlist.list` | 관심종목 조회·추가·삭제 | `/api/v1/accounts/{accountId}/watchlist` |
| `portfolio.summary` | 보유종목, 평가액, 손익, 평가 이력 | `/portfolio`, `/portfolio/history` |
| `orders.entry` | 수량·가격 입력, orderability 확인, mock 주문 | `/trades/orderability`, `POST /trades` |
| `orders.history` | 주문·체결 내역 | `/orders`, `/trades` |

주문 화면은 VI·상하한가·외국인 한도·거래정지 경고를 표시한다. 실행 결과는 Stock-exchange-BE의 mock ledger다.

## 뉴스·알림

| ID | 기능 | API |
| --- | --- | --- |
| `news.market` | 시장 뉴스, trending, 상세 | `/api/v1/market/news/**` |
| `notifications.inbox` | 알림 목록·필터·읽음 처리 | `/api/v1/accounts/{accountId}/notifications/**` |
| `notifications.devices` | push device 등록·비활성화 | `/notifications/devices/**` |

번역 상태, 원문 링크, What/Why/Impact, sentiment, importance, glossary를 표시한다. 잘린 요약이나 품질 메타 문구를 사용자 문장으로 조합하지 않는다.

## 글로벌 세무 자동화

| ID | 기능 | API |
| --- | --- | --- |
| `tax.status` | 최신 환급 케이스와 진행 상태 | `GET /api/v1/accounts/{accountId}/tax/refund-status` |
| `tax.upload.residence` | 거주자 증명서 선택·업로드 | `POST /tax/documents` |
| `tax.upload.apostille` | 아포스티유 선택·업로드 | `POST /tax/documents` |
| `tax.upload.reduced_rate` | 제한세율 적용신청서 선택·업로드 | `POST /tax/documents` |
| `tax.verification` | 문서별 OCR 진행·검증 결과 polling | `GET /tax/documents/{documentId}/verification` |
| `tax.case` | 검증 완료 3문서로 환급 케이스 생성 | `POST /tax/refund-cases` |
| `tax.sync` | Hana 상태 동기화 | `POST /tax/refund-status/sync` |

파일 선택은 `file_selector`를 사용한다. 세 문서를 순서대로 업로드하며 각 문서가 Hannah OCR `VERIFIED` 상태여야 다음 신청 단계가 열린다. 허용 확장자·MIME·크기 오류, OCR 진행, 검수 필요, 거절 사유를 분리해 표시한다. 파일명과 세무 데이터는 로그·샘플 화면에서 마스킹한다.

## 컨트롤러

`ExchangeSessionController`, `AccountController`, `MarketQuoteController`, `MarketIndexController`, `MarketCalendarController`, `MarketDetailController`, `MarketNewsController`, `WatchlistController`, `TradeController`, `NotificationController`, `TaxController`는 `ExchangeShell`에서 생성·주입한다. 기능 추가 시 controller, API client, 상태별 UI, 단위/widget test를 함께 갱신한다.
