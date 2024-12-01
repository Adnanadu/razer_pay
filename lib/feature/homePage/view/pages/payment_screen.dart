import 'dart:convert';
import 'dart:developer';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:razer_pay_test/env/env.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:uuid/uuid.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _amountController = TextEditingController();
  final _razorpay = Razorpay();
  late String uuid;
  final baseUrl = 'https://api.razorpay.com/v1/orders';

  Future<void> payAmount() async {
    await doPayment(Env.razerKey);
  }

  Future<dynamic> createOrder() async {
    final amount = int.parse(_amountController.text);
    final dio = Dio();
    uuid = const Uuid().v4();
    final String razerKey = Env.razerKey;
    final String secretKey = Env.secretKey;

    try {
      final response = await dio.post(
        baseUrl,
        options: Options(
          contentType: 'application/json',
          headers: {
            // rzp_test_Ye95J2G7yZUg0R
            'Authorization':
                'Basic ${base64.encode(utf8.encode('$razerKey:$secretKey'))}',
          },
        ),
        data: jsonEncode({
          "amount": (100 * amount),
          "currency": "INR",
          "receipt": uuid,
        }),
      );
      return response.data;
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> doPayment(String razerKey) async {
    final orderData = await createOrder();
    var options = {
      'key': razerKey,
      'amount': orderData['amount'],
      'name': 'Levelx',
      'order_id': '${orderData['id']}',
      'description': 'Chair',
      'timeout': 60 * 2
    };
    _razorpay.open(options);
  }

  void _handlePaymentSuccess(
      PaymentSuccessResponse response, String secretKey) {
    final keySecret = utf8.encode(secretKey);
    final bytes = utf8.encode('${response.orderId}|${response.paymentId}');
    final hmacSha256 = Hmac(sha256, keySecret);
    final generatedSignature = hmacSha256.convert(bytes);
    if (generatedSignature.toString() == response.signature) {
      log('Payment successful');

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Success : payment successful"),
            // content: const Text("Are you sure you wish to delete this item?"),
            actions: <Widget>[
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // PlaceOrderPrepaid();
                  },
                  child: const Text("OK"))
              // ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Success : payment Failed"),
            // content: const Text("Are you sure you wish to delete this item?"),
            actions: <Widget>[
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // PlaceOrderPrepaid();
                  },
                  child: const Text("OK"))
              // ),
            ],
          );
        },
      );
    }
  }

  /// Handle payment error

  void _handlePaymentError(PaymentFailureResponse response) {
    log("Payment error :${response.message}");
  }

  /// Handle external wallet
  /// Like Paytm, PhonePe, Google Pay, etc.
  void _handleExternalWallet(ExternalWalletResponse response) {
    log("${response.walletName} opend");
  }

  /// Initialize the Razorpay object
  /// Add the event listeners

  @override
  void initState() {
    super.initState();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Clear the object when the widget is disposed
  @override
  void dispose() {
    super.dispose();
    // _razorpay.clear();
    _amountController.dispose();
  }

  /// Build the UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Center(
          child: TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(
              hintText: 'Amount',
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => payAmount(),
        child: const Icon(Icons.payment),
      ),
    );
  }
}
