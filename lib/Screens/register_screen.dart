import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

import '../../widgets/custom_appbar.dart';

import '../widgets/register_and_sigin/auth_redirect_text.dart';
import '../widgets/register_and_sigin/field_button.dart';
import '../widgets/register_and_sigin/or_divider.dart';
import '../widgets/register_and_sigin/social_login_button.dart';
import '../widgets/register_and_sigin/text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  void _togglePasswordVisibility(){
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final supabase = Supabase.instance.client;

    try {
      final response = await supabase.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        data: {'full_name': _nameCtrl.text.trim()},
      );

      final user = response.user;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tạo được tài khoản')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo tài khoản thành công')),
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi database: ${e.message}')),
      );
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng ký: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        onBack: (){
        Navigator.pop(context);
        },
        title: 'REGISTER',
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text('Register',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
                const SizedBox(height: 20),

                CustomTextField(
                  label: 'Full Name',
                  controller: _nameCtrl,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập họ tên';
                    }
                    return null; // hợp lệ
                  },
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Enter Email',
                  controller: _emailCtrl,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!value.contains('@')) {
                      return 'Email không hợp lệ';
                    }
                    return null; // hợp lệ
                  },
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Password',
                  controller: _passCtrl,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  validator: (value){
                    if(value == null || value.isEmpty)
                      return 'Mật khẩu không được để trống';
                    if(value.length < 6)
                      return 'Mật khẩu phải dài hơn 6 kí tự';
                    return null;
                  },
                  onTogglePassword: _togglePasswordVisibility,
                ),
                const SizedBox(height: 20),
                FieldButton(type: 'createAccount', action: _isLoading ? null : _createAccount),
                const SizedBox(height: 20),
                OrDivider(),
                const SizedBox(height: 15),
                SocialLoginButton(),
                const SizedBox(height: 20),
                AuthRedirectText(type: 'register',),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
