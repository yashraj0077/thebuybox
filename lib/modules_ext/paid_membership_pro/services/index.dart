import 'dart:convert' as convert;

import 'package:inspireui/utils/logs.dart';
import 'package:quiver/strings.dart';

import '../../../services/services.dart';
import '../models/invoice.dart';
import '../models/plan.dart';

class PaidMembershipProServices {
  final domain = Services().api.domain;
  Future<List<Plan>> getPlans() async {
    try {
      var list = <Plan>[];
      var response = await httpGet(
          Uri.parse('$domain/wp-json/api/flutter_paid_memberships_pro/plans'));
      var jsonDecode = convert.jsonDecode(response.body);
      if (jsonDecode is Map && isNotBlank(jsonDecode['message'])) {
        throw jsonDecode['message'];
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

  Future<Invoice> signUp(
      {required String username,
      required String email,
      required String firstName,
      required String lastName,
      required String password,
       String? cardNumber,
       String? expiryDate,
       String? cvv,
      required Plan plan}) async {
    try {
      final expDate = expiryDate?.split('/');
      var bodyReq = {
        'username': username,
        'email': email,
        'firstname': firstName,
        'lastname': lastName,
        'password': password,

        'plan': plan.id
      };
      if(plan.isFree == false){
        bodyReq['card'] =  {
          'number': cardNumber,
          'exp_month': expDate?.first,
          'exp_year': expDate?.last,
          'cvc': cvv
        };
      }

      var response = await httpPost(
          Uri.parse(
              '$domain/wp-json/api/flutter_paid_memberships_pro/register'),
          body: convert.jsonEncode(bodyReq),
          headers: {'Content-Type': 'application/json'});
      var jsonDecode = convert.jsonDecode(response.body);
      if (jsonDecode is Map && isNotBlank(jsonDecode['message'])) {
        throw Exception(jsonDecode['message']);
      } else {
        return Invoice.fromJson(jsonDecode['invoice'],
            confirmMessage: jsonDecode['confirmation_message']);
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }
}
