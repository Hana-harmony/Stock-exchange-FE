# Stock-exchange-FE

현지 거래소·브로커 MTS 프론트엔드 예시 서비스다. Flutter 기반 iOS/Android 영어 모바일 앱으로 구현하며, Stock-exchange-BE가 제공하는 사용자별 모든 한국 상장주식 데이터, 매매제한 신호, 뉴스·공시 인텔리전스, 세무 환급 상태를 USD 기준 화면으로 제공한다.

## 플랫폼
- Flutter
- iOS 앱
- Android 앱
- Web은 운영 대상이 아니라 내부 QA 또는 데모가 필요한 경우에만 별도 검토한다.

## 빠른 시작
```bash
flutter pub get
flutter test
```

로컬 앱 실행과 검증은 [로컬 앱 테스트](docs/LOCAL_APP_TESTING.md)를 따른다. `Stock-exchange-FE`는 iOS/Android 앱이므로 Docker로 앱을 띄우는 방식을 표준으로 두지 않는다.

## 현재 구현 상태
- Material 3 앱 shell과 Market, Portfolio, Alerts, Tax 하단 탭이 구현되어 있다.
- Market 화면은 KRW/USD 시세, WebSocket live 상태, REST snapshot 복구 상태, 환율 기준시각/출처 표시 영역을 가진다.
- Portfolio 화면은 mock USD cash와 실제 주문이 아닌 자체 ledger 기반 거래 영역을 가진다.
- Alerts 화면은 AI 번역 뉴스·공시, 원문 링크, My Portfolio/Watchlist 필터 영역을 가진다.
- Tax 화면은 서류 상태, 환급 추정, 매도 실현손익 기반 입력, 선지급 후 환수 리스크 고지 영역을 가진다.
- `ExchangeApiClient`는 Stock-exchange-BE 공통 응답 envelope와 bearer auth session header를 처리한다.
- `ExchangeSessionController`는 login, restore, refresh, sign out 상태 전이와 session store 경계를 제공한다.
- `AccountController`는 mock USD account REST 조회와 실제 결제 없는 deposit API 호출 상태를 관리한다.
- `TradeController`는 orderability 확인, 자체 mock ledger 주문 실행, portfolio/holding/recent trade 조회 상태를 관리한다.
- Market/Portfolio 세션 패널은 username/password 로그인, 회원가입 후 로그인, refresh, sign out 액션을 session controller에 연결한다.
- Portfolio 화면은 로그인된 accountId로 mock USD cash balance를 조회하고, 입력한 금액으로 실제 결제 없는 mock USD deposit을 실행한다.
- Portfolio 화면은 KIS 주문을 보내지 않는 자체 mock order pad와 orderability 경고/차단 표시를 제공한다.
- `MarketQuoteController`는 Stock-exchange-BE REST snapshot을 조회해 Market 화면의 KRW/USD quote와 FX metadata를 갱신한다.
- `MarketQuoteLiveClient`는 Stock-exchange-BE `/ws/market` STOMP WebSocket에 연결해 market quote topic tick을 구독하고 Market 화면의 quote list에 병합한다.
- `MarketQuoteController`는 WebSocket이 예기치 않게 닫히면 backoff 후 마지막 market/watchlist/portfolio topic을 재구독한다.
- Portfolio 화면은 bearer auth session의 accountId로 watchlist/portfolio quote REST snapshot을 갱신하고 account-scoped WebSocket topic을 구독한다.
- Market 화면은 Stock-exchange-BE REST로 종목 상세, KRX 기반 과거 차트, 호가 snapshot을 조회해 KRW 가격과 USD 환산 가격, 외국인 한도, VI/상·하한가 상태를 표시한다.
- Tax 화면은 bearer auth session의 accountId로 세무 환급 상태를 조회하고, 정부 검증 상태/참조번호와 원천징수세 대비 조세조약세·환급 가능분 비중을 표시한다.
- 앱 기본 session 저장소는 `flutter_secure_storage` 기반 token secure storage를 사용한다.
- 실제 iOS/Android 플랫폼 target 세부 설정은 후속 구현 대상이다.

## 범위
- 한국 주식 종목 검색과 종목 상세 화면
- 전체 종목, 시장별 종목, watchlist, 보유종목의 실시간 시세 조회 화면
- 실시간 시세 WebSocket 구독과 재연결/복구 처리
- 원화 가격과 실시간 환율 적용 USD 가격 동시 표시
- 과거 시세 차트 화면
- 외국인 보유율/한도소진율 게이지
- 당일 예측 지분율 boundary 표시
- VI 발동, 단일가 매매, 상·하한가 상태 배지
- 아이디/비밀번호 회원가입, 로그인, mock USD 계좌 잔고 화면
- 실제 결제 없는 달러 충전 화면
- KIS 모의투자 API가 아닌 Stock-exchange-BE 자체 mock ledger 기반 주문 패드와 주문 제한/주의 팝업
- 매도 내역과 실현손익 표시
- 종목별 K-News 인텔리전스 피드
- 보유종목/watchlist 기반 통합 알림함
- 세무 서류 업로드, 환급 상태, 환급 신청, 선지급 완료/리스크 고지 화면

## 책임 경계
- Hana-OmniLens-API를 직접 호출하지 않고 Stock-exchange-BE를 통해 데이터를 받는다.
- API key, 외부 API credential, push provider token은 프론트엔드에 두지 않는다.
- 실제 주문 체결, 정산, 환전, 실제 결제, 세무 지급/환수 실행은 화면에서 직접 처리하지 않고 백엔드 상태를 표시한다.

## 주요 화면
- 종목 상세: 현재가 KRW, USD 환산 가격, 적용 환율 기준시각, 외국인 투자한도 게이지, 당일 예상 범위, VI/상·하한가 배지
- 주문/자산: mock USD 잔고, 모의 매수·매도 기준 가격, 평가금액, 매도 실현손익, 외국인 한도 도달 주의
- 주문 패드: VI 발동 또는 상·하한가 도달 시 즉시 체결 불가능 안내
- K-News: 번역 제목, 요약, 감성, 중요도, 이벤트 태그, 원문 링크
- 알림함: All, My Portfolio, Watchlist 필터와 실시간 푸시 타임라인
- 세무: 서류 등록, 정부 검증 상태, 정산 상세, 환급 신청, 선지급 완료/사후 환수 리스크 고지

## 문서
- [아키텍처](docs/ARCHITECTURE.md)
- [기능 분류와 레포 책임](docs/FEATURE_CLASSIFICATION.md)
- [로컬 앱 테스트](docs/LOCAL_APP_TESTING.md)
- [로드맵](docs/ROADMAP.md)
