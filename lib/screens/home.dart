// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:multi_restaurant_app/model/nearby_restaurant_model.dart';
import 'package:multi_restaurant_app/screens/cart.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(37.42796133580664,
        -122.085749655962), // Default location (e.g., city center)
    zoom: 14.0,
  );

  GoogleMapController? _controller;
  final loc.Location _location = loc.Location();
  bool isExpanded = false;
  bool showProfileText = false;

  User? user = FirebaseAuth.instance.currentUser;
  String? displayName;
  String? email;
  String? photoURL;
  String? city;
  String? country;

  List<Restaurant> restaurants = [];

  Restaurant? selectedRestaurant; // Track selected restaurant for details

  bool isFirstTimeLocationUpdate =
      true; // Flag to track first time location update

  @override
  void initState() {
    super.initState();

    // Fetch user profile information
    fetchUserProfile();

    // Fetch nearby restaurants once on init using saved user location
    _fetchNearbyRestaurants();
  }

  Future<void> fetchUserProfile() async {
    if (user != null) {
      try {
        DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (documentSnapshot.exists) {
          setState(() {
            displayName = documentSnapshot.get('displayName');
            email = documentSnapshot.get('email');
            photoURL = documentSnapshot.get('photoURL');
            city = documentSnapshot.get('city');
            country = documentSnapshot.get('country');
          });

          // Check if user's location details are empty and update if necessary
          if (isFirstTimeLocationUpdate &&
              (city == null ||
                  country == null ||
                  city!.isEmpty ||
                  country!.isEmpty)) {
            await _updateUserLocationOnTap(); // Update location if necessary
          }

          isFirstTimeLocationUpdate = false;
        }
      } catch (e) {
        print("Error fetching user profile: $e");
      }
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

  Future<void> _fetchNearbyRestaurants() async {
    try {
      // Fetch user's location from Firestore
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (userDoc.exists) {
          double latitude = userDoc['latitude'];
          double longitude = userDoc['longitude'];

          // Fetch nearby restaurants based on stored latitude and longitude
          fetchRestaurants(latitude, longitude);
        }
      }
    } catch (e) {
      print("Error fetching user location from Firestore: $e");
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
      // Assuming a radius of 10 kilometers for nearby restaurants
      double radius = 10.0; // in kilometers

      // Calculate the bounds for latitude and longitude
      double latitudeDelta = radius /
          111.12; // 1 degree of latitude is approximately 111.12 kilometers
      double longitudeDelta = radius / (111.12 * cos(latitude * pi / 180));

      // Define the query to fetch nearby restaurants
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

      // Update map camera position to focus on restaurants
      _updateCameraPositionForRestaurants(fetchedRestaurants);
    } catch (e) {
      print("Error fetching restaurants: $e");
    }
  }

  void _updateCameraPositionForRestaurants(List<Restaurant> restaurants) {
    if (restaurants.isNotEmpty && _controller != null) {
      // Calculate the center position based on restaurant locations
      double sumLatitudes = 0.0;
      double sumLongitudes = 0.0;

      for (var restaurant in restaurants) {
        sumLatitudes += restaurant.latitude;
        sumLongitudes += restaurant.longitude;
      }

      double centerLatitude = sumLatitudes / restaurants.length;
      double centerLongitude = sumLongitudes / restaurants.length;

      // Set camera position to center on restaurant locations
      _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(centerLatitude, centerLongitude),
          12.0, // Adjust the zoom level as needed
        ),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
  }

  void _updateUserLocation(double latitude, double longitude) async {
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

  void _onRestaurantMarkerTap(Restaurant restaurant) {
    setState(() {
      selectedRestaurant = restaurant; // Set selected restaurant for details
    });
  }

  // Helper function to parse TimeOfDay from string
  TimeOfDay parseTimeOfDay(String timeString) {
    List<String> parts = timeString.split(' ');
    List<int> timeParts = parts[0].split(':').map(int.parse).toList();
    int hour = timeParts[0];
    int minute = int.parse(timeParts[1].toString());
    if (parts[1].toLowerCase() == 'pm' && hour < 12) {
      hour += 12;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  bool isTimeOfDayAM(TimeOfDay time) {
    return time.hour < 12;
  }

  // Helper function to adjust TimeOfDay to PM if needed
  TimeOfDay adjustTimeOfDayPM(TimeOfDay time) {
    return TimeOfDay(hour: time.hour + 12, minute: time.minute);
  }

  // Function to determine if the restaurant is currently open
  bool isOpenNow() {
    // Get current time
    DateTime now = DateTime.now();
    // Parse restaurant timings
    List<String> timings = selectedRestaurant!.timing.split(' to ');
    // Parse open and close times
    TimeOfDay openTime = parseTimeOfDay(timings[0]);
    TimeOfDay closeTime = parseTimeOfDay(timings[1]);

    // Convert current time to TimeOfDay format
    TimeOfDay currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

    // Compare current time with open and close times
    if (isTimeOfDayAM(openTime) && !isTimeOfDayAM(closeTime)) {
      closeTime = adjustTimeOfDayPM(closeTime);
    } else if (!isTimeOfDayAM(openTime) && isTimeOfDayAM(closeTime)) {
      openTime = adjustTimeOfDayPM(openTime);
    }

    if (currentTime.hour > openTime.hour ||
        (currentTime.hour == openTime.hour &&
            currentTime.minute >= openTime.minute)) {
      if (currentTime.hour < closeTime.hour ||
          (currentTime.hour == closeTime.hour &&
              currentTime.minute <= closeTime.minute)) {
        return true; // Restaurant is open
      }
    }
    return false; // Restaurant is closed
  }

  // Function to format the timing string based on current open status
  Widget formatTiming() {
    String status = isOpenNow() ? 'Open' : 'Closed';
    Color statusColor = isOpenNow() ? Colors.green : Colors.red;

    return Text(
      status,
      style: TextStyle(
        fontSize: 14,
        color: statusColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: _kInitialPosition,
            markers: Set<Marker>.of(restaurants.map((restaurant) {
              return Marker(
                markerId: MarkerId(restaurant.uid),
                position: LatLng(restaurant.latitude, restaurant.longitude),
                onTap: () => _onRestaurantMarkerTap(restaurant),
                infoWindow: InfoWindow(
                  title: restaurant.name,
                  snippet: restaurant.address,
                ),
              );
            })),
          ),
          Positioned(
            top: 50,
            left: 16,
            child: GestureDetector(
              onTap: () {
                _updateUserLocationOnTap(); // Update user location on tap
              },
              child: const CircleAvatar(
                backgroundImage: NetworkImage(
                  'https://img.freepik.com/free-vector/sightseeing-tour-landmark-visit-milestone-accomplishment-moving-forward-roadmap-progress-decorative-design-element-gps-navigation-location-pin_335657-3540.jpg?w=740&t=st=1720486228~exp=1720486828~hmac=62eb31d70faf57f92b918264037d63d3d1360335b4a406d4f0ee0bd5f57a3d5b',
                ),
                radius: 30,
              ),
            ),
          ),
          if (selectedRestaurant != null) // Show restaurant details if selected
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                width: 100, // Adjust the width as needed
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 7,
                      offset: const Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        selectedRestaurant!.imageUrl,
                        width:
                            120, // Set the width and height to maintain aspect ratio
                        height: 120, // Adjust height as needed
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(
                        width: 8), // Adjust the space between image and text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedRestaurant!.name,
                                softWrap: false, // Ensure text doesn't wrap
                                overflow: TextOverflow
                                    .ellipsis, // Truncate with ellipsis if too long
                                maxLines:
                                    3, // Limit to 3 lines before truncating
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text('${selectedRestaurant!.ratings}'),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedRestaurant!.address,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          formatTiming(),
                          const SizedBox(height: 4),
                          Text(
                            selectedRestaurant!.availability == true
                                ? 'Table Available'
                                : 'Not Available',
                            style: TextStyle(
                              fontSize: 14,
                              color: selectedRestaurant!.availability == true
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.end, // Align to the right
                            children: [
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => CartScreen(
                                              selectedRestaurant:
                                                  restaurants[0])));
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.red, // Text color
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  textStyle: const TextStyle(fontSize: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: const Text('Book Now'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
