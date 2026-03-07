class GiftCard {
  final int id;
  final String title;
  final String description;
  final int pointsRequired;
  final String imageUrl;
  final String? agreement;
  final String? policies;
  final String? detailDescription;
  final String? contactPhone;
  final String? expireDate;

  GiftCard({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsRequired,
    required this.imageUrl,
    this.agreement,
    this.policies,
    this.detailDescription,
    this.contactPhone,
    this.expireDate,
  });

  factory GiftCard.fromMap(Map<String, dynamic> map) {
    return GiftCard(
      id: map['id'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      pointsRequired: map['points_required'] ?? 0,
      imageUrl: map['image_url'] ?? '',
      agreement: map['agreement'],
      policies: map['policies'],
      detailDescription: map['detail_description'],
      contactPhone: map['contact_phone'],
      expireDate: map['expire_date'],
    );
  }
}
