# TypeTalk Database Schema Design

## 📋 개요

TypeTalk 앱의 Firestore 데이터베이스 구조 설계입니다. MBTI 기반 소셜 채팅 앱의 모든 데이터 요구사항을 체계적으로 관리합니다.

## 🗂️ 컬렉션 구조

### 1. **users** (사용자 정보)
사용자의 기본 정보와 프로필을 저장합니다.

```typescript
interface User {
  uid: string;                    // 사용자 고유 ID
  email: string;                  // 이메일
  name: string;                   // 이름
  createdAt: Timestamp;          // 가입일
  updatedAt: Timestamp;          // 최종 수정일
  mbtiType?: string;             // MBTI 타입 (16가지)
  mbtiTestCount: number;         // MBTI 테스트 완료 횟수
  profileImageUrl?: string;      // 프로필 이미지 URL
  bio?: string;                  // 자기소개
  loginProvider: string;         // 로그인 제공자 (email, google, apple)
  
  // 사용자 설정
  preferences: {
    notifications: boolean;      // 알림 설정
    darkMode: boolean;          // 다크 모드
    language: string;           // 언어 설정
    privateChatEnabled: boolean; // 개인 채팅 허용
    mbtiVisible: boolean;       // MBTI 공개 설정
  };
  
  // 사용자 통계
  stats: {
    chatCount: number;          // 참여한 채팅 수
    friendCount: number;        // 친구 수
    messageCount: number;       // 보낸 메시지 수
    lastLoginAt: Timestamp;     // 마지막 로그인
    lastActiveAt: Timestamp;    // 마지막 활동
  };
  
  // 위치 정보 (선택적)
  location?: {
    country: string;
    city: string;
    timezone: string;
  };
}
```

### 2. **chats** (채팅방 정보)
MBTI 기반 그룹 채팅방과 개인 채팅방을 관리합니다.

```typescript
interface Chat {
  chatId: string;               // 채팅방 고유 ID
  type: 'group' | 'private';    // 채팅방 타입
  title: string;                // 채팅방 제목
  description?: string;         // 채팅방 설명
  createdBy: string;           // 생성자 UID
  createdAt: Timestamp;        // 생성일
  updatedAt: Timestamp;        // 최종 수정일
  
  // 참여자 정보
  participants: string[];       // 참여자 UID 배열
  participantCount: number;     // 참여자 수
  maxParticipants?: number;     // 최대 참여자 수
  
  // MBTI 관련 (그룹 채팅용)
  targetMBTI?: string[];        // 대상 MBTI 타입들
  mbtiCategory?: string;        // MBTI 카테고리 (NT, NF, ST, SF)
  
  // 채팅방 설정
  settings: {
    isPrivate: boolean;         // 비공개 여부
    allowInvites: boolean;      // 초대 허용
    moderatedMode: boolean;     // 중재 모드
    autoDelete: boolean;        // 자동 삭제 설정
    autoDeleteDays?: number;    // 자동 삭제 일수
  };
  
  // 채팅방 통계
  stats: {
    messageCount: number;       // 메시지 수
    activeMembers: number;      // 활성 멤버 수
    lastActivity: Timestamp;    // 마지막 활동
  };
  
  // 마지막 메시지 정보 (목록 표시용)
  lastMessage?: {
    content: string;
    senderId: string;
    senderName: string;
    timestamp: Timestamp;
    type: string;
  };
}
```

### 3. **messages** (메시지 정보)
채팅방의 모든 메시지를 저장합니다.

```typescript
interface Message {
  messageId: string;           // 메시지 고유 ID
  chatId: string;             // 채팅방 ID
  senderId: string;           // 발신자 UID
  senderName: string;         // 발신자 이름
  senderMBTI?: string;        // 발신자 MBTI
  content: string;            // 메시지 내용
  type: 'text' | 'image' | 'file' | 'system'; // 메시지 타입
  createdAt: Timestamp;       // 전송 시간
  updatedAt?: Timestamp;      // 수정 시간 (편집된 경우)
  
  // 미디어 정보 (이미지/파일인 경우)
  media?: {
    url: string;
    filename: string;
    size: number;
    mimeType: string;
  };
  
  // 메시지 상태
  status: {
    isEdited: boolean;         // 편집 여부
    isDeleted: boolean;        // 삭제 여부
    readBy: string[];          // 읽은 사용자 목록
  };
  
  // 반응 정보
  reactions?: {
    [emoji: string]: string[]; // 이모지: 반응한 사용자 UID 배열
  };
  
  // 답글 정보
  replyTo?: {
    messageId: string;
    content: string;
    senderId: string;
  };
}
```

