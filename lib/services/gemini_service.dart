import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../config/gemini_config.dart';

/// GEMINI API 응답 모델
class GeminiResponse {
  final String text;
  final bool success;
  final String? error;

  GeminiResponse({
    required this.text,
    required this.success,
    this.error,
  });

  factory GeminiResponse.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 GeminiResponse.fromJson 시작');
      print('📄 입력 JSON 키: ${json.keys.toList()}');
      
      if (!json.containsKey('candidates')) {
        print('❌ candidates 키가 없음');
        return GeminiResponse(
          text: '응답을 처리할 수 없습니다.',
          success: false,
          error: 'candidates 키가 없음',
        );
      }
      
      final candidates = json['candidates'] as List;
      print('📋 candidates 개수: ${candidates.length}');
      
      if (candidates.isEmpty) {
        print('❌ candidates가 비어있음');
        return GeminiResponse(
          text: '응답을 처리할 수 없습니다.',
          success: false,
          error: 'candidates가 비어있음',
        );
      }
      
      final firstCandidate = candidates[0];
      print('📋 첫 번째 candidate: ${firstCandidate.keys.toList()}');
      
      if (!firstCandidate.containsKey('content')) {
        print('❌ content 키가 없음');
        return GeminiResponse(
          text: '응답을 처리할 수 없습니다.',
          success: false,
          error: 'content 키가 없음',
        );
      }
      
      final content = firstCandidate['content'];
      print('📄 content 키: ${content.keys.toList()}');
      
      if (!content.containsKey('parts')) {
        print('❌ parts 키가 없음');
        return GeminiResponse(
          text: '응답을 처리할 수 없습니다.',
          success: false,
          error: 'parts 키가 없음',
        );
      }
      
      final parts = content['parts'] as List;
      print('📋 parts 개수: ${parts.length}');
      
      if (parts.isEmpty) {
        print('❌ parts가 비어있음');
        return GeminiResponse(
          text: '응답을 처리할 수 없습니다.',
          success: false,
          error: 'parts가 비어있음',
        );
      }
      
      final firstPart = parts[0];
      print('📋 첫 번째 part: ${firstPart.keys.toList()}');
      
      if (!firstPart.containsKey('text')) {
        print('❌ text 키가 없음');
        return GeminiResponse(
          text: '응답을 처리할 수 없습니다.',
          success: false,
          error: 'text 키가 없음',
        );
      }
      
      final text = firstPart['text'] as String;
      print('✅ 텍스트 추출 성공: ${text.substring(0, text.length > 100 ? 100 : text.length)}...');
      
      return GeminiResponse(text: text, success: true);
    } catch (e, stackTrace) {
      print('💥 GeminiResponse.fromJson 예외 발생');
      print('🚨 오류 메시지: $e');
      print('📚 스택 트레이스: $stackTrace');
      
      return GeminiResponse(
        text: '응답을 처리할 수 없습니다.',
        success: false,
        error: e.toString(),
      );
    }
  }

  factory GeminiResponse.error(String error) {
    return GeminiResponse(
      text: '오류가 발생했습니다.',
      success: false,
      error: error,
    );
  }
}

/// GEMINI API 서비스
class GeminiService extends GetxService {
  final _isLoading = false.obs;
  final _conversationHistory = <Map<String, String>>[].obs;

  bool get isLoading => _isLoading.value;
  List<Map<String, String>> get conversationHistory => _conversationHistory;

