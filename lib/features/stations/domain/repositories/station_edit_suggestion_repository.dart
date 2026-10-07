import '../entities/station_edit_suggestion.dart';

abstract class StationEditSuggestionRepository {
  Future<void> submit(StationEditSuggestion suggestion);
}
