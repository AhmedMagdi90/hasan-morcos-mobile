class Branch {
  const Branch({
    required this.id,
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.city,
    required this.address,
  });

  final int id;
  final String code;
  final String nameAr;
  final String nameEn;
  final String city;
  final String address;

  String get displayName => '$code - $nameAr';

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] as int,
      code: json['code']?.toString() ?? '',
      nameAr: json['name_ar']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
    );
  }
}
