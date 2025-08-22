# 소셜 로그인 설정 가이드

## Google 로그인 설정

### 1. Firebase Console 설정

1. [Firebase Console](https://console.firebase.google.com/)에 접속
2. 프로젝트 선택 (typetalk-3dc68)
3. Authentication > Sign-in method로 이동
4. Google 제공업체 활성화
5. 프로젝트 지원 이메일 설정

### 2. Android 설정

1. **SHA-1 인증서 지문 추가**
   ```bash
   # 디버그 키스토어의 SHA-1 확인
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   
   # 릴리즈 키스토어의 SHA-1 확인 (릴리즈 빌드 시)
   keytool -list -v -keystore your-release-key.keystore -alias your-key-alias
   ```

2. **google-services.json 업데이트**
   - Firebase Console에서 다운로드한 최신 `google-services.json` 파일을 `android/app/` 폴더에 복사
   - OAuth 클라이언트 정보가 포함되어야 함

### 3. iOS 설정

1. **GoogleService-Info.plist 업데이트**
   - Firebase Console에서 다운로드한 최신 `GoogleService-Info.plist` 파일을 `ios/Runner/` 폴더에 복사
   - OAuth 클라이언트 정보가 포함되어야 함

## Apple 로그인 설정

### 1. Apple Developer Console 설정

1. [Apple Developer Console](https://developer.apple.com/)에 접속
2. Certificates, Identifiers & Profiles로 이동
3. Identifiers에서 App ID 선택 또는 생성
4. Sign In with Apple 기능 활성화

### 2. Firebase Console 설정

1. Firebase Console > Authentication > Sign-in method
2. Apple 제공업체 활성화
3. Service ID, Team ID, Key ID, Private Key 설정

### 3. iOS 설정

1. **Info.plist 설정 확인**
   - `CFBundleURLTypes`와 `LSApplicationQueriesSchemes` 설정 확인
   - 이미 설정되어 있음

2. **Capabilities 설정**
   - Xcode에서 프로젝트 선택
   - Signing & Capabilities 탭
   - Sign In with Apple 기능 추가

## 패키지 설치

필요한 패키지들이 이미 `pubspec.yaml`에 추가되어 있습니다:

```yaml
dependencies:
  google_sign_in: ^6.2.1
  sign_in_with_apple: ^6.1.3
  crypto: ^3.0.3
```

## 주의사항

1. **Google 로그인**
   - Google Play 서비스가 설치된 Android 기기에서만 작동
   - SHA-1 인증서 지문이 Firebase Console에 등록되어야 함

2. **Apple 로그인**
   - iOS 13.0 이상에서만 지원
   - Apple Developer 계정이 필요
   - 실제 기기에서 테스트 필요 (시뮬레이터에서는 제한적)

3. **테스트**
   - 실제 기기에서 테스트 권장
   - 에뮬레이터/시뮬레이터에서는 일부 기능이 제한될 수 있음

## 문제 해결

### Google 로그인 오류
- SHA-1 인증서 지문 확인
- google-services.json 파일 최신화
- Google Play 서비스 설치 확인

### Apple 로그인 오류
- Apple Developer Console 설정 확인
- Firebase Console Apple 제공업체 설정 확인
- 실제 iOS 기기에서 테스트

## 추가 리소스

- [Google Sign-In Flutter Plugin](https://pub.dev/packages/google_sign_in)
- [Sign in with Apple Flutter Plugin](https://pub.dev/packages/sign_in_with_apple)
- [Firebase Authentication](https://firebase.google.com/docs/auth)
- [Apple Sign In Documentation](https://developer.apple.com/sign-in-with-apple/)
