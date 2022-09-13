class Invoice {
  final dynamic id;
  final String? code;
  final String? accountNumber;
  final String? cardType;
  final String? expirationMonth;
  final String? expirationYear;
  final double total;
  final String? confirmMessage;
  final String? username;
  final String? email;
  final String? membershipLevel;

  Invoice(
      {this.id,
      this.code,
      this.accountNumber,
      this.cardType,
      this.expirationMonth,
      this.expirationYear,
      this.total = 0.0,
      this.confirmMessage,
      this.username,
      this.email,
      this.membershipLevel});

  factory Invoice.fromJson(Map<String, dynamic> parsedJson,
          {String? confirmMessage}) =>
      Invoice(
          id: parsedJson['id'].toString(),
          code: parsedJson['code'],
          accountNumber: parsedJson['accountnumber'],
          cardType: parsedJson['cardtype'],
          expirationMonth: parsedJson['expirationmonth'],
          expirationYear: parsedJson['expirationyear'],
          total: double.tryParse('${parsedJson['total']}') != null
              ? double.parse('${parsedJson['total']}')
              : 0.0,
          confirmMessage: confirmMessage,
          username: parsedJson['user']['user_nicename'],
          email: parsedJson['user']['user_email'],
          membershipLevel: parsedJson['membership_level']['name']);
}
