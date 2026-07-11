# Flutter·Figma 작업 기준

## 작업 전

1. Figma node URL과 대상 화면 크기를 확인한다.
2. `.agents/docs/current-feature-inventory.md`에서 유지할 기능 ID와 controller·API 배선을 확인한다.
3. Figma의 component, variable, auto layout, typography, spacing, icon과 상태 variant를 읽는다.
4. 기존 `exchange_styles.dart`, `exchange_shared_widgets.dart`와 화면별 공통 widget을 먼저 찾는다.

## 구현 기준

- Figma component hierarchy와 auto layout 의도를 Flutter widget·Row·Column·Flex·constraint로 옮긴다.
- 고정 좌표는 장식 요소에만 사용한다. 화면 구조는 SafeArea, scroll, keyboard inset과 text scale을 지원한다.
- 색상·간격·radius·typography는 기존 token을 재사용하고 반복되는 새 값은 token으로 승격한다.
- SVG·PNG·font는 저장소 asset을 우선 사용한다. 임시 emoji, placeholder icon과 임의 원격 이미지를 추가하지 않는다.
- 기존 REST/WebSocket 기능, loading·empty·error·stale·reconnect 상태와 접근성 semantics를 유지한다.
- 주가·위험·세무 상태는 색상 외에 텍스트·아이콘·부호를 함께 제공한다.
- API key, token, 실제 계정·파일명·거래값을 Figma fixture나 코드 예시에 넣지 않는다.

## 컴포넌트 경계

- 셸과 controller 주입: `lib/src/app.dart`
- 디자인 token: `lib/src/features/exchange/shared/exchange_styles.dart`
- 공통 widget: `lib/src/features/exchange/shared/exchange_shared_widgets.dart`
- 화면 전용 widget: 해당 `lib/src/features/exchange/<feature>/` 디렉터리

리디자인으로 기능 위치가 바뀌면 기능 ID는 유지하고 `.agents/docs/current-feature-inventory.md`의 화면 위치를 갱신한다.

## 검증과 보고

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build ios --simulator --dart-define=EXCHANGE_API_BASE_URL=http://localhost:3000
```

PR에는 대상 Figma node, 변경 화면, 재사용·추가한 component/token, 유지한 기능 ID, 자동·Simulator 검증과 남은 시각 차이를 기록한다. 픽셀 비교보다 기능·접근성·반응형 회귀를 우선 차단한다.
