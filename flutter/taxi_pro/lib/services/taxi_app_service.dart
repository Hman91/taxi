import '../api/client.dart';
import '../api/models.dart';

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

  Future<AppLoginResponse> loginApp({
    required String email,
    required String password,
  }) =>
      _client.loginApp(email: email, password: password);

  Future<Map<String, dynamic>> registerAppUser({
    required String email,
    required String password,
    required String role,
  }) =>
      _client.registerAppUser(email: email, password: password, role: role);

  Future<List<Ride>> listRides(String token) => _client.listRides(token);

  Future<Ride> createRide({
    required String token,
    required String pickup,
    required String destination,
  }) =>
      _client.createRide(token: token, pickup: pickup, destination: destination);

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

  Future<Trip> createTrip({
    required String token,
    required String route,
    required double fare,
    String type = 'كاش / بطاقة',
  }) =>
      _client.createTrip(token: token, route: route, fare: fare, type: type);

  Future<List<Trip>> listTrips(String token) => _client.listTrips(token);

  Future<Map<String, dynamic>> ownerMetrics(String token) =>
      _client.ownerMetrics(token);

  Future<Map<String, dynamic>> submitRating(int stars) =>
      _client.submitRating(stars);
}
