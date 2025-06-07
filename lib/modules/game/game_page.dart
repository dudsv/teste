import 'package:flutter/material.dart';
import 'package:fono_terapia/app_initializer.dart';
import 'package:fono_terapia/modules/game/game_page_viewmodel.dart';
import 'package:fono_terapia/modules/game/widgets/build_game_question.dart';
import 'package:fono_terapia/shared/assets/app_text_styles.dart';
import 'package:fono_terapia/shared/model/sub_category.dart';
import 'package:fono_terapia/shared/utils/responsive_size.dart';
import 'package:fono_terapia/shared/widgets/custom_header.dart';
import 'package:fono_terapia/shared/widgets/elevated_text_button.dart';
import 'package:fono_terapia/shared/widgets/my_text.dart';
import 'package:fono_terapia/shared/widgets/progress_indicator_with_text.dart';
import 'package:provider/provider.dart';
import 'widgets/build_game_list_of_options.dart';

class GamePage extends StatefulWidget {
  const GamePage({
    super.key,
    required this.subCategory,
  });

  final SubCategory subCategory;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late GameViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = GameViewModel(
      subCategory: widget.subCategory,
      database: AppInitializer.database,
      repository: AppInitializer.gameResultRepository,
      userId: AppInitializer.authRepository.currentUser!.uid
    );
    viewModel.initializeGame();
  }

  @override
  Widget build(BuildContext context) {
    final responsiveSize = AppInitializer.responsiveSize;

    return ChangeNotifierProvider<GameViewModel>(
      create: (_) => viewModel,
      child: Consumer<GameViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.gameFinished) {
            viewModel.handleFinish(context);

            viewModel.gameFinished = false;
          }

          if (viewModel.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    bottom: responsiveSize.scaleSize(20),
                  ),
                  child: CustomHeader(
                    text: viewModel.subCategory.name,
                  ),
                ),
                _buildTopBar(context, viewModel, responsiveSize),
                Expanded(
                  child: viewModel.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Padding(
                    padding: EdgeInsets.only(
                      top: responsiveSize.scaleSize(30),
                      left: responsiveSize.scaleSize(20),
                      right: responsiveSize.scaleSize(20),
                      bottom: responsiveSize.scaleSize(20),
                    ),
                    child: _buildContent(context, viewModel, responsiveSize),
                  ),
                ),
                _buildBottomBar(context, viewModel, responsiveSize),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, GameViewModel viewModel, ResponsiveSize responsiveSize) {
    if ([2, 8, 11, 12, 13, 14, 15, 16, 17].contains(viewModel.subCategory.id)) {
      return SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: responsiveSize.scaleSize(50),
              ),
              child: BuildGameQuestion(
                player: viewModel.player,
                subCategoryId: viewModel.subCategory.id,
                rightAnswer: viewModel.rightAnswer,
                responsiveSize: responsiveSize,
              ),
            ),
            if ([15, 16, 17].contains(viewModel.subCategory.id))
              MyText(
                viewModel.buildHintText(),
                style: TextStyles.textLargeRegular,
              ),
            BuildGameListOfOptions(
              gameComponents: viewModel.gameComponents,
              subCategoryId: viewModel.subCategory.id,
              rightAnswer: viewModel.rightAnswer,
              responsiveSize: responsiveSize,
              onTap: viewModel.optionSelected,
            ),
          ],
        ),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(
              bottom: responsiveSize.scaleSize(20),
            ),
            child: BuildGameQuestion(
              responsiveSize: responsiveSize,
              player: viewModel.player,
              subCategoryId: viewModel.subCategory.id,
              rightAnswer: viewModel.rightAnswer,
            ),
          ),
          Expanded(
            child: BuildGameListOfOptions(
              responsiveSize: responsiveSize,
              gameComponents: viewModel.gameComponents,
              subCategoryId: viewModel.subCategory.id,
              rightAnswer: viewModel.rightAnswer,
              onTap: viewModel.optionSelected,
            ),
          ),
        ],
      );
    }
  }

  Padding _buildTopBar(BuildContext context, GameViewModel viewModel, ResponsiveSize responsiveSize) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsiveSize.scaleSize(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: EdgeInsets.only(
              right: responsiveSize.scaleSize(20),
            ),
            child: ElevatedTextButton(
              widthRatio: responsiveSize.scaleSize(250),
              textStyle: TextStyles.buttonMediumText.copyWith(
                fontSize: responsiveSize.scaleSize(TextStyles.buttonMediumText.fontSize!),
              ),
              text: "Configuração",
              onPressed: () {
                viewModel.openConfigurationDialog(context);
              },
            ),
          ),
          Expanded(
            child: ProgressIndicatorWithText(
              answeredCorrectly: viewModel.answeredCorrectly,
              totalNumberOfQuestions: viewModel.configuration.totalNumberOfQuestions,
            ),
          ),
        ],
      ),
    );
  }

  Padding _buildBottomBar(BuildContext context, GameViewModel viewModel, ResponsiveSize responsiveSize) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: responsiveSize.scaleSize(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (![2, 8, 11, 12, 13, 14].contains(viewModel.subCategory.id))
            ElevatedTextButton(
              widthRatio: responsiveSize.scaleSize(130),
              textStyle: TextStyles.buttonMediumText.copyWith(
                fontSize: responsiveSize.scaleSize(TextStyles.buttonMediumText.fontSize!),
              ),
              text: "Ajuda",
              onPressed: () {
                if ([15, 16, 17].contains(viewModel.subCategory.id)) {
                  viewModel.updateHintText();
                } else {
                  viewModel.removeRandomComponent();
                }
              },
            ),
          ElevatedTextButton(
            widthRatio: responsiveSize.scaleSize(160),
            textStyle: TextStyles.buttonMediumText.copyWith(
              fontSize: responsiveSize.scaleSize(TextStyles.buttonMediumText.fontSize!),
            ),
            text: "Próximo",
            onPressed: () {
              viewModel.handleNext(context);
            },
          ),
          ElevatedTextButton(
            widthRatio: responsiveSize.scaleSize(160),
            textStyle: TextStyles.buttonMediumText.copyWith(
              fontSize: responsiveSize.scaleSize(TextStyles.buttonMediumText.fontSize!),
            ),
            text: "Finalizar",
            onPressed: () {
              viewModel.handleFinish(context);
            },
          ),
        ],
      ),
    );
  }
}
