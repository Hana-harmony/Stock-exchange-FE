# 로컬 앱 테스트

`Stock-exchange-FE`는 Flutter 기반 iOS/Android 앱이다. 운영 대상은 모바일 앱이므로 Docker 컨테이너로 앱을 띄우는 방식을 표준으로 두지 않는다.

## 공통 검증

```bash
flutter pub get
flutter analyze
flutter test
```

## iOS Simulator

macOS와 Xcode가 필요하다.

```bash
open -a Simulator
flutter devices
flutter run -d ios
```

## Android Emulator

Android Studio 또는 Android SDK/Emulator가 필요하다.

```bash
flutter devices
flutter run -d android
```

## 백엔드 연결

로컬 백엔드는 Docker로 띄울 수 있다.

```bash
cd ../Hana-OmniLens-API
docker compose -f compose.local.yml up --build

cd ../Stock-exchange-BE
docker compose -f compose.local.yml up --build
```

앱은 `Stock-exchange-BE` API만 호출한다. iOS Simulator는 호스트의 `localhost:3000`을 사용할 수 있고, Android Emulator는 일반적으로 `10.0.2.2:3000`을 사용한다.

## Docker 사용 경계

- iOS 앱 빌드와 Simulator 실행은 Docker에서 처리하지 않는다.
- Android emulator/device 실행도 Docker 표준 경로로 두지 않는다.
- CI에서 필요하면 Flutter SDK 기반 `flutter analyze`와 `flutter test`만 수행한다.
