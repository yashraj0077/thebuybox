import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/tools/flash.dart';
import '../../../models/booking/booking_model.dart';
import '../../../models/index.dart' show CartModel, Product;
import '../booking_constants.dart';
import '../viewmodel/booking_viewmodel.dart';
import 'booking_widget.dart';

class ProductBookingLayout extends StatefulWidget {
  final Product? product;
  final Function(BookingModel bookingInfo)? onCallBack;

  const ProductBookingLayout({Key? key, this.product, this.onCallBack})
      : super(key: key);

  @override
  State<ProductBookingLayout> createState() => _ProductBookingLayoutState();
}

class _ProductBookingLayoutState extends State<ProductBookingLayout>
    with SingleTickerProviderStateMixin {
  BookingViewmodel? _bookingViewmodel;

  var top = 0.0;
  void onBooking(BuildContext ct, BookingModel model,
      {bool requiredStaff = false}) {
    if (model.isEmpty == false &&
        ((requiredStaff && (model.staffs?.isNotEmpty ?? false) ||
            (!requiredStaff)))) {
      widget.product!.bookingInfo = model;
      if (widget.onCallBack != null) {
        widget.onCallBack!(widget.product!.bookingInfo!);
        return;
      }
      addToCartForProductBooking(ct);
    }
  }

  void addToCartForProductBooking(BuildContext ct) {
    final cartModel = Provider.of<CartModel>(context, listen: false);
    var message = cartModel.addProductToCart(
        context: ct, product: widget.product, quantity: 1);
    if (message.isNotEmpty) {
      FlashHelper.errorBar(context, message: message);
    }
  }

  @override
  void initState() {
    super.initState();
    _bookingViewmodel = BookingViewmodel(widget.product!.id);
  }

  @override
  void dispose() {
    FlashHelper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    FlashHelper.init(context);
    return SliverToBoxAdapter(
      child: BookingWidget(
        // key: ValueKey('booking${widget.product!.id}'),
        product: widget.product!,
        viewModel: _bookingViewmodel,
        requiredStaff: BookingConstants.requiredStaff,
        onBooking: (model) {
          onBooking(context, model,
              requiredStaff: BookingConstants.requiredStaff);
        },
      ),
    );
  }
}
