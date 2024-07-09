import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String restaurantName;
  final String restaurantAddress;
  final String restaurantImage;
  final String userId;
  final int numberOfPersons;
  final bool status;
  final String table;
  final String totalAmount;
  final Timestamp timestamp;

  Booking({
    required this.restaurantName,
    required this.restaurantAddress,
    required this.restaurantImage,
    required this.userId,
    required this.numberOfPersons,
    required this.status,
    required this.table,
    required this.totalAmount,
    required this.timestamp,
  });

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      restaurantName: map['restaurantName'],
      restaurantAddress: map['restaurantAddress'],
      restaurantImage: map['restaurantImage'],
      userId: map['userId'],
      numberOfPersons: map['numberOfPersons'],
      status: map['status'],
      table: map['table'],
      totalAmount: map['totalAmount'],
      timestamp:
          map['timestamp'] ?? Timestamp.now(), // Handle null case if necessary
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantName': restaurantName,
      'restaurantAddress': restaurantAddress,
      'restaurantImage': restaurantImage,
      'userId': userId,
      'numberOfPersons': numberOfPersons,
      'status': status,
      'table': table,
      'totalAmount': totalAmount,
      'timestamp': timestamp,
    };
  }
}
