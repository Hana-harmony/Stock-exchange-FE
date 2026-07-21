# 품질 로드맵

## 현재 운영 기준

- iOS/Android 셸, 인증·secure storage, 시장·검색·종목 상세·watchlist·계좌 화면을 구현했다.
- REST snapshot과 WebSocket 시세, stale·재연결, 차트·호가·글로벌 피어·주문 제한을 표시한다.
- 뉴스·공시 목록·상세, What/Why/Impact, 번역 상태, glossary와 알림함을 제공한다.
- 거주자 증명서·아포스티유·제한세율 적용신청서를 native file picker로 순차 업로드하고 OCR 진행·검증·환급 상태를 표시한다.
- controller·API client·parsing 단위 테스트와 핵심 widget test를 CI에서 실행한다.

## 다음 품질 기준

- iPhone·Android 주요 화면 크기, Dynamic Type·text scale, screen reader와 색상 대비 접근성을 검증한다.
- 실기기에서 secure storage, file picker, 네트워크 전환, background·resume과 WebSocket 재연결을 검증한다.
- 인증→검색→상세→mock 주문, 알림 원문, 세무 3문서 업로드→환급 신청의 integration test를 구축한다.
- 민감 파일명·계정·거래 정보가 crash report, analytics와 화면 캡처용 fixture에 노출되지 않게 점검한다.
- App Store·Play Store 서명, privacy manifest, 데이터 보존·삭제 안내와 release rollback 절차를 확정한다.

기능 완료 기준은 로딩·빈 상태·오류·stale 상태, 접근성, 자동 테스트와 실기기 결과를 포함한다.
# 2026-07-21 · 전문 번역 비동기 상세 조회

- 장문 번역을 기다리던 상세 요청의 504를 제거하기 위해 저장 이벤트를 즉시 받고 `translatedContent`가 채워질 때까지 재조회한다.
- 대기 중에는 전문 번역 준비 상태를 표시하고 제목·What/Why/Impact를 본문으로 합성하지 않는다.
- 화면을 닫으면 재조회를 중단하고 일시적인 조회 실패는 세 번까지 재시도한다.
