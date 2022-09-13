import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../common/constants.dart';
import '../../../common/tools/price_tools.dart';
import '../../../models/app_model.dart';
import '../../../widgets/html/index.dart';
import '../models/invoice.dart';

class ConfirmationScreen extends StatefulWidget {
  final Invoice invoice;
  const ConfirmationScreen({required this.invoice});

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  @override
  Widget build(BuildContext context) {
    final currency = Provider.of<AppModel>(context, listen: false).currency;
    final currencyRate =
        Provider.of<AppModel>(context, listen: false).currencyRate;

    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context)
                  .popUntil(ModalRoute.withName(RouteList.login));
            }),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HtmlWidget(
                widget.invoice.confirmMessage ?? '',
                textStyle: const TextStyle(color: Colors.black, fontSize: 17.0),
              ),
              const SizedBox(height: 20.0),
              Text(
                'Invoice #${widget.invoice.code}',
                style: Theme.of(context).textTheme.headline5!.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10.0),
              Item(
                  label: 'Account',
                  value:
                      '${widget.invoice.username} (${widget.invoice.email})'),
              Item(
                  label: 'Membership Level',
                  value: widget.invoice.membershipLevel ?? ''),
              if(widget.invoice.accountNumber?.isNotEmpty ?? false) Item(
                  label: 'Account Number',
                  value: widget.invoice.accountNumber ?? ''),
              if(widget.invoice.expirationMonth?.isNotEmpty ?? false) Item(
                  label: 'Expiration',
                  value:
                      '${widget.invoice.expirationMonth}/${widget.invoice.expirationYear}'),
              Item(
                  label: 'Total Billed',
                  value: PriceTools.getCurrencyFormatted(
                          widget.invoice.total, currencyRate,
                          currency: currency) ??
                      '0.0'),
            ],
          ),
        ),
      ),
    );
  }
}

class Item extends StatelessWidget {
  const Item({Key? key, required this.label, required this.value})
      : super(key: key);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Text(
            '$label:',
            style: Theme.of(context).textTheme.headline6!.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: 10.0),
          Text(
            value,
            style: Theme.of(context).textTheme.headline6!.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
          )
        ],
      ),
    );
  }
}
