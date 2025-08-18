# Firebase Security Rules 설정 가이드

TypeTalk 앱의 Firebase Firestore 보안 규칙에 대한 상세한 설명입니다.

## 📋 목차

1. [보안 규칙 개요](#보안-규칙-개요)
2. [컬렉션별 보안 규칙](#컬렉션별-보안-규칙)
3. [주요 보안 함수](#주요-보안-함수)
4. [배포 방법](#배포-방법)
5. [테스트 방법](#테스트-방법)
6. [보안 베스트 프랙티스](#보안-베스트-프랙티스)

## 📚 보안 규칙 개요

### 기본 원칙

1. **최소 권한 원칙**: 필요한 최소한의 권한만 부여
2. **인증 필수**: 모든 작업에 인증 요구
3. **소유권 검증**: 자신의 데이터만 접근 가능
4. **데이터 유효성 검사**: 입력 데이터 검증
5. **읽기/쓰기 분리**: 각 작업별 세분화된 권한

### 보안 레벨

- 🔴 **HIGH**: 개인정보, 인증정보
- 🟡 **MEDIUM**: 사용자 생성 콘텐츠
- 🟢 **LOW**: 공개 정보, 시스템 설정

## 🏗️ 컬렉션별 보안 규칙

### 1. Users 컬렉션 (`/users/{userId}`)

**보안 레벨**: 🔴 HIGH

```javascript
// 읽기: 모든 인증된 사용자
allow read: if isAuthenticated();

// 생성: 본인 계정만
allow create: if isAuthenticated() && isOwner(userId) && isValidUserData();

// 수정: 본인만, 특정 필드 제한
allow update: if isAuthenticated() && isOwner(userId) && 
              !affectsProtectedFields(['uid', 'email', 'createdAt']);

// 삭제: 본인만
allow delete: if isAuthenticated() && isOwner(userId);
```

**보호되는 데이터**:
- 개인정보 (이메일, 이름)
- MBTI 정보
- 프로필 설정
- 활동 통계

### 2. Recommendations 컬렉션 (`/recommendations/{recommendationId}`)

**보안 레벨**: 🟡 MEDIUM

```javascript
// 읽기: 추천 받는 사용자만
allow read: if isAuthenticated() && isOwner(resource.data.userId);

// 생성: 시스템(서버)에서만
allow create: if isAuthenticated() && isOwner(request.resource.data.userId);

// 수정: 상태 변경만 (viewedAt, actionTaken)
allow update: if isAuthenticated() && isOwner(resource.data.userId) &&
              onlyAffects(['viewedAt', 'actionTaken']);
```

**보호되는 데이터**:
- 추천 알고리즘 결과
- 개인화된 매칭 정보
- 사용자 행동 패턴

### 3. Chats 컬렉션 (`/chats/{chatId}`)

**보안 레벨**: 🟡 MEDIUM

```javascript
// 읽기: 모든 인증된 사용자 (탐색용)
allow read: if isAuthenticated();

// 생성: 인증된 사용자, 자신을 참여자로 포함
allow create: if isAuthenticated() && 
              request.resource.data.createdBy == request.auth.uid;

// 수정: 참여자만, 제한적 수정
allow update: if isAuthenticated() && 
              request.auth.uid in resource.data.participants;
```

### 4. Messages 컬렉션 (`/messages/{messageId}`)

**보안 레벨**: 🟡 MEDIUM

```javascript
// 읽기: 채팅방 참여자만
allow read: if isAuthenticated() && isParticipant(resource.data.chatId);

// 생성: 채팅방 참여자만
allow create: if isAuthenticated() && 
              isParticipant(request.resource.data.chatId) &&
              request.resource.data.senderId == request.auth.uid;

// 수정: 작성자만, 내용만 수정 가능
allow update: if isAuthenticated() && isOwner(resource.data.senderId);
```

### 5. MBTI Tests 컬렉션 (`/mbti_tests/{testId}`)

**보안 레벨**: 🔴 HIGH

```javascript
// 읽기: 테스트 수행자만
allow read: if isAuthenticated() && isOwner(resource.data.userId);

// 생성: 본인 테스트만
allow create: if isAuthenticated() && 
              isOwner(request.resource.data.userId) &&
              isValidMBTI(request.resource.data.result);

// 수정: 허용하지 않음 (불변 데이터)
allow update: if false;
```

## 🛠️ 주요 보안 함수

### 인증 및 권한 함수

```javascript
// 인증 확인
function isAuthenticated() {
  return request.auth != null;
}

// 소유권 확인
function isOwner(userId) {
  return request.auth.uid == userId;
}

// 관리자 권한 확인
function isAdmin() {
  return isAuthenticated() && request.auth.token.admin == true;
}
```

### 데이터 유효성 검사 함수

```javascript
// 사용자 데이터 검증
function isValidUserData() {
  let data = request.resource.data;
  return data.keys().hasAll(['uid', 'email', 'name']) &&
         data.email.matches('.*@.*\\..*') &&
         data.name.size() >= 2 && data.name.size() <= 50;
}

// MBTI 타입 검증
function isValidMBTI(mbtiType) {
  return mbtiType in ['ENFP', 'INTJ', 'INFJ', /* ... 16개 타입 */];
}

// 점수 범위 검증
function isValidScore(score) {
  return score is number && score >= 0 && score <= 100;
}
```

## 🚀 배포 방법

### 1. Firebase CLI 설치

```bash
npm install -g firebase-tools
```

### 2. 프로젝트 초기화

```bash
firebase login
firebase init firestore
```

### 3. 보안 규칙 배포

```bash
# 규칙 검증
firebase firestore:rules:validate

# 규칙 배포
firebase deploy --only firestore:rules
```

### 4. 배포 확인

```bash
# 현재 활성 규칙 확인
firebase firestore:rules:get
```

## 🧪 테스트 방법

### 1. Firebase 에뮬레이터 사용

```bash
# 에뮬레이터 시작
firebase emulators:start --only firestore

# 에뮬레이터에서 테스트
firebase firestore:rules:test --test-file=test/firestore.test.js
```

### 2. 수동 테스트 시나리오

#### 시나리오 1: 사용자 프로필 접근
```javascript
// ✅ 성공해야 하는 경우
- 인증된 사용자가 자신의 프로필 읽기
- 인증된 사용자가 자신의 프로필 수정

// ❌ 실패해야 하는 경우
- 비인증 사용자의 프로필 접근
- 다른 사용자의 프로필 수정
- 보호된 필드(uid, email) 수정
```

#### 시나리오 2: 추천 시스템 접근
```javascript
// ✅ 성공해야 하는 경우
- 사용자가 자신의 추천 목록 조회
- 사용자가 추천 상태 변경 (수락/거절)

// ❌ 실패해야 하는 경우
- 다른 사용자의 추천 목록 조회
- 추천 점수나 이유 임의 수정
```

#### 시나리오 3: 채팅 시스템 접근
```javascript
// ✅ 성공해야 하는 경우
- 채팅방 참여자가 메시지 읽기
- 채팅방 참여자가 메시지 작성
- 메시지 작성자가 자신의 메시지 수정

// ❌ 실패해야 하는 경우
- 비참여자의 채팅방 메시지 읽기
- 다른 사용자의 메시지 수정/삭제
```

### 3. 자동화된 테스트

```javascript
// test/firestore.test.js
const firebase = require('@firebase/testing');

describe('Firestore Security Rules', () => {
  test('사용자는 자신의 프로필만 수정할 수 있다', async () => {
    const db = firebase.firestore();
    const userRef = db.collection('users').doc('user1');
    
    // 성공해야 함
    await firebase.assertSucceeds(
      userRef.update({ name: '새로운 이름' })
    );
    
    // 실패해야 함
    await firebase.assertFails(
      userRef.update({ uid: '다른_uid' })
    );
  });
});
```

## 🔒 보안 베스트 프랙티스

### 1. 인증 보안

- **다단계 인증**: 중요한 작업에는 추가 인증 요구
- **토큰 검증**: 커스텀 클레임으로 권한 세분화
- **세션 관리**: 적절한 토큰 만료 시간 설정

### 2. 데이터 보안

- **입력 검증**: 모든 사용자 입력 데이터 검증
- **SQL 인젝션 방지**: 쿼리 파라미터 검증
- **XSS 방지**: HTML/스크립트 태그 필터링

### 3. 접근 제어

- **최소 권한 원칙**: 필요한 최소 권한만 부여
- **역할 기반 접근**: 사용자 역할에 따른 권한 분리
- **시간 기반 제한**: 작업 시간 제한 설정

### 4. 모니터링

- **실시간 모니터링**: Firebase Security Rules 로그 모니터링
- **이상 행동 탐지**: 비정상적인 접근 패턴 감지
- **정기 감사**: 보안 규칙 정기 검토

### 5. 오류 처리

- **정보 노출 방지**: 상세한 오류 메시지 숨김
- **로깅**: 보안 이벤트 상세 로깅
- **알림**: 보안 위반 시 즉시 알림

## 📊 성능 최적화

### 1. 규칙 최적화

- **조건 순서**: 빠른 조건을 먼저 배치
- **중복 제거**: 공통 함수로 중복 로직 제거
- **캐싱**: 반복되는 데이터베이스 조회 최소화

### 2. 쿼리 최적화

- **인덱스 활용**: 적절한 인덱스 설정
- **배치 작업**: 여러 문서 동시 처리
- **페이지네이션**: 대량 데이터 분할 조회

## 🚨 보안 체크리스트

### 배포 전 확인사항

- [ ] 모든 컬렉션에 적절한 보안 규칙 설정
- [ ] 테스트 계정으로 권한 검증 완료
- [ ] 보호된 필드 수정 불가 확인
- [ ] 데이터 유효성 검사 규칙 적용
- [ ] 관리자 권한 분리 확인
- [ ] 에러 로깅 설정 완료

### 운영 중 모니터링

- [ ] 일일 보안 로그 검토
- [ ] 이상 접근 패턴 모니터링
- [ ] 규칙 위반 알림 설정
- [ ] 정기적인 보안 감사
- [ ] 사용자 피드백 모니터링

---

**⚠️ 중요**: 보안 규칙은 정기적으로 검토하고 업데이트해야 합니다. 새로운 기능 추가 시 해당 기능에 맞는 보안 규칙을 함께 구현하세요.
