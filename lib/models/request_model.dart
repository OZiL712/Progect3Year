import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String id;
  final String receiverCode;
  final String senderCode;
  final String officeName;
  final String senderName;
  final String receiverName;
  final String delegateName;
  final String receiverPhone;
  final String senderNumber;
  final String delegatePhone;
  final String messageFee;
  final String messageTitle;
  final DateTime date;
  final String notes;
  final String status;
  final bool isRead;

  RequestModel({
    required this.id,
    required this.receiverCode,
    required this.senderCode,
    required this.officeName,
    required this.senderName,
    required this.receiverName,
    required this.delegateName,
    required this.receiverPhone,
    required this.senderNumber,
    required this.delegatePhone,
    required this.messageFee,
    required this.messageTitle,
    required this.date,
    required this.notes,
    required this.status,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receiverCode': receiverCode,
      'senderCode': senderCode,
      'officeName': officeName,
      'senderName': senderName,
      'receiverName': receiverName,
      'delegateName': delegateName,
      'receiverPhone': receiverPhone,
      'senderNumber': senderNumber,
      'delegatePhone': delegatePhone,
      'messageFee': messageFee,
      'messageTitle': messageTitle,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'status': status,
      'isRead': isRead,
    };
  }

  factory RequestModel.fromMap(Map<String, dynamic> map, String docId) {
    return RequestModel(
      id: docId,
      receiverCode: map['receiverCode'] ?? '',
      senderCode: map['senderCode'] ?? '',
      officeName: map['officeName'] ?? '',
      senderName: map['senderName'] ?? '',
      receiverName: map['receiverName'] ?? '',
      delegateName: map['delegateName'] ?? '',
      receiverPhone: map['receiverPhone'] ?? '',
      senderNumber: map['senderNumber'] ?? '',
      delegatePhone: map['delegatePhone'] ?? '',
      messageFee: map['messageFee'] ?? '',
      messageTitle: map['messageTitle'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: map['notes'] ?? '',
      status: map['status'] ?? 'pending',
      isRead: map['isRead'] ?? false,
    );
  }
}
