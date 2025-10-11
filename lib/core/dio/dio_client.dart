//
// import 'dart:async';
//
// import 'package:chemiq/core/di/service_locator.dart';
// import 'package:chemiq/core/ui/chemiq_toast.dart';
// import 'package:chemiq/data/models/reissue_request.dart';
// import 'package:chemiq/data/models/reissue_response.dart';
// import 'package:chemiq/features/auth/provider/auth_state_provider.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
//
// import '../../main.dart';
//
// class DioClient {
//   final Dio dio;
//   late final Dio _tokenDio;
//   final FlutterSecureStorage storage;
//   final ProviderContainer _container;
//
//   bool _isForceLogout = false;
//   // ★★★★★ 수정: _isRefreshing 플래그와 콜백 리스트를 Completer로 대체 ★★★★★
//   Completer<void>? _refreshCompleter;
//
//   DioClient({
//     required this.dio,
//     required this.storage,
//     required ProviderContainer container,
//   }) : _container = container {
//     dio.options = BaseOptions(
//       baseUrl: dotenv.env['SERVER_URL'] ?? 'http://localhost:8080',
//       connectTimeout: const Duration(seconds: 5),
//       receiveTimeout: const Duration(seconds: 5),
//     );
//
//     _tokenDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
//
//     dio.interceptors.add(
//       QueuedInterceptorsWrapper(
//         onRequest: (options, handler) async {
//           print('➡️ [REQ] ${options.method} ${options.uri}');
//
//           if (_isForceLogout) {
//             return handler.reject(
//               DioException(
//                 requestOptions: options,
//                 message: '로그아웃이 진행 중이라 요청을 취소합니다.',
//               ),
//             );
//           }
//
//           final connectivityResult = await Connectivity().checkConnectivity();
//           if (connectivityResult == ConnectivityResult.none) {
//             return handler.reject(DioException(requestOptions: options, message: '인터넷 연결을 확인해주세요.'));
//           }
//           if (!options.path.contains('/login') && !options.path.contains('/signup') && !options.path.contains('/reissue')) {
//             final accessToken = await storage.read(key: 'accessToken');
//             if (accessToken != null) {
//               options.headers['Authorization'] = 'Bearer $accessToken';
//             }
//           }
//           return handler.next(options);
//         },
//         onResponse: (response, handler) {
//           print('⬅️ [RES] ${response.statusCode} | ${response.requestOptions.method} ${response.requestOptions.uri}');
//           return handler.next(response);
//         },
//         onError: (DioException e, handler) async {
//           print('💀 [ERR] ${e.response?.statusCode} | ${e.requestOptions.method} ${e.requestOptions.uri}');
//
//           if (e.response?.statusCode == 401) {
//             if (e.requestOptions.extra['isLogoutRequest'] == true) {
//               return handler.next(e);
//             }
//
//             // ★★★★★ 수정: Completer를 사용한 새로운 토큰 재발급 로직 ★★★★★
//
//             // 1. 이미 다른 요청이 토큰 재발급을 진행 중인 경우
//             if (_refreshCompleter != null) {
//               try {
//                 // 진행 중인 재발급 작업이 끝날 때까지 기다립니다.
//                 await _refreshCompleter!.future;
//
//                 // 재발급이 성공적으로 끝났으므로, 새 토큰으로 현재 요청을 재시도합니다.
//                 final newAccessToken = await storage.read(key: 'accessToken');
//                 e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
//                 final response = await _tokenDio.fetch(e.requestOptions);
//                 return handler.resolve(response);
//               } catch (_) {
//                 // 재발급 작업이 실패한 경우, 현재 요청도 실패 처리합니다.
//                 return handler.reject(e);
//               }
//             }
//
//             // 2. 이 요청이 토큰 재발급을 시작하는 첫 번째 요청인 경우
//             _refreshCompleter = Completer<void>();
//
//             try {
//               final refreshToken = await storage.read(key: 'refreshToken');
//               if (refreshToken == null) throw Exception('No refresh token available');
//
//               print('--- 리프레시 재발급 시작 ---');
//               final requestDto = ReissueRequest(refreshToken: refreshToken);
//               final reissueResponse = await _tokenDio.post('/reissue', data: requestDto.toJson());
//               print('⬅️⬅️ [RES] ${reissueResponse.statusCode} | ${reissueResponse.requestOptions.method} ${reissueResponse.requestOptions.uri}');
//
//               final newAccessToken = reissueResponse.headers.value('Authorization')?.replaceFirst('Bearer ', '');
//               final newRefreshToken = ReissueResponse.fromJson(reissueResponse.data).newRefreshToken;
//
//               if (newAccessToken != null && newRefreshToken.isNotEmpty) {
//                 await storage.write(key: 'accessToken', value: newAccessToken);
//                 await storage.write(key: 'refreshToken', value: newRefreshToken);
//
//                 // 재발급 성공을 다른 대기 중인 요청들에게 알립니다.
//                 _refreshCompleter!.complete();
//                 _refreshCompleter = null;
//
//                 // 원래 실패했던 현재 요청을 새 토큰으로 재시도합니다.
//                 print('--- 새로운 토큰으로 재요청 시작 ---');
//
//                 e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
//                 final response = await _tokenDio.fetch(e.requestOptions);
//                 print('⬅️⬅️ [RES] ${response.statusCode} | ${response.requestOptions.method} ${response.requestOptions.uri}');
//                 return handler.resolve(response);
//               }
//
//               throw Exception('Failed to receive new tokens');
//
//             } catch (err) {
//               // 재발급 실패를 다른 대기 중인 요청들에게 알립니다.
//               _refreshCompleter!.completeError(err);
//               _refreshCompleter = null;
//
//               await _handleForceLogout();
//               return handler.reject(DioException(requestOptions: e.requestOptions, error: TokenExpiredException('Token refresh failed: $err')));
//             }
//           }
//           return handler.next(e);
//         },
//       ),
//     );
//   }
//
//   Future<void> _handleForceLogout() async {
//     if (_isForceLogout) return;
//     _isForceLogout = true;
//
//     try {
//       final authNotifier = _container.read(authStateProvider.notifier);
//       showChemiQToast("세션이 만료되었습니다.\n다시 로그인 해주세요!", type: ToastType.error);
//       if (authNotifier.mounted) await authNotifier.logout();
//       await Future.delayed(const Duration(milliseconds: 100));
//     } catch (e) {
//       print('로그아웃 처리 중 에러: $e');
//     } finally {
//       _isForceLogout = false;
//     }
//   }
//
//   // Future<void> _handleForceLogout() async {
//   //   if (_isForceLogout) return;
//   //   _isForceLogout = true;
//   //
//   //   try {
//   //     // ★★★★★ 2. 직접 로그아웃을 호출하는 대신, 안내창을 띄우는 함수를 호출 ★★★★★
//   //     _showSessionExpiredDialog(_container);
//   //
//   //   } catch (e) {
//   //     print('세션 만료 대화상자 표시 중 에러: $e');
//   //   } finally {
//   //     // 플래그는 바로 해제하여, 다른 요청이 불필요하게 차단되는 것을 방지합니다.
//   //     // 실제 로그아웃 시점은 사용자가 '확인'을 눌렀을 때입니다.
//   //     _isForceLogout = false;
//   //   }
//   // }
//
// }
//
// class TokenExpiredException implements Exception {
//   final String message;
//   TokenExpiredException(this.message);
//   @override
//   String toString() => 'TokenExpiredException: $message';
// }
//
// void _showSessionExpiredDialog(ProviderContainer container) {
//   // GlobalKey를 통해 현재 활성화된 context를 가져옵니다.
//   final context = navigatorKey.currentContext;
//   if (context == null) return;
//
//   showDialog(
//     context: context,
//     // 사용자가 대화상자 바깥을 탭해도 닫히지 않도록 설정
//     barrierDismissible: false,
//     builder: (BuildContext dialogContext) {
//       return AlertDialog(
//         title: const Text('로그인 만료'),
//         content: const Text('보안을 위해 로그인이 만료되었습니다.\n다시 로그인해주세요.'),
//         actions: <Widget>[
//           TextButton(
//             child: const Text('확인'),
//             onPressed: () {
//               // 1. 대화상자를 닫습니다.
//               Navigator.of(dialogContext).pop();
//               // 2. ProviderContainer를 사용해 AuthStateNotifier의 logout을 호출합니다.
//               container.read(authStateProvider.notifier).logout();
//             },
//           ),
//         ],
//       );
//     },
//   );
// }
//
//
//
import 'dart:async';
import 'package:chemiq/core/di/service_locator.dart';
import 'package:chemiq/core/ui/chemiq_toast.dart';
import 'package:chemiq/data/models/reissue_request.dart';
import 'package:chemiq/data/models/reissue_response.dart';
import 'package:chemiq/features/auth/provider/auth_state_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chemiq/main.dart';

