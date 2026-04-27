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
  TaxiApiClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

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
    return DriverPinLoginResponse.fromJson(
        jsonDecode(r.body) as Map<String, dynamic>);
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
      throw TaxiApiException(code ?? r.body, r.statusCode);
    }
    return AppLoginResponse.fromJson(
        jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<AppLoginResponse> loginGoogle({
    String? idToken,
    String? accessToken,
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
        if ((phone ?? '').trim().isNotEmpty) 'phone': phone!.trim(),
      }),
    );
    if (r.statusCode != 200) {
      final code = _errorCodeFromBody(r.body);
      if (r.statusCode == 403 && code == 'account_disabled') {
        throw TaxiAccountDisabledException();
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

  Future<List<Map<String, dynamic>>> listAdminTunisiaFlightArrivals(
      String token) async {
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
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
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
  }) async {
    final r = await _http.post(
      _u('/api/b2b/bookings'),
      headers: _jsonHeaders(bearer: token),
      body: jsonEncode({
        'route': route,
        'guest_name': guestName,
        'guest_phone': guestPhone,
        'hotel_name': hotelName,
        'flight_eta': flightEta,
        'room_number': roomNumber,
        'fare': fare,
        'source_code': sourceCode,
      }),
    );
    if (r.statusCode != 201) {
      throw TaxiApiException(
          _errorCodeFromBody(r.body) ?? r.body, r.statusCode);
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(body['booking'] as Map);
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
  }) async {
    final r = await _http.post(
      _u('/api/rides/driver/location'),
      headers: _jsonHeaders(bearer: token),
      body: jsonEncode({
        'current_zone': currentZone,
        if (isAvailable != null) 'is_available': isAvailable,
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
}
