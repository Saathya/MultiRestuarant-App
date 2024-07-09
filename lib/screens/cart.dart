// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:multi_restaurant_app/model/nearby_restaurant_model.dart';
import 'package:multi_restaurant_app/screens/payment/rpayment.dart';

class CartScreen extends StatefulWidget {
  final Restaurant selectedRestaurant;

  const CartScreen({super.key, required this.selectedRestaurant});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  int _numberOfPersons = 2; // Initial number of persons

  void _incrementPersons() {
    setState(() {
      _numberOfPersons++;
    });
  }

  void _decrementPersons() {
    setState(() {
      if (_numberOfPersons > 1) {
        _numberOfPersons--;
      }
    });
  }

  double totalAmount = 0.0;
  String tableno = '';

  String generateTbaleNO() {
    int min = 10; // Minimum value for 2-digit number
    int max = 99; // Maximum value for 2-digit number
    int randomNumber = Random().nextInt(max - min + 1) + min;
    return 'Table No.${randomNumber.toString()}';
  }

  // Function to calculate total amount
  double calculateTotal() {
    double averagePrice = widget.selectedRestaurant.averagePricePerPerson;
    double gst = 0.18; // 18% GST
    double discount = 0.05; // 5% discount

    // Calculate total before applying discount and GST
    double totalBeforeDiscount = _numberOfPersons * averagePrice;

    // Apply discount
    double discountedAmount = totalBeforeDiscount * discount;
    double amountAfterDiscount = totalBeforeDiscount - discountedAmount;

    // Apply GST
    double gstAmount = amountAfterDiscount * gst;
    totalAmount = amountAfterDiscount + gstAmount;

    return totalAmount;
  }

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to check if the user has already booked the same restaurant today
  Future<bool> hasUserBookedToday(String userId, String restaurantName) async {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    QuerySnapshot querySnapshot = await _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('restaurantName', isEqualTo: restaurantName)
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThanOrEqualTo: endOfDay)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  // Function to save booking details
  Future<void> saveBooking() async {
    try {
      // Start loading indicator
      EasyLoading.show(
          status: 'Please wait...', maskType: EasyLoadingMaskType.black);

      // Fetch user data if available
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      // Check if user has already booked the same restaurant today
      bool hasBookedToday =
          await hasUserBookedToday(userId, widget.selectedRestaurant.name);

      if (hasBookedToday) {
        // Dismiss loading indicator
        EasyLoading.dismiss();

        // Show error dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Booking Not Allowed'),
              content:
                  const Text('You have already booked this restaurant today.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                ),
              ],
            );
          },
        );
        return; // Exit the function if booking is not allowed
      }

      // Save booking details to Firestore
      await _firestore.collection('bookings').add({
        'restaurantName': widget.selectedRestaurant.name,
        'restaurantAddress': widget.selectedRestaurant.address,
        'restaurantImage': widget.selectedRestaurant.imageUrl,
        'userId': userId,
        'numberOfPersons': _numberOfPersons,
        'status': true,
        'table': generateTbaleNO(),
        'totalAmount': (calculateTotal() * 0.95 * 1.18).toStringAsFixed(2),
        'timestamp': FieldValue.serverTimestamp(),
        // Add other relevant fields as needed
      });

      // Dismiss loading indicator
      EasyLoading.dismiss();

      // Show AlertDialog for booking confirmation
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Booking Confirmed!'),
            content: const Text('Your booking has been confirmed.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.of(context).pop(); // Pop the BookingPage
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Dismiss loading indicator on error
      EasyLoading.dismiss();

      // Handle error
      print('Error saving booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving booking: $e')),
      );
    }
  }

  Future<void> _showBookingDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Choose Booking Option'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Do you want to book with or without payment?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Book Now Without Payment'),
              onPressed: () {
                Navigator.of(context).pop();
                _saveBookingWithoutPayment();
              },
            ),
            TextButton(
              child: const Text('Book Now With Payment'),
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToPaymentPage(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToPaymentPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(totalAmount: totalAmount),
      ),
    );
  }

  Future<void> _saveBookingWithoutPayment() async {
    // Function to save booking details to Firestore as before
    await saveBooking();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Book Your Table',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            width: double.infinity,
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
                    widget.selectedRestaurant.imageUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.selectedRestaurant.name,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.selectedRestaurant.ratings}',
                                style: const TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.selectedRestaurant.address,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${widget.selectedRestaurant.priceRange} ${widget.selectedRestaurant.averagePricePerPerson}"
                            .toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: _decrementPersons,
                            icon: const Icon(Icons.remove),
                            padding: EdgeInsets.zero,
                            color: Colors.black,
                          ),
                          Text(
                            '$_numberOfPersons',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black),
                          ),
                          IconButton(
                            onPressed: _incrementPersons,
                            icon: const Icon(Icons.add),
                            padding: EdgeInsets.zero,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // New Container for total amount, GST, discount, and total
          Container(
            padding: const EdgeInsets.all(16.0),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      "${widget.selectedRestaurant.priceRange} ${calculateTotal().toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'GST (18%)',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      "${widget.selectedRestaurant.priceRange} ${(calculateTotal() * 0.18).toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Discount (5%)',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      "${widget.selectedRestaurant.priceRange}${(calculateTotal() * 0.05).toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Grand Total',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      "${widget.selectedRestaurant.priceRange} ${(calculateTotal() * 0.95 * 1.18).toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: FloatingActionButton.extended(
          onPressed: () async {
            // Save booking details to Firestore
            _showBookingDialog(context);
            // Initiate payment process (e.g., start transaction with PhonePe)
          },
          icon: const Icon(Icons.book_outlined),
          label: const Text('Book Now'),
          backgroundColor: Colors.red, // Change background color to red
          foregroundColor: Colors.white, // Change text color to white
        ),
      ),
    );
  }
}
