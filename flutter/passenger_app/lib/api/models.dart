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
    this.appAccessToken,
    this.userId,
    this.refreshToken,
  });

  final String accessToken;
  final String role;
  final String? appAccessToken;
  final int? userId;
  final String? refreshToken;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] as String,
      role: json['role'] as String,
      appAccessToken: json['app_access_token'] as String?,
      userId: (json['user_id'] as num?)?.toInt(),
      refreshToken: json['refresh_token'] as String?,
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
    this.preferredLanguage,
    this.refreshToken,
  });

  final String accessToken;
  final String role;
  final String? refreshToken;
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
  final String? preferredLanguage;

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
      preferredLanguage: json['preferred_language'] as String?,
      refreshToken: json['refresh_token'] as String?,
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
    this.preferredLanguage,
    this.displayName,
    this.photoUrl,
    this.email,
    this.phone,
    this.refreshToken,
  });

  final String accessToken;
  final String role;
  final int userId;
  final String? refreshToken;
  final String? preferredLanguage;
  final String? displayName;
  final String? photoUrl;
  final String? email;
  final String? phone;

  factory AppLoginResponse.fromJson(Map<String, dynamic> json) {
    return AppLoginResponse(
      accessToken: json['access_token'] as String,
      role: json['role'] as String,
      userId: (json['user_id'] as num).toInt(),
      refreshToken: json['refresh_token'] as String?,
      preferredLanguage: json['preferred_language'] as String?,
      displayName: json['display_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
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
    this.pickupAddress,
    this.pickupDisplayName,
    this.destinationAddress,
    this.destinationDisplayName,
    this.pickupLat,
    this.pickupLng,
    this.destinationLat,
    this.destinationLng,
    this.driverName,
    this.driverVehicle,
    this.driverPhone,
    this.passengerName,
    this.passengerPhone,
    this.isRated,
    this.driverPhotoUrl,
    this.driverCarModel,
    this.driverCarColor,
    this.driverCurrentZone,
    this.isB2b,
    this.b2bGuestName,
    this.b2bRoomNumber,
    this.b2bTenantName,
    this.b2bSourceCode,
    this.b2bFare,
    this.scheduledPickupAt,
    this.reservationStatus,
    this.createdAt,
    this.updatedAt,
    this.quotedDistanceKm,
    this.quotedDurationSeconds,
    this.quotedFareDt,
    this.quotedBaseFareDt,
    this.quotedNightSurchargeDt,
    this.quotedIsNight,
  });

  final int id;
  final int userId;
  final int? driverId;
  final String status;
  final String pickup;
  final String destination;
  /// Reverse-geocoded or client-captured formatted pickup address (optional).
  final String? pickupAddress;
  /// Passenger-facing pickup place name (optional).
  final String? pickupDisplayName;
  final String? destinationAddress;
  final String? destinationDisplayName;
  final double? pickupLat;
  final double? pickupLng;
  final double? destinationLat;
  final double? destinationLng;
  final String? driverName;
  final String? driverVehicle;
  final String? driverPhone;
  final String? passengerName;
  final String? passengerPhone;
  final bool? isRated;
  final String? driverPhotoUrl;
  final String? driverCarModel;
  final String? driverCarColor;
  final String? driverCurrentZone;
  final bool? isB2b;
  final String? b2bGuestName;
  final String? b2bRoomNumber;
  final String? b2bTenantName;
  final String? b2bSourceCode;
  final double? b2bFare;
  final String? scheduledPickupAt;
  final String? reservationStatus;
  final String? createdAt;
  final String? updatedAt;
  /// Locked route distance from Google Directions at booking (km).
  final double? quotedDistanceKm;
  /// Locked driving duration from Google Directions at booking (seconds).
  final int? quotedDurationSeconds;
  /// Locked passenger price in Tunisian dinars (includes night surcharge when applicable).
  final double? quotedFareDt;
  final double? quotedBaseFareDt;
  final double? quotedNightSurchargeDt;
  final bool? quotedIsNight;

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      driverId: (json['driver_id'] as num?)?.toInt(),
      status: json['status'] as String,
      pickup: json['pickup'] as String,
      destination: json['destination'] as String,
      pickupAddress: json['pickup_address'] as String?,
      pickupDisplayName: json['pickup_display_name'] as String?,
      destinationAddress: json['destination_address'] as String?,
      destinationDisplayName: json['destination_display_name'] as String?,
      pickupLat: (json['pickup_lat'] as num?)?.toDouble(),
      pickupLng: (json['pickup_lng'] as num?)?.toDouble(),
      destinationLat: (json['destination_lat'] as num?)?.toDouble(),
      destinationLng: (json['destination_lng'] as num?)?.toDouble(),
      driverName: json['driver_name'] as String?,
      driverVehicle: json['driver_vehicle'] as String?,
      driverPhone: json['driver_phone'] as String?,
      passengerName: json['passenger_name'] as String?,
      passengerPhone: json['passenger_phone'] as String?,
      isRated: json['is_rated'] as bool?,
      driverPhotoUrl: json['driver_photo_url'] as String?,
      driverCarModel: json['driver_car_model'] as String?,
      driverCarColor: json['driver_car_color'] as String?,
      driverCurrentZone: json['driver_current_zone'] as String?,
      isB2b: json['is_b2b'] as bool?,
      b2bGuestName: json['b2b_guest_name'] as String?,
      b2bRoomNumber: json['b2b_room_number'] as String?,
      b2bTenantName: json['b2b_tenant_name'] as String?,
      b2bSourceCode: json['b2b_source_code'] as String?,
      b2bFare: (json['b2b_fare'] as num?)?.toDouble(),
      scheduledPickupAt: json['scheduled_pickup_at'] as String?,
      reservationStatus: json['reservation_status'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      quotedDistanceKm: (json['quoted_distance_km'] as num?)?.toDouble(),
      quotedDurationSeconds: (json['quoted_duration_seconds'] as num?)?.toInt(),
      quotedFareDt: (json['quoted_fare_dt'] as num?)?.toDouble(),
      quotedBaseFareDt: (json['quoted_base_fare_dt'] as num?)?.toDouble(),
      quotedNightSurchargeDt:
          (json['quoted_night_surcharge_dt'] as num?)?.toDouble(),
      quotedIsNight: json['quoted_is_night'] as bool?,
    );
  }
}

