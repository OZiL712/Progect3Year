import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/request_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/request_card.dart';

class NotificationsPage extends StatefulWidget {
  final UserModel currentUser;
  final FirestoreService firestoreService;

  const NotificationsPage({
    super.key,
    required this.currentUser,
    required this.firestoreService,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final Set<String> _viewedIds = {};

  @override
  void dispose() {
    _markViewedAsRead();
    super.dispose();
  }

  void _markViewedAsRead() {
    for (String id in _viewedIds) {
      widget.firestoreService.markAsRead(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
      ),
      body: StreamBuilder<List<RequestModel>>(
        // We stream ONLY unread messages here
        stream: widget.firestoreService.getUnreadInboxRequests(widget.currentUser.branchCode),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }

          final unreadRequests = snapshot.data ?? [];
          
          // Keep track of any unread message we have shown on screen
          for (var req in unreadRequests) {
            _viewedIds.add(req.id);
          }
          
          if (unreadRequests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: AppTheme.textGrey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد إشعارات جديدة',
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            itemCount: unreadRequests.length,
            itemBuilder: (context, index) {
              final req = unreadRequests[index];
              return RequestCard(
                request: req,
                currentUser: widget.currentUser,
                onTapAction: () {
                  // Specific message clicked: mark as read immediately
                  widget.firestoreService.markAsRead(req.id);
                },
                onStatusChange: (newStatus) async {
                  await widget.firestoreService.updateRequestStatus(req.id, newStatus);
                },
              );
            },
          );
        },
      ),
    );
  }
}

