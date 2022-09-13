import 'package:flutter/material.dart';

import '../../../models/index.dart';
import '../../../services/services.dart';
import 'list_subcategory_model.dart';

class SubcategoryModel with ChangeNotifier {
  final _serviceApi = Services().api;
  final String _parentId;

  final ListSubcategoryModel listSubcategoryModel;

  Category? parentCategory;

  SubcategoryModel({required String parentId})
      : _parentId = parentId,
        listSubcategoryModel = ListSubcategoryModel(parentId: parentId);

  Future<void> getData() {
    return Future.wait([
      _getInfoParentCategory(),
      listSubcategoryModel.getData(),
    ]);
  }

  Future<void> _getInfoParentCategory() async {
    parentCategory =
        await _serviceApi.getProductCategoryById(categoryId: _parentId);
    notifyListeners();
  }
}
