import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod의 StreamProvider를 사용하여 기기의 네트워크 연결 상태 변화를 실시간으로 감시합니다.
final networkProvider = StreamProvider.autoDispose<ConnectivityResult>((ref) {
  // onConnectivityChanged는 이제 List<ConnectivityResult>의 스트림을 반환합니다.
  // .map을 사용하여, 이 목록에서 항상 가장 마지막(최신) 결과만 추출하여 반환하도록 수정합니다.
  return Connectivity().onConnectivityChanged.map((resultList) => resultList.last);
});
