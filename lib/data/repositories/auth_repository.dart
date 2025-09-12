import 'package:dio/dio.dart';
import 'package:chemiq/core/di/service_locator.dart';
import 'package:chemiq/core/dio/dio_client.dart';
import 'package:chemiq/data/models/login_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/member_signup_request.dart';
import '../models/rogout_request.dart';

class AuthRepository {
  final DioClient _dioClient;

  // 생성자를 통해 DioClient를 주입받음
  AuthRepository({required DioClient dioClient}) : _dioClient = dioClient;

  /// 로그인 API 호출
  Future<void> login({
    required String memberId,
    required String password,
  }) async {
    try {
      // 1. API 명세서에 따라 form-data 형식으로 데이터 생성
      final formData = FormData.fromMap({
        'memberId': memberId,
        'password': password,
      });

      // 2. Dio를 사용하여 로그인 API 호출
      final response = await _dioClient.dio.post('/login', data: formData);

      // 3. 응답 성공 시 (status code 200)
      if (response.statusCode == 200) {
        // 3-1. 헤더에서 Access Token 추출 ('Bearer ' 부분 제거)
        final accessToken = response.headers.value('Authorization')?.replaceFirst('Bearer ', '');

        // 3-2. 바디를 LoginResponse 모델로 변환하여 Refresh Token 추출
        final loginResponse = LoginResponse.fromJson(response.data);
        final refreshToken = loginResponse.refreshToken;

        // 3-3. 두 토큰을 FlutterSecureStorage에 저장 (null 체크)
        if (accessToken != null && refreshToken.isNotEmpty) {
          await _dioClient.storage.write(key: 'accessToken', value: accessToken);
          await _dioClient.storage.write(key: 'refreshToken', value: refreshToken);
          print('로그인 성공 및 토큰 저장 완료');
        } else {
          // 토큰이 없는 예외적인 경우
          throw Exception('API 응답에 토큰이 포함되어 있지 않습니다.');
        }
      }
    } on DioException catch (e) {
      // Dio 에러 처리 (401 인증 실패, 500 서버 에러 등)
      print('로그인 실패: ${e.response?.data}');
      // UI 단에서 에러를 인지하고 사용자에게 피드백을 줄 수 있도록 에러를 다시 던집니다.
      rethrow;
    } catch (e) {
      // 그 외 알 수 없는 에러
      print('알 수 없는 에러 발생: $e');
      rethrow;
    }
  }

  /// 로그아웃 API 호출 메서드
  Future<void> logout() async {
    try {
      // 1. 기기에 저장된 Refresh Token을 읽어옵니다.
      final refreshToken = await _dioClient.storage.read(key: 'refreshToken');

      // 2. 토큰이 없으면 서버에 요청할 필요가 없으므로 함수를 즉시 종료합니다.
      if (refreshToken == null) {
        print('저장된 Refresh Token이 없어 서버에 로그아웃 요청을 보내지 않습니다.');
        return;
      }

      // 3. 서버에 보낼 요청 데이터를 만듭니다.
      final requestDto = LogoutRequest(refreshToken: refreshToken);

      // 4. '/logout' 경로로 POST 요청을 보냅니다.
      await _dioClient.dio.post('/logout', data: requestDto.toJson());
      print('서버 DB의 Refresh Token 무효화 성공');

    } catch (e) {
      // 5. 서버 로그아웃 요청에 실패하더라도, 클라이언트의 로그아웃 흐름은 계속되어야 합니다.
      // 따라서 에러를 다시 던지지(rethrow) 않고 콘솔에 로그만 남깁니다.
      print('서버 로그아웃 요청 실패: $e');
    }
  }


  Future<void> test() async {
    try {
      // 4. '/logout' 경로로 POST 요청을 보냅니다.
      await _dioClient.dio.get('/members/me/info');
      print('아직 요청가능');

    } catch (e) {
      // 5. 서버 로그아웃 요청에 실패하더라도, 클라이언트의 로그아웃 흐름은 계속되어야 합니다.
      // 따라서 에러를 다시 던지지(rethrow) 않고 콘솔에 로그만 남깁니다.
      print('이게 무슨 문제?: $e');
    }
  }

  /// (✨ 추가된 부분) 회원가입 API 호출
  Future<void> signUp({
    required String memberId,
    required String password,
    required String nickname,
  }) async {
    try {
      // 1. API 명세에 맞춰 요청 DTO를 생성합니다.
      final requestDto = MemberSignUpRequest(
        memberId: memberId,
        password: password,
        nickname: nickname,
      );

      // 2. '/signup' 경로로 POST 요청을 보냅니다.
      //    이번에는 JSON 형식으로 데이터를 보냅니다 (toJson() 호출).
      await _dioClient.dio.post('/signup', data: requestDto.toJson());
      print('회원가입 성공');

    } on DioException catch (e) {
      // Dio 에러 처리
      if (e.response?.statusCode == 409) {
        // 409 Conflict 에러는 아이디 중복을 의미합니다.
        throw Exception('이미 사용 중인 아이디입니다.');
      }
      // 그 외 다른 에러
      throw Exception('회원가입에 실패했습니다: ${e.message}');
    } catch (e) {
      // 알 수 없는 에러
      print('알 수 없는 에러 발생: $e');
      rethrow;
    }
  }
// TODO: 여기에 나중에 회원가입, 로그아웃 등의 API 호출 메서드를 추가합니다.
}

// AuthRepository를 Riverpod에게 제공하는 Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return serviceLocator<AuthRepository>();
});
