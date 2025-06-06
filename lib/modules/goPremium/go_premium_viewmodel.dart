import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:fono_terapia/data/auth_repository.dart';
import 'package:fono_terapia/data/user_data_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoPremiumViewModel extends ChangeNotifier {
  final AuthRepository authRepository;
  final UserDataStorage userDataStorage;
  final InAppPurchase iap;
  List<ProductDetails> availableProducts = [];

  bool isPremium = false;

  GoPremiumViewModel({
    required this.authRepository,
    required this.userDataStorage,
    required this.iap,
  }) {
    _fetchAvailableSubscriptions(); // Fetch products without initializing the listener again
    _initializePurchaseListener(); // Hook into the global purchase listener
  }

  // Fetch available subscriptions from the store
  Future<void> _fetchAvailableSubscriptions() async {
    const Set<String> _kIds = <String>{'subscription_monthly'};
    print("Fetching available subscriptions...");
    final ProductDetailsResponse response = await iap.queryProductDetails(_kIds);

    print("ProductDetailsResponse: ${response.productDetails}");
    print("NotFoundIDs: ${response.notFoundIDs}");

    if (response.notFoundIDs.isNotEmpty) {
      print("Subscription product not found: ${response.notFoundIDs}");
    }

    availableProducts = response.productDetails;

    if (availableProducts.isEmpty) {
      print("No products found in the store.");
    } else {
      print("Available products: ${availableProducts.map((p) => p.id).join(', ')}");
    }

    notifyListeners();
  }

  // Start the subscription purchase process
  void startSubscriptionPurchase() {
    if (availableProducts.isNotEmpty) {
      final ProductDetails product = availableProducts.first; // Assuming only one product
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      iap.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      print("No products available for purchase");
    }
  }

  // Access and handle the global listener
  void _initializePurchaseListener() {
    final Stream<List<PurchaseDetails>> purchaseUpdated = iap.purchaseStream;

    print('Attaching local listener to purchaseStream...');
    purchaseUpdated.listen((List<PurchaseDetails> purchaseDetailsList) {
      print('Purchase update received, length: ${purchaseDetailsList.length}');
      for (var purchaseDetails in purchaseDetailsList) {
        print("Purchase details: ${purchaseDetails.productID}, status: ${purchaseDetails.status}");
        handlePurchaseUpdate(purchaseDetails);
      }
    }, onError: (error) {
      print("Error in purchase stream: $error");
    });
  }

  // Confirm the purchase by completing it
  Future<void> confirmPurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.pendingCompletePurchase) {
      try {
        await iap.completePurchase(purchaseDetails);
        print("Purchase completed: ${purchaseDetails.productID}");
      } catch (e) {
        print("Error completing purchase: $e");
      }
    }
  }

  // Handle purchase updates that will come from the global listener
  Future<void> handlePurchaseUpdate(PurchaseDetails purchaseDetails) async {
    print("Handling purchase update: ${purchaseDetails.productID}, status: ${purchaseDetails.status}");

    if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) {
      print("Purchase status valid, verifying subscription...");
      await _verifyAndDeliverSubscription(purchaseDetails);
    } else {
      print("Unhandled purchase status: ${purchaseDetails.status}");
    }

    print("Confirming purchase: ${purchaseDetails.productID}");
    await confirmPurchase(purchaseDetails);
  }

  // Verify and deliver the subscription to the user
  Future<void> _verifyAndDeliverSubscription(PurchaseDetails purchaseDetails) async {
    print("Validating subscription for product: ${purchaseDetails.productID}");

    var user = await authRepository.currentUser;
    if (user == null) {
      print("No authenticated user found.");
      return;
    }

    print("Authenticated user: ${user.uid}");

    var userData = await userDataStorage.loadUserData();
    if (userData == null) {
      print("No user data found in local storage.");
    } else {
      print("User data found, marking as premium.");
      userData.isPremium = true;
      await userDataStorage.saveUserData(userData);
    }

    try {
      print("Updating Firestore for user: ${user.uid}");
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).update({
        'isPremium': true,
      });
      print("Firestore updated successfully.");
    } catch (e) {
      print("Error updating Firestore: $e");
    }

    isPremium = true;
    notifyListeners();
  }
}