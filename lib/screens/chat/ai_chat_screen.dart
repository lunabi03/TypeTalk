import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:typetalk/models/mbti_avatar_model.dart';
import 'package:typetalk/services/ai_chat_service.dart';
import 'package:typetalk/core/theme/app_colors.dart';


// AI 채팅 화면
class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIChatService _aiChatService = Get.find<AIChatService>();
  
  late MBTIAvatar avatar;
  List<Map<String, dynamic>> messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // 전달받은 아바타 정보 가져오기
    avatar = Get.arguments['avatar'] as MBTIAvatar;
    
    // 초기 인사 메시지 추가
    _addMessage('avatar', _aiChatService.generateGreetingMessage(avatar));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 메시지 추가
  void _addMessage(String sender, String content) {
    setState(() {
      messages.add({
        'sender': sender,
        'content': content,
        'timestamp': DateTime.now().toIso8601String(),
        'topic': _extractMessageTopic(content),
        'emotion': _extractMessageEmotion(content),
      });
    });
    
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
  }

  // 메시지 주제 추출
  String _extractMessageTopic(String content) {
    final contentLower = content.toLowerCase();
    if (contentLower.contains('일') || contentLower.contains('직장') || contentLower.contains('업무')) return 'work';
    if (contentLower.contains('학교') || contentLower.contains('공부') || contentLower.contains('학업')) return 'study';
    if (contentLower.contains('가족') || contentLower.contains('부모') || contentLower.contains('형제')) return 'family';
    if (contentLower.contains('친구') || contentLower.contains('사람') || contentLower.contains('관계')) return 'relationship';
    if (contentLower.contains('건강') || contentLower.contains('운동') || contentLower.contains('병')) return 'health';
    if (contentLower.contains('돈') || contentLower.contains('경제') || contentLower.contains('재정')) return 'finance';
    return 'general';
  }

  // 메시지 감정 추출
  String _extractMessageEmotion(String content) {
    final contentLower = content.toLowerCase();
    if (contentLower.contains('힘들') || contentLower.contains('나쁘') || contentLower.contains('싫') || 
        contentLower.contains('어렵') || contentLower.contains('불안') || contentLower.contains('걱정') ||
        contentLower.contains('슬프') || contentLower.contains('화나') || contentLower.contains('짜증') ||
        contentLower.contains('지치') || contentLower.contains('피곤') || contentLower.contains('아프')) {
      return 'negative';
    } else if (contentLower.contains('좋') || contentLower.contains('기쁘') || contentLower.contains('즐겁') ||
               contentLower.contains('신나') || contentLower.contains('행복') || contentLower.contains('만족') ||
               contentLower.contains('감사')) {
      return 'positive';
    }
    return 'neutral';
  }

  // 사용자 메시지 전송
  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // 사용자 메시지 추가
    _addMessage('user', message);
    _messageController.clear();

    // AI 응답 생성 중 표시
    setState(() {
      _isTyping = true;
    });

    try {
      // AI 응답 생성
      final aiResponse = await _aiChatService.generateAvatarResponse(
        avatar,
        message,
        messages,
      );

      // 타이핑 효과를 위한 지연
      await Future.delayed(const Duration(milliseconds: 1000));

      // AI 응답 추가
      _addMessage('avatar', aiResponse);
    } catch (e) {
      _addMessage('avatar', '죄송해요, 응답을 생성하는 중에 오류가 발생했어요.');
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }

  // 대화 종료
  void _endConversation() {
    // 대화 맥락 분석을 위한 컨텍스트 생성
    final context = <String, dynamic>{
      'messageCount': messages.length,
      'conversationStage': messages.length <= 3 ? 'first_meeting' : 
                           messages.length <= 10 ? 'getting_to_know' : 'deep_conversation',
    };
    
    Get.dialog(
      AlertDialog(
        title: Text('대화 종료'),
        content: Text('${avatar.name}와의 대화를 종료하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // 대화 종료 메시지 생성
              final farewellMessage = _aiChatService.generateFarewellMessage(avatar, context);
              _addMessage('avatar', farewellMessage);
              
              // 잠시 후 채팅 화면 종료
              Future.delayed(const Duration(seconds: 2), () {
                Get.back();
              });
            },
            child: Text('종료'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: Row(
          children: [
            // 아바타 아바타
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: _getAvatarColor(avatar.mbtiType),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Center(
                child: Text(
                  avatar.name[0],
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  avatar.name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  avatar.mbtiType,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: _endConversation,
          ),
        ],
      ),
      body: Column(
        children: [
          // 채팅 영역
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              itemCount: messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && _isTyping) {
                  // 타이핑 중 표시
                  return _buildTypingIndicator();
                }
                
                final message = messages[index];
                final isUser = message['sender'] == 'user';
                
                return _buildMessageBubble(message, isUser);
              },
            ),
          ),

          // 메시지 입력 영역
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: const Color(0xFFE9ECEF),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: '${avatar.name}에게 메시지를 입력하세요...',
                        hintStyle: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black45,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: _getAvatarColor(avatar.mbtiType),
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 메시지 버블 위젯
  Widget _buildMessageBubble(Map<String, dynamic> message, bool isUser) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // 아바타 아바타
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: _getAvatarColor(avatar.mbtiType),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Center(
                child: Text(
                  avatar.name[0],
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
          ],
          
          // 메시지 내용
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isUser ? _getAvatarColor(avatar.mbtiType) : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message['content'] ?? '',
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
            // 사용자 아바타
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 타이핑 중 표시 위젯
  Widget _buildTypingIndicator() {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          // 아바타 아바타
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: _getAvatarColor(avatar.mbtiType),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Center(
              child: Text(
                avatar.name[0],
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          
          // 타이핑 애니메이션
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                SizedBox(width: 4.w),
                _buildTypingDot(1),
                SizedBox(width: 4.w),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 타이핑 점 애니메이션
  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: Colors.black45,
            shape: BoxShape.circle,
          ),
          child: AnimatedOpacity(
            opacity: value,
            duration: const Duration(milliseconds: 200),
            child: Container(),
          ),
        );
      },
      onEnd: () {
        // 애니메이션 반복
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  // MBTI 유형별 색상 반환
  Color _getAvatarColor(String mbtiType) {
    final colorMap = {
      'ENFP': const Color(0xFFFF6B6B),
      'INTJ': const Color(0xFF191970),
      'ISFJ': const Color(0xFFDEB887),
      'ENTP': const Color(0xFF45B7D1),
      'INFJ': const Color(0xFF2E8B57),
      'ESTJ': const Color(0xFF4682B4),
      'ISFP': const Color(0xFFFF69B4),
      'INTP': const Color(0xFF4169E1),
    };

    return colorMap[mbtiType] ?? AppColors.primary;
  }
}
