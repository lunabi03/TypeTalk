# 🔥 Firebase 실제 연동 가이드

TypeTalk 앱을 실제 Firebase와 연동하기 위한 단계별 설정 가이드입니다.

## 📋 사전 준비사항

### 1. 필수 도구 설치 확인
- [Node.js](https://nodejs.org/) (v16 이상)
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Git](https://git-scm.com/)

### 2. Firebase 계정 준비
- Google 계정으로 [Firebase Console](https://console.firebase.google.com/) 접속

## 🚀 단계별 설정 명령어

### **Step 1: Flutter 의존성 설치**
```bash
# 프로젝트 디렉토리로 이동
cd C:\Projects\TypeTalk

# Firebase 패키지들 설치
flutter pub get
```

### **Step 2: Firebase CLI 설치**
```bash
# Firebase CLI 전역 설치
npm install -g firebase-tools

# 설치 확인
firebase --version
```

### **Step 3: Firebase 로그인**
```bash
# Firebase 계정으로 로그인
firebase login

# 로그인 상태 확인
firebase projects:list
```

### **Step 4: FlutterFire CLI 설치**
```bash
# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# PATH 설정 확인 (Windows)
echo $env:PATH | Select-String "dart"
```

### **Step 5: Firebase 프로젝트 생성**

#### **Firebase Console에서 설정:**
1. https://console.firebase.google.com/ 접속
2. "프로젝트 추가" 클릭
3. 프로젝트 이름: `TypeTalk`
4. Google Analytics 활성화 (선택사항)

#### **필수 서비스 활성화:**
```
✅ Authentication
   - 로그인 방법 → Email/비밀번호 활성화
   - 로그인 방법 → Google 활성화 (선택사항)
   - 로그인 방법 → Apple 활성화 (선택사항)

✅ Firestore Database
   - 데이터베이스 만들기 → 테스트 모드로 시작
   - 위치: asia-northeast3 (서울)

✅ Storage (선택사항)
   - 시작하기 → 테스트 모드로 시작
```

### **Step 6: Flutter 앱과 Firebase 연결**
```bash
# 프로젝트 루트에서 실행
flutterfire configure

# 선택사항들:
# - 프로젝트 선택: TypeTalk
# - 플랫폼 선택: android, ios, web (필요한 것만)
# - 패키지 이름: net.levelupcode.typetalk
```

### **Step 7: Firebase 초기화**
```bash
# Firebase 프로젝트 초기화
firebase init

# 선택할 기능들:
# [x] Firestore: Configure security rules and indexes files
# [x] Hosting: Configure files for Firebase Hosting
# [x] Storage: Configure a security rules file for Cloud Storage (선택사항)
```

### **Step 8: 설정 파일 확인**
다음 파일들이 생성되었는지 확인:
```
📁 TypeTalk/
├── firebase.json
├── .firebaserc
├── lib/
│   └── firebase_options.dart
├── firestore.rules
├── firestore.indexes.json
└── public/ (hosting 선택 시)
```

### **Step 9: 앱 실행 및 테스트**
```bash
# 웹에서 실행
flutter run -d chrome

# Android에서 실행 (에뮬레이터 실행 후)
flutter run -d android

# iOS에서 실행 (macOS에서만)
flutter run -d ios
```

## 🔧 문제 해결

### **일반적인 오류들:**

#### **1. Firebase CLI 인증 오류**
```bash
# 로그아웃 후 재로그인
firebase logout
firebase login --reauth
```

#### **2. FlutterFire 설정 오류**
```bash
# FlutterFire 재설정
flutterfire configure --force
```

#### **3. 패키지 설치 오류**
```bash
# 캐시 정리 후 재설치
flutter clean
flutter pub get
```

#### **4. 웹 빌드 오류**
```bash
# 웹 전용 빌드
flutter build web --web-renderer html
```

## 📊 Firebase Console 확인 사항

### **Authentication 확인:**
- Console → Authentication → Users
- 회원가입한 사용자들 확인

### **Firestore 확인:**
- Console → Firestore Database → Data
- `users` 컬렉션에서 사용자 프로필 데이터 확인

### **Analytics 확인 (활성화한 경우):**
- Console → Analytics → Events
- 사용자 활동 데이터 확인

## 🛡️ 보안 규칙 설정

### **Firestore 보안 규칙 (`firestore.rules`):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 사용자는 자신의 문서만 읽기/쓰기 가능
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 채팅방은 참여자만 접근 가능
    match /chats/{chatId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participants;
    }
    
    // 메시지는 채팅방 참여자만 접근 가능
    match /messages/{messageId} {
      allow read, write: if request.auth != null;
      // TODO: 채팅방 참여자 확인 로직 추가
    }
  }
}
```

### **Storage 보안 규칙 (선택사항):**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 🚀 배포 명령어

### **Firebase Hosting 배포:**
```bash
# 웹 앱 빌드
flutter build web --web-renderer html

# Firebase에 배포
firebase deploy --only hosting

# 특정 프로젝트에 배포
firebase deploy --only hosting --project typetalk
```

### **Firestore 규칙 배포:**
```bash
# 보안 규칙 배포
firebase deploy --only firestore:rules

# 인덱스 배포
firebase deploy --only firestore:indexes
```

## 📞 지원 및 문서

- [Firebase 문서](https://firebase.google.com/docs)
- [FlutterFire 문서](https://firebase.flutter.dev/)
- [Flutter 문서](https://flutter.dev/docs)

---

## ⚠️ 중요 참고사항

1. **API 키 보안**: `firebase_options.dart` 파일을 Git에 커밋할 때 민감한 정보가 포함되어 있는지 확인
2. **비용 관리**: Firebase 사용량을 정기적으로 모니터링하여 예상치 못한 비용 발생 방지
3. **백업**: Firestore 데이터를 정기적으로 백업하여 데이터 손실 방지
4. **보안 규칙**: 프로덕션 환경에서는 반드시 적절한 보안 규칙 설정

## 🎯 다음 단계

Firebase 연동이 완료되면:
1. 실제 회원가입/로그인 테스트
2. Firestore에 데이터 저장 확인
3. Authentication 사용자 목록 확인
4. 보안 규칙 점진적 강화

Firebase 연동이 성공적으로 완료되면 TypeTalk 앱이 실제 클라우드 데이터베이스와 연결됩니다! 🎉

