import 'dart:io';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfatoorah_flutter/embeddedapplepay/MFApplePayButton.dart';
import 'package:myfatoorah_flutter/myfatoorah_flutter.dart';
import 'package:myfatoorah_flutter/utils/MFEnvironment.dart';

import '../../../common/config.dart';
import '../../../common/tools/image_tools.dart';
import '../../../generated/l10n.dart';
import '../../../models/entities/credit_card.dart';
import '../../../modules/native_payment/credit_card/credit_card_form.dart';
import 'utils.dart';

class MyFatoorahScreen extends StatefulWidget {
  const MyFatoorahScreen({Key? key, required this.amount, required this.customerName, required this.onFinish, this.currency}) : super(key: key);
  final double amount;
  final String customerName;
  final String? currency;
  final Function(String?) onFinish;

  @override
  State<MyFatoorahScreen> createState() => _MyFatoorahScreenState();
}

class _MyFatoorahScreenState extends State<MyFatoorahScreen> {

  final List<PaymentMethods> _paymentMethods = [];
  PaymentMethods? _selectedPaymentMethod;

  bool _isLoading = true;
  bool _isPaying = false;

  String cardNumber = '';
  String expiryMonth = '';
  String expiryYear = '';
  String securityCode = '';
  String cardHolderName = '';

  late MFPaymentCardView mfPaymentCardView;
  late MFApplePayButton mfApplePayButton;

  @override
  void initState() {
    super.initState();

    MFSDK.init(kMyFatoorahConfig['apiToken'], MFUtils.getMFCountryByCountryCode(kMyFatoorahConfig['accountCountry']), kMyFatoorahConfig['production'] == true ? MFEnvironment.LIVE : MFEnvironment.TEST);

    initiatePayment();
    initiateSession();
  }

