# TypeTalk

MBTI 기반 소셜 채팅 애플리케이션

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
- **백엔드**: Firebase (Authentication, Firestore, Analytics)
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

#### 3. 앱 실행 (데모 모드)
```bash
flutter run -d chrome
```

### 🔥 Firebase 실제 연동

**데모 모드**에서 **실제 Firebase**로 전환하려면:

```bash
# 자세한 Firebase 설정 가이드 확인
cat FIREBASE_SETUP.md
```

또는 [Firebase 설정 가이드](./FIREBASE_SETUP.md)를 참조하세요.

#### 주요 Firebase 설정 명령어:
```bash
# Firebase CLI 설치
npm install -g firebase-tools

# Firebase 로그인
firebase login

# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# Firebase 프로젝트 연결
flutterfire configure
```

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
git commit -m "Initial commit: TypeMate app implementation"
```

5. main 브랜치로 변경
```bash
git branch -M main
```

6. 원격 저장소로 푸시
```bash
git push -u origin main
```

## 📁 프로젝트 구조

```
lib/
├── 📱 screens/           # UI 화면들 (기능별 그룹화)
│   ├── auth/            # 인증 관련 (로그인, 회원가입)
│   ├── start/           # 시작 화면
│   ├── question/        # MBTI 테스트 화면
│   ├── result/          # 결과 화면
│   ├── profile/         # 프로필 화면
│   └── chat/           # 채팅 화면
├── 🎛️ controllers/      # 상태 관리 (GetX Controllers)
│   └── auth_controller.dart
├── 🛠️ services/         # 비즈니스 로직 및 데이터 처리
│   ├── auth_service.dart      # 인증 서비스
│   ├── firestore_service.dart # 데이터베이스 서비스
│   └── user_repository.dart   # 사용자 데이터 저장소
├── 📊 models/           # 데이터 모델들
│   ├── user_model.dart
│   ├── chat_model.dart
│   ├── message_model.dart
│   ├── mbti_model.dart
│   └── recommendation_model.dart
├── 🛡️ middleware/       # 라우팅 보안 및 검증
│   └── auth_middleware.dart
├── 🗂️ core/            # 공통 리소스
│   ├── theme/          # 디자인 시스템
│   │   ├── app_colors.dart
│   │   └── app_text_styles.dart
│   └── widgets/        # 재사용 가능한 UI 컴포넌트
│       ├── app_button.dart
│       ├── app_card.dart
│       └── app_text_field.dart
├── 🛣️ routes/           # 라우팅 설정
│   └── app_routes.dart
└── 🚀 main.dart         # 앱 진입점
```

### 📋 주요 파일 설명

- **`main.dart`**: 앱 초기화 및 의존성 주입
- **`auth_service.dart`**: 회원가입, 로그인, 소셜 로그인 처리
- **`firestore_service.dart`**: 데모/실제 Firestore 데이터베이스 추상화
- **`user_repository.dart`**: 사용자 데이터 CRUD 작업
- **`auth_controller.dart`**: 인증 상태 및 사용자 프로필 관리
- **`*_model.dart`**: 타입 안전한 데이터 모델들
- **`auth_middleware.dart`**: 페이지 접근 권한 제어

## 🚀 주요 특징

### 🧠 MBTI 기반 매칭 시스템
- 16가지 MBTI 유형별 호환성 알고리즘
- 개인화된 사용자 및 채팅방 추천
- 정교한 성격 분석 리포트

### 💬 실시간 소통
- WebSocket 기반 실시간 메시지
- 이모지 반응 및 답글 시스템
- 그룹 채팅 및 개인 채팅

### 🔐 강력한 보안
- Firebase Authentication 연동
- 세션 관리 및 자동 로그인
- 라우트 레벨 접근 제어

### 📱 크로스 플랫폼
- Web, Android, iOS 지원
- 반응형 UI 디자인
- 일관된 사용자 경험

## 📖 추가 문서

- 📋 [개발 체크리스트](./Project/dev_checklist.md)
- 🔥 [Firebase 설정 가이드](./FIREBASE_SETUP.md)
- 🗄️ [데이터베이스 스키마](./docs/DATABASE_SCHEMA.md)
- 🎨 [디자인 시스템](./design-system.md)

## 🐛 문제 해결

### 일반적인 오류들

#### Firebase 연동 오류
```bash
# Firebase 재로그인
firebase logout
firebase login --reauth

# FlutterFire 재설정
flutterfire configure --force
```

#### 패키지 설치 오류
```bash
# 캐시 정리
flutter clean
flutter pub get
```

#### 웹 실행 오류
```bash
# CORS 오류 해결
flutter run -d chrome --web-browser-flag="--disable-web-security"
```

## 📞 지원

문제가 발생하거나 질문이 있으시면:

1. [Issues](https://github.com/lunabi03/TypeTalk/issues)에 문제를 등록해주세요
2. [Discussions](https://github.com/lunabi03/TypeTalk/discussions)에서 토론에 참여해주세요

## 🤝 기여 방법

기여를 환영합니다! 다음 단계를 따라주세요:

1. 이 저장소를 포크합니다
2. 기능 브랜치를 생성합니다 (`git checkout -b feature/amazing-feature`)
3. 변경사항을 커밋합니다 (`git commit -m 'Add amazing feature'`)
4. 브랜치에 푸시합니다 (`git push origin feature/amazing-feature`)
5. Pull Request를 생성합니다

### 개발 가이드라인
- Clean Architecture 원칙 준수
- 코드 주석 및 문서화
- 단위 테스트 작성 권장
- Conventional Commits 사용

## 📄 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

---

**TypeTalk**로 MBTI 기반의 새로운 소셜 경험을 시작해보세요! 🎉