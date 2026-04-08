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