  void initiatePayment() {
    var request = MFInitiatePaymentRequest(
        widget.amount, widget.currency?.toUpperCase() ?? MFCurrencyISO.UNITED_STATE_USD);

    MFSDK.initiatePayment(
        request,
        MFAPILanguage.EN,
            (MFResult<MFInitiatePaymentResponse> result) {
          setState((){
            _isLoading = false;
          });
          if (result.isSuccess()){
              setState(() {
                _paymentMethods.addAll(result.response?.paymentMethods ?? []);
                _selectedPaymentMethod = null;
              });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error?.message ?? '')));
          }
        });
  }


  void executeRegularPayment(int? paymentMethodId) {
    var request =
    MFExecutePaymentRequest(paymentMethodId ?? 0, widget.amount);
    request.displayCurrencyIso = widget.currency?.toUpperCase() ?? MFCurrencyISO.UNITED_STATE_USD;

    setState(() {
      _isPaying = true;
    });
    MFSDK.executePayment(
        context,
        request,
        MFAPILanguage.EN,
        onInvoiceCreated: (String invoiceId) =>
        {

        },
        onPaymentResponse: (String invoiceId,
            MFResult<MFPaymentStatusResponse> result)
        {
          setState(() {
            _isPaying = false;
          });
          if (!result.isSuccess() && result.error?.code != 106){
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error?.message ?? '')));
          }
          if(result.isSuccess()){
            Navigator.pop(context);
            widget.onFinish(invoiceId);
          }
        });
  }


  void executeDirectPayment(int? paymentMethodId) {
    var request =
    MFExecutePaymentRequest(paymentMethodId ?? 0, widget.amount);

    setState(() {
      _isPaying = true;
    });

    var mfCardInfo = MFCardInfo(
        cardNumber: cardNumber,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        securityCode: securityCode,
        cardHolderName: cardHolderName,
        bypass3DS: false,
        saveToken: false);

    MFSDK.executeDirectPayment(
        context,
        request,
        mfCardInfo,
        MFAPILanguage.EN,
            (String invoiceId, MFResult<MFDirectPaymentResponse> result)  {
              setState(() {
                _isPaying = false;
              });
              if (!result.isSuccess() && result.error?.code != 106){
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error?.message ?? '')));
              }
              if(result.isSuccess()){
                Navigator.pop(context);
                widget.onFinish(invoiceId);
              }
        });
  }

  void pay() {
      if (_selectedPaymentMethod?.isDirectPayment == true) {
        if (cardNumber.isEmpty ||
            expiryMonth.isEmpty ||
            expiryYear.isEmpty ||
            securityCode.isEmpty){
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).pleaseInputFillAllFields)));
        }else{
            executeDirectPayment(
                _selectedPaymentMethod?.paymentMethodId);
        }
      } else {
          executeRegularPayment(
              _selectedPaymentMethod?.paymentMethodId);
      }
  }

  void initiateSession() {
    MFSDK.initiateSession(null, (MFResult<MFInitiateSessionResponse> result) => {
      if (result.isSuccess())
        {
          mfPaymentCardView.load(result.response!)

          /// This for Apple pay button
          // if(Platform.isIOS)
          //   loadApplePay(result.response)
        }
    });
  }

  void loadApplePay(MFInitiateSessionResponse mfInitiateSessionResponse) {
    var request = MFExecutePaymentRequest.constructorForApplyPay(
        0.100, widget.currency?.toUpperCase() ?? MFCurrencyISO.UNITED_STATE_USD);
    mfApplePayButton.load(
        mfInitiateSessionResponse,
        request,
        MFAPILanguage.EN,
            (String invoiceId, MFResult<MFPaymentStatusResponse> result)
        {
          setState(() {
            _isPaying = false;
          });
          if (!result.isSuccess()){
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error?.message ?? '')));
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            widget.onFinish(null);
            Navigator.of(context).pop();
          },
        ),
        title: Text(S.of(context).paymentMethod, style: Theme.of(context)
            .textTheme
            .headline6
            ?.copyWith(fontWeight: FontWeight.w700),),
        backgroundColor: Theme.of(context).backgroundColor,
      ),
      body: _isLoading ? kLoadingWidget(context) : SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ..._paymentMethods.map((item) => PaymentMethodItem(item: item, isSelected: _selectedPaymentMethod?.paymentMethodId, onSelected: (value){
                    setState(() {
                      _selectedPaymentMethod = value;
                    });
                  })).toList(),
                  _selectedPaymentMethod?.isDirectPayment == true
                      ? CreditCardForm(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    textColor: Theme.of(context).textTheme.bodyText2!.color,
                    themeColor: Theme.of(context).primaryColor,
                    onCreditCardModelChange: (CreditCard? model) {
                      setState(() {
                        cardNumber = model?.cardNumber ?? '';
                        expiryMonth = model?.expiryDate?.split('/')[0] ?? '';
                        expiryYear = model?.expiryDate?.split('/')[1] ?? '';
                        securityCode = model?.cvv ?? '';
                        cardHolderName = model?.cardHolderName ?? '';
                      });
                    },
                  )
                      : Column(),
                  const Padding(
                    padding: EdgeInsets.all(5.0),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        primary: _selectedPaymentMethod != null ? Theme.of(context).primaryColor : Colors.grey),
                    onPressed: _isPaying || _selectedPaymentMethod == null ? null : pay,
                    child: Text(
                      _isPaying ? S.of(context).loading : S.of(context).payNow,
                      style: Theme.of(context).textTheme.subtitle2?.copyWith().copyWith(color: Colors.white),
                    ),
                  ),
                  if(Platform.isIOS)
                    createApplePayButton(),
                ]),
          ),
        ),
      ),
    );
  }

  MFApplePayButton createApplePayButton() {
    mfApplePayButton = MFApplePayButton(height: 50.0);
    return mfApplePayButton;
  }
}

class PaymentMethodItem extends StatelessWidget {
  const PaymentMethodItem({Key? key, required this.item, required this.isSelected, required this.onSelected}) : super(key: key);
  final PaymentMethods item;
  final int? isSelected;
  final Function(PaymentMethods) onSelected;


  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        InkWell(
          onTap: () {
            onSelected(item);
          },
          child: Container(
            decoration: BoxDecoration(
                color: isSelected == item.paymentMethodId
                    ? Theme.of(context).primaryColorLight
                    : Colors.transparent),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 5),
              child: Row(
                children: <Widget>[
                  Radio<String?>(
                      value: item.paymentMethodId?.toString() ?? '',
                      groupValue: isSelected.toString(),
                      onChanged: (String? value){
                        onSelected(item);
                      }),
                  const SizedBox(width: 10),
                  ImageTools.image(
                    url: item.imageUrl ?? '',
                    width: 40.0,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  if(item.paymentMethodEn?.isNotEmpty ?? false) Expanded(child: Text(item.paymentMethodEn!))
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1)
      ],
    );
  }
}
