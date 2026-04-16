import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'week4_payment_config.dart';

class PaymentService {
  /// Calls the backend Cloud Function to create a Midtrans Snap transaction.
  /// Returns the JSON response from the backend which includes `orderId` and `redirect_url`.
  static Future<Map<String, dynamic>> createMidtransTransaction({
    required String campaignId,
    required int amount,
  }) async {
    if (functionsBaseUrl.isEmpty) {
      throw Exception(
        'Payment backend not configured (functionsBaseUrl is empty)',
      );
    }

    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) throw Exception('Not authenticated');

    final url = Uri.parse('$functionsBaseUrl/createMidtransTransaction');
    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'campaignId': campaignId, 'amount': amount}),
    );

    if (resp.statusCode != 200) {
      throw Exception('Payment backend error: ${resp.statusCode} ${resp.body}');
    }

    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}
