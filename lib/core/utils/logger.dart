import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

// 전역 Logger 인스턴스
final Logger logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0, // 호출 스택 출력 줄 수
    colors: true,   // 컬러 출력
    printEmojis: true,
  ),
);

// 로그 출력 함수
void logInfo(String message) {
  if (!kReleaseMode) logger.i(message);
}

void logDebug(String message) {
  if (!kReleaseMode) logger.d(message);
}

void logWarning(String message) {
  if (!kReleaseMode) logger.w(message);
}

void logError(String message) {
  if (!kReleaseMode) logger.e(message);
}
