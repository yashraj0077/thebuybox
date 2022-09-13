import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../services/services.dart';

export 'package:flutter_stripe/flutter_stripe.dart';

class StripeServicesV2 {
  bool _initialized = false;

  static final StripeServicesV2 _instance = StripeServicesV2._internal();

  factory StripeServicesV2() => _instance;

  StripeServicesV2._internal();

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    Stripe.publishableKey = kStripeConfig['publishableKey'];
    Stripe.merchantIdentifier = kStripeConfig['merchantIdentifier'] ??
        'merchant.com.inspireui.mstore.flutter';
    Stripe.urlScheme =
        '${kStripeConfig['returnUrl'] ?? 'fluxstore://'}'.split('://').first;
    await Stripe.instance.applySettings();
    _initialized = true;
  }

  Future<bool> handlePayment({
    required String orderId,
    required String totalPrice,
    required String currencyCode,
    required String emailAddress,
    required String name,
    Color? color,
    bool darkMode = false,
    bool useApplePay = false,
    bool useGooglePay = false,
    String applePayPrice = '0',
  }) async {
    try {
      await init();
      final isTestEnv =
          !('${kStripeConfig['publishableKey']}'.startsWith('pk_live'));

      var paymentIntentClientSecret;
      if (!useApplePay) {
        paymentIntentClientSecret = await getClientSecret(
          totalPrice: totalPrice,
          currencyCode: currencyCode,
          emailAddress: emailAddress,
          name: name,
          orderId: orderId,
        );
      }

      if (!useApplePay && paymentIntentClientSecret == null) {
        return false;
      }

      if (useApplePay && (await Stripe.instance.checkApplePaySupport())) {
        await Stripe.instance.presentApplePay(
          ApplePayPresentParams(
            cartItems: [
              ApplePayCartSummaryItem.immediate(
                label: kStripeConfig['merchantDisplayName'],
                amount: applePayPrice,
                isPending: false,
              ),
            ],
            country: kStripeConfig['merchantCountryCode'] ?? 'US',
            currency: currencyCode,
            requiredBillingContactFields: [
              ApplePayContactFieldsType.name,
              ApplePayContactFieldsType.emailAddress,
            ],
          ),
        );

        paymentIntentClientSecret = await getClientSecret(
          totalPrice: totalPrice,
          currencyCode: currencyCode,
          emailAddress: emailAddress,
          name: name,
          orderId: orderId,
        );

        if (paymentIntentClientSecret == null) {
          return false;
        }

        await Stripe.instance.confirmApplePayPayment(paymentIntentClientSecret);
        return true;
      }

      if (useGooglePay &&
          (await Stripe.instance.isGooglePaySupported(
            IsGooglePaySupportedParams(
              testEnv: isTestEnv,
              existingPaymentMethodRequired: false,
            ),
          ))) {
        await Stripe.instance.initGooglePay(
          GooglePayInitParams(
            merchantName: kStripeConfig['merchantDisplayName'],
            countryCode: kStripeConfig['merchantCountryCode'] ?? 'US',
            isEmailRequired: true,
            testEnv: isTestEnv,
            existingPaymentMethodRequired: false,
          ),
        );
        final param = PresentGooglePayParams(
          currencyCode: currencyCode,
          clientSecret: paymentIntentClientSecret,
        );
        await Stripe.instance.presentGooglePay(param);
        return true;
      }

      final billingDetails = BillingDetails(
        email: emailAddress,
        name: name,
      );

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          merchantDisplayName: kStripeConfig['merchantDisplayName'],
          returnURL: kStripeConfig['returnUrl'],
          style: darkMode ? ThemeMode.dark : ThemeMode.light,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: color,
            ),
            primaryButton: PaymentSheetPrimaryButtonAppearance(
              colors: PaymentSheetPrimaryButtonTheme(
                light: PaymentSheetPrimaryButtonThemeColors(
                  background: color,
                ),
                dark: PaymentSheetPrimaryButtonThemeColors(
                  background: color,
                ),
              ),
            ),
          ),
          billingDetails: billingDetails,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      return true;
    } catch (err, trace) {
      printLog(err);
      printLog(trace);
      rethrow;
    }
  }

  Future<String?> getClientSecret({
    required String totalPrice,
    required String currencyCode,
    required String emailAddress,
    required String name,
    required String orderId,
  }) async {
    try {
      final clientSecret = await Services().api.createPaymentIntentStripeV3(
            totalPrice: totalPrice,
            currencyCode: currencyCode,
            emailAddress: emailAddress,
            name: name,
            orderId: orderId,
          );

      return clientSecret;
    } catch (e) {
      printLog(e);
      rethrow;
    }
  }
}
