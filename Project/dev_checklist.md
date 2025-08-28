# TypeTalk 개발 체크리스트

아래 체크리스트를 순서대로 진행하며, 각 항목을 완료하면 체크(✔) 표시 후 다음 단계로 이동하세요.

## 1. 프로젝트 환경 세팅
- [✔] Flutter 및 필수 패키지 설치
- [✔] 프로젝트 구조 및 폴더 정리

## 2. 디자인 시스템 적용
- [✔] 컬러, 폰트, 버튼 등 디자인 시스템 반영
- [✔] 공통 UI 컴포넌트 구현 (Button, Card, Input 등)

## 3. 주요 화면 개발
- [✔] 시작 화면 구현
- [✔] MBTI 질문 화면 구현
- [✔] 결과 화면 구현
- [✔] 프로필 화면 구현
- [✔] 채팅 화면 구현
- [✔] 바텀 바(네비게이션) 구현

## 4. 기능 개발
- [✔] MBTI 검사 로직 구현
- [✔] 회원가입/로그인 기능 구현
- [✔] 프로필 관리 기능 구현
- [✔] 매칭/추천 알고리즘 구현
- [✔] 실시간 채팅 기능 구현
- [✔] 알림/푸시 기능 구현

### (Firebase 기반 백엔드 기능 구현)
- [ ] Firebase 프로젝트 및 환경 세팅
    - [ ] Firebase 콘솔에서 프로젝트 생성 및 앱 등록(Android/iOS)
    - [ ] GoogleService-Info.plist, google-services.json 연동
    - [ ] 필수 패키지 설치 및 Firebase 초기화
- [✔] 인증(회원가입/로그인) 기능
    - [✔] Firebase Authentication(이메일/비밀번호) 연동
    - [✔] 소셜 로그인(Google, Apple 등) 연동
    - [✔] 인증 상태 관리 및 자동 로그인 처리
    - [✔] 회원 정보 Firestore/Realtime Database에 저장
- [✔] 프로필/매칭/추천 데이터 관리
    - [✔] Firestore/Realtime Database 구조 설계
    - [✔] 사용자 프로필 데이터 CRUD 구현
    - [✔] 매칭/추천 알고리즘 데이터 저장 및 조회
    - [✔] 데이터 보안 규칙(Firebase Rules) 설정
- [ ] 실시간 채팅 기능
    - [✔] 채팅방/메시지 데이터 구조 설계
    - [✔] 메시지 전송    - [✔] 채팅방/메시지 데이터 구조 설계
 Database)
    - [✔] 채팅 알림(푸시) 연동
    - [ ] 채팅 데이터 정합성 및 삭제 처리
- [✔] 알림/푸시 기능
    - [✔] Firebase Cloud Messaging(FCM) 연동
    - [✔] 토큰 발급 및 관리
- [✔] 이벤트 발생 시 푸시 알림 전송
- [✔] 알림 수신 및 앱 내 처리

- [✔] **채팅방/메시지 데이터 구조 설계 및 구현**
  - [✔] ChatModel 개선 (통계 정보 추가, DateTime 파싱 수정)
  - [✔] MessageModel 개선 (DateTime 파싱 수정)
  - [✔] ChatParticipantModel 개선 (DateTime 파싱 수정)
  - [✔] ChatInviteModel 개선 (DateTime 파싱 수정)
  - [✔] ChatNotificationModel 생성 (알림 시스템)
  - [✔] ChatSearchModel 생성 (검색 시스템)
  - [✔] ChatStatsService 생성 (통계 관리)
  - [✔] ChatSearchService 생성 (검색 관리)
  - [✔] ChatNotificationService 생성 (알림 관리)
  - [✔] FirestoreService 확장 (컬렉션 getter, 샘플 데이터)

## 5. 테스트 및 검증
- [✔] **flutter analyze**로 코드 정적 분석 및 오류 사전 점검
  - [✔] SearchStats 클래스에 const 생성자 추가
  - [✔] NotificationMetadata 클래스에 const 생성자 추가
  - [✔] ChatSearchService의 nullability 문제 수정
  - [✔] 모든 서비스를 main.dart에 등록
  - [✔] 빌드 오류 해결 및 성공적인 빌드 완료
- [ ] 각 화면별 UI/UX 테스트
- [ ] 주요 기능별 단위 테스트
- [ ] 통합 테스트 및 시나리오 테스트
- [ ] 접근성(색상 대비, 폰트 크기 등) 점검

### (Firebase 백엔드 테스트 및 검증)
- [ ] 각 기능별 Firebase 연동 테스트
- [ ] 에러/예외 처리 및 로깅
- [ ] 데이터 보안 규칙 및 접근 권한 검증

## 6. 버그 수정 및 최종 점검
- [ ] 발견된 버그 수정
- [ ] 불필요한 코드/리소스 정리
- [ ] 최종 빌드 및 배포 준비

- 프로필 화면
  - [✔] 6-1 내 정보 수정 시 프로필 업데이트 안됨
  - [ ] 6-2 재로그인시 MBTI 기록 삭제
  - [ ] 6-3 사용자 가입일이 현재 날짜로 바뀜
  - [✔] 6-4 회원 탈퇴 후 동일한 계정으로 재가입 시 회원가입 절차 없이 로그인됨

---

> 각 항목을 완료할 때마다 체크박스에 ✔ 표시하고, 테스트를 마친 후 다음 단계로 넘어가세요.
> 앱 테스트 전에는 반드시 `flutter analyze`를 실행하여 오류를 먼저 해결해야 합니다. 