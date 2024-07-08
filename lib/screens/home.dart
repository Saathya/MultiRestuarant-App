import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:multi_restaurant_app/screens/profile/profilepage.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
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
        }
      } catch (e) {
        print("Error fetching user profile: $e");
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _location.onLocationChanged.listen((loc.LocationData currentLocation) {
      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target:
                LatLng(currentLocation.latitude!, currentLocation.longitude!),
            zoom: 15.0,
          ),
        ),
      );
      _updateUserLocation(
          currentLocation.latitude!, currentLocation.longitude!);
    });

    fetchUserProfile();
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

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: _kGooglePlex,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            top: 50,
            left: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfilePage(),
                  ),
                );
              },
              child: CircleAvatar(
                backgroundImage: NetworkImage(
                  photoURL ??
                      'https://img.freepik.com/free-psd/3d-illustration-human-avatar-profile_23-2150671142.jpg?t=st=1720343478~exp=1720347078~hmac=23eacdd0e71bbc7b20ce6c6032432bf694553fd0d8d184ec2f0f2aa5c15cb5a8&w=740',
                ),
                radius: 25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
