# 로컬 앱 테스트

`Stock-exchange-FE`의 운영 대상은 Flutter Web이다. 브라우저 폭이 넓어도 앱 영역은 최대 430px이며, 좁은 화면에서는 가용 폭을 사용한다.

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

## 웹 실행

```bash
flutter run -d chrome \
  --web-port=15100 \
  --dart-define=EXCHANGE_API_BASE_URL=http://localhost:3000 \
  --dart-define=WEB_PUSH_VAPID_PUBLIC_KEY=<VAPID_PUBLIC_KEY>
```

`15100`은 Stock-exchange-BE의 로컬 CORS·WebSocket 허용 Origin이다. 임의 포트로 실행하면 REST preflight와 실시간 시세 WebSocket 연결이 차단될 수 있다.

Web Push 권한은 로그인만으로 요청하지 않는다. Notifications 화면의 알림 활성화 버튼을 누르면 service worker와 브라우저 구독을 생성하고 전체 `PushSubscription` JSON을 백엔드에 등록한다. 운영 배포는 HTTPS가 필요하며 localhost만 개발 예외다. 웹 전용 배포에는 APNs 자격증명이 필요 없다.

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

기본 포트는 Hannah `8000`, OmniLens API `8080`, Stock-exchange-BE `3000`이다. 두 Spring 백엔드를 동시에 띄울 때 OmniLens PostgreSQL host port는 `5432`, Stock-exchange-BE PostgreSQL host port는 `25434`를 사용한다. 앱은 `Stock-exchange-BE` API만 호출한다.

API base URL은 Flutter compile-time 환경값으로 지정한다.

```bash
flutter build web --release \
  --dart-define=EXCHANGE_API_BASE_URL=https://api.example.com \
  --dart-define=WEB_PUSH_VAPID_PUBLIC_KEY=<VAPID_PUBLIC_KEY>
```

## 검증 경계

- CI는 format, analyze, test와 release web build를 수행한다.
- Web Push는 실제 HTTPS origin, service worker, VAPID 키, 브라우저 권한이 모두 있는 통합 환경에서 최종 검증한다.
