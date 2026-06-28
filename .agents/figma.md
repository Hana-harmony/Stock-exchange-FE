# Flutter + Figma MCP 개발 지침

## 최종 목표

Flutter 앱을 **Figma를 기준으로 처음부터 구현**한다.

Figma가 유일한 UI 명세(Single Source of Truth)이며, 디자인에 대한 추측이나 임의 해석 없이 최대한 동일하게 구현한다.

기존 Flutter 코드는 참고만 가능하며, 구현 기준은 아니다.

---

## 구현 원칙

### 1. Figma 우선 원칙

구현 전에 반드시 Figma MCP를 통해 아래 내용을 먼저 확인한다.

- Frame 구조
- Auto Layout
- Component
- Variant
- Variables
- Style
- Token
- Prototype
- Interaction
- Constraint
- Naming

Figma에 존재하는 정보가 항상 우선한다.

모르는 부분이 있으면 추측하지 말고 보고한다.

---

### 2. Pixel Perfect 구현

다음 항목을 최대한 동일하게 구현한다.

- 색상
- Typography
- Font Weight
- Font Size
- Line Height
- Letter Spacing
- Radius
- Border
- Shadow
- Opacity
- Padding
- Margin
- Gap
- Icon Size
- Safe Area
- Status Bar
- Navigation Bar
- Bottom Sheet
- Dialog
- Animation

"비슷하게" 구현하지 않는다.

---

### 3. Auto Layout 반영

Figma Auto Layout을 Flutter Widget 구조에 그대로 대응시킨다.

가능한 한 구조까지 동일하게 구현한다.

예시

- Vertical → Column
- Horizontal → Row
- Wrap → Wrap
- Gap → SizedBox
- Fill → Expanded
- Hug → MainAxisSize.min
- Padding → Padding
- Scroll → ListView / CustomScrollView

Absolute Position은 디자인상 반드시 필요한 경우에만 사용한다.

---

### 4. 디자인 토큰 우선

직접 값을 작성하지 않는다.

반드시 Figma Variable 또는 Style을 우선 사용한다.

금지

- Hex 직접 입력
- Radius 직접 입력
- FontSize 직접 입력
- Shadow 직접 입력

토큰이 없다면 공통 Theme로 분리한다.

---

### 5. 컴포넌트 재사용

새 Widget을 만들기 전에 Figma Component를 먼저 확인한다.

동일 Component가 있다면 그대로 구현한다.

Variant가 있다면 Flutter에서도 하나의 Widget으로 관리한다.

예시

- PrimaryButton
- SecondaryButton
- TextField
- Card
- BottomNavigation
- SearchBar
- Chip
- Badge
- Dialog

동일 UI를 여러 번 구현하지 않는다.

---

### 6. Flutter 구현 원칙

화면마다 스타일을 직접 작성하지 않는다.

공통 Theme와 Widget을 우선 사용한다.

가능한 구조

```
theme/
    app_colors.dart
    app_text_styles.dart
    app_spacing.dart
    app_radius.dart
    app_theme.dart

widgets/
    buttons/
    cards/
    inputs/
    dialogs/
    navigation/
```

---

### 7. 반응형

우선 기준

- iPhone 16 Pro

이후

- 작은 화면에서도 Overflow 발생 금지
- SafeArea 적용
- Keyboard 대응
- Bottom Navigation 겹침 방지

---

### 8. 기능 구현

UI 구현 중 API 명세가 있다면 그대로 사용한다.

명세가 없다면 임의 구현하지 않는다.

필요하면 TODO와 함께 보고한다.

---

### 9. 네이밍

Figma Layer 이름이 아니라 **역할 중심**으로 작성한다.

좋은 예

- ActivityCard
- SearchBar
- UserProfileHeader
- ReviewCard
- FilterChip
- ReportCard

나쁜 예

- Container1
- Frame13
- Widget2
- TempButton

---

### 10. 금지사항

금지

- Figma와 다른 디자인 적용
- 임의 여백 변경
- 임의 색상 사용
- 임의 Typography 사용
- 임의 Radius 사용
- 동일 Widget 중복 구현
- Component 무시
- Variant 무시
- Absolute Position 남용
- 하드코딩 스타일 작성

---

## 구현 완료 후 보고

반드시 아래 내용을 보고한다.

### 변경한 화면

- 화면명
- 대응 Figma Frame

### 생성한 Widget

- Widget명
- 사용 화면

### 재사용한 Figma Component

- Component명
- Variant

### 새로 만든 Theme

- Color
- Typography
- Radius
- Shadow
- Spacing

### 구현하지 못한 부분

- 이유
- 필요한 정보
- 제안사항

---

## 최종 체크리스트

- Figma와 시각적으로 거의 동일한가
- Component를 재사용했는가
- Variant를 모두 구현했는가
- Theme를 사용했는가
- 하드코딩 스타일이 없는가
- Overflow가 없는가
- Pixel Perfect 수준으로 구현되었는가
