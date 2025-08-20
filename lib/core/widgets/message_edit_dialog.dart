import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:typetalk/core/theme/app_colors.dart';
import 'package:typetalk/core/theme/app_text_styles.dart';
import 'package:typetalk/controllers/realtime_chat_controller.dart';

/// 메시지 편집을 위한 전용 다이얼로그
class MessageEditDialog extends StatefulWidget {
  final String messageId;
  final String currentContent;
  final VoidCallback? onEditComplete;

  const MessageEditDialog({
    Key? key,
    required this.messageId,
    required this.currentContent,
    this.onEditComplete,
  }) : super(key: key);

  @override
  State<MessageEditDialog> createState() => _MessageEditDialogState();
}

class _MessageEditDialogState extends State<MessageEditDialog> {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  final RealtimeChatController _chatController = Get.find<RealtimeChatController>();
  
  bool _isEditing = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.currentContent);
    _focusNode = FocusNode();
    
    // 포커스 요청
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _textController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _textController.text.length,
      );
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleEdit() async {
    final newContent = _textController.text.trim();
    
    if (newContent.isEmpty) {
      setState(() {
        _errorMessage = '메시지 내용을 입력해주세요.';
      });
      return;
    }
    
    if (newContent == widget.currentContent) {
      Navigator.of(context).pop();
      return;
    }
    
    setState(() {
      _isEditing = true;
      _errorMessage = '';
    });
    
    try {
      await _chatController.editMessage(widget.messageId, newContent);
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onEditComplete?.call();
        
        Get.snackbar(
          '성공',
          '메시지가 편집되었습니다.',
          backgroundColor: AppColors.success,
          colorText: AppColors.white,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = '메시지 편집에 실패했습니다: $e';
      });
    } finally {
      setState(() {
        _isEditing = false;
      });
    }
  }

  void _handleCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(
          maxWidth: 400,
          minHeight: 200,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Row(
              children: [
                const Icon(
                  Icons.edit,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '메시지 편집',
                  style: AppTextStyles.h6.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 편집 안내
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '메시지를 편집하면 "(편집됨)" 표시가 나타납니다.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 입력 필드
            TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: 4,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: '메시지를 입력하세요...',
                hintStyle: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _errorMessage.isNotEmpty 
                        ? AppColors.error 
                        : AppColors.lightGrey,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _errorMessage.isNotEmpty 
                        ? AppColors.error 
                        : AppColors.primary,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: AppTextStyles.body,
              onChanged: (value) {
                if (_errorMessage.isNotEmpty) {
                  setState(() {
                    _errorMessage = '';
                  });
                }
              },
            ),
            
            // 오류 메시지
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // 버튼들
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isEditing ? null : _handleCancel,
                  child: const Text('취소'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isEditing ? null : _handleEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isEditing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.white,
                            ),
                          ),
                        )
                      : const Text('편집'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 메시지 편집 다이얼로그를 표시하는 헬퍼 함수
class MessageEditHelper {
  /// 메시지 편집 다이얼로그를 표시합니다.
  static Future<void> showEditDialog({
    required BuildContext context,
    required String messageId,
    required String currentContent,
    VoidCallback? onEditComplete,
  }) {
    return showDialog(
      context: context,
      builder: (context) => MessageEditDialog(
        messageId: messageId,
        currentContent: currentContent,
        onEditComplete: onEditComplete,
      ),
    );
  }
  
  /// 간단한 인라인 편집을 위한 위젯을 생성합니다.
  static Widget buildInlineEditor({
    required String messageId,
    required String currentContent,
    required Function(String) onEdit,
    required VoidCallback onCancel,
    bool isEditing = false,
  }) {
    return _InlineMessageEditor(
      messageId: messageId,
      currentContent: currentContent,
      onEdit: onEdit,
      onCancel: onCancel,
      isEditing: isEditing,
    );
  }
}

/// 인라인 메시지 편집을 위한 위젯
class _InlineMessageEditor extends StatefulWidget {
  final String messageId;
  final String currentContent;
  final Function(String) onEdit;
  final VoidCallback onCancel;
  final bool isEditing;

  const _InlineMessageEditor({
    required this.messageId,
    required this.currentContent,
    required this.onEdit,
    required this.onCancel,
    required this.isEditing,
  });

  @override
  State<_InlineMessageEditor> createState() => _InlineMessageEditorState();
}

class _InlineMessageEditorState extends State<_InlineMessageEditor> {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.currentContent);
    _focusNode = FocusNode();
    
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
        _textController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _textController.text.length,
        );
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSave() {
    final newContent = _textController.text.trim();
    
    if (newContent.isEmpty) {
      setState(() {
        _errorMessage = '메시지 내용을 입력해주세요.';
      });
      return;
    }
    
    if (newContent == widget.currentContent) {
      widget.onCancel();
      return;
    }
    
    widget.onEdit(newContent);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 편집 안내
          Row(
            children: [
              Icon(
                Icons.edit,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '메시지 편집 중',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 입력 필드
          TextField(
            controller: _textController,
            focusNode: _focusNode,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: '메시지를 입력하세요...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _errorMessage.isNotEmpty 
                      ? AppColors.error 
                      : AppColors.lightGrey,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _errorMessage.isNotEmpty 
                      ? AppColors.error 
                      : AppColors.primary,
                ),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: AppTextStyles.body,
            onChanged: (value) {
              if (_errorMessage.isNotEmpty) {
                setState(() {
                  _errorMessage = '';
                });
              }
            },
          ),
          
          // 오류 메시지
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          
          // 버튼들
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: const Text('취소'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text('저장'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

