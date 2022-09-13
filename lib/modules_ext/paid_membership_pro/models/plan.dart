class Plan {
  final dynamic id;
  final String? name;
  final String? description;
  final String? cost;
  final double initialPayment;
  final bool? isFree;

  Plan(
      {this.id,
      this.name,
      this.description,
      this.cost,
      this.initialPayment = 0.0,
      this.isFree = false});

  factory Plan.fromJson(Map<String, dynamic> parsedJson) => Plan(
      id: parsedJson['id'].toString(),
      name: parsedJson['name'],
      cost: parsedJson['cost_text'],
      description: parsedJson['description'],
      initialPayment:
          double.tryParse('${parsedJson['initial_payment']}') != null
              ? double.parse('${parsedJson['initial_payment']}')
              : 0.0,isFree: parsedJson['is_free_level'] as bool?);
}
