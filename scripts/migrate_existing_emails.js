// Firebase Admin SDK를 사용하여 기존 가입 사용자들의 이메일을 emails 컬렉션에 추가
// Node.js 환경에서 실행

const admin = require('firebase-admin');

// Firebase Admin SDK 초기화 (서비스 계정 키 필요)
const serviceAccount = require('../android/app/google-services.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://typetalk-3dc64-default-rtdb.firebaseio.com'
});

const db = admin.firestore();
const auth = admin.auth();

async function migrateExistingEmails() {
  console.log('기존 가입 사용자 이메일 마이그레이션 시작...');
  
  try {
    // 1. Firebase Auth에서 모든 사용자 목록 가져오기
    const listUsersResult = await auth.listUsers();
    const users = listUsersResult.users;
    
    console.log(`총 ${users.length}명의 사용자 발견`);
    
    // 2. 각 사용자의 이메일을 emails 컬렉션에 추가
    const batch = db.batch();
    let addedCount = 0;
    
    for (const userRecord of users) {
      if (userRecord.email) {
        const emailLower = userRecord.email.toLowerCase();
        const emailDocRef = db.collection('emails').doc(emailLower);
        
        // 이미 존재하는지 확인
        const existingDoc = await emailDocRef.get();
        if (!existingDoc.exists) {
          batch.set(emailDocRef, {
            email: emailLower,
            uid: userRecord.uid,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          addedCount++;
          console.log(`추가 예정: ${userRecord.email} -> ${userRecord.uid}`);
        } else {
          console.log(`이미 존재: ${userRecord.email}`);
        }
      }
    }
    
    // 3. 배치 실행
    if (addedCount > 0) {
      await batch.commit();
      console.log(`✅ ${addedCount}개의 이메일을 emails 컬렉션에 추가 완료`);
    } else {
      console.log('✅ 추가할 새로운 이메일이 없습니다');
    }
    
  } catch (error) {
    console.error('❌ 마이그레이션 실패:', error);
  }
}

// 스크립트 실행
migrateExistingEmails()
  .then(() => {
    console.log('마이그레이션 완료');
    process.exit(0);
  })
  .catch((error) => {
    console.error('마이그레이션 오류:', error);
    process.exit(1);
  });
