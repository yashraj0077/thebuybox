import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:inspireui/widgets/void_widget.dart';
import 'package:provider/provider.dart';

import '../../common/config.dart';
import '../../common/constants.dart';
import '../../generated/l10n.dart';
import '../../models/entities/filter_sorty_by.dart';
import '../../models/index.dart'
    show
        AppModel,
        Category,
        CategoryModel,
        FilterAttributeModel,
        Product,
        ProductModel,
        TagModel,
        UserModel;
import '../../modules/dynamic_layout/helper/countdown_timer.dart';
import '../../modules/dynamic_layout/helper/helper.dart';
import '../../modules/dynamic_layout/index.dart';
import '../../services/index.dart';
import '../../widgets/asymmetric/asymmetric_view.dart';
import '../../widgets/backdrop/backdrop.dart';
import '../../widgets/backdrop/backdrop_menu.dart';
import '../../widgets/common/flux_image.dart';
import '../../widgets/product/product_bottom_sheet.dart';
import '../../widgets/product/product_list.dart';
import '../common/app_bar_mixin.dart';
import 'products_backdrop.dart';
import 'products_flatview.dart';
import 'products_mixin.dart';

class FilterLabel extends StatelessWidget {
  final String label;
  final Widget? icon;
  final Widget? leading;
  final Function()? onTap;

  const FilterLabel({
    Key? key,
    required this.label,
    this.onTap,
    this.icon,
    this.leading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        constraints: const BoxConstraints(minWidth: 50),
        height: 30,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: Theme.of(context).primaryColor, width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 4),
            ],
            Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.caption?.copyWith(
                      textBaseline: TextBaseline.ideographic,
                    ),
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 4),
              icon!,
            ]
          ],
        ),
      ),
    );
  }
}

class ProductsScreen extends StatefulWidget {
  final List<Product>? products;
  final ProductConfig? config;
  final Duration countdownDuration;
  final String? listingLocation;
  final bool enableSearchHistory;

  const ProductsScreen({
    this.products,
    this.countdownDuration = Duration.zero,
    this.listingLocation,
    this.config,
    this.enableSearchHistory = false,
  });

  @override
  State<StatefulWidget> createState() {
    return ProductsScreenState();
  }
}

class ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin, AppBarMixin, ProductsMixin {
  late AnimationController _controller;

  ProductConfig get productConfig => widget.config ?? ProductConfig.empty();

  CategoryModel get categoryModel =>
      Provider.of<CategoryModel>(context, listen: false);

  TagModel get tagModel => Provider.of<TagModel>(context);

  ProductModel get productModel =>
      Provider.of<ProductModel>(context, listen: false);

  FilterAttributeModel get filterAttrModel =>
      Provider.of<FilterAttributeModel>(context, listen: false);

  UserModel get userModel => Provider.of<UserModel>(context, listen: false);

  AppModel get appModel => Provider.of<AppModel>(context, listen: false);

  /// Image ratio from Product Cart
  double get ratioProductImage => appModel.ratioProductImage;

  num get productListItemHeight => kProductDetail.productListItemHeight;

  ///
  bool get enableProductBackdrop => kAdvanceConfig.enableProductBackdrop;

  bool get categoryImageMenu => kAdvanceConfig.categoryImageMenu;

  bool get showBottomCornerCart => kAdvanceConfig.showBottomCornerCart;

  String? newTagId;
  String? newCategoryId;
  String? newListingLocationId;
  double? minPrice;
  double? maxPrice;
  String? attribute;
  String? search;

  bool isFiltering = false;
  List<Product>? products = [];
  String? errMsg;
  int _page = 1;

  String _currentTitle = '';

  String get currentTitle =>
      search != null ? S.of(context).results : _currentTitle;

  List? include;

  FilterSortBy _currentFilterSortBy = const FilterSortBy();

  @override
  void didUpdateWidget(covariant ProductsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    onFilter();
  }

