import 'package:chemiq/styles/app_colors.dart';
import 'package:flutter/material.dart';

/// "예/아니오"와 같은 확인을 받는 공통 다이얼로그입니다.
/// 사용자가 '확인'을 누르면 true, 그 외에는 false를 반환합니다.
Future<bool> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = '확인',
  String cancelText = '취소',
  bool isDestructive = false, // '확인' 버튼을 위험을 나타내는 빨간색으로 만들지 여부
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0), // 부드러운 모서리
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.left,),
        content: Text(
          content,
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actionsAlignment: MainAxisAlignment.center,
        actions: <Widget>[
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: AppColors.primary,
                  ),
                  child: Text(confirmText),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(cancelText),
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                ),
              ),

            ],
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// 특정 행동(예: 페이지 이동)을 유도하는 공통 다이얼로그입니다.
Future<void> showActionDialog({
  required BuildContext context,
  required String title,
  required String content,
  required String actionText,
  required VoidCallback onAction,
  String cancelText = '나중에 할게요',
  bool barrierDismissible = false,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.left,),
        content: Text(
          content,
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actionsAlignment: MainAxisAlignment.center,
        actions: <Widget>[
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(cancelText),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(actionText),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    onAction();
                  },
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

