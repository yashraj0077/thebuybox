import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../common/tools.dart';
import '../../../generated/l10n.dart';
import '../../../models/app_model.dart';
import '../../../models/cart/cart_model.dart';
import '../../../widgets/html/index.dart';
import '../models/plan.dart';
import '../services/index.dart';

List<Map<String, dynamic>> kPlanItemDesign = [
  /// isRecommended should be supported via GET APIs, not here.
  {
    'isTextColorAccent': true,
    'backgroundColor': Colors.grey.withOpacity(0.5),
    'textColor': Colors.black12.withOpacity(0.7),
    'isRecommended': false,
  },
  {
    'isTextColorAccent': false,
    'backgroundColor': Colors.indigoAccent.withOpacity(0.9),
    'textColor': Colors.white70.withOpacity(0.9),
    'isRecommended': true,
  },
  {
    'isTextColorAccent': false,
    'backgroundColor': Colors.indigo.withOpacity(0.9),
    'textColor': Colors.white,
    'isRecommended': false,
  }
];

class PlansScreen extends StatefulWidget {
  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  final _memoizer = AsyncMemoizer<List<Plan>?>();
  final _services = MembershipServices();

  Future<List<Plan>?> getPlans() {
    return _memoizer.runOnce(
      _services.getPlans,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        systemOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        title: Text(
          S.of(context).choosePlan,
          style: Theme.of(context)
              .textTheme
              .headline6!
              .copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<Plan>?>(
        future: getPlans(),
        builder: (BuildContext context, AsyncSnapshot<List<Plan>?> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.active:
            case ConnectionState.waiting:
              return Center(child: kLoadingWidget(context));
            case ConnectionState.done:
            default:
              if (snapshot.hasError ||
                  snapshot.data == null ||
                  snapshot.data!.isEmpty) {
                return const SizedBox();
              }
              return SafeArea(
                child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (BuildContext context, int index) {
                      final layout = kPlanItemDesign.length > index
                          ? kPlanItemDesign[index]
                          : kPlanItemDesign[0];
                      return PlanItem(
                        item: snapshot.data![index],
                        textColor: layout['textColor'],
                        backgroundColor: layout['backgroundColor'],
                        isRecommended: layout['isRecommended'],
                        isTextColorAccent: layout['isTextColorAccent'],
                      );
                    }),
              );
          }
        },
      ),
    );
  }
}

class PlanItem extends StatelessWidget {
  final Plan item;
  final Color backgroundColor;
  final Color textColor;
  final bool? isRecommended;
  final bool isTextColorAccent;
  const PlanItem(
      {required this.item,
      required this.backgroundColor,
      required this.textColor,
      this.isRecommended = false,
      required this.isTextColorAccent});

  @override
  Widget build(BuildContext context) {
    final cartModel = Provider.of<CartModel>(context, listen: false);
    final currencyRate =
        Provider.of<AppModel>(context, listen: false).currencyRate;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: InkWell(
        splashColor: backgroundColor,
        onTap: () {
          Navigator.of(context)
              .pushNamed(RouteList.memberShipUltimateSignUp, arguments: item);
        },
        borderRadius: const BorderRadius.all(
          Radius.circular(10.0),
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(10.0),
                  ),
                  color: backgroundColor),
              child: Column(
                children: [
                  SizedBox(
                    height: 50,
                    child: Center(
                      child: Text(
                        item.label!,
                        style: Theme.of(context).textTheme.subtitle1!.copyWith(
                              color: isTextColorAccent
                                  ? Theme.of(context).colorScheme.secondary
                                  : textColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 70,
                    child: Center(
                      child: Text(
                        PriceTools.getCurrencyFormatted(
                            item.price, currencyRate,
                            currency: cartModel.currencyCode)!,
                        style: Theme.of(context).textTheme.headline2!.copyWith(
                              color: isTextColorAccent
                                  ? Theme.of(context).colorScheme.secondary
                                  : textColor,
                            ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.maxFinite,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20.0, horizontal: 20.0),
                      child: HtmlWidget(
                        item.description!,
                        textStyle:
                            Theme.of(context).textTheme.bodyText2!.copyWith(
                                  color: isTextColorAccent
                                      ? Theme.of(context).colorScheme.secondary
                                      : textColor,
                                ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isRecommended!)
              const Positioned(
                top: 10,
                right: 10,
                child: _RecommendedSign(),
              )
          ],
        ),
      ),
    );
  }
}

class _RecommendedSign extends StatelessWidget {
  const _RecommendedSign({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 20,
      decoration: const BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.all(
          Radius.circular(4.0),
        ),
      ),
      child: Center(
        child: Text(
          S.of(context).recommended,
          style: Theme.of(context)
              .textTheme
              .bodyText2!
              .copyWith(fontSize: 12.0, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
