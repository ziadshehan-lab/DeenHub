/// مدينة للاختيار اليدوي لمواقيت الصلاة عند تعذر تحديد الموقع.
class CityModel {
  const CityModel({
    required this.nameArabic,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  final String nameArabic;
  final String country;
  final double latitude;
  final double longitude;

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      nameArabic: json['nameArabic'] as String,
      country: json['country'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'nameArabic': nameArabic,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
      };
}
