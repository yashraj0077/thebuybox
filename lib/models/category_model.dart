import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:quiver/strings.dart';

import '../common/constants.dart';
import '../services/index.dart';
import 'entities/category.dart';

class CategoryModel with ChangeNotifier {
  final Services _service = Services();

  List<Category>? _categories = [];

  List<Category>? get categories => _categories;

  Map<String?, Category> categoryList = {};

  bool isLoading = false;
  List<Category>? allCategories;
  String? message;

  /// Format the Category List and assign the List by Category ID
  void sortCategoryList(
      {List<Category>? categoryList,
      dynamic sortingList,
      String? categoryLayout}) {
    var listCategory = <String?, Category>{};
    var result = categoryList;

    if (sortingList != null) {
      var categories = <Category>[];
      var subCategories = <Category>[];
      var isParent = true;
      for (var cate in sortingList) {
        var item = categoryList!.firstWhereOrNull(
            (Category cat) => cat.id.toString() == cate.toString());
        if (item != null) {
          if (item.parent != '0') {
            isParent = false;
          }
          categories.add(item);
        }
      }
      if (!['column', 'grid', 'subCategories'].contains(categoryLayout)) {
        for (var category in categoryList!) {
          var item =
              categories.firstWhereOrNull((cat) => cat.id == category.id);
          if (item == null && isParent && category.parent != '0') {
            subCategories.add(category);
          }
        }
      }
      result = [...categories, ...subCategories];
    }

    for (var cat in result!) {
      listCategory[cat.id] = cat;
    }
    this.categoryList = listCategory;
    _categories = result;
    notifyListeners();
  }

  void mapCategories(List<Category> categories, List<Map> remapCategories) {
    var result = <String?, Category>{};
    for (var cat in categories) {
      result[cat.id] = cat;
    }
    var items = <String?, Category>{};
    for (var remapCategory in remapCategories) {
      final categoryId = remapCategory['category'].toString();
      var category = result[categoryId];
      if (category != null) {
        items[remapCategory['category'].toString()] = category.copyWith(
          totalProduct: null,
          name: remapCategory['name'],
          image: remapCategory['image'],
          parent: remapCategory['parent']?.toString(),
        );
        result.removeWhere((key, value) => key == categoryId);
      }
    }
    items.addAll(result);
    result = items;
    categoryList = Map<String?, Category>.from(result);
    _categories = result.values.toList();

    // Override total product after remap
    for (var category in _categories!) {
      if (category.isRoot) {
        final totalProduct = _categories!
            .where((element) => element.parent == category.id.toString())
            .fold(
                0,
                (int previousValue, element) =>
                    previousValue + (element.totalProduct ?? 0));
        if (totalProduct > 0) {
          category = category.copyWith(totalProduct: totalProduct);
        }
        categoryList[category.id] = category;
      }
    }
    _categories = categoryList.values.toList();
    notifyListeners();
  }

  Future<void> getCategories({
    lang,
    sortingList,
    categoryLayout,
    List<Map>? remapCategories,
  }) async {
    try {
      printLog('[Category] getCategories');
      isLoading = true;
      notifyListeners();
      allCategories = await _service.api.getCategories(lang: lang);
      message = null;

      if (remapCategories != null) {
        mapCategories(
            List<Category>.from(allCategories ?? []), remapCategories);
      } else {
        sortCategoryList(
          categoryList: allCategories,
          sortingList: sortingList,
          categoryLayout: categoryLayout,
        );
      }

      isLoading = false;
      notifyListeners();
    } catch (err) {
      isLoading = false;
      message =
          'There is an issue with the app during request the data, please contact admin for fixing the issues $err';
      //notifyListeners();
    }
  }

  /// Prase category list from json Object
  static List<Category> parseCategoryList(response) {
    var categories = <Category>[];
    if (response is Map && isNotBlank(response['message'])) {
      throw Exception(response['message']);
    } else {
      for (var item in response) {
        if (item['slug'] != 'uncategorized') {
          categories.add(Category.fromJson(item));
        }
      }
      return categories;
    }
  }

  List<Category>? getCategory({required String parentId}) {
    return _categories?.where((element) => element.parent == parentId).toList();
  }
}
