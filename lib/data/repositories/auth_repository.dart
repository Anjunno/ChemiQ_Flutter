// import 'package:dio/dio.dart';
// import 'package:chemiq/core/di/service_locator.dart';
// import 'package:chemiq/core/dio/dio_client.dart';
// import 'package:chemiq/data/models/login_response.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// import '../models/member_signup_request.dart';
// import '../models/logout_request.dart';
//
// class AuthRepository {
//   final DioClient _dioClient;
//
//   AuthRepository({required DioClient dioClient}) : _dioClient = dioClient;
//
//   /// ✨ 가볍고 빠른 토큰 유효성 검증 API
//   Future<void> validateToken() async {
//     // ✨ 데이터를 조회만 하므로 POST 대신 GET 사용
//     await _dioClient.dio.get('/test');
//   }
//
//   /// 로그인 API 호출
//   Future<void> login({
//     required String memberId,
//     required String password,
//   }) async {
//     try {
//       final formData = FormData.fromMap({
//         'memberId': memberId,
//         'password': password,
//       });
//       final response = await _dioClient.dio.post('/login', data: formData);
//
//       if (response.statusCode == 200) {
//         final accessToken = response.headers.value('Authorization')?.replaceFirst('Bearer ', '');
//         final loginResponse = LoginResponse.fromJson(response.data);
//         final refreshToken = loginResponse.refreshToken;
//
//         if (accessToken != null && refreshToken.isNotEmpty) {
//           await _dioClient.storage.write(key: 'accessToken', value: accessToken);
//           await _dioClient.storage.write(key: 'refreshToken', value: refreshToken);
//         } else {
//           throw Exception('API 응답에 토큰이 포함되어 있지 않습니다.');
//         }
//       }
//     } on DioException catch (e) {
//       print('로그인 실패: ${e.response?.data}');
//       rethrow;
//     } catch (e) {
//       print('알 수 없는 에러 발생: $e');
//       rethrow;
//     }
//   }
//
//   /// 로그아웃 API 호출 메서드
//   Future<void> logout() async {
//     print("[AuthRepository] 로그아웃 메서드 시작.");
//     try {
//       final refreshToken = await _dioClient.storage.read(key: 'refreshToken');
//       print("[AuthRepository] 리프레시 토큰 읽기 성공");
//       if (refreshToken == null) {
//         print("[AuthRepository] 리프레시 토큰 없음");
//         return;
//       }
//       final requestDto = LogoutRequest(refreshToken: refreshToken);
//       print("[AuthRepository] Dto 생성 완료 : " + requestDto.refreshToken);
//       await _dioClient.dio.post('/logout', data: requestDto.toJson());
//       print('서버 DB의 Refresh Token 무효화 성공');
//     } catch (e) {
//       print('서버 로그아웃 요청 실패: $e');
//     }
//   }
//
//   // ✨ validateToken과 기능이 중복되므로 test() 함수는 제거했습니다.
//
//   /// 회원가입 API 호출
//   Future<void> signUp({
//     required String memberId,
//     required String password,
//     required String nickname,
//   }) async {
//     try {
//       final requestDto = MemberSignUpRequest(
//         memberId: memberId,
//         password: password,
//         nickname: nickname,
//       );
//       await _dioClient.dio.post('/signup', data: requestDto.toJson());
//       print('회원가입 성공');
//     } on DioException catch (e) {
//       if (e.response?.statusCode == 409) {
//         throw '이미 사용 중인 아이디입니다.';
//       }
//       throw '회원가입에 실패했습니다. 잠시 후 다시 시도해주세요.';
//     } catch (e) {
//       print('알 수 없는 에러 발생: $e');
//       rethrow;
//     }
//   }
// }
//
// final authRepositoryProvider = Provider<AuthRepository>((ref) {
//   return serviceLocator<AuthRepository>();
// });
//


import 'package:dio/dio.dart';
import 'package:chemiq/core/di/service_locator.dart';
import 'package:chemiq/core/dio/dio_client.dart';
import 'package:chemiq/data/models/login_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


import '../models/member_signup_request.dart';
import '../models/logout_request.dart';

class AuthRepository {
  final DioClient _dioClient;

  AuthRepository({required DioClient dioClient}) : _dioClient = dioClient;

  /// ✨ 가볍고 빠른 토큰 유효성 검증 API
  Future<void> validateToken() async {
    // ✨ 데이터를 조회만 하므로 POST 대신 GET 사용
    await _dioClient.dio.get('/test');
  }

  /// 로그인 API 호출
  Future<void> login({
    required String memberId,
    required String password,
  }) async {
    try {
      final formData = FormData.fromMap({
        'memberId': memberId,
        'password': password,
      });
      final response = await _dioClient.dio.post('/login', data: formData);

      if (response.statusCode == 200) {
        final accessToken = response.headers.value('Authorization')?.replaceFirst('Bearer ', '');
        final loginResponse = LoginResponse.fromJson(response.data);
        final refreshToken = loginResponse.refreshToken;

        if (accessToken != null && refreshToken.isNotEmpty) {
          await _dioClient.storage.write(key: 'accessToken', value: accessToken);
          await _dioClient.storage.write(key: 'refreshToken', value: refreshToken);
        } else {
          throw Exception('API 응답에 토큰이 포함되어 있지 않습니다.');
        }
      }
    } on DioException catch (e) {
      print('로그인 실패: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('알 수 없는 에러 발생: $e');
      rethrow;
    }
  }

  /// 로그아웃 API 호출 메서드
  Future<void> logout() async {
    print("[AuthRepository] 로그아웃 메서드 시작.");
    final refreshToken = await _dioClient.storage.read(key: 'refreshToken');
    print("[AuthRepository] 리프레시 토큰 읽기 성공");

    if (refreshToken != null) {
      try {
        final requestDto = LogoutRequest(refreshToken: refreshToken);
        print("[AuthRepository] Dto 생성 완료 : " + requestDto.refreshToken);
        await _dioClient.dio.post(
          '/logout',
          data: requestDto.toJson(),
          // 이 요청은 401 에러가 발생해도 인터셉터의 재발급/강제로그아웃 로직을 타지 않도록 설정합니다.
          options: Options(
            extra: {'isLogoutRequest': true},
          ),
        );
        print('서버 DB의 Refresh Token 무효화 성공');
      } on DioException catch (e) {
        // 로그아웃 요청은 실패해도 괜찮습니다.
        // 어차피 로컬 토큰은 삭제될 것이기 때문입니다.
        print('서버 로그아웃 요청 실패 (무시함): $e');
      }
    } else {
      print("[AuthRepository] 리프레시 토큰 없음");
    }
  }


  // ✨ validateToken과 기능이 중복되므로 test() 함수는 제거했습니다.

  /// 회원가입 API 호출
  Future<void> signUp({
    required String memberId,
    required String password,
    required String nickname,
  }) async {
    try {
      final requestDto = MemberSignUpRequest(
        memberId: memberId,
        password: password,
        nickname: nickname,
      );
      await _dioClient.dio.post('/signup', data: requestDto.toJson());
      print('회원가입 성공');
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw '이미 사용 중인 아이디입니다.';
      }
      throw '회원가입에 실패했습니다. 잠시 후 다시 시도해주세요.';
    } catch (e) {
      print('알 수 없는 에러 발생: $e');
      rethrow;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return serviceLocator<AuthRepository>();
});

