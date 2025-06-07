import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fono_terapia/data/auth_repository.dart';
import 'package:fono_terapia/data/game_result_repository.dart';
import 'package:fono_terapia/data/service/user_service.dart';
import 'package:fono_terapia/data/user_data_storage.dart';
import 'package:fono_terapia/database/app_database.dart';
import 'package:fono_terapia/database/dao/category_dao.dart';
import 'package:fono_terapia/database/firebase_database.dart';
import 'package:fono_terapia/shared/utils/responsive_size.dart';
import 'package:fono_terapia/shared/utils/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class AppInitializer {
  static late Database database;
  static late ResponsiveSize responsiveSize;
  static late AuthRepository authRepository;
  static late GameResultRepository gameResultRepository;
  static late UserService userService;
  static late UserDataStorage userDataStorage;
  static late FirebaseDatabase firebaseDatabase;
  static late CategoryDao categoryDao;
  static late InAppPurchase inAppPurchase;

  // Shared state for purchases
  static List<PurchaseDetails> activePurchases = [];
  static bool purchasesRestored =
      false; // Flag to check if purchases are restored

  static Future<void> logout() async {
    await authRepository.signOut();
    await userDataStorage.clearUserData();
    activePurchases = [];
    purchasesRestored = false;
    logDebug("Logged out, cleared purchase state.");
  }

  static Future<void> initializeApp(BuildContext context) async {
    try {
      logDebug("[AppInitializer] Starting app initialization...");

      // Initialize Firebase
      logDebug("[AppInitializer] Initializing Firebase...");
      await Firebase.initializeApp(
          // options: DefaultFirebaseOptions.currentPlatform,
          );
      logDebug("[AppInitializer] Firebase initialized successfully.");

      // Initialize database
      logDebug("[AppInitializer] Initializing local database...");
      database = await openOrInitializeDatabase();
      logDebug("[AppInitializer] Local database initialized successfully.");

      // Initialize responsiveSize
      logDebug("[AppInitializer] Initializing responsiveSize...");
      responsiveSize = ResponsiveSize(mediaQueryData: MediaQuery.of(context));
      logDebug("[AppInitializer] responsiveSize initialized successfully.");

      // Initialize Auth and UserService
      logDebug(
          "[AppInitializer] Initializing authentication and user services...");
      authRepository = AuthRepository();
      userDataStorage = UserDataStorage();
      userService = UserService(userDataStorage);
      logDebug("[AppInitializer] Auth and UserService initialized successfully.");

      // Initialize FirebaseDatabase
      logDebug("[AppInitializer] Initializing Firebase Database...");
      firebaseDatabase = FirebaseDatabase();
      logDebug("[AppInitializer] Firebase Database initialized successfully.");

      // Initialize DAOs
      logDebug("[AppInitializer] Initializing DAOs...");
      categoryDao = CategoryDao();
      gameResultRepository = GameResultRepository(
          firebaseDatabase: firebaseDatabase, db: database);
      logDebug("[AppInitializer] DAOs initialized successfully.");

      logDebug("[AppInitializer] App initialization completed successfully.");
    } catch (e) {
      logDebug("[AppInitializer] Error during app initialization: $e");
      rethrow;
    }
  }

  // New function that initializes the in-app purchase services and validation logic
  static Future<void> initializePurchaseServices() async {
    logDebug("INITIALIZING PURCHASE SERVICES");
    // Initialize InAppPurchase instance and listener
    inAppPurchase = InAppPurchase.instance;

    // Initialize the purchase listener
    _initializePurchaseListener();

    // Restore purchases
    await _restorePurchases();

    // Validate subscription
    await _validateSubscription();
  }

  static void _initializePurchaseListener() {
    logDebug('Initializing global purchase listener');
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        inAppPurchase.purchaseStream;

    logDebug('Attaching global listener to purchaseStream...');
    purchaseUpdated.listen((List<PurchaseDetails> purchaseDetailsList) {
      logDebug(
          'Global purchase update received, length: ${purchaseDetailsList.length}');
      activePurchases =
          purchaseDetailsList; // Store the received purchases globally
    }, onError: (error) {
      logDebug("Error in global purchase stream: $error");
    });
  }

  static Future<void> _restorePurchases() async {
    logDebug("Restoring previous purchases...");
    purchasesRestored = false; // Reset flag

    try {
      await inAppPurchase.restorePurchases();
      logDebug("Purchases restored successfully");
      purchasesRestored = true; // Mark as restored
    } catch (e) {
      logDebug("Error restoring purchases: $e");
      purchasesRestored =
          true; // Mark as done, even on failure to avoid blocking
    }
  }

  // Add a function to validate the subscription
  static Future<void> _validateSubscription() async {
    logDebug("Validating subscription status at startup...");

    // Wait until `activePurchases` is populated
    if (activePurchases.isEmpty) {
      logDebug("Waiting for global purchase data...");
      await Future.delayed(Duration(seconds: 2));
    }

    bool subscriptionIsActive = false;

    for (var purchaseDetails in activePurchases) {
      if (purchaseDetails.productID == 'subscription_monthly' &&
          (purchaseDetails.status == PurchaseStatus.purchased ||
              purchaseDetails.status == PurchaseStatus.restored)) {
        subscriptionIsActive = await _verifySubscription(purchaseDetails);
        break;
      }
    }

    // Update local storage and Firestore based on subscription validity
    if (authRepository.currentUser != null) {
      await _updateSubscriptionStatus(subscriptionIsActive);
    }

    if (!subscriptionIsActive) {
      logDebug("Subscription is not active.");
    } else {
      logDebug("Subscription is active.");
    }
  }

  // Verify subscription with the store (App Store/Play Store)
  static Future<bool> _verifySubscription(
      PurchaseDetails purchaseDetails) async {
    logDebug("Verifying subscription for product: ${purchaseDetails.productID}");

    // Add any additional logic for verifying receipt if needed here
    return purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored;
  }

  // Update Firestore and local data if subscription status changes
  static Future<void> _updateSubscriptionStatus(bool isPremium) async {
    var user = await authRepository.currentUser;
    if (user != null) {
      var userData = await userDataStorage.loadUserData();
      if (userData != null) {
        userData.isPremium = isPremium;
        await userDataStorage.saveUserData(userData);

        // Update Firestore
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .update({
          'isPremium': isPremium,
        });
        logDebug('Subscription status updated in Firestore: $isPremium');
      }
    }
  }
}
