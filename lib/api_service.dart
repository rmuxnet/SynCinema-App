import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

class ApiService {
  static String baseUrl = '';
  static String? currentUser;
  static final Dio _dio = Dio();
  static final CookieJar _cookieJar = CookieJar();

  static void init() {
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  static void setBaseUrl(String ip) {
    if (!ip.startsWith('http')) ip = 'http://$ip';
    if (ip.endsWith('/')) ip = ip.substring(0, ip.length - 1);
    
    baseUrl = ip;
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      contentType: 'application/json',
      connectTimeout: const Duration(seconds: 5),
    );
  }

  static Future<String> getCookieHeader() async {
    List<Cookie> cookies = await _cookieJar.loadForRequest(Uri.parse(baseUrl));
    return cookies.map((c) => '${c.name}=${c.value}').join('; ');
  }

  static Future<bool> login(String username, String password) async {
    if (baseUrl.isEmpty) return false;
    try {
      final response = await _dio.post('/api/login', data: {
        'username': username,
        'password': password,
      });
      if (response.data['status'] == 'success') {
        currentUser = username;
        return true;
      }
      return false;
    } catch (e) {
      print('Login Error: $e');
      return false;
    }
  }

  static Future<List<String>> getMovies() async {
    try {
      final response = await _dio.get('/api/movies');
      return List<String>.from(response.data['movies']);
    } catch (e) {
      return [];
    }
  }

  static String getMovieUrl(String filename) {
    return '$baseUrl/movies/${Uri.encodeComponent(filename)}';
  }
}