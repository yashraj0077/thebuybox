import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:stripe_sdk/stripe_sdk.dart' as stripe_sdk;
import 'package:stripe_sdk/stripe_sdk_ui.dart' as stripe_sdk_ui;

import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../services/services.dart';

class StripeServices {
  stripe_sdk.Stripe? stripe;

  static final StripeServices _instance = StripeServices._internal();

  factory StripeServices() {
    _instance.stripe ??= stripe_sdk.Stripe(
      kStripeConfig['publishableKey'],
    );
    return _instance;
  }

  StripeServices._internal();

  Future<Map<String, dynamic>?> createPaymentIntent({
    required String totalPrice,
    String? currencyCode,
    String? emailAddress,
    String? name,
    required stripe_sdk_ui.StripeCard stripeCard,
  }) async {
    try {
      final paymentMethod =
          await stripe!.api.createPaymentMethodFromCard(stripeCard);
      final clientSecret = await Services().api.createPaymentIntentStripe(
          totalPrice: totalPrice,
          currencyCode: currencyCode,
          emailAddress: emailAddress,
          name: name,
          paymentMethodId: paymentMethod['id']);

      if (clientSecret != null) {
        return await stripe!.api.retrievePaymentIntent(
          clientSecret,
        );
      }
    } catch (e) {
      printLog(e);
      rethrow;
    }
    return null;
  }

  Future<bool> executePayment({
    required String totalPrice,
    String? currencyCode,
    String? emailAddress,
    String? name,
    required stripe_sdk_ui.StripeCard stripeCard,
    required BuildContext context,
  }) async {
    try {
      var paymentIntentRes = await createPaymentIntent(
        totalPrice: totalPrice,
        currencyCode: currencyCode,
        emailAddress: emailAddress,
        name: name,
        stripeCard: stripeCard,
      );

      if (paymentIntentRes == null) {
        return false;
      }

      final String? clientSecret = paymentIntentRes['client_secret'];
      final String? paymentMethodId = paymentIntentRes['payment_method'];

      //3D secure is enable in this card
      if (paymentIntentRes['status'] == 'requires_action') {
        paymentIntentRes = await confirmPayment3DSecure(
            clientSecret!, paymentMethodId, context);
      }
      if (paymentIntentRes?['status'] == 'requires_confirmation') {
        // paymentIntentRes = await stripe!
        //     .confirmPayment(clientSecret!, paymentMethodId: paymentMethodId);
      }

      return paymentIntentRes?['status'] == 'succeeded' ||
          paymentIntentRes?['status'] == 'requires_capture';
    } catch (e, trace) {
      printLog(e);
      printLog(trace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> confirmPayment3DSecure(String clientSecret,
      String? paymentMethodId, BuildContext context) async {
    try {
      await stripe!.confirmPayment(clientSecret, context,
          paymentMethodId: paymentMethodId);
      final paymentIntentRes3dSecure =
          await stripe!.api.retrievePaymentIntent(clientSecret);
      return paymentIntentRes3dSecure;
    } catch (e) {
      printLog(e);
      return null;
    }
  }
}
