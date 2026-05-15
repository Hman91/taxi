import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/chat_message.dart';
import 'auth_refreshing_client.dart';
import 'auth_token_store.dart';
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

/// `login-app`/`login-google` returned 403 with `account_pending`.
class TaxiAccountPendingException implements Exception {
  @override
  String toString() => 'TaxiAccountPendingException';
}

class TaxiApiClient {
  TaxiApiClient({http.Client? httpClient})
      : _http = httpClient ?? AuthRefreshingClient();

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

  Map<String, String> _jsonHeaders({String? bearer, bool b2bRoleOnly = false}) {
    final h = <String, String>{'Content-Type': 'application/json'};
    final token = AuthTokenStore.instance.resolveBearer(
      bearer,
      b2bRoleOnly: b2bRoleOnly,
    );
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
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

  Future<Map<String, dynamic>> quoteAirport(String routeKey,
      {DateTime? pricingTime}) async {
    final body = <String, dynamic>{
      'mode': 'airport',
      'route_key': routeKey,
    };
    if (pricingTime != null) {
      body['pricing_time'] = pricingTime.toUtc().toIso8601String();
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

  Future<Map<String, dynamic>> quoteGps(
      {double? distanceKm, DateTime? pricingTime}) async {
    final body = <String, dynamic>{'mode': 'gps'};
    if (distanceKm != null) {
      body['distance_km'] = distanceKm;
    }
    if (pricingTime != null) {
      body['pricing_time'] = pricingTime.toUtc().toIso8601String();
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

  Future<LoginResponse> login(
      {required String role, required String secret}) async {
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
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = DriverPinLoginResponse.fromJson(
        jsonDecode(r.body) as Map<String, dynamic>);
    AuthTokenStore.instance.applyFromDriverPin(body);
    return body;
  }

  Future<Trip> createTrip({
    required String token,
    required String route,
    required double fare,
    String? driverPhone,
    String type = 'كاش / بطاقة',
  }) async {
    final r = await _http.post(
      _u('/api/trips'),
      headers: _jsonHeaders(bearer: token),
      body: jsonEncode({
        'route': route,
        'fare': fare,
        'type': type,
        if (driverPhone != null && driverPhone.isNotEmpty)
          'driver_phone': driverPhone,
      }),
    );
    if (r.statusCode != 201) {
      throw TaxiApiException(r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return Trip.fromJson(body['trip'] as Map<String, dynamic>);
  }

  Future<List<Trip>> listTrips(String token) async {
    final r =
        await _http.get(_u('/api/trips'), headers: _jsonHeaders(bearer: token));
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

  Future<Map<String, dynamic>> submitRating({
    required String token,
    required int rideId,
    required int stars,
  }) async {
    final r = await _http.post(
      _u('/api/ratings'),
      headers: _jsonHeaders(bearer: token),
      body: jsonEncode({'ride_id': rideId, 'stars': stars}),
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
    String? displayName,
    String? phone,
    String? photoUrl,
    String? carModel,
    String? carColor,
  }) async {
    final r = await _http.post(
      _u('/api/auth/register'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'email': email,
        'password': password,
        'role': role,
        if ((displayName ?? '').trim().isNotEmpty) 'display_name': displayName!.trim(),
        if ((phone ?? '').trim().isNotEmpty) 'phone': phone!.trim(),
        if ((photoUrl ?? '').trim().isNotEmpty) 'photo_url': photoUrl!.trim(),
        if ((carModel ?? '').trim().isNotEmpty) 'car_model': carModel!.trim(),
        if ((carColor ?? '').trim().isNotEmpty) 'car_color': carColor!.trim(),
      }),
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
      if (r.statusCode == 403 && code == 'account_pending') {
        throw TaxiAccountPendingException();
      }
      throw TaxiApiException(code ?? r.body, r.statusCode);
    }
    final body = AppLoginResponse.fromJson(
        jsonDecode(r.body) as Map<String, dynamic>);
    return body;
  }

  Future<bool> requestPasswordReset({
    required String email,
  }) async {
    final r = await _http.post(
      _u('/api/auth/forgot-password-request'),
      headers: _jsonHeaders(),
      body: jsonEncode({'email': email}),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(_errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return (body['email_sent'] as bool?) ?? false;
  }

  Future<void> confirmPasswordReset({
    required String email,
    required String resetCode,
    required String newPassword,
  }) async {
    final r = await _http.post(
      _u('/api/auth/forgot-password-confirm'),
      headers: _jsonHeaders(),
      body: jsonEncode(
        {
          'email': email,
          'reset_code': resetCode,
          'new_password': newPassword,
        },
      ),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(_errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
  }

  Future<AppLoginResponse> loginGoogle({
    String? idToken,
    String? accessToken,
    String? role,
    String? phone,
  }) async {
    final tokenId = (idToken ?? '').trim();
    final tokenAccess = (accessToken ?? '').trim();
    if (tokenId.isEmpty && tokenAccess.isEmpty) {
      throw TaxiApiException('missing_google_token', 400);
    }
    final r = await _http.post(
      _u('/api/auth/login-google'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        if (tokenId.isNotEmpty) 'id_token': tokenId,
        if (tokenAccess.isNotEmpty) 'access_token': tokenAccess,
        if ((role ?? '').trim().isNotEmpty) 'role': role!.trim(),
        if ((phone ?? '').trim().isNotEmpty) 'phone': phone!.trim(),
      }),
    );
    if (r.statusCode != 200) {
      final code = _errorCodeFromBody(r.body);
      if (r.statusCode == 403 && code == 'account_disabled') {
        throw TaxiAccountDisabledException();
      }
      if (r.statusCode == 403 && code == 'account_pending') {
        throw TaxiAccountPendingException();
      }
      throw TaxiApiException(code ?? r.body, r.statusCode);
    }
    return AppLoginResponse.fromJson(
      jsonDecode(r.body) as Map<String, dynamic>,
    );
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
      return RideConversationInfo.fromJson(
          jsonDecode(r.body) as Map<String, dynamic>);
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
    final uri = _u('/api/conversations/$conversationId/messages')
        .replace(queryParameters: q);
    final r = await _http.get(uri, headers: _jsonHeaders(bearer: token));
    if (r.statusCode != 200) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final list = body['messages'] as List<dynamic>;
    return list
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessage> sendConversationMessage({
    required String token,
    required int conversationId,
    required String text,
  }) async {
    final r = await _http.post(
      _u('/api/conversations/$conversationId/messages'),
      headers: _jsonHeaders(bearer: token),
      body: jsonEncode({'text': text}),
    );
    if (r.statusCode != 201) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return ChatMessage.fromJson(body['message'] as Map<String, dynamic>);
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
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
  }

  Future<Map<String, dynamic>> patchMyAccount({
    required String token,
    required String currentPassword,
    String? email,
    String? password,
  }) async {
    final r = await _http.patch(
      _u('/api/me/account'),
      headers: _jsonHeaders(bearer: token),
      body: jsonEncode({
        'current_password': currentPassword,
        if ((email ?? '').trim().isNotEmpty) 'email': email!.trim(),
        if ((password ?? '').trim().isNotEmpty) 'password': password,
      }),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(_errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(body['user'] as Map);
  }

  Future<List<Map<String, dynamic>>> listAdminFareRoutes(String token) async {
    final r = await _http.get(
      _u('/api/admin/fare-routes'),
      headers: _jsonHeaders(bearer: token),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final list = body['routes'] as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> patchAdminFareRoute({
    required String token,
    required int routeId,
    required double baseFare,
  }) async {
    final r = await _http.patch(
      _u('/api/admin/fare-routes/$routeId'),
      headers: _jsonHeaders(bearer: token),
      body: jsonEncode({'base_fare': baseFare}),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(body['route'] as Map);
  }

  Future<({List<Map<String, dynamic>> flights, String? source})>
      listAdminTunisiaFlightArrivals(String token) async {
    final r = await _http.get(
      _u('/api/admin/tunisia-flight-arrivals'),
      headers: _jsonHeaders(bearer: token),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final list = body['flights'] as List<dynamic>;
    final flights =
        list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final source = body['flight_data_source'] as String?;
    return (flights: flights, source: source);
  }

  Future<List<Map<String, dynamic>>> listAdminRides(
    String token, {
    int limit = 200,
  }) async {
    final uri =
        _u('/api/admin/rides').replace(queryParameters: {'limit': '$limit'});
    final r = await _http.get(uri, headers: _jsonHeaders(bearer: token));
    if (r.statusCode != 200) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final list = body['rides'] as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> listAdminDriverLocations(
      String token) async {
    final r = await _http.get(
      _u('/api/admin/drivers/locations'),
      headers: _jsonHeaders(bearer: token),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
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
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> listAdminB2bBookings(
    String token, {
    int limit = 200,
  }) async {
    final uri = _u('/api/admin/b2b-bookings')
        .replace(queryParameters: {'limit': '$limit'});
    final r = await _http.get(uri, headers: _jsonHeaders(bearer: token));
    if (r.statusCode != 200) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final list = body['b2b_bookings'] as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> createB2bBooking({
    required String token,
    required String route,
    required String guestName,
    String guestPhone = '',
    String hotelName = '',
    String flightEta = '',
    required String roomNumber,
    required double fare,
    required String sourceCode,
    DateTime? scheduledPickupAt,
    String? pickupAddress,
    String? pickupDisplayName,
    String? destinationAddress,
    String? destinationDisplayName,
    double? pickupLat,
    double? pickupLng,
    double? destinationLat,
    double? destinationLng,
    double? quotedDistanceKm,
    int? quotedDurationSeconds,
    double? quotedFareDt,
    double? quotedBaseFareDt,
    double? quotedNightSurchargeDt,
    bool? quotedIsNight,
  }) async {
    final body = <String, dynamic>{
      'route': route,
      'guest_name': guestName,
      'guest_phone': guestPhone,
      'hotel_name': hotelName,
      'flight_eta': flightEta,
      'room_number': roomNumber,
      'fare': fare,
      'source_code': sourceCode,
      if (scheduledPickupAt != null)
        'scheduled_pickup_at': scheduledPickupAt.toUtc().toIso8601String(),
      if ((pickupAddress ?? '').trim().isNotEmpty)
        'pickup_address': pickupAddress!.trim(),
      if ((pickupDisplayName ?? '').trim().isNotEmpty)
        'pickup_display_name': pickupDisplayName!.trim(),
      if ((destinationAddress ?? '').trim().isNotEmpty)
        'destination_address': destinationAddress!.trim(),
      if ((destinationDisplayName ?? '').trim().isNotEmpty)
        'destination_display_name': destinationDisplayName!.trim(),
      if (pickupLat != null) 'pickup_lat': pickupLat,
      if (pickupLng != null) 'pickup_lng': pickupLng,
      if (destinationLat != null) 'destination_lat': destinationLat,
      if (destinationLng != null) 'destination_lng': destinationLng,
      if (quotedDistanceKm != null) 'quoted_distance_km': quotedDistanceKm,
      if (quotedDurationSeconds != null)
        'quoted_duration_seconds': quotedDurationSeconds,
      if (quotedFareDt != null) 'quoted_fare_dt': quotedFareDt,
      if (quotedBaseFareDt != null) 'quoted_base_fare_dt': quotedBaseFareDt,
      if (quotedNightSurchargeDt != null)
        'quoted_night_surcharge_dt': quotedNightSurchargeDt,
      if (quotedIsNight != null) 'quoted_is_night': quotedIsNight,
    };
    final r = await _http.post(
      _u('/api/b2b/bookings'),
      headers: _jsonHeaders(bearer: token),
      body: jsonEncode(body),
    );
    if (r.statusCode != 201) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final decoded = jsonDecode(r.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(decoded['booking'] as Map);
  }

  Future<Map<String, dynamic>> getB2bMe(String token) async {
    final r = await _http.get(
      _u('/api/b2b/me'),
      headers: _jsonHeaders(bearer: token),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    return Map<String, dynamic>.from(jsonDecode(r.body) as Map);
  }

  Future<Map<String, dynamic>> patchB2bMe({
    required String token,
    String? displayName,
    String? phone,
    String? label,
    String? contactName,
    String? pin,
    String? tenantPhone,
    String? hotel,
    String? email,
    String? password,
    String? currentPassword,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['display_name'] = displayName;
    if (phone != null) body['phone'] = phone;
    if (label != null) body['label'] = label;
    if (contactName != null) body['contact_name'] = contactName;
    if (pin != null) body['pin'] = pin;
    if (tenantPhone != null) body['tenant_phone'] = tenantPhone;
    if (hotel != null) body['hotel'] = hotel;
    if (email != null) body['email'] = email;
    if (password != null) body['password'] = password;
    if (currentPassword != null) body['current_password'] = currentPassword;
    final r = await _http.patch(
      _u('/api/b2b/me'),
      headers: _jsonHeaders(bearer: token),
      body: jsonEncode(body),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    return Map<String, dynamic>.from(jsonDecode(r.body) as Map);
  }

  Future<Map<String, dynamic>> getDriverMe(String token) async {
    final r = await _http.get(
      _u('/api/driver/me'),
      headers: _jsonHeaders(bearer: token),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    return Map<String, dynamic>.from(jsonDecode(r.body) as Map);
  }

  Future<Map<String, dynamic>> patchDriverMe({
    required String token,
    String? displayName,
    String? phone,
    String? email,
    String? password,
    String? carModel,
    String? carColor,
    String? photoUrl,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['display_name'] = displayName;
    if (phone != null) body['phone'] = phone;
    if (email != null) body['email'] = email;
    if (password != null) body['password'] = password;
    if (carModel != null) body['car_model'] = carModel;
    if (carColor != null) body['car_color'] = carColor;
    if (photoUrl != null) body['photo_url'] = photoUrl;
    final r = await _http.patch(
      _u('/api/driver/me'),
      headers: _jsonHeaders(bearer: token),
      body: jsonEncode(body),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    return Map<String, dynamic>.from(jsonDecode(r.body) as Map);
  }

  Future<List<Map<String, dynamic>>> listAdminUsers(
    String token, {
    int limit = 100,
    int offset = 0,
  }) async {
    final uri = _u('/api/admin/users').replace(
      queryParameters: {'limit': '$limit', 'offset': '$offset'},
    );
    final r = await _http.get(uri, headers: _jsonHeaders(bearer: token));
    if (r.statusCode != 200) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final list = body['users'] as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> listAdminPendingUsers(
    String token, {
    int limit = 100,
    int offset = 0,
  }) async {
    final uri = _u('/api/admin/users/pending').replace(
      queryParameters: {'limit': '$limit', 'offset': '$offset'},
    );
    final r = await _http.get(uri, headers: _jsonHeaders(bearer: token));
    if (r.statusCode != 200) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final list = body['users'] as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> setAdminUserEnabled({
    required String token,
    required int userId,
    required bool isEnabled,
  }) async {
    final r = await _http.patch(
      _u('/api/admin/users/$userId'),
      headers: _jsonHeaders(bearer: token),
      body: jsonEncode({'is_enabled': isEnabled}),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(body['user'] as Map);
  }

  Future<Map<String, dynamic>> createAdminAppUser({
    required String token,
    required String email,
    required String password,
    required String role,
    required String displayName,
    required String phone,
    String? carModel,
    String? carColor,
    bool autoApprove = true,
  }) async {
    final r = await _http.post(
      _u('/api/admin/users'),
      headers: _jsonHeaders(bearer: token),
      body: jsonEncode({
        'email': email,
        'password': password,
        'role': role,
        'display_name': displayName,
        'phone': phone,
        if ((carModel ?? '').trim().isNotEmpty) 'car_model': carModel!.trim(),
        if ((carColor ?? '').trim().isNotEmpty) 'car_color': carColor!.trim(),
        'auto_approve': autoApprove,
      }),
    );
    if (r.statusCode != 201) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(body['user'] as Map);
  }

  Future<Map<String, dynamic>> patchAdminAppUserProfile({
    required String token,
    required int userId,
    required Map<String, dynamic> payload,
  }) async {
    final r = await _http.patch(
      _u('/api/admin/users/$userId/profile'),
      headers: _jsonHeaders(bearer: token),
      body: jsonEncode(payload),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(body['user'] as Map);
  }

  Future<void> deleteAdminAppUser({
    required String token,
    required int userId,
  }) async {
    final r = await _http.delete(
      _u('/api/admin/users/$userId'),
      headers: _jsonHeaders(bearer: token),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
  }

  Future<List<Map<String, dynamic>>> listAdminB2bTenants(String token) async {
    final r = await _http.get(
      _u('/api/admin/b2b-tenants'),
      headers: _jsonHeaders(bearer: token),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final list = body['b2b_tenants'] as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> setAdminB2bEnabled({
    required String token,
    required int tenantId,
    required bool isEnabled,
  }) async {
    final r = await _http.patch(
      _u('/api/admin/b2b-tenants/$tenantId'),
      headers: _jsonHeaders(bearer: token),
      body: jsonEncode({'is_enabled': isEnabled}),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(body['b2b_tenant'] as Map);
  }

  Future<Map<String, dynamic>> createAdminB2bTenant({
    required String token,
    required String code,
    String label = '',
    String contactName = '',
    String pin = '',
    String phone = '',
    String hotel = '',
    bool isEnabled = true,
  }) async {
    final r = await _http.post(
      _u('/api/admin/b2b-tenants'),
      headers: _jsonHeaders(bearer: token),
      body: jsonEncode({
        'code': code,
        'label': label,
        'contact_name': contactName,
        'pin': pin,
        'phone': phone,
        'hotel': hotel,
        'is_enabled': isEnabled,
      }),
    );
    if (r.statusCode != 201) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(body['b2b_tenant'] as Map);
  }

  Future<Map<String, dynamic>> patchAdminB2bTenant({
    required String token,
    required int tenantId,
    Map<String, dynamic> payload = const {},
  }) async {
    final r = await _http.patch(
      _u('/api/admin/b2b-tenants/$tenantId'),
      headers: _jsonHeaders(bearer: token),
      body: jsonEncode(payload),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(body['b2b_tenant'] as Map);
  }

  Future<List<Map<String, dynamic>>> listAdminDriverPinAccounts(
      String token) async {
    final r = await _http.get(
      _u('/api/admin/driver-pin-accounts'),
      headers: _jsonHeaders(bearer: token),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final list = body['driver_pin_accounts'] as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> listAdminDriverWalletBreakdown(
      String token) async {
    final r = await _http.get(
      _u('/api/admin/driver-wallet-breakdown'),
      headers: _jsonHeaders(bearer: token),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final list = body['driver_wallets'] as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> createAdminDriverPinAccount({
    required String token,
    required String phone,
    required String pin,
    required String driverName,
    required String carModel,
    required String carColor,
    required String photoUrl,
  }) async {
    final r = await _http.post(
      _u('/api/admin/driver-pin-accounts'),
      headers: _jsonHeaders(bearer: token),
      body: jsonEncode({
        'phone': phone,
        'pin': pin,
        'driver_name': driverName,
        'car_model': carModel,
        'car_color': carColor,
        'photo_url': photoUrl,
      }),
    );
    if (r.statusCode != 201) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(body['driver_pin_account'] as Map);
  }

  Future<List<Map<String, dynamic>>> listAdminDriverRatings(String token) async {
    final r = await _http.get(
      _u('/api/admin/ratings/drivers'),
      headers: _jsonHeaders(bearer: token),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final list = body['driver_ratings'] as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> patchAdminDriverPinAccount({
    required String token,
    required int accountId,
    Map<String, dynamic> payload = const {},
  }) async {
    final r = await _http.patch(
      _u('/api/admin/driver-pin-accounts/$accountId'),
      headers: _jsonHeaders(bearer: token),
      body: jsonEncode(payload),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(body['driver_pin_account'] as Map);
  }

  Future<List<Ride>> listRides(String token) async {
    final r =
        await _http.get(_u('/api/rides'), headers: _jsonHeaders(bearer: token));
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
    DateTime? scheduledPickupAt,
    double? quotedDistanceKm,
    int? quotedDurationSeconds,
    double? quotedFareDt,
    double? quotedBaseFareDt,
    double? quotedNightSurchargeDt,
    bool? quotedIsNight,
  }) async {
    final payload = <String, dynamic>{
      'pickup': pickup,
      'destination': destination,
      if (scheduledPickupAt != null)
        'scheduled_pickup_at': scheduledPickupAt.toUtc().toIso8601String(),
      if (quotedDistanceKm != null) 'quoted_distance_km': quotedDistanceKm,
      if (quotedDurationSeconds != null)
        'quoted_duration_seconds': quotedDurationSeconds,
      if (quotedFareDt != null) 'quoted_fare_dt': quotedFareDt,
      if (quotedBaseFareDt != null) 'quoted_base_fare_dt': quotedBaseFareDt,
      if (quotedNightSurchargeDt != null)
        'quoted_night_surcharge_dt': quotedNightSurchargeDt,
      if (quotedIsNight != null) 'quoted_is_night': quotedIsNight,
    };
    final r = await _http.post(
      _u('/api/rides'),
      headers: _jsonHeaders(bearer: token),
      body: jsonEncode(payload),
    );
    if (r.statusCode != 201) {
      throw TaxiApiException(r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return Ride.fromJson(body['ride'] as Map<String, dynamic>);
  }

  Future<GuestRideCreateResponse> createGuestRide({
    required String pickup,
    required String destination,
  }) async {
    final r = await _http.post(
      _u('/api/rides/guest'),
      headers: _jsonHeaders(),
      body: jsonEncode({'pickup': pickup, 'destination': destination}),
    );
    if (r.statusCode != 201) {
      throw TaxiApiException(r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return GuestRideCreateResponse.fromJson(body);
  }

  Future<Ride> cancelGuestRide({required int rideId}) async {
    final r = await _http.post(
      _u('/api/rides/guest/$rideId/cancel'),
      headers: _jsonHeaders(),
    );
    if (r.statusCode != 200) {
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

  Future<Ride> completeRide(
      {required String token, required int rideId}) async {
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

  Future<void> updateDriverLocation({
    required String token,
    required String currentZone,
    bool? isAvailable,
    double? lat,
    double? lng,
  }) async {
    final r = await _http.post(
      _u('/api/rides/driver/location'),
      headers: _jsonHeaders(bearer: token),
      body: jsonEncode({
        'current_zone': currentZone,
        if (isAvailable != null) 'is_available': isAvailable,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      }),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(_errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
  }

  Future<Map<String, dynamic>> driverGains(String token) async {
    final r = await _http.get(
      _u('/api/rides/driver/gains'),
      headers: _jsonHeaders(bearer: token),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(body['gains'] as Map);
  }

  Future<List<Map<String, dynamic>>> listDriverAvailability(String token) async {
    final r = await _http.get(
      _u('/api/rides/driver/availability'),
      headers: _jsonHeaders(bearer: token),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(_errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final list = body['slots'] as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> createDriverAvailability({
    required String token,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    final r = await _http.post(
      _u('/api/rides/driver/availability'),
      headers: _jsonHeaders(bearer: token),
      body: jsonEncode({
        'starts_at': startsAt.toUtc().toIso8601String(),
        'ends_at': endsAt.toUtc().toIso8601String(),
      }),
    );
    if (r.statusCode != 201) {
      throw TaxiApiException(_errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(body['slot'] as Map);
  }

  Future<void> deleteDriverAvailability({
    required String token,
    required int slotId,
  }) async {
    final r = await _http.delete(
      _u('/api/rides/driver/availability/$slotId'),
      headers: _jsonHeaders(bearer: token),
    );
    if (r.statusCode != 200) {
      throw TaxiApiException(_errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
  }
}
