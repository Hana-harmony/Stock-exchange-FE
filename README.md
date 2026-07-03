# Stock-exchange-FE

Flutter 기반 iOS/Android MTS 프론트엔드다. 사용자는 한국 상장주식의 실시간 시세, 종목 상세, 뉴스·공시 인텔리전스, 외국인 한도 신호, 모의 원장 기반 주문/자산, 세무 환급 상태를 영어 UI와 USD 환산 기준으로 확인한다.

## 핵심 기능
- Markets: KOSPI/KOSDAQ/KOSPI 200 지수, 인기 종목, 검색, 시장별 시세
- 실시간 시세: Stock-exchange-BE WebSocket 구독, 재연결, stale 상태 표시
- 종목 상세: 1D/1W/1M 차트, KRW/USD 가격, 외국인 보유 제한, VI/상·하한가, 호가, K-News, 공시
- Watchlist/Portfolio: 관심종목, 보유종목, 계좌별 quote snapshot과 WebSocket tick 반영
- 주문 화면: 실제 주문이 아닌 mock ledger 주문, orderability 경고/차단 표시
- 알림함: 뉴스·공시·세무 리스크 알림, 읽음 처리, push device 등록 상태
- 세무 화면: 서류 업로드, 환급 신청 상태, 매도 실현손익 기반 입력, 사후 환수 리스크 안내

## 실행
```bash
flutter pub get
flutter test
flutter run --dart-define=EXCHANGE_API_BASE_URL=http://localhost:13001
```

로컬 앱 검증 절차는 [docs/LOCAL_APP_TESTING.md](docs/LOCAL_APP_TESTING.md)를 따른다. 백엔드는 `Hannah-Montana-AI -> Hana-OmniLens-API -> Stock-exchange-BE` 순서로 먼저 띄운다.

## 검증
```bash
dart format lib test
flutter analyze
flutter test
flutter build ios --simulator --dart-define=EXCHANGE_API_BASE_URL=http://localhost:13001
```

## 책임 경계
- FE는 Stock-exchange-BE만 호출한다.
- Hana-OmniLens-API, Hannah-Montana-AI, 외부 provider key는 앱에 노출하지 않는다.
- 실제 주문 체결, 정산, 환전, 세무 지급/환수 실행은 FE 책임이 아니다.

## 문서
- [아키텍처](docs/ARCHITECTURE.md)
- [기능 분류와 레포 책임](docs/FEATURE_CLASSIFICATION.md)
- [로컬 앱 테스트](docs/LOCAL_APP_TESTING.md)
- [로드맵](docs/ROADMAP.md)
