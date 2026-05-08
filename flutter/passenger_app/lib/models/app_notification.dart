class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.rideId,
    this.event,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final int? rideId;
  final String? event;
  bool isRead;
}
