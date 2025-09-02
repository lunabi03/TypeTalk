import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:typetalk/services/gemini_service.dart';
import 'package:typetalk/controllers/auth_controller.dart';

/// AI 채팅 화면
class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = Get.put(GeminiService());
  final AuthController _authController = Get.find<AuthController>();
  
  String? get userMBTI => _authController.userModel.value?.mbtiType;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFF9C27B0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.smart_toy,
                color: const Color(0xFF9C27B0),
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI 어시스턴트',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'GEMINI AI와 대화하세요',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey[600]),
            onPressed: () => _clearChat(),
            tooltip: '대화 초기화',
          ),
        ],
      ),
      body: Column(
        children: [
          // MBTI 정보 표시
          if (userMBTI != null)
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16.w),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFF9C27B0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: const Color(0xFF9C27B0).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: const Color(0xFF9C27B0),
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      '당신의 MBTI: $userMBTI',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF9C27B0),
                      ),
                    ),
                  ),
                  Text(
                    'AI가 더 개인화된 답변을 제공합니다',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF9C27B0).withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          
          // 대화 내용
          Expanded(
            child: Obx(() {
              if (_geminiService.conversationHistory.isEmpty) {
                return _buildWelcomeMessage();
              }
              
              return ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                itemCount: _geminiService.conversationHistory.length,
                itemBuilder: (context, index) {
                  final message = _geminiService.conversationHistory[index];
                  final isUser = message['role'] == 'user';
                  
                  return _buildMessageBubble(
                    message['content'] ?? '',
                    isUser: isUser,
                  );
                },
              );
            }),
          ),
          
          // 입력 영역
          _buildInputArea(),
        ],
      ),
    );
  }

  /// 환영 메시지
  Widget _buildWelcomeMessage() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: const Color(0xFF9C27B0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(50.r),
              ),
              child: Icon(
                Icons.smart_toy,
                size: 64.sp,
                color: const Color(0xFF9C27B0),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              '안녕하세요! AI 어시스턴트입니다',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              'MBTI 관련 질문이나 일반적인 대화를 나눠보세요.\n친근하고 도움이 되는 답변을 드리겠습니다!',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            // 빠른 질문 버튼들
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _buildQuickQuestionButton('MBTI 궁합에 대해 알려줘'),
                _buildQuickQuestionButton('ENFP 성격 특성은?'),
                _buildQuickQuestionButton('대화 잘하는 방법'),
                _buildQuickQuestionButton('스트레스 해소법'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 빠른 질문 버튼
  Widget _buildQuickQuestionButton(String question) {
    return InkWell(
      onTap: () => _sendQuickQuestion(question),
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          question,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }

  /// 빠른 질문 전송
  void _sendQuickQuestion(String question) {
    _messageController.text = question;
    _sendMessage();
  }

  /// 메시지 버블
  Widget _buildMessageBubble(String message, {required bool isUser}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: const Color(0xFF9C27B0),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 18.sp,
              ),
            ),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isUser 
                    ? const Color(0xFF9C27B0) 
                    : Colors.white,
                borderRadius: BorderRadius.circular(16.r).copyWith(
                  bottomLeft: isUser ? Radius.circular(16.r) : Radius.circular(4.r),
                  bottomRight: isUser ? Radius.circular(4.r) : Radius.circular(16.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isUser ? Colors.white : Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 8.w),
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                Icons.person,
                color: Colors.grey[600],
                size: 18.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 입력 영역
  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: '메시지를 입력하세요...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.emoji_emotions, color: Colors.grey[600]),
                    onPressed: () {
                      // TODO: 이모지 선택기 구현
                    },
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Obx(() => _geminiService.isLoading
              ? SizedBox(
                  width: 48.w,
                  height: 48.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF9C27B0)),
                  ),
                )
              : Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0),
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                    onPressed: _sendMessage,
                  ),
                )),
        ],
      ),
    );
  }

  /// 메시지 전송
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    print('💬 AI 채팅 메시지 전송 시작');
    print('📝 메시지: $message');
    print('🧠 사용자 MBTI: $userMBTI');

    _messageController.clear();
    
    // 스크롤을 맨 아래로 이동
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      print('🚀 GEMINI API 호출 시작...');
      
      // MBTI 컨텍스트와 함께 메시지 전송
      final response = await _geminiService.sendMessageWithMBTI(
        message,
        userMBTI ?? 'UNKNOWN',
      );

      print('📡 GEMINI API 응답 수신');
      print('✅ 성공 여부: ${response.success}');
      print('📝 응답 텍스트: ${response.text.substring(0, response.text.length > 100 ? 100 : response.text.length)}...');
      
      if (response.error != null) {
        print('❌ 오류 정보: ${response.error}');
      }

      if (!response.success) {
        print('🚨 API 호출 실패');
        Get.snackbar(
          '오류',
          response.error ?? '메시지 전송에 실패했습니다.',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
      } else {
        print('🎉 API 호출 성공');
      }

      // 응답 후 스크롤을 맨 아래로 이동
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e, stackTrace) {
      print('💥 메시지 전송 중 예외 발생');
      print('🚨 오류 메시지: $e');
      print('📚 스택 트레이스: $stackTrace');
      
      Get.snackbar(
        '오류',
        '메시지 전송 중 오류가 발생했습니다: $e',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  /// 대화 초기화
  void _clearChat() {
    Get.dialog(
      AlertDialog(
        title: Text('대화 초기화'),
        content: Text('모든 대화 내용이 삭제됩니다. 계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () {
              _geminiService.clearHistory();
              Get.back();
            },
            child: Text('확인'),
          ),
        ],
      ),
    );
  }
}
