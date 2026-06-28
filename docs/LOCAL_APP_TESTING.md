# 로컬 앱 테스트

`Stock-exchange-FE`는 Flutter 기반 iOS/Android 앱이다. 운영 대상은 모바일 앱이므로 Docker 컨테이너로 앱을 띄우는 방식을 표준으로 두지 않는다.

## 공통 검증

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

한 번만 아래 명령으로 Git hook을 설치하면 커밋 시 변경된 Dart 파일 formatter가 자동 적용되고, 푸시 시 analyze/test가 실행된다.

```bash
python3 -m pip install --user pre-commit
python3 -m pre_commit install --hook-type pre-commit --hook-type pre-push
python3 -m pre_commit run --all-files
```

## iOS Simulator

macOS와 Xcode가 필요하다. `ios/Runner.xcworkspace`와 `ios/Runner.xcodeproj`는 저장소에 포함되어 있으며, CocoaPods 설정은 `ios/Podfile`을 기준으로 한다.

```bash
open -a Simulator
flutter devices
flutter run -d ios
```

## Android Emulator

Android Studio 또는 Android SDK/Emulator가 필요하다. `android/app` target은 `com.hanaharmony.stockexchange` application id와 인터넷/알림 권한을 포함한다.

```bash
flutter devices
flutter run -d android
```

## 백엔드 연결

로컬 백엔드는 Docker로 띄울 수 있다. 앱은 `Stock-exchange-BE`만 호출하지만, 뉴스·공시 AI 분석과 종목 상세 계약까지 함께 확인하려면 `Hannah-Montana-AI -> Hana-OmniLens-API -> Stock-exchange-BE` 순서로 실행한다.

```bash
cd ../Hannah-Montana-AI
docker compose -f compose.local.yml up -d --build
curl -fsS http://localhost:8000/health

cd ../Hana-OmniLens-API
docker compose -f compose.local.yml up -d --build
curl -fsS http://localhost:8080/actuator/health

cd ../Stock-exchange-BE
docker compose -f compose.local.yml up -d --build
curl -fsS http://localhost:3000/actuator/health
```

기본 포트는 Hannah `8000`, OmniLens API `8080`, Stock-exchange-BE `3000`이다. 두 Spring 백엔드를 동시에 띄울 때 OmniLens PostgreSQL host port는 `5432`, Stock-exchange-BE PostgreSQL host port는 `5433`을 사용한다. 앱은 `Stock-exchange-BE` API만 호출한다. iOS Simulator는 호스트의 `localhost:3000`을 사용할 수 있고, Android Emulator는 일반적으로 `10.0.2.2:3000`을 사용한다.

API base URL은 Flutter compile-time 환경값으로 지정한다.

```bash
flutter run -d ios --dart-define=EXCHANGE_API_BASE_URL=http://localhost:3000
flutter run -d android --dart-define=EXCHANGE_API_BASE_URL=http://10.0.2.2:3000
```

## Docker 사용 경계

- iOS 앱 빌드와 Simulator 실행은 Docker에서 처리하지 않는다.
- Android emulator/device 실행도 Docker 표준 경로로 두지 않는다.
- CI에서는 Flutter SDK 기반 `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, `flutter test`를 수행한다.
