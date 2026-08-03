import 'package:latlong2/latlong.dart';

class Polda {
  final int id;
  final String namaPolda;
  final String latitude; // raw value from API — preserves exact precision
  final String longitude; // raw value from API — preserves exact precision
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
      id:
          json["id"] is int
              ? json["id"]
              : int.tryParse(json["id"].toString()) ?? 0,
      namaPolda: json["nama_polda"]?.toString() ?? "Unknown",
      latitude: (json["latitude"] ?? json["lat"])?.toString() ?? "",
      longitude:
          (json["longitude"] ?? json["lng"] ?? json["lon"])?.toString() ?? "",
      createdAt: json["created_at"]?.toString(),
    );
  }

  bool get hasValidCoordinates {
    final lat = double.tryParse(latitude);
    final lng = double.tryParse(longitude);
    return lat != null && lng != null && lat != 0.0 && lng != 0.0;
  }

  LatLng get latLng => LatLng(
    double.tryParse(latitude) ?? 0.0,
    double.tryParse(longitude) ?? 0.0,
  );
}
