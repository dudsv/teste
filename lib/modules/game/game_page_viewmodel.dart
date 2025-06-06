import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:fono_terapia/data/game_result_repository.dart';
import 'package:fono_terapia/database/dao/category_dao.dart';
import 'package:fono_terapia/database/dao/game_component_dao.dart';
import 'package:fono_terapia/modules/game/game_result_dialog.dart';
import 'package:fono_terapia/modules/game/widgets/game_configuration_dialog.dart';
import 'package:fono_terapia/shared/assets/app_assets.dart';
import 'package:fono_terapia/shared/model/game_component.dart';
import 'package:fono_terapia/shared/model/game_configuration.dart';
import 'package:fono_terapia/shared/model/game_result.dart';
import 'package:fono_terapia/shared/model/sub_category.dart';
import 'package:sqflite/sqflite.dart';

class GameViewModel extends ChangeNotifier {
  final SubCategory subCategory;
  final Database database;
  final GameComponentDao gameComponentDao = GameComponentDao();
  final AudioPlayer player = AudioPlayer();
  final GameResultRepository repository;
  final String userId;

  bool isLoading = true;
  String hintText = "";
  int questionsAnswered = 0;
  int answeredCorrectly = 0;
  late GameConfiguration configuration;
  late double percentage;
  late List<GameComponent> gameComponents;
  late GameComponent rightAnswer;

  bool gameFinished = false;

  GameViewModel(
      {required this.subCategory,
      required this.database,
      required this.repository,
      required this.userId});

  // Initialize game configuration and load components
  Future<void> initializeGame() async {
    configuration = GameConfiguration(2, questionsAnswered, 10);
    percentage = 0;
    await loadGameComponents();
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadGameComponents() async {
    gameComponents = await gameComponentDao.findRandomComponents(
      database,
      subCategory.section,
      configuration.numberOfOptions,
    );
    rightAnswer = gameComponentDao.getRightAnswer(gameComponents);
    hintText = '_' * rightAnswer.name.length;
    isLoading = false;
    notifyListeners();
  }

  String buildHintText() {
    if (hintText.isEmpty) {
      hintText = '_' * rightAnswer.name.length;
    }
    return hintText;
  }

  void updateHintText() {
    int index = hintText.indexOf('_');
    if (index != -1) {
      hintText = hintText.replaceFirst(
        '_',
        rightAnswer.name.characters.elementAt(index),
      );
      notifyListeners();
    }
  }

  void removeRandomComponent() {
    List<int> indices = List.generate(gameComponents.length, (index) => index)
        .where((index) => gameComponents[index] != rightAnswer)
        .toList();

    if (indices.isNotEmpty) {
      int randomIndex = Random().nextInt(indices.length);
      gameComponents.removeAt(indices[randomIndex]);
      notifyListeners();
    }
  }

  Future<void> openConfigurationDialog(BuildContext context) async {
    configuration.questionsAnswered = questionsAnswered;
    final GameConfiguration? result = await showDialog<GameConfiguration>(
      context: context,
      builder: (context) {
        return GameConfigurationDialog(
          configurations: configuration,
          subCategoryId: subCategory.id,
        );
      },
    );

    if (result != null) {
      configuration = result;
      percentage =
          (answeredCorrectly / configuration.totalNumberOfQuestions) * 100;
      await loadGameComponents();
    }
  }

  // Trigger when game is completed
  void optionSelected(GameComponent? selectedOption) {
    if (selectedOption == rightAnswer) {
      player.play(AssetSource(AppAssets.correctSound), volume: 0.1);
      answeredCorrectly++;
    } else {
      player.play(AssetSource(AppAssets.wrongSound), volume: 0.1);
    }

    questionsAnswered++;
    percentage =
        (answeredCorrectly / configuration.totalNumberOfQuestions) * 100;

    if (questionsAnswered >= configuration.totalNumberOfQuestions) {
      gameFinished = true; // Set the flag to true to indicate game finished
      notifyListeners(); // Notify listeners to trigger the dialog in the GamePage
    } else {
      loadNextQuestion();
    }
  }

  void loadNextQuestion() async {
    isLoading = true;
    hintText = "";
    await loadGameComponents();
    isLoading = false;
    notifyListeners();
  }

  void handleNext(BuildContext context) {
    questionsAnswered++;
    if (questionsAnswered >= configuration.totalNumberOfQuestions) {
      handleFinish(context);
    } else {
      loadNextQuestion();
    }
  }

  Future<void> handleFinish(BuildContext context) async {
    if (questionsAnswered == 0) {
      // No questions answered, go straight to the menu
      Navigator.of(context).pushNamedAndRemoveUntil('/menu', (route) => false);
    } else {
      // Questions have been answered, show the GameResultDialog
      configuration.questionsAnswered = questionsAnswered;
      final gameResult = GameResult(
        null,
        DateTime.now().toString().split(' ')[0],
        questionsAnswered,
        answeredCorrectly,
        subCategory,
        await CategoryDao().findCategory(database, subCategory.category!.id),
      );
      await repository
          .saveGameResult(userId, gameResult); // Save to Firebase and local database

      showDialog<GameResult>(
        context: context,
        builder: (context) => GameResultDialog(
          gameResult: gameResult,
          subCategory: subCategory,
        ),
      );
    }
  }
}
