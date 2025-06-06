import 'package:fono_terapia/shared/model/category.dart';
import 'package:fono_terapia/shared/model/sub_category.dart';

class GameResult {
  int? id;
  final String date;
  final int totalQuestions;
  final int answeredCorrectly;
  final SubCategory subCategory;
  final Category category;

  GameResult(
      this.id,
      this.date,
      this.totalQuestions,
      this.answeredCorrectly,
      this.subCategory,
      this.category,
      );

  /// Converts the GameResult to a map for Firebase storage.
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'totalQuestions': totalQuestions,
      'answeredCorrectly': answeredCorrectly,
      'subCategoryId': subCategory.id,
      'categoryId': category.id,
    };
  }

  /// Creates a GameResult instance from a Firebase map.
  static GameResult fromMap(Map<String, dynamic> map, SubCategory subCategory, Category category) {
    return GameResult(
      null, // No need for an ID as Firebase generates it
      map['date'] ?? '',
      map['totalQuestions'] ?? 0,
      map['answeredCorrectly'] ?? 0,
      subCategory,
      category,
    );
  }

  @override
  String toString() {
    return 'GameResult{id: $id, date: $date, totalQuestions: $totalQuestions, answeredCorrectly: $answeredCorrectly, subCategory: ${subCategory.id}, category: ${category.id}}';
  }
}