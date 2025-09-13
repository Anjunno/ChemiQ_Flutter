import 'package:chemiq/styles/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

// 토스트 메시지의 타입을 정의합니다.
enum ToastType { success, error, normal }

/// 앱 전체에서 사용할 일관된 디자인의 토스트 메시지를 보여줍니다.
///
/// 사용 예시:
/// showChemiQToast('요청 성공!', type: ToastType.success);
/// showChemiQToast('에러 발생!', type: ToastType.error);
void showChemiQToast(
    String message, {
      ToastType type = ToastType.normal,
    }) {
  Color backgroundColor;

  // 타입에 따라 배경색을 결정합니다.
  switch (type) {
    case ToastType.success:
      backgroundColor = AppColors.secondary; // 성공: 세이지 그린
      break;
    case ToastType.error:
      backgroundColor = AppColors.primary; // 에러: 빨간색
      break;
    case ToastType.normal:
      backgroundColor = Colors.black87; // 일반: 검은색
      break;
  }

  Fluttertoast.showToast(
    msg: message,
    gravity: ToastGravity.BOTTOM, // 화면 하단에 표시
    backgroundColor: backgroundColor,
    textColor: Colors.white,
    fontSize: 16.0,
    toastLength: Toast.LENGTH_SHORT,
  );
}
