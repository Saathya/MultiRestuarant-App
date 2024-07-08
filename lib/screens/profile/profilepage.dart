import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_restaurant_app/pallete.dart';
import 'package:multi_restaurant_app/screens/login/loginui.dart';
import 'package:multi_restaurant_app/screens/mainpage/mainhomepage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? user = FirebaseAuth.instance.currentUser;
  String? displayName;
  String? email;
  String? photoURL;
  String? city;
  String? country;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
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
        }
      } catch (e) {
        print("Error fetching user profile: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const MainHomePage()));
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              isDark ? Icons.wb_sunny : Icons.nightlight_round,
              color: Colors.black,
            ),
          ),
        ],
      ),
      body: user == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _buildUserProfile(),
    );
  }

  Widget _buildUserProfile() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your user data fields here
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              height: 130.0,
              width: 130.0,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: photoURL != null
                      ? NetworkImage(photoURL!)
                      : const NetworkImage(
                          'https://img.freepik.com/free-psd/3d-illustration-person-with-sunglasses_23-2149436188.jpg?w=2000'),
                  fit: BoxFit.cover,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.0),
              ),
            ),

            Text(
              displayName ?? '',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),

            Text(
              email ?? '',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  city ?? '',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const Text(
                  ', ',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  country ?? '',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),

            // Add more user data fields as needed
            const SizedBox(height: 20),

            // Edit Profile Button
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () {
                  // Handle edit profile button press here
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Edit Profile',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Divider
            const Divider(),
            const SizedBox(height: 10),

            // Profile Menu Items
            // Replace with your ProfileMenuWidget items
            ProfileMenuWidget(
              title: "Settings",
              icon: Icons.settings,
              onPress: () {
                // Handle Settings menu item press here
              },
            ),
            ProfileMenuWidget(
              title: "Billing Details",
              icon: Icons.payment,
              onPress: () {
                // Handle Billing Details menu item press here
              },
            ),
            // ProfileMenuWidget(
            //   title: "Admin Login",
            //   icon: Icons.supervised_user_circle,
            //   onPress: () {
            //     // Handle User Management menu item press here
            //     Navigator.pushReplacement(
            //         context,
            //         MaterialPageRoute(
            //             builder: (context) => const SuperAdminLanding()));
            //   },
            // ),

            // Divider
            const Divider(),
            const SizedBox(height: 10),

            // Information and Logout Menu Items
            ProfileMenuWidget(
              title: "Information",
              icon: Icons.info,
              onPress: () {
                // Handle Information menu item press here
              },
            ),
            ProfileMenuWidget(
              title: "Logout",
              icon: Icons.logout,
              textColor: Colors.red,
              endIcon: false,
              onPress: () {
                logout(context);

                // Handle Logout menu item press here
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> logout(BuildContext context) async {
  const CircularProgressIndicator();
  await FirebaseAuth.instance.signOut().then(
        (value) => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginUI(),
            )),
      );
}

class ProfileMenuWidget extends StatelessWidget {
  const ProfileMenuWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.onPress,
    this.endIcon = true,
    this.textColor,
  });

  final String title;
  final IconData icon;
  final VoidCallback onPress;
  final bool endIcon;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    var isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    var iconColor = isDark ? Pallete.gradient1 : Pallete.gradient2;

    return ListTile(
      onTap: onPress,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: iconColor.withOpacity(0.1),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title,
          style:
              Theme.of(context).textTheme.bodyLarge?.apply(color: textColor)),
      trailing: endIcon
          ? Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: Colors.grey.withOpacity(0.1),
              ),
              child: const Icon(Icons.abc, size: 18.0, color: Colors.grey))
          : null,
    );
  }
}
