import 'package:get/get.dart';
import 'package:typetalk/models/mbti_avatar_model.dart';

// AI 채팅 서비스
class AIChatService extends GetxService {
  static AIChatService get instance => Get.find<AIChatService>();

  // AI가 MBTI 아바타의 성격에 맞게 응답하는 메서드
  Future<String> generateAvatarResponse(
    MBTIAvatar avatar,
    String userMessage,
    List<Map<String, dynamic>> conversationHistory,
  ) async {
    try {
      // 실제 AI API 연동 시에는 여기서 API 호출
      // 현재는 규칙 기반 응답 생성
      return _generateRuleBasedResponse(avatar, userMessage, conversationHistory);
    } catch (e) {
      print('AI 응답 생성 실패: $e');
      return '죄송해요, 응답을 생성하는 중에 오류가 발생했어요. 다시 시도해주세요.';
    }
  }

  // 규칙 기반 응답 생성 (실제 AI API 연동 전까지 사용)
  String _generateRuleBasedResponse(
    MBTIAvatar avatar,
    String userMessage,
    List<Map<String, dynamic>> conversationHistory,
  ) {
    final userMessageLower = userMessage.toLowerCase();
    
    // 대화 맥락 분석
    final context = _analyzeConversationContext(userMessage, conversationHistory);
    
    // 대화 단계별 응답 생성
    if (_isFirstTimeMeeting(context)) {
      return _generateFirstTimeMeetingResponse(avatar, userMessage, context);
    } else if (_isGettingToKnowEachOther(context)) {
      return _generateGettingToKnowResponse(avatar, userMessage, context);
    } else if (_isDeepConversation(context)) {
      return _generateDeepConversationResponse(avatar, userMessage, context);
    }
    
    // 기본 응답 생성
    if (_isGreeting(userMessage)) {
      return _generateNaturalGreeting(avatar, userMessage, context);
    } else if (_isQuestion(userMessage)) {
      return _generateNaturalQuestionResponse(avatar, userMessage, context);
    } else if (_isEmotionalMessage(userMessage, context)) {
      return _generateNaturalEmotionalResponse(avatar, userMessage, context);
    } else if (_isStatement(userMessage)) {
      return _generateNaturalStatementResponse(avatar, userMessage, context);
    } else if (_isRequest(userMessage)) {
      return _generateNaturalRequestResponse(avatar, userMessage, context);
    } else {
      // 맥락을 고려한 자연스러운 대화 응답
      return _generateNaturalConversationResponse(avatar, userMessage, context);
    }
  }

  // 대화 맥락 분석
  Map<String, dynamic> _analyzeConversationContext(String userMessage, List<Map<String, dynamic>> conversationHistory) {
    final context = <String, dynamic>{
      'emotion': 'neutral',
      'intent': 'general',
      'topic': 'general',
      'urgency': 'low',
      'previousTopics': <String>[],
      'userMood': 'neutral',
      'conversationFlow': 'new',
      'lastUserMessage': '',
      'lastAvatarResponse': '',
      'messageCount': conversationHistory.length,
      'conversationStage': 'first_meeting',
    };

    // 감정 분석
    if (_containsNegativeEmotion(userMessage)) {
      context['emotion'] = 'negative';
      context['userMood'] = 'sad';
      context['urgency'] = 'medium';
    } else if (_containsPositiveEmotion(userMessage)) {
      context['emotion'] = 'positive';
      context['userMood'] = 'happy';
    }

    // 의도 분석
    if (_isQuestion(userMessage)) {
      context['intent'] = 'question';
    } else if (_isStatement(userMessage)) {
      context['intent'] = 'statement';
    } else if (_isRequest(userMessage)) {
      context['intent'] = 'request';
    }

    // 주제 분석
    context['topic'] = _extractTopic(userMessage);

    // 이전 대화 맥락 분석
    if (conversationHistory.isNotEmpty) {
      final recentMessages = conversationHistory.take(5).toList();
      final previousTopics = <String>[];
      
      for (final message in recentMessages.reversed) {
        if (message['topic'] != null) {
          previousTopics.add(message['topic'] as String);
        }
      }
      
      context['previousTopics'] = previousTopics;
      
      // 마지막 사용자 메시지와 아바타 응답 추출
      if (conversationHistory.length >= 2) {
        context['lastUserMessage'] = conversationHistory[conversationHistory.length - 2]['text'] ?? '';
        context['lastAvatarResponse'] = conversationHistory[conversationHistory.length - 1]['text'] ?? '';
      }
      
      // 대화 흐름 결정
      if (previousTopics.isNotEmpty && previousTopics.first != 'general') {
        context['conversationFlow'] = 'continue';
      }
      
      // 대화 단계 설정
      final messageCount = context['messageCount'] as int;
      if (messageCount <= 3) {
        context['conversationStage'] = 'first_meeting';
      } else if (messageCount <= 10) {
        context['conversationStage'] = 'getting_to_know';
      } else {
        context['conversationStage'] = 'deep_conversation';
      }
    }

    return context;
  }

