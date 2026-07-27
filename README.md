# Stock-exchange-FE

Flutter iOS/Android 기반 MTS 프론트엔드다. Flutter Web은 내부 QA·데모에서 앱 영역을 최대 430px로 유지한다. 사용자는 한국 상장주식의 실시간 시세, 종목 상세, 뉴스·공시 인텔리전스, 외국인 한도 신호, 모의 원장 기반 주문/자산, 세무 환급 상태를 영어 UI와 USD 환산 기준으로 확인한다.

## 주요 화면

| 실시간 투자 속보 | AI 스마트 브리핑 |
| --- | --- |
| ![보유·관심종목 실시간 알림](https://raw.githubusercontent.com/Hana-harmony/.github/main/images/15.png) | ![원문 근거 AI 스마트 브리핑](https://raw.githubusercontent.com/Hana-harmony/.github/main/images/17.png) |
| 글로벌 피어 비교 | 외국인 보유 한도 신호 |
| ![글로벌 피어 비교](https://raw.githubusercontent.com/Hana-harmony/.github/main/images/18.png) | ![외국인 보유 한도 예측](https://raw.githubusercontent.com/Hana-harmony/.github/main/images/22.png) |
| 세무 서류 업로드 | 세무 처리 현황 |
| ![세무 서류 순차 업로드](https://raw.githubusercontent.com/Hana-harmony/.github/main/images/27.png) | ![세무 신청 운영 화면](https://raw.githubusercontent.com/Hana-harmony/.github/main/images/29.png) |

## 핵심 기능
- Markets: KOSPI/KOSDAQ/KOSPI 200 지수, 1~10위가 한 줄로 표시되는 인기 종목, 검색, 시장별 시세
- 실시간 시세: Stock-exchange-BE WebSocket 구독, 재연결, stale 상태 표시
- 종목 상세: 기본 Chart 탭에서 외국인 보유 제한 예측·금지, 1D/1W/1M 차트, 보유 정보를 순서대로 표시하고 KRW/USD 가격, VI/서킷브레이커/상·하한가, K-News, 공시를 제공
- 글로벌 피어: AI가 종목별 사업요약에서 생성한 3개 comparison과 4개 Key Strength를 생략 없이 2×2로 표시
- Watchlist/Portfolio: 관심종목, 보유종목, 계좌별 quote snapshot과 WebSocket tick 반영
- 인증·계좌: secure storage 세션, access token 검증·자동 갱신, 비밀번호 확인과 6자리 거래 PIN을 포함한 단계형 가입, 거래 PIN 확인 USD 모의 원장 충전
- 주문 화면: 거래 PIN으로 승인하는 mock ledger 주문, orderability 경고/차단 표시
- 뉴스·알림함: Discover와 Notifications에 동일한 감성·중요도·날짜·썸네일 정보 계층을 적용하고, 관심·보유종목 All/My Portfolio/Watchlist 필터, 읽음 처리, 표준 Web Push 구독과 금융 고유어 클릭 해설 제공
- 세무 화면: 거주자 증명서·아포스티유·제한세율 적용신청서 파일 선택과 순차 업로드, OCR 진행·검증, Figma `998:10969` 기준 제출 완료 화면, 신청 Case와 승인 상태 표시. 수익 금액은 표시하지 않음

## 문서
- [아키텍처](docs/ARCHITECTURE.md)
- [기능 분류와 레포 책임](docs/FEATURE_CLASSIFICATION.md)
- [로컬 앱 테스트](docs/LOCAL_APP_TESTING.md)
- [로드맵](docs/ROADMAP.md)
