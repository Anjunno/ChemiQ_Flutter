import 'package:chemiq/data/models/reissue_request.dart';
import 'package:chemiq/data/models/reissue_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chemiq/core/di/service_locator.dart';
import 'package:chemiq/features/auth/provider/auth_state_provider.dart';


class DioClient {
  final Dio dio;
  final FlutterSecureStorage storage;

  DioClient({required this.dio, required this.storage}) {
    dio.options = BaseOptions(
      baseUrl: dotenv.env['SERVER_URL'] ?? 'http://localhost:8080', // .env 파일에서 서버 URL을 가져옵니다. 없으면 기본값 사용
      connectTimeout: const Duration(seconds: 5), // 서버 연결 시도 시간
      receiveTimeout: const Duration(seconds: 5),  // 서버 응답 대기 시간
    );

    // QueuedInterceptorsWrapper: 여러 요청이 동시에 401 에러를 받았을 때,
    // 토큰 재발급 요청을 한 번만 실행하고 나머지 요청들은 대기열에서 기다리게 하는 인터셉터입니다.
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        // --- 1. 요청을 보내기 전 ---
        onRequest: (options, handler) async {
          // 로그인, 회원가입, 토큰 재발급 API는 토큰이 필요 없으므로 제외합니다.
          if (!options.path.contains('/login') &&
              !options.path.contains('/signup') &&
              !options.path.contains('/reissue')) {
            // 저장된 Access Token을 가져와서
            final accessToken = await storage.read(key: 'accessToken');
            if (accessToken != null) {
              // 헤더에 'Authorization'으로 추가합니다.
              options.headers['Authorization'] = 'Bearer $accessToken';
            }
          }
          // 준비된 요청을 다음 단계로 보냅니다.
          return handler.next(options);
        },
        // --- 2. 성공적인 응답을 받았을 때 ---
        onResponse: (response, handler) {
          // 개발 중 디버깅을 위해 성공 로그를 출력합니다.
          print('[RES] [${response.requestOptions.method}] ${response.requestOptions.uri}');
          return handler.next(response);
        },
        // --- 3. 에러가 발생했을 때 ---
        onError: (DioException e, handler) async {
          print('[ERR] [${e.requestOptions.method}] ${e.requestOptions.uri}');

          // Access Token 만료로 인한 401 에러인지 확인합니다.
          if (e.response?.statusCode == 401) {
            // 만약 토큰 재발급 요청 자체에서 401 에러가 발생했다면,
            // 이는 Refresh Token도 만료되었다는 의미이므로 무한 루프를 방지하기 위해 즉시 종료합니다.
            if (e.requestOptions.path == '/reissue') {
              print('토큰 재발급 실패: Refresh Token 만료. 강제 로그아웃합니다.');
              await serviceLocator<AuthStateNotifier>().logout(); // AuthStateNotifier를 통해 로그아웃 처리
              return handler.next(e);
            }
            try {
              // 저장된 Refresh Token을 가져옵니다.
              final refreshToken = await storage.read(key: 'refreshToken');
              if (refreshToken == null) throw Exception("저장된 Refresh Token이 없습니다.");

              // 토큰 재발급 요청을 위한 새로운 Dio 인스턴스를 생성합니다.
              // (기존 dio 인스턴스의 인터셉터를 타지 않기 위함)
              final reissueDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
              final requestDto = ReissueRequest(refreshToken: refreshToken);

              // 토큰 재발급 API(/reissue)를 호출합니다.
              final reissueResponse = await reissueDio.post('/reissue', data: requestDto.toJson());

              // 응답에서 새로운 Access Token(헤더)과 Refresh Token(바디)을 추출합니다.
              final newAccessToken = reissueResponse.headers.value('Authorization')?.replaceFirst('Bearer ', '');
              final newRefreshToken = ReissueResponse.fromJson(reissueResponse.data).newRefreshToken;

              if (newAccessToken != null && newRefreshToken.isNotEmpty) {
                // 새로 발급받은 토큰들을 안전하게 저장합니다.
                await storage.write(key: 'accessToken', value: newAccessToken);
                await storage.write(key: 'refreshToken', value: newRefreshToken);
                print('토큰 재발급 및 저장 성공');

                // 원래 실패했던 요청 정보를 가져와서
                final originalRequest = e.requestOptions;
                // 헤더만 새로운 Access Token으로 교체한 뒤,
                originalRequest.headers['Authorization'] = 'Bearer $newAccessToken';

                // dio.fetch를 사용해 원래 요청을 그대로 다시 보냅니다.
                final response = await dio.fetch(originalRequest);
                // 재요청이 성공하면, 원래 요청이 성공한 것처럼 응답을 반환합니다.
                return handler.resolve(response);
              }
              // 응답에 토큰이 없는 예외적인 경우
              throw Exception("새로운 토큰을 받지 못했습니다.");

            } catch (err) {
              // 위 'try' 블록에서 어떤 종류의 에러든 발생하면, 최종적으로 로그아웃 처리합니다.
              print('토큰 재발급 과정에서 최종 에러 발생: $err. 강제 로그아웃합니다.');
              await serviceLocator<AuthStateNotifier>().logout();
              return handler.next(e); // 원래 발생했던 401 에러를 반환
            }
          }
          // 401 에러가 아니라면, 다른 종류의 에러이므로 그대로 다음 핸들러로 넘깁니다.
          return handler.next(e);
        },
      ),
    );
  }
}

