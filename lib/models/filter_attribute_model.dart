import 'package:flutter/material.dart';

import '../services/index.dart';
import 'entities/filter_attribute.dart';
import 'mixins/language_mixin.dart';

class FilterAttributeModel with ChangeNotifier, LanguageMixin {
  List<FilterAttribute>? lstProductAttribute;
  final Services _service = Services();
  List<SubAttribute> lstCurrentAttr = [];
  List<bool> lstCurrentSelectedTerms = [];
  bool isLoading = false;
  int? selectedAttr;
  int get indexSelectedAttr => selectedAttr != null
      ? (lstProductAttribute
              ?.indexWhere((element) => element.id == selectedAttr) ??
          -1)
      : -1;

  Future<void> getFilterAttributes() async {
    try {
      isLoading = true;
      notifyListeners();
      lstProductAttribute = await _service.api.getFilterAttributes(
        lang: langCode,
      );
      if (lstProductAttribute != null &&
          lstProductAttribute!.isNotEmpty &&
          lstProductAttribute?.first.id != null) {
        await getAttr(id: lstProductAttribute!.first.id);
      } else {
        isLoading = false;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> getAttr({int? id}) async {
    try {
      if (!isLoading) {
        isLoading = true;
        notifyListeners();
      }
      selectedAttr = id;
      lstCurrentAttr = await _service.api.getSubAttributes(
        id: id,
        lang: langCode,
      )!;
      // Remove duplicates item
      for (var index = 0; index < lstCurrentAttr.length; index++) {
        final currentProduct = lstCurrentAttr[index];
        final listDuplicate = lstCurrentAttr
            .where((element) => currentProduct.id == element.id)
            .toList();
        if (listDuplicate.length > 1) {
          for (var indexDup = 1; indexDup < listDuplicate.length; indexDup++) {
            lstCurrentAttr.remove(listDuplicate[indexDup]);
          }
        }
      }
      lstCurrentSelectedTerms.clear();

      List.generate(
        lstCurrentAttr.length,
        (index) => lstCurrentSelectedTerms.add(false),
      );

      isLoading = false;
      notifyListeners();
    } catch (_) {}
    isLoading = false;
    notifyListeners();
  }

  void updateAttributeSelectedItem(int index, bool value) {
    lstCurrentSelectedTerms[index] = value;
    notifyListeners();
  }

  void resetFilter() {
    selectedAttr = null;
    lstCurrentSelectedTerms = [];
  }
}
