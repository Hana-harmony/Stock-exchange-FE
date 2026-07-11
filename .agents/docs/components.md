# 공통 컴포넌트 기준

## 앱 셸

- `AppHeader`: 로고, 검색, 알림, 계정 진입을 제공한다.
- `AppBottomNavigation`: Home, Discover, Markets, Watchlists, Accounts, My 탭을 유지한다.
- 모든 최상위 화면은 `SafeArea`와 키보드·하단 inset을 반영한다.

## 공통 스타일

- 색상·간격·타이포그래피는 `exchange_styles.dart`의 토큰을 우선 사용한다.
- 공통 카드, 상태 배지, 빈 상태, 오류 상태, 로딩 표시는 `exchange_shared_widgets.dart`를 재사용한다.
- 주가 상승·하락 색상만으로 의미를 전달하지 않고 부호·텍스트·아이콘을 함께 표시한다.
- Pretendard font와 등록된 `assets/icons`, `assets/illustrations`, 종목 로고를 사용한다.

## 화면 컴포넌트

- 검색 UI: `search/search_widgets.dart`
- 시장: `market/market_screen.dart`
- 종목 상세: `stock_detail/stock_detail_components.dart`, `stock_detail/widgets/`
- 뉴스 카드: `stock_detail/widgets/stock_news_cards.dart`
- 주문: `stock_detail/stock_order_entry_screen.dart`
- 관심종목: `watchlist/watchlist_screen.dart`
- 세무: `accounts/tax_refund_request_screen.dart`

새 위젯을 만들기 전에 동일한 상태·레이아웃 컴포넌트가 있는지 확인한다. 화면 전용 코드는 해당 feature 디렉터리에 두고 `app.dart`에는 셸과 주입만 둔다.