### 4. **mbti_tests** (MBTI 테스트 결과)
사용자의 MBTI 테스트 결과와 이력을 저장합니다.

```typescript
interface MBTITest {
  testId: string;             // 테스트 고유 ID
  userId: string;             // 사용자 UID
  result: string;             // MBTI 결과 (16가지)
  completedAt: Timestamp;     // 완료 시간
  
  // 테스트 세부 결과
  scores: {
    E_I: number;              // 외향성-내향성 점수 (-100 ~ 100)
    S_N: number;              // 감각-직관 점수
    T_F: number;              // 사고-감정 점수
    J_P: number;              // 판단-인식 점수
  };
  
  // 각 질문별 답변
  answers: {
    questionId: string;
    answer: number;           // 1-5 점수
    timeSpent: number;        // 답변에 소요된 시간(초)
  }[];
  
  // 테스트 메타데이터
  metadata: {
    version: string;          // 테스트 버전
    totalQuestions: number;   // 총 질문 수
    totalTimeSpent: number;   // 총 소요 시간
    accuracy: number;         // 답변 일관성 점수
  };
}
```

### 5. **friendships** (친구 관계)
사용자 간의 친구 관계를 관리합니다.

```typescript
interface Friendship {
  friendshipId: string;       // 친구 관계 고유 ID
  users: string[];           // 친구 관계에 있는 사용자 UID (2명)
  status: 'pending' | 'accepted' | 'blocked'; // 상태
  initiatedBy: string;       // 친구 요청을 보낸 사용자
  createdAt: Timestamp;      // 친구 요청 시간
  acceptedAt?: Timestamp;    // 수락 시간
  
  // 친구 관계 메타데이터
  metadata: {
    howMet: 'chat' | 'search' | 'recommendation'; // 만난 경로
    mutualFriends: number;    // 공통 친구 수
    compatibilityScore?: number; // MBTI 호환성 점수
  };
}
```

### 6. **recommendations** (추천 시스템)
MBTI 기반 사용자 및 채팅방 추천 정보를 저장합니다.

```typescript
interface Recommendation {
  recommendationId: string;   // 추천 고유 ID
  userId: string;            // 추천 받는 사용자 UID
  type: 'user' | 'chat';     // 추천 타입
  targetId: string;          // 추천 대상 ID
  score: number;             // 추천 점수 (0-100)
  reasons: string[];         // 추천 이유
  createdAt: Timestamp;      // 생성 시간
  viewedAt?: Timestamp;      // 조회 시간
  actionTaken?: 'accepted' | 'rejected' | 'ignored'; // 사용자 행동
  
  // 추천 알고리즘 정보
  algorithm: {
    version: string;          // 알고리즘 버전
    factors: {               // 추천 요인들
      mbtiCompatibility: number;  // MBTI 호환성
      sharedInterests: number;    // 공통 관심사
      activityLevel: number;      // 활동성
      location: number;           // 위치 근접성
    };
  };
}
```

### 7. **notifications** (알림)
사용자 알림을 관리합니다.

```typescript
interface Notification {
  notificationId: string;     // 알림 고유 ID
  userId: string;            // 수신자 UID
  type: 'message' | 'friend_request' | 'chat_invite' | 'system'; // 알림 타입
  title: string;             // 알림 제목
  body: string;              // 알림 내용
  createdAt: Timestamp;      // 생성 시간
  readAt?: Timestamp;        // 읽은 시간
  
  // 알림 관련 데이터
  data: {
    chatId?: string;          // 관련 채팅방 ID
    senderId?: string;        // 발신자 ID
    friendshipId?: string;    // 친구 요청 ID
    actionUrl?: string;       // 액션 URL
  };
  
  // 알림 설정
  settings: {
    priority: 'high' | 'normal' | 'low'; // 우선순위
    pushSent: boolean;        // 푸시 알림 전송 여부
    emailSent: boolean;       // 이메일 알림 전송 여부
  };
}
```

