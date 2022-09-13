import 'package:inspireui/utils/logs.dart';

class Plan {
  dynamic id;
  String? name;
  String? label;
  String? description;
  String? price;

  Plan.fromJson(Map<String, dynamic> parsedJson) {
    try {
      id = parsedJson['id'].toString();
      name = parsedJson['name'];
      label = parsedJson['label'];
      description = parsedJson['description'];
      price = parsedJson['price'] ?? '0';
    } catch (e, trace) {
      printLog(trace);
    }
  }
}
