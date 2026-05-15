import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Curated tourist restaurants (Hammamet / Tunis corridor) for map discovery.
/// Coordinates are approximate pin points for map display.
class TunisiaTouristRestaurant {
  const TunisiaTouristRestaurant({
    required this.id,
    required this.name,
    required this.position,
  });

  final String id;
  final String name;
  final LatLng position;
}

abstract final class TunisiaTouristRestaurants {
  TunisiaTouristRestaurants._();

  static const List<TunisiaTouristRestaurant> all = [
    TunisiaTouristRestaurant(
      id: 'bab-tounes',
      name: 'Bab Tounès',
      position: LatLng(36.4012, 10.6080),
    ),
    TunisiaTouristRestaurant(
      id: 'dar-slah',
      name: 'Dar Slah',
      position: LatLng(36.7989, 10.1689),
    ),
    TunisiaTouristRestaurant(
      id: 'lastragale',
      name: "Restaurant L'Astragale",
      position: LatLng(36.4105, 10.6310),
    ),
    TunisiaTouristRestaurant(
      id: 'set-al-habayeb',
      name: 'Restaurant Set Al Habayeb',
      position: LatLng(36.4020, 10.6195),
    ),
    TunisiaTouristRestaurant(
      id: 'federico',
      name: 'FEDERICO',
      position: LatLng(36.3575, 10.5320),
    ),
    TunisiaTouristRestaurant(
      id: 'la-gargote',
      name: 'La Gargote',
      position: LatLng(36.4035, 10.6150),
    ),
    TunisiaTouristRestaurant(
      id: 'la-table-du-chef',
      name: 'La Table du Chef',
      position: LatLng(36.3995, 10.6210),
    ),
    TunisiaTouristRestaurant(
      id: 'la-bella-marina',
      name: 'La Bella Marina',
      position: LatLng(36.3590, 10.5250),
    ),
    TunisiaTouristRestaurant(
      id: 'la-vague-kais',
      name: 'Restaurant La Vague Chez Kais',
      position: LatLng(36.3610, 10.5280),
    ),
    TunisiaTouristRestaurant(
      id: 'le-jardin-des-legumes',
      name: 'Restaurant "Le Jardin des Légumes"',
      position: LatLng(36.4005, 10.6105),
    ),
    TunisiaTouristRestaurant(
      id: 'com-art',
      name: 'Com Art Restaurant',
      position: LatLng(36.8720, 10.3240),
    ),
    TunisiaTouristRestaurant(
      id: 'tip-top',
      name: 'Tip Top Restaurant',
      position: LatLng(36.4050, 10.6180),
    ),
    TunisiaTouristRestaurant(
      id: 'radisson-blu-hammamet',
      name: 'Radisson Blu Hammamet Tunisie',
      position: LatLng(36.3745, 10.5560),
    ),
    TunisiaTouristRestaurant(
      id: 'petit-pecheur-1',
      name: 'Petit Pêcheur 1 Hammamet',
      position: LatLng(36.3625, 10.5275),
    ),
    TunisiaTouristRestaurant(
      id: 'restaurant-des-arts',
      name: 'Restaurant des Arts',
      position: LatLng(36.8010, 10.1655),
    ),
    TunisiaTouristRestaurant(
      id: 'walima',
      name: 'Walima',
      position: LatLng(36.8480, 10.2750),
    ),
    TunisiaTouristRestaurant(
      id: 'le-sultan',
      name: 'Le Sultan Restaurant & Lounge',
      position: LatLng(36.3700, 10.5480),
    ),
    TunisiaTouristRestaurant(
      id: 'el-ali',
      name: 'El Ali Restaurant & Cafe',
      position: LatLng(36.3980, 10.6125),
    ),
    TunisiaTouristRestaurant(
      id: 'la-vinotheque',
      name: 'La Vinothèque by La Salle à Manger',
      position: LatLng(36.8510, 10.3120),
    ),
  ];

  static TunisiaTouristRestaurant? byId(String raw) {
    final id = raw.trim();
    if (id.isEmpty) return null;
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }
}
