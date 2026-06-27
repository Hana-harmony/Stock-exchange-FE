# 페이지구조
불확실한건 하드코딩, 더미코딩 한다.

## 첫 화면
- https://www.figma.com/design/9moVhLUkZRSfnnCAPeqwKS/%ED%95%98%EB%82%98%EA%B8%88%EC%9C%B5%EA%B7%B8%EB%A3%B9?node-id=505-457&t=keV3umEGH6hBhejd-11
- Makrets가 선택된것이 첫 화면임. 
- 검색창 제외하고는 더미로 구현하면 됨
- trending stocks
  - 각 목록 상승: https://www.figma.com/design/9moVhLUkZRSfnnCAPeqwKS/%ED%95%98%EB%82%98%EA%B8%88%EC%9C%B5%EA%B7%B8%EB%A3%B9?node-id=485-760&t=keV3umEGH6hBhejd-11
  - 각 목록 하락: https://www.figma.com/design/9moVhLUkZRSfnnCAPeqwKS/%ED%95%98%EB%82%98%EA%B8%88%EC%9C%B5%EA%B7%B8%EB%A3%B9?node-id=505-5796&t=keV3umEGH6hBhejd-11
- 여기서 헤더 우측에 있는 https://www.figma.com/design/9moVhLUkZRSfnnCAPeqwKS/%ED%95%98%EB%82%98%EA%B8%88%EC%9C%B5%EA%B7%B8%EB%A3%B9?node-id=505-475&t=keV3umEGH6hBhejd-11 에서 돋보기 아이콘을 누르면 화면 2로 이동함.
  - 돋보기 아이콘 : assets/icons/header_search.png
  - 그 오른쪽 아이콘: assets/icons/header_notifications.png
- 상단 주식 3개 정보
  - 하락: https://www.figma.com/design/9moVhLUkZRSfnnCAPeqwKS/%ED%95%98%EB%82%98%EA%B8%88%EC%9C%B5%EA%B7%B8%EB%A3%B9?node-id=505-5807&t=keV3umEGH6hBhejd-11
    - assets/illustrations/stock_card_red.png
  - 상승: https://www.figma.com/design/9moVhLUkZRSfnnCAPeqwKS/%ED%95%98%EB%82%98%EA%B8%88%EC%9C%B5%EA%B7%B8%EB%A3%B9?node-id=505-4043&t=keV3umEGH6hBhejd-11
    - assets/illustrations/stock_card_green.png
- 그 아래 카드 영역은 일단 assets/illustrations/MarketDataContainer.png로 임시구현

## 화면 2 
- 검색화면임
- 전체: https://www.figma.com/design/9moVhLUkZRSfnnCAPeqwKS/%ED%95%98%EB%82%98%EA%B8%88%EC%9C%B5%EA%B7%B8%EB%A3%B9?node-id=482-273&t=keV3umEGH6hBhejd-11
- 검색 바
  - 일반: https://www.figma.com/design/9moVhLUkZRSfnnCAPeqwKS/%ED%95%98%EB%82%98%EA%B8%88%EC%9C%B5%EA%B7%B8%EB%A3%B9?node-id=485-404&t=keV3umEGH6hBhejd-11
  - 입력 중: https://www.figma.com/design/9moVhLUkZRSfnnCAPeqwKS/%ED%95%98%EB%82%98%EA%B8%88%EC%9C%B5%EA%B7%B8%EB%A3%B9?node-id=485-412&t=keV3umEGH6hBhejd-11
  - 입력 완료: https://www.figma.com/design/9moVhLUkZRSfnnCAPeqwKS/%ED%95%98%EB%82%98%EA%B8%88%EC%9C%B5%EA%B7%B8%EB%A3%B9?node-id=485-418&t=keV3umEGH6hBhejd-11
- 검색바 아래에는 search history, most searched, trending 존재
  - most searched 각 목록: https://www.figma.com/design/9moVhLUkZRSfnnCAPeqwKS/%ED%95%98%EB%82%98%EA%B8%88%EC%9C%B5%EA%B7%B8%EB%A3%B9?node-id=485-760&t=keV3umEGH6hBhejd-11
