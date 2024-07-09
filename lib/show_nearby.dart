// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math' show cos, pi;
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:multi_restaurant_app/food_itemcell.dart';
import 'package:multi_restaurant_app/model/nearby_restaurant_model.dart';
import 'package:multi_restaurant_app/screens/cart.dart';

class ShowNearbyRestaurants extends StatefulWidget {
  const ShowNearbyRestaurants({super.key});

  @override
  State<ShowNearbyRestaurants> createState() => _ShowNearbyRestaurantsState();
}

class _ShowNearbyRestaurantsState extends State<ShowNearbyRestaurants> {
  List<Restaurant> restaurants = [];
  final loc.Location _location = loc.Location();

  @override
  void initState() {
    super.initState();
    _fetchNearbyRestaurants();
  }

  Future<void> _fetchNearbyRestaurants() async {
    try {
      var currentLocation = await _getLocation();
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        await fetchRestaurants(
            currentLocation.latitude!, currentLocation.longitude!);
      }
    } catch (e) {
      print("Error fetching nearby restaurants: $e");
    }
  }

  Future<void> _updateUserLocationOnTap() async {
    try {
      loc.LocationData currentLocation = await _getLocation();
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        _updateUserLocation(
            currentLocation.latitude!, currentLocation.longitude!);
        _fetchNearbyRestaurants(); // Fetch nearby restaurants after updating location
      }
    } catch (e) {
      print("Error fetching user location: $e");
    }
  }

  Future<loc.LocationData> _getLocation() async {
    try {
      return await _location.getLocation();
    } catch (e) {
      print("Error getting location: $e");
      return loc.LocationData.fromMap({
        "latitude": 0.0,
        "longitude": 0.0,
      });
    }
  }

  Future<void> fetchRestaurants(double latitude, double longitude) async {
    try {
      double radius = 10.0;
      double latitudeDelta = radius / 111.12;
      double longitudeDelta = radius / (111.12 * cos(latitude * pi / 180));

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('nearby_restaurants')
          .where('latitude', isLessThanOrEqualTo: latitude + latitudeDelta)
          .where('latitude', isGreaterThanOrEqualTo: latitude - latitudeDelta)
          .where('longitude', isLessThanOrEqualTo: longitude + longitudeDelta)
          .where('longitude',
              isGreaterThanOrEqualTo: longitude - longitudeDelta)
          .get();

      List<Restaurant> fetchedRestaurants = snapshot.docs.map((doc) {
        return Restaurant(
          uid: doc.id,
          name: doc['name'],
          address: doc['address'],
          ratings: doc['ratings'],
          availability: doc['availability'],
          cityName: doc['cityName'],
          latitude: doc['latitude'],
          longitude: doc['longitude'],
          imageUrl: doc['imageUrl'],
          averagePricePerPerson: doc['averagePricePerPerson'],
          priceRange: doc['priceRange'],
          category: doc['category'],
          timing: doc['timing'],
        );
      }).toList();

      setState(() {
        restaurants = fetchedRestaurants;
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching restaurants: $e");
      }
    }
  }

  Future<void> _updateUserLocation(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String country = placemark.country ?? 'Unknown';
        String city = placemark.locality ?? 'Unknown';

        // Get current user's document reference
        DocumentReference userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid);

        // Update Firestore with location data
        await userRef.update({
          'country': country,
          'city': city,
          'latitude': latitude,
          'longitude': longitude,
        });
      }
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Nearby Restaurants',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              _updateUserLocationOnTap(); // Update user location on tap
            },
            child: Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.only(right: 16),
              child: const CircleAvatar(
                backgroundImage: NetworkImage(
                  'https://img.freepik.com/free-vector/sightseeing-tour-landmark-visit-milestone-accomplishment-moving-forward-roadmap-progress-decorative-design-element-gps-navigation-location-pin_335657-3540.jpg?w=740&t=st=1720486228~exp=1720486828~hmac=62eb31d70faf57f92b918264037d63d3d1360335b4a406d4f0ee0bd5f57a3d5b',
                ),
                radius: 22,
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: restaurants.length,
        itemBuilder: (BuildContext context, int index) {
          return FoodItemCell(
            restaurant: restaurants[index],
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          CartScreen(selectedRestaurant: restaurants[index])));
            },
          );
        },
      ),
    );
  }
}