extension RideQuoteMerge on Ride {
  /// Keeps quotation fields when a socket/API payload omits them.
  Ride preservingQuotesFrom(Ride previous) {
    return Ride(
      id: id,
      userId: userId,
      driverId: driverId,
      status: status,
      pickup: pickup,
      destination: destination,
      pickupAddress: pickupAddress ?? previous.pickupAddress,
      pickupDisplayName: pickupDisplayName ?? previous.pickupDisplayName,
      destinationAddress: destinationAddress ?? previous.destinationAddress,
      destinationDisplayName: destinationDisplayName ?? previous.destinationDisplayName,
      pickupLat: pickupLat ?? previous.pickupLat,
      pickupLng: pickupLng ?? previous.pickupLng,
      destinationLat: destinationLat ?? previous.destinationLat,
      destinationLng: destinationLng ?? previous.destinationLng,
      driverName: driverName,
      driverVehicle: driverVehicle,
      driverPhone: driverPhone,
      passengerName: passengerName,
      passengerPhone: passengerPhone,
      isRated: isRated,
      driverPhotoUrl: driverPhotoUrl,
      driverCarModel: driverCarModel,
      driverCarColor: driverCarColor,
      driverCurrentZone: driverCurrentZone,
      isB2b: isB2b,
      b2bGuestName: b2bGuestName,
      b2bRoomNumber: b2bRoomNumber,
      b2bTenantName: b2bTenantName ?? previous.b2bTenantName,
      b2bSourceCode: b2bSourceCode,
      b2bFare: b2bFare,
      scheduledPickupAt: scheduledPickupAt,
      reservationStatus: reservationStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
      quotedDistanceKm: quotedDistanceKm ?? previous.quotedDistanceKm,
      quotedDurationSeconds:
          quotedDurationSeconds ?? previous.quotedDurationSeconds,
      quotedFareDt: quotedFareDt ?? previous.quotedFareDt,
      quotedBaseFareDt: quotedBaseFareDt ?? previous.quotedBaseFareDt,
      quotedNightSurchargeDt:
          quotedNightSurchargeDt ?? previous.quotedNightSurchargeDt,
      quotedIsNight: quotedIsNight ?? previous.quotedIsNight,
    );
  }
}
