import '../../../models/entities/category.dart';

import '../../../models/entities/paging_response.dart';
import '../../../services/paging/paging_repository.dart';

class ListSubcategoryRepository extends PagingRepository<Category> {
  final String _parentId;

  ListSubcategoryRepository({required String parentId}) : _parentId = parentId;

  @override
  Future<PagingResponse<Category>> Function(dynamic) get requestApi =>
      (page) => service.api.getSubCategories(
            page: page,
            parentId: _parentId,
          );
}
