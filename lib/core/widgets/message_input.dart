import 'package:flutter/material.dart';
import 'package:typetalk/core/theme/app_colors.dart';
import 'package:typetalk/core/theme/app_text_styles.dart';
import 'package:typetalk/models/message_model.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(MessageReply?)? onReplyChanged;
  final MessageReply? replyTo;
  final bool isLoading;
  final bool isTyping;
  final VoidCallback? onTypingStart;
  final VoidCallback? onTypingStop;

  const MessageInput({
    Key? key,
    required this.onSendMessage,
    this.onReplyChanged,
    this.replyTo,
    this.isLoading = false,
    this.isTyping = false,
    this.onTypingStart,
    this.onTypingStop,
  }) : super(key: key);

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final isComposing = _textController.text.isNotEmpty;
    if (isComposing != _isComposing) {
      setState(() {
        _isComposing = isComposing;
      });
      
      if (isComposing) {
        widget.onTypingStart?.call();
      } else {
        widget.onTypingStop?.call();
      }
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      widget.onTypingStop?.call();
    }
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    
    widget.onSendMessage(text.trim());
    _textController.clear();
    _isComposing = false;
    
    // 답글 상태 초기화
    if (widget.replyTo != null) {
      widget.onReplyChanged?.call(null);
    }
  }

  void _clearReply() {
    widget.onReplyChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 답글 표시
          if (widget.replyTo != null) ...[
            Container(
              padding: const EdgeInsets.all(12.0),
              margin: const EdgeInsets.only(bottom: 8.0),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.reply,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.replyTo!.senderName,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          widget.replyTo!.content,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _clearReply,
                    icon: Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // 메시지 입력 필드
          Row(
            children: [
              // 첨부 파일 버튼
              IconButton(
                onPressed: widget.isLoading ? null : _showAttachmentOptions,
                icon: Icon(
                  Icons.attach_file,
                  color: AppColors.textSecondary,
                ),
                tooltip: '파일 첨부',
              ),
              
              // 메시지 입력 필드
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(
                      color: _focusNode.hasFocus 
                          ? AppColors.primary 
                          : AppColors.border,
                    ),
                  ),
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    enabled: !widget.isLoading,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _handleSubmitted,
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요...',
                      hintStyle: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                    ),
                    style: AppTextStyles.body,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // 전송 버튼
              Container(
                decoration: BoxDecoration(
                  color: _isComposing && !widget.isLoading 
                      ? AppColors.primary 
                      : AppColors.disabled,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isComposing && !widget.isLoading 
                      ? () => _handleSubmitted(_textController.text)
                      : null,
                  icon: widget.isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                  tooltip: '전송',
                ),
              ),
            ],
          ),
          
          // 타이핑 상태 표시
          if (widget.isTyping) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '타이핑 중...',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo, color: AppColors.primary),
              title: Text('사진/동영상'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.primary),
              title: Text('카메라'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: Icon(Icons.folder, color: AppColors.primary),
              title: Text('파일'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
            ListTile(
              leading: Icon(Icons.location_on, color: AppColors.primary),
              title: Text('위치'),
              onTap: () {
                Navigator.pop(context);
                _shareLocation();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _pickImage() {
    // TODO: 이미지 선택 구현
  }

  void _takePhoto() {
    // TODO: 카메라 촬영 구현
  }

  void _pickFile() {
    // TODO: 파일 선택 구현
  }

  void _shareLocation() {
    // TODO: 위치 공유 구현
  }
} 