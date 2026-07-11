# Git 전략

## 브랜치

- `main`: 운영 release 기준
- `feature`: 검증된 UI·기능 변경 통합
- 작업 브랜치: 최신 `feature`에서 생성한 `<type>/<kebab-case-description>`
- type: `feat`, `fix`, `hotfix`, `refactor`, `docs`, `test`, `security`, `chore`, `release`

작업 브랜치 → `feature` PR을 체크 후 병합하고, 이어서 `feature` → `main` PR을 체크 후 병합한다. 보호 브랜치에 직접 push하지 않는다.

## 커밋과 PR

- 제목: `type(scope): 한글 제목`
- 본문: 배경, 변경 사항, 검증 결과, 영향 범위, rollback과 체크리스트
- PR에는 변경 화면, 유지한 기능 ID, API 계약, 접근성, 자동 테스트와 iOS/Android 검증 결과를 기록한다.
- format, analyze와 test CI가 통과한 PR만 squash merge한다.

Figma 기반 변경은 node URL과 component/token 재사용 내용을 포함하고 `.agents/docs/current-feature-inventory.md`를 함께 갱신한다.
