// import 'package:dio/dio.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:chemiq/core/api_exception.dart';
//
// /**
//  * ApiClient 클래스
//  * * 앱의 모든 API 통신을 중앙에서 관리하는 클래스입니다.
//  * Singleton 패턴과 의존성 주입(DI)을 통해 앱 전체에서 단 하나의 인스턴스만 사용하도록 설계되었습니다.
//  * Dio의 Interceptor를 사용하여 JWT 토큰 관리(자동 추가, 갱신, 재요청)를 자동화합니다.
//  */
// class ApiClient {
//   // FlutterSecureStorage 인스턴스를 외부에서 주입받아 사용합니다. (의존성 주입)
//   // 이를 통해 토큰을 안전하게 저장하고 불러올 수 있습니다.
//   final FlutterSecureStorage storage;
//
//   // Dio 인스턴스는 클래스 내부에서 생성 및 관리됩니다.
//   late final Dio dio;
//
//   // 생성자: ApiClient가 생성될 때 Dio 인스턴스를 초기화합니다.
//   ApiClient(this.storage) {
//     dio = _createDio();
//   }
//
//   // Dio 인스턴스를 생성하고 초기 설정을 구성하는 내부 메서드
//   Dio _createDio() {
//     // Dio의 기본 설정을 정의합니다.
//     final dio = Dio(
//       BaseOptions(
//         // .env 파일에 정의된 API 기본 URL을 사용합니다.
//         baseUrl: dotenv.env['SERVER_URL'] ?? 'YOUR_DEFAULT_API_URL',
//         // 모든 요청에 기본적으로 포함될 헤더를 설정합니다.
//         headers: {'Content-Type': 'application/json'},
//       ),
//     );
//
//     dio.interceptors.add(QueuedInterceptorsWrapper(
//       onRequest: (options, handler) async {
//         // 토큰 인증이 필요 없는 API 경로들을 정의합니다.
//         final noAuthPaths = ['/login', '/signup', '/reissue'];
//
//         if (!noAuthPaths.contains(options.path)) {
//           final accessToken = await storage.read(key: 'ACCESS_TOKEN');
//           if (accessToken != null) {
//             options.headers['Authorization'] = 'Bearer $accessToken';
//           }
//         }
//         return handler.next(options);
//       },
//       onError: (e, handler) async {
//         if (e.response?.statusCode == 401) {
//           try {
//             final refreshToken = await storage.read(key: 'REFRESH_TOKEN');
//             if (refreshToken == null) {
//               await storage.deleteAll(); // 토큰이 없으니 저장소 정리
//               return handler.reject(
//                 DioException(
//                   requestOptions: e.requestOptions,
//                   error: SessionExpiredException(),
//                 ),
//               );
//             }
//
//             var refreshDio = Dio(BaseOptions(baseUrl: dotenv.env['SERVER_URL']!));
//             final response = await refreshDio.post("/reissue", data: {"refreshToken": refreshToken},);
//
//             // 1. 헤더에서 새로운 액세스 토큰 추출
//             final authHeader = response.headers.value('Authorization');
//             if (authHeader == null || !authHeader.startsWith('Bearer ')) {
//               // 헤더가 없거나 형식이 잘못된 경우 에러 처리
//               throw DioException(requestOptions: e.requestOptions, message: "Invalid new access token format");
//             }
//             // "Bearer " (7글자) 다음부터 순수 토큰만 추출
//             final newAccessToken = authHeader.substring(7);
//
//             // 2. 바디에서 새로운 리프레시 토큰 추출
//             final newRefreshToken = response.data['newRefreshToken'];
//
//             // 3. 새로운 토큰들을 저장소에 저장
//             await storage.write(key: 'ACCESS_TOKEN', value: newAccessToken);
//             // 새로운 리프레시 토큰이 존재할 경우에만 덮어쓰기
//             if (newRefreshToken != null) {
//               await storage.write(key: 'REFRESH_TOKEN', value: newRefreshToken);
//             }
//
//             // --- 2-3. 원래 요청 재시도 ---
//             e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
//             final clonedRequest = await dio.fetch(e.requestOptions);
//             return handler.resolve(clonedRequest);
//
//           } catch (refreshError) {
//             // --- 2-4. 토큰 갱신 실패 ---
//             await storage.deleteAll();
//             return handler.reject(
//               DioException(
//                 requestOptions: e.requestOptions,
//                 error: SessionExpiredException(),
//               ),
//             );
//           }
//         }
//         // 2. 401 이외의 모든 DioException을 우리가 만든 ApiException으로 변환합니다.
//         if (e is DioException) {
//           String errorMessage = '알 수 없는 오류가 발생했습니다.';
//           // 서버가 에러 메시지를 응답 본문에 담아 보냈다면, 그 메시지를 사용합니다.
//           if (e.response != null && e.response?.data is Map) {
//             errorMessage = e.response?.data['message'] ?? errorMessage;
//           }
//           // 정제된 ApiException을 던집니다.
//           return handler.reject(
//             DioException(
//               requestOptions: e.requestOptions,
//               error: ApiException(errorMessage, e.response?.statusCode),
//             ),
//           );
//         }
//
//         // 3. DioException이 아닌 다른 에러는 그대로 던집니다.
//         return handler.next(e);
//       },
//     ));
//
//     return dio;
//   }
// }