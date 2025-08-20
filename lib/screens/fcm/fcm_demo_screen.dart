import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:typetalk/controllers/fcm_controller.dart';
import 'package:typetalk/core/theme/app_colors.dart';
import 'package:typetalk/core/theme/app_text_styles.dart';

/// FCM 데모 화면
/// FCM 연동 기능을 테스트할 수 있는 화면입니다.
class FCMDemoScreen extends StatelessWidget {
  const FCMDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fcmController = Get.put(FCMController());
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM 데모'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // FCM 상태 카드
            _buildStatusCard(fcmController),
            const SizedBox(height: 16),
            
            // 알림 설정 카드
            _buildSettingsCard(fcmController),
            const SizedBox(height: 16),
            
            // 알림 전송 카드
            _buildNotificationCard(fcmController),
            const SizedBox(height: 16),
            
            // FCM 토큰 카드
            _buildTokenCard(fcmController),
            const SizedBox(height: 16),
            
            // 알림 목록 카드
            _buildNotificationListCard(fcmController),
          ],
        ),
      ),
    );
  }
  
  /// FCM 상태 카드
  Widget _buildStatusCard(FCMController controller) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FCM 상태',
              style: AppTextStyles.h5.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() => _buildStatusRow('초기화 상태', controller.isFCMInitialized.value ? '완료' : '진행 중')),
            Obx(() => _buildStatusRow('권한 상태', controller.hasPermission.value ? '허용됨' : '거부됨')),
            Obx(() => _buildStatusRow('알림 활성화', controller.isNotificationEnabled.value ? '활성화' : '비활성화')),
            Obx(() => _buildStatusRow('읽지 않은 알림', '${controller.unreadCount.value}개')),
          ],
        ),
      ),
    );
  }
  
  /// 알림 설정 카드
  Widget _buildSettingsCard(FCMController controller) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '알림 설정',
              style: AppTextStyles.h5.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() => SwitchListTile(
              title: const Text('알림 활성화'),
              subtitle: const Text('푸시 알림을 받습니다'),
              value: controller.isNotificationEnabled.value,
              onChanged: (value) => controller.updateNotificationSettings(enabled: value),
            )),
            Obx(() => SwitchListTile(
              title: const Text('소리 알림'),
              subtitle: const Text('알림 시 소리를 재생합니다'),
              value: controller.isSoundEnabled.value,
              onChanged: (value) => controller.updateNotificationSettings(sound: value),
            )),
            Obx(() => SwitchListTile(
              title: const Text('진동 알림'),
              subtitle: const Text('알림 시 진동을 울립니다'),
              value: controller.isVibrationEnabled.value,
              onChanged: (value) => controller.updateNotificationSettings(vibration: value),
            )),
          ],
        ),
      ),
    );
  }
  
  /// 알림 전송 카드
  Widget _buildNotificationCard(FCMController controller) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '알림 전송',
              style: AppTextStyles.h5.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => controller.sendTestNotification(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('테스트 알림 전송'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _showCustomNotificationDialog(controller),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('사용자 정의 알림 전송'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _showChatNotificationDialog(controller),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('채팅 알림 전송'),
            ),
          ],
        ),
      ),
    );
  }
  
  /// FCM 토큰 카드
  Widget _buildTokenCard(FCMController controller) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FCM 토큰',
              style: AppTextStyles.h5.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '토큰:',
                    style: AppTextStyles.body2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.fcmToken.value.isEmpty 
                        ? '토큰을 가져오는 중...' 
                        : controller.fcmToken.value,
                    style: AppTextStyles.body2.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => controller.refreshFCMToken(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('토큰 새로고침'),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 알림 목록 카드
  Widget _buildNotificationListCard(FCMController controller) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '알림 목록',
                  style: AppTextStyles.h5.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Obx(() => Text(
                  '${controller.notifications.length}개',
                  style: AppTextStyles.body2.copyWith(
                    color: Colors.grey[600],
                  ),
                )),
              ],
            ),
            const SizedBox(height: 12),
            Obx(() => controller.notifications.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '알림이 없습니다',
                          style: AppTextStyles.body2.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '위의 버튼을 눌러 테스트 알림을 전송해보세요',
                          style: AppTextStyles.body2.copyWith(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: controller.notifications
                        .take(5)
                        .map((notification) => _buildNotificationItem(notification, controller))
                        .toList(),
                  )),
            if (controller.notifications.isNotEmpty) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => controller.markAllNotificationsAsRead(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('모든 알림 읽음 처리'),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 상태 행 위젯
  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body2.copyWith(
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: AppTextStyles.body2.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 알림 아이템 위젯
  Widget _buildNotificationItem(dynamic notification, FCMController controller) {
    final isRead = notification.status?.value == 'read';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRead ? Colors.grey[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isRead ? Colors.grey[300]! : Colors.blue[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  notification.title ?? '알림',
                  style: AppTextStyles.body2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isRead ? Colors.grey[700] : Colors.blue[700],
                  ),
                ),
              ),
              if (!isRead)
                IconButton(
                  onPressed: () => controller.markNotificationAsRead(notification.notificationId),
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  color: Colors.green,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          if (notification.body != null) ...[
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: AppTextStyles.body2.copyWith(
                color: isRead ? Colors.grey[600] : Colors.blue[600],
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            _formatDateTime(notification.createdAt),
            style: AppTextStyles.body2.copyWith(
              color: Colors.grey[500],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 사용자 정의 알림 다이얼로그
  void _showCustomNotificationDialog(FCMController controller) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: const Text('사용자 정의 알림'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: '알림 제목',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(
                labelText: '알림 내용',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty && bodyController.text.isNotEmpty) {
                Get.back();
                await controller.sendSystemNotification(
                  title: titleController.text,
                  body: bodyController.text,
                  recipientIds: ['current_user'],
                );
              }
            },
            child: const Text('전송'),
          ),
        ],
      ),
    );
  }
  
  /// 채팅 알림 다이얼로그
  void _showChatNotificationDialog(FCMController controller) {
    final senderNameController = TextEditingController(text: '테스트 사용자');
    final messageController = TextEditingController(text: '안녕하세요! 테스트 메시지입니다.');
    final chatTitleController = TextEditingController(text: '테스트 채팅방');
    
    Get.dialog(
      AlertDialog(
        title: const Text('채팅 알림 전송'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: senderNameController,
              decoration: const InputDecoration(
                labelText: '발신자 이름',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: '메시지 내용',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: chatTitleController,
              decoration: const InputDecoration(
                labelText: '채팅방 제목',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (senderNameController.text.isNotEmpty && 
                  messageController.text.isNotEmpty &&
                  chatTitleController.text.isNotEmpty) {
                Get.back();
                await controller.sendChatNotification(
                  chatId: 'demo_chat_${DateTime.now().millisecondsSinceEpoch}',
                  senderId: 'demo_sender',
                  senderName: senderNameController.text,
                  messageContent: messageController.text,
                  recipientIds: ['current_user'],
                  chatTitle: chatTitleController.text,
                );
              }
            },
            child: const Text('전송'),
          ),
        ],
      ),
    );
  }
  
  /// 날짜 시간 포맷팅
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '알 수 없음';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}
