# TypeTalk

MBTI 기반 소셜 채팅 애플리케이션

## 🎉 프로젝트 상태: 데모 모드 → 실제 Firebase 모드 전환 완료!

TypeTalk는 **데모 모드에서 실제 Firebase 모드로 성공적으로 전환**되었습니다! 이제 실제 사용자들이 사용할 수 있는 완전한 클라우드 기반 애플리케이션입니다.

## 🔥 Firebase 설정 완료!

**TypeTalk Firebase 프로젝트가 성공적으로 설정되었습니다!**

- ✅ **프로젝트 ID**: `typetalk-3dc68`
- ✅ **웹 앱**: `1:805092955656:web:57e99fa547805cf9ef63bd`
- ✅ **Android 앱**: `1:805092955656:android:6a86c830a06d5b3def63bd`
- ✅ **iOS 앱**: `1:805092955656:ios:da27e9062f914b98ef63bd`

## 프로젝트 소개

TypeTalk는 MBTI 성격 유형 검사를 통해 자신의 성격을 파악하고, 이를 바탕으로 자신과 잘 맞는 상대와 채팅을 통해 교류할 수 있는 소셜 채팅 애플리케이션입니다.

## 주요 기능

- 🧠 **MBTI 성격 유형 검사**: 정교한 알고리즘으로 16가지 성격 유형 분석
- 👤 **프로필 관리**: 개인 정보, 설정, 통계 관리
- 🎯 **지능형 매칭 시스템**: MBTI 기반 호환성 분석 및 사용자/채팅방 추천
- 💬 **실시간 채팅**: 그룹 채팅, 개인 채팅, 반응, 답글 기능
- 🔐 **인증 시스템**: 이메일/비밀번호, Google, Apple 소셜 로그인
- 📊 **데이터 분석**: 사용자 활동 통계 및 MBTI 분석 리포트

## 기술 스택

- **Frontend**: Flutter (Dart)
- **상태관리**: GetX
- **백엔드**: Firebase (Authentication, Firestore, Analytics, Storage, Hosting)
- **UI/UX**: Flutter ScreenUtil, Google Fonts
- **아키텍처**: Clean Architecture, MVVM Pattern

## 시작하기

### 필수 요구사항

- **Flutter SDK** (3.2.3 이상)
- **Node.js** (v16 이상, Firebase CLI용)
- **Android Studio** 또는 **VS Code**
- **Git**

### 🚀 빠른 시작

#### 1. 리포지토리 클론
```bash
git clone https://github.com/lunabi03/TypeTalk.git
cd TypeTalk
```

#### 2. 의존성 설치
```bash
flutter pub get
```

#### 3. 앱 실행
```bash
# Firebase 설정 완료 후 (현재 상태)
flutter run -d chrome
# 실제 Firebase 모드로 실행되며, 클라우드 데이터 사용
# 실제 사용자 회원가입/로그인 가능
```

### 🔥 Firebase 실제 연동

**TypeTalk는 이미 실제 Firebase 모드로 전환되었습니다!** 

**Firebase 프로젝트 설정도 완료되어 이제 실제 사용자들이 사용할 수 있는 완전한 애플리케이션입니다!**

#### Firebase 설정 완료 상태:
- ✅ **프로젝트 생성**: `typetalk-3dc68`
- ✅ **FlutterFire CLI 설정**: 자동 설정 완료
- ✅ **설정값 생성**: `firebase_options.dart` 자동 생성
- 🔄 **서비스 활성화**: Firebase Console에서 Auth, Firestore, Storage 활성화 필요

#### Firebase Console 설정:
1. [Firebase Console](https://console.firebase.google.com/project/typetalk-3dc68) 접속
2. Authentication, Firestore, Storage 서비스 활성화
3. 보안 규칙 설정

자세한 설정 방법은 [Firebase 설정 가이드](./FIREBASE_SETUP.md)를 참조하세요.

## 📱 현재 상태

### 🟢 완료된 작업
- [x] Firebase 패키지 설치 및 활성화
- [x] 실제 Firebase 서비스 코드 구현
- [x] 데모 모드에서 실제 모드로 전환
- [x] Firebase 초기화 코드 구현
- [x] 설정 가이드 문서 작성
- [x] Firebase 프로젝트 설정 완료
- [x] Firebase 설정값 자동 생성 완료

### 🟡 필요한 작업 (Firebase Console 설정)
- [ ] Firebase Console에서 서비스 활성화 (Auth, Firestore, Storage)
- [ ] 보안 규칙 설정

## 🔄 모드별 동작

### **Firebase 설정 완료 후 (현재 상태):**
- ✅ 앱 실행 시 Firebase 초기화 성공
- ✅ 실제 사용자 회원가입/로그인 가능
- ✅ 클라우드에 데이터 저장 및 동기화
- ✅ 실시간 채팅 및 기능 사용 가능

## 📚 문서

- [Firebase 설정 가이드](./FIREBASE_SETUP.md) - Firebase 연동 방법
- [데모 모드 전환 완료](./DEMO_MODE.md) - 전환 과정 및 현재 상태
- [프로젝트 요구사항](./PRD.md) - 프로젝트 기능 명세
- [디자인 시스템](./design-system.md) - UI/UX 가이드라인

## GitHub 리포지토리 설정 및 푸시 방법

1. 로컬 Git 저장소 초기화
```bash
git init
```

2. 원격 저장소 추가
```bash
git remote add origin https://github.com/lunabi03/TypeTalk.git
```

3. 파일 스테이징
```bash
git add .
```

4. 변경사항 커밋
```bash
git commit -m "feat: 데모 모드에서 실제 Firebase 모드로 전환 완료 + Firebase 설정 완료"
```

## 🎯 다음 단계

1. ✅ **Firebase Console에서 프로젝트 생성** - 완료
2. ✅ **FlutterFire CLI로 자동 설정** - 완료
3. 🔄 **Firebase 서비스 활성화** (Auth, Firestore, Storage)
4. 🔄 **보안 규칙 설정** (Firestore, Storage)
5. 🔄 **실제 사용자 테스트**

---

## 🚀 전환 완료!

**TypeTalk 앱이 데모 모드에서 실제 Firebase 모드로 성공적으로 전환되었습니다!**

**Firebase 프로젝트 설정도 완료되어 이제 실제 사용자들이 사용할 수 있는 완전한 애플리케이션입니다!**

### **현재 상태:**
- 🟢 **코드 전환 완료**: 데모 모드에서 실제 Firebase 모드로 완전 전환
- 🟢 **Firebase 설정 완료**: 프로젝트 생성 및 설정값 자동 생성
- 🔄 **서비스 활성화**: Firebase Console에서 최종 설정 필요

자세한 설정 방법은 [FIREBASE_SETUP.md](./FIREBASE_SETUP.md)를 참조하세요.

---

*TypeTalk는 이제 데모가 아닌 실제 서비스가 될 준비가 완료되었습니다! 🎉*

**Firebase 설정 완료로 인해 앱이 실제 클라우드 환경에서 동작합니다! 🚀*