import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tuazon_advmobprog/models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // get all users
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();

        return user;
      }).toList();
    });
  }

  // send message
  Future<void> sendMessage(String receiverId, message) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String? currentUserEmail = _firebaseAuth.currentUser!.email;
    final Timestamp timestamp = Timestamp.now();

    MessageModel newMessage = MessageModel(
      senderId: currentUserId,
      senderEmail: currentUserEmail ?? "",
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
    );

    // construct chat room ID for the two users (sorted to ensure uniqueness)
    List<String> ids = [currentUserId, receiverId];
    ids.sort(); // sort the ids (this ensure the chatroomID is the same for any 2 people)
    String chatRoomID = ids.join("_");

    // add new message to database
    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .add(newMessage.toMap());
  }

  // get message
  Stream<QuerySnapshot> getMessage(String userID, otherUserID) {
    // construct chat room ID for the two users (sorted to ensure uniqueness)
    List<String> ids = [userID, otherUserID];
    ids.sort(); // sort the ids (this ensure the chatroomID is the same for any 2 people)
    String chatRoomID = ids.join("_");

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy('timestamp', descending: true)
        // without this the bubble stays on "sending..." until the screen
        // is reopened, because the server acknowledgement only changes
        // the metadata and not the message itself.
        .snapshots(includeMetadataChanges: true);
  }

  // marks every message the other user sent me as seen.
  Future<void> markMessagesAsSeen(String otherUserID) async {
    final String currentUserId = _firebaseAuth.currentUser?.uid ?? "";
    if (currentUserId.isEmpty || otherUserID.isEmpty) return;

    // same sorted id trick the other methods use.
    List<String> ids = [currentUserId, otherUserID];
    ids.sort();
    String chatRoomID = ids.join("_");

    // only the messages addressed to me that are still unseen.
    final unseen = await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .where('receiverId', isEqualTo: currentUserId)
        .where('seen', isEqualTo: false)
        .get();

    if (unseen.docs.isEmpty) return;

    // one batch so all of them update together.
    final batch = _firestore.batch();
    for (final doc in unseen.docs) {
      batch.update(doc.reference, {'seen': true});
    }
    await batch.commit();
  }

  Future<String?> getUidByEmail(String email) async {
    final q = await _firestore
        .collection('Users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (q.docs.isEmpty) return null;

    // Ensure your Users doc actually stores the Firebase Auth UID in a field `uid`
    return (q.docs.first.data()['uid'] ?? '').toString();
  }
}