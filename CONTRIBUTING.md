# 기여 가이드

## 개발 흐름
- 브랜치와 커밋 규칙은 [Git 전략](docs/GIT_STRATEGY.md)을 따른다.
- 일반 작업은 최신 `feature`에서 작업 브랜치를 생성한다.
- PR은 `feature` 대상으로 생성하고, 운영 반영은 `feature`에서 `main`으로 릴리스 PR을 만든다.

## 커밋 템플릿
```bash
git config commit.template .gitmessage.txt
```

## 변경 기준
- 화면/API 계약 변경은 README, 아키텍처 문서, 테스트를 함께 갱신한다.
- 민감정보와 외부 token은 프론트엔드 코드와 문서 예시에 원문으로 남기지 않는다.
- 운영 빌드는 iOS와 Android를 대상으로 한다. Web target은 내부 QA·데모 용도로 제한한다.

## 로컬 검증
```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Git hook 설정
커밋 시 formatter를 자동 적용하고, 푸시 전에 정적 검사와 테스트를 강제하려면 아래 명령으로 `pre-commit`을 설치한다.

```bash
python3 -m pip install --user pre-commit
python3 -m pre_commit install --hook-type pre-commit --hook-type pre-push
python3 -m pre_commit run --all-files
```
