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
- Web target은 운영 대상이 아니라 내부 QA 또는 데모 용도로만 사용한다.

## 로컬 검증
```bash
flutter analyze
flutter test
```
