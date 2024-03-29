import 'dart:convert';

import 'package:coopaz_app/dao/data_access.dart';
import 'package:coopaz_app/logger.dart';
import 'package:coopaz_app/podo/cart_item.dart';
import 'package:coopaz_app/podo/payment_method.dart';
import 'package:http/http.dart' as http;

class OrderDao extends GoogleAppsScriptDao {
  OrderDao(
      {required super.googleAppsScriptUrlApi,
      required super.appsScriptId,
      required super.authManager});

  Future createOrder(String clientMail, List<CartItem> productLines,
      PaymentMethod paymentMethod, String chequeNumber) async {
    var body = {
      "function": "processOrder",
      "parameters": [
        clientMail,
        paymentMethod.asTechnicalString,
        productLines
            .map((p) =>
                {"product": p.product?.designation, "qty": double.tryParse(p.qty ?? '0')})
            .toList(),
        chequeNumber
      ],
      // Set to true work on the last saved Apps Script. Set to false to work only on the last deployed Apps Script.
      "devMode": true
    };

    var bodyJson = jsonEncode(body);
    final response =
        await http.post(Uri.parse('$googleAppsScriptUrlApi/$appsScriptId:run'),
            headers: {
              'Accept': 'application/json',
              'content-type': 'application/json',
              'Authorization': 'Bearer ${await authManager.getAccessToken()}',
            },
            body: bodyJson);

    if (response.statusCode == 200) {
      var body = jsonDecode(response.body);
      log('Response: $body');
    } else {
      log('Failed to call macro: [${response.statusCode}] ${response.body}');
      throw Exception(
          'Failed to load products: [${response.statusCode}] ${response.body}');
    }
  }
}
