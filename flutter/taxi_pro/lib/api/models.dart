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

class DriverPinLoginResponse {
  DriverPinLoginResponse({
    required this.accessToken,
    required this.role,
    required this.userId,
    this.driverId,
    required this.driverName,
    required this.phone,
    required this.walletBalance,
    required this.ownerCommissionRate,
    required this.b2bCommissionRate,
    required this.autoDeductEnabled,
    this.photoUrl,
    this.carModel,
    this.carColor,
    this.currentZone,
  });

  final String accessToken;
  final String role;
  final int userId;
  final int? driverId;
  final String driverName;
  final String phone;
  final double walletBalance;
  final double ownerCommissionRate;
  final double b2bCommissionRate;
  final bool autoDeductEnabled;
  final String? photoUrl;
  final String? carModel;
  final String? carColor;
  final String? currentZone;

  factory DriverPinLoginResponse.fromJson(Map<String, dynamic> json) {
    return DriverPinLoginResponse(
      accessToken: json['access_token'] as String,
      role: json['role'] as String,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      driverId: (json['driver_id'] as num?)?.toInt(),
      driverName: json['driver_name'] as String,
      phone: json['phone'] as String,
      walletBalance: (json['wallet_balance'] as num?)?.toDouble() ?? 0.0,
      ownerCommissionRate:
          (json['owner_commission_rate'] as num?)?.toDouble() ?? 10.0,
      b2bCommissionRate:
          (json['b2b_commission_rate'] as num?)?.toDouble() ?? 5.0,
      autoDeductEnabled: (json['auto_deduct_enabled'] as bool?) ?? true,
      photoUrl: json['photo_url'] as String?,
      carModel: json['car_model'] as String?,
      carColor: json['car_color'] as String?,
      currentZone: json['current_zone'] as String?,
    );
  }
}

class GuestRideCreateResponse {
  GuestRideCreateResponse({
    required this.ride,
    required this.accessToken,
    required this.userId,
  });

  final Ride ride;
  final String accessToken;
  final int userId;

  factory GuestRideCreateResponse.fromJson(Map<String, dynamic> json) {
    return GuestRideCreateResponse(
      ride: Ride.fromJson(json['ride'] as Map<String, dynamic>),
      accessToken: json['access_token'] as String,
      userId: (json['user_id'] as num).toInt(),
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

/// `GET /api/rides/:id/conversation`
class RideConversationInfo {
  RideConversationInfo({
    required this.conversationId,
    required this.rideId,
  });

  final int conversationId;
  final int rideId;

  factory RideConversationInfo.fromJson(Map<String, dynamic> json) {
    return RideConversationInfo(
      conversationId: (json['conversation_id'] as num).toInt(),
      rideId: (json['ride_id'] as num).toInt(),
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
    this.driverName,
    this.driverVehicle,
    this.driverPhone,
    this.driverPhotoUrl,
    this.driverCarModel,
    this.driverCarColor,
    this.driverCurrentZone,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int userId;
  final int? driverId;
  final String status;
  final String pickup;
  final String destination;
  final String? driverName;
  final String? driverVehicle;
  final String? driverPhone;
  final String? driverPhotoUrl;
  final String? driverCarModel;
  final String? driverCarColor;
  final String? driverCurrentZone;
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
      driverName: json['driver_name'] as String?,
      driverVehicle: json['driver_vehicle'] as String?,
      driverPhone: json['driver_phone'] as String?,
      driverPhotoUrl: json['driver_photo_url'] as String?,
      driverCarModel: json['driver_car_model'] as String?,
      driverCarColor: json['driver_car_color'] as String?,
      driverCurrentZone: json['driver_current_zone'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}
