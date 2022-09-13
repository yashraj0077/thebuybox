import 'dart:async';
import 'dart:convert' as convert;

import '../../../common/config.dart';
import '../../../common/constants.dart';

class TapServices {
  Future<String?> getCheckoutUrl(params) async {
    try {
      var response = await httpPost(
        'https://api.tap.company/v2/charges'.toUri()!,
        body: convert.jsonEncode(params),
        headers: {
          'content-type': 'application/json',
          'Authorization': 'Bearer ${kTapConfig['SecretKey']}'
        },
      );

      final body = convert.jsonDecode(response.body);
      if (response.statusCode == 200) {
        return body['transaction'] != null ? body['transaction']['url'] : null;
      } else if (body['errors'] != null) {
        var errors = List<Map<String, dynamic>>.from(body['errors']);
        if (errors.isNotEmpty) {
          throw errors[0]['description'];
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
