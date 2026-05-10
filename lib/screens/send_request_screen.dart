import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/custom_textfield.dart';
import '../widgets/custom_button.dart';
import '../models/user_model.dart';
import '../models/request_model.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';

class SendRequestScreen extends StatefulWidget {
  final UserModel user;
  final RequestModel? editRequest;

  const SendRequestScreen({super.key, required this.user, this.editRequest});

  @override
  State<SendRequestScreen> createState() => _SendRequestScreenState();
}

class _SendRequestScreenState extends State<SendRequestScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _receiverCodeCtrl; //1
  late final TextEditingController _officeNameCtrl; //5
  late final TextEditingController _senderNameCtrl;
  late final TextEditingController _receiverNameCtrl; //3
  late final TextEditingController _delegateNameCtrl; //7
  late final TextEditingController _receiverPhoneCtrl; //4
  late final TextEditingController _senderNumberCtrl; //6
  late final TextEditingController _delegatePhoneCtrl; //8
  late final TextEditingController _messageFeeCtrl; //9
  late final TextEditingController _messageTitleCtrl; //2
  late final TextEditingController _notesCtrl;

  bool _isLoading = false;
  List<UserModel> _allUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    final req = widget.editRequest;

    _receiverCodeCtrl = TextEditingController(text: req?.receiverCode ?? '');
    _officeNameCtrl = TextEditingController(text: req?.officeName ?? '');
    _senderNameCtrl = TextEditingController(
      text: req?.senderName ?? widget.user.branchName,
    );
    _receiverNameCtrl = TextEditingController(text: req?.receiverName ?? '');
    _delegateNameCtrl = TextEditingController(text: req?.delegateName ?? '');
    _receiverPhoneCtrl = TextEditingController(text: req?.receiverPhone ?? '');
    _senderNumberCtrl = TextEditingController(text: req?.senderNumber ?? '');
    _delegatePhoneCtrl = TextEditingController(text: req?.delegatePhone ?? '');
    _messageFeeCtrl = TextEditingController(text: req?.messageFee ?? '');
    _messageTitleCtrl = TextEditingController(text: req?.messageTitle ?? '');
    _notesCtrl = TextEditingController(text: req?.notes ?? '');
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _firestoreService.getAllUsers();
      if (mounted) {
        setState(() {
          _allUsers = users;
        });
      }
    } catch (e) {
      debugPrint("Error loading users: $e");
    }
  }

  @override
  void dispose() {
    _receiverCodeCtrl.dispose();
    _officeNameCtrl.dispose();
    _senderNameCtrl.dispose();
    _receiverNameCtrl.dispose();
    _delegateNameCtrl.dispose();
    _receiverPhoneCtrl.dispose();
    _senderNumberCtrl.dispose();
    _delegatePhoneCtrl.dispose();
    _messageFeeCtrl.dispose();
    _messageTitleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final receiverCode = _receiverCodeCtrl.text.trim();
    if (receiverCode.isEmpty) return;

    final receiverExists = _allUsers.any((u) => u.branchCode == receiverCode);
    if (!receiverExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كود الفرع غير موجود (Branch code does not exist)'), backgroundColor: Colors.red),
      );
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          widget.editRequest == null ? 'تأكيد الإرسال' : 'تأكيد التعديل',
        ),
        content: Text(
          widget.editRequest == null
              ? 'هل أنت متأكد من إرسال هذا الطلب؟'
              : 'هل أنت متأكد من حفظ التعديلات؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final isEditing = widget.editRequest != null;
        final request = RequestModel(
          id: isEditing ? widget.editRequest!.id : const Uuid().v4(),
          receiverCode: _receiverCodeCtrl.text.trim(),
          senderCode: widget.user.branchCode,
          officeName: _officeNameCtrl.text.trim(),
          senderName: _senderNameCtrl.text.trim(),
          receiverName: _receiverNameCtrl.text.trim(),
          delegateName: _delegateNameCtrl.text.trim(),
          receiverPhone: _receiverPhoneCtrl.text.trim(),
          senderNumber: _senderNumberCtrl.text.trim(),
          delegatePhone: _delegatePhoneCtrl.text.trim(),
          messageFee: _messageFeeCtrl.text.trim(),
          messageTitle: _messageTitleCtrl.text.trim(),
          date: isEditing ? widget.editRequest!.date : DateTime.now(),
          notes: _notesCtrl.text.trim(),
          status: isEditing
              ? widget.editRequest!.status
              : AppConstants.statusPending,
        );

        if (isEditing) {
          await _firestoreService.updateRequest(request);
        } else {
          await _firestoreService.sendRequest(request);
          await _sendSmsNotification(
            _receiverPhoneCtrl.text.trim(),
            _messageTitleCtrl.text.trim(),
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing ? 'تم تعديل الطلب بنجاح' : 'تم إرسال الطلب بنجاح',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _sendSmsNotification(String phone, String title) async {
    final message = Uri.encodeComponent(
      "لديك طلب جديد: $title من ${widget.user.branchName}.",
    );
    final uri = Uri.parse("sms:$phone?body=$message");
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint("Could not launch SMS app: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editRequest == null ? 'إرسال طلب جديد' : 'تعديل الطلب',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Autocomplete<UserModel>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<UserModel>.empty();
                    }
                    return _allUsers.where((UserModel user) {
                      return user.branchName.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                             user.branchCode.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                             (user.location != null && user.location!.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    });
                  },
                  displayStringForOption: (UserModel option) => option.branchCode,
                  onSelected: (UserModel selection) {
                    _receiverCodeCtrl.text = selection.branchCode;
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    if (_receiverCodeCtrl.text.isNotEmpty && controller.text.isEmpty) {
                      controller.text = _receiverCodeCtrl.text;
                    }
                    controller.addListener(() {
                      _receiverCodeCtrl.text = controller.text;
                    });
                    return CustomTextField(
                      controller: controller,
                      focusNode: focusNode,
                      onFieldSubmitted: (v) => onFieldSubmitted(),
                      hintText: 'كود المستلم (الفرع الوجهة)',
                      validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final UserModel option = options.elementAt(index);
                              return ListTile(
                                title: Text('${option.branchName} (${option.branchCode})'),
                                subtitle: Text(option.location ?? 'لا يوجد موقع'),
                                onTap: () {
                                  onSelected(option);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _messageTitleCtrl,
                  hintText: 'عنوان الرسالة / الطلب',
                  validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _receiverNameCtrl,
                        hintText: 'اسم المستلم ',
                        validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        controller: _receiverPhoneCtrl,
                        hintText: 'هاتف المستلم',
                        keyboardType: TextInputType.phone,
                        validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _officeNameCtrl,
                        hintText: 'اسم المرسل',
                        validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        controller: _senderNumberCtrl,
                        hintText: 'هاتف المرسل',
                        validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _delegateNameCtrl,
                        hintText: 'اسم المندوب',
                        validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        controller: _delegatePhoneCtrl,
                        hintText: 'هاتف المندوب',
                        keyboardType: TextInputType.phone,
                        validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _messageFeeCtrl,
                  hintText: 'رسوم الرسالة',
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _notesCtrl,
                  hintText: 'ملاحظات (اختياري)',
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: widget.editRequest == null
                      ? 'إرسال الطلب'
                      : 'حفظ التعديلات',
                  onPressed: _submitRequest,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
