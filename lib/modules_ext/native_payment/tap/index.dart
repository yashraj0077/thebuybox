import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../common/config.dart';
import '../../../models/cart/cart_model.dart';
import 'services.dart';

const kRedirectUrl = 'http://your_website.com/redirect_url';

class TapPayment extends StatefulWidget {
  final Map<String, dynamic>? params;
  final Function? onFinish;

  const TapPayment({this.params, this.onFinish});

  @override
  State<StatefulWidget> createState() {
    return TapPaymentState();
  }
}

class TapPaymentState extends State<TapPayment> {
  String? checkoutUrl;
  TapServices services = TapServices();

  @override
  void initState() {
    super.initState();
    // final flutterWebviewPlugin = FlutterWebviewPlugin();
    // flutterWebviewPlugin.onUrlChanged.listen((String url) async {
    //   if (url.startsWith('http://your_website.com/redirect_url')) {
    //     final uri = Uri.parse(url);
    //     final tapId = uri.queryParameters['tap_id'];
    //     widget.onFinish!(tapId);
    //     Navigator.of(context).pop();
    //   }
    // });

    Future.delayed(Duration.zero, () async {
      try {
        final params = getOrderParams();
        final url = await services.getCheckoutUrl(params);
        setState(() {
          checkoutUrl = url;
        });
      } catch (e) {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(e.toString()),
          ));
        widget.onFinish!(null);
        Navigator.of(context).pop();
      }
    });
  }

  Map<String, dynamic> getOrderParams() {
    var cartModel = Provider.of<CartModel>(context, listen: false);
    return {
      'amount': cartModel.getTotal(),
      'currency': kAdvanceConfig.defaultCurrency?.currencyDisplay,
      'threeDSecure': true,
      'save_card': false,
      'receipt': {'email': false, 'sms': true},
      'customer': {
        'first_name': cartModel.address?.firstName ?? '',
        'last_name': cartModel.address?.lastName ?? '',
        'email': cartModel.address?.email ?? '',
      },
      'source': {'id': 'src_card'},
      'post': {'url': kRedirectUrl},
      'redirect': {'url': kRedirectUrl}
    };
  }

  @override
  Widget build(BuildContext context) {
    if (checkoutUrl != null) {
      return WillPopScope(
        onWillPop: _handleAndroidBack,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).backgroundColor,
            leading: GestureDetector(
              onTap: () {
                widget.onFinish!(null);
                Navigator.pop(context);
              },
              child: const Icon(Icons.arrow_back_ios),
            ),
          ),
          body: WebView(
            initialUrl: checkoutUrl,
            javascriptMode: JavascriptMode.unrestricted,
            navigationDelegate: (NavigationRequest request) {
              if (request.url.startsWith(kRedirectUrl)) {
                final uri = Uri.parse(request.url);
                final tapId = uri.queryParameters['tap_id'];
                widget.onFinish!(tapId);
                Navigator.of(context).pop();
              }
              return NavigationDecision.navigate;
            },
          ),
        ),
      );
    } else {
      return WillPopScope(
        onWillPop: _handleAndroidBack,
        child: Scaffold(
          appBar: AppBar(
            systemOverlayStyle: SystemUiOverlayStyle.light,
            leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                }),
            backgroundColor: Theme.of(context).backgroundColor,
            elevation: 0.0,
          ),
          body: Container(child: kLoadingWidget(context)),
        ),
      );
    }
  }

  Future<bool> _handleAndroidBack() async {
    widget.onFinish!(null);
    return true;
  }
}
