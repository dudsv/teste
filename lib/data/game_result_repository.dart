import 'package:fono_terapia/database/dao/category_dao.dart';
import 'package:fono_terapia/database/dao/sub_category_dao.dart';
import 'package:fono_terapia/database/firebase_database.dart';
import 'package:fono_terapia/shared/model/game_result.dart';
import 'package:sqflite/sqflite.dart';

class GameResultRepository {
  final FirebaseDatabase firebaseDatabase;
  final Database db;

  GameResultRepository({required this.firebaseDatabase, required this.db});

  Future<void> saveGameResult(String userId, GameResult gameResult) async {
    await firebaseDatabase.addGameResult(userId, gameResult.toMap());
  }

  Future<List<GameResult>> fetchGameResults(String userId) async {
    final querySnapshot = await firebaseDatabase.firestore
        .collection('Users')
        .doc(userId)
        .collection('gameResults')
        .get();

    List<GameResult> gameResults = [];

    for (var doc in querySnapshot.docs) {
      // Use await to retrieve subCategory and category
      final subCategory = await SubCategoryDao().findSubCategory(db, doc['subCategoryId']);
      final category = await CategoryDao().findCategory(db, doc['categoryId']);

      // Create GameResult instance and add it to the list
      gameResults.add(GameResult.fromMap(doc.data(), subCategory, category));
    }

    return gameResults;
  }
}