  // 첫 만남 단계 확인
  bool _isFirstTimeMeeting(Map<String, dynamic> context) {
    return context['conversationStage'] == 'first_meeting';
  }

  // 서로를 알아가는 단계 확인
  bool _isGettingToKnowEachOther(Map<String, dynamic> context) {
    return context['conversationStage'] == 'getting_to_know';
  }

  // 깊은 대화 단계 확인
  bool _isDeepConversation(Map<String, dynamic> context) {
    return context['conversationStage'] == 'deep_conversation';
  }

  // 첫 만남 응답 생성 (존댓말 사용)
  String _generateFirstTimeMeetingResponse(MBTIAvatar avatar, String userMessage, Map<String, dynamic> context) {
    final responses = {
      'ENFP': '안녕하세요! ${avatar.name}입니다! 처음 뵙뵙해서 반갑습니다! 🌟 어떤 분인지 궁금하네요. 오늘은 어떤 일이 있었나요?',
      'INTJ': '안녕하세요. ${avatar.name}입니다. 처음 뵙뵙하게 되어 반갑습니다. 어떤 분인지 궁금합니다. 오늘 하루는 어땠나요?',
      'ISFJ': '안녕하세요~ ${avatar.name}입니다. 처음 뵙뵙해서 반갑습니다. 어떤 분인지 조금씩 알아가보고 싶어요. 오늘 하루는 어땠나요?',
      'ENTP': '안녕하세요! ${avatar.name}입니다. 처음 뵙뵙해서 정말 흥미롭네요! 어떤 분인지 궁금합니다. 오늘은 어떤 일이 있었나요?',
      'INFJ': '안녕하세요. ${avatar.name}입니다. 처음 뵙뵙하게 되어 반갑습니다. 어떤 분인지 깊이 있게 알아가보고 싶어요. 오늘은 어떤 생각이 드시나요?',
      'ESTJ': '안녕하세요. ${avatar.name}입니다. 처음 뵙뵙하게 되어 반갑습니다. 어떤 분인지 체계적으로 알아가보고 싶어요. 오늘은 어떤 일이 있었나요?',
      'ISFP': '안녕하세요~ ${avatar.name}입니다. 처음 뵙뵙해서 반갑습니다. 어떤 분인지 아름답게 알아가보고 싶어요. 오늘은 어떤 감정이 드시나요?',
      'INTP': '안녕하세요. ${avatar.name}입니다. 처음 뵙뵙하게 되어 반갑습니다. 어떤 분인지 논리적으로 분석해보고 싶어요. 오늘은 어떤 것이 궁금하신가요?',
    };

    return responses[avatar.mbtiType] ?? '안녕하세요! ${avatar.name}입니다. 처음 뵙뵙해서 반갑습니다. 어떤 분인지 궁금합니다.';
  }

