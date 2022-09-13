import 'package:flutter/cupertino.dart';

import '../../../models/booking/booking_model.dart';
import '../../../models/entities/product.dart';
import '../views/product_booking_layout.dart';

mixin BookingServiceMixin {
  /// Get Booking Layout
  Widget getBookingLayout(
      {required Product product, Function(BookingModel)? onCallBack}) {
    return ProductBookingLayout(
      key: ValueKey('keyProductBooking${product.id}'),
      product: product,
      onCallBack: onCallBack,
    );
  }
}
