import 'package:get/get.dart';
import 'package:typetalk/models/chat_model.dart';
import 'package:typetalk/models/message_model.dart';
import 'package:typetalk/models/chat_participant_model.dart';
import 'package:typetalk/services/real_firebase_service.dart';

// 채팅 통계 서비스 클래스
class ChatStatsService extends GetxService {
  final RealFirebaseService _firestoreService = Get.find<RealFirebaseService>();
  
  // 통계 데이터
  final RxMap<String, ChatStats> chatStats = <String, ChatStats>{}.obs;
  final RxMap<String, ParticipantStats> participantStats = <String, ParticipantStats>{}.obs;
  
  // 전체 통계
  final RxInt totalChats = 0.obs;
  final RxInt totalMessages = 0.obs;
  final RxInt totalParticipants = 0.obs;
  final RxInt activeUsers = 0.obs;
  
  // MBTI별 통계
  final RxMap<String, int> mbtiChatCount = <String, int>{}.obs;
  final RxMap<String, int> mbtiMessageCount = <String, int>{}.obs;
  final RxMap<String, int> mbtiParticipantCount = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadGlobalStats();
  }

  // 전역 통계 로드
  Future<void> _loadGlobalStats() async {
    try {
            // 채팅방 통계
      final chatsSnapshot = await _firestoreService.getCollectionDocuments('chats');
      totalChats.value = chatsSnapshot.docs.length;
      
      // 메시지 통계
      final messagesSnapshot = await _firestoreService.getCollectionDocuments('messages');
      totalMessages.value = messagesSnapshot.docs.length;
      
      // 참여자 통계
      final participantsSnapshot = await _firestoreService.getCollectionDocuments('chatParticipants');
      totalParticipants.value = participantsSnapshot.docs.length;
      
      // MBTI별 통계 계산
      _calculateMBTIStats(chatsSnapshot.docs, messagesSnapshot.docs, participantsSnapshot.docs);
      
    } catch (e) {
      print('전역 통계 로드 실패: $e');
    }
  }

  // MBTI별 통계 계산
  void _calculateMBTIStats(
    List<dynamic> chats,
    List<dynamic> messages,
    List<dynamic> participants,
  ) {
    // MBTI별 채팅방 수
    for (final chatSnapshot in chats) {
      final chat = ChatModel.fromMap(chatSnapshot.data);
      if (chat.targetMBTI != null) {
        for (final mbti in chat.targetMBTI!) {
          mbtiChatCount[mbti] = (mbtiChatCount[mbti] ?? 0) + 1;
        }
      }
    }
    
    // MBTI별 메시지 수
    for (final messageSnapshot in messages) {
      final message = MessageModel.fromMap(messageSnapshot.data);
      if (message.senderMBTI != null) {
        mbtiMessageCount[message.senderMBTI!] = (mbtiMessageCount[message.senderMBTI!] ?? 0) + 1;
      }
    }
    
    // MBTI별 참여자 수
    for (final participantSnapshot in participants) {
      // 실제로는 사용자 정보에서 MBTI를 가져와야 함
      // 여기서는 데모용으로 랜덤 MBTI 할당
      final randomMBTI = _getRandomMBTI();
      mbtiParticipantCount[randomMBTI] = (mbtiParticipantCount[randomMBTI] ?? 0) + 1;
    }
  }

  // 랜덤 MBTI 생성 (데모용)
  String _getRandomMBTI() {
    final mbtiTypes = ['ENFP', 'ENFJ', 'ENTP', 'ENTJ', 'ESFP', 'ESFJ', 'ESTP', 'ESTJ', 
                       'INFP', 'INFJ', 'INTP', 'INTJ', 'ISFP', 'ISFJ', 'ISTP', 'ISTJ'];
    return mbtiTypes[DateTime.now().millisecondsSinceEpoch % mbtiTypes.length];
  }

  // 채팅방 통계 업데이트
  Future<void> updateChatStats(String chatId, ChatStats newStats) async {
    try {
      chatStats[chatId] = newStats;
      
      // Firestore 업데이트
      await _firestoreService.updateDocument('chats/$chatId', {
        'stats': newStats.toMap(),
      });
      
      // 전역 통계 업데이트
      _updateGlobalStats();
      
    } catch (e) {
      print('채팅방 통계 업데이트 실패: $e');
    }
  }

  // 메시지 통계 업데이트
  Future<void> updateMessageStats(String chatId, String messageType) async {
    try {
      final currentStats = chatStats[chatId];
      if (currentStats != null) {
        final updatedStats = currentStats.incrementMessageCount(messageType);
        await updateChatStats(chatId, updatedStats);
      }
      
      // 전역 메시지 수 업데이트
      totalMessages.value++;
      
    } catch (e) {
      print('메시지 통계 업데이트 실패: $e');
    }
  }

  // 참여자 통계 업데이트
  Future<void> updateParticipantStats(String participantId, ParticipantStats newStats) async {
    try {
      participantStats[participantId] = newStats;
      
      // Firestore 업데이트
      await _firestoreService.updateDocument('chatParticipants/$participantId', {
        'stats': newStats.toMap(),
      });
      
    } catch (e) {
      print('참여자 통계 업데이트 실패: $e');
    }
  }

  // 전역 통계 업데이트
  void _updateGlobalStats() {
    int totalChatsCount = 0;
    int totalMessagesCount = 0;
    int totalParticipantsCount = 0;
    
    for (final stats in chatStats.values) {
      totalChatsCount++;
      totalMessagesCount += stats.messageCount;
      totalParticipantsCount += stats.totalParticipants;
    }
    
    totalChats.value = totalChatsCount;
    totalMessages.value = totalMessagesCount;
    totalParticipants.value = totalParticipantsCount;
  }

  // 채팅방별 통계 가져오기
  Future<ChatStats?> getChatStats(String chatId) async {
    try {
      if (chatStats.containsKey(chatId)) {
        return chatStats[chatId];
      }
      
      final chatSnapshot = await _firestoreService.getDocument('chats/$chatId');
      if (chatSnapshot.exists) {
        final chat = ChatModel.fromMap(chatSnapshot.data() as Map<String, dynamic>);
        chatStats[chatId] = chat.stats;
        return chat.stats;
      }
      
      return null;
    } catch (e) {
      print('채팅방 통계 가져오기 실패: $e');
      return null;
    }
  }

  // 참여자별 통계 가져오기
  Future<ParticipantStats?> getParticipantStats(String participantId) async {
    try {
      if (participantStats.containsKey(participantId)) {
        return participantStats[participantId];
      }
      
      final participantSnapshot = await _firestoreService.getDocument('chatParticipants/$participantId');
      if (participantSnapshot.exists) {
        final participant = ChatParticipantModel.fromMap(participantSnapshot.data() as Map<String, dynamic>);
        participantStats[participantId] = participant.stats;
        return participant.stats;
      }
      
      return null;
    } catch (e) {
      print('참여자 통계 가져오기 실패: $e');
      return null;
    }
  }

  // MBTI별 인기 채팅방 가져오기
  Future<List<ChatModel>> getPopularChatsByMBTI(String mbti, {int limit = 10}) async {
    try {
      final chatsSnapshot = await _firestoreService.queryDocuments(
        'chats',
        field: 'targetMBTI',
        isEqualTo: mbti,
        orderByField: 'stats.messageCount',
        descending: true,
        limitCount: limit,
      );
      
              return chatsSnapshot.docs.map((snapshot) => ChatModel.fromMap(snapshot.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      print('MBTI별 인기 채팅방 가져오기 실패: $e');
      return [];
    }
  }

  // 활성 사용자 수 업데이트
  Future<void> updateActiveUsers() async {
    try {
              final participantsSnapshot = await _firestoreService.getCollectionDocuments('chatParticipants');
      int activeCount = 0;
      
      for (final participantSnapshot in participantsSnapshot.docs) {
        final participant = ChatParticipantModel.fromMap(participantSnapshot.data() as Map<String, dynamic>);
        if (participant.isActive) {
          activeCount++;
        }
      }
      
      activeUsers.value = activeCount;
    } catch (e) {
      print('활성 사용자 수 업데이트 실패: $e');
    }
  }

  // 통계 요약 가져오기
  Map<String, dynamic> getStatsSummary() {
    return {
      'totalChats': totalChats.value,
      'totalMessages': totalMessages.value,
      'totalParticipants': totalParticipants.value,
      'activeUsers': activeUsers.value,
      'mbtiChatCount': mbtiChatCount,
      'mbtiMessageCount': mbtiMessageCount,
      'mbtiParticipantCount': mbtiParticipantCount,
    };
  }

  // MBTI 호환성 점수 계산
  double calculateMBTICompatibility(String userMBTI, String targetMBTI) {
    if (userMBTI == targetMBTI) return 1.0;
    
    final userCategory = _getMBTICategory(userMBTI);
    final targetCategory = _getMBTICategory(targetMBTI);
    
    if (userCategory == targetCategory) return 0.8;
    
    // 상보적 관계 확인
    if (_isComplementary(userMBTI, targetMBTI)) return 0.9;
    
    return 0.3;
  }

  String _getMBTICategory(String mbti) {
    if (mbti.length >= 2) {
      return mbti.substring(1, 3); // NT, NF, ST, SF
    }
    return mbti;
  }

  bool _isComplementary(String mbti1, String mbti2) {
    // ENFP <-> INTJ, ENFJ <-> INTP 등 상보적 관계
    final complementaryPairs = {
      'ENFP': 'INTJ', 'ENFJ': 'INTP', 'ENTP': 'INFJ', 'ENTJ': 'INFP',
      'ESFP': 'ISTJ', 'ESFJ': 'ISTP', 'ESTP': 'ISFJ', 'ESTJ': 'ISFP',
    };
    
    return complementaryPairs[mbti1] == mbti2 || complementaryPairs[mbti2] == mbti1;
  }

  // 통계 리셋
  void resetStats() {
    chatStats.clear();
    participantStats.clear();
    totalChats.value = 0;
    totalMessages.value = 0;
    totalParticipants.value = 0;
    activeUsers.value = 0;
    mbtiChatCount.clear();
    mbtiMessageCount.clear();
    mbtiParticipantCount.clear();
  }

  // 통계 내보내기
  Map<String, dynamic> exportStats() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'summary': getStatsSummary(),
      'chatStats': chatStats.map((key, value) => MapEntry(key, value.toMap())),
      'participantStats': participantStats.map((key, value) => MapEntry(key, value.toMap())),
    };
  }
}
