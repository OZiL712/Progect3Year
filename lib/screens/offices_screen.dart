import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class OfficesScreen extends StatefulWidget {
  const OfficesScreen({super.key});

  @override
  State<OfficesScreen> createState() => _OfficesScreenState();
}

class _OfficesScreenState extends State<OfficesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<UserModel> _allOffices = [];
  List<UserModel> _filteredOffices = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadOffices();
  }

  Future<void> _loadOffices() async {
    try {
      final offices = await _firestoreService.getAllUsers();
      if (mounted) {
        setState(() {
          _allOffices = offices;
          _filteredOffices = offices;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterOffices(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredOffices = _allOffices.where((office) {
        return office.branchName.toLowerCase().contains(_searchQuery) ||
            office.branchCode.toLowerCase().contains(_searchQuery) ||
            (office.location != null && office.location!.toLowerCase().contains(_searchQuery));
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دليل الفروع والمكاتب'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filterOffices,
              decoration: InputDecoration(
                hintText: 'ابحث عن فرع، كود، أو موقع...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textGrey),
                filled: true,
                fillColor: AppTheme.inputLightGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOffices.isEmpty
                    ? const Center(
                        child: Text(
                          'لم يتم العثور على أي فروع',
                          style: TextStyle(color: AppTheme.textGrey, fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredOffices.length,
                        itemBuilder: (context, index) {
                          final office = _filteredOffices[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppTheme.primaryDarkBlue,
                                child: Icon(Icons.business, color: Colors.white),
                              ),
                              title: Text(
                                office.branchName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('الموقع: ${office.location ?? 'غير محدد'}'),
                                  const SizedBox(height: 4),
                                  Text(
                                    'كود الفرع: ${office.branchCode}',
                                    style: const TextStyle(
                                      color: AppTheme.primaryDarkBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.copy, color: AppTheme.primaryGreen),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: office.branchCode));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('تم نسخ كود الفرع')),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