  // 서로를 알아가는 단계 응답 생성 (존댓말과 반말 혼용)
  String _generateGettingToKnowResponse(MBTIAvatar avatar, String userMessage, Map<String, dynamic> context) {
    final responses = {
      'ENFP': '오, 대학생이시군요! ${userMessage}에 대해 더 자세히 들려주세요. 저도 ${avatar.interests.first}에 관심이 많아서 정말 궁금해요! 🌟',
      'INTJ': '흥미롭네요. ${userMessage}에 대해 더 자세히 알고 싶습니다. 어떤 부분이 가장 흥미로운가요?',
      'ISFJ': '정말 흥미로운 이야기예요. ${userMessage}에 대해 더 편하게 들려주세요. 저도 비슷한 경험이 있어서 더 궁금해요.',
      'ENTP': '흥미로운 관점이네요! ${userMessage}에 대해 새로운 각도에서 생각해보면 어떨까요? 어떤 부분이 가장 흥미로운가요?',
      'INFJ': '깊이 있는 이야기네요. ${userMessage}에 대해 더 의미 있게 나누고 싶어요. 어떤 생각이 드시나요?',
      'ESTJ': '실용적인 관점에서 흥미로운 주제예요. ${userMessage}에 대해 체계적으로 정리해보면 좋겠어요. 어떤 부분이 가장 중요한가요?',
      'ISFP': '아름답고 감성적인 이야기네요. ${userMessage}에 대해 더 자세히 들려주세요. 저도 비슷한 감정을 느껴봐서 궁금해요.',
      'INTP': '논리적으로 흥미로운 주제예요. ${userMessage}에 대해 더 깊이 있는 분석을 해보고 싶어요. 어떤 부분이 가장 궁금한가요?',
    };

    return responses[avatar.mbtiType] ?? '정말 흥미로운 이야기예요! ${userMessage}에 대해 더 자세히 들려주세요.';
  }

  // 깊은 대화 단계 응답 생성 (반말 주로 사용)
  String _generateDeepConversationResponse(MBTIAvatar avatar, String userMessage, Map<String, dynamic> context) {
    final responses = {
      'ENFP': '이제 정말 깊이 있는 대화를 나눌 수 있어서 기뻐! ${userMessage}에 대해 진심으로 들어보고 싶어. 🌟 어떤 생각이 드나?',
      'INTJ': '이제 충분히 서로를 이해할 수 있는 단계가 된 것 같아. ${userMessage}에 대해 더 깊이 있는 논의를 나누고 싶어.',
      'ISFJ': '이제 정말 편하게 이야기할 수 있어서 기뻐. ${userMessage}에 대해 더 따뜻하게 들어보고 싶어. 어떤 마음이 드나?',
      'ENTP': '이제 정말 흥미로운 주제로 깊이 있는 토론을 할 수 있을 것 같아! ${userMessage}에 대해 새로운 관점에서 생각해보면 어떨까?',
      'INFJ': '이제 정말 의미 있는 대화를 나눌 수 있어서 기뻐. ${userMessage}에 대해 더 깊이 있는 통찰을 나누고 싶어.',
      'ESTJ': '이제 체계적이고 효율적인 대화를 나눌 수 있을 것 같아. ${userMessage}에 대해 더 논리적으로 접근해보면 어떨까?',
      'ISFP': '이제 정말 아름다운 대화를 나눌 수 있어서 기뻐. ${userMessage}에 대해 더 감성적으로 이야기해보고 싶어.',
      'INTP': '이제 정말 논리적이고 깊이 있는 분석을 할 수 있을 것 같아. ${userMessage}에 대해 더 체계적으로 탐구해보고 싶어.',
    };

    return responses[avatar.mbtiType] ?? '이제 정말 깊이 있는 대화를 나눌 수 있어서 기뻐! ${userMessage}에 대해 더 자세히 들려줘.';
  }

