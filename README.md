# **MultiRestaurant App**

A multi-restaurant booking application developed with Flutter and Firebase. This app allows users to book tables at nearby restaurants, view restaurant details, and make payments using various methods.

## **Features**

- User authentication with Google and Email/Password
- View and book tables at nearby restaurants
- Display restaurant details, including images, names, ratings, and availability
- Calculate total amounts with GST and discounts
- Payment integration with PhonePe

## **Getting Started**

### **Prerequisites**

- [Flutter](https://flutter.dev/docs/get-started/install) installed on your machine
- [Firebase](https://firebase.google.com/) project set up
- A code editor like [Visual Studio Code](https://code.visualstudio.com/) or [Android Studio](https://developer.android.com/studio)

### **Setup Guide**

1. **Clone the Repository**
   ```sh
   git clone https://github.com/yourusername/multi-restaurant-app.git
   cd multi-restaurant-app

  2. **Create Firebase Project**

  - Go to the Firebase Console.
- Click on Add Project and follow the setup instructions.
- Once the project is created, add an Android app and a Web app.

3. **Enable Authentication Providers**

- In the Firebase Console, navigate to the Authentication menu.
- Click on the Sign-in method tab.
- Enable Google and Email/Password providers.

4 . **Set Up Firestore Database**

- In the Firebase Console, navigate to Firestore Database.
- Click on Create Database and follow the setup instructions.

5. **Configure Firebase in Flutter Project**

- In the Firebase Console, go to Project Settings.
- Locate your app configuration under General.
- Copy the configuration values and replace the placeholders in your Flutter project at lib/firebase_config.dart.
```sh
const firebaseConfig = {
  "apiKey": "your-api-key",
  "authDomain": "your-auth-domain",
  "projectId": "your-project-id",
  "storageBucket": "your-storage-bucket",
  "messagingSenderId": "your-messaging-sender-id",
  "appId": "your-app-id",
  "measurementId": "your-measurement-id"
};
```

6. **Enable Google Maps API and Configure API Key**

- Go to the Google Cloud Console.
- Navigate to your project and enable the Maps SDK for Android.
- Generate an API key and restrict it as needed.
- Add the API key to your AndroidManifest.xml file inside the <application> tag.
```sh
android/app/src/main/AndroidManifest.xml

<application>
    <!-- Other existing meta-data and activities -->
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_API_KEY_HERE" />
</application>
```

7. **Create Firestore Indexes**

- When running the app for the first time, Firestore will output a link in the terminal to create required indexes.
- Copy the link and paste it into your browser.
- Follow the link to the Firestore Indexes page in the Firebase Console.
- Review and enable the suggested indexes to ensure proper app functionality.


8. **Add Payment Gateway API Key**

- If using Razorpay or another payment gateway, obtain an API key.
- Add the API key in your Flutter project under lib/screens/payment.
```sh
// Example of how to add Razorpay API key in your Flutter project

const razorpayApiKey = "YOUR_RAZORPAY_API_KEY";
```
- Ensure the API key is securely stored and accessed as per the payment gateway's guidelines.




9 **Run the Application**

- Connect your device or start an emulator.
- Run the app using the command:
```sh
flutter run
```

## Contributing
Contributions are welcome! Please create a pull request with detailed information about your changes.
 
