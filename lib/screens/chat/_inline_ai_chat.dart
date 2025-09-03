import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:typetalk/services/gemini_service.dart';

/// 하단 시트 인라인 AI 채팅 위젯
class InlineAIChat extends StatefulWidget {
  final String personaName;
  final String personaMBTI;
  final GeminiService geminiService;
  final String userMBTI;
  const InlineAIChat({
    super.key,
    required this.personaName,
    required this.personaMBTI,
    required this.geminiService,
    required this.userMBTI,
  });

  @override
  State<InlineAIChat> createState() => _InlineAIChatState();
}

class _InlineAIChatState extends State<InlineAIChat> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 대화 내용
        Expanded(
          child: Obx(() {
            final history = widget.geminiService.conversationHistory;
            if (history.isEmpty) {
              return Center(child: Text('대화를 시작해보세요!', style: TextStyle(color: Colors.grey[600])));
            }
            return ListView.builder(
              controller: _scroll,
              padding: EdgeInsets.all(16.w),
              itemCount: history.length,
              itemBuilder: (context, i) {
                final m = history[i];
                final isUser = m['role'] == 'user';
                return Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF9C27B0) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      m['content'] ?? '',
                      style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 14.sp),
                    ),
                  ),
                );
              },
            );
          }),
        ),
        // 입력 영역
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
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
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Obx(() => widget.geminiService.isLoading
                  ? SizedBox(
                      width: 40.w,
                      height: 40.w,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF9C27B0))),
                    )
                  : ElevatedButton(
                      onPressed: _send,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C27B0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                        elevation: 0,
                      ),
                      child: const Icon(Icons.send),
                    )),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await widget.geminiService.sendMessageWithMBTI(text, widget.userMBTI);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }
}


