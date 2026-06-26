---
name: testing
description: Android 및 iOS 앱 프로젝트의 테스트 작성, 실행, 디버깅 방법을 안내한다. 모바일 앱 테스트케이스를 작성하거나 실행하는 경우 이 스킬을 사용한다.
---

# 모바일 앱 테스트 가이드

이 스킬은 Android/iOS 앱 개발 문맥의 테스트 작업에 사용한다. 다만 실제 실행 명령과 테스트 프레임워크는 프로젝트 스택에 따라 다르므로, Agent는 바로 테스트를 작성하거나 실행하기 전에 저장소 구조와 빌드 도구를 먼저 확인해야 한다.

## 먼저 확인할 것

테스트 작업 전 아래를 우선 확인한다.

- Android 네이티브: `build.gradle`, `build.gradle.kts`, `settings.gradle`, `app/src/test`, `app/src/androidTest`
- iOS 네이티브: `*.xcodeproj`, `*.xcworkspace`, `Package.swift`, `Tests`, `UITests`
- React Native: `package.json`, `android/`, `ios/`, `jest`, `detox`
- Flutter: `pubspec.yaml`, `test/`, `integration_test/`

Agent는 스택을 확인하기 전까지 특정 테스트 명령을 단정하지 않는다.

## 테스트 전략

모바일 앱 테스트는 아래 순서로 우선순위를 둔다.

1. 비즈니스 로직 단위 테스트
2. ViewModel, Presenter, UseCase, Reducer 등 상태 관리 계층 테스트
3. 네트워크, 로컬 저장소, DB 연동 테스트
4. 실제 사용자 흐름 기준 UI / 통합 테스트

임시보완책처럼 UI 테스트만 늘리지 말고, flaky하지 않은 단위 테스트와 상태 테스트를 먼저 확보한다.

## 테스트 실행 원칙

- 전체 테스트 실행 전에 변경 범위와 가장 가까운 테스트를 먼저 실행한다.
- 실패 재현 시에는 가장 좁은 테스트 단위부터 확인한다.
- Agent가 테스트를 실행할 때는 가능한 한 출력량이 과도하지 않은 옵션부터 사용한다.
- 시뮬레이터/에뮬레이터가 필요한 테스트는 로컬 환경 준비 상태를 먼저 확인한다.

## 스택별 기본 실행 명령

### Android 네이티브

로컬 JVM 단위 테스트:

```bash
./gradlew test
```

특정 모듈 또는 변형 테스트:

```bash
./gradlew :app:testDebugUnitTest
```

디바이스/에뮬레이터 기반 계측 테스트:

```bash
./gradlew connectedAndroidTest
```

### iOS 네이티브

Xcode scheme과 destination을 먼저 확인한 뒤 테스트를 실행한다.

```bash
xcodebuild test -scheme AppScheme -destination 'platform=iOS Simulator,name=iPhone 16'
```

Swift Package 기반 프로젝트라면:

```bash
swift test
```

### React Native

로직 단위 테스트:

```bash
npm test
```

E2E가 Detox 기반이면:

```bash
npx detox test
```

### Flutter

단위/위젯 테스트:

```bash
flutter test
```

통합 테스트:

```bash
flutter test integration_test
```

## 테스트 위치 가이드

### Android

- JVM 단위 테스트: `app/src/test/...`
- UI / 계측 테스트: `app/src/androidTest/...`

### iOS

- 단위 테스트: `YourAppTests/` 또는 `Tests/`
- UI 테스트: `YourAppUITests/` 또는 `UITests/`

### React Native

- 단위 테스트: `__tests__/`, `*.test.ts`, `*.spec.ts`
- E2E 테스트: `e2e/`

### Flutter

- 단위/위젯 테스트: `test/`
- 통합 테스트: `integration_test/`

## 테스트케이스 작성 원칙

- 화면 자체보다 로직 경계를 먼저 테스트한다.
- 네트워크, 시간, 디바이스 상태, 권한 상태는 실제 시스템에 의존하지 않도록 추상화 후 mocking 한다.
- 테스트명은 사용자 시나리오 또는 기대 결과가 드러나도록 작성한다.
- 하나의 테스트는 하나의 행동과 하나의 검증 이유를 갖도록 유지한다.