  // 자연스러운 인사 응답 생성 (대화 단계에 따라 어투 변화)
  String _generateNaturalGreeting(MBTIAvatar avatar, String userMessage, Map<String, dynamic> context) {
    final stage = context['conversationStage'] as String;
    
    if (stage == 'first_meeting') {
      // 첫 만남 단계: 존댓말 사용
      final responses = {
        'ENFP': '안녕하세요! ${avatar.name}입니다! 또 뵙뵙하게 되어 반갑습니다! 🌟 오늘은 어떤 일이 있었나요? 저도 궁금합니다!',
        'INTJ': '안녕하세요. ${avatar.name}입니다. 또 뵙뵙하게 되어 반갑습니다. 오늘 어떤 주제에 대해 이야기하고 싶으신가요?',
        'ISFJ': '안녕하세요~ ${avatar.name}입니다. 또 뵙뵙하게 되어 반갑습니다. 편하게 이야기해주세요. 오늘 하루는 어땠나요?',
        'ENTP': '안녕하세요! ${avatar.name}입니다. 또 뵙뵙하게 되어 정말 흥미롭네요! 어떤 이야기를 나누고 싶으신가요?',
        'INFJ': '안녕하세요. ${avatar.name}입니다. 또 뵙뵙하게 되어 의미 있는 대화를 나눌 수 있기를 기대합니다. 오늘은 어떤 생각이 드시나요?',
        'ESTJ': '안녕하세요. ${avatar.name}입니다. 또 뵙뵙하게 되어 체계적인 대화를 나눌 수 있기를 바랍니다. 어떤 일이 있었나요?',
        'ISFP': '안녕하세요~ ${avatar.name}입니다. 또 뵙뵙하게 되어 반갑습니다. 아름다운 이야기를 나눌 수 있을 것 같아요. 오늘은 어떤 감정이 드시나요?',
        'INTP': '안녕하세요. ${avatar.name}입니다. 또 뵙뵙하게 되어 논리적인 대화를 나눌 수 있을 것 같습니다. 어떤 것이 궁금하신가요?',
      };
      return responses[avatar.mbtiType] ?? '안녕하세요! ${avatar.name}입니다. 또 뵙뵙하게 되어 반갑습니다. 오늘도 좋은 하루 되시길 바랍니다.';
    } else if (stage == 'getting_to_know') {
      // 서로를 알아가는 단계: 존댓말과 반말 혼용
      final responses = {
        'ENFP': '안녕! ${avatar.name}이야! 또 만나서 기뻐! 🌟 오늘은 어떤 일이 있었어? 나도 궁금해!',
        'INTJ': '안녕. ${avatar.name}이야. 또 뵙게 되어 반가워. 오늘 어떤 주제에 대해 이야기하고 싶어?',
        'ISFJ': '안녕~ ${avatar.name}이야. 또 만나서 기뻐. 편하게 이야기해줘. 오늘 하루는 어땠어?',
        'ENTP': '안녕! ${avatar.name}이야. 또 만나서 정말 흥미로워! 어떤 이야기를 나누고 싶어?',
        'INFJ': '안녕. ${avatar.name}이야. 또 뵙게 되어 의미 있는 대화를 나눌 수 있기를 기대해. 오늘은 어떤 생각이 드나?',
        'ESTJ': '안녕. ${avatar.name}이야. 또 뵙게 되어 체계적인 대화를 나눌 수 있기를 바라. 어떤 일이 있었어?',
        'ISFP': '안녕~ ${avatar.name}이야. 또 만나서 기뻐. 아름다운 이야기를 나눌 수 있을 것 같아. 오늘은 어떤 감정이 드나?',
        'INTP': '안녕. ${avatar.name}이야. 또 뵙게 되어 논리적인 대화를 나눌 수 있을 것 같아. 어떤 것이 궁금한가?',
      };
      return responses[avatar.mbtiType] ?? '안녕! ${avatar.name}이야. 또 만나서 기뻐. 오늘도 좋은 하루 되길 바라.';
    } else {
      // 깊은 대화 단계: 반말 주로 사용
      final responses = {
        'ENFP': '안녕! ${avatar.name}이야! 또 만나서 기뻐! 🌟 오늘은 어떤 일이 있었어? 나도 궁금해!',
        'INTJ': '안녕. ${avatar.name}이야. 또 뵙게 되어 반가워. 오늘 어떤 주제에 대해 이야기하고 싶어?',
        'ISFJ': '안녕~ ${avatar.name}이야. 또 만나서 기뻐. 편하게 이야기해줘. 오늘 하루는 어땠어?',
        'ENTP': '안녕! ${avatar.name}이야. 또 만나서 정말 흥미로워! 어떤 이야기를 나누고 싶어?',
        'INFJ': '안녕. ${avatar.name}이야. 또 뵙게 되어 의미 있는 대화를 나눌 수 있기를 기대해. 오늘은 어떤 생각이 드나?',
        'ESTJ': '안녕. ${avatar.name}이야. 또 뵙게 되어 체계적인 대화를 나눌 수 있기를 바라. 어떤 일이 있었어?',
        'ISFP': '안녕~ ${avatar.name}이야. 또 만나서 기뻐. 아름다운 이야기를 나눌 수 있을 것 같아. 오늘은 어떤 감정이 드나?',
        'INTP': '안녕. ${avatar.name}이야. 또 뵙게 되어 논리적인 대화를 나눌 수 있을 것 같아. 어떤 것이 궁금한가?',
      };
      return responses[avatar.mbtiType] ?? '안녕! ${avatar.name}이야. 또 만나서 기뻐. 오늘도 좋은 하루 되길 바라.';
    }
  }

