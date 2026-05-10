import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send a new request
  Future<void> sendRequest(RequestModel request) async {
    try {
      await _firestore
          .collection(AppConstants.requestsCollection)
          .doc(request.id)
          .set(request.toMap());
    } catch (e) {
      throw Exception("Failed to send request: ${e.toString()}");
    }
  }

  // Update existing request (Full Edit)
  Future<void> updateRequest(RequestModel request) async {
    try {
      await _firestore
          .collection(AppConstants.requestsCollection)
          .doc(request.id)
          .update(request.toMap());
    } catch (e) {
      throw Exception("Failed to update request: ${e.toString()}");
    }
  }

  // Update request status
  Future<void> updateRequestStatus(String requestId, String newStatus) async {
    try {
      await _firestore
          .collection(AppConstants.requestsCollection)
          .doc(requestId)
          .update({'status': newStatus});
    } catch (e) {
      throw Exception("Failed to update status: ${e.toString()}");
    }
  }

  // Delete request permanently
  Future<void> deleteRequest(String requestId) async {
    try {
      await _firestore
          .collection(AppConstants.requestsCollection)
          .doc(requestId)
          .delete();
    } catch (e) {
      throw Exception("Failed to delete request: ${e.toString()}");
    }
  }

  // Mark request as read
  Future<void> markAsRead(String requestId) async {
    try {
      await _firestore
          .collection(AppConstants.requestsCollection)
          .doc(requestId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception("Failed to mark as read: ${e.toString()}");
    }
  }

  // Stream Unread Inbox: receiverCode == branchCode AND status != 'cancelled' AND isRead == false
  Stream<List<RequestModel>> getUnreadInboxRequests(String branchCode) {
    return _firestore
        .collection(AppConstants.requestsCollection)
        .where('receiverCode', isEqualTo: branchCode)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) => RequestModel.fromMap(doc.data(), doc.id)).toList();
          final unreadDocs = docs.where((doc) => 
            doc.isRead == false && doc.status != AppConstants.statusCancelled
          ).toList();
          unreadDocs.sort((a, b) => b.date.compareTo(a.date));
          return unreadDocs;
        });
  }

  // Stream Inbox: receiverCode == branchCode AND status != 'cancelled'
  Stream<List<RequestModel>> getInboxRequests(String branchCode) {
    return _firestore
        .collection(AppConstants.requestsCollection)
        .where('receiverCode', isEqualTo: branchCode)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) => RequestModel.fromMap(doc.data(), doc.id)).toList();
          final filteredDocs = docs.where((doc) => doc.status != AppConstants.statusCancelled).toList();
          filteredDocs.sort((a, b) => b.date.compareTo(a.date));
          return filteredDocs;
        });
  }
  
  // Stream Sent: senderCode == branchCode AND status != 'cancelled'
  Stream<List<RequestModel>> getSentRequests(String branchCode) {
    return _firestore
        .collection(AppConstants.requestsCollection)
        .where('senderCode', isEqualTo: branchCode)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) => RequestModel.fromMap(doc.data(), doc.id)).toList();
          final filteredDocs = docs.where((doc) => doc.status != AppConstants.statusCancelled).toList();
          filteredDocs.sort((a, b) => b.date.compareTo(a.date));
          return filteredDocs;
        });
  }

  // Stream Cancelled: status == 'cancelled' AND senderCode == code
  Stream<List<RequestModel>> getCancelledRequests(String branchCode) {
    return _firestore
        .collection(AppConstants.requestsCollection)
        .where('senderCode', isEqualTo: branchCode)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) => RequestModel.fromMap(doc.data(), doc.id)).toList();
          final filteredDocs = docs.where((doc) => doc.status == AppConstants.statusCancelled).toList();
          filteredDocs.sort((a, b) => b.date.compareTo(a.date));
          return filteredDocs;
        });
  }

  // Generic stream by status (if still needed, updating to handle receiverCode)
  Stream<List<RequestModel>> getRequestsByStatus(String branchCode, String status) {
    return _firestore
        .collection(AppConstants.requestsCollection)
        .where('receiverCode', isEqualTo: branchCode)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) => RequestModel.fromMap(doc.data(), doc.id)).toList();
          final filteredDocs = docs.where((doc) => doc.status == status).toList();
          filteredDocs.sort((a, b) => b.date.compareTo(a.date));
          return filteredDocs;
        });
  }
  // Get all users for branch search
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _firestore.collection(AppConstants.usersCollection).get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  // Get all requests (Inbox + Sent)
  Stream<List<RequestModel>> getAllRequests(String branchCode) {
    final inboxStream = getInboxRequests(branchCode);
    final sentStream = getSentRequests(branchCode);
    
    late StreamController<List<RequestModel>> controller;
    List<RequestModel> inbox = [];
    List<RequestModel> sent = [];
    
    void update() {
        final combined = [...inbox, ...sent];
        final map = <String, RequestModel>{};
        for(var req in combined) { map[req.id] = req; }
        final unique = map.values.toList();
        unique.sort((a, b) => b.date.compareTo(a.date));
        controller.add(unique);
    }

    StreamSubscription? inboxSub;
    StreamSubscription? sentSub;

    controller = StreamController<List<RequestModel>>.broadcast(
      onListen: () {
        inboxSub = inboxStream.listen((data) {
          inbox = data;
          update();
        });
        sentSub = sentStream.listen((data) {
          sent = data;
          update();
        });
      },
      onCancel: () {
        inboxSub?.cancel();
        sentSub?.cancel();
      }
    );
    return controller.stream;
  }
}