좋은 예:

- `로그인 성공 시 홈 화면으로 이동한다`
- `토큰 만료 응답을 받으면 재인증 상태로 전환한다`
- `빈 검색어 입력 시 API를 호출하지 않는다`

## UI 테스트 원칙

- 텍스트 문구 전체 일치보다 접근성 식별자, 테스트 태그, 고정 ID를 우선 사용한다.
- 시간 지연 기반 대기 대신 명시적 상태 대기를 사용한다.
- 애니메이션, 네트워크, 원격 이미지, 푸시 알림처럼 flaky 요인이 큰 부분은 테스트 대상에서 분리하거나 mock 처리한다.
- 스냅샷 테스트는 보조 수단으로만 사용하고, 핵심 로직 검증을 대신하지 않는다.

## Mocking / Stub / Fake 가이드

### 네트워크

- 실제 API 서버 호출 대신 repository/service 레이어에서 stub 또는 mock 을 사용한다.
- 성공, 실패, 타임아웃, 빈 응답, 잘못된 포맷 응답을 모두 분리해 검증한다.

### 시간

- 현재 시각에 의존하는 로직은 clock abstraction을 두고 고정 시간으로 테스트한다.

### 저장소

- 로컬 DB, Keychain, SharedPreferences, UserDefaults 등은 테스트 전용 fake 구현 또는 in-memory 저장소를 우선 사용한다.

### 권한 / 디바이스 상태

- 카메라, 위치, 알림, 네트워크 연결, 백그라운드 전환 등은 시스템 API 직접 호출 대신 wrapper를 두고 mock 한다.

## 프레임워크별 권장 도구

### Android

- 단위 테스트: `JUnit`, `Kotest`
- Mocking: `MockK`, `Mockito`
- Flow/Coroutine 테스트: `kotlinx-coroutines-test`, `Turbine`
- UI 테스트: `Espresso`, `Compose UI Test`

### iOS

- 단위 테스트: `XCTest`
- Mocking: 프로토콜 기반 test double, 필요 시 `Cuckoo`, `Mockingbird`
- 비동기 테스트: `XCTestExpectation`, `async/await` 테스트
- UI 테스트: `XCUITest`

### React Native

- 단위 테스트: `Jest`
- 컴포넌트 테스트: `@testing-library/react-native`
- E2E 테스트: `Detox`

### Flutter

- 단위/위젯 테스트: `flutter_test`
- Mocking: `mocktail`, `mockito`
- 상태 테스트: `bloc_test` 등 프로젝트 상태관리 방식에 맞는 도구
- 통합 테스트: `integration_test`

## 비동기 테스트 원칙

- sleep 기반 대기를 넣지 않는다.
- coroutine, async/await, stream, publisher, flow는 테스트 전용 scheduler 또는 dispatcher를 사용한다.
- 테스트 완료 조건은 "시간 경과"가 아니라 "상태 변화"로 검증한다.

## 에러 재현 기준

버그 수정 시에는 아래 순서를 우선한다.

1. 실패하는 테스트를 먼저 만든다.
2. 최소 수정으로 테스트를 통과시킨다.
3. 연관된 회귀 테스트까지 확인한다.

재현 테스트 없이 증상만 보고 임시 분기 처리로 덮지 않는다.

## CI 기준

- PR 단계에서는 빠른 단위 테스트를 우선 실행한다.
- 에뮬레이터/시뮬레이터 기반 UI 테스트는 비용이 크므로 병렬화와 분리가 필요하다.
- flaky 테스트는 일단 무시하지 말고 원인을 분리해 수정하거나 quarantine 기준을 명확히 둔다.

## Agent 작업 원칙

- 새 테스트를 추가할 때는 현재 프로젝트의 테스트 프레임워크와 디렉토리 규칙을 먼저 따른다.
- 기존에 `MockK`를 쓰는 프로젝트에 갑자기 `Mockito`를 섞지 않는다.
- iOS/Android 어느 한쪽만 수정해도, 공통 도메인 규칙에 영향이 있으면 반대 플랫폼 테스트 영향도 같이 확인한다.
- 테스트 실행 환경이 부족하면 없는 환경을 있는 것처럼 가정하지 말고, 어떤 테스트가 실행 불가한지 명시한다.
