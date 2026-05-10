import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/request_model.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../services/firestore_service.dart';
import 'send_request_screen.dart';

class RequestDetailScreen extends StatelessWidget {
  final RequestModel request;
  final UserModel currentUser;

  const RequestDetailScreen({
    super.key,
    required this.request,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.requestsCollection)
          .doc(request.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('خطأ: ${snapshot.error}')));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('الطلب لم يعد موجوداً')),
          );
        }

        final updatedRequest = RequestModel.fromMap(
          snapshot.data!.data() as Map<String, dynamic>,
          snapshot.data!.id,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('تفاصيل الطلب'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildStatusHeader(updatedRequest),
                        const SizedBox(height: 24),

                        //تفاصيل الرسالة
                        _buildDetailCard(
                          title: 'تفاصيل الرسالة',
                          icon: Icons.subject,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow('العنوان', updatedRequest.messageTitle, isBoldValue: true),
                              const Divider(),
                              const Text(
                                'المحتوى / الملاحظات:',
                                style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                updatedRequest.notes.isNotEmpty ? updatedRequest.notes : 'لا توجد تفاصيل إضافية.',
                                style: const TextStyle(height: 1.5, fontSize: 15),
                              ),
                            ],
                          ),
                        ),

                        //معلومات الرسالة
                        //const SizedBox(height: 16),
                        _buildDetailCard(
                          title: 'معلومات الإرسال',
                          icon: Icons.local_shipping_outlined,
                          content: Column(
                            children: [
                        _buildDetailRow('كود المكتب', updatedRequest.senderCode, isBoldValue: true),
                        const Divider(),
                        _buildDetailRow('اسم المكتب', updatedRequest.senderName),
                        const Divider(),     
                        _buildDetailRow('تاريخ الإرسال', DateFormat('yyyy-MM-dd – kk:mm').format(updatedRequest.date)),
                            ],
                          ),
                        ),
                          //بيانات المندوب

                       // const SizedBox(height: 16),
                        _buildDetailCard(
                          title: 'بيانات المندوب',
                          icon: Icons.delivery_dining,
                          content: Column(
                            children: [
                              _buildDetailRow('اسم المندوب', updatedRequest.delegateName.isNotEmpty ? updatedRequest.delegateName : 'غير محدد'),
                              const Divider(),
                              _buildDetailRow('رقم الهاتف', updatedRequest.delegatePhone.isNotEmpty ? updatedRequest.delegatePhone : 'غير محدد'),
                            ],
                          ),
                        ),
                        //بيانات المستلم

                       _buildDetailCard(
                          title: 'بيانات المستلم',
                          icon: Icons.person,
                          content: Column(
                            children: [
                              _buildDetailRow("اسم المستلم", updatedRequest.receiverName),
                              const Divider(),
                              _buildDetailRow('هاتف المستلم', updatedRequest.receiverPhone),
                            ],
                          ),),


                       // const SizedBox(height: 16),
                            //بيانات المرسل
                         _buildDetailCard(
                          title: 'بيانات المرسل',
                          icon: Icons.person,
                          content: Column(
                            children: [
                               _buildDetailRow('اسم المرسل', updatedRequest.officeName),
                              const Divider(),
                              _buildDetailRow('هاتف المرسل', updatedRequest.senderNumber),
                            ],
                          ),),

                          //تفاصيل الدفع
                        _buildDetailCard(
                          title: 'تفاصيل الدفع',
                          icon: Icons.payment,
                          content: Column(
                            children: [
                              _buildDetailRow('رسوم التوصيل', updatedRequest.messageFee.isNotEmpty ? '${updatedRequest.messageFee} ريال' : 'غير محدد', isBoldValue: true, valueColor: AppTheme.primaryDarkBlue),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildActionButtons(context, updatedRequest),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, RequestModel req) {
    final bool isSender = req.senderCode == currentUser.branchCode;
    final bool isReceiver = req.receiverCode == currentUser.branchCode;
    final bool isPending = req.status == AppConstants.statusPending;

    List<Widget> buttons = [];

    // Receiver Action: Mark as Delivered
    if (isReceiver && isPending) {
      buttons.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton.icon(
              onPressed: () => _updateStatus(context, req.id, AppConstants.statusDelivered),
              icon: const Icon(Icons.check_circle),
              label: const Text('تأكيد الوصول'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            ),
          ),
        ),
      );
    }

    // Sender Actions: Edit & Cancel (Only if pending)
    if (isSender && isPending) {
      buttons.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SendRequestScreen(
                      user: currentUser,
                      editRequest: req,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('تعديل'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryDarkBlue, foregroundColor: Colors.white),
            ),
          ),
        ),
      );
      buttons.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ElevatedButton.icon(
              onPressed: () => _confirmCancel(context, req.id),
              icon: const Icon(Icons.cancel),
              label: const Text('إلغاء'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            ),
          ),
        ),
      );
    }

    // Sender Actions: Permanent Delete (Only if cancelled)
    if (isSender && req.status == AppConstants.statusCancelled) {
      buttons.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ElevatedButton.icon(
              onPressed: () => _confirmDelete(context, req.id),
              icon: const Icon(Icons.delete_forever),
              label: const Text('حذف نهائي'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            ),
          ),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Row(children: buttons),
    );
  }

  Future<void> _updateStatus(BuildContext context, String id, String status) async {
    try {
      await FirestoreService().updateRequestStatus(id, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الحالة بنجاح'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmCancel(BuildContext context, String id) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء الطلب'),
        content: const Text('هل أنت متأكد من إلغاء هذا الطلب؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('نعم، إلغاء', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      _updateStatus(context, id, AppConstants.statusCancelled);
    }
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف نهائي'),
        content: const Text('هل أنت متأكد من حذف هذا الطلب نهائياً؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('نعم، حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirestoreService().deleteRequest(id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم الحذف بنجاح'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildStatusHeader(RequestModel req) {
    Color statusColor = _getStatusColor(req.status);
    String statusText = AppConstants.statusTranslations[req.status] ?? req.status;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryDarkBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(_getStatusIcon(req.status), color: statusColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'طلب رقم #${req.id.length > 8 ? req.id.substring(0, 8) : req.id}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({required String title, required IconData icon, required Widget content}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryDarkBlue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDarkBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBoldValue = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(color: AppTheme.textGrey))),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isBoldValue ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? AppTheme.primaryDarkBlue,
                fontSize: isBoldValue ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return Icons.hourglass_empty;
      case AppConstants.statusDelivered:
        return Icons.check_circle;
      case AppConstants.statusCancelled:
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}