  @override
  void initState() {
    super.initState();
    newCategoryId = productConfig.category ?? '-1';
    newTagId = productConfig.tag;
    _currentFilterSortBy = _currentFilterSortBy
        .copyWith(
          onSale: productConfig.onSale,
          featured: productConfig.featured,
        )
        .copyWithString(
          orderBy: productConfig.orderby,
        );
    newListingLocationId = widget.listingLocation;
    include = productConfig.include;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      value: 1.0,
    );

    /// only request to server if there is empty config params
    // / If there is config, load the products one
    WidgetsBinding.instance.endOfFrame.then((_) {
      if (mounted) {
        filterAttrModel.resetFilter();
        onRefresh();
      }
    });
  }

  void onFilter({
    dynamic minPrice,
    dynamic maxPrice,
    dynamic categoryId,
    String? categoryName,
    String? tagId,
    dynamic listingLocationId,
    FilterSortBy? sortBy,
    String? search,
  }) {
    printLog('[onFilter] ♻️ Reload product list');
    _controller.forward();
    _currentFilterSortBy = sortBy ?? _currentFilterSortBy;

    if (listingLocationId != null) {
      newListingLocationId = listingLocationId;
    }

    if (minPrice == maxPrice && minPrice == 0) {
      this.minPrice = null;
      this.maxPrice = null;
    } else {
      this.minPrice = minPrice ?? this.minPrice;
      this.maxPrice = maxPrice ?? this.maxPrice;
    }

    if (tagId != null) {
      newTagId = tagId;
    }

    if (search != null) {
      this.search = search;
    }

    // set attribute
    if (filterAttrModel.selectedAttr != null &&
        filterAttrModel.indexSelectedAttr != -1 &&
        filterAttrModel.lstProductAttribute != null) {
      var selectedAttr = filterAttrModel.indexSelectedAttr <
              filterAttrModel.lstProductAttribute!.length
          ? filterAttrModel
              .lstProductAttribute![filterAttrModel.indexSelectedAttr]
          : null;
      attribute = selectedAttr?.slug;
    }

    /// Set category title, ID
    if (categoryId != null) {
      newCategoryId = categoryId;

      final selectedCat = categoryModel.categories!
          .firstWhereOrNull((element) => element.id == categoryId.toString());

      if (selectedCat != null) {
        productModel.categoryName = selectedCat.name;
        _currentTitle = selectedCat.name!;
      }
    }

    /// reset paging and clean up product
    _page = 1;
    productModel.setProductsList([]);

    _getProductList();
    setState(() {});
  }

  void _getProductList() {
    productModel.getProductsList(
      categoryId: newCategoryId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      page: _page,
      lang: appModel.langCode,
      orderBy: _currentFilterSortBy.orderByType?.name,
      order: _currentFilterSortBy.orderType?.name,
      featured: _currentFilterSortBy.featured,
      onSale: _currentFilterSortBy.onSale,
      tagId: newTagId,
      attribute: attribute,
      attributeTerm: getAttributeTerm(),
      userId: userModel.user?.id,
      listingLocation: newListingLocationId,
      include: include,
      search: search,
    );
  }

  Future<void> onRefresh() async {
    setState(() {
      _page = 1;
    });
    _getProductList();
  }

  Widget? renderCategoryMenu({bool imageLayout = false}) {
    if (widget.enableSearchHistory) {
      return kVoidWidget;
    }

    var parentCategoryId = newCategoryId;
    if (categoryModel.categories != null &&
        categoryModel.categories!.isNotEmpty) {
      parentCategoryId =
          getParentCategories(categoryModel.categories, parentCategoryId) ??
              parentCategoryId;

      var parentImage =
          categoryModel.categoryList[parentCategoryId.toString()]?.image ?? '';
      final listSubCategory =
          getSubCategories(categoryModel.categories, parentCategoryId)!;

      if (listSubCategory.length < 2) return null;

      return ListenableProvider.value(
        value: categoryModel,
        child: Consumer<CategoryModel>(builder: (context, value, child) {
          final listSubCategory =
              getSubCategories(categoryModel.categories, parentCategoryId)!;

          if (value.isLoading) {
            return Center(child: kLoadingWidget(context));
          }

          if (value.categories != null) {
            var renderListCategory = <Widget>[];
            var categoryMenu = categoryImageMenu;

            renderListCategory.add(
              _renderItemCategory(
                context,
                categoryId: parentCategoryId,
                categoryName: S.of(context).seeAll,
                categoryImage:
                    categoryMenu && parentImage.isNotEmpty && imageLayout
                        ? parentImage
                        : null,
              ),
            );

            renderListCategory.addAll([
              for (var category in listSubCategory)
                _renderItemCategory(
                  context,
                  categoryId: category.id,
                  categoryName: category.name!,
                  categoryImage:
                      categoryMenu && imageLayout ? category.image : null,
                )
            ]);

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 5),
              color: Theme.of(context).backgroundColor,
              constraints: const BoxConstraints(minHeight: 50),
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: renderListCategory,
                  ),
                ),
              ),
            );
          }

          return const SizedBox();
        }),
      );
    }
    return null;
  }

  List<Category>? getSubCategories(categories, id) {
    return categories.where((o) => o.parent == id).toList();
  }

  String? getParentCategories(categories, id) {
    for (var item in categories) {
      if (item.id == id) {
        return (item.parent == null || item.parent == '0') ? null : item.parent;
      }
    }
    return '0';
  }

  Widget _renderFilterSortByTag() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_currentFilterSortBy.displaySpecial != null)
          FilterLabel(
            label: _currentFilterSortBy.displaySpecial!,
            onTap: () {
              _currentFilterSortBy =
                  _currentFilterSortBy.applyOnSale(null).applyFeatured(null);
              onFilter();
            },
            leading: _currentFilterSortBy.onSale ?? false
                ? Icon(
                    CupertinoIcons.tag_solid,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  )
                : Icon(
                    CupertinoIcons.star_circle_fill,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
          ),
        if (_currentFilterSortBy.displayOrderBy != null &&
            _currentFilterSortBy.orderType != null)
          FilterLabel(
            label: _currentFilterSortBy.displayOrderBy!,
            icon: _currentFilterSortBy.orderType!.isAsc
                ? Icon(
                    CupertinoIcons.sort_up,
                    size: 20,
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.6),
                  )
                : Icon(
                    CupertinoIcons.sort_down,
                    size: 20,
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.6),
                  ),
            onTap: () {
              _currentFilterSortBy =
                  _currentFilterSortBy.applyOrder(null).applyOrderBy(null);
              onFilter();
            },
          ),
      ],
    );
  }

  Widget _renderItemCategory(
    BuildContext context, {
    String? categoryId,
    required String categoryName,
    String? categoryImage,
  }) {
    var highlightColor = newCategoryId == categoryId
        ? Theme.of(context).colorScheme.secondary.withOpacity(0.2)
        : Colors.transparent;
    return GestureDetector(
      onTap: () {
        include = null;
        onFilter(categoryId: categoryId);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: categoryImage != null ? 5 : 10,
          vertical: 4,
        ),
        margin: const EdgeInsets.only(left: 5, top: 10, bottom: 4),
        decoration: BoxDecoration(
          color: highlightColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: categoryImage != null
            ? Container(
                width: 70,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Column(
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 55,
                        height: 50,
                        child: FluxImage(
                          imageUrl: categoryImage,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      categoryName.toUpperCase(),
                      maxLines: 1,
                      style: Theme.of(context)
                          .textTheme
                          .caption!
                          .copyWith(
                            fontWeight: FontWeight.w500,
                          )
                          .apply(
                            fontSizeFactor: 0.7,
                          ),
                      textAlign: TextAlign.center,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ),
              )
            : Center(
                child: Text(
                  categoryName.toUpperCase(),
                  style: Theme.of(context).textTheme.caption!.copyWith(
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
              ),
      ),
    );
  }

  String getAttributeTerm({bool showName = false}) {
    var terms = '';
    for (var i = 0; i < filterAttrModel.lstCurrentSelectedTerms.length; i++) {
      if (filterAttrModel.lstCurrentSelectedTerms[i]) {
        if (showName) {
          terms += '${filterAttrModel.lstCurrentAttr[i].name},';
        } else {
          terms += '${filterAttrModel.lstCurrentAttr[i].id},';
        }
      }
    }
    return terms.isNotEmpty ? terms.substring(0, terms.length - 1) : '';
  }

  void onLoadMore() {
    _page = _page + 1;
    _getProductList();
  }

  ProductBackdrop backdrop({
    products,
    isFetching,
    errMsg,
    isEnd,
    width,
    required String layout,
  }) {
    return ProductBackdrop(
      backdrop: Backdrop(
        bgColor: productConfig.backgroundColor,
        frontLayer: layout.isListView
            ? ProductList(
                products: products,
                onRefresh: onRefresh,
                onLoadMore: onLoadMore,
                isFetching: isFetching,
                errMsg: errMsg,
                isEnd: isEnd,
                layout: layout,
                ratioProductImage: ratioProductImage,
                productListItemHeight: productListItemHeight,
                width: width,
              )
            : AsymmetricView(
                products: products,
                isFetching: isFetching,
                isEnd: isEnd,
                onLoadMore: onLoadMore,
                width: width),
        backLayer: BackdropMenu(
          onFilter: onFilter,
          categoryId: newCategoryId,
          tagId: newTagId,
          sortBy: _currentFilterSortBy,
          listingLocationId: newListingLocationId,
        ),
        frontTitle: productConfig.showCountDown
            ? Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentTitle),
                      CountDownTimer(widget.countdownDuration)
                    ],
                  ),
                ],
              )
            : Text(currentTitle),
        backTitle: Text(S.of(context).filter),
        controller: _controller,
        appbarCategory: renderCategoryMenu(),
        onTapShareButton: () async {
          await shareProductsLink(context);
        },
      ),
      expandingBottomSheet: (Services().widget.enableShoppingCart(null) &&
              !ServerConfig().isListingType &&
              kAdvanceConfig.showBottomCornerCart)
          ? ExpandingBottomSheet(hideController: _controller)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    _currentTitle = productConfig.name ??
        productModel.categoryName ??
        S.of(context).results;

    Widget buildMain = LayoutBuilder(
      builder: (context, constraint) {
        return FractionallySizedBox(
          widthFactor: 1.0,
          child: Selector<AppModel, String>(
            selector: (context, provider) => provider.productListLayout,
            builder: (context, productListLayout, child) {
              /// override the layout to listTile if enableSearchUX
              /// otherwise, using default productListLayout from the Config
              var layout = widget.enableSearchHistory
                  ? Layout.simpleList
                  : productListLayout;

              return ListenableProvider.value(
                value: productModel,
                child: Consumer<ProductModel>(
                  builder: (context, model, child) {
                    var backdropLayout = enableProductBackdrop;

                    if (!backdropLayout) {
                      var tagName =
                          tagModel.tags?[newTagId.toString()]?.name ?? '';
                      var currentCategory =
                          categoryModel.categoryList[productModel.categoryId];
                      var attributeTerms = getAttributeTerm(showName: true);
                      var attributeList = attributeTerms.isNotEmpty
                          ? attributeTerms.split(',')
                          : [];

                      return ProductFlatView(
                        enableSearchHistory: widget.enableSearchHistory,
                        builder: (controller) => layout.isListView
                            ? ProductList(
                                scrollController: controller,
                                products: model.productsList,
                                onRefresh: onRefresh,
                                onLoadMore: onLoadMore,
                                isFetching: model.isFetching,
                                errMsg: model.errMsg,
                                isEnd: model.isEnd,
                                layout: layout,
                                ratioProductImage: ratioProductImage,
                                productListItemHeight: productListItemHeight,
                                width: constraint.maxWidth,
                                header: [
                                  const SizedBox(height: 44),
                                  renderCategoryMenu(imageLayout: true) ??
                                      const SizedBox(),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 10,
                                        right: 10,
                                        bottom: 10,
                                        top: 25),
                                    child: Column(
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              currentTitle,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline6!
                                                  .copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    height: 0.6,
                                                  ),
                                            ),
                                            const Spacer(),
                                            if ((currentCategory
                                                        ?.totalProduct ??
                                                    0) >
                                                0) ...[
                                              Text(
                                                '${currentCategory!.totalProduct} ${S.of(context).items}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .caption!
                                                    .copyWith(
                                                      color: Theme.of(context)
                                                          .hintColor,
                                                    ),
                                              ),
                                              const SizedBox(width: 5),
                                            ]
                                          ],
                                        ),
                                        if (productConfig.showCountDown) ...[
                                          const SizedBox(height: 5),
                                          Row(
                                            children: [
                                              Text(
                                                S
                                                    .of(context)
                                                    .endsIn('')
                                                    .toUpperCase(),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .subtitle1!
                                                    .copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .secondary
                                                          .withOpacity(0.8),
                                                    )
                                                    .apply(fontSizeFactor: 0.6),
                                              ),
                                              CountDownTimer(
                                                  widget.countdownDuration),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  )
                                ],
                              )
                            : AsymmetricView(
                                products: model.productsList,
                                isFetching: model.isFetching,
                                isEnd: model.isEnd,
                                onLoadMore: onLoadMore,
                                width: constraint.maxWidth),
                        titleFilter: Row(
                          children: [
                            _renderFilterSortByTag(),
                            const SizedBox(width: 5),
                            if (attributeList.isNotEmpty)
                              for (int i = 0; i < attributeList.length; i++)
                                FilterLabel(
                                  label: attributeList[i].toString(),
                                  onTap: () {
                                    filterAttrModel.resetFilter();
                                    onFilter();
                                  },
                                ),
                            if (tagName.isNotEmpty)
                              FilterLabel(
                                label: tagName.capitalize(),
                                onTap: () {
                                  productModel.resetTag();
                                  onFilter(tagId: '');
                                },
                              ),
                            if (minPrice != null &&
                                maxPrice != null &&
                                maxPrice != 0)
                              FilterLabel(
                                onTap: () {
                                  productModel.resetPrice();
                                  onFilter(minPrice: 0.0, maxPrice: 0.0);
                                },
                                label:
                                    '${minPrice?.toStringAsFixed(0) ?? ''} - ${maxPrice?.toStringAsFixed(0) ?? ''}',
                              ),
                          ],
                        ),
                        onFilter: onFilter,
                        onSearch: (String searchText) => {
                          onFilter(
                            minPrice: minPrice,
                            maxPrice: maxPrice,
                            categoryId: newCategoryId,
                            tagId: newTagId,
                            listingLocationId: newListingLocationId,
                            search: searchText,
                          )
                        },
                        filterMenu: (scrollController) => BackdropMenu(
                          onFilter: onFilter,
                          categoryId: newCategoryId,
                          sortBy: _currentFilterSortBy,
                          tagId: newTagId,
                          listingLocationId: newListingLocationId,
                          controller: scrollController,
                          minPrice: minPrice,
                          maxPrice: maxPrice,

                          /// hide layout filter from Search screen
                          showLayout: widget.enableSearchHistory ? false : true,
                        ),
                        bottomSheet: (Services()
                                    .widget
                                    .enableShoppingCart(null) &&
                                !ServerConfig().isListingType &&
                                showBottomCornerCart)
                            ? ExpandingBottomSheet(hideController: _controller)
                            : null,
                      );
                    }
                    return backdrop(
                      products: model.productsList,
                      isFetching: model.isFetching,
                      errMsg: model.errMsg,
                      isEnd: model.isEnd,
                      width: constraint.maxWidth,
                      layout: layout,
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );

    buildMain = renderScaffold(routeName: RouteList.backdrop, body: buildMain);

    return kIsWeb
        ? WillPopScope(
            onWillPop: () async {
              eventBus.fire(const EventOpenCustomDrawer());
              // LayoutWebCustom.changeStateMenu(true);
              Navigator.of(context).pop();
              return false;
            },
            child: buildMain,
          )
        : buildMain;
  }
}
