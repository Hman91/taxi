import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/chat_message.dart';
import 'models.dart';

class TaxiApiException implements Exception {
  TaxiApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  @override
  String toString() => 'TaxiApiException: $message (${statusCode ?? "-"})';
}

/// `login-app` returned 403 with `account_disabled`.
class TaxiAccountDisabledException implements Exception {
  @override
  String toString() => 'TaxiAccountDisabledException';
}

class TaxiApiClient {
  TaxiApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  Uri _u(String path) => Uri.parse(apiBaseUrl).resolve(path);

  String? _errorCodeFromBody(String body) {
    try {
      final m = jsonDecode(body);
      if (m is Map<String, dynamic> && m['error'] is String) {
        return m['error'] as String;
      }
    } catch (_) {}
    return null;
  }

  Map<String, String> _jsonHeaders({String? bearer}) {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (bearer != null && bearer.isNotEmpty) {
      h['Authorization'] = 'Bearer $bearer';
    }
    return h;
  }

  Future<void> health() async {
    final r = await _http.get(_u('/api/health'));
    if (r.statusCode != 200) {
      throw TaxiApiException(r.body, r.statusCode);
    }
  }

  Future<Map<String, double>> getAirportFares() async {
    final r = await _http.get(_u('/api/fares/airport'));
    if (r.statusCode != 200) {
      throw TaxiApiException(r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final fares = body['fares'] as Map<String, dynamic>;
    return fares.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  Future<Map<String, dynamic>> quoteAirport(String routeKey) async {
    final r = await _http.post(
      _u('/api/fares/quote'),
      headers: _jsonHeaders(),
      body: jsonEncode({'mode': 'airport', 'route_key': routeKey}),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(r.body, r.statusCode);
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> quoteGps({double? distanceKm}) async {
    final body = <String, dynamic>{'mode': 'gps'};
    if (distanceKm != null) {
      body['distance_km'] = distanceKm;
    }
    final r = await _http.post(
      _u('/api/fares/quote'),
      headers: _jsonHeaders(),
      body: jsonEncode(body),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(r.body, r.statusCode);
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<LoginResponse> login({required String role, required String secret}) async {
    final r = await _http.post(
      _u('/api/auth/login'),
      headers: _jsonHeaders(),
      body: jsonEncode({'role': role, 'secret': secret}),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(r.body, r.statusCode);
    }
    return LoginResponse.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<DriverPinLoginResponse> loginDriverPin({
    required String phone,
    required String pin,
  }) async {
    final r = await _http.post(
      _u('/api/auth/login-driver-pin'),
      headers: _jsonHeaders(),
      body: jsonEncode({'phone': phone, 'pin': pin}),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(_errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    return DriverPinLoginResponse.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<Trip> createTrip({
    required String token,
    required String route,
    required double fare,
    String type = 'كاش / بطاقة',
  }) async {
    final r = await _http.post(
      _u('/api/trips'),
      headers: _jsonHeaders(bearer: token),
      body: jsonEncode({'route': route, 'fare': fare, 'type': type}),
    );
    if (r.statusCode != 201) {
      throw TaxiApiException(r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return Trip.fromJson(body['trip'] as Map<String, dynamic>);
  }

  Future<List<Trip>> listTrips(String token) async {
    final r = await _http.get(_u('/api/trips'), headers: _jsonHeaders(bearer: token));
    if (r.statusCode != 200) {
      throw TaxiApiException(r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final list = body['trips'] as List<dynamic>;
    return list.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> ownerMetrics(String token) async {
    final r = await _http.get(
      _u('/api/metrics/owner'),
      headers: _jsonHeaders(bearer: token),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(r.body, r.statusCode);
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitRating(int stars) async {
    final r = await _http.post(
      _u('/api/ratings'),
      headers: _jsonHeaders(),
      body: jsonEncode({'stars': stars}),
    );
    if (r.statusCode != 201) {
      throw TaxiApiException(r.body, r.statusCode);
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> registerAppUser({
    required String email,
    required String password,
    required String role,
  }) async {
    final r = await _http.post(
      _u('/api/auth/register'),
      headers: _jsonHeaders(),
      body: jsonEncode({'email': email, 'password': password, 'role': role}),
    );
    if (r.statusCode != 201) {
      throw TaxiApiException(r.body, r.statusCode);
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<AppLoginResponse> loginApp({
    required String email,
    required String password,
  }) async {
    final r = await _http.post(
      _u('/api/auth/login-app'),
      headers: _jsonHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (r.statusCode != 200) {
      final code = _errorCodeFromBody(r.body);
      if (r.statusCode == 403 && code == 'account_disabled') {
        throw TaxiAccountDisabledException();
      }
      throw TaxiApiException(code ?? r.body, r.statusCode);
    }
    return AppLoginResponse.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<RideConversationInfo?> getRideConversation({
    required String token,
    required int rideId,
  }) async {
    final r = await _http.get(
      _u('/api/rides/$rideId/conversation'),
      headers: _jsonHeaders(bearer: token),
    );
    if (r.statusCode == 200) {
      return RideConversationInfo.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    }
    if (r.statusCode == 400) {
      final code = _errorCodeFromBody(r.body);
      if (code == 'chat_not_open') return null;
    }
    throw TaxiApiException(_errorCodeFromBody(r.body) ?? r.body, r.statusCode);
  }

  Future<List<ChatMessage>> listConversationMessages({
    required String token,
    required int conversationId,
    int? beforeId,
    int limit = 50,
  }) async {
    final q = <String, String>{'limit': '$limit'};
    if (beforeId != null) q['before_id'] = '$beforeId';
    final uri = _u('/api/conversations/$conversationId/messages').replace(queryParameters: q);
    final r = await _http.get(uri, headers: _jsonHeaders(bearer: token));
    if (r.statusCode != 200) {
      throw TaxiApiException(_errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final list = body['messages'] as List<dynamic>;
    return list.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> patchPreferredLanguage({
    required String token,
    required String preferredLanguage,
  }) async {
    final r = await _http.patch(
      _u('/api/me'),
      headers: _jsonHeaders(bearer: token),
      body: jsonEncode({'preferred_language': preferredLanguage}),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(_errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
  }

  Future<List<Map<String, dynamic>>> listAdminRides(
    String token, {
    int limit = 200,
  }) async {
    final uri = _u('/api/admin/rides').replace(queryParameters: {'limit': '$limit'});
    final r = await _http.get(uri, headers: _jsonHeaders(bearer: token));
    if (r.statusCode != 200) {
      throw TaxiApiException(_errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final list = body['rides'] as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> listAdminDriverLocations(String token) async {
    final r = await _http.get(
      _u('/api/admin/drivers/locations'),
      headers: _jsonHeaders(bearer: token),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(_errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final list = body['drivers'] as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> adminOwnerMetrics(String token) async {
    final r = await _http.get(
      _u('/api/admin/metrics'),
      headers: _jsonHeaders(bearer: token),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(_errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<List<Ride>> listRides(String token) async {
    final r = await _http.get(_u('/api/rides'), headers: _jsonHeaders(bearer: token));
    if (r.statusCode != 200) {
      throw TaxiApiException(r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final list = body['rides'] as List<dynamic>;
    return list.map((e) => Ride.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Ride> createRide({
    required String token,
    required String pickup,
    required String destination,
  }) async {
    final r = await _http.post(
      _u('/api/rides'),
      headers: _jsonHeaders(bearer: token),
      body: jsonEncode({'pickup': pickup, 'destination': destination}),
    );
    if (r.statusCode != 201) {
      throw TaxiApiException(r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return Ride.fromJson(body['ride'] as Map<String, dynamic>);
  }

  Future<Ride> acceptRide({required String token, required int rideId}) async {
    final r = await _http.post(
      _u('/api/rides/$rideId/accept'),
      headers: _jsonHeaders(bearer: token),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return Ride.fromJson(body['ride'] as Map<String, dynamic>);
  }

  Future<Ride> rejectRide({required String token, required int rideId}) async {
    final r = await _http.post(
      _u('/api/rides/$rideId/reject'),
      headers: _jsonHeaders(bearer: token),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return Ride.fromJson(body['ride'] as Map<String, dynamic>);
  }

  Future<Ride> startRide({required String token, required int rideId}) async {
    final r = await _http.post(
      _u('/api/rides/$rideId/start'),
      headers: _jsonHeaders(bearer: token),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return Ride.fromJson(body['ride'] as Map<String, dynamic>);
  }

  Future<Ride> completeRide({required String token, required int rideId}) async {
    final r = await _http.post(
      _u('/api/rides/$rideId/complete'),
      headers: _jsonHeaders(bearer: token),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return Ride.fromJson(body['ride'] as Map<String, dynamic>);
  }

  Future<Ride> cancelRide({required String token, required int rideId}) async {
    final r = await _http.post(
      _u('/api/rides/$rideId/cancel'),
      headers: _jsonHeaders(bearer: token),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return Ride.fromJson(body['ride'] as Map<String, dynamic>);
  }
}
