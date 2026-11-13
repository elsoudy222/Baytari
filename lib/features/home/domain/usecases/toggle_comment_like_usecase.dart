/// Use case: like / unlike a comment.
///
/// Returns the new state (true = now liked). The repository
/// inserts or deletes the `comment_likes` row; the like count is
/// the row count, so the Cubit adjusts it by +-1 from the
/// returned value.
library;

import '../../../../core/errors/result.dart';
import '../repositories/home_repository.dart';

class ToggleCommentLikeUseCase {
  const ToggleCommentLikeUseCase(this._repository);

  final HomeRepository _repository;

  Future<Result<bool>> call(String commentId) {
    return _repository.toggleCommentLike(commentId);
  }
}
