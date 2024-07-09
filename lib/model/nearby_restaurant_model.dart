
class Restaurant {
  String uid;
  String name;
  String address;
  double ratings;
  bool availability;
  String cityName;
  double latitude;
  double longitude;
  String imageUrl;
  double averagePricePerPerson;
  String priceRange;
  String category;
  String timing;

  Restaurant({
    required this.uid,
    required this.name,
    required this.address,
    required this.ratings,
    required this.availability,
    required this.cityName,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.averagePricePerPerson,
    required this.priceRange,
    required this.category,
    required this.timing,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'address': address,
      'ratings': ratings,
      'availability': availability,
      'cityName': cityName,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'averagePricePerPerson': averagePricePerPerson,
      'priceRange': priceRange,
      'category': category,
      'timing': timing,
    };
  }
}
