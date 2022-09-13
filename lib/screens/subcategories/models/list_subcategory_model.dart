import '../../../models/entities/category.dart';
import '../../../models/paging_data_provider.dart';
import '../repositories/subcategories_repository.dart';

class ListSubcategoryModel extends PagingDataProvider<Category> {
  ListSubcategoryModel({required String parentId})
      : super(dataRepo: ListSubcategoryRepository(parentId: parentId));
}
