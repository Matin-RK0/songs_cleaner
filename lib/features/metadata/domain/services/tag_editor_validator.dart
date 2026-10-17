import '../entities/tag_draft.dart';

abstract final class TagEditorValidator {
  static String? validate(TagDraft draft) {
    if (draft.title.trim().isEmpty) return 'titleRequired';
    if (draft.trackNumber < 0 || draft.trackNumber > 999) {
      return 'trackNumberInvalid';
    }
    return null;
  }
}
