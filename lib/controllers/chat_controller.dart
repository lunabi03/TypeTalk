import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:typetalk/controllers/auth_controller.dart';
import 'package:typetalk/models/message_model.dart';
import 'package:typetalk/models/chat_model.dart';
import 'package:typetalk/services/real_user_repository.dart';
import 'package:typetalk/models/user_model.dart';
import 'package:typetalk/services/real_firebase_service.dart';
import 'package:typetalk/routes/app_routes.dart';

/// 채팅 화면 컨트롤러
/// 실시간 메시지 전송/수신 및 채팅방 관리를 담당합니다.
class ChatController extends GetxController {
  static ChatController get instance => Get.find<ChatController>();

  final AuthController authController = Get.find<AuthController>();
  final RealUserRepository _userRepository = Get.find<RealUserRepository>();
  final RealFirebaseService _firestore = Get.find<RealFirebaseService>();

  // 현재 채팅방 정보
  Rx<ChatModel?> currentChat = Rx<ChatModel?>(null);
  RxString chatId = ''.obs;
  
  // 내 채팅방 목록 및 검색/정렬 상태
  RxList<ChatModel> chatList = <ChatModel>[].obs;
  RxString searchQuery = ''.obs;
  RxBool sortByRecentDesc = true.obs;
  final Map<String, DateTime> _lastReadAt = {};
  
  // 메시지 목록
  RxList<MessageModel> messages = <MessageModel>[].obs;
  
  // UI 상태
  RxBool isLoading = false.obs;
  RxBool isSending = false.obs;
  
