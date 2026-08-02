import 'package:latlong2/latlong.dart';

class Polda {
  final int id;
  final String namaPolda;
  final double latitude;
  final double longitude;
  final String? createdAt;

  const Polda({
    required this.id,
    required this.namaPolda,
    required this.latitude,
    required this.longitude,
    this.createdAt,
  });

  factory Polda.fromJson(Map<String, dynamic> json) {
    return Polda(
      id: json["id"] is int
          ? json["id"]
          : int.tryParse(json["id"].toString()) ?? 0,
      namaPolda: json["nama_polda"]?.toString() ?? "Unknown",
      latitude: double.tryParse(
              (json["latitude"] ?? json["lat"]).toString()) ??
          0.0,
      longitude: double.tryParse(
              (json["longitude"] ?? json["lng"] ?? json["lon"]).toString()) ??
          0.0,
      createdAt: json["created_at"]?.toString(),
    );
  }

  bool get hasValidCoordinates => latitude != 0.0 && longitude != 0.0;

  LatLng get latLng => LatLng(latitude, longitude);
}
