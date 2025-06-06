import 'package:flutter/material.dart';
import 'package:fono_terapia/data/game_result_repository.dart';
import 'package:fono_terapia/database/dao/sub_category_dao.dart';
import 'package:fono_terapia/shared/model/category.dart';
import 'package:fono_terapia/shared/model/game_result.dart';
import 'package:fono_terapia/shared/model/sub_category.dart';
import 'package:sqflite/sqflite.dart';

class HistoryViewModel extends ChangeNotifier {
  final Category category;
  final Database database;
  final GameResultRepository repository;
  final String userId;

  bool isLoading = true;
  List<SubCategory> subCategories = [];
  List<bool> subCategoriesCategoryFilter = [];
  String? selectedDateFilter;
  List<GameResult> gameResults = [];

  late DateTime firstDate;
  late DateTime currentDate;

  HistoryViewModel({
    required this.category,
    required this.database,
    required this.repository,
    required this.userId,
  }) {
    _init();
  }

  Future<void> _init() async {
    currentDate = DateTime.now();
    firstDate = DateTime(currentDate.year, currentDate.month, 1);
    await loadSubCategories();
    await loadGameResults();
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadSubCategories() async {
    // Fetch subcategories locally as they are stored in the app itself.
    subCategories = await SubCategoryDao().findAllSubCategories(database, category.id);
    subCategoriesCategoryFilter = List.generate(subCategories.length, (index) => true);
    notifyListeners();
  }

  Future<void> loadGameResults() async {
    // Fetch all game results for the user from Firebase using the repository.
    List<GameResult> allGameResults = await repository.fetchGameResults(userId);

    // Filter results by category and selected subcategories.
    List<SubCategory> filteredSubCategories = _getFilteredSubCategories();

    gameResults = allGameResults.where((result) {
      return filteredSubCategories.any((subCategory) => result.subCategory.id == subCategory.id);
    }).toList();

    // Apply date filter if selected
    if (selectedDateFilter != null) {
      gameResults = gameResults.where((result) => result.date == selectedDateFilter).toList();
    }

    notifyListeners();
  }

  List<SubCategory> _getFilteredSubCategories() {
    return subCategories
        .asMap()
        .entries
        .where((entry) => subCategoriesCategoryFilter[entry.key])
        .map((entry) => entry.value)
        .toList();
  }

  void setSelectedDateFilter(String date) {
    selectedDateFilter = date;
    loadGameResults();
  }

  void setCategoryFilter(List<bool> filter) {
    subCategoriesCategoryFilter = filter;
    loadGameResults();
  }

  // Format date into "DD/MM/YYYY"
  String formatDate(String dateString) {
    DateTime parsedDate = DateTime.parse(dateString);
    return "${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}";
  }
}