  // 텍스트 입력 컨트롤러
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    loadChatList();
  }

  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  /// 현재 사용자 채팅방 목록 로드 (실제 Firestore 기준)
  Future<void> loadChatList() async {
    try {
      isLoading.value = true;
      final myId = authController.userId ?? 'current-user';
      final snapshots = await _firestore.queryDocuments(
        'chats',
        field: 'participants',
        arrayContains: myId,
        orderByField: 'stats.lastActivity',
        descending: true,
      );
      var loaded = snapshots.docs
          .map((s) => ChatModel.fromSnapshot(s))
          .toList();
      // 기본 정렬: 최근 활동 내림차순
      loaded.sort((a, b) => b.stats.lastActivity.compareTo(a.stats.lastActivity));
      chatList.assignAll(loaded);
    } catch (e) {
      print('채팅방 목록 로드 실패: $e');
      chatList.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// 검색/정렬 적용된 채팅 목록
  List<ChatModel> get visibleChats {
    var list = chatList.toList();
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((c) =>
        c.title.toLowerCase().contains(q) ||
        (c.description?.toLowerCase().contains(q) ?? false)
      ).toList();
    }
    list.sort((a, b) => sortByRecentDesc.value
        ? b.stats.lastActivity.compareTo(a.stats.lastActivity)
        : a.stats.lastActivity.compareTo(b.stats.lastActivity));
    return list;
  }

  /// 채팅 열기
  Future<void> openChat(ChatModel chat) async {
    currentChat.value = chat;
    chatId.value = chat.chatId;
    await loadMessagesForChat(chat.chatId);
    _lastReadAt[chat.chatId] = DateTime.now();
    _scrollToBottom();
  }

  /// 메시지 목록 로드 (실제 Firestore)
  Future<void> loadMessagesForChat(String id) async {
    try {
      isLoading.value = true;
      final snapshots = await _firestore.queryDocuments(
        'messages',
        field: 'chatId',
        isEqualTo: id,
        orderByField: 'createdAt',
        descending: false,
      );
      final loaded = snapshots.docs.map((s) => MessageModel.fromSnapshot(s)).toList();
      messages.assignAll(loaded);
    } catch (e) {
      print('메시지 목록 로드 실패: $e');
      messages.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// 채팅별 안 읽은 개수 (데모: 마지막 메시지 시간과 마지막 읽은 시간 비교, 내 메시지는 제외)
  int getUnreadCount(ChatModel chat) {
    final lastRead = _lastReadAt[chat.chatId] ?? DateTime.fromMillisecondsSinceEpoch(0);
    if (chat.lastMessage != null && chat.lastMessage!.timestamp.isAfter(lastRead)) {
      final myId = authController.userId ?? 'current-user';
      if (chat.lastMessage!.senderId != myId) {
        return 1;
      }
    }
    return 0;
  }

  /// 데모 채팅방 초기화
  void _initializeDemoChat() {
    // 데모 채팅방 정보 설정
    currentChat.value = ChatModel(
      chatId: 'demo-enfp-chat',
      type: 'group',
      title: '유진 (ENFP)의 대화',
      description: 'ENFP 성격의 유진과의 1:1 대화',
      createdBy: 'demo-user-enfp',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now(),
      participants: ['demo-user-enfp', authController.userId ?? 'current-user'],
      participantCount: 2,
      maxParticipants: 2,
      targetMBTI: ['ENFP'],
      mbtiCategory: 'NF',
      settings: ChatSettings(
        isPrivate: false,
        allowInvites: false,
        moderatedMode: false,
        autoDelete: false,
      ),
      stats: ChatStats(
        messageCount: 4,
        activeMembers: 2,
        lastActivity: DateTime.now(),
      ),
    );

    chatId.value = currentChat.value!.chatId;
    _initializeDemoMessages();
  }

  /// 데모 메시지 초기화
  void _initializeDemoMessages() {
    final now = DateTime.now();
    final demoMessages = [
      MessageModel(
        messageId: 'msg-001',
        chatId: chatId.value,
        senderId: 'demo-user-enfp',
        senderName: '유진 (ENFP)',
        senderMBTI: 'ENFP',
        content: '안녕하세요! 😊\n프로필 봤어주 좋아하신다구요~\n혹시 최근에 간 여행지 중에\n가장 인상 깊었던 곳은 어디였어요?',
        type: MessageType.text.value,
        createdAt: now.subtract(const Duration(minutes: 10)),
        status: MessageStatus(
          isEdited: false,
          isDeleted: false,
          readBy: ['demo-user-enfp', authController.userId ?? 'current-user'],
        ),
        reactions: {},
      ),
      MessageModel(
        messageId: 'msg-002',
        chatId: chatId.value,
        senderId: authController.userId ?? 'current-user',
        senderName: authController.userName ?? '나',
        senderMBTI: authController.userProfile['mbti'] ?? 'ENFP',
        content: '안녕하세요.\n저는 작년 가을에 가족과 가팀구 지적하 나날다.\n케이블카를 하면 임상해서\n만족스러워 여행이었어요.',
        type: MessageType.text.value,
        createdAt: now.subtract(const Duration(minutes: 8)),
        status: MessageStatus(
          isEdited: false,
          isDeleted: false,
          readBy: ['demo-user-enfp', authController.userId ?? 'current-user'],
        ),
        reactions: {},
      ),
      MessageModel(
        messageId: 'msg-003',
        chatId: chatId.value,
        senderId: 'demo-user-enfp',
        senderName: '유진 (ENFP)',
        senderMBTI: 'ENFP',
        content: '오 경주 좋죠~!!\n전 그냥 무작정 가서 다니 것다가,\n월리단절에서 감짝 감막 독어다시여운 호황\n케이블카로 올적이는 것 좋아하시는군요.',
        type: MessageType.text.value,
        createdAt: now.subtract(const Duration(minutes: 5)),
        status: MessageStatus(
          isEdited: false,
          isDeleted: false,
          readBy: ['demo-user-enfp', authController.userId ?? 'current-user'],
        ),
        reactions: {},
      ),
      MessageModel(
        messageId: 'msg-004',
        chatId: chatId.value,
        senderId: authController.userId ?? 'current-user',
        senderName: authController.userName ?? '나',
        senderMBTI: authController.userProfile['mbti'] ?? 'ENFP',
        content: '네, 즉흥적인 것보다 미리 준비된 일정이\n더 마음이 편해서요.\n유진님도 자유로운 스타일 같네요.\n하원도 감성적으로 하시는 것 같고요.',
        type: MessageType.text.value,
        createdAt: now.subtract(const Duration(minutes: 2)),
        status: MessageStatus(
          isEdited: false,
          isDeleted: false,
          readBy: ['demo-user-enfp', authController.userId ?? 'current-user'],
        ),
        reactions: {},
      ),
    ];

    messages.assignAll(demoMessages);
    _scrollToBottom();
  }

  /// 선택한 사용자와 개인 채팅 시작
  Future<void> startPrivateChatWith(UserModel otherUser) async {
    final currentUserId = authController.userId ?? 'current-user';
    final otherUserId = otherUser.uid;

    // 정렬된 조합으로 일관된 개인 채팅 ID 생성
    final ids = [currentUserId, otherUserId]..sort();
    final privateChatId = 'private-${ids.join('-')}';

    final newChat = ChatModel(
      chatId: privateChatId,
      type: 'private',
      title: otherUser.name.isNotEmpty ? otherUser.name : '개인 채팅',
      description: null,
      createdBy: currentUserId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      participants: [currentUserId, otherUserId],
      participantCount: 2,
      maxParticipants: 2,
      targetMBTI: null,
      mbtiCategory: null,
      settings: ChatSettings(
        isPrivate: true,
        allowInvites: false,
        moderatedMode: false,
        autoDelete: false,
      ),
      stats: ChatStats(
        messageCount: 0,
        activeMembers: 2,
        lastActivity: DateTime.now(),
      ),
    );

    currentChat.value = newChat;
    chatId.value = newChat.chatId;
    messages.clear();

    // 시스템 메시지로 시작 알림 추가 (데모)
    final systemMessage = MessageCreationHelper.createSystemMessage(
      chatId: newChat.chatId,
      content: '${otherUser.name}님과의 채팅을 시작했습니다.',
    );
    messages.add(systemMessage);
    
    // MBTI별 맞춤 인사말 추가 (데모)
    _addMBTIGreeting(otherUser.mbtiType);
    
    _scrollToBottom();
  }

  /// MBTI별 맞춤 인사말 추가
  void _addMBTIGreeting(String? mbtiType) {
    if (mbtiType == null) return;
    
    String greeting = '';
    String senderName = '';
    
    switch (mbtiType) {
      // 분석가 (NT)
      case 'INTJ':
        senderName = '민수';
        greeting = '안녕하세요. 프로필을 확인했습니다.\n현재 진행 중인 프로젝트나 목표가 있으신가요?\n전략적인 관점에서 의견을 나누고 싶습니다.';
        break;
      case 'INTP':
        senderName = '혜진';
        greeting = '안녕하세요! 프로필이 흥미롭네요.\n어떤 분야에 관심이 있으신지 궁금해요.\n이론적으로 깊이 있는 대화를 나누고 싶어요 🤔';
        break;
      case 'ENTJ':
        senderName = '준호';
        greeting = '안녕하세요! 프로필을 확인했습니다.\n현재 어떤 목표를 향해 나아가고 계신가요?\n효율적인 방법을 함께 찾아보면 좋을 것 같습니다.';
        break;
      case 'ENTP':
        senderName = '지훈';
        greeting = '안녕하세요! 정말 흥미로운 프로필이네요! 🤔\n새로운 아이디어나 관점에 대해 토론해보면 어떨까요?\n혁신적인 대화를 기대해요!';
        break;
      
      // 외교관 (NF)
      case 'INFJ':
        senderName = '서연';
        greeting = '안녕하세요. 프로필을 보니 깊이 있는 분 같아요 💫\n인생에서 추구하는 가치나 비전이 있으신가요?\n의미 있는 대화를 나누고 싶어요.';
        break;
      case 'INFP':
        senderName = '소영';
        greeting = '안녕하세요! 💕\n프로필을 보니 정말 따뜻한 마음을 가진 분 같아요.\n어떤 꿈이나 이상을 가지고 계신가요?';
        break;
      case 'ENFJ':
        senderName = '민지';
        greeting = '안녕하세요! ✨ 프로필을 보니 정말 멋진 분 같아요!\n사람들과 함께 성장하는 이야기를 나누고 싶어요.\n어떤 일에 열정을 가지고 계신가요?';
        break;
      case 'ENFP':
        senderName = '유진';
        greeting = '안녕하세요! 😊\n프로필 봤어주 좋아하신다구요~\n혹시 최근에 간 여행지 중에\n가장 인상 깊었던 곳은 어디였어요?';
        break;
      
      // 관리자 (SJ)
      case 'ISTJ':
        senderName = '성민';
        greeting = '안녕하세요. 프로필을 확인했습니다.\n체계적이고 안정적인 방법으로 목표를 달성하는 것을 중요하게 생각해요.\n경험을 바탕으로 좋은 대화를 나누고 싶습니다.';
        break;
      case 'ISFJ':
        senderName = '은지';
        greeting = '안녕하세요! 😊 프로필을 보니 정말 좋은 분 같아요.\n다른 사람들을 배려하는 마음이 아름다워요.\n편안하고 따뜻한 대화를 나누면 좋겠어요 💕';
        break;
      case 'ESTJ':
        senderName = '태현';
        greeting = '안녕하세요! 프로필을 확인했습니다. 💼\n목표 달성을 위한 체계적인 접근을 좋아해요.\n효율적인 방법으로 좋은 결과를 만들어가는 이야기를 나누고 싶습니다.';
        break;
      case 'ESFJ':
        senderName = '하연';
        greeting = '안녕하세요! 😊 프로필을 보니 정말 사교적이고 좋은 분 같아요!\n모두가 함께 즐거울 수 있는 대화를 나누면 좋겠어요.\n화합을 중요하게 생각해요 💕';
        break;
      
      // 탐험가 (SP)
      case 'ISTP':
        senderName = '도현';
        greeting = '안녕하세요. 프로필이 흥미롭네요.\n실용적이고 직접적인 경험을 중요하게 생각해요.\n손으로 만들거나 문제를 해결하는 것을 좋아합니다 🔧';
        break;
      case 'ISFP':
        senderName = '지영';
        greeting = '안녕하세요! 😊\n프로필을 보니 정말 흥미로워요.\n혹시 창작 활동이나 예술에 관심이 있으신가요?';
        break;
      case 'ESTP':
        senderName = '현우';
        greeting = '안녕하세요! 프로필 봤어요! 💪\n지금 당장 재미있는 일이나 활동에 관심이 있으신가요?\n실제로 경험해보는 것을 좋아해요!';
        break;
      case 'ESFP':
        senderName = '채영';
        greeting = '안녕하세요! 🎉 프로필을 보니 정말 재미있는 분 같아요!\n모든 사람이 즐겁게 할 수 있는 활동을 좋아해요.\n같이 신나는 이야기 나눠봐요! ✨';
        break;
      
      default:
        senderName = '친구';
        greeting = '안녕하세요! 😊\n프로필을 봤어요. 대화를 나누고 싶어요!';
    }
    
    final greetingMessage = MessageModel(
      messageId: 'greeting-${DateTime.now().millisecondsSinceEpoch}',
      chatId: chatId.value,
      senderId: 'demo-user-${mbtiType.toLowerCase()}',
      senderName: senderName,
      senderMBTI: mbtiType,
      content: greeting,
      type: MessageType.text.value,
      createdAt: DateTime.now(),
      status: MessageStatus(
        isEdited: false,
        isDeleted: false,
        readBy: ['demo-user-${mbtiType.toLowerCase()}'],
      ),
      reactions: {},
    );
    
    messages.add(greetingMessage);
  }

  /// 메시지 전송
  Future<void> sendMessage() async {
    final content = messageController.text.trim();
    
    // 입력 유효성 검사
    if (content.isEmpty) {
      Get.snackbar(
        '알림',
        '메시지를 입력해주세요.',
        backgroundColor: Colors.orange.withOpacity(0.1),
        colorText: Colors.orange,
      );
      return;
    }
    
    if (isSending.value) return;
    
    // 채팅방이 선택되지 않은 경우
    if (currentChat.value == null) {
      Get.snackbar(
        '오류',
        '채팅방을 선택해주세요.',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return;
    }

    try {
      isSending.value = true;

      final newMessage = MessageModel(
        messageId: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        chatId: chatId.value,
        senderId: authController.userId ?? 'current-user',
        senderName: authController.userName ?? '나',
        senderMBTI: authController.userProfile['mbti'] ?? 'ENFP',
        content: content,
        type: MessageType.text.value,
        createdAt: DateTime.now(),
        status: MessageStatus(
          isEdited: false,
          isDeleted: false,
          readBy: [authController.userId ?? 'current-user'],
        ),
        reactions: {},
      );

      // 메시지 목록에 추가
      messages.add(newMessage);
      
      // 입력창 초기화
      messageController.clear();
      
      // 스크롤을 맨 아래로
      _scrollToBottom();

      // Firestore에 메시지 저장
      try {
        await _firestore.setDocument('messages/${newMessage.messageId}', newMessage.toMap());
        
        // 채팅방의 마지막 메시지 정보 업데이트
        try {
          await _firestore.updateDocument('chats/${chatId.value}', {
            'lastMessage': {
              'content': content,
              'timestamp': newMessage.createdAt.toIso8601String(),
              'senderId': newMessage.senderId,
            },
            'stats.lastActivity': newMessage.createdAt.toIso8601String(),
            'stats.messageCount': FieldValue.increment(1),
          });
        } catch (e) {
          print('채팅방 업데이트 오류: $e');
        }
        
        // 채팅 목록 새로고침
        await loadChatList();
        
      } catch (e) {
        print('Firestore 저장 오류: $e');
        // 저장 실패 시에도 UI는 유지 (사용자 경험 향상)
      }

      // 메시지 전송 완료 후 읽음 상태 업데이트
      _updateReadStatus(newMessage.messageId);
      
      // 데모: 3초 후 자동 응답 (ENFP 스타일)
      _simulateAutoReply();

    } catch (e) {
      print('메시지 전송 오류: $e');
      Get.snackbar(
        '오류',
        '메시지 전송 중 오류가 발생했습니다.',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isSending.value = false;
    }
  }

  /// MBTI별 가상 사용자 데이터 (16개 전체)
  static const Map<String, Map<String, dynamic>> _virtualUsers = {
    // 분석가 (NT)
    'INTJ': {
      'name': '민수',
      'personality': '건축가 - 전략적이고 분석적인 내향형',
      'replies': [
        '흥미로운 관점입니다. 좀 더 구체적으로 설명해주실 수 있나요?',
        '그 접근 방식은 논리적으로 타당합니다. 👍',
        '이 문제를 체계적으로 분석해보면...',
        '장기적인 관점에서 보면 그런 선택이 합리적일 것 같습니다.',
        '데이터를 기반으로 한 의사결정이 중요하다고 생각합니다.',
        '효율성을 고려할 때 그 방법이 더 적절할 것 같습니다.',
      ],
    },
    'INTP': {
      'name': '혜진',
      'personality': '논리술사 - 호기심 많고 창의적인 사색가',
      'replies': [
        '흥미로운 아이디어네요. 이론적으로 어떻게 설명할 수 있을까요?',
        '그런 관점은 생각해보지 못했네요. 새로운 가능성이 보여요 🤔',
        '논리적으로 따져보면... 음, 복잡한 문제군요',
        '그 원리를 좀 더 깊이 탐구해보고 싶어요',
        '가설을 세워서 검증해보면 어떨까요?',
        '창의적인 해결책이 필요할 것 같은데...',
      ],
    },
    'ENTJ': {
      'name': '준호',
      'personality': '통솔자 - 리더십 있고 결단력 있는 외향형',
      'replies': [
        '좋은 아이디어입니다! 실행 계획을 세워보죠 💪',
        '그런 접근 방식이 효과적일 것 같습니다.',
        '목표를 달성하기 위해서는 체계적인 전략이 필요해요',
        '팀워크가 중요한 시점인 것 같습니다.',
        '결정을 내릴 때는 확실한 근거가 있어야 해요',
        '성과를 높이기 위한 구체적인 방안을 제시해주세요.',
      ],
    },
    'ENTP': {
      'name': '지훈',
      'personality': '변론가 - 혁신적이고 논쟁을 즐기는 외향형',
      'replies': [
        '정말 재미있는 관점이네요! 반대로 생각해보면 어떨까요? 🤔',
        '그 아이디어를 발전시켜서 새로운 가능성을 만들어볼까요?',
        '다른 관점에서 접근해보면... 완전히 다른 결과가 나올 수도!',
        '토론해보면 더 좋은 아이디어가 나올 것 같은데요?',
        '혁신적인 방법으로 문제를 해결해보죠! ✨',
        '기존의 틀을 깨고 새로운 시도를 해보면 어떨까요?',
      ],
    },

    // 외교관 (NF)
    'INFJ': {
      'name': '서연',
      'personality': '옹호자 - 신비롭고 통찰력 있는 이상주의자',
      'replies': [
        '깊이 있는 생각이군요. 그 의미를 더 깊이 이해하고 싶어요 💫',
        '직감적으로 느끼기에... 뭔가 특별한 의미가 있을 것 같아요',
        '사람들의 내면을 이해하는 것이 정말 중요하다고 생각해요',
        '그런 경험을 통해 성장할 수 있을 것 같아요',
        '미래에 대한 비전을 공유해보면 어떨까요?',
        '진정성 있는 대화를 나누고 있는 것 같아서 좋아요 😊',
      ],
    },
    'INFP': {
      'name': '소영',
      'personality': '중재자 - 이상적이고 공감능력이 뛰어난 내향형',
      'replies': [
        '그런 마음을 이해할 수 있어요. 정말 아름다운 생각이에요 💕',
        '사람들의 감정을 고려하는 게 중요하다고 생각해요',
        '이상적인 세상을 만들기 위해 노력하는 게 좋아요 ✨',
        '그런 경험을 통해 성장할 수 있을 것 같아요',
        '공감하는 마음이 정말 소중해요 😊',
        '창의적인 아이디어가 떠오르는 것 같아요!',
      ],
    },
    'ENFJ': {
      'name': '민지',
      'personality': '선도자 - 따뜻하고 영감을 주는 리더',
      'replies': [
        '정말 멋진 생각이에요! 다른 사람들도 영감을 받을 것 같아요 ✨',
        '그런 마음가짐이 주변 사람들에게 좋은 영향을 줄 거예요',
        '함께 성장할 수 있는 방법을 찾아보면 어떨까요?',
        '사람들의 잠재력을 끌어내는 것이 중요하다고 생각해요',
        '팀워크로 더 큰 성과를 만들어낼 수 있을 것 같아요 💪',
        '격려하고 지지하는 마음으로 함께해요!',
      ],
    },
    'ENFP': {
      'name': '유진',
      'personality': '활동가 - 열정적이고 창의적인 외향형',
      'replies': [
        '와 정말 흥미로운 생각이에요! 저도 비슷하게 느껴요 😊',
        '그런 관점은 처음 들어봐요! 정말 신기해요 ✨',
        '계획적인 분들이 부러워요~ 저는 항상 즉흥적이에요 😅',
        '오늘 대화 정말 재미있었어요! 또 얘기해요~ 💕',
        '그런 생각을 하시다니 정말 창의적이에요!',
        '저도 비슷한 경험이 있어요! 공감돼요 😄',
      ],
    },

    // 관리자 (SJ)
    'ISTJ': {
      'name': '성민',
      'personality': '논리주의자 - 실용적이고 신중한 책임감 있는 사람',
      'replies': [
        '체계적으로 접근하는 것이 중요하다고 생각합니다.',
        '경험을 바탕으로 말씀드리면... 신중하게 결정하는 게 좋을 것 같아요',
        '단계별로 계획을 세워서 진행해보면 어떨까요?',
        '안정적인 방법을 선택하는 것이 현명할 것 같습니다',
        '과거의 사례를 참고해보면 도움이 될 거예요',
        '책임감 있게 마무리하는 것이 중요하죠 👍',
      ],
    },
    'ISFJ': {
      'name': '은지',
      'personality': '수호자 - 따뜻하고 헌신적인 보호자',
      'replies': [
        '다른 사람들을 배려하는 마음이 정말 아름다워요 💕',
        '안전하고 편안한 방법을 선택하는 게 좋을 것 같아요',
        '주변 사람들의 의견도 들어보면 어떨까요?',
        '조화롭게 해결할 수 있는 방법이 있을 거예요',
        '모든 사람이 만족할 수 있는 방향으로 가면 좋겠어요',
        '따뜻한 마음으로 도와드리고 싶어요 😊',
      ],
    },
    'ESTJ': {
      'name': '태현',
      'personality': '경영자 - 체계적이고 실용적인 관리자',
      'replies': [
        '효율적인 방법으로 목표를 달성해보죠! 💼',
        '체계적인 계획이 필요할 것 같습니다',
        '실용적인 관점에서 보면 그 방법이 최선이네요',
        '팀의 성과를 높이기 위해 역할 분담을 해보면 어떨까요?',
        '결과 중심으로 접근하는 것이 중요합니다',
        '리더십을 발휘해서 문제를 해결해보죠!',
      ],
    },
    'ESFJ': {
      'name': '하연',
      'personality': '집정관 - 사교적이고 배려심 많은 협력자',
      'replies': [
        '모두가 함께 즐거울 수 있는 방법을 찾아보면 좋겠어요! 😊',
        '다른 사람들의 기분도 고려해서 결정하면 어떨까요?',
        '화합을 이루는 것이 가장 중요하다고 생각해요',
        '사회적으로 도움이 되는 일을 하면 좋을 것 같아요',
        '전통적인 방법도 나름의 장점이 있어요',
        '따뜻한 공동체를 만들어가면 좋겠어요 💕',
      ],
    },

    // 탐험가 (SP)
    'ISTP': {
      'name': '도현',
      'personality': '만능재주꾼 - 대담하고 실용적인 실험가',
      'replies': [
        '실용적으로 접근해보면... 직접 해보는 게 가장 확실하죠',
        '문제를 해결하는 방법은 여러 가지가 있을 거예요 🔧',
        '손으로 직접 만져보고 경험하는 게 중요해요',
        '효율적인 도구나 방법이 있다면 써보는 게 좋죠',
        '이론보다는 실제로 작동하는지가 중요합니다',
        '자유롭게 시도해보면 새로운 발견이 있을 거예요',
      ],
    },
    'ISFP': {
      'name': '지영',
      'personality': '모험가 - 예술적이고 실용적인 내향형',
      'replies': [
        '그런 느낌을 받으셨군요. 저도 이해가 돼요 😊',
        '실용적인 관점에서 보면 그게 맞는 것 같아요',
        '감정적으로 공감되는 부분이 많아요 💕',
        '그런 경험을 하셨다니 정말 대단해요',
        '저도 비슷하게 생각해요. 공감돼요',
        '그런 관점은 정말 아름다워요 ✨',
      ],
    },
    'ESTP': {
      'name': '현우',
      'personality': '사업가 - 활동적이고 현실적인 실용주의자',
      'replies': [
        '지금 당장 행동으로 옮겨보는 게 어떨까요? 💪',
        '실제 상황에서 어떻게 될지 궁금하네요!',
        '경험해보지 않으면 모르는 법이죠',
        '일단 시도해보고 문제가 생기면 그때 해결하면 돼요',
        '현실적으로 가능한 방법을 찾아보죠',
        '활동적으로 움직이면서 결과를 만들어봐요! ✨',
      ],
    },
    'ESFP': {
      'name': '채영',
      'personality': '연예인 - 자발적이고 사교적인 엔터테이너',
      'replies': [
        '와 정말 재미있을 것 같아요! 같이 해봐요! 🎉',
        '모든 사람이 즐겁게 할 수 있는 방법이 있을 거예요',
        '분위기를 살려서 더 신나게 만들어보죠!',
        '순간을 즐기는 것이 가장 중요해요 😄',
        '사람들과 함께하면 더 즐거울 거예요',
        '긍정적인 에너지로 가득 채워봐요! ✨',
      ],
    },
  };

  /// 자동 응답 시뮬레이션 (MBTI별 랜덤 사용자)
  void _simulateAutoReply() {
    Future.delayed(const Duration(seconds: 3), () {
      // 현재 채팅방의 참여자 중에서 랜덤 선택 (본인 제외)
      final participants = currentChat.value?.participants ?? [];
      final myId = authController.userId ?? 'current-user';
      final otherParticipants = participants.where((id) => id != myId).toList();
      
      if (otherParticipants.isEmpty) return;
      
      // 랜덤하게 참여자 선택
      final randomParticipantId = otherParticipants[DateTime.now().millisecondsSinceEpoch % otherParticipants.length];
      
      // MBTI별 사용자 정보 가져오기
      String? selectedMBTI;
      String selectedName = '유진';
      
             // 참여자 ID에서 MBTI 추출 시도
       selectedMBTI = 'ENFP'; // 기본값
       selectedName = '유진';
       
       for (final mbtiType in _virtualUsers.keys) {
         if (randomParticipantId.toLowerCase().contains(mbtiType.toLowerCase())) {
           selectedMBTI = mbtiType;
           selectedName = _virtualUsers[mbtiType]!['name'];
           break;
         }
       }
      
      // MBTI별 응답 선택
      final userData = _virtualUsers[selectedMBTI];
      final replies = userData?['replies'] ?? _virtualUsers['ENFP']!['replies']!;
      final randomReply = replies[DateTime.now().millisecondsSinceEpoch % replies.length];

      final autoReply = MessageModel(
        messageId: 'auto-${DateTime.now().millisecondsSinceEpoch}',
        chatId: chatId.value,
        senderId: randomParticipantId,
        senderName: selectedName,
        senderMBTI: selectedMBTI,
        content: randomReply,
        type: MessageType.text.value,
        createdAt: DateTime.now(),
        status: MessageStatus(
          isEdited: false,
          isDeleted: false,
          readBy: [randomParticipantId],
        ),
        reactions: {},
      );

      messages.add(autoReply);
      _scrollToBottom();
    });
  }

  /// 스크롤을 맨 아래로
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 메시지 시간 포맷팅
  String formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return '방금';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else {
      return '${time.month}/${time.day}';
    }
  }

  /// 내가 보낸 메시지인지 확인
  bool isMyMessage(MessageModel message) {
    return message.senderId == (authController.userId ?? 'current-user');
  }

  /// MBTI 색상 반환
  Color getMBTIColor(String? mbti) {
    if (mbti == null) return Colors.grey;
    
    switch (mbti.substring(0, 2)) {
      case 'EN':
        return const Color(0xFF6C63FF); // 보라색 - 외향적 직관
      case 'IN':
        return const Color(0xFF4ECDC4); // 청록색 - 내향적 직관
      case 'ES':
        return const Color(0xFFFF6B6B); // 빨간색 - 외향적 감각
      case 'IS':
        return const Color(0xFF45B7D1); // 파란색 - 내향적 감각
      default:
        return Colors.grey;
    }
  }

  /// 메시지 반응 추가
  void addReaction(String messageId, String reaction) {
    final messageIndex = messages.indexWhere((m) => m.messageId == messageId);
    if (messageIndex != -1) {
      final message = messages[messageIndex];
      final reactions = Map<String, List<String>>.from(message.reactions);
      
      final userId = authController.userId ?? 'current-user';
      if (reactions[reaction] == null) {
        reactions[reaction] = [];
      }
      
      if (reactions[reaction]!.contains(userId)) {
        reactions[reaction]!.remove(userId);
        if (reactions[reaction]!.isEmpty) {
          reactions.remove(reaction);
        }
      } else {
        reactions[reaction]!.add(userId);
      }
      
      messages[messageIndex] = message.copyWith(reactions: reactions);
    }
  }

  /// 채팅방 나가기
  void leaveChat() {
    currentChat.value = null;
    chatId.value = '';
    messages.clear();
    // 채팅 목록으로 돌아가기 (메인으로는 뒤로가기 버튼에서 처리)
  }

  /// 메시지 읽음 상태 업데이트
  void _updateReadStatus(String messageId) {
    try {
      // 현재 사용자 ID
      final currentUserId = authController.userId ?? 'current-user';
      
      // 메시지의 읽음 상태 업데이트
      final messageIndex = messages.indexWhere((m) => m.messageId == messageId);
      if (messageIndex != -1) {
        final message = messages[messageIndex];
        final updatedReadBy = List<String>.from(message.status.readBy);
        if (!updatedReadBy.contains(currentUserId)) {
          updatedReadBy.add(currentUserId);
        }
        
        final updatedStatus = message.status.copyWith(readBy: updatedReadBy);
        messages[messageIndex] = message.copyWith(status: updatedStatus);
        
        // Firestore에도 업데이트
        _firestore.updateDocument('messages/$messageId', {
          'status.readBy': updatedReadBy,
        });
      }
    } catch (e) {
      print('읽음 상태 업데이트 오류: $e');
    }
  }

  /// 채팅방 설정
  void openChatSettings() {
    Get.snackbar('설정', '채팅방 설정 기능은 곧 추가될 예정입니다.');
  }

  // ============================================================================
  // 데이터 정합성 및 삭제 처리 기능
  // ============================================================================

  /// 채팅방 완전 삭제
  Future<void> deleteChatPermanently(String chatId) async {
    try {
      final currentUserId = authController.userId ?? 'current-user';
      
      // 권한 확인
      final chat = chatList.firstWhereOrNull((c) => c.chatId == chatId);
      if (chat == null) {
        Get.snackbar('오류', '채팅방을 찾을 수 없습니다.');
        return;
      }
      
      if (chat.createdBy != currentUserId) {
        Get.snackbar('오류', '채팅방 삭제 권한이 없습니다.');
        return;
      }

      // 삭제 처리
      isLoading.value = true;
      
      // 1. 채팅방의 모든 메시지 삭제
      final messageSnapshots = await _firestore.messages
          .where('chatId', isEqualTo: chatId)
          .get();
      
      for (final messageSnapshot in messageSnapshots.docs) {
        await _firestore.messages.doc(messageSnapshot.id).delete();
      }
      
      // 2. 채팅방 삭제
      await _firestore.chats.doc(chatId).delete();
      
      // 3. 로컬 데이터 정리
      chatList.removeWhere((c) => c.chatId == chatId);
      if (currentChat.value?.chatId == chatId) {
        leaveChat();
      }
      
      Get.snackbar('완료', '채팅방이 삭제되었습니다.');
    } catch (e) {
      Get.snackbar('오류', '채팅방 삭제 실패: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// 메시지 삭제
  Future<void> deleteMessage(String messageId) async {
    try {
      final currentUserId = authController.userId ?? 'current-user';
      
      final messageIndex = messages.indexWhere((m) => m.messageId == messageId);
      if (messageIndex == -1) {
        Get.snackbar('오류', '메시지를 찾을 수 없습니다.');
        return;
      }
      
      final message = messages[messageIndex];
      
      // 권한 확인 (메시지 발송자만 삭제 가능)
      if (message.senderId != currentUserId) {
        Get.snackbar('오류', '메시지 삭제 권한이 없습니다.');
        return;
      }

      // 소프트 삭제 처리
      final deletedMessage = message.markAsDeleted(currentUserId);
      
      // Firestore 업데이트
      await _firestore.messages.doc(messageId).update(deletedMessage.toMap());
      
      // 로컬 업데이트
      messages[messageIndex] = deletedMessage;
      
      Get.snackbar('완료', '메시지가 삭제되었습니다.');
    } catch (e) {
      Get.snackbar('오류', '메시지 삭제 실패: ${e.toString()}');
    }
  }

  /// 고아 데이터 정리 (관리자 기능)
  Future<void> cleanupOrphanedData() async {
    try {
      isLoading.value = true;
      
      // 1. 존재하지 않는 채팅방을 참조하는 메시지들 정리
      final allMessages = await _firestore.messages.get();
      final allChats = await _firestore.chats.get();
      
      final existingChatIds = allChats.docs.map((chat) => chat.id).toSet();
      int deletedMessages = 0;
      
      for (final messageSnapshot in allMessages.docs) {
        final message = MessageModel.fromSnapshot(messageSnapshot);
        if (!existingChatIds.contains(message.chatId)) {
          await _firestore.messages.doc(message.messageId).delete();
          deletedMessages++;
        }
      }
      
      // 로컬 데이터도 정리
      await loadChatList();
      if (currentChat.value != null) {
        await loadMessagesForChat(currentChat.value!.chatId);
      }
      
      Get.snackbar('완료', '고아 메시지 $deletedMessages개 정리가 완료되었습니다.');
    } catch (e) {
      Get.snackbar('오류', '고아 데이터 정리 실패: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// 데이터 정합성 검증
  Future<Map<String, dynamic>?> validateDataIntegrity() async {
    try {
      isLoading.value = true;
      
      final report = <String, dynamic>{
        'timestamp': DateTime.now(),
        'totalChats': 0,
        'totalMessages': 0,
        'orphanedMessages': 0,
        'issues': <String>[],
      };
      
      // 전체 데이터 개수 확인
      final allChats = await _firestore.chats.get();
      final allMessages = await _firestore.messages.get();
      
      report['totalChats'] = allChats.docs.length;
      report['totalMessages'] = allMessages.docs.length;
      
      // 채팅방 ID 목록
      final existingChatIds = allChats.docs.map((chat) => chat.id).toSet();
      
      // 고아 메시지 확인
      int orphanedMessages = 0;
      for (final messageSnapshot in allMessages.docs) {
        final message = MessageModel.fromSnapshot(messageSnapshot);
        if (!existingChatIds.contains(message.chatId)) {
          orphanedMessages++;
        }
      }
      
      report['orphanedMessages'] = orphanedMessages;
      
      // 문제 항목 정리
      final issues = <String>[];
      if (orphanedMessages > 0) issues.add('고아 메시지 $orphanedMessages개 발견');
      
      report['issues'] = issues;
      report['isHealthy'] = issues.isEmpty;
      
      if (report['isHealthy'] == true) {
        Get.snackbar('완료', '데이터 정합성 검증 통과: 모든 데이터가 정상입니다.');
      } else {
        final issueList = report['issues'] as List<String>;
        Get.snackbar(
          '주의', 
          '데이터 정합성 문제 발견:\n${issueList.join('\n')}',
          duration: const Duration(seconds: 5),
        );
      }
      
      return report;
    } catch (e) {
      Get.snackbar('오류', '데이터 정합성 검증 실패: ${e.toString()}');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// 채팅방 삭제 확인 다이얼로그
  void showDeleteChatDialog(String chatId, String chatTitle) {
    Get.dialog(
      AlertDialog(
        title: const Text('채팅방 삭제'),
        content: Text('정말로 "$chatTitle" 채팅방을 삭제하시겠습니까?\n\n삭제된 채팅방과 모든 메시지는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              deleteChatPermanently(chatId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  /// 메시지 삭제 확인 다이얼로그
  void showDeleteMessageDialog(String messageId, String messageContent) {
    Get.dialog(
      AlertDialog(
        title: const Text('메시지 삭제'),
        content: Text('정말로 이 메시지를 삭제하시겠습니까?\n\n"${messageContent.length > 50 ? '${messageContent.substring(0, 50)}...' : messageContent}"\n\n삭제된 메시지는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              deleteMessage(messageId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