### 8. **chat_participants** (채팅 참여자 상세 정보)
채팅방별 참여자의 상세 정보를 저장합니다.

```typescript
interface ChatParticipant {
  participantId: string;      // 참여자 고유 ID
  chatId: string;            // 채팅방 ID
  userId: string;            // 사용자 UID
  role: 'admin' | 'moderator' | 'member'; // 역할
  joinedAt: Timestamp;       // 참여 시간
  leftAt?: Timestamp;        // 나간 시간
  
  // 참여자 상태
  status: {
    isActive: boolean;        // 활성 상태
    isMuted: boolean;         // 음소거 상태
    lastReadMessageId?: string; // 마지막 읽은 메시지 ID
    lastSeenAt: Timestamp;    // 마지막 접속 시간
  };
  
  // 참여자 설정
  settings: {
    notifications: boolean;   // 알림 설정
    nickname?: string;        // 채팅방 내 닉네임
  };
  
  // 참여자 통계
  stats: {
    messageCount: number;     // 보낸 메시지 수
    reactionsGiven: number;   // 준 반응 수
    reactionsReceived: number; // 받은 반응 수
  };
}
```

## 🔍 인덱스 설계

### 성능 최적화를 위한 복합 인덱스

```typescript
// Users 컬렉션
users: [
  ['mbtiType', 'stats.lastActiveAt'],
  ['location.country', 'location.city'],
  ['createdAt'],
  ['stats.lastLoginAt']
]

// Chats 컬렉션
chats: [
  ['type', 'targetMBTI', 'stats.lastActivity'],
  ['participants', 'updatedAt'],
  ['createdBy', 'createdAt'],
  ['settings.isPrivate', 'participantCount']
]

// Messages 컬렉션
messages: [
  ['chatId', 'createdAt'],
  ['senderId', 'createdAt'],
  ['type', 'createdAt']
]

// Recommendations 컬렉션
recommendations: [
  ['userId', 'type', 'score'],
  ['userId', 'createdAt'],
  ['actionTaken', 'createdAt']
]
```

## 🔐 보안 규칙 설계

### Firestore Security Rules 기본 구조

```javascript
// 사용자는 자신의 데이터만 읽기/쓰기 가능
users: {
  read: auth.uid == resource.data.uid,
  write: auth.uid == resource.data.uid && validateUserData()
}

// 채팅방 참여자만 메시지 읽기 가능
messages: {
  read: auth.uid in getChatParticipants(resource.data.chatId),
  write: auth.uid == resource.data.senderId && validateMessage()
}

// 친구는 서로의 기본 정보 조회 가능
friendships: {
  read: auth.uid in resource.data.users,
  write: auth.uid in resource.data.users && validateFriendship()
}
```

## 📊 데이터 관계도

```
Users (1) ←→ (N) MBTITests
Users (N) ←→ (N) Chats (through ChatParticipants)
Users (1) ←→ (N) Messages
Users (N) ←→ (N) Friendships
Users (1) ←→ (N) Recommendations
Users (1) ←→ (N) Notifications
Chats (1) ←→ (N) Messages
Chats (1) ←→ (N) ChatParticipants
```

## 🚀 확장성 고려사항

### 1. **샤딩 전략**
- 지역별 데이터 분산
- MBTI 타입별 분산
- 시간 기반 파티셔닝

### 2. **캐싱 전략**
- 자주 조회되는 사용자 정보 캐시
- 활성 채팅방 목록 캐시
- MBTI 호환성 점수 캐시

### 3. **백업 및 복구**
- 일일 자동 백업
- 중요 데이터 실시간 복제
- 재해 복구 계획

## 📈 모니터링 지표

### 1. **성능 지표**
- 쿼리 응답 시간
- 동시 접속자 수
- 메시지 전송 지연시간

### 2. **사용 지표**
- 일간/월간 활성 사용자
- 채팅방 참여율
- MBTI 테스트 완료율

### 3. **품질 지표**
- 데이터 일관성
- 오류 발생률
- 사용자 만족도

이 설계는 TypeTalk 앱의 모든 기능을 지원하면서도 확장성과 성능을 보장하는 구조입니다.

