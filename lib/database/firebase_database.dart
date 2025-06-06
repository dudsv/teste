import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseDatabase {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future addUser(String userId, Map<String, dynamic> userInfoMap) {
    return firestore
        .collection("Users")
        .doc(userId)
        .set(userInfoMap);
  }

  Future<void> addGameResult(String userId, Map<String, dynamic> gameResultMap) async {
    await firestore
        .collection('Users')
        .doc(userId)
        .collection('gameResults')
        .add(gameResultMap);
  }

  Future<List<Map<String, dynamic>>> getGameResults(String userId) async {
    final querySnapshot = await firestore
        .collection('Users')
        .doc(userId)
        .collection('gameResults')
        .get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }
}