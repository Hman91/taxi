import '../api/client.dart';
import '../api/models.dart';
import '../models/chat_message.dart';

/// UI talks to this layer only — no HTTP in widgets (see `.cursor/rules.md`).
class TaxiAppService {
  TaxiAppService({TaxiApiClient? client}) : _client = client ?? TaxiApiClient();

  final TaxiApiClient _client;

  Future<void> health() => _client.health();

  Future<Map<String, double>> getAirportFares() => _client.getAirportFares();

  Future<Map<String, dynamic>> quoteAirport(String routeKey) =>
      _client.quoteAirport(routeKey);

  Future<Map<String, dynamic>> quoteGps({double? distanceKm}) =>
      _client.quoteGps(distanceKm: distanceKm);

  Future<LoginResponse> login({required String role, required String secret}) =>
      _client.login(role: role, secret: secret);

  Future<DriverPinLoginResponse> loginDriverPin({
    required String phone,
    required String pin,
  }) =>
      _client.loginDriverPin(phone: phone, pin: pin);

  Future<AppLoginResponse> loginApp({
    required String email,
    required String password,
  }) =>
      _client.loginApp(email: email, password: password);

  Future<AppLoginResponse> loginGoogle({
    String? idToken,
    String? accessToken,
    String? phone,
  }) =>
      _client.loginGoogle(
        idToken: idToken,
        accessToken: accessToken,
        phone: phone,
      );

  Future<Map<String, dynamic>> registerAppUser({
    required String email,
    required String password,
    required String role,
    String? displayName,
    String? phone,
    String? photoUrl,
  }) =>
      _client.registerAppUser(
        email: email,
        password: password,
        role: role,
        displayName: displayName,
        phone: phone,
        photoUrl: photoUrl,
      );

  Future<List<Ride>> listRides(String token) => _client.listRides(token);

  Future<Ride> createRide({
    required String token,
    required String pickup,
    required String destination,
  }) =>
      _client.createRide(
          token: token, pickup: pickup, destination: destination);

  Future<GuestRideCreateResponse> createGuestRide({
    required String pickup,
    required String destination,
  }) =>
      _client.createGuestRide(pickup: pickup, destination: destination);

  Future<Ride> cancelGuestRide({required int rideId}) =>
      _client.cancelGuestRide(rideId: rideId);

  Future<Ride> acceptRide({required String token, required int rideId}) =>
      _client.acceptRide(token: token, rideId: rideId);

  Future<Ride> rejectRide({required String token, required int rideId}) =>
      _client.rejectRide(token: token, rideId: rideId);

  Future<Ride> startRide({required String token, required int rideId}) =>
      _client.startRide(token: token, rideId: rideId);

  Future<Ride> completeRide({required String token, required int rideId}) =>
      _client.completeRide(token: token, rideId: rideId);

  Future<Ride> cancelRide({required String token, required int rideId}) =>
      _client.cancelRide(token: token, rideId: rideId);

  Future<void> updateDriverLocation({
    required String token,
    required String currentZone,
    bool? isAvailable,
  }) =>
      _client.updateDriverLocation(
        token: token,
        currentZone: currentZone,
        isAvailable: isAvailable,
      );

  Future<Map<String, dynamic>> driverGains(String token) =>
      _client.driverGains(token);

  Future<Trip> createTrip({
    required String token,
    required String route,
    required double fare,
    String? driverPhone,
    String type = 'كاش / بطاقة',
  }) =>
      _client.createTrip(
        token: token,
        route: route,
        fare: fare,
        driverPhone: driverPhone,
        type: type,
      );

  Future<List<Trip>> listTrips(String token) => _client.listTrips(token);

  Future<Map<String, dynamic>> ownerMetrics(String token) =>
      _client.ownerMetrics(token);

  Future<Map<String, dynamic>> submitRating({
    required String token,
    required int rideId,
    required int stars,
  }) =>
      _client.submitRating(token: token, rideId: rideId, stars: stars);

  Future<RideConversationInfo?> getRideConversation({
    required String token,
    required int rideId,
  }) =>
      _client.getRideConversation(token: token, rideId: rideId);

  Future<List<ChatMessage>> listConversationMessages({
    required String token,
    required int conversationId,
    int? beforeId,
    int limit = 50,
  }) =>
      _client.listConversationMessages(
        token: token,
        conversationId: conversationId,
        beforeId: beforeId,
        limit: limit,
      );

