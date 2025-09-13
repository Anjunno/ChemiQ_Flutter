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
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: Text(title),
        content: Text(content, style: Theme.of(context).textTheme.bodyMedium),
        actions: <Widget>[
          TextButton(
            child: Text(cancelText),
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          TextButton(
            child: Text(
              confirmText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDestructive ? Colors.red : Theme.of(context).colorScheme.primary,
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      );
    },
  );
  // 사용자가 다이얼로그 바깥을 탭하여 닫으면 null이 반환되므로, false로 처리합니다.
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
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: Text(title),
        content: Text(content, style: Theme.of(context).textTheme.bodyMedium),
        actions: <Widget>[
          TextButton(
            child: Text(cancelText),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          ElevatedButton(
            child: Text(actionText),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onAction(); // '확인' 버튼에 연결된 특정 행동 실행
            },
          ),
        ],
      );
    },
  );
}
