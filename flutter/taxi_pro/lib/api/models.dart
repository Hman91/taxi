class Trip {
  Trip({
    required this.id,
    required this.date,
    required this.driver,
    required this.route,
    required this.fare,
    required this.commission,
    required this.type,
    required this.status,
    this.createdAt,
  });

  final int id;
  final String date;
  final String driver;
  final String route;
  final double fare;
  final double commission;
  final String type;
  final String status;
  final String? createdAt;

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as int,
      date: json['date'] as String,
      driver: json['driver'] as String,
      route: json['route'] as String,
      fare: (json['fare'] as num).toDouble(),
      commission: (json['commission'] as num).toDouble(),
      type: json['type'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] as String?,
    );
  }
}

class LoginResponse {
  LoginResponse({
    required this.accessToken,
    required this.role,
  });

  final String accessToken;
  final String role;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] as String,
      role: json['role'] as String,
    );
  }
}

/// JWT from `/api/auth/login-app` (includes `uid` in token for ride APIs).
class AppLoginResponse {
  AppLoginResponse({
    required this.accessToken,
    required this.role,
    required this.userId,
  });

  final String accessToken;
  final String role;
  final int userId;

  factory AppLoginResponse.fromJson(Map<String, dynamic> json) {
    return AppLoginResponse(
      accessToken: json['access_token'] as String,
      role: json['role'] as String,
      userId: json['user_id'] as int,
    );
  }
}

class Ride {
  Ride({
    required this.id,
    required this.userId,
    required this.driverId,
    required this.status,
    required this.pickup,
    required this.destination,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int userId;
  final int? driverId;
  final String status;
  final String pickup;
  final String destination;
  final String? createdAt;
  final String? updatedAt;

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      driverId: (json['driver_id'] as num?)?.toInt(),
      status: json['status'] as String,
      pickup: json['pickup'] as String,
      destination: json['destination'] as String,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}