- https://www.figma.com/design/9moVhLUkZRSfnnCAPeqwKS/%ED%95%98%EB%82%98%EA%B8%88%EC%9C%B5%EA%B7%B8%EB%A3%B9?node-id=505-7797&t=keV3umEGH6hBhejd-11 처럼 키보드가 보임 
- 검색시 화면 3으로 이동

## 화면 3
- 전체: https://www.figma.com/design/9moVhLUkZRSfnnCAPeqwKS/%ED%95%98%EB%82%98%EA%B8%88%EC%9C%B5%EA%B7%B8%EB%A3%B9?node-id=505-758&t=keV3umEGH6hBhejd-11
- 한국 국가코드: https://www.figma.com/design/9moVhLUkZRSfnnCAPeqwKS/%ED%95%98%EB%82%98%EA%B8%88%EC%9C%B5%EA%B7%B8%EB%A3%B9?node-id=505-4295&t=keV3umEGH6hBhejd-11
  - assets/icons/country_badge_kr.png
- 홍콩 국가코드: https://www.figma.com/design/9moVhLUkZRSfnnCAPeqwKS/%ED%95%98%EB%82%98%EA%B8%88%EC%9C%B5%EA%B7%B8%EB%A3%B9?node-id=505-4297&t=keV3umEGH6hBhejd-11
  - assets/icons/country_badge_hk.png
- 한국 국기: https://www.figma.com/design/9moVhLUkZRSfnnCAPeqwKS/%ED%95%98%EB%82%98%EA%B8%88%EC%9C%B5%EA%B7%B8%EB%A3%B9?node-id=505-7162&t=keV3umEGH6hBhejd-11
  - assets/icons/korea_flag_icon.png
- 큰 화살표: assets/icon/arrow_up_icon_big.png
검색시 검색 결과가 나오는 화면임
- 각 목록: https://www.figma.com/design/9moVhLUkZRSfnnCAPeqwKS/%ED%95%98%EB%82%98%EA%B8%88%EC%9C%B5%EA%B7%B8%EB%A3%B9?node-id=505-6170&t=keV3umEGH6hBhejd-11
- 즐겨찾기도 가능
  - 즐겨찾기 아이콘:   - assets/icons/favorite_icon.png
- 목록 하나를 클릭시 화면 4로 넘어감

## 화면 4
- 전체: https://www.figma.com/design/9moVhLUkZRSfnnCAPeqwKS/%ED%95%98%EB%82%98%EA%B8%88%EC%9C%B5%EA%B7%B8%EB%A3%B9?node-id=608-4146&t=keV3umEGH6hBhejd-11
- 상단 고정: https://www.figma.com/design/9moVhLUkZRSfnnCAPeqwKS/%ED%95%98%EB%82%98%EA%B8%88%EC%9C%B5%EA%B7%B8%EB%A3%B9?node-id=608-4160&t=keV3umEGH6hBhejd-11
- 하단 order, chart, fundamentals, k-news 탭 존재
- 탭 컴포넌트 : https://www.figma.com/design/9moVhLUkZRSfnnCAPeqwKS/%ED%95%98%EB%82%98%EA%B8%88%EC%9C%B5%EA%B7%B8%EB%A3%B9?node-id=485-526&t=keV3umEGH6hBhejd-11
  - 선택됨:https://www.figma.com/design/9moVhLUkZRSfnnCAPeqwKS/%ED%95%98%EB%82%98%EA%B8%88%EC%9C%B5%EA%B7%B8%EB%A3%B9?node-id=485-470&t=keV3umEGH6hBhejd-11
  - 비선택: https://www.figma.com/design/9moVhLUkZRSfnnCAPeqwKS/%ED%95%98%EB%82%98%EA%B8%88%EC%9C%B5%EA%B7%B8%EB%A3%B9?node-id=485-472&t=keV3umEGH6hBhejd-11
- 맨처음에는 order탭으로 들어와짐
- 우선 order, chart, fundamentals, k-news 세부페이지는 빈화면으로 구현

