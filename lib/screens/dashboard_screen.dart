import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/request_card.dart';
import '../widgets/notification_badge.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/request_model.dart';
import 'send_request_screen.dart';
import 'notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  String _searchQuery = '';
  String _selectedCategory = 'All Mail';
  Stream<List<RequestModel>>? _currentStream;
  Stream<List<RequestModel>>? _unreadStream;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        if (_currentUser != null) {
          _unreadStream = _firestoreService.getUnreadInboxRequests(_currentUser!.branchCode);
        }
        _updateStream();
      });
    }
  }

  void _updateStream() {
    if (_currentUser == null) return;
    
    // Update main list stream
    if (_selectedCategory == 'Sent') {
      _currentStream = _firestoreService.getSentRequests(_currentUser!.branchCode);
    } else if (_selectedCategory == 'Cancelled') {
      _currentStream = _firestoreService.getCancelledRequests(_currentUser!.branchCode);
    } else if (_selectedCategory == 'All Mail') {
      _currentStream = _firestoreService.getAllRequests(_currentUser!.branchCode);
    } else {
      _currentStream = _firestoreService.getInboxRequests(_currentUser!.branchCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentUser!.branchName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          StreamBuilder<List<RequestModel>>(
            stream: _unreadStream,
            builder: (context, snapshot) {
              int count = 0;
              if (snapshot.hasData) {
                count = snapshot.data!.length;
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: IconButton(
                  icon: NotificationBadge(count: count),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationsPage(
                          currentUser: _currentUser!,
                          firestoreService: _firestoreService,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      drawer: AppDrawer(
        onCategorySelected: (category) {
          setState(() {
            _selectedCategory = category;
            _updateStream();
          });
        },
        onProfileUpdated: _loadUser,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderCard(context),
            _buildSearchBar(),
            Expanded(child: _buildStatusList(context)),
          ],
        ),
      ),
      //زر الاضافة
      floatingActionButton: FloatingActionButton(
      
         tooltip: "إرسال طلب",
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SendRequestScreen(user: _currentUser!),
            ),
          );
        },

        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: AppTheme.primaryDarkBlue,
      child: Card(
        elevation: 0,
        color: AppTheme.primaryDarkBlue.withOpacity(0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.primaryGreen, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'كود الفرع الخاص بك',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentUser!.branchCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: AppTheme.primaryGreen),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: _currentUser!.branchCode),
                  );
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('تم نسخ الكود')));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'ابحث عن مرسل، مستلم، أو عنوان...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.textGrey),
          filled: true,
          fillColor: AppTheme.inputLightGrey,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusList(BuildContext context) {
    if (_currentStream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<RequestModel>>(
      stream: _currentStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }

        List<RequestModel> requests = snapshot.data ?? [];

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          requests = requests
              .where(
                (r) =>
                    r.senderName.toLowerCase().contains(_searchQuery) ||
                    r.receiverName.toLowerCase().contains(_searchQuery) ||
                    r.messageTitle.toLowerCase().contains(_searchQuery),
              )
              .toList();
        }

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 80,
                  color: AppTheme.textGrey.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'فارغ ',
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 18),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final isSentCategory = _selectedCategory == 'Sent';
            final isUnread = (!req.isRead && !isSentCategory && req.receiverCode == _currentUser!.branchCode);
            final isSent = req.senderCode == _currentUser!.branchCode;

            return RequestCard(
              request: req,
              currentUser: _currentUser!,
              isUnread: isUnread,
              icon: _selectedCategory == 'All Mail'
                  ? (isSent ? Icons.outbox : Icons.move_to_inbox)
                  : null,
              iconColor: _selectedCategory == 'All Mail'
                  ? (isSent ? Colors.orange : AppTheme.primaryDarkBlue)
                  : null,
              onTapAction: () {
                if (isUnread) {
                  _firestoreService.markAsRead(req.id);
                }
              },
              onStatusChange: (newStatus) async {
                await _firestoreService.updateRequestStatus(req.id, newStatus);
              },
            );
          },
        );
      },
    );
  }
}