  Future<void> patchPreferredLanguage({
    required String token,
    required String preferredLanguage,
  }) =>
      _client.patchPreferredLanguage(
        token: token,
        preferredLanguage: preferredLanguage,
      );

  Future<List<Map<String, dynamic>>> listAdminFareRoutes(String token) =>
      _client.listAdminFareRoutes(token);

  Future<Map<String, dynamic>> patchAdminFareRoute({
    required String token,
    required int routeId,
    required double baseFare,
  }) =>
      _client.patchAdminFareRoute(
        token: token,
        routeId: routeId,
        baseFare: baseFare,
      );

  Future<List<Map<String, dynamic>>> listAdminTunisiaFlightArrivals(
          String token) =>
      _client.listAdminTunisiaFlightArrivals(token);

  Future<List<Map<String, dynamic>>> listAdminRides(
    String token, {
    int limit = 200,
  }) =>
      _client.listAdminRides(token, limit: limit);

  Future<List<Map<String, dynamic>>> listAdminDriverLocations(String token) =>
      _client.listAdminDriverLocations(token);

  Future<Map<String, dynamic>> adminOwnerMetrics(String token) =>
      _client.adminOwnerMetrics(token);

  Future<List<Map<String, dynamic>>> listAdminB2bBookings(
    String token, {
    int limit = 200,
  }) =>
      _client.listAdminB2bBookings(token, limit: limit);

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
  }) =>
      _client.createB2bBooking(
        token: token,
        route: route,
        guestName: guestName,
        guestPhone: guestPhone,
        hotelName: hotelName,
        flightEta: flightEta,
        roomNumber: roomNumber,
        fare: fare,
        sourceCode: sourceCode,
      );

  Future<List<Map<String, dynamic>>> listAdminUsers(
    String token, {
    int limit = 100,
    int offset = 0,
  }) =>
      _client.listAdminUsers(token, limit: limit, offset: offset);

  Future<Map<String, dynamic>> setAdminUserEnabled({
    required String token,
    required int userId,
    required bool isEnabled,
  }) =>
      _client.setAdminUserEnabled(
        token: token,
        userId: userId,
        isEnabled: isEnabled,
      );

  Future<List<Map<String, dynamic>>> listAdminB2bTenants(String token) =>
      _client.listAdminB2bTenants(token);

  Future<Map<String, dynamic>> setAdminB2bEnabled({
    required String token,
    required int tenantId,
    required bool isEnabled,
  }) =>
      _client.setAdminB2bEnabled(
        token: token,
        tenantId: tenantId,
        isEnabled: isEnabled,
      );

  Future<Map<String, dynamic>> createAdminB2bTenant({
    required String token,
    required String code,
    String label = '',
    String contactName = '',
    String pin = '',
    String phone = '',
    String hotel = '',
    bool isEnabled = true,
  }) =>
      _client.createAdminB2bTenant(
        token: token,
        code: code,
        label: label,
        contactName: contactName,
        pin: pin,
        phone: phone,
        hotel: hotel,
        isEnabled: isEnabled,
      );

  Future<Map<String, dynamic>> patchAdminB2bTenant({
    required String token,
    required int tenantId,
    Map<String, dynamic> payload = const {},
  }) =>
      _client.patchAdminB2bTenant(
        token: token,
        tenantId: tenantId,
        payload: payload,
      );

  Future<List<Map<String, dynamic>>> listAdminDriverPinAccounts(String token) =>
      _client.listAdminDriverPinAccounts(token);

  Future<List<Map<String, dynamic>>> listAdminDriverWalletBreakdown(
          String token) =>
      _client.listAdminDriverWalletBreakdown(token);

  Future<Map<String, dynamic>> createAdminDriverPinAccount({
    required String token,
    required String phone,
    required String pin,
    required String driverName,
    required String carModel,
    required String carColor,
    required String photoUrl,
  }) =>
      _client.createAdminDriverPinAccount(
        token: token,
        phone: phone,
        pin: pin,
        driverName: driverName,
        carModel: carModel,
        carColor: carColor,
        photoUrl: photoUrl,
      );

  Future<Map<String, dynamic>> patchAdminDriverPinAccount({
    required String token,
    required int accountId,
    Map<String, dynamic> payload = const {},
  }) =>
      _client.patchAdminDriverPinAccount(
        token: token,
        accountId: accountId,
        payload: payload,
      );

  Future<List<Map<String, dynamic>>> listAdminDriverRatings(String token) =>
      _client.listAdminDriverRatings(token);
}