  /// GEMINI API에 메시지 전송
  Future<GeminiResponse> sendMessage(String message, {String? context}) async {
    try {
      _isLoading.value = true;
      
      print('🚀 GEMINI API 호출 시작');
      print('📝 사용자 메시지: $message');
      print('🔗 API URL: ${GeminiConfig.apiUrl}');
      print('🔑 API 키: ${GeminiConfig.apiKey.substring(0, 10)}...');
      
      // 대화 히스토리 추가
      _conversationHistory.add({
        'role': 'user',
        'content': message,
      });

      // API 요청 본문 구성
      final requestBody = _buildRequestBody(message, context);
      print('📦 요청 본문 구성 완료');
      print('📊 요청 본문 크기: ${jsonEncode(requestBody).length} bytes');
      
      // API 요청 전송
      print('🌐 HTTP 요청 전송 중...');
      final response = await http.post(
        Uri.parse(GeminiConfig.apiUrl),
        headers: GeminiConfig.headers,
        body: jsonEncode(requestBody),
      );

      print('📡 HTTP 응답 수신');
      print('📊 응답 상태 코드: ${response.statusCode}');
      print('📏 응답 본문 크기: ${response.body.length} bytes');
      print('🔍 응답 헤더: ${response.headers}');

      if (response.statusCode == 200) {
        print('✅ HTTP 200 성공 응답');
        print('📄 응답 본문: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');
        
        final responseData = jsonDecode(response.body);
        print('🔍 JSON 파싱 성공');
        print('📊 응답 데이터 구조: ${responseData.keys.toList()}');
        
        final geminiResponse = GeminiResponse.fromJson(responseData);
        print('🎯 GeminiResponse 생성 완료');
        print('📝 AI 응답 텍스트: ${geminiResponse.text.substring(0, geminiResponse.text.length > 200 ? 200 : geminiResponse.text.length)}...');
        print('✅ 성공 여부: ${geminiResponse.success}');
        
        if (geminiResponse.success) {
          // AI 응답을 대화 히스토리에 추가
          _conversationHistory.add({
            'role': 'assistant',
            'content': geminiResponse.text,
          });
          print('💾 AI 응답을 대화 히스토리에 저장 완료');
        }
        
        return geminiResponse;
      } else {
        print('❌ HTTP 오류 응답');
        print('🚫 상태 코드: ${response.statusCode}');
        print('🚫 응답 본문: ${response.body}');
        
        final errorResponse = GeminiResponse.error(
          'API 요청 실패: ${response.statusCode} - ${response.reasonPhrase}',
        );
        return errorResponse;
      }
    } catch (e, stackTrace) {
      print('💥 예외 발생');
      print('🚨 오류 메시지: $e');
      print('📚 스택 트레이스: $stackTrace');
      
      final errorResponse = GeminiResponse.error('네트워크 오류: $e');
      return errorResponse;
    } finally {
      _isLoading.value = false;
      print('🏁 GEMINI API 호출 완료');
    }
  }

  /// API 요청 본문 구성
  Map<String, dynamic> _buildRequestBody(String message, String? context) {
    print('🔧 API 요청 본문 구성 시작');
    
    final parts = [
      {
        'text': GeminiConfig.systemPrompt,
      },
    ];
    print('📋 시스템 프롬프트 추가: ${GeminiConfig.systemPrompt.substring(0, 50)}...');

    // 컨텍스트가 있으면 추가
    if (context != null && context.isNotEmpty) {
      parts.add({
        'text': '컨텍스트: $context\n\n',
      });
      print('🎯 컨텍스트 추가: $context');
    } else {
      print('ℹ️ 컨텍스트 없음');
    }

    // 대화 히스토리 추가 (최근 10개 메시지)
    final recentHistory = _conversationHistory.take(10).toList();
    print('📚 대화 히스토리 ${recentHistory.length}개 메시지 추가');
    for (final entry in recentHistory) {
      parts.add({
        'text': '${entry['role'] == 'user' ? '사용자' : 'AI'}: ${entry['content']}\n',
      });
    }

    // 현재 메시지 추가
    parts.add({
      'text': '사용자: $message',
    });
    print('💬 현재 메시지 추가: $message');

    final requestBody = {
      'contents': [
        {
          'parts': parts,
        },
      ],
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 1024,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
      ],
    };

    print('📊 요청 본문 구성 완료');
    print('📋 parts 개수: ${parts.length}');
    print('⚙️ generationConfig: ${requestBody['generationConfig']}');
    print('🛡️ safetySettings: ${(requestBody['safetySettings'] as List).length}개 설정');

    return requestBody;
  }

  /// 대화 히스토리 초기화
  void clearHistory() {
    _conversationHistory.clear();
  }

  /// 특정 MBTI 컨텍스트로 메시지 전송
  Future<GeminiResponse> sendMessageWithMBTI(String message, String mbtiType) {
    final context = '사용자의 MBTI 유형은 $mbtiType입니다. 이 정보를 바탕으로 더 개인화된 답변을 제공해주세요.';
    return sendMessage(message, context: context);
  }

  /// MBTI 관련 질문에 특화된 응답
  Future<GeminiResponse> askMBTIQuestion(String question, String? userMBTI) {
    String enhancedQuestion = question;
    if (userMBTI != null && userMBTI.isNotEmpty) {
      enhancedQuestion = '사용자 MBTI: $userMBTI\n\n$question';
    }
    
    final mbtiContext = '''
MBTI 전문가로서 답변해주세요. 
MBTI 유형별 특성, 궁합, 커뮤니케이션 스타일 등에 대해 정확하고 도움이 되는 정보를 제공해주세요.
답변은 친근하고 이해하기 쉽게 작성해주세요.
''';
    
    return sendMessage(enhancedQuestion, context: mbtiContext);
  }
}
