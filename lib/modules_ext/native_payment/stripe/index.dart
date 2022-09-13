import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stripe_sdk/stripe_sdk_ui.dart' as stripe_sdk_ui;

import '../../../generated/l10n.dart';
import '../../../models/app_model.dart';
import '../../../models/cart/cart_model.dart';
import '../../../models/entities/credit_card.dart';
import '../../../modules/native_payment/credit_card/index.dart';
import 'services.dart';

class StripePayment extends StatefulWidget {
  final Function? onFinish;

  const StripePayment({
    Key? key,
    this.onFinish,
  }) : super(key: key);

  @override
  StripePaymentState createState() => StripePaymentState();
}

class StripePaymentState extends State<StripePayment> {
  StripeServices services = StripeServices();

  String? cardNumber = '';
  String? cardHolderName = '';
  String? expiryDate = '';
  String? cvv = '';
  bool? showBackView = false;

  bool isChecking = false;

  bool get areFieldsValid =>
      cardHolderName!.isNotEmpty &&
      cvv!.isNotEmpty &&
      expiryDate!.isNotEmpty &&
      cardNumber!.isNotEmpty;

  String formatPrice(String price) {
    final formatCurrency = NumberFormat.currency(symbol: '', decimalDigits: 1);
    var number = '';
    number = formatCurrency.format(price.isNotEmpty ? double.parse(price) : 0);
    return number;
  }

  Future<void> handlePayment(BuildContext context) async {
    setState(() {
      isChecking = true;
    });

    var cartModel = Provider.of<CartModel>(context, listen: false);
    final totalPrice = cartModel.getTotal()!;

    final appModel = Provider.of<AppModel>(context, listen: false);
    final currencyCode = appModel.currencyCode;
    final smallestUnitRate = appModel.smallestUnitRate ?? 1;

    var result = false;
    try {
      final expDate = expiryDate!.split('/');
      result = await services.executePayment(
        totalPrice: (totalPrice * smallestUnitRate).round().toStringAsFixed(0),
        currencyCode: currencyCode,
        emailAddress: cartModel.address?.email,
        name: cardHolderName,
        stripeCard: stripe_sdk_ui.StripeCard(
          expMonth: int.parse(expDate.first),
          expYear: int.parse(expDate.last),
          number: cardNumber,
          cvc: cvv,
        ),
        context: context,
      );

      if (result == true && widget.onFinish != null) {
        widget.onFinish!(result);
        Navigator.of(context).pop();
      }

      if (result == false) {
        final snackbar = SnackBar(
          content: Text(S.of(context).transactionCancelled),
        );

        ScaffoldMessenger.of(context).showSnackBar(snackbar);
      }
    } catch (err) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(S.of(context).orderStatusFailed),
            content: Text('$err'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  S.of(context).ok,
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              )
            ],
          );
        },
      );
      return;
    } finally {
      setState(() {
        isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleAndroidBack,
      child: Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).backgroundColor,
          leading: GestureDetector(
            onTap: () {
              widget.onFinish!(null);
              Navigator.pop(context);
            },
            child: const Icon(Icons.arrow_back_ios),
          ),
          title: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  S.of(context).payment,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).primaryTextTheme.headline6
                      : Theme.of(context).textTheme.headline6,
                ),
              ),
              Builder(builder: (BuildContext context) {
                return ButtonTheme(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0)),
                  child: ElevatedButton(
                    onPressed:
                        areFieldsValid ? () => handlePayment(context) : null,
                    child: isChecking
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                            ),
                          )
                        : Text(
                            S.of(context).checkout,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                );
              }),
            ],
          ),
        ),
        body: GestureDetector(
          onTap: () {
            final focus = FocusScope.of(context);
            if (!focus.hasPrimaryFocus) {
              focus.unfocus();
            }
          },
          child: SafeArea(
            child: Column(
              children: [
                CreditCardWidget(
                  cardBgColor: Theme.of(context).primaryColor,
                  expiryDate: expiryDate,
                  cardHolderName: cardHolderName,
                  cardNumber: cardNumber!,
                  cvvCode: cvv,
                  showBackView: showBackView!,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: CreditCardForm(
                      textColor: Theme.of(context).textTheme.bodyText2!.color,
                      themeColor: Theme.of(context).primaryColor,
                      onCreditCardModelChange: (CreditCard? model) {
                        setState(() {
                          cardNumber = model!.cardNumber;
                          cardHolderName = model.cardHolderName;
                          cvv = model.cvv;
                          expiryDate = model.expiryDate;
                          showBackView = model.isCvvFocused;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _handleAndroidBack() async {
    widget.onFinish!(null);
    return true;
  }
}
