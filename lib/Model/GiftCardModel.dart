class GiftCard {
  final int id;
  final String title;
  final String description;
  final int pointsRequired;
  final String imageUrl;

  GiftCard({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsRequired,
    required this.imageUrl,
  });

  factory GiftCard.fromMap(Map<String, dynamic> map) {
    return GiftCard(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      pointsRequired: map['points_required'],
      imageUrl: map['image_url'] ?? '',
    );
  }
}
