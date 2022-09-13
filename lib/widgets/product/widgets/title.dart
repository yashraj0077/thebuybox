import 'package:flutter/material.dart';

import '../../../models/entities/product.dart';

class ProductTitle extends StatelessWidget {
  final Product product;
  final bool hide;
  final TextStyle? style;
  final int? maxLines;

  const ProductTitle({
    Key? key,
    required this.product,
    this.style,
    required this.hide,
    this.maxLines = 2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return hide
        ? const SizedBox()
        : Text(
            '${product.name}\n',
            style: style ??
                Theme.of(context).textTheme.subtitle1!.apply(
                      fontSizeFactor: 0.9,
                    ),
            maxLines: maxLines ?? 2,
          );
  }
}