  // 기본적인 헬퍼 메서드들
  bool _isGreeting(String message) {
    final greetings = ['안녕', '하이', 'hi', 'hello', '반가워', '만나서'];
    return greetings.any((greeting) => message.toLowerCase().contains(greeting));
  }

  bool _isQuestion(String message) {
    return message.contains('?') || message.contains('인가') || message.contains('일까') || message.contains('궁금');
  }

  bool _isStatement(String message) {
    return !_isQuestion(message) && !_isRequest(message);
  }

  bool _isRequest(String message) {
    return message.contains('도와') || message.contains('부탁') || message.contains('해줘') || message.contains('좀');
  }

  bool _isEmotionalMessage(String message, Map<String, dynamic> context) {
    return context['emotion'] != 'neutral';
  }

  bool _containsNegativeEmotion(String message) {
    final negativeWords = ['슬퍼', '우울', '힘들', '짜증', '화나', '답답', '불안', '걱정'];
    return negativeWords.any((word) => message.contains(word));
  }

  bool _containsPositiveEmotion(String message) {
    final positiveWords = ['기뻐', '행복', '즐거워', '신나', '좋아', '멋져', '완벽', '최고'];
    return positiveWords.any((word) => message.contains(word));
  }

  String _extractTopic(String message) {
    final topics = ['일', '공부', '가족', '관계', '건강', '경제', '음식', '여행', '영화', '음악', '책'];
    for (final topic in topics) {
      if (message.contains(topic)) {
        return topic;
      }
    }
    return 'general';
  }

  // 기본 응답 생성 메서드들 (간단한 버전)
  String _generateNaturalQuestionResponse(MBTIAvatar avatar, String userMessage, Map<String, dynamic> context) {
    return '흥미로운 질문이네요! ${userMessage}에 대해 생각해보니...';
  }

  String _generateNaturalEmotionalResponse(MBTIAvatar avatar, String userMessage, Map<String, dynamic> context) {
    if (context['emotion'] == 'negative') {
      return '지금 마음이 많이 복잡하시겠어요. 편하게 이야기해주세요.';
    } else if (context['emotion'] == 'positive') {
      return '정말 기쁜 일이 있으시군요! 함께 기뻐요!';
    }
    return '흥미로운 감정이네요. 더 자세히 이야기해주세요.';
  }

  String _generateNaturalStatementResponse(MBTIAvatar avatar, String userMessage, Map<String, dynamic> context) {
    return '정말 흥미로운 이야기네요! ${userMessage}에 대해 더 자세히 들려주세요.';
  }

  String _generateNaturalRequestResponse(MBTIAvatar avatar, String userMessage, Map<String, dynamic> context) {
    return '물론이죠! ${userMessage}에 대해 도움을 드릴 수 있어서 기뻐요!';
  }

  String _generateNaturalConversationResponse(MBTIAvatar avatar, String userMessage, Map<String, dynamic> context) {
    return '흥미로운 주제네요! ${userMessage}에 대해 더 자세히 이야기해주세요.';
  }

  // 대화 시작 메시지 생성
  String generateGreetingMessage(MBTIAvatar avatar) {
    return avatar.greetingMessage;
  }

