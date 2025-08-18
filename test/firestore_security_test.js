/**
 * Firebase Firestore Security Rules 테스트
 * TypeTalk 앱의 보안 규칙을 검증합니다.
 */

const firebase = require('@firebase/testing');
const fs = require('fs');

// 테스트 프로젝트 ID
const PROJECT_ID = 'typetalk-test';

// 보안 규칙 파일 읽기
const RULES = fs.readFileSync('firestore.rules', 'utf8');

/**
 * 테스트 앱 생성 (인증된 사용자)
 */
function getAuthedFirestore(auth) {
  return firebase.initializeTestApp({
    projectId: PROJECT_ID,
    auth: auth
  }).firestore();
}

/**
 * 테스트 앱 생성 (비인증 사용자)
 */
function getUnauthedFirestore() {
  return firebase.initializeTestApp({
    projectId: PROJECT_ID,
    auth: null
  }).firestore();
}

/**
 * 관리자 앱 생성
 */
function getAdminFirestore() {
  return firebase.initializeAdminApp({
    projectId: PROJECT_ID
  }).firestore();
}

describe('TypeTalk Firestore Security Rules', () => {
  beforeAll(async () => {
    // 보안 규칙 로드
    await firebase.loadFirestoreRules({
      projectId: PROJECT_ID,
      rules: RULES
    });
  });

  afterAll(async () => {
    // 모든 앱 정리
    await firebase.clearFirestoreData({ projectId: PROJECT_ID });
    await Promise.all(firebase.apps().map(app => app.delete()));
  });

  afterEach(async () => {
    // 각 테스트 후 데이터 정리
    await firebase.clearFirestoreData({ projectId: PROJECT_ID });
  });

  // ================================
  // 사용자 컬렉션 테스트
  // ================================

  describe('Users Collection', () => {
    const userId = 'testuser';
    const otherUserId = 'otheruser';
    
    const validUserData = {
      uid: userId,
      email: 'test@example.com',
      name: '테스트 사용자',
      createdAt: firebase.firestore.FieldValue.serverTimestamp(),
      updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
      mbtiType: 'ENFP'
    };

    test('인증된 사용자는 다른 사용자 프로필을 읽을 수 있다', async () => {
      const admin = getAdminFirestore();
      const db = getAuthedFirestore({ uid: userId });
      
      // 관리자가 사용자 데이터 생성
      await admin.collection('users').doc(otherUserId).set({
        ...validUserData,
        uid: otherUserId,
        email: 'other@example.com'
      });

      // 인증된 사용자가 다른 사용자 프로필 읽기
      await firebase.assertSucceeds(
        db.collection('users').doc(otherUserId).get()
      );
    });

    test('비인증 사용자는 사용자 프로필을 읽을 수 없다', async () => {
      const admin = getAdminFirestore();
      const db = getUnauthedFirestore();
      
      // 관리자가 사용자 데이터 생성
      await admin.collection('users').doc(userId).set(validUserData);

      // 비인증 사용자가 프로필 읽기 시도
      await firebase.assertFails(
        db.collection('users').doc(userId).get()
      );
    });

    test('사용자는 자신의 프로필만 생성할 수 있다', async () => {
      const db = getAuthedFirestore({ uid: userId });

      // 자신의 프로필 생성 (성공)
      await firebase.assertSucceeds(
        db.collection('users').doc(userId).set(validUserData)
      );

      // 다른 사용자의 프로필 생성 (실패)
      await firebase.assertFails(
        db.collection('users').doc(otherUserId).set({
          ...validUserData,
          uid: otherUserId
        })
      );
    });

    test('사용자는 자신의 프로필만 수정할 수 있다', async () => {
      const admin = getAdminFirestore();
      const db = getAuthedFirestore({ uid: userId });
      
      // 관리자가 두 사용자 데이터 생성
      await admin.collection('users').doc(userId).set(validUserData);
      await admin.collection('users').doc(otherUserId).set({
        ...validUserData,
        uid: otherUserId,
        email: 'other@example.com'
      });

      // 자신의 프로필 수정 (성공)
      await firebase.assertSucceeds(
        db.collection('users').doc(userId).update({
          name: '수정된 이름',
          updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        })
      );

      // 다른 사용자의 프로필 수정 (실패)
      await firebase.assertFails(
        db.collection('users').doc(otherUserId).update({
          name: '해킹된 이름'
        })
      );
    });

    test('보호된 필드는 수정할 수 없다', async () => {
      const admin = getAdminFirestore();
      const db = getAuthedFirestore({ uid: userId });
      
      // 관리자가 사용자 데이터 생성
      await admin.collection('users').doc(userId).set(validUserData);

      // uid 수정 시도 (실패)
      await firebase.assertFails(
        db.collection('users').doc(userId).update({
          uid: 'changed_uid'
        })
      );

      // email 수정 시도 (실패)
      await firebase.assertFails(
        db.collection('users').doc(userId).update({
          email: 'changed@example.com'
        })
      );

      // createdAt 수정 시도 (실패)
      await firebase.assertFails(
        db.collection('users').doc(userId).update({
          createdAt: firebase.firestore.FieldValue.serverTimestamp()
        })
      );
    });

    test('유효하지 않은 MBTI 타입은 거부된다', async () => {
      const db = getAuthedFirestore({ uid: userId });

      // 유효하지 않은 MBTI 타입으로 생성 (실패)
      await firebase.assertFails(
        db.collection('users').doc(userId).set({
          ...validUserData,
          mbtiType: 'INVALID'
        })
      );

      // 유효한 MBTI 타입으로 생성 (성공)
      await firebase.assertSucceeds(
        db.collection('users').doc(userId).set({
          ...validUserData,
          mbtiType: 'INTJ'
        })
      );
    });
  });

  // ================================
  // 추천 컬렉션 테스트
  // ================================

  describe('Recommendations Collection', () => {
    const userId = 'testuser';
    const otherUserId = 'otheruser';
    const recommendationId = 'rec_test_123';
    
    const validRecommendation = {
      recommendationId: recommendationId,
      userId: userId,
      type: 'user',
      targetId: 'target_user',
      score: 85.5,
      reasons: ['MBTI 호환성이 높습니다', '공통 관심사가 있습니다'],
      createdAt: firebase.firestore.FieldValue.serverTimestamp(),
      algorithm: {
        version: '1.0',
        factors: {
          mbtiCompatibility: 90.0,
          sharedInterests: 80.0,
          activityLevel: 85.0,
          location: 87.0
        }
      }
    };

    test('사용자는 자신의 추천만 읽을 수 있다', async () => {
      const admin = getAdminFirestore();
      const db = getAuthedFirestore({ uid: userId });
      const otherDb = getAuthedFirestore({ uid: otherUserId });
      
      // 관리자가 추천 데이터 생성
      await admin.collection('recommendations').doc(recommendationId).set(validRecommendation);

      // 자신의 추천 읽기 (성공)
      await firebase.assertSucceeds(
        db.collection('recommendations').doc(recommendationId).get()
      );

      // 다른 사용자의 추천 읽기 (실패)
      await firebase.assertFails(
        otherDb.collection('recommendations').doc(recommendationId).get()
      );
    });

    test('추천 상태만 수정할 수 있다', async () => {
      const admin = getAdminFirestore();
      const db = getAuthedFirestore({ uid: userId });
      
      // 관리자가 추천 데이터 생성
      await admin.collection('recommendations').doc(recommendationId).set(validRecommendation);

      // 상태 변경 (성공)
      await firebase.assertSucceeds(
        db.collection('recommendations').doc(recommendationId).update({
          viewedAt: firebase.firestore.FieldValue.serverTimestamp(),
          actionTaken: 'accepted'
        })
      );

      // 점수 변경 시도 (실패)
      await firebase.assertFails(
        db.collection('recommendations').doc(recommendationId).update({
          score: 100.0
        })
      );

      // 추천 이유 변경 시도 (실패)
      await firebase.assertFails(
        db.collection('recommendations').doc(recommendationId).update({
          reasons: ['조작된 이유']
        })
      );
    });

    test('유효하지 않은 actionTaken 값은 거부된다', async () => {
      const admin = getAdminFirestore();
      const db = getAuthedFirestore({ uid: userId });
      
      // 관리자가 추천 데이터 생성
      await admin.collection('recommendations').doc(recommendationId).set(validRecommendation);

      // 유효하지 않은 액션 (실패)
      await firebase.assertFails(
        db.collection('recommendations').doc(recommendationId).update({
          actionTaken: 'invalid_action'
        })
      );

      // 유효한 액션 (성공)
      await firebase.assertSucceeds(
        db.collection('recommendations').doc(recommendationId).update({
          actionTaken: 'rejected'
        })
      );
    });
  });

  // ================================
  // 채팅 컬렉션 테스트
  // ================================

  describe('Chats Collection', () => {
    const userId = 'testuser';
    const otherUserId = 'otheruser';
    const chatId = 'chat_test_123';
    
    const validChatData = {
      chatId: chatId,
      type: 'group',
      title: '테스트 채팅방',
      createdBy: userId,
      createdAt: firebase.firestore.FieldValue.serverTimestamp(),
      updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
      participants: [userId]
    };

    test('인증된 사용자는 채팅방을 읽을 수 있다', async () => {
      const admin = getAdminFirestore();
      const db = getAuthedFirestore({ uid: otherUserId });
      
      // 관리자가 채팅방 생성
      await admin.collection('chats').doc(chatId).set(validChatData);

      // 인증된 사용자가 채팅방 읽기 (성공)
      await firebase.assertSucceeds(
        db.collection('chats').doc(chatId).get()
      );
    });

    test('사용자는 자신을 참여자로 포함하는 채팅방만 생성할 수 있다', async () => {
      const db = getAuthedFirestore({ uid: userId });

      // 자신을 포함한 채팅방 생성 (성공)
      await firebase.assertSucceeds(
        db.collection('chats').doc(chatId).set(validChatData)
      );

      // 자신을 포함하지 않은 채팅방 생성 (실패)
      await firebase.assertFails(
        db.collection('chats').doc('other_chat').set({
          ...validChatData,
          chatId: 'other_chat',
          createdBy: userId,
          participants: [otherUserId] // 자신이 없음
        })
      );
    });

    test('채팅방 참여자만 수정할 수 있다', async () => {
      const admin = getAdminFirestore();
      const db = getAuthedFirestore({ uid: userId });
      const nonParticipantDb = getAuthedFirestore({ uid: otherUserId });
      
      // 관리자가 채팅방 생성
      await admin.collection('chats').doc(chatId).set(validChatData);

      // 참여자가 채팅방 수정 (성공)
      await firebase.assertSucceeds(
        db.collection('chats').doc(chatId).update({
          title: '수정된 제목',
          updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        })
      );

      // 비참여자가 채팅방 수정 (실패)
      await firebase.assertFails(
        nonParticipantDb.collection('chats').doc(chatId).update({
          title: '해킹된 제목'
        })
      );
    });
  });

  // ================================
  // 메시지 컬렉션 테스트
  // ================================

  describe('Messages Collection', () => {
    const userId = 'testuser';
    const otherUserId = 'otheruser';
    const chatId = 'chat_test_123';
    const messageId = 'msg_test_123';
    
    const validMessageData = {
      messageId: messageId,
      chatId: chatId,
      senderId: userId,
      content: '테스트 메시지입니다.',
      type: 'text',
      createdAt: firebase.firestore.FieldValue.serverTimestamp()
    };

    beforeEach(async () => {
      // 각 테스트 전에 채팅방 생성
      const admin = getAdminFirestore();
      await admin.collection('chats').doc(chatId).set({
        chatId: chatId,
        type: 'group',
        title: '테스트 채팅방',
        createdBy: userId,
        participants: [userId, otherUserId],
        createdAt: firebase.firestore.FieldValue.serverTimestamp(),
        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
      });
    });

    test('채팅방 참여자만 메시지를 읽을 수 있다', async () => {
      const admin = getAdminFirestore();
      const participantDb = getAuthedFirestore({ uid: userId });
      const nonParticipantDb = getAuthedFirestore({ uid: 'nonparticipant' });
      
      // 관리자가 메시지 생성
      await admin.collection('messages').doc(messageId).set(validMessageData);

      // 참여자가 메시지 읽기 (성공)
      await firebase.assertSucceeds(
        participantDb.collection('messages').doc(messageId).get()
      );

      // 비참여자가 메시지 읽기 (실패)
      await firebase.assertFails(
        nonParticipantDb.collection('messages').doc(messageId).get()
      );
    });

    test('채팅방 참여자만 메시지를 작성할 수 있다', async () => {
      const participantDb = getAuthedFirestore({ uid: userId });
      const nonParticipantDb = getAuthedFirestore({ uid: 'nonparticipant' });

      // 참여자가 메시지 작성 (성공)
      await firebase.assertSucceeds(
        participantDb.collection('messages').doc(messageId).set(validMessageData)
      );

      // 비참여자가 메시지 작성 (실패)
      await firebase.assertFails(
        nonParticipantDb.collection('messages').doc('other_msg').set({
          ...validMessageData,
          messageId: 'other_msg',
          senderId: 'nonparticipant'
        })
      );
    });

    test('메시지 작성자만 자신의 메시지를 수정할 수 있다', async () => {
      const admin = getAdminFirestore();
      const senderDb = getAuthedFirestore({ uid: userId });
      const otherDb = getAuthedFirestore({ uid: otherUserId });
      
      // 관리자가 메시지 생성
      await admin.collection('messages').doc(messageId).set(validMessageData);

      // 작성자가 메시지 수정 (성공)
      await firebase.assertSucceeds(
        senderDb.collection('messages').doc(messageId).update({
          content: '수정된 메시지',
          updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        })
      );

      // 다른 사용자가 메시지 수정 (실패)
      await firebase.assertFails(
        otherDb.collection('messages').doc(messageId).update({
          content: '해킹된 메시지'
        })
      );
    });
  });

  // ================================
  // MBTI 테스트 컬렉션 테스트
  // ================================

  describe('MBTI Tests Collection', () => {
    const userId = 'testuser';
    const otherUserId = 'otheruser';
    const testId = 'test_123';
    
    const validTestData = {
      testId: testId,
      userId: userId,
      result: 'ENFP',
      completedAt: firebase.firestore.FieldValue.serverTimestamp(),
      scores: {
        E_I: 35.0,
        S_N: 40.0,
        T_F: 25.0,
        J_P: 45.0
      }
    };

    test('사용자는 자신의 테스트 결과만 읽을 수 있다', async () => {
      const admin = getAdminFirestore();
      const db = getAuthedFirestore({ uid: userId });
      const otherDb = getAuthedFirestore({ uid: otherUserId });
      
      // 관리자가 테스트 결과 생성
      await admin.collection('mbti_tests').doc(testId).set(validTestData);

      // 자신의 테스트 결과 읽기 (성공)
      await firebase.assertSucceeds(
        db.collection('mbti_tests').doc(testId).get()
      );

      // 다른 사용자의 테스트 결과 읽기 (실패)
      await firebase.assertFails(
        otherDb.collection('mbti_tests').doc(testId).get()
      );
    });

    test('사용자는 자신의 테스트 결과만 생성할 수 있다', async () => {
      const db = getAuthedFirestore({ uid: userId });

      // 자신의 테스트 결과 생성 (성공)
      await firebase.assertSucceeds(
        db.collection('mbti_tests').doc(testId).set(validTestData)
      );

      // 다른 사용자의 테스트 결과 생성 (실패)
      await firebase.assertFails(
        db.collection('mbti_tests').doc('other_test').set({
          ...validTestData,
          testId: 'other_test',
          userId: otherUserId
        })
      );
    });

    test('테스트 결과는 수정할 수 없다', async () => {
      const admin = getAdminFirestore();
      const db = getAuthedFirestore({ uid: userId });
      
      // 관리자가 테스트 결과 생성
      await admin.collection('mbti_tests').doc(testId).set(validTestData);

      // 테스트 결과 수정 시도 (실패)
      await firebase.assertFails(
        db.collection('mbti_tests').doc(testId).update({
          result: 'INTJ'
        })
      );
    });

    test('유효하지 않은 MBTI 결과는 거부된다', async () => {
      const db = getAuthedFirestore({ uid: userId });

      // 유효하지 않은 MBTI 결과 (실패)
      await firebase.assertFails(
        db.collection('mbti_tests').doc(testId).set({
          ...validTestData,
          result: 'INVALID'
        })
      );
    });
  });

  // ================================
  // 일반적인 보안 테스트
  // ================================

  describe('General Security', () => {
    test('비인증 사용자는 모든 데이터에 접근할 수 없다', async () => {
      const db = getUnauthedFirestore();

      // 사용자 컬렉션 접근 (실패)
      await firebase.assertFails(
        db.collection('users').get()
      );

      // 추천 컬렉션 접근 (실패)
      await firebase.assertFails(
        db.collection('recommendations').get()
      );

      // 채팅 컬렉션 접근 (실패)
      await firebase.assertFails(
        db.collection('chats').get()
      );

      // 메시지 컬렉션 접근 (실패)
      await firebase.assertFails(
        db.collection('messages').get()
      );
    });

    test('명시되지 않은 컬렉션은 접근할 수 없다', async () => {
      const db = getAuthedFirestore({ uid: 'testuser' });

      // 존재하지 않는 컬렉션 접근 (실패)
      await firebase.assertFails(
        db.collection('unknown_collection').get()
      );

      // 시스템 컬렉션 접근 (실패)
      await firebase.assertFails(
        db.collection('_internal').get()
      );
    });
  });
});

// 테스트 실행 스크립트
if (require.main === module) {
  console.log('Firebase Security Rules 테스트를 실행합니다...');
  
  // Jest 또는 다른 테스트 러너로 실행
  // npm test 명령어로 실행 가능
}
