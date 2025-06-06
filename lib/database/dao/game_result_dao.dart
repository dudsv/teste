import 'package:fono_terapia/database/dao/category_dao.dart';
import 'package:fono_terapia/database/dao/sub_category_dao.dart';
import 'package:fono_terapia/shared/model/category.dart';
import 'package:fono_terapia/shared/model/game_result.dart';
import 'package:fono_terapia/shared/model/sub_category.dart';
import 'package:sqflite/sqflite.dart';

class GameResultDao {
  static const tableName = 'game_results';
  static const _id = 'id';
  static const _date = 'date';
  static const _totalQuestions = 'total_questions';
  static const _answeredCorrectly = 'answered_correctly';
  static const _subCategoryId = 'sub_category_id';
  static const _subCategoryTableName = SubCategoryDao.tableName;
  static const _categoryId = 'category_id';
  static const _categoryTableName = CategoryDao.tableName;

  static String get tableSql {
    return '''CREATE TABLE $tableName(
        $_id INTEGER PRIMARY KEY AUTOINCREMENT,
        $_date TEXT NOT NULL,
        $_totalQuestions INTEGER NOT NULL,
        $_answeredCorrectly INTEGER NOT NULL,
        $_subCategoryId INTEGER NOT NULL,
        $_categoryId INTEGER NOT NULL,
        FOREIGN KEY ($_subCategoryId) REFERENCES $_subCategoryTableName($_id),
        FOREIGN KEY ($_categoryId) REFERENCES $_categoryTableName($_id)
      );''';
  }

  // Find all game results in a specific category
  Future<List<GameResult>> findAllInCategory(Database db, int categoryId) async {
    final List<Map<String, dynamic>> result = await db.query(
      tableName,
      where: '$_categoryId = ?',
      whereArgs: [categoryId],
    );
    return _toList(result, db);
  }

  // Convert the query result into a list of GameResult
  Future<List<GameResult>> _toList(List<Map<String, dynamic>> result, Database db) async {
    final List<GameResult> gameResults = [];

    for (Map<String, dynamic> row in result) {
      final int subCategoryId = row[_subCategoryId];
      final int categoryId = row[_categoryId];

      // Fetch the SubCategory and Category from their respective DAOs
      final SubCategory subCategory = await SubCategoryDao().findSubCategory(db, subCategoryId);
      final Category category = await CategoryDao().findCategory(db, categoryId);

      // Create a GameResult object and add it to the list
      final GameResult gameResult = _fromMap(row, subCategory, category);
      gameResults.add(gameResult);
    }

    return gameResults;
  }

  // Create a GameResult object from a map
  GameResult _fromMap(Map<String, dynamic> map, SubCategory subCategory, Category category) {
    return GameResult(
      map[_id],
      map[_date],
      map[_totalQuestions],
      map[_answeredCorrectly],
      subCategory,
      category,
    );
  }
}