import '../utils/logger.dart';

class DioClient {
  final Dio dio;
  late final Dio _tokenDio;
  final FlutterSecureStorage storage;
  final ProviderContainer _container;

  bool _isForceLogout = false;

  // 강화된 동시성 제어
  Future<String?>? _refreshTokenFuture;
  final List<Completer<String?>> _waitingCompleters = [];

  DioClient({
    required this.dio,
    required this.storage,
    required ProviderContainer container,
  }) : _container = container {
    dio.options = BaseOptions(
      baseUrl: dotenv.env['SERVER_URL'] ?? 'http://localhost:8080',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    );

    _tokenDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          logInfo('➡️ [REQ] ${options.method} ${options.uri}');

          if (_isForceLogout) {
            return handler.reject(
              DioException(
                requestOptions: options,
                message: '로그아웃이 진행 중이라 요청을 취소합니다.',
              ),
            );
          }

          final connectivityResult = await Connectivity().checkConnectivity();
          if (connectivityResult == ConnectivityResult.none) {
            return handler.reject(
              DioException(
                requestOptions: options,
                message: '인터넷 연결을 확인해주세요.',
              ),
            );
          }

          if (!options.path.contains('/login') &&
              !options.path.contains('/signup') &&
              !options.path.contains('/reissue')) {
            final accessToken = await storage.read(key: 'accessToken');
            if (accessToken != null) {
              options.headers['Authorization'] = 'Bearer $accessToken';
            }
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          logInfo('⬅️ [RES] ${response.statusCode} | ${response.requestOptions.method} ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          logError('💀 [ERR] ${e.response?.statusCode} | ${e.requestOptions.method} ${e.requestOptions.uri}');

          if (e.response?.statusCode == 401) {
            if (e.requestOptions.path.contains('/reissue') ||
                e.requestOptions.extra['isLogoutRequest'] == true) {
              return handler.next(e);
            }

            try {
              final newAccessToken = await _getValidAccessTokenSynchronized();

              if (newAccessToken != null) {
                logDebug('--- 새로운 토큰으로 재요청: ${e.requestOptions.path} ---');
                e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                final response = await _tokenDio.fetch(e.requestOptions);
                return handler.resolve(response);
              } else {
                throw Exception('토큰 재발급 실패');
              }
            } catch (refreshError) {
              logError('--- 토큰 재발급 최종 실패: $refreshError ---');
              await _handleForceLogout();
              return handler.reject(
                DioException(
                  requestOptions: e.requestOptions,
                  error: TokenExpiredException('Token refresh failed: $refreshError'),
                ),
              );
            }
          }

          return handler.next(e);
        },
      ),
    );
  }

  // 동기화된 토큰 재발급
  Future<String?> _getValidAccessTokenSynchronized() async {
    if (_refreshTokenFuture != null) {
      logDebug('--- 진행 중인 토큰 재발급을 대기합니다 (대기자 수: ${_waitingCompleters.length}) ---');
      final completer = Completer<String?>();
      _waitingCompleters.add(completer);
      return await completer.future;
    }

    logDebug('--- 토큰 재발급을 시작합니다 ---');
    _refreshTokenFuture = _performTokenRefreshInternal();

    String? result;
    try {
      result = await _refreshTokenFuture!;

      logDebug('--- 대기 중인 ${_waitingCompleters.length}개 요청에 결과 전달 ---');
      for (final completer in _waitingCompleters) {
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      }

      return result;
    } catch (error) {
      for (final completer in _waitingCompleters) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      }
      rethrow;
    } finally {
      _waitingCompleters.clear();
      _refreshTokenFuture = null;
      logDebug('--- 토큰 재발급 완료, 상태 초기화 ---');
    }
  }

  // 실제 토큰 재발급
  Future<String?> _performTokenRefreshInternal() async {
    try {
      final refreshToken = await storage.read(key: 'refreshToken');
      if (refreshToken == null) throw Exception('No refresh token available');

      logDebug('--- 서버에 토큰 재발급 요청 ---');
      final requestDto = ReissueRequest(refreshToken: refreshToken);

      final reissueResponse = await _tokenDio.post(
        '/reissue',
        data: requestDto.toJson(),
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final newAccessToken =
      reissueResponse.headers.value('Authorization')?.replaceFirst('Bearer ', '');
      final newRefreshToken = ReissueResponse.fromJson(reissueResponse.data).newRefreshToken;

      if (newAccessToken != null && newRefreshToken.isNotEmpty) {
        await Future.wait([
          storage.write(key: 'accessToken', value: newAccessToken),
          storage.write(key: 'refreshToken', value: newRefreshToken),
        ]);

        logInfo('--- 토큰 재발급 성공 ---');
        return newAccessToken;
      }

      throw Exception('Invalid tokens received from server');
    } catch (error) {
      logError('--- 토큰 재발급 실패: $error ---');
      return null;
    }
  }

  Future<void> _handleForceLogout() async {
    if (_isForceLogout) return;
    _isForceLogout = true;

    try {
      showChemiQToast("세션이 만료되었습니다.\n다시 로그인 해주세요!", type: ToastType.error);
      final authNotifier = _container.read(authStateProvider.notifier);
      if (authNotifier.mounted) await authNotifier.logout();
    } catch (e) {
      logError('로그아웃 처리 중 에러: $e');
    } finally {
      _isForceLogout = false;
    }
  }
}

class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException(this.message);
  @override
  String toString() => 'TokenExpiredException: $message';
}