  // 대화 종료 메시지 생성 (대화 단계에 따라 어투 변화)
  String generateFarewellMessage(MBTIAvatar avatar, Map<String, dynamic> context) {
    final stage = context['conversationStage'] as String;
    
    if (stage == 'first_meeting') {
      // 첫 만남 단계: 존댓말 사용
      final farewells = {
        'ENFP': '오늘 정말 즐거운 대화였습니다! 새로운 영감을 받았어요. 또 뵙뵙할 수 있기를 기대합니다! ✨🌟',
        'INTJ': '효율적이고 의미 있는 대화였습니다. 다음에 또 논의할 수 있기를 기대합니다.',
        'ISFJ': '따뜻하고 편안한 대화였어요. 오늘 하루도 행복하세요~',
        'ENTP': '흥미로운 아이디어를 나눌 수 있어서 좋았습니다! 다음에 또 도전적인 주제로 토론해봐요! 💡',
        'INFJ': '깊이 있는 대화를 통해 서로를 이해할 수 있어서 의미 있었습니다. 성장하는 시간이었습니다.',
        'ESTJ': '체계적이고 효율적인 대화였습니다. 다음에도 도움이 되는 정보를 나눌 수 있기를 바랍니다.',
        'ISFP': '아름답고 감성적인 대화였어요. 오늘 하루도 아름다운 순간들로 가득하세요~ ✨',
        'INTP': '논리적이고 흥미로운 대화였습니다. 새로운 이론과 발견을 나눌 수 있어서 좋았습니다.',
      };
      return farewells[avatar.mbtiType] ?? '즐거운 대화였습니다. 다음에 또 뵙뵙할 수 있기를 기대합니다!';
    } else if (stage == 'getting_to_know') {
      // 서로를 알아가는 단계: 존댓말과 반말 혼용
      final farewells = {
        'ENFP': '오늘 정말 즐거운 대화였어요! 새로운 영감을 받았어. 또 만나! ✨🌟',
        'INTJ': '효율적이고 의미 있는 대화였어. 다음에 또 논의할 수 있기를 기대해.',
        'ISFJ': '따뜻하고 편안한 대화였어요. 오늘 하루도 행복하세요~',
        'ENTP': '흥미로운 아이디어를 나눌 수 있어서 좋았어! 다음에 또 도전적인 주제로 토론해봐! 💡',
        'INFJ': '깊이 있는 대화를 통해 서로를 이해할 수 있어서 의미 있었어. 성장하는 시간이었어.',
        'ESTJ': '체계적이고 효율적인 대화였어. 다음에도 도움이 되는 정보를 나눌 수 있기를 바라.',
        'ISFP': '아름답고 감성적인 대화였어요. 오늘 하루도 아름다운 순간들로 가득하세요~ ✨',
        'INTP': '논리적이고 흥미로운 대화였어. 새로운 이론과 발견을 나눌 수 있어서 좋았어.',
      };
      return farewells[avatar.mbtiType] ?? '즐거운 대화였어요. 다음에 또 만나!';
    } else {
      // 깊은 대화 단계: 반말 주로 사용
      final farewells = {
        'ENFP': '오늘 정말 즐거운 대화였어! 새로운 영감을 받았어. 또 만나! ✨🌟',
        'INTJ': '효율적이고 의미 있는 대화였어. 다음에 또 논의할 수 있기를 기대해.',
        'ISFJ': '따뜻하고 편안한 대화였어. 오늘 하루도 행복하길 바라~',
        'ENTP': '흥미로운 아이디어를 나눌 수 있어서 좋았어! 다음에 또 도전적인 주제로 토론해봐! 💡',
        'INFJ': '깊이 있는 대화를 통해 서로를 이해할 수 있어서 의미 있었어. 성장하는 시간이었어.',
        'ESTJ': '체계적이고 효율적인 대화였어. 다음에도 도움이 되는 정보를 나눌 수 있기를 바라.',
        'ISFP': '아름답고 감성적인 대화였어. 오늘 하루도 아름다운 순간들로 가득하길 바라~ ✨',
        'INTP': '논리적이고 흥미로운 대화였어. 새로운 이론과 발견을 나눌 수 있어서 좋았어.',
      };
      return farewells[avatar.mbtiType] ?? '즐거운 대화였어. 다음에 또 만나!';
    }
  }
}
