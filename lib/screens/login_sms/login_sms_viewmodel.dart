import 'dart:async';

import 'package:flutter/material.dart';

import '../../modules/firebase/firebase_service.dart';

class LoginSmsViewModel extends ChangeNotifier {
  final FirebaseServices _firebaseServices;
  late final StreamController _verifySuccessStream;

  String? _code;
  String? _dialCode;
  String? _name;
  String? _phone;
  var _isLoading = false;

  LoginSmsViewModel(this._firebaseServices)
      : _verifySuccessStream = _firebaseServices.getFirebaseStream();

  bool get isLoading => _isLoading;
  String? get countryCode => _code;
  String? get countryName => _name;
  String? get countryDialCode => _dialCode;
  String get phoneFullText => '${_dialCode ?? ''}${_phone ?? ''}';
  String get phoneNumber => _phone ?? '';
  Stream get getStreamSuccess => _verifySuccessStream.stream;

  void loadConfig({
    String? code,
    String? dialCode,
    String? name,
  }) {
    _code ??= (code?.isEmpty ?? true) ? null : code;
    _dialCode ??= (dialCode?.isEmpty ?? true) ? null : dialCode;
    _name ??= (name?.isEmpty ?? true) ? null : name;
  }

  void updateCountryCode({
    String? code,
    String? dialCode,
    String? name,
  }) {
    loadConfig(code: code, dialCode: dialCode, name: name);
    notifyListeners();
  }

  void enableLoading([bool isEnable = true]) {
    _isLoading = isEnable;
    notifyListeners();
  }

  Future<void> verify({
    required Future Function(String verId, [int? forceCodeResend]) smsCodeSent,
    required Future Function(String verId) autoRetrieve,
    required Future Function() startVerify,
    required Function(dynamic exception) verifyFailed,
  }) async {
    if (_isLoading) {
      return;
    }

    await startVerify();

    _firebaseServices.verifyPhoneNumber(
      phoneNumber: phoneFullText,
      codeAutoRetrievalTimeout: autoRetrieve,
      verificationCompleted: _verifySuccessStream.add,
      verificationFailed: verifyFailed,
      codeSent: smsCodeSent,
    );
  }

  void updatePhone(String phoneNumber) {
    if (_phone != phoneNumber) {
      _phone = phoneNumber;
    }
  }
}
