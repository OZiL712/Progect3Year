import 'package:flutter/material.dart';
import '../models/request_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../screens/request_detail_screen.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';

class RequestCard extends StatelessWidget {
  final RequestModel request;
  final UserModel currentUser;
  final Function(String newStatus)? onStatusChange;
  final VoidCallback? onTapAction;
  final bool isUnread;
  final IconData? icon;
  final Color? iconColor;

  const RequestCard({
    super.key,
    required this.request,
    required this.currentUser,
    this.onStatusChange,
    this.onTapAction,
    this.isUnread = false,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCancelled = request.status == AppConstants.statusCancelled;
    final bool isSender = request.senderCode == currentUser.branchCode;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isUnread ? Colors.blue.shade50 : null,
      clipBehavior: Clip.antiAlias,
      elevation: isUnread ? 4 : 1,
      child: InkWell(
        onTap: () {
          if (onTapAction != null) {
            onTapAction!();
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RequestDetailScreen(
                request: request,
                currentUser: currentUser,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: iconColor, size: 24),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      request.messageTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: isUnread ? FontWeight.w900 : FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(request.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppConstants.statusTranslations[request.status] ?? request.status,
                      style: TextStyle(
                        color: _getStatusColor(request.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text("اسم المكتب: ${request.senderName}"),
              Text("اسم المرسل: ${request.officeName}"),
              Text("اسم المستلم: ${request.receiverName}"),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "التاريخ: ${DateFormat('yyyy-MM-dd – kk:mm').format(request.date)}",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  if (isCancelled && isSender)
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: () => _confirmDelete(context),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف دائم'),
        content: const Text('هل أنت متأكد من حذف هذه الرسالة نهائياً؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirestoreService().deleteRequest(request.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم الحذف بنجاح'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في الحذف: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return Colors.orange;
      case AppConstants.statusDelivered:
        return Colors.green;
      case AppConstants.statusCancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
