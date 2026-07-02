---
name: testing
description: Flutter 기반 iOS 앱 프로젝트에서 실무적으로 필요한 테스트 작성, 실행, 디버깅 기준을 안내한다. Android, Web, 과도한 테스트 확장은 이 스킬 범위에 포함하지 않는다.
---

# iOS 테스트 가이드

이 스킬은 iOS 출하 경로에 영향이 있는 변경을 다룰 때 사용한다. 이 저장소는 Flutter 앱이므로, 기본 테스트 계층은 Dart/Flutter이고 `ios/` 네이티브 코드는 iOS 고유 동작이 바뀔 때만 별도로 검증한다.

핵심 원칙은 "버그를 막는 데 필요한 테스트만 추가하고, 설명만 늘리는 테스트는 쓰지 않는다"이다.

## 먼저 확인할 것

테스트를 쓰거나 실행하기 전에 아래를 먼저 본다.

- `pubspec.yaml`
- `test/`
- `ios/Runner/AppDelegate.swift`
- `ios/Podfile`
- `ios/Runner.xcodeproj/project.pbxproj`

먼저 판단해야 할 것은 아래 둘 중 어디가 바뀌었는지다.

1. 공통 Dart/Flutter 로직이 바뀌었는가
2. iOS 네이티브 동작만 바뀌었는가

현재 저장소에는 `test/` 아래 Dart 테스트가 있고, 별도 iOS `XCTest`/`XCUITest` 타깃은 보이지 않는다. 따라서 기본값은 `flutter test`다.

## 어떤 테스트를 우선할지

우선순위는 아래 순서로 잡는다.

1. Dart 단위 테스트
2. 필요한 경우 Flutter widget test
3. iOS 시뮬레이터 수동 검증
4. 정말 필요할 때만 iOS native test 도입 또는 확장

원칙은 간단하다.

- 도메인 로직, API 파싱, 상태 전이는 Dart 테스트로 막는다.
- iOS 권한, lifecycle, plugin bridge, secure storage 연동처럼 iOS에서만 달라지는 동작은 시뮬레이터 검증을 우선한다.
- native XCTest/XCUITest는 이미 타깃이 있거나, 같은 유형의 iOS 회귀가 반복되어 자동화 가치가 분명할 때만 고려한다.

## 테스트를 써야 하는 경우

아래 중 하나에 해당하면 테스트 추가를 우선 검토한다.

- 재현 가능한 버그를 수정했고 회귀 위험이 있다.
- 금액, 세금, 주문 가능 상태, 계좌 상태, 인증 상태처럼 잘못되면 실제 사용자 판단에 영향을 준다.
- API 응답 파싱, 에러 매핑, 빈 상태, 만료 세션, reconnect 같은 분기 로직이 바뀌었다.
- 알림, secure storage, 앱 재시작 후 세션 복원처럼 iOS 사용 흐름에 직접 닿는다.
- `AppDelegate`, plugin 초기화, 권한 요청, foreground/background 전환 등 iOS 고유 코드가 바뀌었다.

## 굳이 쓰지 않아도 되는 테스트

아래는 기본적으로 자동화 테스트를 추가하지 않는다.

- 단순 getter, setter, 상수 매핑만 확인하는 테스트
- Flutter 프레임워크 자체 동작을 다시 증명하는 테스트
- 정적 문구 하나만 확인하는 테스트
- 같은 분기를 이미 더 상위 또는 더 직접적인 테스트가 막고 있는 경우
- mock 설정이 더 길고 실제 검증값은 거의 없는 테스트
- 화면 픽셀 차이만 보는 snapshot/golden 테스트

실무 기준은 "이 테스트가 깨지면 실제 결함 가능성이 높은가"이다. 아니면 대개 쓰지 않는다.

## 이 저장소에서 권장하는 테스트 단위

현재 테스트 구조를 보면 아래 패턴이 기준이다.

- controller 상태 전이: `test/*_controller_test.dart`
- API 계약 및 파싱: `test/exchange_api_client_test.dart`
- 대표 화면 흐름: `test/widget_test.dart`

새 테스트도 이 결을 따른다.

- 로직 수정이면 해당 controller 또는 client 테스트에 붙인다.
- 화면 수정이어도 상태/분기 로직이 핵심이면 widget test보다 controller test를 먼저 본다.
- iOS 네이티브 파일만 바뀌었는데 Dart 레이어에 영향이 없으면, 무리해서 Flutter 테스트를 늘리지 않는다. 대신 빌드/시뮬레이터 검증 결과를 남긴다.

## 테스트 작성 원칙

- 테스트 하나는 하나의 실패 이유만 갖게 쪼갠다.
- 외부 의존성은 mock/stub/fake로 끊고 실제 서버를 호출하지 않는다.
- 시간, 세션, 권한, 네트워크 실패는 재현 가능한 입력으로 고정한다.
- 구현 상세보다 사용자 영향이 있는 상태 변화를 검증한다.
- 기존 프로젝트가 쓰는 패턴을 유지한다. 이 저장소에서는 `flutter_test`, `http/testing.dart` 기반 패턴이 이미 있다.

좋은 테스트 예시는 아래와 같다.

- 세션 만료 응답을 받으면 로그인 상태로 되돌린다.
- 빈 검색어면 API를 호출하지 않는다.
- iOS 알림 디바이스 등록 요청에 `platform: IOS`와 토큰이 포함된다.
- 앱 재시작 후 저장된 세션이 있으면 계좌 화면 초기 상태를 복원한다.

반대로 아래는 피한다.

- 버튼 색상 코드가 정확히 같은지 확인하는 테스트
- `Text('Markets')` 같은 정적 문자열만 단독으로 확인하는 테스트
- private 메서드 호출 순서를 그대로 박아 넣는 테스트

## 실행 원칙

가장 가까운 테스트부터 좁게 실행한다.

```bash
flutter test test/account_controller_test.dart
```

변경 범위가 넓거나 공통 로직이면 전체 Dart 테스트를 돌린다.

```bash
flutter test
```

iOS 네이티브 코드가 바뀌었고 컴파일 확인이 필요하면 Runner 빌드를 본다.

```bash
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -destination 'platform=iOS Simulator,name=iPhone 16' build
```

단, 시뮬레이터 이름이나 Xcode 환경이 맞지 않으면 있는 것처럼 가정하지 말고 실행 불가 사유를 기록한다.

## 수동 검증이 더 적절한 경우

아래는 자동화보다 iOS 시뮬레이터 수동 검증이 먼저다.

- 권한 팝업 노출 여부
- 앱 백그라운드/포그라운드 복귀
- 푸시 토큰 등록 시점
- Keychain/secure storage 실제 저장 여부
- plugin 초기화 실패나 iOS 런치 크래시

이 경우에도 "확인함"으로 끝내지 말고, 어떤 시나리오를 어떤 기기/시뮬레이터에서 봤는지 남긴다.

## Agent 작업 원칙

- 테스트는 변경을 정당화하는 최소 개수만 추가한다.
- 새 기능이라고 무조건 happy path, empty, error, permission, timeout, retry를 전부 다 쓰지 않는다. 실제로 깨질 가능성이 큰 분기만 고른다.
- 회귀 버그 수정이면 가능하면 실패 재현 테스트를 먼저 만든다.
- iOS native 테스트 타깃이 없는 저장소에 대규모 XCTest/XCUITest 도입을 먼저 제안하지 않는다. 반복되는 iOS 회귀가 쌓였을 때만 근거와 함께 제안한다.
- 실행하지 못한 테스트가 있으면 통과한 것처럼 쓰지 말고, 무엇이 막혔는지 분명히 남긴다.
