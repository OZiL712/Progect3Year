import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/custom_button.dart';


class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  bool _isLogin = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _branchNameCtrl = TextEditingController();
  final _branchIdCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _authService.login(
          branchCode: _branchIdCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );
        // Navigation handled by stream builder in main.dart
      } else {
        await _authService.signUp(
          branchName: _branchNameCtrl.text.trim(),
          location: _locationCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );
        // Navigation handled by stream builder in main.dart
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.startsWith('Exception: ')) {
          errorMsg = errorMsg.substring(11);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showResetPasswordDialog(BuildContext context) {
    final resetEmailCtrl = TextEditingController();
    bool isResetLoading = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('استعادة كلمة المرور', style: TextStyle(color: AppTheme.primaryDarkBlue, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'أدخل البريد الإلكتروني الخاص بحسابك لإرسال رابط إعادة تعيين كلمة المرور.',
                  style: TextStyle(color: AppTheme.textGrey),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: resetEmailCtrl,
                  hintText: 'البريد الإلكتروني',
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isResetLoading ? null : () => Navigator.pop(ctx),
                child: const Text('إلغاء', style: TextStyle(color: AppTheme.textGrey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryDarkBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isResetLoading
                    ? null
                    : () async {
                        if (resetEmailCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('الرجاء إدخال البريد الإلكتروني'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        setState(() {
                          isResetLoading = true;
                        });

                        try {
                          await _authService.resetPassword(resetEmailCtrl.text.trim());
                          if (mounted) {
                            Navigator.pop(ctx);
                            // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم إرسال رابط استعادة كلمة المرور بنجاح! Please check your email for the verification link. If you don\'t see it, check your Spam/Junk folder.'),
                                backgroundColor: AppTheme.primaryGreen,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              isResetLoading = false;
                            });
                          }
                        }
                      },
                child: isResetLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('إرسال', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.local_shipping_outlined,
                    size: 80,
                    color: AppTheme.primaryDarkBlue,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isLogin ? 'تسجيل الدخول' : 'إنشاء حساب جديد',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDarkBlue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (!_isLogin) ...[
                    CustomTextField(
                      controller: _branchNameCtrl,
                      hintText: 'اسم الفرع',
                      validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _emailCtrl,
                      hintText: 'البريد الإلكتروني',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v!.isEmpty ? 'مطلوب' : (!v.contains('@') ? 'غير صالح' : null),
                    ),
                    CustomTextField(
                      controller: _locationCtrl,
                      hintText: 'موقع الفرع / Location',
                      validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_isLogin) ...[
                    CustomTextField(
                      controller: _branchIdCtrl,
                      hintText: 'كود الفرع',
                      validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                    ),
                  ],
                  if (!_isLogin)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0, right: 8.0),
                      child: Text(
                        'سيتم إنشاء كود الفرع الخاص بك تلقائياً بعد التسجيل',
                        style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordCtrl,
                    hintText: 'كلمة المرور',
                    isPassword: true,
                    validator: (v) => v!.length < 8 ? '8 أحرف كحد أدنى' : null,
                  ),
                  const SizedBox(height: 8),
                  if (_isLogin)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          _showResetPasswordDialog(context);
                        },
                        child: const Text(
                          'هل نسيت كلمة المرور؟',
                          style: TextStyle(color: AppTheme.primaryDarkBlue),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: _isLogin ? 'دخول' : 'تسجيل',
                    onPressed: _submit,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),
                  if (_isLogin)
                    OutlinedButton(
                      onPressed: _isLoading ? null : _toggleMode,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryDarkBlue,
                        side: const BorderSide(color: AppTheme.primaryDarkBlue),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('إنشاء حساب جديد'),
                    )
                  else
                    TextButton(
                      onPressed: _isLoading ? null : _toggleMode,
                      child: const Text(
                        'لديك حساب بالفعل؟ تسجيل الدخول',
                        style: TextStyle(color: AppTheme.primaryDarkBlue),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
