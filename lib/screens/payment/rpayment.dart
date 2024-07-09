// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_web/razorpay_web.dart';

class PaymentPage extends StatefulWidget {
  final double totalAmount;
  const PaymentPage({super.key, required this.totalAmount});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Razorpay _razorpay;
  User? user = FirebaseAuth.instance.currentUser;
  String? displayName;
  String? email;
  String? photoURL;
  String? city;
  String? country;
  final TextEditingController _razorpayKeyController = TextEditingController();
  bool _isValidKey = true;
  String razorpayKey = '';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    fetchUserProfile();
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
    _razorpayKeyController.dispose();
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

  String generateTransactionId() {
    int min = pow(4, 4).toInt();
    int max = pow(4, 5).toInt() - 1;
    int randomNumber = Random().nextInt(max - min + 1) + min;
    String transactionId = 'ease_${randomNumber.toString().padLeft(4, '0')}';
    return transactionId;
  }

  void openCheckout(double totalAmount, String selectedPaymentMethod) async {
    Map<String, dynamic> method = {};

    switch (selectedPaymentMethod) {
      case 'NetBanking':
        method = {
          'netbanking': true,
          'upi': false,
          'card': false,
          'external': {'wallets': []},
          'wallet': false
        };
        break;
      case 'UPI':
        method = {
          'upi': true,
          'card': false,
          'netbanking': false,
          'external': {'wallets': []},
          'wallet': false
        };
        break;
      case 'Card':
        method = {
          'upi': false,
          'netbanking': false,
          'card': true,
          'external': {'wallets': []},
          'wallet': false
        };
        break;
      case 'ExternalWallets':
        method = {
          'wallet': true,
          'upi': false,
          'netbanking': false,
          'card': false,
          'external': {
            'wallets': ['paytm']
          }
        };
        break;
    }

    if (totalAmount < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid amount. Amount must be at least Rs. 1.'),
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(
            'https://us-central1-crm-fdffe.cloudfunctions.net/api/create_order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': totalAmount}),
      );

      if (response.statusCode == 200) {
        var orderData = jsonDecode(response.body);
        var options = {
          'key': razorpayKey,
          'order_id': orderData['order_id'],
          'amount': (totalAmount * 100).toInt(),
          'name': 'Ease My Deal',
          'description': 'Inditab Esolutions Private Limited ',
          'send_sms_hash': true,
          'prefill': {'contact': '9999999999', 'email': email},
          'method': method,
        };

        _razorpay.open(options);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating order: ${response.statusCode}'),
          ),
        );
        print('Error creating order: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print('Payment successful: ${response.paymentId}');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    developer.log('Error Response: $response');
    Fluttertoast.showToast(
      msg: "ERROR: ${response.code} - ${response.message}",
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    developer.log('External SDK Response: $response');
    Fluttertoast.showToast(
      msg: "EXTERNAL_WALLET: ${response.walletName!}",
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  Future<void> _showPaymentMethodDialog(BuildContext context) async {
    String? selectedMethod = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Payment Method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop('NetBanking');
                },
                child: const Text('NetBanking'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop('UPI');
                },
                child: const Text('UPI'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop('Card');
                },
                child: const Text('Card'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop('ExternalWallets');
                },
                child: const Text('ExternalWallets'),
              ),
            ],
          ),
        );
      },
    );

    if (selectedMethod != null) {
      Future.microtask(() {
        if (_isValidKey) {
          openCheckout(widget.totalAmount, selectedMethod);
        } else {
          Fluttertoast.showToast(
            msg: "Invalid Razorpay key.",
            toastLength: Toast.LENGTH_SHORT,
          );
        }
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showRazorpayKeyDialog(BuildContext context) async {
    String? enteredKey = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Razorpay Key'),
          content: TextField(
            controller: _razorpayKeyController,
            decoration: InputDecoration(
              hintText: 'Enter your Razorpay key',
              errorText: _isValidKey ? null : 'Invalid Razorpay key',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // User canceled the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String key = _razorpayKeyController.text.trim();
                if (key.isNotEmpty) {
                  Navigator.of(context).pop(key); // Return the entered key
                } else {
                  setState(() {
                    _isValidKey = false; // Show error message
                  });
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (enteredKey != null) {
      setState(() {
        _isValidKey = true;
        razorpayKey = enteredKey;
        _showPaymentMethodDialog(context);
      });
    } else {
      Fluttertoast.showToast(
        msg: "Please enter a valid Razorpay key.",
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _showRazorpayKeyDialog(context);
          },
          child: const Text('Proceed to Payment'),
        ),
      ),
    );
  }
}
