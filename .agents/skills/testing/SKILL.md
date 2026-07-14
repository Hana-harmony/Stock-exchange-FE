---
name: stock-exchange-fe-testing
description: Stock-exchange-FE의 Dart 단위·Widget 테스트와 iOS Simulator 검증 기준
---

# Flutter 테스트 가이드

## 필수 순서

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --dart-define=EXCHANGE_API_BASE_URL=http://localhost:3000
```

네트워크 계약, controller 상태 전이, parsing, token 저장, glossary 단어 경계는 단위 테스트로 검증한다. 화면 이동, 로딩·빈 상태·오류·stale 표시, 주요 CTA와 세무 파일 선택 흐름은 widget test로 검증한다.

## 변경별 테스트

- `lib/src/core/`: 대응하는 `test/*_controller_test.dart` 또는 client test를 추가한다.
- 공통 parsing·formatting: 순수 함수 테스트를 우선한다.
- 화면·위젯: 의미 있는 key와 사용자 동작을 기준으로 검증한다. 구현 세부 트리 전체 snapshot에 의존하지 않는다.
- WebSocket: reconnect, 중복 tick, malformed payload, stale 전이를 검증한다.
- 인증·세무: 토큰·파일명·개인정보가 오류 문구와 로그에 노출되지 않는지 확인한다.

## iOS Simulator

```bash
flutter build ios --simulator --dart-define=EXCHANGE_API_BASE_URL=http://localhost:3000
```

네이티브 plugin, 파일 선택, secure storage, SafeArea, 키보드, 실제 화면 크기 문제는 Simulator에서 수동 확인한다. 수동 검증 결과는 PR 본문에 기기·OS·시나리오와 함께 남긴다.

테스트를 건너뛸 때는 실행 불가 원인과 대신 수행한 검증을 기록한다.
