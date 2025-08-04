# TypeMate

MBTI 기반 소셜 채팅 애플리케이션

## 프로젝트 소개

TypeMate는 MBTI 성격 유형 검사를 통해 자신의 성격을 파악하고, 이를 바탕으로 자신과 잘 맞는 상대와 채팅을 통해 교류할 수 있는 소셜 채팅 애플리케이션입니다.

## 주요 기능

- MBTI 성격 유형 검사
- 프로필 관리
- 매칭 시스템
- 실시간 채팅

## 기술 스택

- Flutter
- GetX (상태관리)
- Firebase (백엔드)

## 시작하기

### 필수 요구사항

- Flutter SDK
- Android Studio 또는 VS Code
- Git

### 설치 방법

1. GitHub 리포지토리 클론
```bash
git clone https://github.com/lunabi03/TypeTalk.git
cd TypeTalk
```

2. Flutter 패키지 설치
```bash
flutter pub get
```

3. 앱 실행
```bash
flutter run
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

## 프로젝트 구조

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart
│   │   └── app_text_styles.dart
│   └── widgets/
│       ├── app_button.dart
│       ├── app_card.dart
│       └── app_text_field.dart
├── routes/
│   └── app_routes.dart
├── screens/
│   ├── start/
│   ├── question/
│   ├── result/
│   ├── profile/
│   └── chat/
└── main.dart
```

## 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 기여 방법

1. 이 저장소를 포크합니다.
2. 새로운 브랜치를 생성합니다 (`git checkout -b feature/amazing-feature`).
3. 변경사항을 커밋합니다 (`git commit -m 'Add some amazing feature'`).
4. 브랜치에 푸시합니다 (`git push origin feature/amazing-feature`).
5. Pull Request를 생성합니다.