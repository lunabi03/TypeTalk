# TypeTalk - 데모 모드

## 🎯 개요

현재 TypeTalk 앱은 **데모 모드**로 구성되어 있습니다. Firebase 웹 플랫폼의 호환성 문제로 인해 실제 Firebase 대신 로컬 데모 시스템을 사용합니다.

## 🚀 데모 모드 기능

### ✅ 구현된 기능

1. **자동 로그인**
   - 앱 시작 시 자동으로 데모 사용자로 로그인
   - 사용자 정보: `demo@typetalk.com` / `데모 사용자`

2. **회원가입/로그인 시뮬레이션**
   - 완전한 UI/UX 플로우
   - 폼 유효성 검증
   - 로딩 상태 및 에러 처리
   - 성공/실패 피드백

3. **프로필 관리**
   - 실시간 사용자 정보 표시
   - MBTI 테스트 횟수 카운트
   - 프로필 업데이트 기능

4. **데이터 영속성**
   - 세션 동안 데이터 유지
   - 로컬 메모리 기반 저장소

### 🎨 UI/UX 특징

- 모든 인증 화면 완성
- 반응형 디자인 (flutter_screenutil)
- 깔끔한 디자인 시스템
- 부드러운 애니메이션 및 전환

## 🔧 기술 스택

- **상태 관리**: GetX
- **UI**: Flutter + ScreenUtil
- **데이터**: 로컬 메모리 (데모용)
- **라우팅**: Get Navigation

## 📱 사용 방법

1. 앱을 실행하면 자동으로 메인 화면으로 이동
2. 프로필 탭에서 사용자 정보 확인 가능
3. 로그아웃 후 로그인/회원가입 플로우 테스트 가능
4. 모든 폼 유효성 검증 및 에러 처리 확인 가능

## 🔄 실제 Firebase로 전환

향후 실제 Firebase를 연동하려면:

1. `pubspec.yaml`에 Firebase 패키지 추가:
```yaml
dependencies:
  firebase_core: ^latest
  firebase_auth: ^latest
  cloud_firestore: ^latest
```

2. `lib/services/auth_service.dart`에서 데모 코드를 실제 Firebase 코드로 교체
3. `lib/controllers/auth_controller.dart`에서 데이터 타입을 Firebase 타입으로 변경
4. Firebase 프로젝트 설정 파일 추가

## 🎯 데모 모드의 장점

- **빠른 개발**: Firebase 설정 없이 즉시 테스트 가능
- **UI/UX 집중**: 백엔드 설정 없이 프론트엔드 완성도 확인
- **오프라인 작업**: 인터넷 연결 없이도 모든 기능 테스트 가능
- **성능 최적화**: 네트워크 지연 없는 즉시 응답

## 📋 향후 계획

1. Firebase 프로젝트 설정
2. 실제 인증 시스템 연동
3. Firestore 데이터베이스 연결
4. 실시간 기능 구현 (채팅 등)
5. 푸시 알림 기능 추가

---

*현재 버전은 데모 목적으로 제작되었으며, 모든 인증 기능이 시뮬레이션되어 있습니다.*
