import 'dart:convert' as convert;
import 'package:inspireui/utils/logs.dart';
import 'package:quiver/strings.dart';

import '../../../services/services.dart';
import '../models/plan.dart';

class MembershipServices {
  final domain = Services().api.domain;
  
  Future<List<Plan>> getPlans() async {
    try {
      var list = <Plan>[];
      var response = await httpGet(
          Uri.parse('$domain/wp-json/api/flutter_membership/plans'));
      var jsonDecode = convert.jsonDecode(response.body);
      if (jsonDecode is Map && isNotBlank(jsonDecode['message'])) {
        throw Exception(jsonDecode['message']);
      } else {
        for (var item in jsonDecode) {
          list.add(Plan.fromJson(item));
        }
        return list;
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPayments() async {
    try {
      var response = await httpGet(
          Uri.parse('$domain/wp-json/api/flutter_membership/payments'));
      var jsonDecode = convert.jsonDecode(response.body);
      if (jsonDecode is Map && isNotBlank(jsonDecode['message'])) {
        throw Exception(jsonDecode['message']);
      } else {
        return jsonDecode;
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  Future<Map<String, dynamic>> signUp(
      {username,
      email,
      firstName,
      lastName,
      password,
      selectedPayment,
      planId}) async {
    try {
      var response = await httpPost(
          Uri.parse('$domain/wp-json/api/flutter_membership/register'),
          body: convert.jsonEncode({
            'user_login': username,
            'user_email': email,
            'first_name': firstName,
            'last_name': lastName,
            'pass1': password,
            'pass2': password,
            'tos': '1',
            'ihc_payment_gateway_radio': selectedPayment,
            'ihc_payment_gateway': selectedPayment,
            'ihcaction': 'register',
            'lid': planId,
            'ihcFormType': 'register'
          }),
          headers: {'Content-Type': 'application/json'});
      var jsonDecode = convert.jsonDecode(response.body);
      if (jsonDecode is Map && isNotBlank(jsonDecode['message'])) {
        throw Exception(jsonDecode['message']);
      } else {
        return jsonDecode;
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }
}
